package com.example.@@PROJECT_SNAKE@@.api;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

/** Integration tests for the example slice — nominal and error paths (A4). */
@SpringBootTest
@AutoConfigureMockMvc
class ExampleApiIntegrationTest {

    @Autowired private MockMvc mockMvc;

    @Test
    void create_WithValidPayload_Returns201() throws Exception {
        mockMvc.perform(post("/examples")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"integration-nominal\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.name").value("integration-nominal"));
    }

    @Test
    void create_WithDuplicateName_Returns409() throws Exception {
        String payload = "{\"name\":\"integration-duplicate\"}";
        mockMvc.perform(post("/examples").contentType(MediaType.APPLICATION_JSON).content(payload));

        mockMvc.perform(post("/examples").contentType(MediaType.APPLICATION_JSON).content(payload))
                .andExpect(status().isConflict());
    }

    @Test
    void create_WithBlankName_Returns400() throws Exception {
        mockMvc.perform(post("/examples")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void read_WithUnknownId_Returns404() throws Exception {
        mockMvc.perform(get("/examples/unknown-id")).andExpect(status().isNotFound());
    }
}
