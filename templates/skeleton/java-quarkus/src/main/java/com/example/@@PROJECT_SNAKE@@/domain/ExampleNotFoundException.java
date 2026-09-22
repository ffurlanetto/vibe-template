package com.example.@@PROJECT_SNAKE@@.domain;

/** Thrown when no example carries the requested identifier. */
public class ExampleNotFoundException extends RuntimeException {

    /**
     * Creates the exception.
     *
     * @param id the identifier that could not be found
     */
    public ExampleNotFoundException(String id) {
        super("no example with id '%s'".formatted(id));
    }
}
