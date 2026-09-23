package com.example.@@PROJECT_SNAKE@@.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Payload accepted when creating an example. Validated at the boundary (A3).
 *
 * @param name the label to register
 */
public record CreateExampleRequest(
        @NotBlank @Size(min = 1, max = 120) String name) {}
