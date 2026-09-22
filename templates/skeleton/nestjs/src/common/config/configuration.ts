/**
 * Application settings, read from the environment (AGENTS.md A5).
 *
 * Never hardcode a credential: every value comes from the environment, and
 * .env.example documents the full set.
 */
export interface AppConfig {
  appName: string;
  appEnv: 'development' | 'staging' | 'production';
  logLevel: string;
  port: number;
}

/**
 * Reads and validates the configuration, failing fast on an invalid value (A3).
 *
 * @throws Error when a variable is present but cannot be parsed.
 */
export function loadConfig(env: NodeJS.ProcessEnv = process.env): AppConfig {
  const port = Number.parseInt(env.PORT ?? '8080', 10);
  if (Number.isNaN(port)) {
    throw new Error(`PORT must be an integer, got '${env.PORT}'`);
  }

  return {
    appName: env.APP_NAME ?? '@@PROJECT@@',
    appEnv: (env.APP_ENV as AppConfig['appEnv']) ?? 'development',
    logLevel: env.LOG_LEVEL ?? 'info',
    port,
  };
}
