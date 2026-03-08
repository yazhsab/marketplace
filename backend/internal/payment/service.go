package payment

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"github.com/prabakarankannan/marketplace-backend/internal/booking"
	apperrors "github.com/prabakarankannan/marketplace-backend/internal/common/errors"
	"github.com/prabakarankannan/marketplace-backend/internal/common/pagination"
	"github.com/prabakarankannan/marketplace-backend/internal/order"
	"github.com/prabakarankannan/marketplace-backend/internal/vendor"
)

// PaymentService defines the business-logic contract for the payment module.
type PaymentService interface {
	CreatePaymentOrder(ctx context.Context, customerID uuid.UUID, req CreatePaymentRequest) (*PaymentResponse, error)
	VerifyPayment(ctx context.Context, req VerifyPaymentRequest) (*PaymentResponse, error)
	GetPayment(ctx context.Context, paymentID uuid.UUID) (*PaymentResponse, error)
	GetWallet(ctx context.Context, userID uuid.UUID) (*WalletResponse, error)
	ListTransactions(ctx context.Context, userID uuid.UUID, params pagination.Params) (*pagination.Result[WalletTransactionResponse], error)
	RequestPayout(ctx context.Context, userID uuid.UUID, req PayoutRequest) (*WalletTransactionResponse, error)
	AdminListPayments(ctx context.Context, params pagination.Params) (*pagination.Result[PaymentResponse], error)
	AdminListPayouts(ctx context.Context, params pagination.Params) (*pagination.Result[WalletTransactionResponse], error)
}

// paymentService is the concrete implementation of PaymentService.
type paymentService struct {
	paymentRepo    PaymentRepository
	orderRepo      order.OrderRepository
	bookingRepo    booking.BookingRepository
	vendorRepo     vendor.VendorRepository
	razorpayClient *RazorpayClient
	db             *gorm.DB
}

// NewPaymentService returns a new PaymentService with all required dependencies.
func NewPaymentService(
	paymentRepo PaymentRepository,
	orderRepo order.OrderRepository,
	bookingRepo booking.BookingRepository,
	vendorRepo vendor.VendorRepository,
	razorpayClient *RazorpayClient,
	db *gorm.DB,
) PaymentService {
	return &paymentService{
		paymentRepo:    paymentRepo,
		orderRepo:      orderRepo,
		bookingRepo:    bookingRepo,
		vendorRepo:     vendorRepo,
		razorpayClient: razorpayClient,
		db:             db,
	}
}

// CreatePaymentOrder looks up the order or booking, creates a Razorpay order,
// and saves a payment record.
func (s *paymentService) CreatePaymentOrder(ctx context.Context, customerID uuid.UUID, req CreatePaymentRequest) (*PaymentResponse, error) {
	var amount float64
	var vendorID uuid.UUID
	var currency string = "INR"

	switch req.PaymentType {
	case "order":
		o, err := s.orderRepo.FindByID(ctx, req.ReferenceID)
		if err != nil {
			return nil, apperrors.Internal("failed to look up order")
		}
		if o == nil {
			return nil, apperrors.NotFound("order not found")
		}
		if o.CustomerID != customerID {
			return nil, apperrors.Forbidden("you do not own this order")
		}
		amount = o.Total
		vendorID = o.VendorID

	case "booking":
		b, err := s.bookingRepo.FindByID(ctx, req.ReferenceID)
		if err != nil {
			return nil, apperrors.Internal("failed to look up booking")
		}
		if b == nil {
			return nil, apperrors.NotFound("booking not found")
		}
		if b.CustomerID != customerID {
			return nil, apperrors.Forbidden("you do not own this booking")
		}
		amount = b.Total
		vendorID = b.VendorID

	default:
		return nil, apperrors.BadRequest("invalid payment type")
	}

	// Create Razorpay order.
	receipt := fmt.Sprintf("%s_%s", req.PaymentType, req.ReferenceID.String())
	rzpOrder, err := s.razorpayClient.CreateOrder(amount, currency, receipt)
	if err != nil {
		return nil, apperrors.Internal("failed to create razorpay order: " + err.Error())
	}

	// Save payment record.
	p := Payment{
		ID:              uuid.New(),
		PaymentType:     req.PaymentType,
		ReferenceID:     req.ReferenceID,
		CustomerID:      customerID,
		VendorID:        vendorID,
		Amount:          amount,
		Currency:        currency,
		Status:          "created",
		RazorpayOrderID: &rzpOrder.ID,
	}

	if err := s.paymentRepo.CreatePayment(ctx, &p); err != nil {
		return nil, apperrors.Internal("failed to save payment record")
	}

	return toPaymentResponse(&p), nil
}

// VerifyPayment verifies the Razorpay signature, updates the payment and
// the related order/booking status to paid, and credits the vendor wallet
// (amount minus commission).
func (s *paymentService) VerifyPayment(ctx context.Context, req VerifyPaymentRequest) (*PaymentResponse, error) {
	// Look up payment by Razorpay order ID.
	p, err := s.paymentRepo.GetPaymentByRazorpayOrderID(ctx, req.RazorpayOrderID)
	if err != nil {
		return nil, apperrors.Internal("failed to look up payment")
	}
	if p == nil {
		return nil, apperrors.NotFound("payment not found")
	}

	// Verify signature.
	if !s.razorpayClient.VerifySignature(req.RazorpayOrderID, req.RazorpayPaymentID, req.RazorpaySignature) {
		p.Status = "failed"
		errCode := "SIGNATURE_MISMATCH"
		errDesc := "Payment signature verification failed"
		p.ErrorCode = &errCode
		p.ErrorDescription = &errDesc
		_ = s.paymentRepo.UpdatePayment(ctx, p)
		return nil, apperrors.BadRequest("payment signature verification failed")
	}

	// Use a transaction to update payment, order/booking, and wallet atomically.
	txErr := s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		// Update payment record.
		now := time.Now()
		p.Status = "captured"
		p.RazorpayPaymentID = &req.RazorpayPaymentID
		sig := req.RazorpaySignature
		p.RazorpaySignature = &sig
		p.PaidAt = &now
		p.UpdatedAt = now

		if err := tx.Save(p).Error; err != nil {
			return err
		}

		// Update order/booking payment status.
		switch p.PaymentType {
		case "order":
			if err := tx.Model(&order.Order{}).
				Where("id = ?", p.ReferenceID).
				Updates(map[string]interface{}{
					"payment_status": "paid",
					"status":         "confirmed",
					"updated_at":     now,
				}).Error; err != nil {
				return err
			}
		case "booking":
			if err := tx.Model(&booking.Booking{}).
				Where("id = ?", p.ReferenceID).
				Updates(map[string]interface{}{
					"payment_status": "paid",
					"status":         "confirmed",
					"updated_at":     now,
				}).Error; err != nil {
				return err
			}
		}

		// Credit vendor wallet (amount minus commission).
		v, err := s.vendorRepo.FindByID(ctx, p.VendorID)
		if err != nil || v == nil {
			return fmt.Errorf("vendor not found")
		}

		commissionAmount := p.Amount * (v.CommissionPct / 100)
		vendorAmount := p.Amount - commissionAmount

		wallet, err := s.paymentRepo.GetOrCreateWallet(ctx, p.VendorID)
		if err != nil {
			return err
		}

		desc := fmt.Sprintf("Payment for %s %s", p.PaymentType, p.ReferenceID.String())
		if err := s.paymentRepo.CreditWallet(ctx, tx, wallet.ID, vendorAmount, p.PaymentType, desc, p.ReferenceID); err != nil {
			return err
		}

		return nil
	})

	if txErr != nil {
		return nil, apperrors.Internal("failed to verify payment: " + txErr.Error())
	}

	// Re-fetch the updated payment.
	updated, err := s.paymentRepo.GetPayment(ctx, p.ID)
	if err != nil || updated == nil {
		return nil, apperrors.Internal("failed to retrieve updated payment")
	}

	return toPaymentResponse(updated), nil
}

// GetPayment retrieves a payment by its ID.
func (s *paymentService) GetPayment(ctx context.Context, paymentID uuid.UUID) (*PaymentResponse, error) {
	p, err := s.paymentRepo.GetPayment(ctx, paymentID)
	if err != nil {
		return nil, apperrors.Internal("failed to find payment")
	}
	if p == nil {
		return nil, apperrors.NotFound("payment not found")
	}
	return toPaymentResponse(p), nil
}

// GetWallet retrieves the wallet for the vendor associated with the given user.
func (s *paymentService) GetWallet(ctx context.Context, userID uuid.UUID) (*WalletResponse, error) {
	v, err := s.vendorRepo.FindByUserID(ctx, userID)
	if err != nil {
		return nil, apperrors.Internal("failed to look up vendor profile")
	}
	if v == nil {
		return nil, apperrors.Forbidden("user is not a vendor")
	}

	wallet, err := s.paymentRepo.GetOrCreateWallet(ctx, v.ID)
	if err != nil {
		return nil, apperrors.Internal("failed to get wallet")
	}

	return toWalletResponse(wallet), nil
}

// ListTransactions returns a paginated list of wallet transactions for the
// vendor associated with the given user.
func (s *paymentService) ListTransactions(ctx context.Context, userID uuid.UUID, params pagination.Params) (*pagination.Result[WalletTransactionResponse], error) {
	v, err := s.vendorRepo.FindByUserID(ctx, userID)
	if err != nil {
		return nil, apperrors.Internal("failed to look up vendor profile")
	}
	if v == nil {
		return nil, apperrors.Forbidden("user is not a vendor")
	}

	wallet, err := s.paymentRepo.GetOrCreateWallet(ctx, v.ID)
	if err != nil {
		return nil, apperrors.Internal("failed to get wallet")
	}

	result, err := s.paymentRepo.ListWalletTransactions(ctx, wallet.ID, params)
	if err != nil {
		return nil, apperrors.Internal("failed to list transactions")
	}

	return toWalletTransactionResultResponse(result), nil
}

// RequestPayout debits the vendor wallet and creates a payout transaction.
func (s *paymentService) RequestPayout(ctx context.Context, userID uuid.UUID, req PayoutRequest) (*WalletTransactionResponse, error) {
	v, err := s.vendorRepo.FindByUserID(ctx, userID)
	if err != nil {
		return nil, apperrors.Internal("failed to look up vendor profile")
	}
	if v == nil {
		return nil, apperrors.Forbidden("user is not a vendor")
	}

	wallet, err := s.paymentRepo.GetOrCreateWallet(ctx, v.ID)
	if err != nil {
		return nil, apperrors.Internal("failed to get wallet")
	}

	if wallet.Balance < req.Amount {
		return nil, apperrors.BadRequest("insufficient wallet balance")
	}

	txn, err := s.paymentRepo.CreatePayoutTransaction(ctx, wallet.ID, req.Amount)
	if err != nil {
		return nil, apperrors.Internal("failed to create payout: " + err.Error())
	}

	return toWalletTransactionResponse(txn), nil
}

// AdminListPayments returns a paginated list of all payments.
func (s *paymentService) AdminListPayments(ctx context.Context, params pagination.Params) (*pagination.Result[PaymentResponse], error) {
	result, err := s.paymentRepo.ListPayments(ctx, params)
	if err != nil {
		return nil, apperrors.Internal("failed to list payments")
	}
	return toPaymentResultResponse(result), nil
}

// AdminListPayouts returns a paginated list of all payout transactions.
// This searches for wallet transactions where reference_type = 'payout'.
func (s *paymentService) AdminListPayouts(ctx context.Context, params pagination.Params) (*pagination.Result[WalletTransactionResponse], error) {
	query := s.db.WithContext(ctx).Model(&WalletTransaction{}).Where("reference_type = ?", "payout")

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, apperrors.Internal("failed to count payouts")
	}

	var transactions []WalletTransaction
	if err := query.
		Order("created_at DESC").
		Offset(params.Offset()).
		Limit(params.PerPage).
		Find(&transactions).Error; err != nil {
		return nil, apperrors.Internal("failed to list payouts")
	}

	result := &pagination.Result[WalletTransaction]{
		Items: transactions,
		Total: total,
	}

	return toWalletTransactionResultResponse(result), nil
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// toPaymentResultResponse converts a pagination.Result[Payment] to
// pagination.Result[PaymentResponse].
func toPaymentResultResponse(result *pagination.Result[Payment]) *pagination.Result[PaymentResponse] {
	responses := make([]PaymentResponse, len(result.Items))
	for i := range result.Items {
		responses[i] = *toPaymentResponse(&result.Items[i])
	}
	return &pagination.Result[PaymentResponse]{
		Items: responses,
		Total: result.Total,
	}
}

// toWalletTransactionResultResponse converts a pagination.Result[WalletTransaction]
// to pagination.Result[WalletTransactionResponse].
func toWalletTransactionResultResponse(result *pagination.Result[WalletTransaction]) *pagination.Result[WalletTransactionResponse] {
	responses := make([]WalletTransactionResponse, len(result.Items))
	for i := range result.Items {
		responses[i] = *toWalletTransactionResponse(&result.Items[i])
	}
	return &pagination.Result[WalletTransactionResponse]{
		Items: responses,
		Total: result.Total,
	}
}
