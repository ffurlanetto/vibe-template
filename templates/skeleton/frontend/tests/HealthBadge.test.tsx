import { cleanup, render, screen, waitFor } from '@testing-library/react';
import { afterEach, describe, expect, it, vi } from 'vitest';

import { HealthBadge } from '../src/components/HealthBadge';

describe('HealthBadge', () => {
  afterEach(() => {
    cleanup();
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it('HealthBadge_WhenBackendIsReady_ShowsReady', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(new Response('{"status":"ready"}', { status: 200 })));

    render(<HealthBadge apiBaseUrl="" />);

    await waitFor(() => expect(screen.getByRole('status')).toHaveAttribute('data-status', 'ready'));
  });

  it('HealthBadge_WhenBackendIsUnreachable_ShowsUnavailable', async () => {
    vi.spyOn(console, 'warn').mockImplementation(() => {});
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('offline')));

    render(<HealthBadge apiBaseUrl="" />);

    await waitFor(() =>
      expect(screen.getByRole('status')).toHaveAttribute('data-status', 'unavailable'),
    );
  });
});
