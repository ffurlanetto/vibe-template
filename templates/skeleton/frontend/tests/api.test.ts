import { afterEach, describe, expect, it, vi } from 'vitest';

import { ApiError, requestJson } from '../src/lib/api';

describe('requestJson', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('requestJson_WithSuccessfulResponse_ReturnsParsedBody', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(new Response('{"status":"ready"}', { status: 200 })));

    await expect(requestJson<{ status: string }>('', '/health/ready')).resolves.toEqual({
      status: 'ready',
    });
  });

  it('requestJson_WithErrorStatus_ThrowsApiErrorCarryingTheStatus', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(new Response('{}', { status: 503 })));

    await expect(requestJson('', '/health/ready')).rejects.toMatchObject({
      name: 'ApiError',
      status: 503,
    });
  });

  it('requestJson_WithNetworkFailure_ThrowsApiErrorWithNullStatus', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('offline')));

    const error = await requestJson('', '/health/ready').catch((caught: unknown) => caught);

    expect(error).toBeInstanceOf(ApiError);
    expect((error as ApiError).status).toBeNull();
  });

  it('requestJson_WithMalformedBody_ThrowsApiError', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(new Response('not json', { status: 200 })));

    await expect(requestJson('', '/health/ready')).rejects.toBeInstanceOf(ApiError);
  });
});
