package com.example.@@PROJECT_SNAKE@@.api;

import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Liveness and readiness endpoints.
 *
 * <p>See AGENTS.md A8 and docs/specs/SPEC-001-health-endpoints.md. These are
 * deliberately separate from Actuator so the contract stays explicit and stable.
 */
@RestController
@RequestMapping("/health")
public class HealthController {

    private static final Logger LOG = LoggerFactory.getLogger(HealthController.class);

    /**
     * Reports that the process is running. Touches no dependency.
     *
     * @return 200 with a minimal body
     */
    @GetMapping("/live")
    public ResponseEntity<Map<String, String>> live() {
        return ResponseEntity.ok(Map.of("status", "alive"));
    }

    /**
     * Reports whether every critical dependency is reachable.
     *
     * <p>Add one probe per dependency declared in section B2. Keep each probe
     * cheap and bounded: this endpoint answers in under 100 ms (SPEC-001).
     *
     * @return 200 when ready, 503 naming the failing dependencies otherwise
     */
    @GetMapping("/ready")
    public ResponseEntity<Map<String, Object>> ready() {
        List<String> failing = List.of();

        if (!failing.isEmpty()) {
            // The dependency name is safe to expose; its DSN is not (A5).
            LOG.warn("readiness check failed: {}", failing);
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(Map.of("status", "unavailable", "failing", failing));
        }

        return ResponseEntity.ok(Map.of("status", "ready"));
    }
}
