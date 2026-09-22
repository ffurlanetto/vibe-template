package com.example.@@PROJECT_SNAKE@@.infrastructure;

import com.example.@@PROJECT_SNAKE@@.domain.Example;
import com.example.@@PROJECT_SNAKE@@.domain.ExampleRepository;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Repository;

/**
 * Reference implementation of {@link ExampleRepository}.
 *
 * <p>Replace it with the datastore declared in section B2; the domain and the
 * API layers do not change when you do.
 */
@Repository
public class InMemoryExampleRepository implements ExampleRepository {

    private final Map<String, Example> items = new ConcurrentHashMap<>();

    @Override
    public Example add(String name) {
        Example example = new Example(UUID.randomUUID().toString(), name);
        items.put(example.id(), example);
        return example;
    }

    @Override
    public Optional<Example> findById(String id) {
        return Optional.ofNullable(items.get(id));
    }

    @Override
    public boolean existsByName(String name) {
        return items.values().stream().anyMatch(item -> item.name().equals(name));
    }
}
