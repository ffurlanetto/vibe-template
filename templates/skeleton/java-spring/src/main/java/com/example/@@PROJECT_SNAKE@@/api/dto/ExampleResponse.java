package com.example.@@PROJECT_SNAKE@@.api.dto;

import com.example.@@PROJECT_SNAKE@@.domain.Example;

/**
 * Representation returned to clients.
 *
 * @param id   the example identifier
 * @param name the example label
 */
public record ExampleResponse(String id, String name) {

    /**
     * Maps a domain entity to its API representation.
     *
     * @param example the domain entity
     * @return the response payload
     */
    public static ExampleResponse from(Example example) {
        return new ExampleResponse(example.id(), example.name());
    }
}
