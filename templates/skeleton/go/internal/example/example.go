// Package example is the reference vertical slice: handler -> service ->
// repository. Copy its shape for real features (AGENTS.md A3, B5).
package example

import (
	"errors"
	"fmt"
	"sync"

	"crypto/rand"
	"encoding/hex"
)

// ErrDuplicateName is returned when the requested name is already taken.
// It is an expected business error, not a system failure.
var ErrDuplicateName = errors.New("name already in use")

// ErrNotFound is returned when no example carries the requested id.
var ErrNotFound = errors.New("example not found")

// Example is the domain entity.
type Example struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

// Repository is the persistence contract the service depends on. Swap the
// in-memory implementation for a database without touching the service.
type Repository interface {
	Add(name string) (Example, error)
	Get(id string) (Example, bool)
	ExistsByName(name string) bool
}

// InMemoryRepository is the reference implementation. Replace it with the
// datastore declared in section B2.
type InMemoryRepository struct {
	mu    sync.RWMutex
	items map[string]Example
}

// NewInMemoryRepository returns an empty store.
func NewInMemoryRepository() *InMemoryRepository {
	return &InMemoryRepository{items: make(map[string]Example)}
}

// Add stores a new example under a freshly generated identifier.
func (r *InMemoryRepository) Add(name string) (Example, error) {
	id, err := newID()
	if err != nil {
		return Example{}, fmt.Errorf("generate id: %w", err)
	}

	r.mu.Lock()
	defer r.mu.Unlock()
	item := Example{ID: id, Name: name}
	r.items[id] = item
	return item, nil
}

// Get returns the example with this id, and whether it existed.
func (r *InMemoryRepository) Get(id string) (Example, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	item, ok := r.items[id]
	return item, ok
}

// ExistsByName reports whether an example already uses this name.
func (r *InMemoryRepository) ExistsByName(name string) bool {
	r.mu.RLock()
	defer r.mu.RUnlock()
	for _, item := range r.items {
		if item.Name == name {
			return true
		}
	}
	return false
}

// Service holds the business rules. It knows nothing about HTTP.
type Service struct {
	repository Repository
}

// NewService wires the service to its persistence boundary.
func NewService(repository Repository) *Service {
	return &Service{repository: repository}
}

// Create registers a new example, enforcing name uniqueness.
// It returns ErrDuplicateName when the name is already taken.
func (s *Service) Create(name string) (Example, error) {
	if name == "" {
		return Example{}, fmt.Errorf("name is required: %w", ErrDuplicateName)
	}
	if s.repository.ExistsByName(name) {
		return Example{}, fmt.Errorf("create %q: %w", name, ErrDuplicateName)
	}
	return s.repository.Add(name)
}

// Get returns one example, or ErrNotFound.
func (s *Service) Get(id string) (Example, error) {
	item, ok := s.repository.Get(id)
	if !ok {
		return Example{}, fmt.Errorf("get %q: %w", id, ErrNotFound)
	}
	return item, nil
}

// newID returns a cryptographically random identifier (A5: never math/rand).
func newID() (string, error) {
	buffer := make([]byte, 16)
	if _, err := rand.Read(buffer); err != nil {
		return "", fmt.Errorf("read random bytes: %w", err)
	}
	return hex.EncodeToString(buffer), nil
}
