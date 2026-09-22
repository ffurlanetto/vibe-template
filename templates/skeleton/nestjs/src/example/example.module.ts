import { Module } from '@nestjs/common';

import { ExampleController } from './example.controller.js';
import { ExampleRepository, InMemoryExampleRepository } from './example.repository.js';
import { ExampleService } from './example.service.js';

/** Wires the example slice: controller -> service -> repository. */
@Module({
  controllers: [ExampleController],
  providers: [ExampleService, { provide: ExampleRepository, useClass: InMemoryExampleRepository }],
})
export class ExampleModule {}
