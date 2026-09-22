// Package config reads the process configuration from the environment.
//
// No credential is ever hardcoded (AGENTS.md A5): every value comes from the
// environment, and .env.example documents the full set.
package config

import (
	"fmt"
	"os"
	"strconv"
)

// Config holds the settings the application needs to start.
type Config struct {
	AppName  string
	AppEnv   string
	LogLevel string
	Port     int
}

// Load reads the configuration, failing fast when a value is invalid (A3).
func Load() (Config, error) {
	port, err := intFromEnv("PORT", 8080)
	if err != nil {
		return Config{}, fmt.Errorf("load config: %w", err)
	}

	return Config{
		AppName:  stringFromEnv("APP_NAME", "@@PROJECT@@"),
		AppEnv:   stringFromEnv("APP_ENV", "development"),
		LogLevel: stringFromEnv("LOG_LEVEL", "info"),
		Port:     port,
	}, nil
}

func stringFromEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok && value != "" {
		return value
	}
	return fallback
}

func intFromEnv(key string, fallback int) (int, error) {
	raw, ok := os.LookupEnv(key)
	if !ok || raw == "" {
		return fallback, nil
	}
	value, err := strconv.Atoi(raw)
	if err != nil {
		return 0, fmt.Errorf("%s must be an integer, got %q: %w", key, raw, err)
	}
	return value, nil
}
