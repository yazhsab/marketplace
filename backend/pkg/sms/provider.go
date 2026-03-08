package sms

import (
	"context"
	"fmt"
	"log"

	"github.com/prabakarankannan/marketplace-backend/config"
)

// SMSProvider defines the interface for sending OTP messages via SMS.
type SMSProvider interface {
	SendOTP(ctx context.Context, phone, otp string) error
}

// MockProvider is an SMSProvider that logs OTP sends to stdout instead of
// dispatching real messages. Useful for development and testing.
type MockProvider struct{}

// SendOTP logs the OTP delivery to stdout.
func (m *MockProvider) SendOTP(_ context.Context, phone, otp string) error {
	log.Printf("[SMS-MOCK] Sending OTP %s to %s", otp, phone)
	return nil
}

// NewSMSProvider returns an SMSProvider based on the configured provider name.
// Currently supports:
//   - "mock": returns a MockProvider that logs to stdout
//
// Add additional provider implementations (e.g. Twilio, MSG91) as needed.
func NewSMSProvider(cfg config.SMSConfig) SMSProvider {
	switch cfg.Provider {
	case "mock":
		log.Println("[SMS] Using mock SMS provider")
		return &MockProvider{}
	default:
		log.Printf("[SMS] Unknown provider %q, falling back to mock", cfg.Provider)
		return &MockProvider{}
	}
}

// Ensure MockProvider satisfies the SMSProvider interface at compile time.
var _ SMSProvider = (*MockProvider)(nil)

// Sentinel error for provider-level failures.
var ErrSendFailed = fmt.Errorf("sms: failed to send message")
