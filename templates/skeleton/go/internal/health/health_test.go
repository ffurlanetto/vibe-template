package health_test

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"@@PROJECT_KEBAB@@/internal/health"
)

func newServer(dependencies ...health.Dependency) *http.ServeMux {
	logger := slog.New(slog.NewJSONHandler(io.Discard, nil))
	mux := http.NewServeMux()
	health.NewHandler(logger, dependencies...).Routes(mux)
	return mux
}

func TestLive_WhenProcessIsRunning_Returns200(t *testing.T) {
	recorder := httptest.NewRecorder()
	newServer().ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/health/live", nil))

	if recorder.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", recorder.Code)
	}
}

func TestReady_WhenDependenciesAreReachable_Returns200(t *testing.T) {
	healthy := health.Dependency{Name: "database", Check: func(context.Context) error { return nil }}

	recorder := httptest.NewRecorder()
	newServer(healthy).ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/health/ready", nil))

	if recorder.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", recorder.Code)
	}
}

func TestReady_WhenDependencyIsDown_Returns503WithItsName(t *testing.T) {
	down := health.Dependency{
		Name:  "database",
		Check: func(context.Context) error { return errors.New("connection refused") },
	}

	recorder := httptest.NewRecorder()
	newServer(down).ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/health/ready", nil))

	if recorder.Code != http.StatusServiceUnavailable {
		t.Fatalf("expected 503, got %d", recorder.Code)
	}
	if !strings.Contains(recorder.Body.String(), "database") {
		t.Fatalf("expected the failing dependency to be named, got %s", recorder.Body.String())
	}
}

func TestReady_WhenDependencyIsDown_DoesNotLeakTheError(t *testing.T) {
	down := health.Dependency{
		Name:  "database",
		Check: func(context.Context) error { return errors.New("password=hunter2 refused") },
	}

	recorder := httptest.NewRecorder()
	newServer(down).ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/health/ready", nil))

	if strings.Contains(recorder.Body.String(), "password") {
		t.Fatalf("the response leaked dependency internals: %s", recorder.Body.String())
	}
}
