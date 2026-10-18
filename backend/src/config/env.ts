import { readFileSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { generateKeyPairSync } from 'node:crypto';
import { resolve } from 'node:path';
import { z } from 'zod';

const bool = z
  .union([z.boolean(), z.string()])
  .transform((v) => (typeof v === 'boolean' ? v : ['1', 'true', 'yes', 'on'].includes(v.toLowerCase())));
const csv = z.string().default('').transform((s) => s.split(',').map((x) => x.trim()).filter(Boolean));

export const envSchema = z.object({
  APP_ENV: z.enum(['development', 'test', 'staging', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(4000),
  LOG_LEVEL: z.string().default('info'),
  LOG_PRETTY: bool.default(false),
  PUBLIC_BASE_URL: z.string().url().default('http://localhost:4000'),
  WEB_BASE_URL: z.string().url().default('https://baj-go.com'),
  CORS_ORIGINS: csv,

  DATABASE_URL: z.string().default('postgres://bajgo:bajgo@localhost:5432/bajgo'),
  REDIS_URL: z.string().default('redis://localhost:6379'),

  JWT_PRIVATE_KEY: z.string().optional(),
  JWT_PUBLIC_KEY: z.string().optional(),
  JWT_PRIVATE_KEY_FILE: z.string().default('./keys/dev-private.pem'),
  JWT_PUBLIC_KEY_FILE: z.string().default('./keys/dev-public.pem'),
  JWT_ACCESS_TTL_S: z.coerce.number().int().positive().default(900),
  JWT_REFRESH_TTL_S: z.coerce.number().int().positive().default(30 * 24 * 3600),

  SMS_PROVIDER: z.enum(['console', 'http']).default('console'),
  SMS_HTTP_URL: z.string().optional(),
  SMS_HTTP_TOKEN: z.string().optional(),
  SMS_SENDER_ID: z.string().default('BajGo'),
  OTP_PEPPER: z.string().default('dev-pepper'),
  OTP_TEST_NUMBERS: csv,
  OTP_TEST_CODE: z.string().regex(/^\d{6}$/).default('123456'),

  ROUTING_PROVIDER: z.enum(['haversine', 'osrm']).default('haversine'),
  OSRM_URL: z.string().default('https://router.project-osrm.org'),
  GEOCODING_PROVIDER: z.enum(['local', 'nominatim']).default('local'),
  NOMINATIM_URL: z.string().default('https://nominatim.openstreetmap.org'),

  DISPATCH_INLINE: bool.default(false),
  RUN_WORKER_IN_API: bool.default(true),

  SANDBOX_MM_DELAY_MS: z.coerce.number().int().nonnegative().default(3000),
  SANDBOX_WEBHOOK_SECRET: z.string().default('sandbox-secret'),
  EVC_PLUS_API_URL: z.string().optional(),
  EVC_PLUS_MERCHANT_ID: z.string().optional(),
  EVC_PLUS_API_KEY: z.string().optional(),
  ZAAD_API_URL: z.string().optional(),
  ZAAD_MERCHANT_ID: z.string().optional(),
  ZAAD_API_KEY: z.string().optional(),
  SAHAL_API_URL: z.string().optional(),
  SAHAL_MERCHANT_ID: z.string().optional(),
  SAHAL_API_KEY: z.string().optional(),

  PUSH_PROVIDER: z.enum(['console', 'fcm']).default('console'),
  FCM_SERVICE_ACCOUNT_JSON: z.string().optional(),

  UPLOAD_DIR: z.string().default('./uploads'),
  STORAGE_PROVIDER: z.enum(['local', 's3']).default('local'),
  S3_BUCKET: z.string().optional(),
  S3_REGION: z.string().optional(),
  S3_ENDPOINT: z.string().optional(),
  S3_ACCESS_KEY_ID: z.string().optional(),
  S3_SECRET_ACCESS_KEY: z.string().optional(),

  DEMO_ADMIN_EMAIL: z.string().email().default('admin@baj-go.com'),
  DEMO_ADMIN_PASSWORD: z.string().min(8).default('BajGo-admin-2026'),
});

export type Env = z.infer<typeof envSchema> & {
  isProduction: boolean;
  jwtPrivateKey: string;
  jwtPublicKey: string;
};

export const ENV = Symbol('ENV');

function loadDotEnv() {
  const file = resolve(process.cwd(), '.env');
  if (!existsSync(file)) return;
  for (const line of readFileSync(file, 'utf8').split('\n')) {
    const m = /^\s*([A-Z0-9_]+)\s*=\s*(.*?)\s*$/.exec(line);
    if (!m || line.trim().startsWith('#')) continue;
    if (process.env[m[1]] === undefined) process.env[m[1]] = m[2].replace(/^"(.*)"$/, '$1').replace(/\s+#.*$/, '');
  }
}

function resolveJwtKeys(e: z.infer<typeof envSchema>): { priv: string; pub: string } {
  if (e.JWT_PRIVATE_KEY && e.JWT_PUBLIC_KEY) {
    return { priv: e.JWT_PRIVATE_KEY.replace(/\\n/g, '\n'), pub: e.JWT_PUBLIC_KEY.replace(/\\n/g, '\n') };
  }
  const privFile = resolve(process.cwd(), e.JWT_PRIVATE_KEY_FILE);
  const pubFile = resolve(process.cwd(), e.JWT_PUBLIC_KEY_FILE);
  if (existsSync(privFile) && existsSync(pubFile)) {
    return { priv: readFileSync(privFile, 'utf8'), pub: readFileSync(pubFile, 'utf8') };
  }
  if (e.APP_ENV === 'production') {
    throw new Error('JWT keys missing: set JWT_PRIVATE_KEY/JWT_PUBLIC_KEY or the *_FILE paths');
  }
  // Non-production convenience: generate a dev key pair once and persist it.
  const { privateKey, publicKey } = generateKeyPairSync('rsa', {
    modulusLength: 2048,
    publicKeyEncoding: { type: 'spki', format: 'pem' },
    privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
  });
  try {
    mkdirSync(resolve(privFile, '..'), { recursive: true });
    writeFileSync(privFile, privateKey, { mode: 0o600 });
    writeFileSync(pubFile, publicKey);
  } catch {
    /* read-only FS: keep in memory */
  }
  return { priv: privateKey, pub: publicKey };
}

let cached: Env | undefined;
export function loadEnv(): Env {
  if (cached) return cached;
  loadDotEnv();
  const parsed = envSchema.safeParse(process.env);
  if (!parsed.success) {
    throw new Error(`Invalid environment: ${parsed.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join('; ')}`);
  }
  const e = parsed.data;
  const keys = resolveJwtKeys(e);
  cached = { ...e, isProduction: e.APP_ENV === 'production', jwtPrivateKey: keys.priv, jwtPublicKey: keys.pub };
  return cached;
}
