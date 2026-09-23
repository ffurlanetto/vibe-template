/**
 * Runtime configuration, read from the build-time environment (AGENTS.md A5).
 *
 * Only `VITE_`-prefixed variables reach the browser bundle. Never put a secret
 * in one: everything here is public once the app ships.
 */
export interface AppConfig {
  apiBaseUrl: string;
  appEnv: 'development' | 'staging' | 'production';
}

/**
 * Reads the configuration, failing fast when a required value is missing (A3).
 *
 * @throws Error when VITE_API_BASE_URL is absent in a production build.
 */
export function loadConfig(env: ImportMetaEnv = import.meta.env): AppConfig {
  const appEnv = (env.VITE_APP_ENV as AppConfig['appEnv']) ?? 'development';
  const apiBaseUrl = env.VITE_API_BASE_URL ?? '';

  if (appEnv === 'production' && !apiBaseUrl) {
    throw new Error('VITE_API_BASE_URL is required in a production build');
  }

  return { apiBaseUrl, appEnv };
}
