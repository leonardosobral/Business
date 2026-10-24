#!/usr/bin/env node
// Execute the exact SQL embedded in the protected CFML include, on disposable PostgreSQL 16.
import assert from 'node:assert/strict';
import {existsSync, mkdtempSync, readFileSync, rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {dirname, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
const runtime=resolve(root,'includes/backend/business_home_metrics.cfm');
assert.ok(existsSync(runtime),'Home metrics must implement the production SQL contract in a protected CFML include');
const source=readFileSync(runtime,'utf8');
const scratch=mkdtempSync(resolve(tmpdir(),'business-home-metrics-'));
const bin='/opt/homebrew/opt/postgresql@16/bin';
const run=(name,args,input)=>{
  const r=spawnSync(resolve(bin,name),args,{input,encoding:'utf8',env:{PATH:process.env.PATH,LC_ALL:'C',TMPDIR:tmpdir()}});
  if(r.status!==0) throw Error(`${name}: ${r.stdout||''}${r.stderr||''}`);
  return r.stdout.trim();
};
const sql=input=>run('psql',['-X','-qAt','-v','ON_ERROR_STOP=1','-h',scratch,'-U','postgres','-d','postgres'],input);
const literal=x=>typeof x==='number'||typeof x==='boolean'?String(x):`'${String(x).replaceAll("'","''")}'`;
const query=(name,days=7,zone='UTC')=>{
  const match=source.match(new RegExp(`// BEGIN ${name.toUpperCase()} SQL\\s+VARIABLES\\.businessHomeSql\\.${name} = "([\\s\\S]*?)";\\s+// END ${name.toUpperCase()} SQL`));
  assert.ok(match,`Runtime ${name} query must be present`);
  const statement=match[1].replaceAll(':days',String(days)).replaceAll('now()',"TIMESTAMPTZ '2026-10-24 15:00:00+00'");
  return JSON.parse(sql(`SET TIME ZONE ${literal(zone)}; SELECT row_to_json(r) FROM (${statement}) r;`));
};
let checks=0;
const eq=(actual,expected,message)=>{assert.deepEqual(actual,expected,message);checks++;};
const projection=(row,keys)=>Object.fromEntries(keys.map(key=>[key,typeof row[key]==='boolean'?row[key]:Number(row[key])]));
const id=n=>`00000000-0000-4000-8000-${String(n).padStart(12,'0')}`;
const addEvent=(page,visitor,kind,when,extra={})=>{
  const row={page_view_id:id(page),visitor_id:id(visitor),event_key:kind,event_kind:kind,occurred_at:when,...extra};
  sql(`INSERT INTO audience.events(${Object.keys(row).join(',')}) VALUES(${Object.values(row).map(literal).join(',')});`);
};
const day=(offset,hour='12:00:00-03')=>{
  const d=new Date(Date.UTC(2026,9,24-offset));
  return `${d.toISOString().slice(0,10)} ${hour}`;
};
let started=false;
try {
  run('initdb',['-D',resolve(scratch,'data'),'-U','postgres','-A','trust','--no-locale']);
  run('pg_ctl',['-D',resolve(scratch,'data'),'-l',resolve(scratch,'postgres.log'),'-o',`-F -k ${scratch} -c listen_addresses=''`,'-w','start']);started=true;
  sql(`CREATE SCHEMA audience; CREATE SCHEMA ads;
    CREATE TABLE audience.events(page_view_id uuid,event_key text,event_kind text,visitor_id uuid,occurred_at timestamptz,environment text DEFAULT 'prod',is_internal boolean DEFAULT false,PRIMARY KEY(page_view_id,event_key));
    CREATE TABLE ads.daily_metrics(metric_date date,billing_model text,ad_type text,viewable_impression_count bigint,valid_click_count bigint,cost numeric(14,2));
    CREATE TABLE public.tb_contas(id_conta bigserial PRIMARY KEY,data_criacao timestamptz);
    CREATE TABLE public.tb_usuarios(id serial PRIMARY KEY,data_criacao timestamp);
    CREATE TABLE public.tb_usuarios_gestao(id_usuario integer PRIMARY KEY,ativo boolean,excluido boolean);`);
  for(let offset=0;offset<=61;offset++) {
    for(const kind of ['page_view','content_open','video_start','outbound_click','video_complete','video_progress','page_engagement','slot_view','ad_view']) addEvent(offset+1,1,kind,day(offset));
    sql(`INSERT INTO ads.daily_metrics VALUES(${literal(day(offset).slice(0,10))},'CPC','EVENT',10,2,1.25),(${literal(day(offset).slice(0,10))},'CPC','BANNER',20,3,2.50);
      INSERT INTO public.tb_contas(data_criacao) VALUES(${literal(day(offset))});
      INSERT INTO public.tb_usuarios(data_criacao) VALUES(${literal(day(offset,'12:00:00'))});`);
  }
  const audienceKeys=['visitors','pageviews','interactions','previous_visitors','previous_pageviews','previous_interactions','comparison_ready','interactions_comparison_ready'];
  const adsKeys=['impressions','clicks','cost','event_cost','banner_cost','previous_impressions','previous_clicks','previous_cost','previous_event_cost','previous_banner_cost','comparison_ready'];
  for(const days of [7,30]) {
    eq(projection(query('audience',days),audienceKeys),{visitors:1,pageviews:days,interactions:3*days,previous_visitors:1,previous_pageviews:days,previous_interactions:3*days,comparison_ready:true,interactions_comparison_ready:true},`${days} days include today, browser identities deduplicate, and only the explicit interaction allowlist counts`);
    eq(projection(query('ads',days),adsKeys),{impressions:30*days,clicks:5*days,cost:3.75*days,event_cost:1.25*days,banner_cost:2.5*days,previous_impressions:30*days,previous_clicks:5*days,previous_cost:3.75*days,previous_event_cost:1.25*days,previous_banner_cost:2.5*days,comparison_ready:true},`${days} day Ads totals combine both CPC types without losing separate destinations`);
    for(const name of ['accounts','users']) eq(projection(query(name,days),['new_count','previous_new_count','comparison_ready']),{new_count:days,previous_new_count:days,comparison_ready:true},`${name} uses equal full date windows and excludes future records`);
    for(const name of ['audience','ads','accounts','users']) eq(query(name,days,'Pacific/Honolulu'),query(name,days,'UTC'),`${name} ${days} day bounds are independent from database session timezone`);
  }
  addEvent(1000,1000,'page_view',day(0));
  addEvent(1000,1000,'page_view',day(0),{event_key:'duplicate-page-beacon'});
  addEvent(1001,1001,'content_open',day(0));
  for(const extra of [{environment:'dev'},{is_internal:true},{is_internal:null}]) {
    // NULL is inserted separately so the explicit false-only scope is exercised.
    if(extra.is_internal===null) {sql(`INSERT INTO audience.events VALUES('${id(2000)}','page_view','page_view','${id(2000)}',${literal(day(0))},'prod',NULL)`);continue;}
    const n=extra.environment?2001:2002;
    for(const kind of ['page_view','content_open']) addEvent(n,n,kind,day(0),extra);
  }
  addEvent(2003,2003,'page_view','2026-10-24 15:00:01+00');
  eq(projection(query('audience'),audienceKeys),{visitors:3,pageviews:8,interactions:22,previous_visitors:1,previous_pageviews:7,previous_interactions:21,comparison_ready:true,interactions_comparison_ready:true},'Duplicate page beacons do not inflate views; non-page interactions identify browsers; dev/internal/null-internal/future traffic is excluded');
  addEvent(1002,1002,'page_engagement',day(0));
  eq(Number(query('audience').visitors),4,'A browser with only a passive beacon is still a visitor');
  addEvent(2004,2004,'page_view','2026-10-18 00:00:00-03');
  addEvent(2005,2005,'page_view','2026-10-17 23:59:59.999-03');
  addEvent(2006,2006,'page_view','2026-10-11 00:00:00-03');
  addEvent(2007,2007,'page_view','2026-10-10 23:59:59.999-03');
  eq(projection(query('audience'),['visitors','pageviews','previous_visitors','previous_pageviews']),{visitors:5,pageviews:9,previous_visitors:3,previous_pageviews:9},'São Paulo midnight boundaries are inclusive at start and exclusive between periods');
  sql(`INSERT INTO ads.daily_metrics VALUES('2026-10-24','CPM','EVENT',999,999,999),('2026-10-24','CPC','OTHER',999,999,999),('2026-10-25','CPC','EVENT',999,999,999);
    INSERT INTO public.tb_contas(data_criacao) VALUES('2026-10-24 15:00:01+00');
    INSERT INTO public.tb_usuarios(data_criacao) VALUES('2026-10-24 12:00:01');
    INSERT INTO public.tb_usuarios(data_criacao) VALUES('2026-10-24 11:00:00'),('2026-10-24 11:00:00'),('2026-10-24 11:00:00');
    INSERT INTO public.tb_usuarios_gestao VALUES(64,false,false),(65,false,true),(66,true,false);`);
  eq(Number(query('ads').cost),26.25,'Only CPC EVENT/BANNER rows through today contribute to investment');
  eq(Number(query('accounts').new_count),7,'Accounts exclude future timestamps');
  eq(Number(query('users').new_count),8,'Users without management row count once; inactive/deleted are excluded and explicit active remains');
  sql("DELETE FROM ads.daily_metrics WHERE ad_type='BANNER' AND metric_date='2026-10-19';");
  eq(query('ads').comparison_ready,true,'A sparse no-activity day remains comparable when the type has established prior history');
  sql("DELETE FROM ads.daily_metrics WHERE ad_type='BANNER' AND metric_date<'2026-10-11';");
  eq(query('ads').comparison_ready,false,'A newly instrumented active Ads type cannot claim prior coverage');
  sql("DELETE FROM audience.events WHERE event_kind='video_start' AND occurred_at<'2026-10-11 00:00:00-03';");
  eq(query('audience').comparison_ready,true,'Visitor/pageview history remains comparable when a separate interaction type is new');
  eq(query('audience').interactions_comparison_ready,false,'New interaction instrumentation cannot fabricate comparable interaction growth');
  addEvent(15,1,'video_start',day(14));
  eq(query('audience').interactions_comparison_ready,true,'Reestablished prior instrumentation restores the interaction baseline');
  sql("DELETE FROM audience.events WHERE occurred_at>='2026-10-13 00:00:00-03' AND occurred_at<'2026-10-14 00:00:00-03';");
  eq(query('audience').comparison_ready,false,'A missing measured day suppresses growth even when the SQL succeeds');
  sql('TRUNCATE audience.events,ads.daily_metrics,public.tb_contas,public.tb_usuarios_gestao,public.tb_usuarios;');
  for(const name of ['audience','ads','accounts','users']) {
    const result=query(name);
    eq(result.comparison_ready,false,`${name} without history has no comparative baseline`);
    eq(Number(result[name==='audience'?'visitors':name==='ads'?'cost':'new_count']),0,`${name} successful empty query returns measured zero`);
  }
  console.log(`Business home metrics SQL: ${checks} behavioral assertions passed against isolated PostgreSQL 16.`);
} finally {
  if(started) run('pg_ctl',['-D',resolve(scratch,'data'),'-m','immediate','-w','stop']);
  rmSync(scratch,{recursive:true,force:true});
}
