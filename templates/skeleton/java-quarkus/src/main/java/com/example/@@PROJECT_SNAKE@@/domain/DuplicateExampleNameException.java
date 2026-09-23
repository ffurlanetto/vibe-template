package com.example.@@PROJECT_SNAKE@@.domain;

/** Thrown when the requested name is already taken — an expected business error. */
public class DuplicateExampleNameException extends RuntimeException {

    /**
     * Creates the exception.
     *
     * @param name the name that was already in use
     */
    public DuplicateExampleNameException(String name) {
        super("an example named '%s' already exists".formatted(name));
    }
}
