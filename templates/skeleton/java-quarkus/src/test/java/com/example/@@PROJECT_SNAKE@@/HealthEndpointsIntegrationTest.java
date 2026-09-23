package com.example.@@PROJECT_SNAKE@@;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.is;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

/** Integration tests for the health endpoints (SPEC-001). */
@QuarkusTest
class HealthEndpointsIntegrationTest {

    @Test
    void live_WhenProcessIsRunning_Returns200() {
        given().when().get("/health/live").then().statusCode(200).body("status", is("alive"));
    }

    @Test
    void ready_WhenDependenciesAreReachable_Returns200() {
        given().when().get("/health/ready").then().statusCode(200).body("status", is("ready"));
    }

    @Test
    void create_WithDuplicateName_Returns409() {
        String payload = "{\"name\":\"quarkus-duplicate\"}";
        given().contentType("application/json").body(payload).when().post("/examples")
                .then().statusCode(201);

        given().contentType("application/json").body(payload).when().post("/examples")
                .then().statusCode(409);
    }

    @Test
    void read_WithUnknownId_Returns404() {
        given().when().get("/examples/unknown-id").then().statusCode(404);
    }
}
