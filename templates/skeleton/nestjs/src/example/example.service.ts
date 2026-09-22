import { Injectable } from '@nestjs/common';

import { Example, ExampleRepository } from './example.repository';

/** Raised when the requested name is already taken — an expected error. */
export class DuplicateExampleNameError extends Error {
  constructor(readonly name_: string) {
    super(`an example named '${name_}' already exists`);
    this.name = 'DuplicateExampleNameError';
  }
}

/** Raised when no example carries the requested identifier. */
export class ExampleNotFoundError extends Error {
  constructor(readonly id: string) {
    super(`no example with id '${id}'`);
    this.name = 'ExampleNotFoundError';
  }
}

/** Business rules for examples. No HTTP type belongs in this class (A3). */
@Injectable()
export class ExampleService {
  constructor(private readonly repository: ExampleRepository) {}

  /**
   * Registers a new example, enforcing name uniqueness.
   *
   * @throws DuplicateExampleNameError when the name is already in use.
   */
  create(name: string): Example {
    if (this.repository.existsByName(name)) {
      throw new DuplicateExampleNameError(name);
    }
    return this.repository.add(name);
  }

  /**
   * Returns one example.
   *
   * @throws ExampleNotFoundError when no example carries this identifier.
   */
  get(id: string): Example {
    const example = this.repository.get(id);
    if (!example) {
      throw new ExampleNotFoundError(id);
    }
    return example;
  }
}
