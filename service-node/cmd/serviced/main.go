package main

import (
	"context"
	"embed"
	"fmt"
	"io/fs"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/go-chi/chi/v5"
	chimw "github.com/go-chi/chi/v5/middleware"
	"github.com/joho/godotenv"
	"github.com/pulse-server/service-node/internal/api"
	"github.com/pulse-server/service-node/internal/auth"
	"github.com/pulse-server/service-node/internal/config"
	"github.com/pulse-server/service-node/internal/db"
	"github.com/pulse-server/service-node/internal/middleware"
	"github.com/pulse-server/service-node/internal/repository"
)

//go:embed migrations/*.sql
var migrationsFS embed.FS

// Version is set at build time
var Version = "0.1.0-dev"

func main() {
	// Load .env file if present
	_ = godotenv.Load()

	// Set migrations filesystem
	subFS, err := fs.Sub(migrationsFS, "migrations")
	if err != nil {
		log.Fatalf("Failed to get migrations sub-filesystem: %v", err)
	}
	db.MigrationsFS = subFS

	cfg := config.Load()

	fmt.Printf("Pulse Service Node v%s\n", Version)
	fmt.Printf("Bind address: %s\n", cfg.BindAddr)

	// Initialize database connection
	ctx := context.Background()
	database, err := db.New(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer database.Close()

	// Run migrations
	if err := database.Migrate(ctx); err != nil {
		log.Fatalf("Failed to run migrations: %v", err)
	}

	// Initialize repositories
	userRepo := repository.NewUserRepository(database.Pool)
	tokenRepo := repository.NewRefreshTokenRepository(database.Pool)
	auditRepo := repository.NewAuditLogRepository(database.Pool)
	serverRepo := repository.NewServerRepository(database.Pool)
	alertRepo := repository.NewAlertRepository(database.Pool)

	// Initialize auth service
	authConfig := auth.DefaultConfig(cfg.ServiceNodeSecret)
	authService := auth.NewService(authConfig, userRepo, tokenRepo, auditRepo)

	// Initialize handlers
	authHandler := api.NewAuthHandler(authService)
	serverHandler := api.NewServerHandler(serverRepo)
	alertHandler := api.NewAlertHandler(alertRepo)

	r := chi.NewRouter()

	// Middleware
	r.Use(chimw.RequestID)
	r.Use(chimw.RealIP)
	r.Use(chimw.Logger)
	r.Use(chimw.Recoverer)
	r.Use(chimw.Timeout(30 * time.Second))

	// Health endpoint
	r.Get("/health", api.HealthHandler(Version))

	// API v1 routes
	r.Route("/api/v1", func(r chi.Router) {
		// Health endpoint (also available at /api/v1/health)
		r.Get("/health", api.HealthHandler(Version))

		// Auth routes (public)
		r.Post("/auth/login", authHandler.Login)
		r.Post("/auth/logout", authHandler.Logout)
		r.Post("/auth/refresh", authHandler.Refresh)

		// Auth routes (protected)
		r.Group(func(r chi.Router) {
			r.Use(middleware.AuthMiddleware(authService))
			r.Get("/auth/me", authHandler.Me)

			// Server routes
			r.Get("/servers", serverHandler.List)
			r.Post("/servers", serverHandler.Create)
			r.Get("/servers/{id}", serverHandler.Get)
			r.Put("/servers/{id}", serverHandler.Update)
			r.Delete("/servers/{id}", serverHandler.Delete)

			// Alert rules routes
			r.Get("/alerts/rules", alertHandler.ListAlertRules)
			r.Post("/alerts/rules", alertHandler.CreateAlertRule)
			r.Get("/alerts/rules/{id}", alertHandler.GetAlertRule)
			r.Patch("/alerts/rules/{id}", alertHandler.UpdateAlertRule)
			r.Delete("/alerts/rules/{id}", alertHandler.DeleteAlertRule)

			// Alert events routes
			r.Get("/alerts/events", alertHandler.ListAlertEvents)
			r.Get("/alerts/events/{id}", alertHandler.GetAlertEvent)
			r.Post("/alerts/events/{id}/acknowledge", alertHandler.AcknowledgeAlertEvent)

			// Notification channels routes (under /settings/notifications)
			r.Get("/settings/notifications", alertHandler.ListNotificationChannels)
			r.Post("/settings/notifications", alertHandler.CreateNotificationChannel)
			r.Delete("/settings/notifications/{id}", alertHandler.DeleteNotificationChannel)
			r.Post("/settings/notifications/{id}/test", alertHandler.TestNotificationChannel)
		})
	})

	// Create server
	srv := &http.Server{
		Addr:         cfg.BindAddr,
		Handler:      r,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start server in goroutine
	go func() {
		log.Printf("Starting server on %s", cfg.BindAddr)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server error: %v", err)
		}
	}()

	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")

	// Graceful shutdown with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server stopped")
}
