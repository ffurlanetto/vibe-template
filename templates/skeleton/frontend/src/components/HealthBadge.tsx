import { useEffect, useState } from 'react';

import { ApiError } from '../lib/api';
import { fetchReadiness } from '../lib/health';

type Status = 'loading' | 'ready' | 'unavailable';

export interface HealthBadgeProps {
  /** Origin of the API to probe. */
  apiBaseUrl: string;
}

/**
 * Shows whether the backend is ready.
 *
 * The walking skeleton's visible end: it proves the app, the client and the API
 * contract line up (SPEC-001).
 */
export function HealthBadge({ apiBaseUrl }: HealthBadgeProps) {
  const [status, setStatus] = useState<Status>('loading');

  useEffect(() => {
    let cancelled = false;

    fetchReadiness(apiBaseUrl)
      .then((payload) => {
        if (!cancelled) setStatus(payload.status === 'ready' ? 'ready' : 'unavailable');
      })
      .catch((error: unknown) => {
        // Never swallow: surface a degraded state and keep the detail for the console.
        if (error instanceof ApiError) {
          console.warn('readiness probe failed', { status: error.status });
        }
        if (!cancelled) setStatus('unavailable');
      });

    return () => {
      cancelled = true;
    };
  }, [apiBaseUrl]);

  return (
    <span role="status" aria-live="polite" data-status={status}>
      {status === 'loading' ? 'Checking backend…' : `Backend: ${status}`}
    </span>
  );
}
