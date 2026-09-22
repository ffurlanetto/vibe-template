/**
 * Typed HTTP client.
 *
 * Every failure is wrapped with context rather than swallowed, and the caller
 * always learns whether the request failed on the network, on the status, or on
 * the payload shape (AGENTS.md A3).
 */

/** An HTTP call that did not produce a usable response. */
export class ApiError extends Error {
  constructor(
    message: string,
    readonly status: number | null,
    options?: { cause?: unknown },
  ) {
    super(message, options);
    this.name = 'ApiError';
  }
}

export interface RequestOptions {
  signal?: AbortSignal;
  timeoutMs?: number;
}

/**
 * Performs a JSON request and returns the parsed body.
 *
 * @param baseUrl - origin the path is resolved against
 * @param path - path starting with a slash
 * @param init - fetch options; the JSON content type is added for you
 * @returns the parsed response body
 * @throws ApiError on a network failure, a non-2xx status, or an unparsable body
 */
export async function requestJson<T>(
  baseUrl: string,
  path: string,
  init: RequestInit = {},
  options: RequestOptions = {},
): Promise<T> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), options.timeoutMs ?? 10_000);

  let response: Response;
  try {
    response = await fetch(`${baseUrl}${path}`, {
      ...init,
      signal: options.signal ?? controller.signal,
      headers: { 'Content-Type': 'application/json', ...init.headers },
    });
  } catch (cause) {
    throw new ApiError(`request to ${path} failed`, null, { cause });
  } finally {
    clearTimeout(timeout);
  }

  if (!response.ok) {
    // The status is useful to the caller; the server's message may not be safe
    // to show, so it is not propagated verbatim (A5).
    throw new ApiError(`request to ${path} returned ${response.status}`, response.status);
  }

  try {
    return (await response.json()) as T;
  } catch (cause) {
    throw new ApiError(`response from ${path} was not valid JSON`, response.status, { cause });
  }
}
