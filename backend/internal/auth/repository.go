package auth

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// AuthRepository defines the data-access contract for user authentication.
type AuthRepository interface {
	FindByEmail(ctx context.Context, email string) (*User, error)
	FindByPhone(ctx context.Context, phone string) (*User, error)
	FindByID(ctx context.Context, id uuid.UUID) (*User, error)
	Create(ctx context.Context, user *User) error
	Update(ctx context.Context, user *User) error
	EmailExists(ctx context.Context, email string) bool
	PhoneExists(ctx context.Context, phone string) bool
}

// authRepository is the GORM-backed implementation of AuthRepository.
type authRepository struct {
	db *gorm.DB
}

// NewAuthRepository returns a new AuthRepository backed by the provided GORM DB.
func NewAuthRepository(db *gorm.DB) AuthRepository {
	return &authRepository{db: db}
}

func (r *authRepository) FindByEmail(ctx context.Context, email string) (*User, error) {
	var user User
	if err := r.db.WithContext(ctx).Where("email = ?", email).First(&user).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &user, nil
}

func (r *authRepository) FindByPhone(ctx context.Context, phone string) (*User, error) {
	var user User
	if err := r.db.WithContext(ctx).Where("phone = ?", phone).First(&user).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &user, nil
}

func (r *authRepository) FindByID(ctx context.Context, id uuid.UUID) (*User, error) {
	var user User
	if err := r.db.WithContext(ctx).Where("id = ?", id).First(&user).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &user, nil
}

func (r *authRepository) Create(ctx context.Context, user *User) error {
	return r.db.WithContext(ctx).Create(user).Error
}

func (r *authRepository) Update(ctx context.Context, user *User) error {
	return r.db.WithContext(ctx).Save(user).Error
}

func (r *authRepository) EmailExists(ctx context.Context, email string) bool {
	var count int64
	r.db.WithContext(ctx).Model(&User{}).Where("email = ?", email).Count(&count)
	return count > 0
}

func (r *authRepository) PhoneExists(ctx context.Context, phone string) bool {
	var count int64
	r.db.WithContext(ctx).Model(&User{}).Where("phone = ?", phone).Count(&count)
	return count > 0
}
