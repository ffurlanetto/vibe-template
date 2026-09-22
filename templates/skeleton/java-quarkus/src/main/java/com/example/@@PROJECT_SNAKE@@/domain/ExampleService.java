package com.example.@@PROJECT_SNAKE@@.domain;

import jakarta.enterprise.context.ApplicationScoped;

/** Business rules for examples. Knows nothing about HTTP (AGENTS.md A3). */
@ApplicationScoped
public class ExampleService {

    private final ExampleRepository repository;

    /**
     * Wires the service to its persistence boundary.
     *
     * @param repository the repository implementation to use
     */
    public ExampleService(ExampleRepository repository) {
        this.repository = repository;
    }

    /**
     * Registers a new example, enforcing name uniqueness.
     *
     * @param name the label to register
     * @return the created example
     * @throws DuplicateExampleNameException when the name is already in use
     */
    public Example create(String name) {
        if (repository.existsByName(name)) {
            throw new DuplicateExampleNameException(name);
        }
        return repository.add(name);
    }

    /**
     * Returns one example.
     *
     * @param id the identifier to look up
     * @return the matching example
     * @throws ExampleNotFoundException when no example carries this identifier
     */
    public Example get(String id) {
        return repository.findById(id).orElseThrow(() -> new ExampleNotFoundException(id));
    }
}
