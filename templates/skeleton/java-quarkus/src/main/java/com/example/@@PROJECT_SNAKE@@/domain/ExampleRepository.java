package com.example.@@PROJECT_SNAKE@@.domain;

import java.util.Optional;

/** Persistence contract for examples — owned by the domain (AGENTS.md A3). */
public interface ExampleRepository {

    /**
     * Persists a new example.
     *
     * @param name the label to register
     * @return the created example
     */
    Example add(String name);

    /**
     * Finds one example.
     *
     * @param id the identifier to look up
     * @return the example, or empty when none matches
     */
    Optional<Example> findById(String id);

    /**
     * Reports whether a name is already taken.
     *
     * @param name the label to check
     * @return true when an example already uses it
     */
    boolean existsByName(String name);
}
