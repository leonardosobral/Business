'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../..');
const read = relative => fs.readFileSync(path.join(root, relative), 'utf8');

const sync = read('administracao/ai-mails/includes/sync.cfm');
const ai = read('administracao/ai-mails/includes/ai.cfm');
const service = read('administracao/ai-mails/includes/service.cfm');
const api = read('administracao/ai-mails/api.cfm');
const page = read('administracao/ai-mails/index.cfm');

assert.match(sync, /status="watching_new"/);
assert.match(sync, /monitor_since_ms=:cutoff/);
assert.doesNotMatch(sync, /in:inbox \{after:/, 'não deve existir busca histórica inicial');
assert.doesNotMatch(sync, /Histórico expirado: reconciliando/, 'histórico expirado não deve reativar backlog');
assert.match(ai, /context\.last_inbound_ms<=val\(cfg\.monitor_since_ms\)/);
assert.match(ai, /Conversa anterior ao início do monitor ignorada/);
assert.match(ai, /created_at>=to_timestamp\(:cutoff\/1000\.0\)/, 'a cota automática deve recomeçar no corte sem apagar o histórico');
assert.match(service, /analyzed_at IS NOT NULL OR t\.last_inbound_ms>\(SELECT monitor_since_ms/, 'placeholders históricos não devem aparecer como pendências');
assert.match(service, /AS thread_quota/, 'o painel deve separar o consumo histórico da cota pós-corte');
assert.doesNotMatch(api, /initial_complete=CASE WHEN :reset/);
assert.doesNotMatch(page, /Carga inicial: últimos dias/);
assert.match(page, /somente novas mensagens/i);

console.log('AI-mails start-now checks: OK');
