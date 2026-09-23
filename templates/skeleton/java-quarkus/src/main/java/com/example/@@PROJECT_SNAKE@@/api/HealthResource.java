package com.example.@@PROJECT_SNAKE@@.api;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.List;
import java.util.Map;
import org.jboss.logging.Logger;

/**
 * Liveness and readiness endpoints (AGENTS.md A8, SPEC-001).
 *
 * <p>Explicit paths rather than SmallRye's /q/health, so the contract stays
 * stable and identical across the stacks this organisation runs.
 */
@Path("/health")
@Produces(MediaType.APPLICATION_JSON)
public class HealthResource {

    private static final Logger LOG = Logger.getLogger(HealthResource.class);

    /**
     * Reports that the process is running. Touches no dependency.
     *
     * @return 200 with a minimal body
     */
    @GET
    @Path("/live")
    public Response live() {
        return Response.ok(Map.of("status", "alive")).build();
    }

    /**
     * Reports whether every critical dependency is reachable.
     *
     * <p>Add one probe per dependency declared in section B2.
     *
     * @return 200 when ready, 503 naming the failing dependencies otherwise
     */
    @GET
    @Path("/ready")
    public Response ready() {
        List<String> failing = List.of();

        if (!failing.isEmpty()) {
            // The dependency name is safe to expose; its DSN is not (A5).
            LOG.warnf("readiness check failed: %s", failing);
            return Response.status(Response.Status.SERVICE_UNAVAILABLE)
                    .entity(Map.of("status", "unavailable", "failing", failing))
                    .build();
        }

        return Response.ok(Map.of("status", "ready")).build();
    }
}
