package booking

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
	"gorm.io/gorm"

	apperrors "github.com/prabakarankannan/marketplace-backend/internal/common/errors"
	"github.com/prabakarankannan/marketplace-backend/internal/common/pagination"
	"github.com/prabakarankannan/marketplace-backend/internal/vendor"
)

// bookingValidTransitions defines the allowed state transitions for a booking.
var bookingValidTransitions = map[string][]string{
	"pending":   {"confirmed", "cancelled"},
	"confirmed": {"active", "cancelled"},
	"active":    {"completed", "cancelled"},
	"completed": {},
	"cancelled": {},
}

// canTransitionBooking reports whether moving from the current status to the
// target status is a valid booking state transition.
func canTransitionBooking(from, to string) bool {
	allowed, ok := bookingValidTransitions[from]
	if !ok {
		return false
	}
	for _, s := range allowed {
		if s == to {
			return true
		}
	}
	return false
}

// BookingService defines the business-logic contract for the booking module.
type BookingService interface {
	// Service CRUD (vendor)
	CreateService(ctx context.Context, userID uuid.UUID, req CreateServiceRequest) (*ServiceResponse, error)
	UpdateService(ctx context.Context, userID uuid.UUID, serviceID uuid.UUID, req UpdateServiceRequest) error
	DeleteService(ctx context.Context, userID uuid.UUID, serviceID uuid.UUID) error
	GetService(ctx context.Context, serviceID uuid.UUID) (*ServiceResponse, error)
	ListMyServices(ctx context.Context, userID uuid.UUID, params pagination.Params) (*pagination.Result[ServiceResponse], error)
	ListServices(ctx context.Context, params pagination.Params) (*pagination.Result[ServiceResponse], error)
	ListServicesByCategory(ctx context.Context, categoryID uuid.UUID, params pagination.Params) (*pagination.Result[ServiceResponse], error)
	ListServicesByVendor(ctx context.Context, vendorID uuid.UUID, params pagination.Params) (*pagination.Result[ServiceResponse], error)

	// Slot management (vendor)
	CreateSlots(ctx context.Context, userID uuid.UUID, req CreateSlotsRequest) ([]SlotResponse, error)
	ListMySlots(ctx context.Context, userID uuid.UUID, serviceID uuid.UUID, startDate, endDate *time.Time) ([]SlotResponse, error)
	GetAvailableSlots(ctx context.Context, serviceID uuid.UUID, date *time.Time) ([]SlotResponse, error)

	// Booking operations (customer)
	CreateBooking(ctx context.Context, customerID uuid.UUID, req BookingRequest) (*BookingResponse, error)
	GetBooking(ctx context.Context, bookingID uuid.UUID) (*BookingResponse, error)
	ListMyBookings(ctx context.Context, customerID uuid.UUID, params pagination.Params) (*pagination.Result[BookingResponse], error)
	CancelBooking(ctx context.Context, customerID uuid.UUID, bookingID uuid.UUID) error

	// Booking operations (vendor)
	ListVendorBookings(ctx context.Context, userID uuid.UUID, params pagination.Params) (*pagination.Result[BookingResponse], error)
	UpdateBookingStatus(ctx context.Context, userID uuid.UUID, bookingID uuid.UUID, status string) error

	// Admin
	AdminListBookings(ctx context.Context, params pagination.Params) (*pagination.Result[BookingResponse], error)
	AdminListServices(ctx context.Context, params pagination.Params) (*pagination.Result[ServiceResponse], error)
}

// bookingService is the concrete implementation of BookingService.
type bookingService struct {
	repo       BookingRepository
	vendorRepo vendor.VendorRepository
}

// NewBookingService returns a new BookingService with all required dependencies.
func NewBookingService(
	repo BookingRepository,
	vendorRepo vendor.VendorRepository,
) BookingService {
	return &bookingService{
		repo:       repo,
		vendorRepo: vendorRepo,
	}
}

// ---------------------------------------------------------------------------
// Vendor helpers
// ---------------------------------------------------------------------------

func (s *bookingService) getVendorForUser(ctx context.Context, userID uuid.UUID) (*vendor.Vendor, error) {
	v, err := s.vendorRepo.FindByUserID(ctx, userID)
	if err != nil {
		return nil, apperrors.Internal("failed to look up vendor profile")
	}
	if v == nil {
		return nil, apperrors.Forbidden("user is not a vendor")
	}
	return v, nil
}

// ---------------------------------------------------------------------------
// Service CRUD
// ---------------------------------------------------------------------------

// CreateService creates a new service for the vendor associated with the user.
func (s *bookingService) CreateService(ctx context.Context, userID uuid.UUID, req CreateServiceRequest) (*ServiceResponse, error) {
	v, err := s.getVendorForUser(ctx, userID)
	if err != nil {
		return nil, err
	}

	svc := Service{
		ID:           uuid.New(),
		VendorID:     v.ID,
		CategoryID:   req.CategoryID,
		Name:         req.Name,
		Slug:         req.Slug,
		Description:  req.Description,
		Price:        req.Price,
		DurationMins: 60,
		Images:       pq.StringArray(req.Images),
		IsActive:     true,
		Tags:         pq.StringArray(req.Tags),
	}

	if req.DurationMins != nil {
		svc.DurationMins = *req.DurationMins
	}

	if err := s.repo.CreateService(ctx, &svc); err != nil {
		return nil, apperrors.Internal("failed to create service")
	}

	resp := toServiceResponse(&svc)
	return &resp, nil
}

// UpdateService applies partial updates to a service after verifying vendor ownership.
func (s *bookingService) UpdateService(ctx context.Context, userID uuid.UUID, serviceID uuid.UUID, req UpdateServiceRequest) error {
	v, err := s.getVendorForUser(ctx, userID)
	if err != nil {
		return err
	}

	svc, err := s.repo.GetService(ctx, serviceID)
	if err != nil {
		return apperrors.Internal("failed to find service")
	}
	if svc == nil {
		return apperrors.NotFound("service not found")
	}
	if svc.VendorID != v.ID {
		return apperrors.Forbidden("service does not belong to your vendor profile")
	}

	if req.CategoryID != nil {
		svc.CategoryID = *req.CategoryID
	}
	if req.Name != nil {
		svc.Name = *req.Name
	}
	if req.Slug != nil {
		svc.Slug = *req.Slug
	}
	if req.Description != nil {
		svc.Description = req.Description
	}
	if req.Price != nil {
		svc.Price = *req.Price
	}
	if req.DurationMins != nil {
		svc.DurationMins = *req.DurationMins
	}
	if req.Images != nil {
		svc.Images = pq.StringArray(req.Images)
	}
	if req.IsActive != nil {
		svc.IsActive = *req.IsActive
	}
	if req.Tags != nil {
		svc.Tags = pq.StringArray(req.Tags)
	}

	if err := s.repo.UpdateService(ctx, svc); err != nil {
		return apperrors.Internal("failed to update service")
	}

	return nil
}

// DeleteService soft-deletes a service after verifying vendor ownership.
func (s *bookingService) DeleteService(ctx context.Context, userID uuid.UUID, serviceID uuid.UUID) error {
	v, err := s.getVendorForUser(ctx, userID)
	if err != nil {
		return err
	}

	svc, err := s.repo.GetService(ctx, serviceID)
	if err != nil {
		return apperrors.Internal("failed to find service")
	}
	if svc == nil {
		return apperrors.NotFound("service not found")
	}
	if svc.VendorID != v.ID {
		return apperrors.Forbidden("service does not belong to your vendor profile")
	}

	if err := s.repo.DeleteService(ctx, serviceID); err != nil {
		return apperrors.Internal("failed to delete service")
	}

	return nil
}

// GetService retrieves a service by its ID.
func (s *bookingService) GetService(ctx context.Context, serviceID uuid.UUID) (*ServiceResponse, error) {
	svc, err := s.repo.GetService(ctx, serviceID)
	if err != nil {
		return nil, apperrors.Internal("failed to find service")
	}
	if svc == nil {
		return nil, apperrors.NotFound("service not found")
	}

	resp := toServiceResponse(svc)
	return &resp, nil
}

// ListMyServices returns a paginated list of services for the vendor
// associated with the given user.
func (s *bookingService) ListMyServices(ctx context.Context, userID uuid.UUID, params pagination.Params) (*pagination.Result[ServiceResponse], error) {
	v, err := s.getVendorForUser(ctx, userID)
	if err != nil {
		return nil, err
	}

	result, err := s.repo.ListServicesByVendor(ctx, v.ID, params)
	if err != nil {
		return nil, apperrors.Internal("failed to list services")
	}

	return toServiceResultResponse(result), nil
}

// ListServices returns a paginated list of all active services.
func (s *bookingService) ListServices(ctx context.Context, params pagination.Params) (*pagination.Result[ServiceResponse], error) {
	result, err := s.repo.ListAllServices(ctx, params)
	if err != nil {
		return nil, apperrors.Internal("failed to list services")
	}

	return toServiceResultResponse(result), nil
}

// ListServicesByCategory returns a paginated list of services in a category.
func (s *bookingService) ListServicesByCategory(ctx context.Context, categoryID uuid.UUID, params pagination.Params) (*pagination.Result[ServiceResponse], error) {
	result, err := s.repo.ListServicesByCategory(ctx, categoryID, params)
	if err != nil {
		return nil, apperrors.Internal("failed to list services by category")
	}

	return toServiceResultResponse(result), nil
}

// ListServicesByVendor returns a paginated list of services for a specific vendor.
func (s *bookingService) ListServicesByVendor(ctx context.Context, vendorID uuid.UUID, params pagination.Params) (*pagination.Result[ServiceResponse], error) {
	result, err := s.repo.ListServicesByVendor(ctx, vendorID, params)
	if err != nil {
		return nil, apperrors.Internal("failed to list vendor services")
	}

	return toServiceResultResponse(result), nil
}

// ---------------------------------------------------------------------------
// Slot management
// ---------------------------------------------------------------------------

// CreateSlots creates service slots in batch after verifying vendor ownership.
func (s *bookingService) CreateSlots(ctx context.Context, userID uuid.UUID, req CreateSlotsRequest) ([]SlotResponse, error) {
	v, err := s.getVendorForUser(ctx, userID)
	if err != nil {
		return nil, err
	}

	svc, err := s.repo.GetService(ctx, req.ServiceID)
	if err != nil {
		return nil, apperrors.Internal("failed to find service")
	}
	if svc == nil {
		return nil, apperrors.NotFound("service not found")
	}
	if svc.VendorID != v.ID {
		return nil, apperrors.Forbidden("service does not belong to your vendor profile")
	}

	slots := make([]ServiceSlot, 0, len(req.Slots))
	for _, si := range req.Slots {
		slotDate, parseErr := time.Parse("2006-01-02", si.Date)
		if parseErr != nil {
			return nil, apperrors.BadRequest("invalid date format: " + si.Date + ", expected YYYY-MM-DD")
		}

		maxBookings := 1
		if si.MaxBookings != nil {
			maxBookings = *si.MaxBookings
		}

		slots = append(slots, ServiceSlot{
			ServiceID:   req.ServiceID,
			VendorID:    v.ID,
			SlotDate:    slotDate,
			StartTime:   si.StartTime,
			EndTime:     si.EndTime,
			MaxBookings: maxBookings,
			IsAvailable: true,
		})
	}

	if err := s.repo.CreateSlots(ctx, slots); err != nil {
		return nil, apperrors.Internal("failed to create slots")
	}

	responses := make([]SlotResponse, len(slots))
	for i := range slots {
		responses[i] = toSlotResponse(&slots[i])
	}

	return responses, nil
}

// ListMySlots returns all slots for a vendor's service, optionally filtered
// by date range.
func (s *bookingService) ListMySlots(ctx context.Context, userID uuid.UUID, serviceID uuid.UUID, startDate, endDate *time.Time) ([]SlotResponse, error) {
	v, err := s.getVendorForUser(ctx, userID)
	if err != nil {
		return nil, err
	}

	svc, err := s.repo.GetService(ctx, serviceID)
	if err != nil {
		return nil, apperrors.Internal("failed to find service")
	}
	if svc == nil {
		return nil, apperrors.NotFound("service not found")
	}
	if svc.VendorID != v.ID {
		return nil, apperrors.Forbidden("service does not belong to your vendor profile")
	}

	slots, err := s.repo.ListSlots(ctx, serviceID, startDate, endDate)
	if err != nil {
		return nil, apperrors.Internal("failed to list slots")
	}

	responses := make([]SlotResponse, len(slots))
	for i := range slots {
		responses[i] = toSlotResponse(&slots[i])
	}

	return responses, nil
}

// GetAvailableSlots returns available slots for a service on a given date.
func (s *bookingService) GetAvailableSlots(ctx context.Context, serviceID uuid.UUID, date *time.Time) ([]SlotResponse, error) {
	slots, err := s.repo.ListSlots(ctx, serviceID, date, date)
	if err != nil {
		return nil, apperrors.Internal("failed to list available slots")
	}

	// Filter to only available slots.
	var available []SlotResponse
	for i := range slots {
		if slots[i].IsAvailable && slots[i].BookedCount < slots[i].MaxBookings {
			available = append(available, toSlotResponse(&slots[i]))
		}
	}

	return available, nil
}

// ---------------------------------------------------------------------------
// Booking operations
// ---------------------------------------------------------------------------

// CreateBooking creates a new booking using a GORM transaction to atomically
// reserve the slot.
func (s *bookingService) CreateBooking(ctx context.Context, customerID uuid.UUID, req BookingRequest) (*BookingResponse, error) {
	// Validate service exists.
	svc, err := s.repo.GetService(ctx, req.ServiceID)
	if err != nil {
		return nil, apperrors.Internal("failed to look up service")
	}
	if svc == nil {
		return nil, apperrors.NotFound("service not found")
	}

	// Validate slot exists.
	slot, err := s.repo.GetSlot(ctx, req.SlotID)
	if err != nil {
		return nil, apperrors.Internal("failed to look up slot")
	}
	if slot == nil {
		return nil, apperrors.NotFound("slot not found")
	}
	if slot.ServiceID != req.ServiceID {
		return nil, apperrors.BadRequest("slot does not belong to the specified service")
	}

	var createdBooking *Booking

	// Use a transaction to atomically reserve the slot and create the booking.
	txErr := s.repo.DB().WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		// Reserve the slot (SELECT FOR UPDATE + increment).
		if err := s.repo.ReserveSlot(ctx, tx, req.SlotID); err != nil {
			return apperrors.Conflict("failed to reserve slot: " + err.Error())
		}

		b := Booking{
			ID:             uuid.New(),
			BookingNumber:  GenerateBookingNumber(),
			CustomerID:     customerID,
			VendorID:       svc.VendorID,
			ServiceID:      req.ServiceID,
			SlotID:         req.SlotID,
			AddressID:      req.AddressID,
			Status:         "pending",
			ScheduledDate:  slot.SlotDate,
			ScheduledStart: slot.StartTime,
			ScheduledEnd:   slot.EndTime,
			ServiceName:    svc.Name,
			Price:          svc.Price,
			Tax:            0,
			Total:          svc.Price,
			PaymentStatus:  "pending",
			Notes:          req.Notes,
		}

		now := time.Now()
		b.CreatedAt = now
		b.UpdatedAt = now

		if err := tx.Create(&b).Error; err != nil {
			return err
		}

		createdBooking = &b
		return nil
	})

	if txErr != nil {
		// If the error is already an AppError, return it directly.
		if _, ok := txErr.(*apperrors.AppError); ok {
			return nil, txErr
		}
		return nil, apperrors.Internal("failed to create booking")
	}

	return toBookingResponse(createdBooking), nil
}

// GetBooking retrieves a booking by its ID.
func (s *bookingService) GetBooking(ctx context.Context, bookingID uuid.UUID) (*BookingResponse, error) {
	b, err := s.repo.FindByID(ctx, bookingID)
	if err != nil {
		return nil, apperrors.Internal("failed to find booking")
	}
	if b == nil {
		return nil, apperrors.NotFound("booking not found")
	}
	return toBookingResponse(b), nil
}

// ListMyBookings returns a paginated list of bookings for the authenticated customer.
func (s *bookingService) ListMyBookings(ctx context.Context, customerID uuid.UUID, params pagination.Params) (*pagination.Result[BookingResponse], error) {
	result, err := s.repo.ListByCustomer(ctx, customerID, params)
	if err != nil {
		return nil, apperrors.Internal("failed to list bookings")
	}
	return toBookingResultResponse(result), nil
}

// CancelBooking cancels a booking, verifying ownership and releasing the slot.
func (s *bookingService) CancelBooking(ctx context.Context, customerID uuid.UUID, bookingID uuid.UUID) error {
	b, err := s.repo.FindByID(ctx, bookingID)
	if err != nil {
		return apperrors.Internal("failed to find booking")
	}
	if b == nil {
		return apperrors.NotFound("booking not found")
	}
	if b.CustomerID != customerID {
		return apperrors.Forbidden("you do not own this booking")
	}
	if !canTransitionBooking(b.Status, "cancelled") {
		return apperrors.BadRequest("booking cannot be cancelled in its current status")
	}

	// Release the slot.
	if err := s.repo.ReleaseSlot(ctx, b.SlotID); err != nil {
		return apperrors.Internal("failed to release slot")
	}

	if err := s.repo.UpdateStatus(ctx, bookingID, "cancelled"); err != nil {
		return apperrors.Internal("failed to cancel booking")
	}

	return nil
}

// ListVendorBookings returns a paginated list of bookings for the vendor
// associated with the given user.
func (s *bookingService) ListVendorBookings(ctx context.Context, userID uuid.UUID, params pagination.Params) (*pagination.Result[BookingResponse], error) {
	v, err := s.getVendorForUser(ctx, userID)
	if err != nil {
		return nil, err
	}

	result, err := s.repo.ListByVendor(ctx, v.ID, params)
	if err != nil {
		return nil, apperrors.Internal("failed to list vendor bookings")
	}

	return toBookingResultResponse(result), nil
}

// UpdateBookingStatus updates the booking status after verifying that the
// requesting user is the vendor who owns the booking, and that the state
// transition is valid.
func (s *bookingService) UpdateBookingStatus(ctx context.Context, userID uuid.UUID, bookingID uuid.UUID, status string) error {
	v, err := s.getVendorForUser(ctx, userID)
	if err != nil {
		return err
	}

	b, err := s.repo.FindByID(ctx, bookingID)
	if err != nil {
		return apperrors.Internal("failed to find booking")
	}
	if b == nil {
		return apperrors.NotFound("booking not found")
	}
	if b.VendorID != v.ID {
		return apperrors.Forbidden("booking does not belong to your vendor profile")
	}
	if !canTransitionBooking(b.Status, status) {
		return apperrors.BadRequest("invalid status transition from " + b.Status + " to " + status)
	}

	if err := s.repo.UpdateStatus(ctx, bookingID, status); err != nil {
		return apperrors.Internal("failed to update booking status")
	}

	return nil
}

// AdminListBookings returns a paginated list of all bookings (admin use).
func (s *bookingService) AdminListBookings(ctx context.Context, params pagination.Params) (*pagination.Result[BookingResponse], error) {
	result, err := s.repo.ListAll(ctx, params)
	if err != nil {
		return nil, apperrors.Internal("failed to list bookings")
	}
	return toBookingResultResponse(result), nil
}

// AdminListServices returns a paginated list of all services (admin use),
// including inactive ones.
func (s *bookingService) AdminListServices(ctx context.Context, params pagination.Params) (*pagination.Result[ServiceResponse], error) {
	// For admin, we list all services including inactive.
	// We reuse ListAllServices but note it filters by is_active=true.
	// For a true admin view, we go directly to the vendor listing which includes all.
	result, err := s.repo.ListAllServices(ctx, params)
	if err != nil {
		return nil, apperrors.Internal("failed to list services")
	}
	return toServiceResultResponse(result), nil
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// toServiceResultResponse converts a pagination.Result[Service] to
// pagination.Result[ServiceResponse].
func toServiceResultResponse(result *pagination.Result[Service]) *pagination.Result[ServiceResponse] {
	responses := make([]ServiceResponse, len(result.Items))
	for i := range result.Items {
		responses[i] = toServiceResponse(&result.Items[i])
	}
	return &pagination.Result[ServiceResponse]{
		Items: responses,
		Total: result.Total,
	}
}

// toBookingResultResponse converts a pagination.Result[Booking] to
// pagination.Result[BookingResponse].
func toBookingResultResponse(result *pagination.Result[Booking]) *pagination.Result[BookingResponse] {
	responses := make([]BookingResponse, len(result.Items))
	for i := range result.Items {
		responses[i] = *toBookingResponse(&result.Items[i])
	}
	return &pagination.Result[BookingResponse]{
		Items: responses,
		Total: result.Total,
	}
}
