import { Module } from '@nestjs/common';

import { HealthController } from './health.controller.js';

/** Wires the health endpoints. */
@Module({ controllers: [HealthController] })
export class HealthModule {}
