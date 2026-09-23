package com.example.@@PROJECT_SNAKE@@.api;

import com.example.@@PROJECT_SNAKE@@.domain.Example;
import com.example.@@PROJECT_SNAKE@@.domain.ExampleService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

/**
 * HTTP layer of the example slice. Business rules live in the service; domain
 * errors become status codes in {@link ApiExceptionMappers}.
 */
@Path("/examples")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class ExampleResource {

    private final ExampleService service;

    /**
     * Creates the resource.
     *
     * @param service the example service
     */
    public ExampleResource(ExampleService service) {
        this.service = service;
    }

    /**
     * Payload accepted when creating an example.
     *
     * @param name the label to register
     */
    public record CreateExampleRequest(@NotBlank @Size(min = 1, max = 120) String name) {}

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

    /**
     * Creates an example.
     *
     * @param request the validated payload
     * @return 201 with the created example
     */
    @POST
    public Response create(@Valid CreateExampleRequest request) {
        return Response.status(Response.Status.CREATED)
                .entity(ExampleResponse.from(service.create(request.name())))
                .build();
    }

    /**
     * Returns one example.
     *
     * @param id the identifier to look up
     * @return the example
     */
    @GET
    @Path("/{id}")
    public ExampleResponse read(@PathParam("id") String id) {
        return ExampleResponse.from(service.get(id));
    }
}
