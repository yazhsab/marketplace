package app

import (
	"context"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"

	"github.com/prabakarankannan/marketplace-backend/internal/auth"
	"github.com/prabakarankannan/marketplace-backend/internal/booking"
	"github.com/prabakarankannan/marketplace-backend/internal/delivery"
	"github.com/prabakarankannan/marketplace-backend/internal/media"
	"github.com/prabakarankannan/marketplace-backend/internal/middleware"
	"github.com/prabakarankannan/marketplace-backend/internal/notification"
	"github.com/prabakarankannan/marketplace-backend/internal/order"
	"github.com/prabakarankannan/marketplace-backend/internal/payment"
	"github.com/prabakarankannan/marketplace-backend/internal/product"
	"github.com/prabakarankannan/marketplace-backend/internal/review"
	"github.com/prabakarankannan/marketplace-backend/internal/search"
	"github.com/prabakarankannan/marketplace-backend/internal/user"
	"github.com/prabakarankannan/marketplace-backend/internal/vendor"
)

// registerRoutes wires all repositories, services, and handlers, then mounts
// every module's routes onto the /api/v1 group.
func (a *App) registerRoutes() {
	jwtSecret := a.Config.JWT.AccessSecret

	// =====================================================================
	// Repositories
	// =====================================================================
	authRepo := auth.NewAuthRepository(a.DB)
	userRepo := user.NewUserRepository(a.DB)
	vendorRepo := vendor.NewVendorRepository(a.DB)
	productRepo := product.NewProductRepository(a.DB)
	orderRepo := order.NewOrderRepository(a.DB)
	bookingRepo := booking.NewBookingRepository(a.DB)
	paymentRepo := payment.NewPaymentRepository(a.DB)
	reviewRepo := review.NewReviewRepository(a.DB)
	notificationRepo := notification.NewNotificationRepository(a.DB)
	deliveryRepo := delivery.NewDeliveryRepository(a.DB)

	// =====================================================================
	// Services
	// =====================================================================
	authService := auth.NewAuthService(authRepo, a.Cache, a.SMSProvider, *a.Config)
	userService := user.NewUserService(userRepo)
	vendorService := vendor.NewVendorService(vendorRepo, a.Cache, authRepo)
	productService := product.NewProductService(productRepo, vendorRepo, a.Cache)
	orderService := order.NewOrderService(orderRepo, productRepo, vendorRepo)
	bookingService := booking.NewBookingService(bookingRepo, vendorRepo)
	razorpayClient := payment.NewRazorpayClient(a.Config.Razorpay)
	paymentService := payment.NewPaymentService(paymentRepo, orderRepo, bookingRepo, vendorRepo, razorpayClient, a.DB)
	reviewService := review.NewReviewService(reviewRepo, vendorRepo)
	notificationService := notification.NewNotificationService(notificationRepo, a.Firebase, authRepo)
	searchIndexer := search.NewIndexer(a.Search)
	searchModuleService := search.NewSearchModuleService(a.Search, searchIndexer)
	mediaService := media.NewMediaService(a.Storage, a.Config.MinIO)
	deliveryService := delivery.NewDeliveryService(
		deliveryRepo, authRepo, orderRepo, vendorRepo, notificationService, paymentRepo,
	)

	// Wire auto-assignment hook: when order becomes "ready", auto-assign delivery partner
	orderService.SetOnReadyHook(func(ctx context.Context, orderID uuid.UUID) {
		_ = deliveryService.AutoAssign(ctx, orderID)
	})

	// =====================================================================
	// Handlers
	// =====================================================================
	authHandler := auth.NewAuthHandler(authService)
	userHandler := user.NewHandler(userService)
	vendorHandler := vendor.NewVendorHandler(vendorService)
	productHandler := product.NewProductHandler(productService)
	orderHandler := order.NewOrderHandler(orderService)
	bookingHandler := booking.NewBookingHandler(bookingService)
	paymentHandler := payment.NewPaymentHandler(paymentService)
	reviewHandler := review.NewReviewHandler(reviewService)
	notificationHandler := notification.NewNotificationHandler(notificationService)
	searchHandler := search.NewSearchHandler(searchModuleService)
	mediaHandler := media.NewHandler(mediaService)
	deliveryHandler := delivery.NewDeliveryHandler(deliveryService)

	// =====================================================================
	// API v1 group
	// =====================================================================
	api := a.Fiber.Group("/api/v1")

	// Health check
	api.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "ok",
			"service": a.Config.App.Name,
		})
	})

	// -----------------------------------------------------------------
	// Auth routes (no package-level RegisterRoutes; mounted inline)
	// -----------------------------------------------------------------
	authGroup := api.Group("/auth")
	authGroup.Post("/register", authHandler.Register)
	authGroup.Post("/login/email", authHandler.LoginEmail)
	authGroup.Post("/otp/send", authHandler.SendOTP)
	authGroup.Post("/otp/verify", authHandler.VerifyOTP)
	authGroup.Post("/refresh", authHandler.RefreshToken)
	authGroup.Get("/me", middleware.Auth(jwtSecret), authHandler.GetMe)

	// -----------------------------------------------------------------
	// User routes
	// -----------------------------------------------------------------
	userGroup := api.Group("/users", middleware.Auth(jwtSecret))
	userHandler.RegisterRoutes(userGroup)

	// -----------------------------------------------------------------
	// Vendor routes
	// -----------------------------------------------------------------
	vendor.RegisterRoutes(api, vendorHandler, jwtSecret)

	// -----------------------------------------------------------------
	// Product & category routes
	// -----------------------------------------------------------------
	product.RegisterRoutes(api, productHandler, jwtSecret)

	// -----------------------------------------------------------------
	// Order routes
	// -----------------------------------------------------------------
	order.RegisterRoutes(api, orderHandler, jwtSecret)

	// -----------------------------------------------------------------
	// Booking & service routes
	// -----------------------------------------------------------------
	booking.RegisterRoutes(api, bookingHandler, jwtSecret)

	// -----------------------------------------------------------------
	// Payment & wallet routes
	// -----------------------------------------------------------------
	payment.RegisterRoutes(api, paymentHandler, jwtSecret)

	// -----------------------------------------------------------------
	// Review routes
	// -----------------------------------------------------------------
	review.RegisterRoutes(api, reviewHandler, jwtSecret)

	// -----------------------------------------------------------------
	// Notification routes
	// -----------------------------------------------------------------
	notification.RegisterRoutes(api, notificationHandler, jwtSecret)

	// -----------------------------------------------------------------
	// Search routes (public, no jwtSecret needed)
	// -----------------------------------------------------------------
	search.RegisterRoutes(api, searchHandler)

	// -----------------------------------------------------------------
	// Delivery routes
	// -----------------------------------------------------------------
	delivery.RegisterRoutes(api, deliveryHandler, jwtSecret)

	// -----------------------------------------------------------------
	// Media routes (authenticated)
	// -----------------------------------------------------------------
	mediaGroup := api.Group("/media", middleware.Auth(jwtSecret))
	mediaHandler.RegisterRoutes(mediaGroup)
}
