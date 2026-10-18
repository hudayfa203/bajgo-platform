#!/usr/bin/env node
// Generates an RS256 key pair for local development at keys/dev-*.pem.
import { generateKeyPairSync } from 'node:crypto';
import { writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const dir = join(dirname(fileURLToPath(import.meta.url)), '..', 'keys');
mkdirSync(dir, { recursive: true });
const priv = join(dir, 'dev-private.pem');
const pub = join(dir, 'dev-public.pem');
if (existsSync(priv) && !process.argv.includes('--force')) {
  console.log('keys already exist, pass --force to regenerate');
  process.exit(0);
}
const { privateKey, publicKey } = generateKeyPairSync('rsa', {
  modulusLength: 2048,
  publicKeyEncoding: { type: 'spki', format: 'pem' },
  privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
});
writeFileSync(priv, privateKey, { mode: 0o600 });
writeFileSync(pub, publicKey);
console.log(`wrote ${priv} and ${pub}`);
