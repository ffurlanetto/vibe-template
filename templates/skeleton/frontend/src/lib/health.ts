import { requestJson } from './api';

/** The readiness payload exposed by the backend (SPEC-001). */
export interface ReadinessResponse {
  status: 'ready' | 'unavailable';
  failing?: string[];
}

/**
 * Asks the backend whether it can serve traffic.
 *
 * @param baseUrl - the API origin
 * @returns the readiness payload
 * @throws ApiError when the backend cannot be reached or answers 503
 */
export function fetchReadiness(baseUrl: string): Promise<ReadinessResponse> {
  return requestJson<ReadinessResponse>(baseUrl, '/health/ready');
}
