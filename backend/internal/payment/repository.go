package payment

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"github.com/prabakarankannan/marketplace-backend/internal/common/pagination"
)

// PaymentRepository defines the data-access contract for the payment module.
type PaymentRepository interface {
	// Payment operations
	CreatePayment(ctx context.Context, payment *Payment) error
	GetPayment(ctx context.Context, id uuid.UUID) (*Payment, error)
	GetPaymentByRazorpayOrderID(ctx context.Context, razorpayOrderID string) (*Payment, error)
	UpdatePayment(ctx context.Context, payment *Payment) error
	ListPayments(ctx context.Context, params pagination.Params) (*pagination.Result[Payment], error)
	ListByCustomer(ctx context.Context, customerID uuid.UUID, params pagination.Params) (*pagination.Result[Payment], error)
	ListByVendor(ctx context.Context, vendorID uuid.UUID, params pagination.Params) (*pagination.Result[Payment], error)

	// Wallet operations
	GetOrCreateWallet(ctx context.Context, vendorID uuid.UUID) (*Wallet, error)
	GetOrCreateDeliveryWallet(ctx context.Context, deliveryPartnerID uuid.UUID) (*Wallet, error)
	GetWallet(ctx context.Context, vendorID uuid.UUID) (*Wallet, error)
	CreditWallet(ctx context.Context, tx *gorm.DB, walletID uuid.UUID, amount float64, refType, description string, refID uuid.UUID) error
	DebitWallet(ctx context.Context, tx *gorm.DB, walletID uuid.UUID, amount float64, refType, description string, refID uuid.UUID) error
	ListWalletTransactions(ctx context.Context, walletID uuid.UUID, params pagination.Params) (*pagination.Result[WalletTransaction], error)
	CreatePayoutTransaction(ctx context.Context, walletID uuid.UUID, amount float64) (*WalletTransaction, error)

	// DB returns the underlying *gorm.DB for transaction support.
	DB() *gorm.DB
}

// paymentRepository is the GORM-backed implementation of PaymentRepository.
type paymentRepository struct {
	db *gorm.DB
}

// NewPaymentRepository returns a new PaymentRepository backed by the provided GORM DB.
func NewPaymentRepository(db *gorm.DB) PaymentRepository {
	return &paymentRepository{db: db}
}

// DB returns the underlying *gorm.DB.
func (r *paymentRepository) DB() *gorm.DB {
	return r.db
}

// ---------------------------------------------------------------------------
// Payment operations
// ---------------------------------------------------------------------------

// CreatePayment inserts a new payment record.
func (r *paymentRepository) CreatePayment(ctx context.Context, payment *Payment) error {
	if payment.ID == uuid.Nil {
		payment.ID = uuid.New()
	}
	now := time.Now()
	payment.CreatedAt = now
	payment.UpdatedAt = now
	return r.db.WithContext(ctx).Create(payment).Error
}

// GetPayment retrieves a payment by its primary key.
func (r *paymentRepository) GetPayment(ctx context.Context, id uuid.UUID) (*Payment, error) {
	var p Payment
	if err := r.db.WithContext(ctx).Where("id = ?", id).First(&p).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &p, nil
}

// GetPaymentByRazorpayOrderID retrieves a payment by its Razorpay order ID.
func (r *paymentRepository) GetPaymentByRazorpayOrderID(ctx context.Context, razorpayOrderID string) (*Payment, error) {
	var p Payment
	if err := r.db.WithContext(ctx).Where("razorpay_order_id = ?", razorpayOrderID).First(&p).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &p, nil
}

// UpdatePayment saves all fields of the payment back to the database.
func (r *paymentRepository) UpdatePayment(ctx context.Context, payment *Payment) error {
	payment.UpdatedAt = time.Now()
	return r.db.WithContext(ctx).Save(payment).Error
}

// ListPayments returns a paginated list of all payments.
func (r *paymentRepository) ListPayments(ctx context.Context, params pagination.Params) (*pagination.Result[Payment], error) {
	query := r.db.WithContext(ctx).Model(&Payment{})

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}

	var payments []Payment
	if err := query.
		Order("created_at DESC").
		Offset(params.Offset()).
		Limit(params.PerPage).
		Find(&payments).Error; err != nil {
		return nil, err
	}

	return &pagination.Result[Payment]{
		Items: payments,
		Total: total,
	}, nil
}

// ListByCustomer returns a paginated list of payments for a customer.
func (r *paymentRepository) ListByCustomer(ctx context.Context, customerID uuid.UUID, params pagination.Params) (*pagination.Result[Payment], error) {
	query := r.db.WithContext(ctx).Model(&Payment{}).Where("customer_id = ?", customerID)

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}

	var payments []Payment
	if err := query.
		Order("created_at DESC").
		Offset(params.Offset()).
		Limit(params.PerPage).
		Find(&payments).Error; err != nil {
		return nil, err
	}

	return &pagination.Result[Payment]{
		Items: payments,
		Total: total,
	}, nil
}

// ListByVendor returns a paginated list of payments for a vendor.
func (r *paymentRepository) ListByVendor(ctx context.Context, vendorID uuid.UUID, params pagination.Params) (*pagination.Result[Payment], error) {
	query := r.db.WithContext(ctx).Model(&Payment{}).Where("vendor_id = ?", vendorID)

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}

	var payments []Payment
	if err := query.
		Order("created_at DESC").
		Offset(params.Offset()).
		Limit(params.PerPage).
		Find(&payments).Error; err != nil {
		return nil, err
	}

	return &pagination.Result[Payment]{
		Items: payments,
		Total: total,
	}, nil
}

// ---------------------------------------------------------------------------
// Wallet operations
// ---------------------------------------------------------------------------

// GetOrCreateWallet retrieves the wallet for a vendor, creating one if it
// does not yet exist.
func (r *paymentRepository) GetOrCreateWallet(ctx context.Context, vendorID uuid.UUID) (*Wallet, error) {
	var w Wallet
	if err := r.db.WithContext(ctx).Where("vendor_id = ?", vendorID).First(&w).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			w = Wallet{
				ID:       uuid.New(),
				VendorID: &vendorID,
				Balance:  0,
			}
			now := time.Now()
			w.CreatedAt = now
			w.UpdatedAt = now
			if err := r.db.WithContext(ctx).Create(&w).Error; err != nil {
				return nil, err
			}
			return &w, nil
		}
		return nil, err
	}
	return &w, nil
}

// GetOrCreateDeliveryWallet retrieves the wallet for a delivery partner,
// creating one if it does not yet exist.
func (r *paymentRepository) GetOrCreateDeliveryWallet(ctx context.Context, deliveryPartnerID uuid.UUID) (*Wallet, error) {
	var w Wallet
	if err := r.db.WithContext(ctx).Where("delivery_partner_id = ?", deliveryPartnerID).First(&w).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			w = Wallet{
				ID:                uuid.New(),
				DeliveryPartnerID: &deliveryPartnerID,
				Balance:           0,
			}
			now := time.Now()
			w.CreatedAt = now
			w.UpdatedAt = now
			if err := r.db.WithContext(ctx).Create(&w).Error; err != nil {
				return nil, err
			}
			return &w, nil
		}
		return nil, err
	}
	return &w, nil
}

// GetWallet retrieves the wallet for a vendor.
func (r *paymentRepository) GetWallet(ctx context.Context, vendorID uuid.UUID) (*Wallet, error) {
	var w Wallet
	if err := r.db.WithContext(ctx).Where("vendor_id = ?", vendorID).First(&w).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &w, nil
}

// CreditWallet credits the wallet within the given transaction. It updates
// the balance and total_earned, then creates a wallet_transaction record.
func (r *paymentRepository) CreditWallet(ctx context.Context, tx *gorm.DB, walletID uuid.UUID, amount float64, refType, description string, refID uuid.UUID) error {
	// Update wallet balance and total_earned.
	if err := tx.WithContext(ctx).
		Model(&Wallet{}).
		Where("id = ?", walletID).
		Updates(map[string]interface{}{
			"balance":      gorm.Expr("balance + ?", amount),
			"total_earned": gorm.Expr("total_earned + ?", amount),
			"updated_at":   time.Now(),
		}).Error; err != nil {
		return err
	}

	// Fetch updated balance for the transaction record.
	var wallet Wallet
	if err := tx.WithContext(ctx).Where("id = ?", walletID).First(&wallet).Error; err != nil {
		return err
	}

	txn := WalletTransaction{
		ID:            uuid.New(),
		WalletID:      walletID,
		Type:          "credit",
		Amount:        amount,
		BalanceAfter:  wallet.Balance,
		ReferenceType: &refType,
		ReferenceID:   &refID,
		Description:   description,
		Status:        "completed",
		CreatedAt:     time.Now(),
	}

	return tx.WithContext(ctx).Create(&txn).Error
}

// DebitWallet debits the wallet within the given transaction. It checks that
// the balance is sufficient, updates the balance and total_withdrawn, then
// creates a wallet_transaction record.
func (r *paymentRepository) DebitWallet(ctx context.Context, tx *gorm.DB, walletID uuid.UUID, amount float64, refType, description string, refID uuid.UUID) error {
	// Check current balance.
	var wallet Wallet
	if err := tx.WithContext(ctx).Where("id = ?", walletID).First(&wallet).Error; err != nil {
		return err
	}
	if wallet.Balance < amount {
		return fmt.Errorf("insufficient wallet balance")
	}

	// Update wallet balance and total_withdrawn.
	if err := tx.WithContext(ctx).
		Model(&Wallet{}).
		Where("id = ?", walletID).
		Updates(map[string]interface{}{
			"balance":         gorm.Expr("balance - ?", amount),
			"total_withdrawn": gorm.Expr("total_withdrawn + ?", amount),
			"updated_at":      time.Now(),
		}).Error; err != nil {
		return err
	}

	// Fetch updated balance.
	if err := tx.WithContext(ctx).Where("id = ?", walletID).First(&wallet).Error; err != nil {
		return err
	}

	txn := WalletTransaction{
		ID:            uuid.New(),
		WalletID:      walletID,
		Type:          "debit",
		Amount:        amount,
		BalanceAfter:  wallet.Balance,
		ReferenceType: &refType,
		ReferenceID:   &refID,
		Description:   description,
		Status:        "completed",
		CreatedAt:     time.Now(),
	}

	return tx.WithContext(ctx).Create(&txn).Error
}

// ListWalletTransactions returns a paginated list of transactions for a wallet.
func (r *paymentRepository) ListWalletTransactions(ctx context.Context, walletID uuid.UUID, params pagination.Params) (*pagination.Result[WalletTransaction], error) {
	query := r.db.WithContext(ctx).Model(&WalletTransaction{}).Where("wallet_id = ?", walletID)

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}

	var transactions []WalletTransaction
	if err := query.
		Order("created_at DESC").
		Offset(params.Offset()).
		Limit(params.PerPage).
		Find(&transactions).Error; err != nil {
		return nil, err
	}

	return &pagination.Result[WalletTransaction]{
		Items: transactions,
		Total: total,
	}, nil
}

// CreatePayoutTransaction debits the wallet and creates a payout transaction.
func (r *paymentRepository) CreatePayoutTransaction(ctx context.Context, walletID uuid.UUID, amount float64) (*WalletTransaction, error) {
	var txn *WalletTransaction

	err := r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		// Check balance.
		var wallet Wallet
		if err := tx.Where("id = ?", walletID).First(&wallet).Error; err != nil {
			return err
		}
		if wallet.Balance < amount {
			return fmt.Errorf("insufficient wallet balance")
		}

		// Update wallet.
		if err := tx.
			Model(&Wallet{}).
			Where("id = ?", walletID).
			Updates(map[string]interface{}{
				"balance":         gorm.Expr("balance - ?", amount),
				"total_withdrawn": gorm.Expr("total_withdrawn + ?", amount),
				"updated_at":      time.Now(),
			}).Error; err != nil {
			return err
		}

		// Fetch updated balance.
		if err := tx.Where("id = ?", walletID).First(&wallet).Error; err != nil {
			return err
		}

		payoutType := "payout"
		t := WalletTransaction{
			ID:            uuid.New(),
			WalletID:      walletID,
			Type:          "debit",
			Amount:        amount,
			BalanceAfter:  wallet.Balance,
			ReferenceType: &payoutType,
			Description:   "Payout request",
			Status:        "pending",
			CreatedAt:     time.Now(),
		}

		if err := tx.Create(&t).Error; err != nil {
			return err
		}

		txn = &t
		return nil
	})

	if err != nil {
		return nil, err
	}

	return txn, nil
}
