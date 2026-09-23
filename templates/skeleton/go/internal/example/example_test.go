package example_test

import (
	"errors"
	"testing"

	"@@PROJECT_KEBAB@@/internal/example"
)

func newService() *example.Service {
	return example.NewService(example.NewInMemoryRepository())
}

func TestCreate_WithNewName_ReturnsExample(t *testing.T) {
	item, err := newService().Create("first")

	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if item.Name != "first" || item.ID == "" {
		t.Fatalf("unexpected example: %+v", item)
	}
}

func TestCreate_WithDuplicateName_ReturnsErrDuplicateName(t *testing.T) {
	service := newService()
	if _, err := service.Create("taken"); err != nil {
		t.Fatalf("setup failed: %v", err)
	}

	_, err := service.Create("taken")

	if !errors.Is(err, example.ErrDuplicateName) {
		t.Fatalf("expected ErrDuplicateName, got %v", err)
	}
}

func TestGet_WithKnownID_ReturnsExample(t *testing.T) {
	service := newService()
	created, err := service.Create("known")
	if err != nil {
		t.Fatalf("setup failed: %v", err)
	}

	found, err := service.Get(created.ID)

	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if found.ID != created.ID {
		t.Fatalf("expected %s, got %s", created.ID, found.ID)
	}
}

func TestGet_WithUnknownID_ReturnsErrNotFound(t *testing.T) {
	_, err := newService().Get("does-not-exist")

	if !errors.Is(err, example.ErrNotFound) {
		t.Fatalf("expected ErrNotFound, got %v", err)
	}
}

func TestCreate_TwiceWithDifferentNames_ReturnsDistinctIDs(t *testing.T) {
	service := newService()
	first, _ := service.Create("one")
	second, _ := service.Create("two")

	if first.ID == second.ID {
		t.Fatalf("identifiers must be unique, both were %s", first.ID)
	}
}
