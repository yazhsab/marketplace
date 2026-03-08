package auth

import (
	"context"
	"crypto/rand"
	"fmt"
	"math/big"
	"time"

	"github.com/prabakarankannan/marketplace-backend/pkg/cache"
)

const (
	otpTTL       = 5 * time.Minute
	otpKeyPrefix = "otp:"
)

// GenerateOTP returns a cryptographically random 6-digit numeric string.
func GenerateOTP() string {
	n, err := rand.Int(rand.Reader, big.NewInt(900000))
	if err != nil {
		// Fallback should never happen with a proper OS random source.
		return "000000"
	}
	return fmt.Sprintf("%06d", n.Int64()+100000)
}

// StoreOTP saves the OTP for the given phone number in the cache with a 5-minute TTL.
func StoreOTP(ctx context.Context, cs *cache.CacheService, phone, otp string) error {
	key := otpKeyPrefix + phone
	return cs.Set(ctx, key, otp, otpTTL)
}

// VerifyOTP checks the OTP stored for the given phone and deletes it on success.
// Returns an error if the OTP is missing, expired, or does not match.
func VerifyOTP(ctx context.Context, cs *cache.CacheService, phone, otp string) error {
	key := otpKeyPrefix + phone

	var stored string
	if err := cs.Get(ctx, key, &stored); err != nil {
		return fmt.Errorf("otp expired or not found")
	}

	if stored != otp {
		return fmt.Errorf("invalid otp")
	}

	// Delete the OTP so it cannot be reused.
	_ = cs.Delete(ctx, key)
	return nil
}
