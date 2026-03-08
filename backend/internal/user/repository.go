package user

import (
	"context"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"github.com/prabakarankannan/marketplace-backend/internal/auth"
	apperrors "github.com/prabakarankannan/marketplace-backend/internal/common/errors"
)

// UserRepository defines the data-access contract for user and address operations.
type UserRepository interface {
	GetProfile(ctx context.Context, userID uuid.UUID) (*auth.User, error)
	UpdateProfile(ctx context.Context, userID uuid.UUID, name, avatarURL *string) error
	UpdateFCMToken(ctx context.Context, userID uuid.UUID, token string) error
	DeactivateAccount(ctx context.Context, userID uuid.UUID) error
	ListAddresses(ctx context.Context, userID uuid.UUID) ([]Address, error)
	CreateAddress(ctx context.Context, address *Address) error
	UpdateAddress(ctx context.Context, address *Address) error
	DeleteAddress(ctx context.Context, userID, addressID uuid.UUID) error
	SetDefaultAddress(ctx context.Context, userID, addressID uuid.UUID) error
	GetAddress(ctx context.Context, userID, addressID uuid.UUID) (*Address, error)
}

// userRepository is the GORM-backed implementation of UserRepository.
type userRepository struct {
	db *gorm.DB
}

// NewUserRepository creates a new UserRepository backed by the given GORM DB.
func NewUserRepository(db *gorm.DB) UserRepository {
	return &userRepository{db: db}
}

func (r *userRepository) GetProfile(ctx context.Context, userID uuid.UUID) (*auth.User, error) {
	var user auth.User
	if err := r.db.WithContext(ctx).Where("id = ?", userID).First(&user).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, apperrors.NotFound("User not found")
		}
		return nil, apperrors.Internal("Failed to fetch user profile")
	}
	return &user, nil
}

func (r *userRepository) UpdateProfile(ctx context.Context, userID uuid.UUID, name, avatarURL *string) error {
	updates := map[string]interface{}{}
	if name != nil {
		updates["full_name"] = *name
	}
	if avatarURL != nil {
		updates["avatar_url"] = *avatarURL
	}
	if len(updates) == 0 {
		return nil
	}

	result := r.db.WithContext(ctx).Model(&auth.User{}).Where("id = ?", userID).Updates(updates)
	if result.Error != nil {
		return apperrors.Internal("Failed to update profile")
	}
	if result.RowsAffected == 0 {
		return apperrors.NotFound("User not found")
	}
	return nil
}

func (r *userRepository) UpdateFCMToken(ctx context.Context, userID uuid.UUID, token string) error {
	result := r.db.WithContext(ctx).Model(&auth.User{}).Where("id = ?", userID).Update("fcm_token", token)
	if result.Error != nil {
		return apperrors.Internal("Failed to update FCM token")
	}
	if result.RowsAffected == 0 {
		return apperrors.NotFound("User not found")
	}
	return nil
}

func (r *userRepository) DeactivateAccount(ctx context.Context, userID uuid.UUID) error {
	result := r.db.WithContext(ctx).Model(&auth.User{}).Where("id = ?", userID).Updates(map[string]interface{}{
		"is_active": false,
	})
	if result.Error != nil {
		return apperrors.Internal("Failed to deactivate account")
	}
	if result.RowsAffected == 0 {
		return apperrors.NotFound("User not found")
	}

	// Soft-delete the user record.
	if err := r.db.WithContext(ctx).Where("id = ?", userID).Delete(&auth.User{}).Error; err != nil {
		return apperrors.Internal("Failed to deactivate account")
	}
	return nil
}

func (r *userRepository) ListAddresses(ctx context.Context, userID uuid.UUID) ([]Address, error) {
	var addresses []Address
	if err := r.db.WithContext(ctx).
		Where("user_id = ?", userID).
		Order("is_default DESC, created_at DESC").
		Find(&addresses).Error; err != nil {
		return nil, apperrors.Internal("Failed to list addresses")
	}
	return addresses, nil
}

func (r *userRepository) CreateAddress(ctx context.Context, address *Address) error {
	query := `
		INSERT INTO addresses (id, user_id, label, full_address, landmark, city, state, pincode, latitude, longitude, is_default, location, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ST_MakePoint(?, ?)::geography, NOW(), NOW())
		RETURNING id, created_at, updated_at`

	return r.db.WithContext(ctx).Raw(query,
		address.ID,
		address.UserID,
		address.Label,
		address.FullAddress,
		address.Landmark,
		address.City,
		address.State,
		address.Pincode,
		address.Latitude,
		address.Longitude,
		address.IsDefault,
		address.Longitude, // ST_MakePoint takes (lng, lat)
		address.Latitude,
	).Scan(address).Error
}

func (r *userRepository) UpdateAddress(ctx context.Context, address *Address) error {
	query := `
		UPDATE addresses
		SET label = ?, full_address = ?, landmark = ?, city = ?, state = ?, pincode = ?,
		    latitude = ?, longitude = ?, location = ST_MakePoint(?, ?)::geography,
		    updated_at = NOW()
		WHERE id = ? AND user_id = ?`

	result := r.db.WithContext(ctx).Exec(query,
		address.Label,
		address.FullAddress,
		address.Landmark,
		address.City,
		address.State,
		address.Pincode,
		address.Latitude,
		address.Longitude,
		address.Longitude, // ST_MakePoint takes (lng, lat)
		address.Latitude,
		address.ID,
		address.UserID,
	)
	if result.Error != nil {
		return apperrors.Internal("Failed to update address")
	}
	if result.RowsAffected == 0 {
		return apperrors.NotFound("Address not found")
	}
	return nil
}

func (r *userRepository) DeleteAddress(ctx context.Context, userID, addressID uuid.UUID) error {
	result := r.db.WithContext(ctx).
		Where("id = ? AND user_id = ?", addressID, userID).
		Delete(&Address{})
	if result.Error != nil {
		return apperrors.Internal("Failed to delete address")
	}
	if result.RowsAffected == 0 {
		return apperrors.NotFound("Address not found")
	}
	return nil
}

func (r *userRepository) SetDefaultAddress(ctx context.Context, userID, addressID uuid.UUID) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		// Unset all existing defaults for this user.
		if err := tx.Model(&Address{}).
			Where("user_id = ? AND is_default = ?", userID, true).
			Update("is_default", false).Error; err != nil {
			return apperrors.Internal("Failed to update default address")
		}

		// Set the specified address as default.
		result := tx.Model(&Address{}).
			Where("id = ? AND user_id = ?", addressID, userID).
			Update("is_default", true)
		if result.Error != nil {
			return apperrors.Internal("Failed to set default address")
		}
		if result.RowsAffected == 0 {
			return apperrors.NotFound("Address not found")
		}
		return nil
	})
}

func (r *userRepository) GetAddress(ctx context.Context, userID, addressID uuid.UUID) (*Address, error) {
	var address Address
	if err := r.db.WithContext(ctx).
		Where("id = ? AND user_id = ?", addressID, userID).
		First(&address).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, apperrors.NotFound("Address not found")
		}
		return nil, apperrors.Internal("Failed to fetch address")
	}
	return &address, nil
}
