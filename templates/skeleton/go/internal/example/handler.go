package example

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
)

// Handler translates between HTTP and the service. Business rules stay in the
// service; expected domain errors become status codes here (AGENTS.md A3).
type Handler struct {
	logger  *slog.Logger
	service *Service
}

// NewHandler builds the HTTP layer of the example slice.
func NewHandler(logger *slog.Logger, service *Service) *Handler {
	return &Handler{logger: logger, service: service}
}

// Routes registers the example endpoints on the given mux.
func (h *Handler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("POST /examples", h.create)
	mux.HandleFunc("GET /examples/{id}", h.read)
}

type createRequest struct {
	Name string `json:"name"`
}

func (h *Handler) create(w http.ResponseWriter, r *http.Request) {
	var payload createRequest
	// Bound the body: an unbounded read is a denial-of-service vector (A5).
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 64<<10)).Decode(&payload); err != nil {
		writeError(w, http.StatusBadRequest, "invalid payload")
		return
	}
	if payload.Name == "" {
		writeError(w, http.StatusUnprocessableEntity, "name is required")
		return
	}

	item, err := h.service.Create(payload.Name)
	switch {
	case errors.Is(err, ErrDuplicateName):
		writeError(w, http.StatusConflict, "name already in use")
	case err != nil:
		// Generic message to the client, detail in the structured log (A3).
		h.logger.ErrorContext(r.Context(), "create example failed", slog.String("error", err.Error()))
		writeError(w, http.StatusInternalServerError, "internal error")
	default:
		writeJSON(w, http.StatusCreated, item)
	}
}

func (h *Handler) read(w http.ResponseWriter, r *http.Request) {
	item, err := h.service.Get(r.PathValue("id"))
	switch {
	case errors.Is(err, ErrNotFound):
		writeError(w, http.StatusNotFound, "not found")
	case err != nil:
		h.logger.ErrorContext(r.Context(), "read example failed", slog.String("error", err.Error()))
		writeError(w, http.StatusInternalServerError, "internal error")
	default:
		writeJSON(w, http.StatusOK, item)
	}
}

func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}
