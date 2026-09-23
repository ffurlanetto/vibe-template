package com.example.@@PROJECT_SNAKE@@.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.example.@@PROJECT_SNAKE@@.infrastructure.InMemoryExampleRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Unit tests for {@link ExampleService}. Naming: Subject_Scenario_Result (A4). */
class ExampleServiceTest {

    private ExampleService service;

    @BeforeEach
    void setUp() {
        service = new ExampleService(new InMemoryExampleRepository());
    }

    @Test
    void create_WithNewName_ReturnsExample() {
        Example created = service.create("first");

        assertThat(created.name()).isEqualTo("first");
        assertThat(created.id()).isNotBlank();
    }

    @Test
    void create_WithDuplicateName_ThrowsConflict() {
        service.create("taken");

        assertThatThrownBy(() -> service.create("taken"))
                .isInstanceOf(DuplicateExampleNameException.class);
    }

    @Test
    void get_WithKnownId_ReturnsExample() {
        Example created = service.create("known");

        assertThat(service.get(created.id()).id()).isEqualTo(created.id());
    }

    @Test
    void get_WithUnknownId_ThrowsNotFound() {
        assertThatThrownBy(() -> service.get("does-not-exist"))
                .isInstanceOf(ExampleNotFoundException.class);
    }
}
