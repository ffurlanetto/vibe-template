import {
  Body,
  ConflictException,
  Controller,
  Get,
  NotFoundException,
  Param,
  Post,
} from '@nestjs/common';

import { CreateExampleDto } from './example.dto.js';
import type { Example } from './example.repository.js';
import { DuplicateExampleNameError, ExampleNotFoundError, ExampleService } from './example.service.js';

/**
 * HTTP layer of the example slice. Expected domain errors become status codes
 * here; the service stays framework-free (AGENTS.md A3).
 */
@Controller('examples')
export class ExampleController {
  constructor(private readonly service: ExampleService) {}

  /** Creates an example, rejecting a duplicate name with 409. */
  @Post()
  create(@Body() payload: CreateExampleDto): Example {
    try {
      return this.service.create(payload.name);
    } catch (error) {
      if (error instanceof DuplicateExampleNameError) {
        // Generic message to the client, detail stays in the log (A3, A5).
        throw new ConflictException('name already in use');
      }
      throw error;
    }
  }

  /** Returns one example, or 404 when it does not exist. */
  @Get(':id')
  read(@Param('id') id: string): Example {
    try {
      return this.service.get(id);
    } catch (error) {
      if (error instanceof ExampleNotFoundError) {
        throw new NotFoundException('not found');
      }
      throw error;
    }
  }
}
