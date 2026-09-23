import { describe, expect, it } from 'vitest';

import { loadConfig } from '../src/lib/config';

describe('loadConfig', () => {
  it('loadConfig_WithDefaults_ReturnsDevelopmentConfig', () => {
    const config = loadConfig({} as ImportMetaEnv);

    expect(config.appEnv).toBe('development');
  });

  it('loadConfig_InProductionWithoutApiUrl_ThrowsAtStartup', () => {
    expect(() => loadConfig({ VITE_APP_ENV: 'production' } as unknown as ImportMetaEnv)).toThrow(
      /VITE_API_BASE_URL/,
    );
  });

  it('loadConfig_InProductionWithApiUrl_ReturnsConfig', () => {
    const config = loadConfig({
      VITE_APP_ENV: 'production',
      VITE_API_BASE_URL: 'https://api.example.com',
    } as unknown as ImportMetaEnv);

    expect(config.apiBaseUrl).toBe('https://api.example.com');
  });
});
