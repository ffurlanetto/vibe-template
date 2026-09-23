package com.example.@@PROJECT_SNAKE@@.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

/** Integration tests for the health endpoints (SPEC-001). */
@SpringBootTest
@AutoConfigureMockMvc
class HealthEndpointsIntegrationTest {

    @Autowired private MockMvc mockMvc;

    @Test
    void live_WhenProcessIsRunning_Returns200() throws Exception {
        mockMvc.perform(get("/health/live"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("alive"));
    }

    @Test
    void ready_WhenDependenciesAreReachable_Returns200() throws Exception {
        mockMvc.perform(get("/health/ready"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ready"));
    }

    @Test
    void health_Response_ContainsNoSecret() throws Exception {
        String body = mockMvc.perform(get("/health/ready"))
                .andReturn().getResponse().getContentAsString().toLowerCase();

        assertThat(body).doesNotContain("password", "secret", "token", "dsn");
    }
}
