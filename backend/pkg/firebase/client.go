package firebase

import (
	"context"
	"fmt"
	"log"
	"os"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"github.com/prabakarankannan/marketplace-backend/config"
	"google.golang.org/api/option"
)

// FirebaseService provides Firebase Cloud Messaging (FCM) push notification
// capabilities. When credentials are unavailable it operates as a no-op
// service, logging warnings instead of failing.
type FirebaseService struct {
	msgClient *messaging.Client
	noop      bool
}

// NewFirebaseService initializes Firebase with the credentials file specified
// in cfg. If the credentials file does not exist, it returns a no-op service
// that logs warnings instead of sending notifications.
func NewFirebaseService(cfg config.FirebaseConfig) (*FirebaseService, error) {
	// Handle missing credentials gracefully -- return a no-op service.
	if cfg.CredentialsFile == "" {
		log.Println("[Firebase] No credentials file configured, push notifications disabled")
		return &FirebaseService{noop: true}, nil
	}

	if _, err := os.Stat(cfg.CredentialsFile); os.IsNotExist(err) {
		log.Printf("[Firebase] Credentials file %q not found, push notifications disabled", cfg.CredentialsFile)
		return &FirebaseService{noop: true}, nil
	}

	ctx := context.Background()

	app, err := firebase.NewApp(ctx, nil, option.WithCredentialsFile(cfg.CredentialsFile))
	if err != nil {
		return nil, fmt.Errorf("failed to initialize firebase app: %w", err)
	}

	msgClient, err := app.Messaging(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize firebase messaging client: %w", err)
	}

	return &FirebaseService{
		msgClient: msgClient,
		noop:      false,
	}, nil
}

// SendPushNotification sends a push notification to the specified FCM device
// token. If the service is running in no-op mode (credentials unavailable),
// it logs the notification details and returns nil.
func (s *FirebaseService) SendPushNotification(ctx context.Context, token, title, body string, data map[string]string) error {
	if s.noop {
		log.Printf("[Firebase-NOOP] Push notification not sent (no credentials): token=%s title=%q body=%q", token, title, body)
		return nil
	}

	message := &messaging.Message{
		Token: token,
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Data: data,
	}

	_, err := s.msgClient.Send(ctx, message)
	if err != nil {
		return fmt.Errorf("failed to send push notification: %w", err)
	}

	return nil
}
