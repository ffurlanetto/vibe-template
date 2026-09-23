// Command server is the @@PROJECT@@ HTTP entry point.
//
// Wiring only: configuration, logging, routes, graceful shutdown. Business
// logic lives in the internal packages (AGENTS.md A3).
package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"@@PROJECT_KEBAB@@/internal/example"
	"@@PROJECT_KEBAB@@/internal/health"
	"@@PROJECT_KEBAB@@/internal/platform/config"
	"@@PROJECT_KEBAB@@/internal/platform/logging"
)

func main() {
	if err := run(); err != nil {
		// The process failed to start or to stop cleanly: say so on stderr and
		// exit non-zero so the orchestrator notices.
		fmt.Fprintf(os.Stderr, `{"level":"ERROR","message":%q}`+"\n", err.Error())
		os.Exit(1)
	}
}

func run() error {
	cfg, err := config.Load()
	if err != nil {
		return fmt.Errorf("configuration: %w", err)
	}

	logger := logging.New(cfg.LogLevel)
	mux := http.NewServeMux()

	// Register one health.Dependency per critical dependency from section B2.
	health.NewHandler(logger).Routes(mux)
	example.NewHandler(logger, example.NewService(example.NewInMemoryRepository())).Routes(mux)

	server := &http.Server{
		Addr:              fmt.Sprintf(":%d", cfg.Port),
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      15 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	errs := make(chan error, 1)
	go func() {
		logger.Info("server starting", slog.String("app", cfg.AppName), slog.Int("port", cfg.Port))
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			errs <- fmt.Errorf("listen: %w", err)
		}
	}()

	select {
	case err := <-errs:
		return err
	case <-ctx.Done():
		logger.Info("shutdown requested")
	}

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := server.Shutdown(shutdownCtx); err != nil {
		return fmt.Errorf("shutdown: %w", err)
	}
	return nil
}
