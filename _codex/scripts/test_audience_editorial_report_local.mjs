#!/usr/bin/env node
// Behavioral SQL contract against an isolated PostgreSQL cluster. Never reads connection env vars.
import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const scratch = mkdtempSync(resolve(tmpdir(), 'audience-editorial-report-test-'));
const bin = '/opt/homebrew/opt/postgresql@16/bin';
const run = (name, args, input) => {
  const result = spawnSync(resolve(bin, name), args, {
    input,
    encoding: 'utf8',
    env: { PATH: process.env.PATH, LC_ALL: 'C', TMPDIR: tmpdir() }
  });
  if (result.status !== 0) throw new Error(`${name}: ${result.stdout || ''}${result.stderr || ''}`);
  return result.stdout.trim();
};
const sql = input => run('psql', [
  '-X', '-qAt', '-v', 'ON_ERROR_STOP=1', '-h', scratch, '-U', 'postgres', '-d', 'postgres'
], input);
const params = {
  days: 7,
  environment: 'prod',
  include_internal: false,
  region_dimension: 'market',
  uf: '',
  page_family: '',
  device_class: ''
};
const query = (name, overrides = {}) => {
  const values = { ...params, ...overrides };
  let statement = readFileSync(resolve(root, 'portal/audiencia/queries', `${name}.sql`), 'utf8')
    .replace('/* AUDIENCE_FILTER */', readFileSync(resolve(root, 'portal/audiencia/queries/filter.sql'), 'utf8'));
  for (const [key, value] of Object.entries(values)) {
    const literal = typeof value === 'number' || typeof value === 'boolean'
      ? String(value)
      : `'${value.replaceAll("'", "''")}'`;
    statement = statement.replace(new RegExp(`(?<!:):${key}\\b`, 'g'), literal);
  }
  return JSON.parse(sql(`SELECT coalesce(json_agg(r), '[]'::json) FROM (${statement.trim().replace(/;$/, '')}) r;`));
};
const numericSummary = row => Object.fromEntries([
  'pageviews', 'active_pages', 'visitors', 'sessions', 'engaged_sessions',
  'opportunities', 'renders', 'slot_views', 'ad_renders', 'ad_views',
  'unknown_location', 'unknown_market'
].map(key => [key, Number(row[key])]));
const numericInventory = rows => rows.map(row => Object.fromEntries(Object.entries(row).map(([key, value]) => [
  key,
  /^(opportunities|requests|served|renders|ad_renders|slot_views|ad_views|filled_slots|house_slots|empty_slots|pending_slots|unavailable_slots|errors)$/.test(key)
    ? Number(value)
    : value
])));

let started = false;
try {
  run('initdb', ['-D', resolve(scratch, 'data'), '-U', 'postgres', '-A', 'trust', '--no-locale']);
  run('pg_ctl', [
    '-D', resolve(scratch, 'data'), '-l', resolve(scratch, 'postgres.log'),
    '-o', `-F -k ${scratch} -c listen_addresses=''`, '-w', 'start'
  ]);
  started = true;
  sql(`CREATE SCHEMA audience;
    CREATE TABLE audience.events (
      page_view_id uuid NOT NULL,
      event_key text NOT NULL,
      event_kind text NOT NULL,
      occurred_at timestamptz DEFAULT now(),
      received_at timestamptz DEFAULT now(),
      visitor_id uuid NOT NULL,
      session_id uuid NOT NULL,
      environment text DEFAULT 'prod',
      is_internal boolean DEFAULT false,
      visitor_uf text DEFAULT 'SC',
      profile_uf text DEFAULT 'SC',
      context_uf text DEFAULT 'SC',
      market_uf text DEFAULT 'SC',
      page_family text DEFAULT 'home',
      page_path text DEFAULT '/',
      content_type text DEFAULT '',
      content_id text DEFAULT '',
      source text DEFAULT 'direct',
      medium text DEFAULT '(none)',
      campaign text DEFAULT '',
      creative text DEFAULT '',
      slot_key text DEFAULT '',
      placement_key text DEFAULT '',
      slot_state text DEFAULT '',
      device_class text DEFAULT 'DESKTOP',
      active_ms integer DEFAULT 0,
      visible_ms integer DEFAULT 0,
      max_continuous_ms integer DEFAULT 0,
      view_ratio numeric(5,4) DEFAULT 0,
      PRIMARY KEY (page_view_id, event_key)
    );
    INSERT INTO audience.events
      (page_view_id,event_key,event_kind,visitor_id,session_id,page_family,page_path,content_type,content_id,device_class)
    VALUES
      ('00000000-0000-4000-8000-000000000001','page','page_view','10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','news_detail','/noticias/legado/','news','legacy-news','DESKTOP'),
      ('00000000-0000-4000-8000-000000000001','open','content_open','10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','news_detail','/noticias/legado/','news','legacy-news','DESKTOP'),
      ('00000000-0000-4000-8000-000000000001','engagement','page_engagement','10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','news_detail','/noticias/legado/','news','legacy-news','DESKTOP'),
      ('00000000-0000-4000-8000-000000000002','page','page_view','10000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000002','home','/','','','MOBILE'),
      ('00000000-0000-4000-8000-000000000002','slot','slot_opportunity','10000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000002','home','/','','','MOBILE'),
      ('00000000-0000-4000-8000-000000000003','page','page_view','10000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000002','search','/busca/','','','MOBILE'),
      ('00000000-0000-4000-8000-000000000004','page','page_view','10000000-0000-4000-8000-000000000003','20000000-0000-4000-8000-000000000003','news_detail','/noticias/profundidade/','news','depth-news','DESKTOP'),
      ('00000000-0000-4000-8000-000000000004','open','content_open','10000000-0000-4000-8000-000000000003','20000000-0000-4000-8000-000000000003','news_detail','/noticias/profundidade/','news','depth-news','DESKTOP'),
      ('00000000-0000-4000-8000-000000000005','page','page_view','10000000-0000-4000-8000-000000000003','20000000-0000-4000-8000-000000000003','news_detail','/noticias/profundidade/','news','depth-news','DESKTOP'),
      ('00000000-0000-4000-8000-000000000005','open','content_open','10000000-0000-4000-8000-000000000003','20000000-0000-4000-8000-000000000003','news_detail','/noticias/profundidade/','news','depth-news','DESKTOP'),
      ('00000000-0000-4000-8000-000000000006','page','page_view','10000000-0000-4000-8000-000000000004','20000000-0000-4000-8000-000000000004','home','/','','','MOBILE'),
      ('00000000-0000-4000-8000-000000000007','page','page_view','10000000-0000-4000-8000-000000000005','20000000-0000-4000-8000-000000000005','home','/','','','MOBILE'),
      ('00000000-0000-4000-8000-000000000008','page','page_view','10000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000002','home','/','','','MOBILE');
    UPDATE audience.events SET active_ms=40000 WHERE page_view_id='00000000-0000-4000-8000-000000000001' AND event_key='engagement';
    UPDATE audience.events SET slot_key='home-card', placement_key='feed', slot_state='empty'
      WHERE page_view_id='00000000-0000-4000-8000-000000000002' AND event_key='slot';
    UPDATE audience.events SET is_internal=true WHERE page_view_id='00000000-0000-4000-8000-000000000006';
    UPDATE audience.events SET environment='dev' WHERE page_view_id='00000000-0000-4000-8000-000000000007';
    UPDATE audience.events SET visitor_uf='SP',profile_uf='SP',context_uf='SP',market_uf='SP'
      WHERE page_view_id='00000000-0000-4000-8000-000000000008';`);

  const summaryBefore = numericSummary(query('summary')[0]);
  const inventoryBefore = numericInventory(query('inventory'));

  sql(`INSERT INTO audience.events
      (page_view_id,event_key,event_kind,visitor_id,session_id,environment,is_internal,visitor_uf,profile_uf,context_uf,market_uf,page_family,page_path,content_type,content_id,device_class,visible_ms,max_continuous_ms,view_ratio)
    VALUES
      ('00000000-0000-4000-8000-000000000002','view:card:a','content_viewable','10000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000002','prod',false,'SC','SC','SC','SC','home','/','news','card-news','MOBILE',1000,1000,0.50),
      ('00000000-0000-4000-8000-000000000002','view:card:b','content_viewable','10000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000002','prod',false,'SC','SC','SC','SC','home','/','news','card-news','MOBILE',1000,1000,0.60),
      ('00000000-0000-4000-8000-000000000003','view:card','content_viewable','10000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000002','prod',false,'SC','SC','SC','SC','search','/busca/','news','card-news','MOBILE',1000,1000,0.50),
      ('00000000-0000-4000-8000-000000000006','view:card','content_viewable','10000000-0000-4000-8000-000000000004','20000000-0000-4000-8000-000000000004','prod',true,'SC','SC','SC','SC','home','/','news','card-news','MOBILE',1000,1000,0.50),
      ('00000000-0000-4000-8000-000000000007','view:card','content_viewable','10000000-0000-4000-8000-000000000005','20000000-0000-4000-8000-000000000005','dev',false,'SC','SC','SC','SC','home','/','news','card-news','MOBILE',1000,1000,0.50),
      ('00000000-0000-4000-8000-000000000008','view:card','content_viewable','10000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000002','prod',false,'SP','SP','SP','SP','home','/','news','card-news','MOBILE',1000,1000,0.50),
      ('00000000-0000-4000-8000-000000000004','progress:25:a','content_progress','10000000-0000-4000-8000-000000000003','20000000-0000-4000-8000-000000000003','prod',false,'SC','SC','SC','SC','news_detail','/noticias/profundidade/','news','depth-news','DESKTOP',0,0,0.25),
      ('00000000-0000-4000-8000-000000000004','progress:25:b','content_progress','10000000-0000-4000-8000-000000000003','20000000-0000-4000-8000-000000000003','prod',false,'SC','SC','SC','SC','news_detail','/noticias/profundidade/','news','depth-news','DESKTOP',0,0,0.25),
      ('00000000-0000-4000-8000-000000000004','progress:50','content_progress','10000000-0000-4000-8000-000000000003','20000000-0000-4000-8000-000000000003','prod',false,'SC','SC','SC','SC','news_detail','/noticias/profundidade/','news','depth-news','DESKTOP',0,0,0.50),
      ('00000000-0000-4000-8000-000000000004','progress:75:a','content_progress','10000000-0000-4000-8000-000000000003','20000000-0000-4000-8000-000000000003','prod',false,'SC','SC','SC','SC','news_detail','/noticias/profundidade/','news','depth-news','DESKTOP',0,0,0.75),
      ('00000000-0000-4000-8000-000000000004','progress:75:b','content_progress','10000000-0000-4000-8000-000000000003','20000000-0000-4000-8000-000000000003','prod',false,'SC','SC','SC','SC','news_detail','/noticias/profundidade/','news','depth-news','DESKTOP',0,0,0.75),
      ('00000000-0000-4000-8000-000000000004','progress:100','content_progress','10000000-0000-4000-8000-000000000003','20000000-0000-4000-8000-000000000003','prod',false,'SC','SC','SC','SC','news_detail','/noticias/profundidade/','news','depth-news','DESKTOP',0,0,1.00),
      ('00000000-0000-4000-8000-000000000005','progress:25','content_progress','10000000-0000-4000-8000-000000000003','20000000-0000-4000-8000-000000000003','prod',false,'SC','SC','SC','SC','news_detail','/noticias/profundidade/','news','depth-news','DESKTOP',0,0,0.25),
      ('00000000-0000-4000-8000-000000000005','progress:50','content_progress','10000000-0000-4000-8000-000000000003','20000000-0000-4000-8000-000000000003','prod',false,'SC','SC','SC','SC','news_detail','/noticias/profundidade/','news','depth-news','DESKTOP',0,0,0.50);`);

  assert.deepEqual(numericSummary(query('summary')[0]), summaryBefore,
    'editorial events on known pages must not change summary metrics');
  assert.deepEqual(numericInventory(query('inventory')), inventoryBefore,
    'editorial events must not change inventory metrics');

  const rows = query('content');
  const card = rows.find(row => row.content_id === 'card-news');
  assert.ok(card, 'an exposure-only card must appear in the content ranking');
  assert.equal(Number(card.card_views), 3, 'exposure is distinct by physical page, not event row');
  assert.equal(Number(card.exposed_visitors), 1, 'one browser on multiple pages is one exposed visitor');
  assert.equal(Number(card.pageviews), 0, 'card exposure is not a page opening');
  assert.equal(Number(card.opens), 0, 'card exposure is not content_open');
  assert.equal(Number(card.video_starts), 0, 'card exposure is not playback');
  assert.equal(card.page_path, '', 'an exposure-only row must not present the card host as content path');

  const depth = rows.find(row => row.content_id === 'depth-news');
  assert.deepEqual([
    Number(depth.depth_25), Number(depth.depth_50), Number(depth.depth_75), Number(depth.depth_100)
  ], [2, 2, 1, 1], 'depth milestones count distinct pages and repeated events do not duplicate');
  assert.equal(depth.page_path, '/noticias/profundidade/', 'the report keeps the observed opened-content path');

  const legacy = rows.find(row => row.content_id === 'legacy-news');
  assert.deepEqual({
    pageviews: Number(legacy.pageviews),
    opens: Number(legacy.opens),
    visitors: Number(legacy.visitors),
    active_ms: Number(legacy.active_ms)
  }, { pageviews: 1, opens: 1, visitors: 1, active_ms: 40000 }, 'legacy content metrics stay unchanged');
  assert.deepEqual([
    Number(legacy.card_views), Number(legacy.exposed_visitors),
    Number(legacy.depth_25), Number(legacy.depth_50), Number(legacy.depth_75), Number(legacy.depth_100)
  ], [0, 0, 0, 0, 0, 0], 'legacy rows expose absence of new signals for the UI to render as unavailable');

  assert.equal(Number(query('content', { uf: 'SC' }).find(row => row.content_id === 'card-news').card_views), 2);
  assert.equal(Number(query('content', { uf: 'SP' }).find(row => row.content_id === 'card-news').card_views), 1);
  assert.equal(Number(query('content', { page_family: 'home' }).find(row => row.content_id === 'card-news').card_views), 2);
  assert.equal(Number(query('content', { page_family: 'search' }).find(row => row.content_id === 'card-news').card_views), 1);
  assert.equal(Number(query('content', { device_class: 'MOBILE' }).find(row => row.content_id === 'card-news').card_views), 3);
  assert.equal(query('content', { device_class: 'DESKTOP' }).some(row => row.content_id === 'card-news'), false);
  assert.equal(Number(query('content', { include_internal: true }).find(row => row.content_id === 'card-news').card_views), 4);
  assert.equal(Number(query('content', { environment: 'dev' }).find(row => row.content_id === 'card-news').card_views), 1);

  console.log('Audience editorial report SQL: 21 behavioral assertions passed against isolated PostgreSQL.');
} finally {
  if (started) run('pg_ctl', ['-D', resolve(scratch, 'data'), '-m', 'immediate', '-w', 'stop']);
  rmSync(scratch, { recursive: true, force: true });
}
