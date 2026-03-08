package payment

import (
	"bytes"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"github.com/prabakarankannan/marketplace-backend/config"
)

const razorpayOrdersURL = "https://api.razorpay.com/v1/orders"

// RazorpayClient provides methods for interacting with the Razorpay API.
type RazorpayClient struct {
	keyID     string
	keySecret string
}

// NewRazorpayClient creates a new RazorpayClient from the application config.
func NewRazorpayClient(cfg config.RazorpayConfig) *RazorpayClient {
	return &RazorpayClient{
		keyID:     cfg.KeyID,
		keySecret: cfg.KeySecret,
	}
}

// RazorpayOrderResponse holds the response from Razorpay's create-order API.
type RazorpayOrderResponse struct {
	ID       string `json:"id"`
	Entity   string `json:"entity"`
	Amount   int    `json:"amount"`
	Currency string `json:"currency"`
	Receipt  string `json:"receipt"`
	Status   string `json:"status"`
}

// CreateOrder creates a new Razorpay order. The amount is in the major
// currency unit (e.g., rupees) and is converted to the minor unit (paise)
// before sending to the API.
func (r *RazorpayClient) CreateOrder(amount float64, currency, receipt string) (*RazorpayOrderResponse, error) {
	// Razorpay expects amount in smallest currency unit (paise for INR).
	amountInPaise := int(amount * 100)

	payload := map[string]interface{}{
		"amount":   amountInPaise,
		"currency": currency,
		"receipt":  receipt,
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("marshalling razorpay order request: %w", err)
	}

	req, err := http.NewRequest(http.MethodPost, razorpayOrdersURL, bytes.NewReader(body))
	if err != nil {
		return nil, fmt.Errorf("creating razorpay request: %w", err)
	}

	req.SetBasicAuth(r.keyID, r.keySecret)
	req.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("executing razorpay request: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("reading razorpay response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("razorpay returned status %d: %s", resp.StatusCode, string(respBody))
	}

	var orderResp RazorpayOrderResponse
	if err := json.Unmarshal(respBody, &orderResp); err != nil {
		return nil, fmt.Errorf("unmarshalling razorpay response: %w", err)
	}

	return &orderResp, nil
}

// VerifySignature verifies the Razorpay payment signature using HMAC-SHA256.
// The expected signature is computed as HMAC_SHA256(orderID + "|" + paymentID, keySecret).
func (r *RazorpayClient) VerifySignature(orderID, paymentID, signature string) bool {
	data := orderID + "|" + paymentID
	mac := hmac.New(sha256.New, []byte(r.keySecret))
	mac.Write([]byte(data))
	expectedMAC := hex.EncodeToString(mac.Sum(nil))
	return hmac.Equal([]byte(expectedMAC), []byte(signature))
}
