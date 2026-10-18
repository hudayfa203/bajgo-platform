#!/usr/bin/env node
// Boots the compiled app without listening and writes the OpenAPI document
// to packages/contracts/openapi.json (shared by web/admin).
import { mkdirSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const here = dirname(fileURLToPath(import.meta.url));
process.env.APP_ENV ??= 'development';
process.env.LOG_LEVEL = 'silent';
const { buildOpenApiDocument } = require(join(here, '..', 'dist', 'openapi.js'));
const doc = await buildOpenApiDocument();
const out = join(here, '..', '..', '..', 'packages', 'contracts', 'openapi.json');
mkdirSync(dirname(out), { recursive: true });
writeFileSync(out, JSON.stringify(doc, null, 2));
console.log(`wrote ${out} (${Object.keys(doc.paths).length} paths)`);
process.exit(0);
