import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';

import { ExampleModule } from '../src/example/example.module';
import { HealthModule } from '../src/health/health.module';

/** Integration tests for the health endpoints and the example slice (SPEC-001). */
describe('Health and example endpoints', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [HealthModule, ExampleModule],
    }).compile();

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true }));
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('live_WhenProcessIsRunning_Returns200', async () => {
    const response = await request(app.getHttpServer()).get('/health/live');

    expect(response.status).toBe(200);
    expect(response.body).toEqual({ status: 'alive' });
  });

  it('ready_WhenDependenciesAreReachable_Returns200', async () => {
    const response = await request(app.getHttpServer()).get('/health/ready');

    expect(response.status).toBe(200);
    expect(response.body.status).toBe('ready');
  });

  it('health_Response_ContainsNoSecret', async () => {
    const response = await request(app.getHttpServer()).get('/health/ready');

    expect(JSON.stringify(response.body).toLowerCase()).not.toMatch(/password|secret|token|dsn/);
  });

  it('create_WithDuplicateName_Returns409', async () => {
    const payload = { name: 'e2e-duplicate' };
    await request(app.getHttpServer()).post('/examples').send(payload).expect(201);

    await request(app.getHttpServer()).post('/examples').send(payload).expect(409);
  });

  it('create_WithEmptyName_Returns400', async () => {
    await request(app.getHttpServer()).post('/examples').send({ name: '' }).expect(400);
  });

  it('read_WithUnknownId_Returns404', async () => {
    await request(app.getHttpServer()).get('/examples/unknown-id').expect(404);
  });
});
