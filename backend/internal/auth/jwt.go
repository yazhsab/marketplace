package auth

import (
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"

	"github.com/prabakarankannan/marketplace-backend/config"
)

// Claims holds the custom JWT payload embedded in access and refresh tokens.
type Claims struct {
	UserID uuid.UUID `json:"user_id"`
	Role   string    `json:"role"`
	jwt.RegisteredClaims
}

// GenerateAccessToken creates a signed JWT access token for the given user.
func GenerateAccessToken(userID uuid.UUID, role, secret string, expiry time.Duration) (string, error) {
	now := time.Now()
	claims := Claims{
		UserID: userID,
		Role:   role,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID.String(),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(expiry)),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

// GenerateRefreshToken creates a signed JWT refresh token for the given user.
func GenerateRefreshToken(userID uuid.UUID, role, secret string, expiry time.Duration) (string, error) {
	now := time.Now()
	claims := Claims{
		UserID: userID,
		Role:   role,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID.String(),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(expiry)),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

// ValidateToken parses and validates a JWT string, returning the embedded claims.
func ValidateToken(tokenStr, secret string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &Claims{}, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, jwt.ErrSignatureInvalid
		}
		return []byte(secret), nil
	})
	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, jwt.ErrSignatureInvalid
	}

	return claims, nil
}

// GenerateTokenPair creates both an access and a refresh token using the
// provided JWT configuration.
func GenerateTokenPair(userID uuid.UUID, role string, cfg config.JWTConfig) (accessToken, refreshToken string, err error) {
	accessToken, err = GenerateAccessToken(userID, role, cfg.AccessSecret, cfg.AccessExpiry)
	if err != nil {
		return "", "", err
	}

	refreshToken, err = GenerateRefreshToken(userID, role, cfg.RefreshSecret, cfg.RefreshExpiry)
	if err != nil {
		return "", "", err
	}

	return accessToken, refreshToken, nil
}
