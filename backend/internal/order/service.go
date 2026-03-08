package order

import (
	"context"
	"time"

	"github.com/google/uuid"

	apperrors "github.com/prabakarankannan/marketplace-backend/internal/common/errors"
	"github.com/prabakarankannan/marketplace-backend/internal/common/pagination"
	"github.com/prabakarankannan/marketplace-backend/internal/product"
	"github.com/prabakarankannan/marketplace-backend/internal/vendor"
)

// OrderService defines the business-logic contract for the order module.
type OrderService interface {
	CreateOrder(ctx context.Context, customerID uuid.UUID, req CreateOrderRequest) (*OrderResponse, error)
	GetOrder(ctx context.Context, orderID uuid.UUID) (*OrderResponse, error)
	ListMyOrders(ctx context.Context, customerID uuid.UUID, params pagination.Params) (*pagination.Result[OrderResponse], error)
	ListVendorOrders(ctx context.Context, userID uuid.UUID, params pagination.Params, statusFilter *string) (*pagination.Result[OrderResponse], error)
	CancelOrder(ctx context.Context, customerID uuid.UUID, orderID uuid.UUID) error
	UpdateOrderStatus(ctx context.Context, userID uuid.UUID, orderID uuid.UUID, status string) error
	ListAllOrders(ctx context.Context, params pagination.Params, statusFilter *string) (*pagination.Result[OrderResponse], error)
	SetOnReadyHook(hook OnReadyHook)
}

// OnReadyHook is a callback invoked when an order transitions to "ready".
type OnReadyHook func(ctx context.Context, orderID uuid.UUID)

// orderService is the concrete implementation of OrderService.
type orderService struct {
	orderRepo   OrderRepository
	productRepo product.ProductRepository
	vendorRepo  vendor.VendorRepository
	onReadyHook OnReadyHook
}

// NewOrderService returns a new OrderService with all required dependencies.
func NewOrderService(
	orderRepo OrderRepository,
	productRepo product.ProductRepository,
	vendorRepo vendor.VendorRepository,
) OrderService {
	return &orderService{
		orderRepo:   orderRepo,
		productRepo: productRepo,
		vendorRepo:  vendorRepo,
	}
}

// SetOnReadyHook registers a callback to be invoked when an order becomes "ready".
func (s *orderService) SetOnReadyHook(hook OnReadyHook) {
	s.onReadyHook = hook
}

// CreateOrder validates products, calculates prices, decrements stock, and
// persists the order with its items.
func (s *orderService) CreateOrder(ctx context.Context, customerID uuid.UUID, req CreateOrderRequest) (*OrderResponse, error) {
	// Build order items and validate each product.
	var subtotal float64
	items := make([]OrderItem, 0, len(req.Items))

	for _, ri := range req.Items {
		p, err := s.productRepo.GetProduct(ctx, ri.ProductID)
		if err != nil {
			return nil, apperrors.Internal("failed to look up product")
		}
		if p == nil {
			return nil, apperrors.NotFound("product not found: " + ri.ProductID.String())
		}
		if p.VendorID != req.VendorID {
			return nil, apperrors.BadRequest("product " + p.Name + " does not belong to the specified vendor")
		}
		if p.StockQuantity < ri.Quantity {
			return nil, apperrors.BadRequest("insufficient stock for product: " + p.Name)
		}

		totalPrice := p.Price * float64(ri.Quantity)
		subtotal += totalPrice

		var productImage *string
		if len(p.Images) > 0 {
			productImage = &p.Images[0]
		}

		items = append(items, OrderItem{
			ProductID:    p.ID,
			ProductName:  p.Name,
			ProductImage: productImage,
			Quantity:     ri.Quantity,
			UnitPrice:    p.Price,
			TotalPrice:   totalPrice,
		})
	}

	// Decrement stock for all items.
	for _, ri := range req.Items {
		if err := s.productRepo.DecrementStock(ctx, ri.ProductID, ri.Quantity); err != nil {
			return nil, apperrors.BadRequest("failed to reserve stock: " + err.Error())
		}
	}

	// Calculate totals.
	deliveryFee := 0.0
	if req.DeliveryFee != nil {
		deliveryFee = *req.DeliveryFee
	}
	total := subtotal + deliveryFee

	o := Order{
		ID:            uuid.New(),
		OrderNumber:   GenerateOrderNumber(),
		CustomerID:    customerID,
		VendorID:      req.VendorID,
		AddressID:     req.AddressID,
		Status:        "pending",
		Subtotal:      subtotal,
		DeliveryFee:   deliveryFee,
		Discount:      0,
		Tax:           0,
		Total:         total,
		PaymentStatus: "pending",
		Notes:         req.Notes,
		Items:         items,
	}

	if err := s.orderRepo.Create(ctx, &o); err != nil {
		return nil, apperrors.Internal("failed to create order")
	}

	// Re-fetch to get full preloaded data.
	created, err := s.orderRepo.FindByID(ctx, o.ID)
	if err != nil || created == nil {
		return nil, apperrors.Internal("failed to retrieve created order")
	}

	return toOrderResponse(created), nil
}

// GetOrder retrieves a single order by its ID.
func (s *orderService) GetOrder(ctx context.Context, orderID uuid.UUID) (*OrderResponse, error) {
	o, err := s.orderRepo.FindByID(ctx, orderID)
	if err != nil {
		return nil, apperrors.Internal("failed to find order")
	}
	if o == nil {
		return nil, apperrors.NotFound("order not found")
	}
	return toOrderResponse(o), nil
}

// ListMyOrders returns a paginated list of orders for the authenticated customer.
func (s *orderService) ListMyOrders(ctx context.Context, customerID uuid.UUID, params pagination.Params) (*pagination.Result[OrderResponse], error) {
	result, err := s.orderRepo.ListByCustomer(ctx, customerID, params)
	if err != nil {
		return nil, apperrors.Internal("failed to list orders")
	}
	return toOrderResultResponse(result), nil
}

// ListVendorOrders returns a paginated list of orders for the vendor
// associated with the given user.
func (s *orderService) ListVendorOrders(ctx context.Context, userID uuid.UUID, params pagination.Params, statusFilter *string) (*pagination.Result[OrderResponse], error) {
	v, err := s.vendorRepo.FindByUserID(ctx, userID)
	if err != nil {
		return nil, apperrors.Internal("failed to look up vendor profile")
	}
	if v == nil {
		return nil, apperrors.Forbidden("user is not a vendor")
	}

	result, err := s.orderRepo.ListByVendor(ctx, v.ID, params, statusFilter)
	if err != nil {
		return nil, apperrors.Internal("failed to list vendor orders")
	}
	return toOrderResultResponse(result), nil
}

// CancelOrder cancels an order, verifying ownership and checking the state
// machine allows the transition. It also restores stock for all items.
func (s *orderService) CancelOrder(ctx context.Context, customerID uuid.UUID, orderID uuid.UUID) error {
	o, err := s.orderRepo.FindByID(ctx, orderID)
	if err != nil {
		return apperrors.Internal("failed to find order")
	}
	if o == nil {
		return apperrors.NotFound("order not found")
	}
	if o.CustomerID != customerID {
		return apperrors.Forbidden("you do not own this order")
	}
	if !CanTransition(o.Status, "cancelled") {
		return apperrors.BadRequest("order cannot be cancelled in its current status")
	}

	// Restore stock for each item.
	for _, item := range o.Items {
		if err := s.productRepo.IncrementStock(ctx, item.ProductID, item.Quantity); err != nil {
			return apperrors.Internal("failed to restore stock")
		}
	}

	now := time.Now()
	_ = now
	if err := s.orderRepo.UpdateStatus(ctx, orderID, "cancelled"); err != nil {
		return apperrors.Internal("failed to cancel order")
	}

	return nil
}

// UpdateOrderStatus updates the order status after verifying that the
// requesting user is the vendor who owns the order, and that the state
// transition is valid.
func (s *orderService) UpdateOrderStatus(ctx context.Context, userID uuid.UUID, orderID uuid.UUID, status string) error {
	v, err := s.vendorRepo.FindByUserID(ctx, userID)
	if err != nil {
		return apperrors.Internal("failed to look up vendor profile")
	}
	if v == nil {
		return apperrors.Forbidden("user is not a vendor")
	}

	o, err := s.orderRepo.FindByID(ctx, orderID)
	if err != nil {
		return apperrors.Internal("failed to find order")
	}
	if o == nil {
		return apperrors.NotFound("order not found")
	}
	if o.VendorID != v.ID {
		return apperrors.Forbidden("order does not belong to your vendor profile")
	}
	if !CanTransition(o.Status, status) {
		return apperrors.BadRequest("invalid status transition from " + o.Status + " to " + status)
	}

	if err := s.orderRepo.UpdateStatus(ctx, orderID, status); err != nil {
		return apperrors.Internal("failed to update order status")
	}

	// Trigger auto-assignment when order becomes ready
	if status == "ready" && s.onReadyHook != nil {
		go s.onReadyHook(context.Background(), orderID)
	}

	return nil
}

// ListAllOrders returns a paginated list of all orders (admin use).
func (s *orderService) ListAllOrders(ctx context.Context, params pagination.Params, statusFilter *string) (*pagination.Result[OrderResponse], error) {
	result, err := s.orderRepo.ListAll(ctx, params, statusFilter)
	if err != nil {
		return nil, apperrors.Internal("failed to list orders")
	}
	return toOrderResultResponse(result), nil
}

// toOrderResultResponse converts a pagination.Result[Order] to
// pagination.Result[OrderResponse].
func toOrderResultResponse(result *pagination.Result[Order]) *pagination.Result[OrderResponse] {
	responses := make([]OrderResponse, len(result.Items))
	for i := range result.Items {
		responses[i] = *toOrderResponse(&result.Items[i])
	}
	return &pagination.Result[OrderResponse]{
		Items: responses,
		Total: result.Total,
	}
}
