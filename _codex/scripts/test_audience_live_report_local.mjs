#!/usr/bin/env node
// Executes the production report SQL in isolated PostgreSQL; no production connection or credentials.
import assert from 'node:assert/strict';
import { existsSync, mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const scratch = mkdtempSync(resolve(tmpdir(), 'audience-live-report-'));
const bin = '/opt/homebrew/opt/postgresql@16/bin';
const run = (name, args, input) => {
  const result = spawnSync(resolve(bin, name), args, { input, encoding: 'utf8', env: { PATH: process.env.PATH, LC_ALL: 'C', TMPDIR: tmpdir() } });
  if (result.status !== 0) throw Error(`${name}: ${result.stdout || ''}${result.stderr || ''}`);
  return result.stdout.trim();
};
const sql = input => run('psql', ['-X', '-qAt', '-v', 'ON_ERROR_STOP=1', '-h', scratch, '-U', 'postgres', '-d', 'postgres'], input);
const literal = value => typeof value === 'number' || typeof value === 'boolean' ? String(value) : `'${String(value).replaceAll("'", "''")}'`;
const query = (overrides = {}) => {
  const path = resolve(root, 'portal/audiencia/queries/live_journey.sql');
  assert.ok(existsSync(path), 'the LIVE report must expose campaign totals and event journeys');
  let statement = readFileSync(path, 'utf8').replace('/* AUDIENCE_FILTER */', readFileSync(resolve(root, 'portal/audiencia/queries/filter.sql'), 'utf8'));
  const params = { days: 7, environment: 'prod', include_internal: false, region_dimension: 'market', uf: '', page_family: '', device_class: '', live_source: '', live_campaign: '', live_city: '', live_event: '', ...overrides };
  for (const [key, value] of Object.entries(params)) statement = statement.replace(new RegExp(`(?<!:):${key}\\b`, 'g'), literal(value));
  return JSON.parse(sql(`SELECT coalesce(json_agg(r),'[]'::json) FROM (${statement.trim().replace(/;$/, '')}) r;`));
};
let checks = 0;
const eq = (actual, expected, message) => { assert.deepEqual(actual, expected, message); checks++; };
const counts = row => Object.fromEntries(['pageviews','sessions','qualified_sessions','event_sessions','outbound_sessions','matched_outbound_sessions','unmatched_outbound_sessions'].map(k => [k, Number(row[k])]));
const find = (rows, type, event = '', campaign = 'live_pilot', source = 'google') => rows.find(r => r.row_type === type && r.content_id === event && r.campaign === campaign && r.source === source);
let started = false;
try {
  run('initdb', ['-D', resolve(scratch, 'data'), '-U', 'postgres', '-A', 'trust', '--no-locale']);
  run('pg_ctl', ['-D', resolve(scratch, 'data'), '-l', resolve(scratch, 'postgres.log'), '-o', `-F -k ${scratch} -c listen_addresses=''`, '-w', 'start']);
  started = true;
  sql(`CREATE SCHEMA audience;
    CREATE TABLE audience.events (
      page_view_id uuid, event_key text, event_kind text, occurred_at timestamptz DEFAULT now(), received_at timestamptz DEFAULT now(),
      visitor_id uuid, session_id uuid, environment text DEFAULT 'prod', is_internal boolean DEFAULT false,
      visitor_uf text DEFAULT 'SP', profile_uf text DEFAULT '', context_uf text DEFAULT 'SC', market_uf text DEFAULT 'SC',
      page_family text, page_path text, content_type text DEFAULT '', content_id text DEFAULT '',
      source text DEFAULT 'google', medium text DEFAULT 'cpc', campaign text DEFAULT 'live_pilot', creative text DEFAULT 'ad_a',
      slot_key text DEFAULT '', placement_key text DEFAULT '', slot_state text DEFAULT '', device_class text DEFAULT 'MOBILE',
      active_ms integer DEFAULT 0, PRIMARY KEY(page_view_id,event_key));
    CREATE TABLE public.tb_agrega_eventos(id_agrega_evento integer PRIMARY KEY,tag text);
    CREATE TABLE public.tb_evento_corridas(id_evento integer PRIMARY KEY,id_agrega_evento integer,nome_evento text,tag text,cidade text,estado text);
    INSERT INTO public.tb_agrega_eventos VALUES(1,'live-run-xp'),(2,'outro-circuito');
    INSERT INTO public.tb_evento_corridas VALUES
      (101,1,'Live Jaraguá','live-jaragua','Jaraguá do Sul','SC'),
      (102,1,'Live Campinas','live-campinas','Campinas','SP'),
      (103,2,'Outra prova','outra-prova','Campinas','SP');`);
  const id = (prefix, n) => `${prefix}0000000-0000-4000-8000-${String(n).padStart(12,'0')}`;
  const add = (page, session, kind = 'page_view', content = '', extra = {}) => {
    const row = {
      page_view_id:id(0,page), visitor_id:id(1,session === 3 ? 1 : session), session_id:id(2,session),
      event_kind:kind, event_key:kind === 'outbound_click' ? `outbound_click:live_registration:${content}` : kind,
      page_family:content ? 'event' : 'circuit', page_path:content ? `/evento/prova-${content}/` : '/circuito/live-run-xp/',
      content_type:content ? 'event' : 'circuit', content_id:content || '1', ...extra
    };
    sql(`INSERT INTO audience.events(${Object.keys(row).join(',')}) VALUES(${Object.values(row).map(literal).join(',')});`);
  };
  add(1,1); add(2,1,'page_view','101'); add(3,1,'page_view','101'); add(4,1,'page_view','102');
  add(2,1,'outbound_click','101'); add(3,1,'outbound_click','101'); add(4,1,'outbound_click','102');
  add(5,2); // Circuit-only arrival must remain in the campaign denominator.
  add(6,3,'page_view','101'); add(6,3,'page_engagement','101',{active_ms:31000});
  const delayedOccurrence=new Date(Date.now()-2*86400000),delayedReceipt=new Date(delayedOccurrence.getTime()+120000);
  add(7,4,'outbound_click','101',{page_family:'circuit',page_path:'/circuito/live-run-xp/',occurred_at:delayedOccurrence.toISOString(),received_at:delayedReceipt.toISOString()}); // Circuit modal can exit without opening the event; no arrival is fabricated.
  add(8,5,'page_view','102',{source:'instagram',medium:'paid_social',campaign:'live_social'});
  add(8,5,'outbound_click','102',{source:'instagram',medium:'paid_social',campaign:'live_social'});
  add(9,6,'page_view','101',{environment:'dev'}); add(9,6,'outbound_click','101',{environment:'dev'});
  add(10,7,'page_view','101',{is_internal:true}); add(10,7,'outbound_click','101',{is_internal:true});
  add(11,8,'page_view','101',{occurred_at:'2020-01-01'}); add(11,8,'outbound_click','101',{occurred_at:'2020-01-01'});
  add(12,9,'page_view','101',{campaign:'',source:'direct'});
  add(13,10,'page_view','103'); // Other event is campaign navigation, not a LIVE event visit.
  add(14,11,'outbound_click','999'); // Deleted/missing catalog event must not hide an observed exit.
  add(15,12,'outbound_click','101',{event_key:'outbound_click:another_partner:101'});
  add(16,13,'outbound_click','101',{event_key:'outbound_click:live_registration:102'});
  add(17,14,'page_view','101',{campaign:'live_second',creative:'ad_b'});
  // One session spans creative labels; campaign totals still deduplicate it.
  add(18,1,'page_engagement','101',{creative:'ad_b',active_ms:5000});

  const rows = query(), campaign = find(rows,'campaign');
  eq(counts(campaign), {pageviews:7,sessions:4,qualified_sessions:2,event_sessions:2,outbound_sessions:3,matched_outbound_sessions:1,unmatched_outbound_sessions:2}, 'campaign totals count arrivals once, keep bounces and distinguish missing page beacons');
  eq(counts(find(rows,'event','101')), {pageviews:3,sessions:2,qualified_sessions:0,event_sessions:2,outbound_sessions:2,matched_outbound_sessions:1,unmatched_outbound_sessions:1}, 'repeat page/CTA clicks deduplicate by session/event, not visitor');
  eq(counts(find(rows,'event','102')), {pageviews:1,sessions:1,qualified_sessions:0,event_sessions:1,outbound_sessions:1,matched_outbound_sessions:1,unmatched_outbound_sessions:0}, 'a second event in the same session is distinct only within event detail');
  eq(find(rows,'event','103'), undefined, 'unrelated circuit does not enter LIVE event detail');
  eq(find(rows,'event','999').event_city, '', 'unmatched catalog keeps unknown city explicit');
  eq(Number(find(rows,'event','999').unmatched_outbound_sessions),1,'missing catalog exit is visible without inventing a visit');
  eq(new Date(campaign.first_outbound).toISOString(),delayedReceipt.toISOString(),'first reception uses server receipt time, not client occurrence time');
  eq(rows.some(r => r.campaign === ''), false, 'untagged traffic is not attributed to a paid campaign');
  eq(Number(find(rows,'campaign','','live_social','instagram').sessions),1,'different origins remain separate');
  eq(Number(find(rows,'campaign','','live_second').outbound_sessions),0,'zero received events remains a true observed count');
  eq(find(rows,'campaign','','live_second').first_outbound,null,'no received outbound must not fabricate an instrumentation start');
  eq(Number(find(query({include_internal:true}),'campaign').sessions),5,'internal opt-in remains explicit');
  eq(Number(find(query({environment:'dev'}),'campaign').outbound_sessions),1,'environment filter is applied before aggregation');
  eq(query({device_class:'DESKTOP'}),[],'device filter does not retain events from another device');
  eq(query({uf:'SC',region_dimension:'visitor'}),[],'physical UF and commercial UF remain separate');
  eq(Number(find(query({uf:'SC'}),'campaign').sessions),4,'commercial UF uses observed context, not catalog city');
  const city = query({live_city:'camp'});
  eq(city.filter(r => r.row_type==='event').map(r=>r.content_id),['102','102'],'city filters event detail across campaigns');
  eq(counts(find(city,'campaign')),counts(campaign),'city filter does not shrink the campaign arrival denominator');
  eq(query({live_event:'101'}).filter(r=>r.row_type==='event').every(r=>r.content_id==='101'),true,'event ID filter narrows only detail');
  eq(query({live_source:'instagram'}).map(r=>r.source),['instagram','instagram'],'source filter applies to summary and detail');
  eq(query({live_campaign:'SECOND'}).map(r=>r.campaign),['live_second','live_second'],'campaign search is case-insensitive');
  eq(query({live_campaign:"' OR true --"}),[],'campaign input remains literal data');
  eq(query({live_city:"' OR true --"}).filter(r=>r.row_type==='event'),[],'city input remains literal data');
  const circuitOnly=query({page_family:'circuit'});
  eq(Number(find(circuitOnly,'campaign').sessions),2,'page-family selection is an explicit activity scope');
  eq(Number(find(circuitOnly,'event','101').outbound_sessions),1,'circuit modal exit remains identifiable by target event');
  eq(Number(find(circuitOnly,'event','101').event_sessions),0,'circuit-only filter does not fabricate an event-page visit');
  sql("DELETE FROM audience.events WHERE event_kind='outbound_click';");
  eq(Number(find(query(),'campaign').outbound_sessions),0,'historical views survive when no outgoing telemetry exists');
  eq(find(query(),'campaign').first_outbound,null,'historical page-only data provides no false outbound coverage evidence');
  console.log(`Audience LIVE report SQL: ${checks} behavioral assertions passed against isolated PostgreSQL.`);
} finally {
  if (started) run('pg_ctl',['-D',resolve(scratch,'data'),'-m','immediate','-w','stop']);
  rmSync(scratch,{recursive:true,force:true});
}
