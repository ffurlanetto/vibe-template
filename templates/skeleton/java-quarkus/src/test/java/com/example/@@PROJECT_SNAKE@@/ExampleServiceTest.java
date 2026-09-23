package com.example.@@PROJECT_SNAKE@@;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.example.@@PROJECT_SNAKE@@.domain.DuplicateExampleNameException;
import com.example.@@PROJECT_SNAKE@@.domain.Example;
import com.example.@@PROJECT_SNAKE@@.domain.ExampleNotFoundException;
import com.example.@@PROJECT_SNAKE@@.domain.ExampleService;
import com.example.@@PROJECT_SNAKE@@.infrastructure.InMemoryExampleRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Unit tests for the example service — no CDI container needed (A4). */
class ExampleServiceTest {

    private ExampleService service;

    @BeforeEach
    void setUp() {
        service = new ExampleService(new InMemoryExampleRepository());
    }

    @Test
    void create_WithNewName_ReturnsExample() {
        Example created = service.create("first");

        assertEquals("first", created.name());
        assertFalse(created.id().isBlank());
    }

    @Test
    void create_WithDuplicateName_ThrowsConflict() {
        service.create("taken");

        assertThrows(DuplicateExampleNameException.class, () -> service.create("taken"));
    }

    @Test
    void get_WithKnownId_ReturnsExample() {
        Example created = service.create("known");

        assertEquals(created.id(), service.get(created.id()).id());
    }

    @Test
    void get_WithUnknownId_ThrowsNotFound() {
        assertThrows(ExampleNotFoundException.class, () -> service.get("does-not-exist"));
    }
}
