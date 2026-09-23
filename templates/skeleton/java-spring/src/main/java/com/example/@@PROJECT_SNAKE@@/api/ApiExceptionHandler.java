package com.example.@@PROJECT_SNAKE@@.api;

import com.example.@@PROJECT_SNAKE@@.domain.DuplicateExampleNameException;
import com.example.@@PROJECT_SNAKE@@.domain.ExampleNotFoundException;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * Maps domain errors to HTTP status codes.
 *
 * <p>Client-facing messages stay generic; the detail goes to the structured log
 * (AGENTS.md A3, A5).
 */
@RestControllerAdvice
public class ApiExceptionHandler {

    private static final Logger LOG = LoggerFactory.getLogger(ApiExceptionHandler.class);

    /**
     * Turns a duplicate name into 409 Conflict.
     *
     * @param exception the domain error
     * @return the client response
     */
    @ExceptionHandler(DuplicateExampleNameException.class)
    public ResponseEntity<Map<String, String>> onDuplicate(DuplicateExampleNameException exception) {
        LOG.info("rejected duplicate example: {}", exception.getMessage());
        return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of("error", "name already in use"));
    }

    /**
     * Turns a missing example into 404 Not Found.
     *
     * @param exception the domain error
     * @return the client response
     */
    @ExceptionHandler(ExampleNotFoundException.class)
    public ResponseEntity<Map<String, String>> onNotFound(ExampleNotFoundException exception) {
        LOG.info("example not found: {}", exception.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", "not found"));
    }
}
