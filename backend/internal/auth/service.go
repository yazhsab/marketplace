package auth

import (
	"context"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"

	"github.com/prabakarankannan/marketplace-backend/config"
	apperrors "github.com/prabakarankannan/marketplace-backend/internal/common/errors"
	"github.com/prabakarankannan/marketplace-backend/pkg/cache"
	"github.com/prabakarankannan/marketplace-backend/pkg/sms"
)

// AuthService defines the business-logic contract for authentication.
type AuthService interface {
	Register(ctx context.Context, req RegisterRequest) (*AuthResponse, error)
	LoginWithEmail(ctx context.Context, req LoginEmailRequest) (*AuthResponse, error)
	SendOTP(ctx context.Context, req SendOTPRequest) error
	VerifyOTP(ctx context.Context, req VerifyOTPRequest) (*AuthResponse, error)
	RefreshToken(ctx context.Context, req RefreshTokenRequest) (*AuthResponse, error)
	GetUserByID(ctx context.Context, id uuid.UUID) (*UserResponse, error)
}

// authService is the concrete implementation of AuthService.
type authService struct {
	repo  AuthRepository
	cache *cache.CacheService
	sms   sms.SMSProvider
	cfg   config.Config
}

// NewAuthService returns a new AuthService with all required dependencies.
func NewAuthService(
	repo AuthRepository,
	cache *cache.CacheService,
	sms sms.SMSProvider,
	cfg config.Config,
) AuthService {
	return &authService{
		repo:  repo,
		cache: cache,
		sms:   sms,
		cfg:   cfg,
	}
}

// Register creates a new user with a hashed password and returns a token pair.
func (s *authService) Register(ctx context.Context, req RegisterRequest) (*AuthResponse, error) {
	// Check for existing email.
	if s.repo.EmailExists(ctx, req.Email) {
		return nil, apperrors.Conflict("email already registered")
	}

	// Check for existing phone if provided.
	if req.Phone != nil && *req.Phone != "" {
		if s.repo.PhoneExists(ctx, *req.Phone) {
			return nil, apperrors.Conflict("phone number already registered")
		}
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, apperrors.Internal("failed to hash password")
	}

	user := User{
		ID:           uuid.New(),
		Email:        &req.Email,
		PasswordHash: string(hash),
		FullName:     req.FullName,
		Role:         "customer",
		IsActive:     true,
	}
	if req.Phone != nil && *req.Phone != "" {
		user.Phone = req.Phone
	}

	if err := s.repo.Create(ctx, &user); err != nil {
		return nil, apperrors.Internal("failed to create user")
	}

	accessToken, refreshToken, err := GenerateTokenPair(user.ID, user.Role, s.cfg.JWT)
	if err != nil {
		return nil, apperrors.Internal("failed to generate tokens")
	}

	resp := toUserResponse(&user)
	return &AuthResponse{
		User:         resp,
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

// LoginWithEmail authenticates a user by email and password.
func (s *authService) LoginWithEmail(ctx context.Context, req LoginEmailRequest) (*AuthResponse, error) {
	user, err := s.repo.FindByEmail(ctx, req.Email)
	if err != nil {
		return nil, apperrors.Internal("failed to find user")
	}
	if user == nil {
		return nil, apperrors.Unauthorized("invalid email or password")
	}

	if !user.IsActive {
		return nil, apperrors.Unauthorized("account is deactivated")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		return nil, apperrors.Unauthorized("invalid email or password")
	}

	// Update last login timestamp.
	now := time.Now()
	user.LastLoginAt = &now
	_ = s.repo.Update(ctx, user)

	accessToken, refreshToken, err := GenerateTokenPair(user.ID, user.Role, s.cfg.JWT)
	if err != nil {
		return nil, apperrors.Internal("failed to generate tokens")
	}

	resp := toUserResponse(user)
	return &AuthResponse{
		User:         resp,
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

// SendOTP generates an OTP, stores it in Redis, and dispatches it via SMS.
func (s *authService) SendOTP(ctx context.Context, req SendOTPRequest) error {
	otp := GenerateOTP()

	if err := StoreOTP(ctx, s.cache, req.Phone, otp); err != nil {
		return apperrors.Internal("failed to store OTP")
	}

	if err := s.sms.SendOTP(ctx, req.Phone, otp); err != nil {
		return apperrors.Internal("failed to send OTP")
	}

	return nil
}

// VerifyOTP validates the OTP and returns tokens. If the phone number is not
// registered, a new user account is created automatically.
func (s *authService) VerifyOTP(ctx context.Context, req VerifyOTPRequest) (*AuthResponse, error) {
	if err := VerifyOTP(ctx, s.cache, req.Phone, req.OTP); err != nil {
		return nil, apperrors.Unauthorized(err.Error())
	}

	user, err := s.repo.FindByPhone(ctx, req.Phone)
	if err != nil {
		return nil, apperrors.Internal("failed to find user")
	}

	// Auto-register if phone is not yet associated with an account.
	if user == nil {
		user = &User{
			ID:       uuid.New(),
			Phone:    &req.Phone,
			FullName: "",
			Role:     "customer",
			IsActive: true,
		}
		if err := s.repo.Create(ctx, user); err != nil {
			return nil, apperrors.Internal("failed to create user")
		}
	}

	if !user.IsActive {
		return nil, apperrors.Unauthorized("account is deactivated")
	}

	now := time.Now()
	user.LastLoginAt = &now
	_ = s.repo.Update(ctx, user)

	accessToken, refreshToken, err := GenerateTokenPair(user.ID, user.Role, s.cfg.JWT)
	if err != nil {
		return nil, apperrors.Internal("failed to generate tokens")
	}

	resp := toUserResponse(user)
	return &AuthResponse{
		User:         resp,
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

// RefreshToken validates the provided refresh token and issues a new token pair.
func (s *authService) RefreshToken(ctx context.Context, req RefreshTokenRequest) (*AuthResponse, error) {
	claims, err := ValidateToken(req.RefreshToken, s.cfg.JWT.RefreshSecret)
	if err != nil {
		return nil, apperrors.Unauthorized("invalid or expired refresh token")
	}

	user, err := s.repo.FindByID(ctx, claims.UserID)
	if err != nil {
		return nil, apperrors.Internal("failed to find user")
	}
	if user == nil {
		return nil, apperrors.Unauthorized("user not found")
	}

	if !user.IsActive {
		return nil, apperrors.Unauthorized("account is deactivated")
	}

	accessToken, refreshToken, err := GenerateTokenPair(user.ID, user.Role, s.cfg.JWT)
	if err != nil {
		return nil, apperrors.Internal("failed to generate tokens")
	}

	resp := toUserResponse(user)
	return &AuthResponse{
		User:         resp,
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

// GetUserByID returns the public profile of a user by their ID.
func (s *authService) GetUserByID(ctx context.Context, id uuid.UUID) (*UserResponse, error) {
	user, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, apperrors.Internal("failed to find user")
	}
	if user == nil {
		return nil, apperrors.NotFound("user not found")
	}

	resp := toUserResponse(user)
	return &resp, nil
}
