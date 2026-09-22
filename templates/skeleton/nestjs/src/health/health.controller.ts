import { Controller, Get, HttpStatus, Logger, Res } from '@nestjs/common';
import type { Response } from 'express';

/**
 * Liveness and readiness endpoints (AGENTS.md A8, SPEC-001).
 */
@Controller('health')
export class HealthController {
  private readonly logger = new Logger(HealthController.name);

  /** Reports that the process is running. Touches no dependency. */
  @Get('live')
  live(): { status: string } {
    return { status: 'alive' };
  }

  /**
   * Reports whether every critical dependency is reachable.
   *
   * Add one probe per dependency declared in section B2. Keep each probe cheap
   * and bounded: this endpoint answers in under 100 ms (SPEC-001).
   */
  @Get('ready')
  ready(@Res({ passthrough: true }) response: Response): { status: string; failing?: string[] } {
    const failing: string[] = [];

    if (failing.length > 0) {
      // The dependency name is safe to expose; its DSN is not (A5).
      this.logger.warn({ message: 'readiness check failed', failing });
      response.status(HttpStatus.SERVICE_UNAVAILABLE);
      return { status: 'unavailable', failing };
    }

    return { status: 'ready' };
  }
}
