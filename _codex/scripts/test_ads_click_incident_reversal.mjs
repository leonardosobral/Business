#!/usr/bin/env node
// Isolated PostgreSQL: real canonical reversal function, synthetic table fixtures.
// Never reads production connection variables or contacts a TCP database.
import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const scratch = mkdtempSync(resolve(tmpdir(), 'ads-click-reversal-test-'));
const bin = '/opt/homebrew/opt/postgresql@16/bin';
function run(name, args, input, allowFailure = false) {
  const r = spawnSync(resolve(bin, name), args, {input, encoding: 'utf8',
    env: {PATH: process.env.PATH, LC_ALL: 'C', TMPDIR: tmpdir()}});
  if (r.status !== 0 && !allowFailure) throw new Error(`${name}: ${r.stdout}${r.stderr}`);
  return allowFailure ? r : r.stdout.trim();
}
const sql = (input, fail = false) => run('psql', ['-X','-qAt','-v','ON_ERROR_STOP=1',
  '-h',scratch,'-U','postgres','-d','postgres'], input, fail);
const repair = readFileSync(resolve(root, '_codex/sql/2026-09-12_ads_click_incident_reversal.sql'), 'utf8');
const foundation = readFileSync(resolve(root, '../RoadRunners/_codex/sql/2026-07-26_ads_v1_canonical_foundation.sql'), 'utf8');
function canonical(name) {
  const start = foundation.indexOf(`CREATE OR REPLACE FUNCTION ads.${name}(`);
  const end = foundation.indexOf('$function$;', start);
  assert(start >= 0 && end > start);
  return foundation.slice(start, end + '$function$;'.length);
}
const targets = repair.slice(repair.indexOf('INSERT INTO ads_click_incident_reversal_targets'), repair.indexOf('DO $repair$'));
const seed = () => sql(`TRUNCATE ads.credit_ledger, ads.events, ads.account_balances, ads.campaign_budget_state, ads.daily_metrics;
  CREATE TEMP TABLE ads_click_incident_reversal_targets(ledger_id uuid, delivery_id uuid, click_event_id uuid,
    campaign_id uuid, account_id bigint, expected_amount numeric);
  ${targets}
  INSERT INTO ads.account_balances SELECT DISTINCT account_id, 'BRL', 100, 0, now() FROM ads_click_incident_reversal_targets;
  INSERT INTO ads.campaign_budget_state SELECT campaign_id, account_id, 'BRL', expected_amount, expected_amount,
    ads.business_date(now()), 0, now() FROM ads_click_incident_reversal_targets;
  INSERT INTO ads.events SELECT click_event_id, delivery_id, campaign_id, account_id, 'CLICK', true, true FROM ads_click_incident_reversal_targets;
  INSERT INTO ads.credit_ledger (ledger_entry_id, account_id, campaign_id, delivery_id, event_id, advertisement_id,
    creative_id, placement_id, billing_model, ad_type, price_snapshot, entry_type, source_type, amount, currency,
    balance_after, idempotency_key, occurred_at)
  SELECT ledger_id, account_id, campaign_id, delivery_id, click_event_id, campaign_id, campaign_id, campaign_id,
    'CPC','EVENT', expected_amount,'DEBIT','CLICK',-expected_amount,'BRL',100,'original:'||ledger_id,now()
    FROM ads_click_incident_reversal_targets;
  INSERT INTO ads.daily_metrics SELECT ads.business_date(now()), account_id, campaign_id, campaign_id, campaign_id,
    campaign_id, 'BRL', 0, 0, expected_amount, now() FROM ads_click_incident_reversal_targets;`);
const state = () => sql(`SELECT json_build_object(
  'balance',(SELECT sum(available_balance) FROM ads.account_balances),
  'spent',(SELECT sum(spent_total) FROM ads.campaign_budget_state),
  'cost',(SELECT sum(cost) FROM ads.daily_metrics),
  'reversals',(SELECT count(*) FROM ads.credit_ledger WHERE entry_type='REVERSAL'),
  'clicks',(SELECT count(*) FROM ads.events WHERE valid AND billable))`);
let started = false;
try {
  run('initdb',['-D',resolve(scratch,'data'),'-U','postgres','-A','trust','--no-locale']);
  run('pg_ctl',['-D',resolve(scratch,'data'),'-l',resolve(scratch,'postgres.log'),'-o',`-F -k ${scratch} -c listen_addresses=''`,'-w','start']);
  started = true;
  sql(`CREATE SCHEMA ads;
    CREATE TABLE ads.credit_ledger (ledger_entry_id uuid PRIMARY KEY DEFAULT gen_random_uuid(), account_id bigint,
      campaign_id uuid, delivery_id uuid, event_id uuid, advertisement_id uuid, creative_id uuid, placement_id uuid,
      billing_model text, ad_type text, price_snapshot numeric, entry_type text, source_type text, amount numeric,
      currency text, balance_after numeric, idempotency_key text UNIQUE, reference_entry_id uuid,
      occurred_at timestamptz DEFAULT now(), created_by integer, metadata jsonb);
    CREATE TABLE ads.events (event_id uuid PRIMARY KEY, delivery_id uuid, campaign_id uuid, account_id bigint,
      event_type text, valid boolean, billable boolean);
    CREATE TABLE ads.account_balances (account_id bigint PRIMARY KEY, currency text, available_balance numeric, version integer, updated_at timestamptz);
    CREATE TABLE ads.campaign_budget_state (campaign_id uuid PRIMARY KEY, account_id bigint, currency text,
      spent_total numeric, spent_today numeric, spent_date date, version integer, updated_at timestamptz);
    CREATE TABLE ads.daily_metrics (metric_date date, account_id bigint, campaign_id uuid, advertisement_id uuid,
      creative_id uuid, placement_id uuid, currency text, reversal_count integer, reversal_amount numeric, cost numeric, updated_at timestamptz);
    ${canonical('business_date')}
    ${canonical('reverse_click_debit')}`);
  seed();
  assert.equal(sql(repair).split('\n').length,11);
  assert.deepEqual(JSON.parse(state()),{balance:206.9,spent:0,cost:0,reversals:11,clicks:11});
  assert.equal(sql("SELECT available_balance FROM ads.account_balances WHERE account_id=2"),'105.96');
  assert.equal(sql("SELECT available_balance FROM ads.account_balances WHERE account_id=1"),'100.94');
  const first = state();
  const retry = sql(repair);
  assert.equal(state(),first);
  assert(retry.split('\n').every(line => line.endsWith('|already_recorded|0')));
  // Scope mismatch: no partial credit even when another valid receipt sorts first.
  seed();
  sql("UPDATE ads.credit_ledger SET amount=-0.50 WHERE ledger_entry_id='a479d0b2-6062-4b02-8f96-e0ee45a6aa90'");
  let before = state();
  let rejected = sql(repair,true);
  assert.notEqual(rejected.status,0); assert.match(rejected.stderr,/ausente ou divergente/);
  assert.equal(state(),before);
  // Canonical failure after earlier reversals must roll the whole transaction back.
  seed();
  sql("UPDATE ads.daily_metrics SET cost=0 WHERE campaign_id='caf0e94e-38fe-4034-8b80-e8aa6de872d4'");
  before = state(); rejected = sql(repair,true);
  assert.notEqual(rejected.status,0); assert.match(rejected.stderr,/Metrica financeira original/);
  assert.equal(state(),before);
  // An independently reversed debit is recognized, not credited again.
  seed();
  sql("SELECT * FROM ads.reverse_click_debit('ebd5baf9-e00b-4cf9-8fa6-1a52e7873248','prior-audit',NULL,'fixture')");
  assert.match(sql(repair),/already_reversed/);
  assert.deepEqual(JSON.parse(state()),{balance:206.9,spent:0,cost:0,reversals:11,clicks:11});
  console.log('PASS: canonical reversal function; BRL 6.90 by exact accounts, idempotent retry, prior reversal, identity guard, atomic rollback, unchanged click history.');
} finally {
  if(started) run('pg_ctl',['-D',resolve(scratch,'data'),'-m','fast','-w','stop']);
  console.log(`Isolated fixture retained: ${scratch}`);
}
