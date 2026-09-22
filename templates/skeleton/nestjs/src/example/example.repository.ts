import { randomUUID } from 'node:crypto';

import { Injectable } from '@nestjs/common';

/** An example entity. */
export interface Example {
  id: string;
  name: string;
}

/**
 * Persistence contract the service depends on. Swap the in-memory
 * implementation for the datastore declared in B2 without touching the service.
 */
export abstract class ExampleRepository {
  abstract add(name: string): Example;
  abstract get(id: string): Example | undefined;
  abstract existsByName(name: string): boolean;
}

/** Reference implementation — replace with your datastore. */
@Injectable()
export class InMemoryExampleRepository extends ExampleRepository {
  private readonly items = new Map<string, Example>();

  add(name: string): Example {
    // randomUUID is cryptographically random — never Math.random (A5).
    const example: Example = { id: randomUUID(), name };
    this.items.set(example.id, example);
    return example;
  }

  get(id: string): Example | undefined {
    return this.items.get(id);
  }

  existsByName(name: string): boolean {
    return [...this.items.values()].some((item) => item.name === name);
  }
}
