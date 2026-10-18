#!/usr/bin/env node
// Tiny migration runner: applies drizzle/*.sql in lexical order, once each,
// recording them in schema_migrations. Never uses drizzle-kit push.
import postgres from 'postgres';
import { readdirSync, readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

const dir = join(dirname(fileURLToPath(import.meta.url)), '..', 'drizzle');
const url = process.env.DATABASE_URL ?? 'postgres://bajgo:bajgo@localhost:5432/bajgo';
const sql = postgres(url, { max: 1, onnotice: () => {} });

async function main() {
  await sql`CREATE TABLE IF NOT EXISTS schema_migrations (
    name text PRIMARY KEY, checksum text NOT NULL, applied_at timestamptz NOT NULL DEFAULT now())`;
  const applied = new Set((await sql`SELECT name FROM schema_migrations`).map((r) => r.name));
  // Migrations 0001/0002 may have been applied by hand before this runner existed:
  // detect that by the presence of core tables and record them without re-running.
  const [{ exists }] = await sql`SELECT to_regclass('public.bookings') IS NOT NULL AS exists`;
  const files = readdirSync(dir).filter((f) => f.endsWith('.sql')).sort();
  for (const file of files) {
    if (applied.has(file)) { console.log(`= ${file} (already applied)`); continue; }
    const body = readFileSync(join(dir, file), 'utf8');
    const checksum = createHash('sha256').update(body).digest('hex');
    const bootstrap = exists && (file.startsWith('0001_') || file.startsWith('0002_'));
    if (bootstrap) {
      console.log(`~ ${file} (schema present, recording as applied)`);
      await sql`INSERT INTO schema_migrations (name, checksum) VALUES (${file}, ${checksum})`;
      continue;
    }
    console.log(`> ${file}`);
    await sql.begin(async (tx) => {
      await tx.unsafe(body);
      await tx`INSERT INTO schema_migrations (name, checksum) VALUES (${file}, ${checksum})`;
    });
  }
  console.log('migrations up to date');
}
main().catch((e) => { console.error(e); process.exit(1); }).finally(() => sql.end());
