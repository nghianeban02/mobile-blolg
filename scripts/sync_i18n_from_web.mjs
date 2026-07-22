#!/usr/bin/env node
/**
 * Đồng bộ catalog i18n từ web-blog → assets/i18n/*.json (flat key).
 * Chạy từ root mobile-blog: node scripts/sync_i18n_from_web.mjs
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, '..');
const srcDir = path.resolve(root, '../web-blog/lib/i18n/messages');
const outDir = path.join(root, 'assets/i18n');

function walk(node, prefix, flat) {
  for (const [k, v] of Object.entries(node)) {
    const key = prefix ? `${prefix}.${k}` : k;
    if (v && typeof v === 'object' && !Array.isArray(v)) walk(v, key, flat);
    else flat[key] = String(v);
  }
}

fs.mkdirSync(outDir, { recursive: true });

for (const locale of ['vi', 'en', 'ja', 'de']) {
  let src = fs.readFileSync(path.join(srcDir, `${locale}.ts`), 'utf8');
  src = src.replace(/^import[\s\S]*?;\s*/m, '');
  src = src.replace(/\s+as const;\s*[\s\S]*$/m, '');
  src = src.replace(/\s*export type[\s\S]*$/m, '');
  src = src.replace(/\s*export default[\s\S]*$/m, '');
  src = src.replace(/const\s+(\w+)(?::\s*\w+)?\s*=\s*/, 'const $1 = ');
  const match = src.match(/const\s+\w+\s*=\s*(\{[\s\S]*)\s*;?\s*$/);
  if (!match) throw new Error(`Failed to parse ${locale}`);
  const obj = Function(`"use strict"; return (${match[1].replace(/;\s*$/, '')});`)();
  const flat = {};
  walk(obj, '', flat);
  fs.writeFileSync(path.join(outDir, `${locale}.json`), `${JSON.stringify(flat, null, 2)}\n`);
  console.log(locale, Object.keys(flat).length, 'keys');
}
