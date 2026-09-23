// Package logging configures structured JSON logging (AGENTS.md A3).
package logging

import (
	"log/slog"
	"os"
	"strings"
)

// New returns a JSON logger at the requested level. Never use fmt.Println for
// application events: logs are machine-readable, one object per line.
func New(level string) *slog.Logger {
	return slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: parseLevel(level),
	}))
}

func parseLevel(level string) slog.Level {
	switch strings.ToLower(level) {
	case "debug":
		return slog.LevelDebug
	case "warn", "warning":
		return slog.LevelWarn
	case "error":
		return slog.LevelError
	default:
		return slog.LevelInfo
	}
}
