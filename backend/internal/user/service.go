package user

import (
	"context"

	"github.com/google/uuid"

	"github.com/prabakarankannan/marketplace-backend/internal/auth"
)

// UserService defines the business-logic contract for user operations.
type UserService interface {
	GetProfile(ctx context.Context, userID uuid.UUID) (*auth.User, error)
	UpdateProfile(ctx context.Context, userID uuid.UUID, req UpdateProfileRequest) error
	UpdateFCMToken(ctx context.Context, userID uuid.UUID, token string) error
	DeactivateAccount(ctx context.Context, userID uuid.UUID) error
	ListAddresses(ctx context.Context, userID uuid.UUID) ([]AddressResponse, error)
	AddAddress(ctx context.Context, userID uuid.UUID, req AddressRequest) (*AddressResponse, error)
	UpdateAddress(ctx context.Context, userID uuid.UUID, addressID uuid.UUID, req AddressRequest) (*AddressResponse, error)
	DeleteAddress(ctx context.Context, userID uuid.UUID, addressID uuid.UUID) error
	SetDefaultAddress(ctx context.Context, userID uuid.UUID, addressID uuid.UUID) error
}

// userService is the default implementation of UserService.
type userService struct {
	repo UserRepository
}

// NewUserService creates a new UserService with the given repository.
func NewUserService(repo UserRepository) UserService {
	return &userService{repo: repo}
}

func (s *userService) GetProfile(ctx context.Context, userID uuid.UUID) (*auth.User, error) {
	return s.repo.GetProfile(ctx, userID)
}

func (s *userService) UpdateProfile(ctx context.Context, userID uuid.UUID, req UpdateProfileRequest) error {
	return s.repo.UpdateProfile(ctx, userID, req.FullName, req.AvatarURL)
}

func (s *userService) UpdateFCMToken(ctx context.Context, userID uuid.UUID, token string) error {
	return s.repo.UpdateFCMToken(ctx, userID, token)
}

func (s *userService) DeactivateAccount(ctx context.Context, userID uuid.UUID) error {
	return s.repo.DeactivateAccount(ctx, userID)
}

func (s *userService) ListAddresses(ctx context.Context, userID uuid.UUID) ([]AddressResponse, error) {
	addresses, err := s.repo.ListAddresses(ctx, userID)
	if err != nil {
		return nil, err
	}

	result := make([]AddressResponse, 0, len(addresses))
	for i := range addresses {
		result = append(result, *toResponse(&addresses[i]))
	}
	return result, nil
}

func (s *userService) AddAddress(ctx context.Context, userID uuid.UUID, req AddressRequest) (*AddressResponse, error) {
	address := &Address{
		ID:          uuid.New(),
		UserID:      userID,
		Label:       req.Label,
		FullAddress: req.FullAddress,
		Landmark:    req.Landmark,
		City:        req.City,
		State:       req.State,
		Pincode:     req.Pincode,
		Latitude:    req.Latitude,
		Longitude:   req.Longitude,
	}

	if err := s.repo.CreateAddress(ctx, address); err != nil {
		return nil, err
	}
	return toResponse(address), nil
}

func (s *userService) UpdateAddress(ctx context.Context, userID uuid.UUID, addressID uuid.UUID, req AddressRequest) (*AddressResponse, error) {
	// Verify the address exists and belongs to the user.
	existing, err := s.repo.GetAddress(ctx, userID, addressID)
	if err != nil {
		return nil, err
	}

	existing.Label = req.Label
	existing.FullAddress = req.FullAddress
	existing.Landmark = req.Landmark
	existing.City = req.City
	existing.State = req.State
	existing.Pincode = req.Pincode
	existing.Latitude = req.Latitude
	existing.Longitude = req.Longitude

	if err := s.repo.UpdateAddress(ctx, existing); err != nil {
		return nil, err
	}
	return toResponse(existing), nil
}

func (s *userService) DeleteAddress(ctx context.Context, userID uuid.UUID, addressID uuid.UUID) error {
	return s.repo.DeleteAddress(ctx, userID, addressID)
}

func (s *userService) SetDefaultAddress(ctx context.Context, userID uuid.UUID, addressID uuid.UUID) error {
	return s.repo.SetDefaultAddress(ctx, userID, addressID)
}
