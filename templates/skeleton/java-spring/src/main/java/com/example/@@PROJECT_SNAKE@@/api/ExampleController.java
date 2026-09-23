package com.example.@@PROJECT_SNAKE@@.api;

import com.example.@@PROJECT_SNAKE@@.api.dto.CreateExampleRequest;
import com.example.@@PROJECT_SNAKE@@.api.dto.ExampleResponse;
import com.example.@@PROJECT_SNAKE@@.domain.ExampleService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * HTTP layer of the example slice.
 *
 * <p>The controller translates between HTTP and the service. Business rules
 * live in the service; expected domain errors become status codes in
 * {@link ApiExceptionHandler}.
 */
@RestController
@RequestMapping("/examples")
public class ExampleController {

    private final ExampleService service;

    /**
     * Creates the controller.
     *
     * @param service the example service
     */
    public ExampleController(ExampleService service) {
        this.service = service;
    }

    /**
     * Creates an example.
     *
     * @param request the validated payload
     * @return 201 with the created example
     */
    @PostMapping
    public ResponseEntity<ExampleResponse> create(@Valid @RequestBody CreateExampleRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ExampleResponse.from(service.create(request.name())));
    }

    /**
     * Returns one example.
     *
     * @param id the identifier to look up
     * @return 200 with the example
     */
    @GetMapping("/{id}")
    public ExampleResponse read(@PathVariable String id) {
        return ExampleResponse.from(service.get(id));
    }
}
