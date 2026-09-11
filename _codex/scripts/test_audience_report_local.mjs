#!/usr/bin/env node
// Real PostgreSQL fixtures, isolated socket/database; never reads connection env vars.
import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const scratch = mkdtempSync(resolve(tmpdir(), 'audience-report-test-'));
const bin = '/opt/homebrew/opt/postgresql@16/bin';
const run = (name, args, input) => {
  const result = spawnSync(resolve(bin, name), args, { input, encoding: 'utf8', env: { PATH: process.env.PATH, LC_ALL: 'C', TMPDIR: tmpdir() } });
  if (result.status !== 0) throw new Error(`${name}: ${result.stdout || ''}${result.stderr || ''}`);
  return result.stdout.trim();
};
const sql = input => run('psql', ['-X', '-qAt', '-v', 'ON_ERROR_STOP=1', '-h', scratch, '-U', 'postgres', '-d', 'postgres'], input);
let started = false;
try {
  run('initdb', ['-D', resolve(scratch, 'data'), '-U', 'postgres', '-A', 'trust', '--no-locale']);
  run('pg_ctl', ['-D', resolve(scratch, 'data'), '-l', resolve(scratch, 'postgres.log'), '-o', `-F -k ${scratch} -c listen_addresses=''`, '-w', 'start']);
  started = true;
  sql(`CREATE SCHEMA audience;
    CREATE TABLE audience.events (
      page_view_id uuid, event_key text, event_kind text, occurred_at timestamptz DEFAULT now(), received_at timestamptz DEFAULT now(),
      visitor_id uuid, session_id uuid, environment text DEFAULT 'prod', is_internal boolean DEFAULT false,
      visitor_uf text, profile_uf text, context_uf text, market_uf text, page_family text DEFAULT 'home',
      page_path text DEFAULT '/', content_type text DEFAULT '', content_id text DEFAULT '',
      source text DEFAULT 'direct', medium text DEFAULT '(none)', campaign text DEFAULT '', creative text DEFAULT '',
      slot_key text DEFAULT '', placement_key text DEFAULT '', slot_state text DEFAULT '', device_class text DEFAULT 'DESKTOP',
      active_ms integer DEFAULT 0, visible_ms integer DEFAULT 0, max_continuous_ms integer DEFAULT 0,
      PRIMARY KEY(page_view_id,event_key));
    INSERT INTO audience.events(page_view_id,event_key,event_kind,visitor_id,session_id,visitor_uf,profile_uf,context_uf,market_uf)
    VALUES ('00000000-0000-4000-8000-000000000001','page','page_view','10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','SP','SP','SC','SC'),
           ('00000000-0000-4000-8000-000000000002','page','page_view','10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','SP','SP','SP','SP'),
           ('00000000-0000-4000-8000-000000000003','page','page_view','10000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000002',NULL,NULL,NULL,NULL);
    INSERT INTO audience.events SELECT page_view_id,'engagement','page_engagement',occurred_at,received_at,visitor_id,session_id,environment,is_internal,visitor_uf,profile_uf,context_uf,market_uf,page_family,page_path,content_type,content_id,source,medium,campaign,creative,slot_key,placement_key,slot_state,device_class,31000,0,0 FROM audience.events WHERE event_key='page' AND market_uf='SC';
    INSERT INTO audience.events SELECT page_view_id,'slot:one','slot_opportunity',occurred_at,received_at,visitor_id,session_id,environment,is_internal,visitor_uf,profile_uf,context_uf,market_uf,page_family,page_path,content_type,content_id,source,medium,campaign,creative,'home-one','native-one','empty',device_class,0,0,0 FROM audience.events WHERE event_key='page' AND market_uf='SC';
    INSERT INTO audience.events SELECT page_view_id,'slot:two','slot_opportunity',occurred_at,received_at,visitor_id,session_id,environment,is_internal,visitor_uf,profile_uf,context_uf,market_uf,page_family,page_path,content_type,content_id,source,medium,campaign,creative,'home-two','native-two','filled',device_class,0,0,0 FROM audience.events WHERE event_key='page' AND market_uf='SC';
    INSERT INTO audience.events SELECT page_view_id,'render:two','slot_render',occurred_at,received_at,visitor_id,session_id,environment,is_internal,visitor_uf,profile_uf,context_uf,market_uf,page_family,page_path,content_type,content_id,source,medium,campaign,creative,'home-two','native-two','filled',device_class,0,0,0 FROM audience.events WHERE event_key='page' AND market_uf='SC';
    INSERT INTO audience.events SELECT page_view_id,'visible:two','slot_viewable',occurred_at,received_at,visitor_id,session_id,environment,is_internal,visitor_uf,profile_uf,context_uf,market_uf,page_family,page_path,content_type,content_id,source,medium,campaign,creative,'home-two','native-two','filled',device_class,0,1000,1000 FROM audience.events WHERE event_key='page' AND market_uf='SC';
    ALTER TABLE audience.events ADD COLUMN view_ratio numeric(5,4) DEFAULT 0;
    INSERT INTO audience.events(page_view_id,event_key,event_kind,visitor_id,session_id,is_internal,market_uf) VALUES
    ('00000000-0000-4000-8000-000000000004','page','page_view','10000000-0000-4000-8000-000000000003','20000000-0000-4000-8000-000000000003',true,'SC');
    INSERT INTO audience.events(page_view_id,event_key,event_kind,visitor_id,session_id,environment,market_uf) VALUES
    ('00000000-0000-4000-8000-000000000005','page','page_view','10000000-0000-4000-8000-000000000004','20000000-0000-4000-8000-000000000004','dev','SC');
    INSERT INTO audience.events(page_view_id,event_key,event_kind,visitor_id,session_id,occurred_at,market_uf) VALUES
    ('00000000-0000-4000-8000-000000000006','page','page_view','10000000-0000-4000-8000-000000000005','20000000-0000-4000-8000-000000000005',now()-interval '40 days','SC');`);
  const query = (name, overrides = {}) => {
    const params = { days: 7, environment: 'prod', include_internal: false, region_dimension: 'market', uf: '', page_family: '', device_class: '', ...overrides };
    let statement = readFileSync(resolve(root, 'portal/audiencia/queries', `${name}.sql`), 'utf8')
      .replace('/* AUDIENCE_FILTER */', readFileSync(resolve(root, 'portal/audiencia/queries/filter.sql'), 'utf8'));
    for (const [key,value] of Object.entries(params)) {
      const literal = typeof value === 'number' || typeof value === 'boolean' ? String(value) : `'${value.replaceAll("'", "''")}'`;
      statement = statement.replace(new RegExp(`(?<!:):${key}\\b`, 'g'), literal);
    }
    return JSON.parse(sql(`SELECT coalesce(json_agg(r),'[]'::json) FROM (${statement.trim().replace(/;$/, '')}) r;`));
  };
  const all = query('summary')[0];
  assert.equal(Number(all.pageviews), 3, 'full period excludes internal, dev and old visits');
  assert.equal(Number(all.visitors), 2, 'same visitor across two UFs stays one overall visitor');
  assert.equal(Number(all.sessions), 2);
  assert.equal(Number(all.engaged_sessions), 1);
  assert.equal(Number(all.opportunities), 2, 'empty and filled slots both produce opportunity');
  assert.equal(Number(all.slot_views), 1, 'empty collapsed slot is not a viewable impression');
  assert.equal(Number(query('summary',{uf:'SC'})[0].pageviews),1, 'SP visitor viewing SC counts toward commercial SC');
  assert.equal(Number(query('summary',{uf:'SC',region_dimension:'visitor'})[0].pageviews),0);
  assert.equal(Number(query('summary',{uf:'SP',region_dimension:'visitor'})[0].pageviews),2);
  assert.equal(Number(query('summary',{uf:'--'})[0].pageviews),1, 'unknown region is explicit');
  assert.equal(Number(query('summary',{include_internal:true})[0].pageviews),4);
  assert.equal(Number(query('summary',{uf:"SC' OR true --"})[0].pageviews),0, 'parameters remain data');
  const slots = query('inventory');
  assert.equal(slots.length,2);
  assert.equal(Number(slots.find(r=>r.slot_key==='home-one').slot_views),0);
  assert.equal(Number(slots.find(r=>r.slot_key==='home-two').renders),1);
  assert.equal(Number(slots.find(r=>r.slot_key==='home-two').filled_slots),1);
  assert.equal(Number(slots.find(r=>r.slot_key==='home-two').house_slots),0);
  const regions = query('regions');
  assert.equal(regions.length,3);
  assert.equal(Number(query('acquisition')[0].pageviews),3);
  assert.equal(Number(query('acquisition')[0].engaged_sessions),1,'acquisition distinguishes qualified sessions from traffic alone');
  assert.equal(Number(query('acquisition',{uf:'SP'})[0].engaged_sessions),0,'qualification respects the same commercial filter');
  assert.equal(query('content').length,0);
  assert.ok(query('coverage').some(r=>r.page_family==='home' && Number(r.pageviews)===3));
  assert.equal(query('daily').reduce((sum,r)=>sum+Number(r.pageviews),0),3);
  sql(`UPDATE audience.events SET slot_state='house' WHERE slot_key='home-two';
       UPDATE audience.events SET device_class='UNKNOWN' WHERE page_view_id='00000000-0000-4000-8000-000000000003';
       UPDATE audience.events SET content_type='news',content_id='noticia-teste',page_path='/noticias/noticia-teste/' WHERE page_view_id='00000000-0000-4000-8000-000000000001';`);
  assert.equal(Number(query('inventory').find(r=>r.slot_key==='home-two').house_slots),1);
  assert.equal(Number(query('summary',{device_class:'UNKNOWN'})[0].pageviews),1);
  assert.equal(query('content')[0].content_id,'noticia-teste');
  assert.equal(Number(query('content')[0].pageviews),1);
  assert.equal(Number(query('content')[0].active_ms),31000);
  sql(`INSERT INTO audience.events(page_view_id,event_key,event_kind,visitor_id,session_id,visitor_uf,profile_uf,context_uf,market_uf,page_family,page_path)
       VALUES ('00000000-0000-4000-8000-000000000007','page','page_view','10000000-0000-4000-8000-000000000006','20000000-0000-4000-8000-000000000006','SP','SP','SP','SP','search','/busca/');
       INSERT INTO audience.events(page_view_id,event_key,event_kind,visitor_id,session_id,visitor_uf,profile_uf,context_uf,market_uf,page_family,page_path,slot_key,slot_state)
       VALUES ('00000000-0000-4000-8000-000000000007','slot:SC:one','slot_opportunity','10000000-0000-4000-8000-000000000006','20000000-0000-4000-8000-000000000006','SP','SP','SC','SC','search','/busca/','search-one','empty');`);
  const afterAjax = query('summary')[0], scAjax = query('summary',{uf:'SC'})[0];
  assert.equal(Number(afterAjax.pageviews),4,'AJAX never creates a page opening');
  assert.equal(Number(afterAjax.active_pages),4,'one physical page across contexts stays one overall page');
  assert.equal(Number(afterAjax.visitors),3);
  assert.equal(Number(scAjax.pageviews),1,'original SP opening is not rewritten');
  assert.equal(Number(scAjax.active_pages),2,'later SC context counts its observed page toward SC potential');
  assert.equal(Number(scAjax.visitors),2,'SP visitor changing search to SC joins commercial SC audience');
  assert.equal(Number(scAjax.sessions),2);
  assert.equal(Number(query('regions').find(r=>r.audience_uf==='SC').active_pages),2);
  assert.equal(Number(query('acquisition',{uf:'SC'})[0].visitors),2);
  sql(`UPDATE audience.events SET slot_state='pending' WHERE slot_key='home-one';`);
  assert.equal(Number(query('inventory').find(r=>r.slot_key==='home-one').pending_slots),1);
  assert.equal(Number(query('inventory').find(r=>r.slot_key==='home-one').empty_slots),0,'pending AJAX is not confirmed empty');
  // Profile paths deliberately omit personal slugs: distinct public content IDs
  // must qualify, while reloading the same profile or opening modals must not.
  sql(`INSERT INTO audience.events(page_view_id,event_key,event_kind,visitor_id,session_id,market_uf,page_family,page_path,content_type,content_id)
       VALUES ('00000000-0000-4000-8000-000000000011','page','page_view','10000000-0000-4000-8000-000000000011','20000000-0000-4000-8000-000000000011','SC','profile','/atleta/','profile','page-101'),
              ('00000000-0000-4000-8000-000000000012','page','page_view','10000000-0000-4000-8000-000000000011','20000000-0000-4000-8000-000000000011','SC','profile','/atleta/','profile','page-102');`);
  assert.equal(Number(query('summary',{page_family:'profile'})[0].engaged_sessions),1,'two distinct profiles qualify despite one privacy-safe path');
  assert.equal(Number(query('acquisition',{page_family:'profile'})[0].engaged_sessions),1,'acquisition qualifies two distinct profiles');
  sql(`UPDATE audience.events SET content_id='page-101' WHERE page_view_id='00000000-0000-4000-8000-000000000012';`);
  assert.equal(Number(query('summary',{page_family:'profile'})[0].engaged_sessions),0,'reloading one profile is not two distinct pages');
  assert.equal(Number(query('acquisition',{page_family:'profile'})[0].engaged_sessions),0,'acquisition does not qualify profile reloads');
  sql(`UPDATE audience.events SET content_id='page-102' WHERE page_view_id='00000000-0000-4000-8000-000000000012';
       UPDATE audience.events SET market_uf='SP' WHERE page_family='profile';
       INSERT INTO audience.events(page_view_id,event_key,event_kind,visitor_id,session_id,market_uf,page_family,page_path,slot_key,slot_state)
       SELECT page_view_id,'slot:SC','slot_opportunity',visitor_id,session_id,'SC',page_family,page_path,'profile-slot','empty'
       FROM audience.events WHERE page_family='profile';`);
  const profileSc=query('summary',{page_family:'profile',uf:'SC'})[0];
  assert.equal(Number(profileSc.engaged_sessions),1,'slot-only SC activity reuses the original page identity without content IDs');
  assert.equal(Number(query('acquisition',{page_family:'profile',uf:'SC'})[0].engaged_sessions),1,'acquisition resolves original identity across contextual UF');
  assert.equal(Number(profileSc.pageviews),0,'identity lookup never imports SP openings into SC');
  assert.equal(Number(profileSc.active_pages),2,'SC still has exactly two physical pages with activity');
  sql(`INSERT INTO audience.events(page_view_id,event_key,event_kind,visitor_id,session_id,market_uf,page_family,page_path,content_type,content_id)
       VALUES ('00000000-0000-4000-8000-000000000013','page','page_view','10000000-0000-4000-8000-000000000013','20000000-0000-4000-8000-000000000013','SC','videos','/videos/','',''),
              ('00000000-0000-4000-8000-000000000013','video:one','content_open','10000000-0000-4000-8000-000000000013','20000000-0000-4000-8000-000000000013','SC','videos','/videos/','video','video-1'),
              ('00000000-0000-4000-8000-000000000013','video:two','content_open','10000000-0000-4000-8000-000000000013','20000000-0000-4000-8000-000000000013','SC','videos','/videos/','video','video-2');`);
  assert.equal(Number(query('summary',{page_family:'videos'})[0].engaged_sessions),0,'two video modals on one page do not qualify a session');
  assert.equal(Number(query('acquisition',{page_family:'videos'})[0].engaged_sessions),0,'acquisition ignores modal content identity for page qualification');
  assert.equal(Number(query('summary',{page_family:'videos'})[0].pageviews),1,'opening modals does not create page views');
  console.log('Audience report SQL: 51 assertions passed against isolated PostgreSQL.');
} finally {
  if (started) run('pg_ctl', ['-D', resolve(scratch,'data'), '-m', 'immediate', '-w', 'stop']);
  rmSync(scratch, {recursive:true, force:true});
}
