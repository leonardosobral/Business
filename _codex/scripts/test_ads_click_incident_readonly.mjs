#!/usr/bin/env node
// SQL behavior test in a new Unix-socket-only cluster; no production credentials.
import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const scratch = mkdtempSync(resolve(tmpdir(), 'ads-click-reconcile-test-'));
const bin = '/opt/homebrew/opt/postgresql@16/bin';
function run(name, args, input) {
  const result = spawnSync(resolve(bin, name), args, { input, encoding: 'utf8',
    env: { PATH: process.env.PATH, LC_ALL: 'C', TMPDIR: tmpdir() } });
  if (result.status !== 0) throw new Error(`${name}: ${result.stdout}${result.stderr}`);
  return result.stdout.trim();
}
const sql = input => run('psql', ['-X', '-qA', '-F', '\t', '-P', 'footer=off', '-v', 'ON_ERROR_STOP=1',
  '-h', scratch, '-U', 'postgres', '-d', 'postgres'], input);
const incidents = JSON.parse(readFileSync(resolve(root,
  '_codex/docs/2026-09-11_ads_click_incident_event_ids.json'), 'utf8')).clicks;
const q = value => `'${String(value).replaceAll("'", "''")}'`;
const ledgerId = n => `00000000-0000-4000-8000-${String(n).padStart(12, '0')}`;
let started = false;
try {
  run('initdb', ['-D', resolve(scratch, 'data'), '-U', 'postgres', '-A', 'trust', '--no-locale']);
  run('pg_ctl', ['-D', resolve(scratch, 'data'), '-l', resolve(scratch, 'postgres.log'),
    '-o', `-F -k ${scratch} -c listen_addresses=''`, '-w', 'start']);
  started = true;
  sql(`CREATE SCHEMA ads;
    CREATE TABLE ads.campaigns (campaign_id uuid PRIMARY KEY, account_id bigint, name text);
    CREATE TABLE ads.deliveries (delivery_id uuid PRIMARY KEY, account_id bigint, campaign_id uuid,
      currency text, price_snapshot numeric);
    CREATE TABLE ads.events (event_id uuid PRIMARY KEY, delivery_id uuid, event_type text,
      valid boolean, billable boolean, rejection_reason text, occurred_at timestamptz);
    CREATE TABLE ads.credit_ledger (ledger_entry_id uuid PRIMARY KEY, delivery_id uuid, event_id uuid,
      account_id bigint, currency text, entry_type text, source_type text, amount numeric, reference_entry_id uuid);`);
  for (const [n, c] of incidents.entries()) {
    if (n === 10) continue; // Retain missing delivery as a visible result row.
    sql(`INSERT INTO ads.deliveries VALUES (${q(c.delivery_id)}, 1, ${q(c.campaign_id)}, 'BRL', .94);`);
    sql(`INSERT INTO ads.campaigns VALUES (${q(c.campaign_id)}, 1, 'Fixture ${n}');`);
  }
  for (const n of [0, 1, 2]) {
    const c = incidents[n];
    const time = `2026-09-11T${c.time.slice(12, 20)}Z`;
    sql(`INSERT INTO ads.events VALUES (${q(c.click_event_id)}, ${q(c.delivery_id)}, 'CLICK',
      ${n !== 2}, ${n !== 2}, ${n === 2 ? "'CAMPAIGN_NOT_ACTIVE'" : 'NULL'}, ${q(time)});`);
    if (n < 2) sql(`INSERT INTO ads.credit_ledger VALUES (${q(ledgerId(n + 1))}, ${q(c.delivery_id)},
      ${q(c.click_event_id)}, 1, 'BRL', 'DEBIT', 'CLICK', -.94, NULL);`);
  }
  for (const [n, amount, ref] of [[3, .20, 1], [4, .31, 1], [5, .94, 2]]) {
    sql(`INSERT INTO ads.credit_ledger VALUES (${q(ledgerId(n))}, NULL, NULL, 1, 'BRL',
      'REVERSAL', 'REVERSAL', ${amount}, ${q(ledgerId(ref))});`);
  }
  // Another event on the same delivery must not be attributed to the observed GET.
  sql(`INSERT INTO ads.credit_ledger VALUES (${q(ledgerId(6))}, ${q(incidents[0].delivery_id)},
    ${q(ledgerId(100))}, 1, 'BRL', 'DEBIT', 'CLICK', -9, NULL);`);
  for (const [n, time] of [[7, '23:08:40'], [8, '23:08:41'], [9, '23:08:44']]) {
    sql(`INSERT INTO ads.events VALUES (${q(ledgerId(n))}, ${q(incidents[0].delivery_id)},
      'VIEWABLE_IMPRESSION', true, false, NULL, '2026-09-11T${time}Z');`);
  }
  const statement = readFileSync(resolve(root, '_codex/sql/2026-09-11_ads_click_incident_readonly.sql'), 'utf8');
  const before = sql('SELECT sum(amount) FROM ads.credit_ledger;');
  const [header, ...lines] = sql(statement).split('\n');
  const rows = lines.map(line => Object.fromEntries(header.split('\t').map((key, i) => [key, line.split('\t')[i]])));
  assert.equal(rows.length, 11);
  assert.equal(rows[0].resultado, 'DEBITO_PARA_REVISAO');
  assert.equal(rows[0].nome_campanha, 'Fixture 0');
  assert.equal(Number(rows[0].valor_debitado), .94);
  assert.equal(Number(rows[0].valor_estornado), .51);
  assert.equal(Number(rows[0].debito_liquido), .43);
  assert.equal(Number(rows[0].debitos_encontrados), 1);
  assert.equal(Number(rows[0].impressoes_validas_da_entrega), 3);
  assert.equal(Number(rows[0].impressoes_validas_antes_do_clique), 2);
  assert.equal(Number(rows[0].total_debitado_na_moeda), 1.88);
  assert.equal(rows[1].resultado, 'DEBITO_JA_ESTORNADO');
  assert.equal(rows[2].resultado, 'CLIQUE_NAO_COBRAVEL');
  assert.equal(rows[3].resultado, 'CLIQUE_NAO_ENCONTRADO');
  assert.equal(rows[10].resultado, 'ENTREGA_NAO_ENCONTRADA');
  assert.equal(sql('SELECT sum(amount) FROM ads.credit_ledger;'), before);
  console.log('PASS: read-only reconciliation; 11 rows, exact click IDs, no join multiplication, partial/full reversal, missing/rejected records, unchanged ledger.');
} finally {
  if (started) run('pg_ctl', ['-D', resolve(scratch, 'data'), '-m', 'fast', '-w', 'stop']);
  console.log(`Isolated test data retained at ${scratch}`);
}
