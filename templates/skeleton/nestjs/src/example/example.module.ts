import { Module } from '@nestjs/common';

import { ExampleController } from './example.controller';
import { ExampleRepository, InMemoryExampleRepository } from './example.repository';
import { ExampleService } from './example.service';

/** Wires the example slice: controller -> service -> repository. */
@Module({
  controllers: [ExampleController],
  providers: [ExampleService, { provide: ExampleRepository, useClass: InMemoryExampleRepository }],
})
export class ExampleModule {}
