#!/usr/bin/env node
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {dirname, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const socket = process.env.PAID_BANNER_PG_SOCKET;
assert(socket, 'PAID_BANNER_PG_SOCKET must name the disposable PostgreSQL socket directory');

const paidSource = readFileSync(resolve(root, 'portal/includes/paid_banner_queries.cfm'), 'utf8');
const adsSource = readFileSync(resolve(root, 'ads/includes/backend.cfm'), 'utf8');

function psql(input, quiet = true) {
  return spawnSync('/opt/homebrew/opt/postgresql@16/bin/psql', [
    '-X', '-v', 'ON_ERROR_STOP=1', '-h', socket, '-U', 'postgres', '-d', 'postgres', ...(quiet ? ['-q'] : [])
  ], {input, encoding: 'utf8'});
}

const identityResult = spawnSync('/opt/homebrew/opt/postgresql@16/bin/psql', [
  '-X', '-A', '-t', '-v', 'ON_ERROR_STOP=1', '-h', socket, '-U', 'postgres', '-d', 'postgres'
], {input: "SELECT advertisement.campaign_id::text||'|'||advertisement.account_id::text||'|'||review.campaign_review_request_id::text FROM ads.advertisements advertisement JOIN LATERAL (SELECT campaign_review_request_id FROM ads.campaign_review_requests review WHERE review.campaign_id=advertisement.campaign_id AND review.account_id=advertisement.account_id AND review.ad_type='BANNER' ORDER BY campaign_review_request_id DESC LIMIT 1) review ON true WHERE advertisement.ad_type='BANNER' ORDER BY advertisement.created_at LIMIT 1;", encoding: 'utf8'});
assert.equal(identityResult.status, 0, identityResult.stderr);
const identityLine = identityResult.stdout.trim().split('\n').find(line => /^[0-9a-f-]+\|\d+\|\d+$/.test(line.trim()));
assert(identityLine, 'migrated fixture contains a reviewed BANNER campaign');
const [bannerCampaignId, bannerAccountId, bannerReviewId] = identityLine.trim().split('|');

function tagQuery(name) {
  const match = adsSource.match(new RegExp(`<cfquery\\s+name="${name}"[^>]*>([\\s\\S]*?)<\\/cfquery>`, 'i'));
  assert(match, `query ${name} exists`);
  return match[1]
    .replace(/<cfqueryparam\b(?=[^>]*ReviewRequestId)[^>]*\/>/gi, `${bannerReviewId}::bigint`)
    .replace(/<cfqueryparam\b[^>]*cfsqltype="cf_sql_bigint"[^>]*\/>/gi, `${bannerAccountId}::bigint`)
    .replace(/<cfqueryparam\b[^>]*cfsqltype="cf_sql_integer"[^>]*\/>/gi, '901::integer')
    .replace(/<cfqueryparam\b[^>]*cfsqltype="cf_sql_decimal"[^>]*\/>/gi, '1::numeric')
    .replace(/<cfqueryparam\b[^>]*cfsqltype="cf_sql_timestamp"[^>]*\/>/gi, 'now()')
    .replace(/<cfqueryparam\b[^>]*cfsqltype="cf_sql_bit"[^>]*\/>/gi, 'false')
    .replace(/<cfqueryparam\b[^>]*\/>/gi, `'${bannerCampaignId}'::text`)
    .replace(/<\/?cf(?:if|else)\b[^>]*>/gi, '')
    .trim();
}

const paidQueries = [...paidSource.matchAll(/return\s+queryExecute\("([\s\S]*?)",(?:p|\{account=)/g)].map(match => match[1]);
assert.equal(paidQueries.length, 3, 'all three paid-banner reads are extracted from runtime source');

const paidSql = paidQueries.map(sql => sql
  .replaceAll(':global', 'false')
  .replaceAll(':account', '2::bigint')
  .replaceAll(':campaign', "''::text")
  .replaceAll(':days', '6::integer'));

const eventNames = [
  'qAdsV1CampaignReviewQueue',
  'qAdsV1AdminOperationalCampaigns',
  'qAdsV1Campaigns',
  'qAdsV1SelectedCampaign',
  'qAdsV1Ledger',
  'qAdsV1ReversibleDebits',
  'qAdsV1StatusHistory',
  'qAdsV1ReviewDecisionTarget',
  'qAdsV1PrepareEditTarget',
  'qAdsV1CampaignSaveTarget',
  'qAdsV1StatusTarget'
];

const eventSql = Object.fromEntries(eventNames.map(name => [name, tagQuery(name)]));
const excludesBanner = name => `DO $task2$ BEGIN IF EXISTS(SELECT 1 FROM (${eventSql[name]}) task2_result WHERE campaign_id='${bannerCampaignId}'::uuid) THEN RAISE EXCEPTION '${name} leaked BANNER campaign'; END IF; END $task2$`;

const statements = [
  'BEGIN',
  "ALTER TABLE public.tb_contas ADD COLUMN IF NOT EXISTS nome_conta text DEFAULT 'Fixture account'",
  "ALTER TABLE public.tb_evento_corridas ADD COLUMN IF NOT EXISTS nome_evento text DEFAULT 'Fixture event'",
  "ALTER TABLE public.tb_evento_corridas ADD COLUMN IF NOT EXISTS tag text DEFAULT 'fixture-event'",
  'ALTER TABLE public.tb_evento_corridas ADD COLUMN IF NOT EXISTS cidade text',
  'ALTER TABLE public.tb_evento_corridas ADD COLUMN IF NOT EXISTS data_inicial timestamptz',
  "ALTER TABLE public.tb_usuarios ADD COLUMN IF NOT EXISTS name text DEFAULT 'Fixture user'",
  "SET LOCAL session_replication_role='replica'",
  `UPDATE ads.campaigns SET status='DRAFT' WHERE campaign_id='${bannerCampaignId}'::uuid`,
  `UPDATE ads.campaign_review_requests SET status='PENDING_REVIEW' WHERE campaign_review_request_id=${bannerReviewId}::bigint`,
  "SET LOCAL session_replication_role='origin'",
  ...paidSql.map(sql => `EXPLAIN ${sql}`),
  ...eventNames.map(name => `EXPLAIN ${eventSql[name]}`),
  ...[
    'qAdsV1CampaignReviewQueue',
    'qAdsV1Campaigns',
    'qAdsV1SelectedCampaign',
    'qAdsV1StatusHistory',
    'qAdsV1ReviewDecisionTarget',
    'qAdsV1PrepareEditTarget',
    'qAdsV1CampaignSaveTarget',
    'qAdsV1StatusTarget'
  ].map(excludesBanner),
  "SET LOCAL session_replication_role='replica'",
  `UPDATE ads.campaigns SET status='ACTIVE' WHERE campaign_id='${bannerCampaignId}'::uuid`,
  `UPDATE ads.campaign_review_requests SET status='APPROVED' WHERE campaign_review_request_id=${bannerReviewId}::bigint`,
  "SET LOCAL session_replication_role='origin'",
  excludesBanner('qAdsV1AdminOperationalCampaigns'),
  `DO $task2$ BEGIN IF EXISTS(SELECT 1 FROM (${eventSql.qAdsV1Ledger}) task2_ledger LEFT JOIN LATERAL (SELECT advertisement.ad_type::text AS actual_type FROM ads.advertisements advertisement WHERE advertisement.campaign_id=task2_ledger.campaign_id AND advertisement.account_id=task2_ledger.account_id AND advertisement.status<>'ARCHIVED' ORDER BY advertisement.created_at,advertisement.advertisement_id LIMIT 1) actual ON true WHERE task2_ledger.product_type<>coalesce(actual.actual_type,'ACCOUNT')) THEN RAISE EXCEPTION 'shared ledger product label mismatch'; END IF; END $task2$`,
  'ROLLBACK'
];

const result = psql(`${statements.join(';\n')};\n`);

if (result.status !== 0) {
  process.stderr.write(result.stdout);
  process.stderr.write(result.stderr);
  process.exit(result.status ?? 1);
}

assert.match(result.stdout, /Seq Scan|Index Scan|Result|Aggregate|Limit|Nested Loop/, 'PostgreSQL produced execution plans');
console.log(`PASS compiled ${paidSql.length} paid workspace queries from runtime source against migrated PostgreSQL`);
console.log(`PASS compiled ${eventNames.length} EVENT-isolation/shared-ledger queries from runtime source against migrated PostgreSQL`);
console.log('PASS executable EVENT boundaries exclude a real BANNER fixture campaign from reads and mutation targets');
console.log('PASS executable shared-ledger query labels product from the campaign advertisement');
console.log('PASS fixture-only compatibility columns rolled back');
