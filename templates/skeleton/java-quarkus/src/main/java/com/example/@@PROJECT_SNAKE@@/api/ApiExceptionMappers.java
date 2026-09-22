package com.example.@@PROJECT_SNAKE@@.api;

import com.example.@@PROJECT_SNAKE@@.domain.DuplicateExampleNameException;
import com.example.@@PROJECT_SNAKE@@.domain.ExampleNotFoundException;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;
import java.util.Map;
import org.jboss.logging.Logger;

/**
 * Maps domain errors to HTTP status codes.
 *
 * <p>Client-facing messages stay generic; the detail goes to the log (A3, A5).
 */
public final class ApiExceptionMappers {

    private static final Logger LOG = Logger.getLogger(ApiExceptionMappers.class);

    private ApiExceptionMappers() {}

    /** Turns a duplicate name into 409 Conflict. */
    @Provider
    public static class DuplicateMapper implements ExceptionMapper<DuplicateExampleNameException> {

        @Override
        public Response toResponse(DuplicateExampleNameException exception) {
            LOG.infof("rejected duplicate example: %s", exception.getMessage());
            return Response.status(Response.Status.CONFLICT)
                    .entity(Map.of("error", "name already in use"))
                    .build();
        }
    }

    /** Turns a missing example into 404 Not Found. */
    @Provider
    public static class NotFoundMapper implements ExceptionMapper<ExampleNotFoundException> {

        @Override
        public Response toResponse(ExampleNotFoundException exception) {
            LOG.infof("example not found: %s", exception.getMessage());
            return Response.status(Response.Status.NOT_FOUND)
                    .entity(Map.of("error", "not found"))
                    .build();
        }
    }
}
