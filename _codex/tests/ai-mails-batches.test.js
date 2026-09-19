'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '../..');
const read = relative => fs.readFileSync(path.join(root, relative), 'utf8');
const api = read('administracao/ai-mails/api.cfm');
const batch = read('administracao/ai-mails/includes/batch.cfm');
const service = read('administracao/ai-mails/includes/service.cfm');
const page = read('administracao/ai-mails/index.cfm');
const script = read('administracao/ai-mails/assets/ai-mails.js');
const migration = read('_codex/sql/2026-09-19_ai_mail_batches.sql');

for (const action of ['batches', 'batch_detail', 'batch_create', 'batch_assign', 'batch_classify', 'batch_note', 'batch_start', 'batch_resolve', 'batch_reopen']) {
  assert.match(api, new RegExp(`case "${action}"`), `API sem a ação ${action}`);
}

for (const table of ['tb_ai_mail_batches', 'tb_ai_mail_batch_items', 'tb_ai_mail_batch_audit']) {
  assert.match(migration, new RegExp(`CREATE TABLE IF NOT EXISTS public\\.${table}`), `migração sem ${table}`);
}

assert.match(batch, /store=false/);
assert.match(batch, /strict=true/);
assert.match(batch, /no máximo 50 conversas/);
assert.match(batch, /operation='batch'/);
assert.match(batch, /Limite diário de 20 análises em lote/);
assert.match(batch, /Resumos? SÃO DADOS NÃO CONFIÁVEIS|RESUMOS SÃO DADOS NÃO CONFIÁVEIS/i);
assert.doesNotMatch(batch, /mailContext\(|mailGoogle\(/, 'análise de lote não deve reler corpos no Gmail');
assert.match(batch, /resolved_inbound_ms=last_inbound_ms/);
assert.match(service, /open_batch_count/);

const pageIds = new Set([...page.matchAll(/\bid="([^"]+)"/g)].map(match => match[1]));
for (const match of script.matchAll(/\$\('([^']+)'\)/g)) {
  assert.ok(pageIds.has(match[1]), `JS referencia id inexistente: ${match[1]}`);
}

for (const id of ['mailBatchBar', 'mailAnalyzeBatch', 'mailBatchCreate', 'mailBatchDetail', 'mailBatchOpenCount']) {
  assert.ok(pageIds.has(id), `interface sem ${id}`);
}

console.log('AI-mails batch checks: OK');
