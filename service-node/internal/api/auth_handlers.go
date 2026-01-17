package api

import (
	"encoding/json"
	"net/http"

	"github.com/pulse-server/service-node/internal/auth"
	"github.com/pulse-server/service-node/internal/middleware"
	"github.com/pulse-server/service-node/internal/models"
)

// AuthHandler handles authentication endpoints.
type AuthHandler struct {
	authService *auth.Service
}

// NewAuthHandler creates a new AuthHandler.
func NewAuthHandler(authService *auth.Service) *AuthHandler {
	return &AuthHandler{authService: authService}
}

// Login handles POST /auth/login
func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req models.LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.Username == "" || req.Password == "" {
		WriteError(w, http.StatusBadRequest, "username and password are required")
		return
	}

	ipAddress := getClientIP(r)
	userAgent := r.UserAgent()

	resp, err := h.authService.Login(r.Context(), &req, ipAddress, userAgent)
	if err != nil {
		switch err {
		case auth.ErrInvalidCredentials:
			WriteError(w, http.StatusUnauthorized, "invalid username or password")
		case auth.ErrUserInactive:
			WriteError(w, http.StatusForbidden, "user account is inactive")
		default:
			WriteError(w, http.StatusInternalServerError, "authentication failed")
		}
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

// Refresh handles POST /auth/refresh
func (h *AuthHandler) Refresh(w http.ResponseWriter, r *http.Request) {
	var req models.RefreshRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.RefreshToken == "" {
		WriteError(w, http.StatusBadRequest, "refresh_token is required")
		return
	}

	ipAddress := getClientIP(r)
	userAgent := r.UserAgent()

	resp, err := h.authService.Refresh(r.Context(), req.RefreshToken, ipAddress, userAgent)
	if err != nil {
		switch err {
		case auth.ErrTokenExpired:
			WriteError(w, http.StatusUnauthorized, "refresh token has expired")
		case auth.ErrTokenInvalid:
			WriteError(w, http.StatusUnauthorized, "invalid refresh token")
		case auth.ErrTokenRevoked:
			WriteError(w, http.StatusUnauthorized, "refresh token has been revoked")
		case auth.ErrUserInactive:
			WriteError(w, http.StatusForbidden, "user account is inactive")
		default:
			WriteError(w, http.StatusInternalServerError, "token refresh failed")
		}
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

// Logout handles POST /auth/logout
func (h *AuthHandler) Logout(w http.ResponseWriter, r *http.Request) {
	var req models.RefreshRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.RefreshToken == "" {
		WriteError(w, http.StatusBadRequest, "refresh_token is required")
		return
	}

	ipAddress := getClientIP(r)
	userAgent := r.UserAgent()

	if err := h.authService.Logout(r.Context(), req.RefreshToken, ipAddress, userAgent); err != nil {
		WriteError(w, http.StatusInternalServerError, "logout failed")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// Me handles GET /auth/me
func (h *AuthHandler) Me(w http.ResponseWriter, r *http.Request) {
	claims, ok := middleware.GetUserClaims(r.Context())
	if !ok {
		WriteError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	user, err := h.authService.GetUserFromToken(r.Context(), claims)
	if err != nil {
		WriteError(w, http.StatusInternalServerError, "failed to get user")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}

// getClientIP extracts the client IP address from the request.
func getClientIP(r *http.Request) string {
	// Check X-Forwarded-For header first (for proxied requests)
	xff := r.Header.Get("X-Forwarded-For")
	if xff != "" {
		// Take the first IP in the chain
		ips := splitAndTrim(xff, ",")
		if len(ips) > 0 {
			return ips[0]
		}
	}

	// Check X-Real-IP header
	xri := r.Header.Get("X-Real-IP")
	if xri != "" {
		return xri
	}

	// Fall back to RemoteAddr
	return r.RemoteAddr
}

// splitAndTrim splits a string and trims whitespace from each part.
func splitAndTrim(s, sep string) []string {
	var result []string
	for _, part := range split(s, sep) {
		trimmed := trim(part)
		if trimmed != "" {
			result = append(result, trimmed)
		}
	}
	return result
}

func split(s, sep string) []string {
	var result []string
	for len(s) > 0 {
		i := indexOf(s, sep)
		if i < 0 {
			result = append(result, s)
			break
		}
		result = append(result, s[:i])
		s = s[i+len(sep):]
	}
	return result
}

func indexOf(s, substr string) int {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return i
		}
	}
	return -1
}

func trim(s string) string {
	start := 0
	end := len(s)
	for start < end && (s[start] == ' ' || s[start] == '\t') {
		start++
	}
	for start < end && (s[end-1] == ' ' || s[end-1] == '\t') {
		end--
	}
	return s[start:end]
}
