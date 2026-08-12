import { z } from 'zod';

/**
 * Environment variables always arrive as strings, even numeric ones.
 * Validating the string first and only then coercing keeps the error
 * message readable: a missing variable reports "expected string,
 * received undefined" instead of a confusing "received NaN".
 */
const port = z
  .string()
  .min(1)
  .transform(Number)
  .pipe(z.number().int().min(1).max(65535));

export const envSchema = z.object({
  PORT: port,
  DB_HOST: z.string().min(1),
  DB_PORT: port,
  DB_NAME: z.string().min(1),
  DB_USER: z.string().min(1),
  DB_PASSWORD: z.string().min(1),
});

export type Env = z.infer<typeof envSchema>;

export function validateEnv(config: Record<string, unknown>): Env {
  const result = envSchema.safeParse(config);

  if (!result.success) {
    throw new Error(
      `Invalid environment variables:\n${z.prettifyError(result.error)}`,
    );
  }

  return result.data;
}
