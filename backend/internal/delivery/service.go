package delivery

import (
	"context"
	"crypto/rand"
	"fmt"
	"math/big"
	"time"

	"github.com/google/uuid"

	"github.com/prabakarankannan/marketplace-backend/internal/auth"
	apperrors "github.com/prabakarankannan/marketplace-backend/internal/common/errors"
	"github.com/prabakarankannan/marketplace-backend/internal/common/pagination"
	"github.com/prabakarankannan/marketplace-backend/internal/notification"
	"github.com/prabakarankannan/marketplace-backend/internal/order"
	"github.com/prabakarankannan/marketplace-backend/internal/payment"
	"github.com/prabakarankannan/marketplace-backend/internal/vendor"
)

// DeliveryService defines the business-logic contract for the delivery module.
type DeliveryService interface {
	// Partner self-service
	Register(ctx context.Context, userID uuid.UUID, req RegisterDeliveryPartnerRequest) (*DeliveryPartnerResponse, error)
	GetProfile(ctx context.Context, userID uuid.UUID) (*DeliveryPartnerResponse, error)
	UpdateProfile(ctx context.Context, userID uuid.UUID, req UpdateProfileRequest) error
	UpdateLocation(ctx context.Context, userID uuid.UUID, req UpdateLocationRequest) error
	SetAvailability(ctx context.Context, userID uuid.UUID, isAvailable bool) error
	SetShift(ctx context.Context, userID uuid.UUID, isOnShift bool) error

	// Assignment operations
	ListMyAssignments(ctx context.Context, userID uuid.UUID, params pagination.Params, statusFilter *string) (*pagination.Result[AssignmentResponse], error)
	GetAssignment(ctx context.Context, userID uuid.UUID, assignmentID uuid.UUID) (*AssignmentResponse, error)
	AcceptAssignment(ctx context.Context, userID uuid.UUID, assignmentID uuid.UUID) error
	RejectAssignment(ctx context.Context, userID uuid.UUID, assignmentID uuid.UUID, reason *string) error
	PickupOrder(ctx context.Context, userID uuid.UUID, assignmentID uuid.UUID) error
	DeliverOrder(ctx context.Context, userID uuid.UUID, assignmentID uuid.UUID, req DeliveryProofRequest) error

	// Earnings & stats
	GetEarnings(ctx context.Context, userID uuid.UUID) (*EarningsResponse, error)
	GetEarningsHistory(ctx context.Context, userID uuid.UUID, params pagination.Params) (*pagination.Result[AssignmentResponse], error)
	GetStats(ctx context.Context, userID uuid.UUID) (*StatsResponse, error)

	// Auto-assignment (called when order status becomes 'ready')
	AutoAssign(ctx context.Context, orderID uuid.UUID) error

	// Admin
	AdminListPartners(ctx context.Context, params pagination.Params, status string) (*pagination.Result[DeliveryPartnerResponse], error)
	AdminGetPartner(ctx context.Context, id uuid.UUID) (*DeliveryPartnerResponse, error)
	AdminUpdateStatus(ctx context.Context, id uuid.UUID, req AdminUpdatePartnerStatusRequest) error
	AdminListAssignments(ctx context.Context, params pagination.Params, statusFilter *string) (*pagination.Result[AssignmentResponse], error)
	AdminManualAssign(ctx context.Context, req AdminManualAssignRequest) (*AssignmentResponse, error)
}

type deliveryService struct {
	repo        DeliveryRepository
	authRepo    auth.AuthRepository
	orderRepo   order.OrderRepository
	vendorRepo  vendor.VendorRepository
	notifSvc    notification.NotificationService
	paymentRepo payment.PaymentRepository
}

// NewDeliveryService returns a new DeliveryService with all required dependencies.
func NewDeliveryService(
	repo DeliveryRepository,
	authRepo auth.AuthRepository,
	orderRepo order.OrderRepository,
	vendorRepo vendor.VendorRepository,
	notifSvc notification.NotificationService,
	paymentRepo payment.PaymentRepository,
) DeliveryService {
	return &deliveryService{
		repo:        repo,
		authRepo:    authRepo,
		orderRepo:   orderRepo,
		vendorRepo:  vendorRepo,
		notifSvc:    notifSvc,
		paymentRepo: paymentRepo,
	}
}

// ---------------------------------------------------------------------------
// Partner self-service
// ---------------------------------------------------------------------------

func (s *deliveryService) Register(ctx context.Context, userID uuid.UUID, req RegisterDeliveryPartnerRequest) (*DeliveryPartnerResponse, error) {
	user, err := s.authRepo.FindByID(ctx, userID)
	if err != nil {
		return nil, apperrors.Internal("failed to look up user")
	}
	if user == nil {
		return nil, apperrors.NotFound("user not found")
	}

	existing, err := s.repo.FindByUserID(ctx, userID)
	if err != nil {
		return nil, apperrors.Internal("failed to check existing delivery partner")
	}
	if existing != nil {
		return nil, apperrors.Conflict("user already has a delivery partner profile")
	}

	partner := DeliveryPartner{
		ID:               uuid.New(),
		UserID:           userID,
		VehicleType:      req.VehicleType,
		VehicleNumber:    req.VehicleNumber,
		LicenseNumber:    req.LicenseNumber,
		Status:           "pending",
		CurrentLatitude:  req.Latitude,
		CurrentLongitude: req.Longitude,
		ZonePreference:   req.ZonePreference,
		CommissionPct:    15.0,
	}

	if err := s.repo.Create(ctx, &partner); err != nil {
		return nil, apperrors.Internal("failed to create delivery partner")
	}

	user.Role = "delivery"
	if err := s.authRepo.Update(ctx, user); err != nil {
		return nil, apperrors.Internal("failed to update user role")
	}

	resp := toDeliveryPartnerResponse(&partner)
	return &resp, nil
}

func (s *deliveryService) GetProfile(ctx context.Context, userID uuid.UUID) (*DeliveryPartnerResponse, error) {
	partner, err := s.repo.FindByUserID(ctx, userID)
	if err != nil {
		return nil, apperrors.Internal("failed to find delivery partner")
	}
	if partner == nil {
		return nil, apperrors.NotFound("delivery partner profile not found")
	}
	resp := toDeliveryPartnerResponse(partner)
	return &resp, nil
}

func (s *deliveryService) UpdateProfile(ctx context.Context, userID uuid.UUID, req UpdateProfileRequest) error {
	partner, err := s.repo.FindByUserID(ctx, userID)
	if err != nil {
		return apperrors.Internal("failed to find delivery partner")
	}
	if partner == nil {
		return apperrors.NotFound("delivery partner profile not found")
	}

	if req.VehicleType != nil {
		partner.VehicleType = *req.VehicleType
	}
	if req.VehicleNumber != nil {
		partner.VehicleNumber = req.VehicleNumber
	}
	if req.LicenseNumber != nil {
		partner.LicenseNumber = req.LicenseNumber
	}
	if req.ZonePreference != nil {
		partner.ZonePreference = req.ZonePreference
	}

	if err := s.repo.Update(ctx, partner); err != nil {
		return apperrors.Internal("failed to update delivery partner")
	}
	return nil
}

func (s *deliveryService) UpdateLocation(ctx context.Context, userID uuid.UUID, req UpdateLocationRequest) error {
	partner, err := s.repo.FindByUserID(ctx, userID)
	if err != nil {
		return apperrors.Internal("failed to find delivery partner")
	}
	if partner == nil {
		return apperrors.NotFound("delivery partner profile not found")
	}

	if err := s.repo.UpdateLocation(ctx, partner.ID, req.Latitude, req.Longitude); err != nil {
		return apperrors.Internal("failed to update location")
	}
	return nil
}

func (s *deliveryService) SetAvailability(ctx context.Context, userID uuid.UUID, isAvailable bool) error {
	partner, err := s.repo.FindByUserID(ctx, userID)
	if err != nil {
		return apperrors.Internal("failed to find delivery partner")
	}
	if partner == nil {
		return apperrors.NotFound("delivery partner profile not found")
	}
	if partner.Status != "approved" {
		return apperrors.BadRequest("only approved partners can set availability")
	}

	if err := s.repo.UpdateAvailability(ctx, partner.ID, isAvailable); err != nil {
		return apperrors.Internal("failed to update availability")
	}
	return nil
}

func (s *deliveryService) SetShift(ctx context.Context, userID uuid.UUID, isOnShift bool) error {
	partner, err := s.repo.FindByUserID(ctx, userID)
	if err != nil {
		return apperrors.Internal("failed to find delivery partner")
	}
	if partner == nil {
		return apperrors.NotFound("delivery partner profile not found")
	}
	if partner.Status != "approved" {
		return apperrors.BadRequest("only approved partners can manage shifts")
	}

	if err := s.repo.UpdateShift(ctx, partner.ID, isOnShift); err != nil {
		return apperrors.Internal("failed to update shift status")
	}
	return nil
}

// ---------------------------------------------------------------------------
// Assignment operations
// ---------------------------------------------------------------------------

func (s *deliveryService) ListMyAssignments(ctx context.Context, userID uuid.UUID, params pagination.Params, statusFilter *string) (*pagination.Result[AssignmentResponse], error) {
	partner, err := s.repo.FindByUserID(ctx, userID)
	if err != nil {
		return nil, apperrors.Internal("failed to find delivery partner")
	}
	if partner == nil {
		return nil, apperrors.NotFound("delivery partner not found")
	}

	result, err := s.repo.ListAssignmentsByPartner(ctx, partner.ID, params, statusFilter)
	if err != nil {
		return nil, apperrors.Internal("failed to list assignments")
	}
	return toAssignmentResultResponse(result), nil
}

func (s *deliveryService) GetAssignment(ctx context.Context, userID uuid.UUID, assignmentID uuid.UUID) (*AssignmentResponse, error) {
	partner, err := s.repo.FindByUserID(ctx, userID)
	if err != nil {
		return nil, apperrors.Internal("failed to find delivery partner")
	}
	if partner == nil {
		return nil, apperrors.NotFound("delivery partner not found")
	}

	assignment, err := s.repo.FindAssignmentByID(ctx, assignmentID)
	if err != nil {
		return nil, apperrors.Internal("failed to find assignment")
	}
	if assignment == nil {
		return nil, apperrors.NotFound("assignment not found")
	}
	if assignment.DeliveryPartnerID != partner.ID {
		return nil, apperrors.Forbidden("assignment does not belong to you")
	}

	resp := toAssignmentResponse(assignment)
	return &resp, nil
}

func (s *deliveryService) AcceptAssignment(ctx context.Context, userID uuid.UUID, assignmentID uuid.UUID) error {
	partner, err := s.repo.FindByUserID(ctx, userID)
	if err != nil {
		return apperrors.Internal("failed to find delivery partner")
	}
	if partner == nil {
		return apperrors.NotFound("delivery partner not found")
	}

	assignment, err := s.repo.FindAssignmentByID(ctx, assignmentID)
	if err != nil {
		return apperrors.Internal("failed to find assignment")
	}
	if assignment == nil {
		return apperrors.NotFound("assignment not found")
	}
	if assignment.DeliveryPartnerID != partner.ID {
		return apperrors.Forbidden("assignment does not belong to you")
	}
	if assignment.Status != "assigned" {
		return apperrors.BadRequest("assignment cannot be accepted in current status")
	}

	now := time.Now()
	assignment.Status = "accepted"
	assignment.AcceptedAt = &now
	if err := s.repo.UpdateAssignment(ctx, assignment); err != nil {
		return apperrors.Internal("failed to accept assignment")
	}

	// Set current_order_id with optimistic lock
	rowsAffected, err := s.repo.SetCurrentOrder(ctx, partner.ID, &assignment.OrderID)
	if err != nil {
		return apperrors.Internal("failed to update partner current order")
	}
	if rowsAffected == 0 {
		return apperrors.Conflict("partner already has an active delivery")
	}

	// Update order status to out_for_delivery
	if err := s.orderRepo.UpdateStatus(ctx, assignment.OrderID, "out_for_delivery"); err != nil {
		return apperrors.Internal("failed to update order status")
	}

	// Update order delivery_partner_id
	if err := s.orderRepo.UpdateDeliveryPartner(ctx, assignment.OrderID, partner.ID); err != nil {
		return apperrors.Internal("failed to set delivery partner on order")
	}

	return nil
}

func (s *deliveryService) RejectAssignment(ctx context.Context, userID uuid.UUID, assignmentID uuid.UUID, reason *string) error {
	partner, err := s.repo.FindByUserID(ctx, userID)
	if err != nil {
		return apperrors.Internal("failed to find delivery partner")
	}
	if partner == nil {
		return apperrors.NotFound("delivery partner not found")
	}

	assignment, err := s.repo.FindAssignmentByID(ctx, assignmentID)
	if err != nil {
		return apperrors.Internal("failed to find assignment")
	}
	if assignment == nil {
		return apperrors.NotFound("assignment not found")
	}
	if assignment.DeliveryPartnerID != partner.ID {
		return apperrors.Forbidden("assignment does not belong to you")
	}
	if assignment.Status != "assigned" {
		return apperrors.BadRequest("assignment cannot be rejected in current status")
	}

	assignment.Status = "rejected"
	assignment.RejectionReason = reason
	if err := s.repo.UpdateAssignment(ctx, assignment); err != nil {
		return apperrors.Internal("failed to reject assignment")
	}

	// Revert order status back to ready so auto-assignment can retry
	if err := s.orderRepo.UpdateStatus(ctx, assignment.OrderID, "ready"); err != nil {
		return apperrors.Internal("failed to revert order status")
	}

	// Trigger re-assignment asynchronously
	go func() {
		_ = s.AutoAssign(context.Background(), assignment.OrderID)
	}()

	return nil
}

func (s *deliveryService) PickupOrder(ctx context.Context, userID uuid.UUID, assignmentID uuid.UUID) error {
	partner, err := s.repo.FindByUserID(ctx, userID)
	if err != nil {
		return apperrors.Internal("failed to find delivery partner")
	}
	if partner == nil {
		return apperrors.NotFound("delivery partner not found")
	}

	assignment, err := s.repo.FindAssignmentByID(ctx, assignmentID)
	if err != nil {
		return apperrors.Internal("failed to find assignment")
	}
	if assignment == nil {
		return apperrors.NotFound("assignment not found")
	}
	if assignment.DeliveryPartnerID != partner.ID {
		return apperrors.Forbidden("assignment does not belong to you")
	}
	if assignment.Status != "accepted" {
		return apperrors.BadRequest("assignment must be accepted before pickup")
	}

	now := time.Now()
	assignment.Status = "picked_up"
	assignment.PickedUpAt = &now
	if err := s.repo.UpdateAssignment(ctx, assignment); err != nil {
		return apperrors.Internal("failed to update assignment")
	}

	return nil
}

func (s *deliveryService) DeliverOrder(ctx context.Context, userID uuid.UUID, assignmentID uuid.UUID, req DeliveryProofRequest) error {
	partner, err := s.repo.FindByUserID(ctx, userID)
	if err != nil {
		return apperrors.Internal("failed to find delivery partner")
	}
	if partner == nil {
		return apperrors.NotFound("delivery partner not found")
	}

	assignment, err := s.repo.FindAssignmentByID(ctx, assignmentID)
	if err != nil {
		return apperrors.Internal("failed to find assignment")
	}
	if assignment == nil {
		return apperrors.NotFound("assignment not found")
	}
	if assignment.DeliveryPartnerID != partner.ID {
		return apperrors.Forbidden("assignment does not belong to you")
	}
	if assignment.Status != "picked_up" {
		return apperrors.BadRequest("order must be picked up before delivery")
	}
	if assignment.DeliveryOTP != req.OTP {
		return apperrors.BadRequest("invalid delivery OTP")
	}

	// Fetch order to calculate earnings
	o, err := s.orderRepo.FindByID(ctx, assignment.OrderID)
	if err != nil || o == nil {
		return apperrors.Internal("failed to find order")
	}

	// Calculate earnings: delivery fee minus commission
	earnings := o.DeliveryFee * (1 - partner.CommissionPct/100)

	now := time.Now()
	assignment.Status = "delivered"
	assignment.DeliveredAt = &now
	assignment.DeliveryProofURL = &req.ProofURL
	assignment.Earnings = &earnings
	if err := s.repo.UpdateAssignment(ctx, assignment); err != nil {
		return apperrors.Internal("failed to update assignment")
	}

	// Clear partner's current order
	if _, err := s.repo.SetCurrentOrder(ctx, partner.ID, nil); err != nil {
		return apperrors.Internal("failed to clear partner current order")
	}

	// Increment partner stats
	if err := s.repo.IncrementStats(ctx, partner.ID, earnings); err != nil {
		return apperrors.Internal("failed to update partner stats")
	}

	// Update order status to delivered
	if err := s.orderRepo.UpdateStatus(ctx, assignment.OrderID, "delivered"); err != nil {
		return apperrors.Internal("failed to update order status")
	}

	// Credit delivery partner wallet
	wallet, err := s.paymentRepo.GetOrCreateDeliveryWallet(ctx, partner.ID)
	if err == nil && wallet != nil {
		db := s.paymentRepo.DB()
		_ = s.paymentRepo.CreditWallet(ctx, db, wallet.ID, earnings, "delivery", "Delivery earnings", assignment.OrderID)
	}

	// Notify customer
	_ = s.notifSvc.SendNotification(ctx, o.CustomerID,
		"Order Delivered",
		fmt.Sprintf("Your order %s has been delivered!", o.OrderNumber),
		"order_delivered",
		map[string]string{
			"order_id": o.ID.String(),
		},
	)

	return nil
}

// ---------------------------------------------------------------------------
// Earnings & stats
// ---------------------------------------------------------------------------

func (s *deliveryService) GetEarnings(ctx context.Context, userID uuid.UUID) (*EarningsResponse, error) {
	partner, err := s.repo.FindByUserID(ctx, userID)
	if err != nil {
		return nil, apperrors.Internal("failed to find delivery partner")
	}
	if partner == nil {
		return nil, apperrors.NotFound("delivery partner not found")
	}

	return s.repo.GetEarningsSummary(ctx, partner.ID)
}

func (s *deliveryService) GetEarningsHistory(ctx context.Context, userID uuid.UUID, params pagination.Params) (*pagination.Result[AssignmentResponse], error) {
	partner, err := s.repo.FindByUserID(ctx, userID)
	if err != nil {
		return nil, apperrors.Internal("failed to find delivery partner")
	}
	if partner == nil {
		return nil, apperrors.NotFound("delivery partner not found")
	}

	result, err := s.repo.GetEarningsHistory(ctx, partner.ID, params)
	if err != nil {
		return nil, apperrors.Internal("failed to get earnings history")
	}
	return toAssignmentResultResponse(result), nil
}

func (s *deliveryService) GetStats(ctx context.Context, userID uuid.UUID) (*StatsResponse, error) {
	partner, err := s.repo.FindByUserID(ctx, userID)
	if err != nil {
		return nil, apperrors.Internal("failed to find delivery partner")
	}
	if partner == nil {
		return nil, apperrors.NotFound("delivery partner not found")
	}

	return s.repo.GetPartnerStats(ctx, partner.ID)
}

// ---------------------------------------------------------------------------
// Auto-assignment
// ---------------------------------------------------------------------------

func (s *deliveryService) AutoAssign(ctx context.Context, orderID uuid.UUID) error {
	o, err := s.orderRepo.FindByID(ctx, orderID)
	if err != nil {
		return apperrors.Internal("failed to find order")
	}
	if o == nil {
		return apperrors.NotFound("order not found")
	}

	// Get vendor location for proximity search
	v, err := s.vendorRepo.FindByID(ctx, o.VendorID)
	if err != nil || v == nil {
		return apperrors.Internal("failed to find vendor")
	}

	// Find up to 5 nearest available partners within 10 km of vendor
	partners, err := s.repo.FindNearbyAvailable(ctx, v.Latitude, v.Longitude, 10.0, 5)
	if err != nil {
		return apperrors.Internal("failed to find nearby partners")
	}
	if len(partners) == 0 {
		return nil // No partners available; order stays in "ready"
	}

	otp := generateOTP()

	// Try assigning to nearest available partner
	for _, partner := range partners {
		assignment := DeliveryAssignment{
			ID:                uuid.New(),
			OrderID:           orderID,
			DeliveryPartnerID: partner.ID,
			Status:            "assigned",
			AssignedAt:        time.Now(),
			DeliveryOTP:       otp,
			CreatedAt:         time.Now(),
		}

		if err := s.repo.CreateAssignment(ctx, &assignment); err != nil {
			continue
		}

		// Update order status to 'assigned'
		if err := s.orderRepo.UpdateStatus(ctx, orderID, "assigned"); err != nil {
			continue
		}

		// Send push notification to partner
		_ = s.notifSvc.SendNotification(ctx, partner.UserID,
			"New Delivery Assignment",
			fmt.Sprintf("Order %s is ready for pickup", o.OrderNumber),
			"delivery_assignment",
			map[string]string{
				"assignment_id": assignment.ID.String(),
				"order_id":      orderID.String(),
			},
		)

		return nil
	}

	return nil // All partners busy; order stays in "ready"
}

// ---------------------------------------------------------------------------
// Admin
// ---------------------------------------------------------------------------

func (s *deliveryService) AdminListPartners(ctx context.Context, params pagination.Params, status string) (*pagination.Result[DeliveryPartnerResponse], error) {
	result, err := s.repo.ListAll(ctx, params, status)
	if err != nil {
		return nil, apperrors.Internal("failed to list delivery partners")
	}
	return toPartnerResultResponse(result), nil
}

func (s *deliveryService) AdminGetPartner(ctx context.Context, id uuid.UUID) (*DeliveryPartnerResponse, error) {
	partner, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, apperrors.Internal("failed to find delivery partner")
	}
	if partner == nil {
		return nil, apperrors.NotFound("delivery partner not found")
	}
	resp := toDeliveryPartnerResponse(partner)
	return &resp, nil
}

func (s *deliveryService) AdminUpdateStatus(ctx context.Context, id uuid.UUID, req AdminUpdatePartnerStatusRequest) error {
	partner, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return apperrors.Internal("failed to find delivery partner")
	}
	if partner == nil {
		return apperrors.NotFound("delivery partner not found")
	}

	if err := s.repo.UpdateStatus(ctx, id, req.Status); err != nil {
		return apperrors.Internal("failed to update status")
	}

	// Notify partner
	_ = s.notifSvc.SendNotification(ctx, partner.UserID,
		"Account Status Updated",
		fmt.Sprintf("Your delivery partner account has been %s", req.Status),
		"partner_status_update",
		map[string]string{
			"status": req.Status,
		},
	)

	return nil
}

func (s *deliveryService) AdminListAssignments(ctx context.Context, params pagination.Params, statusFilter *string) (*pagination.Result[AssignmentResponse], error) {
	result, err := s.repo.ListAllAssignments(ctx, params, statusFilter)
	if err != nil {
		return nil, apperrors.Internal("failed to list assignments")
	}
	return toAssignmentResultResponse(result), nil
}

func (s *deliveryService) AdminManualAssign(ctx context.Context, req AdminManualAssignRequest) (*AssignmentResponse, error) {
	partner, err := s.repo.FindByID(ctx, req.DeliveryPartnerID)
	if err != nil {
		return nil, apperrors.Internal("failed to find delivery partner")
	}
	if partner == nil {
		return nil, apperrors.NotFound("delivery partner not found")
	}
	if partner.Status != "approved" {
		return nil, apperrors.BadRequest("partner is not approved")
	}

	o, err := s.orderRepo.FindByID(ctx, req.OrderID)
	if err != nil || o == nil {
		return nil, apperrors.NotFound("order not found")
	}

	otp := generateOTP()
	assignment := DeliveryAssignment{
		ID:                uuid.New(),
		OrderID:           req.OrderID,
		DeliveryPartnerID: req.DeliveryPartnerID,
		Status:            "assigned",
		AssignedAt:        time.Now(),
		DeliveryOTP:       otp,
		CreatedAt:         time.Now(),
	}

	if err := s.repo.CreateAssignment(ctx, &assignment); err != nil {
		return nil, apperrors.Internal("failed to create assignment")
	}

	_ = s.orderRepo.UpdateStatus(ctx, req.OrderID, "assigned")

	_ = s.notifSvc.SendNotification(ctx, partner.UserID,
		"New Delivery Assignment",
		fmt.Sprintf("Order %s has been assigned to you", o.OrderNumber),
		"delivery_assignment",
		map[string]string{
			"assignment_id": assignment.ID.String(),
			"order_id":      req.OrderID.String(),
		},
	)

	resp := toAssignmentResponse(&assignment)
	return &resp, nil
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

func generateOTP() string {
	const digits = "0123456789"
	otp := make([]byte, 6)
	for i := range otp {
		n, _ := rand.Int(rand.Reader, big.NewInt(10))
		otp[i] = digits[n.Int64()]
	}
	return string(otp)
}

func toAssignmentResultResponse(result *pagination.Result[DeliveryAssignment]) *pagination.Result[AssignmentResponse] {
	responses := make([]AssignmentResponse, len(result.Items))
	for i := range result.Items {
		responses[i] = toAssignmentResponse(&result.Items[i])
	}
	return &pagination.Result[AssignmentResponse]{
		Items: responses,
		Total: result.Total,
	}
}

func toPartnerResultResponse(result *pagination.Result[DeliveryPartner]) *pagination.Result[DeliveryPartnerResponse] {
	responses := make([]DeliveryPartnerResponse, len(result.Items))
	for i := range result.Items {
		responses[i] = toDeliveryPartnerResponse(&result.Items[i])
	}
	return &pagination.Result[DeliveryPartnerResponse]{
		Items: responses,
		Total: result.Total,
	}
}
