// Package health exposes the liveness and readiness endpoints (AGENTS.md A8,
// docs/specs/SPEC-001-health-endpoints.md).
package health

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
)

// Dependency is one critical dependency the service needs to serve traffic.
type Dependency struct {
	Name  string
	Check func(context.Context) error
}

// Handler answers the health endpoints.
type Handler struct {
	logger       *slog.Logger
	dependencies []Dependency
}

// NewHandler builds a handler over the given dependencies. Register one entry
// per critical dependency declared in section B2 — database, cache, broker.
func NewHandler(logger *slog.Logger, dependencies ...Dependency) *Handler {
	return &Handler{logger: logger, dependencies: dependencies}
}

// Routes registers the health endpoints on the given mux.
func (h *Handler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /health/live", h.live)
	mux.HandleFunc("GET /health/ready", h.ready)
}

// live reports that the process is running. It touches no dependency.
func (h *Handler) live(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{"status": "alive"})
}

// ready reports whether every critical dependency is reachable.
func (h *Handler) ready(w http.ResponseWriter, r *http.Request) {
	failing := make([]string, 0, len(h.dependencies))
	for _, dependency := range h.dependencies {
		if err := dependency.Check(r.Context()); err != nil {
			// The dependency name is safe to expose; its DSN is not (A5).
			h.logger.WarnContext(r.Context(), "dependency unavailable",
				slog.String("dependency", dependency.Name),
				slog.String("error", err.Error()))
			failing = append(failing, dependency.Name)
		}
	}

	if len(failing) > 0 {
		writeJSON(w, http.StatusServiceUnavailable, map[string]any{
			"status":  "unavailable",
			"failing": failing,
		})
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{"status": "ready"})
}

func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}
