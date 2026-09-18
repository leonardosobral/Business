#!/usr/bin/env node
// Real canonical SQL in a fresh Unix-socket-only PostgreSQL. No production variables.
import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync, spawn } from 'node:child_process';
const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const rr = resolve(root, '../RoadRunners/_codex/sql');
const scratch = mkdtempSync(resolve(tmpdir(), 'ads-house-scope-'));
const bin = '/opt/homebrew/opt/postgresql@16/bin';
const env = {PATH:process.env.PATH, LC_ALL:'C', TMPDIR:tmpdir()};
function run(name,args,input,fail=false) {
  const r=spawnSync(resolve(bin,name),args,{input,encoding:'utf8',env,maxBuffer:16*1024*1024});
  if(r.status!==0&&!fail) throw new Error(`${name}: ${r.error||''}${r.stdout}${r.stderr}`);
  return fail?r:r.stdout.trim();
}
const args=['-X','-qAt','-v','ON_ERROR_STOP=1','-h',scratch,'-U','postgres','-d','postgres'];
const sql=(input,fail=false)=>run('psql',args,input,fail);
const read=name=>readFileSync(resolve(rr,name),'utf8');
const func=(source,name)=>{
  const start=source.indexOf(`CREATE OR REPLACE FUNCTION ads.${name}(`);
  const end=source.indexOf('$function$;',start);
  assert(start>=0&&end>start,`Missing canonical ${name}`);
  return source.slice(start,end+'$function$;'.length);
};
const session=(input,ready)=>new Promise((resolveSession,reject)=>{
  const child=spawn(resolve(bin,'psql'),args,{env}); let output=''; let signaled=false;
  child.stdout.on('data',chunk=>{output+=chunk;if(ready&&!signaled&&output.includes('LOCKED')){signaled=true;ready();}});
  child.stderr.on('data',chunk=>{output+=chunk;}); child.on('error',reject);
  child.on('close',code=>resolveSession({code,output}));child.stdin.end(input);
});
let started=false;
try {
  run('initdb',['-D',resolve(scratch,'data'),'-U','postgres','-A','trust','--no-locale']);
  run('pg_ctl',['-D',resolve(scratch,'data'),'-l',resolve(scratch,'postgres.log'),'-o',`-F -k ${scratch} -c listen_addresses=''`,'-w','start']);started=true;
  sql(`CREATE ROLE runner LOGIN; CREATE ROLE runner_dba LOGIN;
    CREATE TABLE public.tb_usuarios(id integer PRIMARY KEY,is_admin boolean DEFAULT false,is_dev boolean DEFAULT false);
    CREATE TABLE public.tb_contas(id_conta bigint PRIMARY KEY,status text NOT NULL);
    CREATE TABLE public.tb_evento_corridas(id_evento integer PRIMARY KEY,ativo boolean NOT NULL,estado text);
    CREATE TABLE public.tb_conta_usuarios(id_conta bigint,id_usuario integer,status text,papel text);
    CREATE TABLE public.tb_conta_eventos(id_conta bigint,id_evento integer,status text,PRIMARY KEY(id_conta,id_evento));`);
  sql(read('2026-07-26_ads_v1_canonical_foundation.sql'));
  sql(read('2026-08-18_ads_v1_admin_api.sql'));
  sql(func(read('2026-08-20_ads_v1_house_banner.sql'),'save_house_banner_campaign'));
  const auction=read('2026-09-02_ads_event_auction_ranking.sql');
  sql(`CREATE TABLE ads.account_financial_holds(account_id bigint,status text);
    ALTER TABLE ads.account_financial_holds OWNER TO ads_owner;
    GRANT SELECT ON ads.account_financial_holds TO ads_reader;
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO ads_owner,runner;
    INSERT INTO public.tb_usuarios VALUES(901,true,false),(902,false,false),(903,false,true);
    INSERT INTO public.tb_contas VALUES(1,'ATIVA'),(2,'ATIVA');
    INSERT INTO public.tb_evento_corridas VALUES(901,true,'SC');
    INSERT INTO public.tb_conta_eventos VALUES(1,901,'ATIVO');
    INSERT INTO ads.schema_migrations(migration_key,description) VALUES('2026-09-02_ads_event_auction_ranking','isolated real function baseline');
    INSERT INTO ads.placements(placement_key,channel,surface,format_key,device_class,status)
      VALUES('rr-sidebar-banner-300x250','ROADRUNNERS','SIDEBAR','IMAGE','ALL','ACTIVE');`);
  for(const name of ['event_auction_relevance_factor','event_auction_price','event_auction_tie_break','select_delivery_candidate_v2','apply_event_auction_price_snapshot']) sql(func(auction,name));
  sql(`CREATE TRIGGER trg_ads_deliveries_event_auction_price BEFORE INSERT ON ads.deliveries
    FOR EACH ROW EXECUTE FUNCTION ads.apply_event_auction_price_snapshot();
    DO $b$ DECLARE f regprocedure; BEGIN FOR f IN SELECT oid::regprocedure FROM pg_proc WHERE pronamespace='ads'::regnamespace LOOP
      EXECUTE format('ALTER FUNCTION %s OWNER TO ads_owner',f); END LOOP; END $b$;
    REVOKE ALL ON FUNCTION ads.save_house_banner_campaign(uuid,bigint,text,text,text,integer,integer,text,integer,integer,text,text,boolean,timestamptz,timestamptz,integer,integer,integer,bigint),
      ads.select_delivery_candidate_v2(text,timestamptz,text,character,text,integer,text,text[],uuid[]) FROM PUBLIC;
    GRANT EXECUTE ON FUNCTION ads.save_house_banner_campaign(uuid,bigint,text,text,text,integer,integer,text,integer,integer,text,text,boolean,timestamptz,timestamptz,integer,integer,integer,bigint) TO ads_business;
    GRANT EXECUTE ON FUNCTION ads.select_delivery_candidate_v2(text,timestamptz,text,character,text,integer,text,text[],uuid[]) TO ads_delivery;`);
  if(!process.argv.includes('--baseline')) {
    const migration=read('2026-09-15_ads_house_banner_scope.sql');
    sql(migration);sql(migration);
    console.log(sql(read('2026-09-02_ads_event_auction_ranking_contract_tests.sql')).split('\n').filter(line=>line.includes('PASSED')).join('\n'));
    console.log(sql(read('2026-07-26_ads_v1_canonical_contract_tests.sql')).split('\n').filter(line=>line.includes('PASSED')).join('\n'));
    // An unrecognized concurrent contract edit must fail and leave all functions untouched.
    const signature='ads.select_delivery_candidate_v2(text,timestamptz,text,character,text,integer,text,text[],uuid[])';
    const installed=sql(`SELECT pg_get_functiondef('${signature}'::regprocedure)`);
    const altered=installed.replace('WITH raw_context AS (','-- unrelated future contract\nWITH raw_context AS (');
    sql(altered);
    const mismatch=sql(migration,true);
    assert.notEqual(mismatch.status,0);assert.match(mismatch.stderr,/Baseline select_delivery_candidate_v2 divergente/);
    assert.equal(sql(`SELECT pg_get_functiondef('${signature}'::regprocedure)`),altered);
    sql(installed);
    console.log('PASS incompatible baseline rejected atomically; exact installed contract preserved.');
  }
  console.log(sql(read('2026-09-15_ads_house_banner_scope_contract_tests.sql')).split('\n').filter(line=>line.startsWith('PASS')).join('\n'));
  if(!process.argv.includes('--baseline')) {
    // Selector observes old scope, concurrent writer commits new scope while delivery waits.
    const c=JSON.parse(sql(`WITH x AS(SELECT * FROM ads.save_house_banner_campaign_v2(NULL,1,'rr-sidebar-banner-300x250','Concurrent','https://example.test/d.png',300,250,'https://example.test/m.png',300,250,'alt','https://example.test/',false,now()-interval '1 hour',now()+interval '1 day',1,1,901,NULL,'{"regions_mode":"ALL","regions":[],"pages_mode":"ALL","pages":[]}')) SELECT row_to_json(x) FROM x;`));
    sql(`SELECT ads.activate_campaign('${c.campaign_id}',901,'fixture');`);
    assert.equal(sql(`SELECT campaign_id FROM ads.select_house_banner_candidate('rr-sidebar-banner-300x250',now(),'DESKTOP','BR','SP','home')`),c.campaign_id);
    let ready;const locked=new Promise(resolveReady=>{ready=resolveReady;});
    const leader=session(`BEGIN;SET LOCAL statement_timeout='5s';
      SET LOCAL ROLE runner;
      SELECT ads.change_campaign_status('${c.campaign_id}','PAUSED',901,'concurrent scope edit');
      SELECT * FROM ads.save_house_banner_campaign_v2('${c.campaign_id}',1,'rr-sidebar-banner-300x250','Concurrent SC','https://example.test/d.png',300,250,'https://example.test/m.png',300,250,'alt','https://example.test/',false,now()-interval '1 hour',now()+interval '1 day',1,1,901,NULL,'{"regions_mode":"SELECTED","regions":["SC"],"pages_mode":"ALL","pages":[]}');
      SELECT ads.activate_campaign('${c.campaign_id}',901,'concurrent scope edit complete');
      \\echo LOCKED
      SELECT pg_sleep(0.4);COMMIT;`,ready);
    await Promise.race([locked,leader.then(r=>{if(!r.output.includes('LOCKED'))throw new Error(r.output);})]);
    const follower=session(`SET ROLE runner;SET statement_timeout='5s';SELECT * FROM ads.serve_delivery(gen_random_uuid(),'${c.campaign_id}','${c.advertisement_id}','${c.creative_id}','${c.placement_id}',repeat('a',64),now()+interval '5 minutes',now(),1::smallint,NULL,NULL,NULL,'DESKTOP','BR','SP','sidebar','{"banner_page":"home"}');`);
    const [a,b]=await Promise.all([leader,follower]);
    assert.equal(a.code,0,a.output);assert.notEqual(b.code,0,b.output);assert.match(b.output,/escopo|elegivel/);assert.doesNotMatch(b.output,/deadlock|timeout/i);
    assert.equal(sql(`SELECT count(*) FROM ads.deliveries WHERE campaign_id='${c.campaign_id}'`),'0');
    console.log('PASS concurrency: delivery waits for campaign edit, rejects newly incompatible scope; no receipt/debit.');
  }
} catch(error) {console.error(error.message);process.exitCode=1;}
finally {if(started)run('pg_ctl',['-D',resolve(scratch,'data'),'-m','fast','-w','stop']);console.log(`Isolated fixture retained: ${scratch}`);}
