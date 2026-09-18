#!/usr/bin/env node
// Synthetic accounts in a fresh socket-only PostgreSQL; all finance functions are canonical SQL.
import assert from 'node:assert/strict';
import {mkdtempSync,readFileSync,existsSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync,spawn} from 'node:child_process';
import {randomUUID} from 'node:crypto';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
const rr=resolve(root,'../RoadRunners/_codex/sql');
const scratch=mkdtempSync(resolve(tmpdir(),'ads-paid-banner-'));
const bin='/opt/homebrew/opt/postgresql@16/bin';
const env={PATH:process.env.PATH,LC_ALL:'C',TMPDIR:tmpdir()};
function run(name,args,input,fail=false){const r=spawnSync(resolve(bin,name),args,{input,encoding:'utf8',env,maxBuffer:24*1024*1024});if(r.status!==0&&!fail)throw Error(`${name}: ${r.error||''}${r.stdout}${r.stderr}`);return fail?r:r.stdout.trim();}
const args=['-X','-qAt','-v','ON_ERROR_STOP=1','-h',scratch,'-U','postgres','-d','postgres'];
const sql=(input,fail=false)=>run('psql',args,input,fail);
const read=name=>readFileSync(resolve(rr,name),'utf8');
const business=name=>readFileSync(resolve(root,'_codex/sql',name),'utf8');
function func(source,name){const start=source.indexOf(`CREATE OR REPLACE FUNCTION ads.${name}(`);const end=source.indexOf('$function$;',start);assert(start>=0&&end>start,`Missing canonical ${name}`);return source.slice(start,end+11);}
let started=false;
try {
  run('initdb',['-D',resolve(scratch,'data'),'-U','postgres','-A','trust','--no-locale','-c','shared_memory_type=mmap','-c','dynamic_shared_memory_type=mmap']);
  run('pg_ctl',['-D',resolve(scratch,'data'),'-l',resolve(scratch,'postgres.log'),'-o',`-F -k ${scratch} -c listen_addresses=''`,'-w','start']);started=true;
  sql(`ALTER DATABASE postgres SET ads.paid_banner_test_fixture='isolated-local-v1'`);
  sql(`CREATE ROLE runner LOGIN; CREATE ROLE runner_dba LOGIN;
    CREATE TABLE public.tb_usuarios(id integer PRIMARY KEY,is_admin boolean DEFAULT false,is_dev boolean DEFAULT false);
    CREATE TABLE public.tb_contas(id_conta bigint PRIMARY KEY,status text NOT NULL);
    CREATE TABLE public.tb_evento_corridas(id_evento integer PRIMARY KEY,ativo boolean NOT NULL,estado text);
    CREATE TABLE public.tb_conta_usuarios(id_conta bigint,id_usuario integer,status text,papel text);
    CREATE TABLE public.tb_conta_eventos(id_conta bigint,id_evento integer,status text,PRIMARY KEY(id_conta,id_evento));
    CREATE TABLE public.tb_conta_cadastro_solicitacoes(id_solicitacao bigint,id_conta bigint,id_usuario integer,status text);
    CREATE TABLE public.tb_conta_evento_solicitacoes(id_conta bigint,id_evento integer,id_usuario_solicitante integer,status text);`);
  sql(read('2026-07-26_ads_v1_canonical_foundation.sql'));
  sql(read('2026-08-18_ads_v1_admin_api.sql'));
  sql(read('2026-08-18_ads_v1_shadow_selection.sql'));
  sql(read('2026-08-18_ads_v1_house_delivery.sql'));
  sql(read('2026-08-19_ads_v1_cpc_delivery.sql'));
  sql(func(read('2026-08-20_ads_v1_all_spots_foundation.sql'),'select_delivery_candidate_v2'));
  sql(func(read('2026-08-20_ads_v1_all_spots_foundation.sql'),'replace_campaign_placements'));
  sql(`ALTER FUNCTION ads.select_delivery_candidate_v2(text,timestamptz,text,character,text,integer,text,text[],uuid[]) OWNER TO ads_owner`);
  // All-spots migration also migrates legacy data. This fixture creates only its required placement.
  sql(`INSERT INTO ads.schema_migrations(migration_key,description) VALUES('2026-08-20_ads_v1_all_spots_foundation','synthetic inventory');
    INSERT INTO ads.placements(placement_key,channel,surface,format_key,device_class,status) VALUES('rr-sidebar-banner-300x250','ROADRUNNERS','SIDEBAR','IMAGE','ALL','ACTIVE');
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO ads_owner,runner;`);
  sql(read('2026-08-21_ads_phase2_payments.sql'));
  sql(read('2026-09-02_ads_event_auction_ranking.sql'));
  sql(func(read('2026-08-20_ads_v1_house_banner.sql'),'save_house_banner_campaign'));
  const onboarding=business('2026-08-24_ads_pending_onboarding.sql');
  sql(onboarding.slice(onboarding.indexOf('CREATE TABLE IF NOT EXISTS ads.campaign_review_requests'),onboarding.indexOf('CREATE OR REPLACE FUNCTION ads.guard_reserved_voucher_redemption')));
  for(const name of ['submit_campaign_review','review_campaign','cancel_open_campaign_reviews'])sql(func(onboarding,name));
  sql(business('2026-08-25_ads_refresh_campaign_review_permission.sql'));
  sql(business('2026-09-11_ads_prepare_pending_campaign_edit.sql'));
  sql(read('2026-09-04_ads_review_activation_invariants.sql'));
  sql(`DO $b$ DECLARE f regprocedure; BEGIN FOR f IN SELECT oid::regprocedure FROM pg_proc WHERE pronamespace='ads'::regnamespace LOOP EXECUTE format('ALTER FUNCTION %s OWNER TO ads_owner',f);END LOOP; END $b$;
    ALTER TABLE ads.campaign_review_requests OWNER TO ads_owner; ALTER TABLE ads.campaign_review_history OWNER TO ads_owner;
    GRANT SELECT ON ads.campaign_review_requests,ads.campaign_review_history TO ads_reader;
    REVOKE ALL ON FUNCTION ads.cancel_open_campaign_reviews(bigint,integer,text),ads.replace_campaign_placements(uuid,text[],integer,text) FROM PUBLIC;
    GRANT EXECUTE ON FUNCTION ads.cancel_open_campaign_reviews(bigint,integer,text) TO ads_admin;
    GRANT EXECUTE ON FUNCTION ads.replace_campaign_placements(uuid,text[],integer,text) TO ads_business;
    REVOKE ALL ON FUNCTION ads.save_house_banner_campaign(uuid,bigint,text,text,text,integer,integer,text,integer,integer,text,text,boolean,timestamptz,timestamptz,integer,integer,integer,bigint) FROM PUBLIC;
    GRANT EXECUTE ON FUNCTION ads.save_house_banner_campaign(uuid,bigint,text,text,text,integer,integer,text,integer,integer,text,text,boolean,timestamptz,timestamptz,integer,integer,integer,bigint) TO ads_business;
    INSERT INTO public.tb_usuarios VALUES(901,true,false),(902,false,false),(903,false,false),(904,false,false);
    INSERT INTO public.tb_contas VALUES(1,'ATIVA'),(2,'ATIVA'),(3,'PENDENTE');
    INSERT INTO public.tb_conta_usuarios VALUES(2,902,'ATIVO','OWNER'),(2,903,'ATIVO','VISUALIZADOR'),(3,904,'ATIVO','OWNER');
    INSERT INTO public.tb_evento_corridas VALUES(901,true,'SC'); INSERT INTO public.tb_conta_eventos VALUES(2,901,'ATIVO');`);
  // Immutable reviewed HOUSE baseline: the live workspace migration was replaced by an operator query.
  // Recovered byte-for-byte from the September 15 final-review added-file diff; no runtime source edits.
  sql(readFileSync(resolve(root,'_codex/tests/paid-banner-house-scope-baseline.sql'),'utf8'));
  if(process.argv.includes('--inspect'))console.log(sql(`SELECT proname||' '||oid::regprocedure::text||' '||md5(prosrc) FROM pg_proc WHERE pronamespace='ads'::regnamespace AND proname IN('activate_campaign','serve_delivery','change_campaign_status','charge_cpc_click','record_cpc_viewable','charge_cpc_click_token','invalidate_campaign_review_on_edit','prepare_campaign_for_edit','replace_campaign_placements') ORDER BY proname; SELECT conrelid::regclass||' '||conname||' '||pg_get_constraintdef(oid) FROM pg_constraint WHERE connamespace='ads'::regnamespace AND conname IN('ck_ads_advertisements_product','ck_ads_deliveries_product','ck_ads_credit_ledger_click');`));
  const migration='2026-09-16_ads_paid_banners.sql';
  if(!process.argv.includes('--baseline')&&existsSync(resolve(rr,migration))){sql(read(migration));sql(read(migration));sql(read('2026-09-16_ads_paid_banners_preflight.sql'));}
  console.log(sql(read('2026-09-16_ads_paid_banners_contract_tests.sql')));
  console.log(sql(read('2026-09-15_ads_house_banner_scope_contract_tests.sql')).split('\n').filter(line=>line.startsWith('PASS')).join('\n'));
  const quote=v=>v===null?'NULL':"'"+String(v).replaceAll("'","''")+"'";
  const row=q=>JSON.parse(sql(`SELECT row_to_json(x) FROM (${q}) x`));
  const fails=(q,pattern)=>{const r=sql(q,true);assert.notEqual(r.status,0,`Unexpected success: ${q.slice(0,220)}`);if(pattern)assert.match(r.stderr,pattern);};
  const values={name:'Paid fixture',placement_key:'rr-sidebar-banner-300x250',image_url_desktop:'https://example.test/d.png',width_desktop:300,height_desktop:250,image_url_mobile:'https://example.test/m.png',width_mobile:300,height_mobile:250,alt_text:'Fixture brand',destination_url:'https://example.test/brand',open_new_tab:false,starts_at:new Date(Date.now()-3600000).toISOString(),ends_at:new Date(Date.now()+86400000).toISOString(),cpc_bid:1,budget_total:10,budget_daily:5,target_device:'ALL',banner_scope_v1:{regions_mode:'SELECTED',regions:['SC'],pages_mode:'SELECTED',pages:['home']}};
  const saveQ=(id=null,actor=902,account=2,patch={},submit=false)=>`SELECT * FROM ads.save_paid_banner_campaign(${quote(id)},${account},${actor},${quote(JSON.stringify({...values,...(id?{expected_version:Number(sql(`SELECT version FROM ads.campaigns WHERE campaign_id=${quote(id)}`))}:{}),...patch}))}::jsonb,${submit})`;
  const save=(...a)=>row(saveQ(...a));
  const approve=(c,actor=901,expected=c.campaign_review_request_id)=>row(`SELECT * FROM ads.review_paid_banner_campaign('${c.campaign_id}','APPROVE',${actor},'fixture','paid-${randomUUID()}',${expected})`);
  const choose=(region='SC',page='home')=>sql(`SELECT campaign_id FROM ads.select_paid_banner_candidate('rr-sidebar-banner-300x250',now(),'DESKTOP','BR',${quote(region)},${quote(page)})`);
  const serve=c=>{const token=randomUUID()+randomUUID();return {...row(`SELECT * FROM ads.serve_delivery(gen_random_uuid(),'${c.campaign_id}','${c.advertisement_id}','${c.creative_id}','${c.placement_id}',encode(sha256(convert_to('${token}','UTF8')),'hex'),now()+interval '5 minutes',now(),1::smallint,NULL,NULL,NULL,'DESKTOP','BR','SC','sidebar','{"banner_page":"home"}')`),token};};
  const clickQ=(d,event=randomUUID())=>`SELECT * FROM ads.charge_cpc_click_token('${event}','${d.delivery_id}','${d.token}',now())`;
  const session=(input,ready,holdOpen=false)=>{
    let child;
    const result=new Promise((done,reject)=>{child=spawn(resolve(bin,'psql'),args,{env});let output='',signaled=false;child.stdout.on('data',chunk=>{output+=chunk;if(ready&&!signaled&&output.includes('LOCKED')){signaled=true;ready();}});child.stderr.on('data',chunk=>{output+=chunk;});child.on('error',reject);child.on('close',code=>done({code,output}));if(holdOpen)child.stdin.write(input);else child.stdin.end(input);});
    result.release=()=>child.stdin.end('COMMIT;\n');return result;
  };
  const observeLock=async applicationName=>{
    const deadline=Date.now()+4000;
    while(Date.now()<deadline){
      if(sql(`SELECT EXISTS(SELECT 1 FROM pg_stat_activity WHERE application_name=${quote(applicationName)} AND wait_event_type='Lock' AND cardinality(pg_blocking_pids(pid))>0)`) === 't')return;
      await new Promise(resolveWait=>setTimeout(resolveWait,20));
    }
    assert.fail(`Competing session ${applicationName} never entered an observed PostgreSQL lock wait`);
  };
  for(const [actor,account] of [[903,2],[904,2],[902,3]])fails(saveQ(null,actor,account),/autoriz|permiss|conta/i);
  for(const patch of [{destination_url:'https://127.0.0.1/a'},{destination_url:'javascript:alert(1)'},{destination_url:'https://public.test@localhost/a'},{target_device:'SMARTTV'},{banner_scope_v1:{...values.banner_scope_v1,regions:['XX']}},{cpc_bid:0.5},{account_id:3}])fails(saveQ(null,902,2,patch));
  const c=save();
  save(c.campaign_id,902,2,{expected_version:1});
  fails(saveQ(c.campaign_id,902,2,{expected_version:1}),/vers|obsolet|conflit/i);
  fails(`SET ROLE runner;SELECT * FROM ads.replace_campaign_placements('${c.campaign_id}',ARRAY['rr-sidebar-banner-300x250'],904,'foreign')`,/autoriz|banner|Banner/i);
  sql(`INSERT INTO ads.placements(placement_key,channel,surface,format_key,status) VALUES('rr-test-event-safety','ROADRUNNERS','TEST','NATIVE_EVENT','ACTIVE')`);
  const beforeEventBypass=sql(`SELECT to_jsonb(x) FROM ads.campaigns x WHERE campaign_id='${c.campaign_id}'`);
  fails(`SET ROLE runner;SELECT * FROM ads.save_event_campaign('${c.campaign_id}',2,901,'rr-test-event-safety','Unsafe conversion','https://example.test/',1,10,5,now(),now()+interval '1 day','ALL','BR',NULL,902)`,/evento|EVENT/i);
  fails(`SET ROLE runner;SELECT * FROM ads.save_pending_event_campaign('${c.campaign_id}',2,NULL,901,'rr-test-event-safety','Unsafe pending conversion','https://example.test/',1,10,5,now(),now()+interval '1 day','ALL','BR',NULL,902)`,/evento|EVENT/i);
  fails(`SET ROLE runner;SELECT * FROM ads.submit_campaign_review('${c.campaign_id}',2,902,901)`,/Evento|evento/i);
  assert.equal(sql(`SELECT to_jsonb(x) FROM ads.campaigns x WHERE campaign_id='${c.campaign_id}'`),beforeEventBypass);
  fails(saveQ(c.campaign_id,904,3),/conta|autoriz/i);
  fails(`SELECT ads.activate_campaign('${c.campaign_id}',902,'bypass')`,/revis|aprov/i);
  fails(`UPDATE ads.advertisements SET core_event_id=901 WHERE campaign_id='${c.campaign_id}'`);
  fails(`INSERT INTO ads.advertisements(campaign_id,account_id,billing_model,ad_type,name,status,core_event_id,destination_url) VALUES('${c.campaign_id}',2,'CPC','EVENT','bad','ACTIVE',NULL,'https://example.test/')`);
  console.log('PASS account roles, isolation, public HTTPS, enums, scope, floor, and EVENT/BANNER references');
  sql(`SELECT ads.credit_account(2,50,'paid-fixture-credit','MANUAL',901,'{}')`);
  let pending=save(c.campaign_id,902,2,{},true);
  assert.equal(pending.review_status,'PENDING_REVIEW');assert.equal(choose(),'');
  sql(`SET ROLE runner;SELECT ads.refresh_campaign_review_prerequisites(2,NULL,901)`);
  assert.equal(sql(`SELECT status FROM ads.campaign_review_requests WHERE campaign_review_request_id=${pending.campaign_review_request_id}`),'PENDING_REVIEW','Refreshing an active account must not demote a pending banner');
  fails(`SET ROLE runner;SELECT * FROM ads.submit_paid_banner_review('${c.campaign_id}',2,904)`,/autoriz/i);
  fails(`SELECT * FROM ads.review_paid_banner_campaign('${c.campaign_id}','APPROVE',902,'bad','self',${pending.campaign_review_request_id})`,/administr|global|RunnerHub/i);
  const old=pending.campaign_review_request_id;
  pending=save(c.campaign_id,902,2,{alt_text:'Changed'},true);
  fails(`SELECT * FROM ads.review_paid_banner_campaign('${c.campaign_id}','APPROVE',901,'bad','stale',${old})`,/vigente|revis|obsolet/i);
  assert.equal(approve(pending).campaign_status,'ACTIVE');assert.equal(choose(),c.campaign_id);
  sql(`SET ROLE runner;SELECT ads.change_campaign_status('${c.campaign_id}','PAUSED',902,'normal pause');SELECT ads.activate_campaign('${c.campaign_id}',902,'normal resume')`);
  assert.equal(choose(),c.campaign_id);
  for(const [region,page] of [['BA','home'],[null,'home'],['SC','event']])assert.equal(choose(region,page),'');
  fails(`SELECT ads.change_campaign_status('${c.campaign_id}','PAUSED',904,'foreign')`,/conta|autoriz/i);
  const receipt=serve(c);assert.equal(Number(receipt.price_snapshot),0.51);
  assert.equal(sql(`SELECT count(*) FROM ads.events WHERE delivery_id='${receipt.delivery_id}' AND event_type='VIEWABLE_IMPRESSION'`),'0');
  fails(`SELECT * FROM ads.record_cpc_viewable(gen_random_uuid(),'${receipt.delivery_id}','${receipt.token}',now(),999,0.5)`,/Viewable CPC invalido/);
  assert.equal(row(`SELECT * FROM ads.record_cpc_viewable(gen_random_uuid(),'${receipt.delivery_id}','${receipt.token}',now(),1000,0.5)`).event_valid,true);
  fails(`SELECT * FROM ads.charge_cpc_click_token(gen_random_uuid(),'${receipt.delivery_id}',repeat('x',48),now())`,/Token/i);
  fails(`SELECT * FROM ads.charge_cpc_click_token(gen_random_uuid(),'${receipt.delivery_id}','${receipt.token}',now()+interval '1 hour')`,/expirada/i);
  const event=randomUUID(),debit=row(clickQ(receipt,event));assert.equal(debit.billable,true);
  const replay=row(clickQ(receipt,event));assert.equal(replay.ledger_entry_id,debit.ledger_entry_id);
  assert.equal(sql(`SELECT count(*) FROM ads.credit_ledger WHERE delivery_id='${receipt.delivery_id}' AND entry_type='DEBIT'`),'1');
  assert.equal(row(clickQ(receipt)).rejection_reason,'DELIVERY_ALREADY_BILLED');
  assert.equal(sql(`SELECT available_balance FROM ads.account_balances WHERE account_id=2`),'49.49');
  sql(`SELECT * FROM ads.reverse_click_debit('${debit.ledger_entry_id}','paid-refund',901,'fixture');SELECT * FROM ads.reverse_click_debit('${debit.ledger_entry_id}','paid-refund',901,'fixture');`);
  assert.equal(sql(`SELECT available_balance FROM ads.account_balances WHERE account_id=2`),'50.00');
  const edited=save(c.campaign_id,902,2,{cpc_bid:2});assert.equal(edited.campaign_status,'DRAFT');assert.equal(choose(),'');
  assert.equal(sql(`SELECT price_snapshot FROM ads.deliveries WHERE delivery_id='${receipt.delivery_id}'`),'0.51');
  const held=save(null,904,3,{},true);assert.equal(held.review_status,'WAITING_PREREQUISITES');
  fails(`SELECT * FROM ads.review_paid_banner_campaign('${held.campaign_id}','APPROVE',901,'pending','pending-account',${held.campaign_review_request_id})`,/conta|ativ|prerequi/i);
  sql(`UPDATE public.tb_contas SET status='ATIVA' WHERE id_conta=3;SET ROLE runner;SELECT ads.refresh_campaign_review_prerequisites(3,NULL,901)`);
  assert.equal(sql(`SELECT status FROM ads.campaign_review_requests WHERE campaign_review_request_id=${held.campaign_review_request_id}`),'PENDING_REVIEW','Account approval must release paid banner into global review queue');
  assert.equal(sql(`SELECT count(*) FROM ads.campaign_review_history WHERE campaign_review_request_id=${held.campaign_review_request_id} AND from_status='WAITING_PREREQUISITES' AND to_status='PENDING_REVIEW'`),'1');
  assert.equal(sql(`SET ROLE runner;SELECT ads.refresh_campaign_review_prerequisites(3,NULL,901)`),'0','Idempotent refresh adds no duplicate transition');
  sql(`UPDATE public.tb_contas SET status='PENDENTE' WHERE id_conta=3;SET ROLE runner;SELECT ads.refresh_campaign_review_prerequisites(3,NULL,901)`);
  assert.equal(sql(`SELECT status FROM ads.campaign_review_requests WHERE campaign_review_request_id=${held.campaign_review_request_id}`),'WAITING_PREREQUISITES','A now-inactive account must wait again');
  console.log('PASS account approval releases BANNER review, active refresh preserves pending, real demotion/history/idempotency');
  console.log('PASS latest-review lifecycle, pending account, scope, immutable price, token, canonical debit replay and refund');
  const priorState=sql(`SELECT to_jsonb(c) FROM ads.campaigns c WHERE campaign_id='${c.campaign_id}'`);
  fails(saveQ(c.campaign_id,902,2,{name:'Must roll back',starts_at:'2020-01-01T00:00:00Z',ends_at:'2020-01-02T00:00:00Z'},true),/periodo|vigente/i);
  assert.equal(sql(`SELECT to_jsonb(c) FROM ads.campaigns c WHERE campaign_id='${c.campaign_id}'`),priorState);
  const beforeCount=sql(`SELECT count(*) FROM ads.campaigns`);
  fails(saveQ(null,902,2,{starts_at:'2020-01-01T00:00:00Z',ends_at:'2020-01-02T00:00:00Z'},true));
  assert.equal(sql(`SELECT count(*) FROM ads.campaigns`),beforeCount);
  const regional=save(c.campaign_id,902,2,{},true);approve(regional);
  const national=save(null,902,2,{name:'National',cpc_bid:1.5,banner_scope_v1:{regions_mode:'ALL',regions:[],pages_mode:'ALL',pages:[]}},true);approve(national);
  assert.equal(choose(),regional.campaign_id);assert.equal(choose('BA'),national.campaign_id);assert.equal(choose(null),national.campaign_id);
  assert.equal(Number(serve(regional).price_snapshot),0.91); // score 1.50*1.2 / 2 + 0.01
  const nationalHigh=save(national.campaign_id,902,2,{name:'National high bid',cpc_bid:2,banner_scope_v1:{regions_mode:'ALL',regions:[],pages_mode:'ALL',pages:[]}},true);approve(nationalHigh);
  assert.equal(choose(),nationalHigh.campaign_id);assert.equal(Number(serve(nationalHigh).price_snapshot),1.68);
  sql(`SELECT ads.change_campaign_status('${national.campaign_id}','PAUSED',902,'fixture');SELECT ads.change_campaign_status('${regional.campaign_id}','PAUSED',902,'fixture')`);
  console.log('PASS atomic failed submit and regional relevance × bid with canonical auction price');
  // Existing EVENT save/submit/review/token contracts remain usable without forged banner events.
  sql(`INSERT INTO ads.placements(placement_key,channel,surface,format_key,status) VALUES('rr-test-paid-native','ROADRUNNERS','TEST','NATIVE_EVENT','ACTIVE');
    INSERT INTO public.tb_contas VALUES(4,'ATIVA');INSERT INTO public.tb_conta_usuarios VALUES(4,902,'ATIVO','OWNER');INSERT INTO public.tb_conta_eventos VALUES(4,901,'ATIVO');
    SELECT ads.credit_account(4,0.75,'concurrent-credit','MANUAL',901,'{}')`);
  const ev=row(`SELECT * FROM ads.save_event_campaign(NULL,4,901,'rr-test-paid-native','Shared event','https://example.test/event',0.51,5,NULL,now()-interval '1 hour',now()+interval '1 day','ALL','BR',NULL,902)`);
  const evReview=row(`SELECT * FROM ads.submit_campaign_review('${ev.campaign_id}',4,902,901)`);
  assert.equal(sql(`SET ROLE runner;SELECT ads.refresh_campaign_review_prerequisites(4,NULL,901)`),'0');
  assert.equal(sql(`SELECT status FROM ads.campaign_review_requests WHERE campaign_review_request_id=${evReview.campaign_review_request_id}`),'PENDING_REVIEW','EVENT prerequisites remain valid');
  assert.equal(row(`SELECT * FROM ads.review_campaign('${ev.campaign_id}','APPROVE',901,'fixture','event-approval',${evReview.campaign_review_request_id})`).campaign_status,'ACTIVE');
  const banner=save(null,902,4,{cpc_bid:0.51,budget_total:5,budget_daily:null},true);approve(banner);
  const ed=serve(ev),bd=serve(banner);
  sql(`SELECT * FROM ads.record_cpc_viewable(gen_random_uuid(),'${ed.delivery_id}','${ed.token}',now(),1000,0.5);SELECT * FROM ads.record_cpc_viewable(gen_random_uuid(),'${bd.delivery_id}','${bd.token}',now(),1000,0.5)`);
  let firstCharged;const balanceLocked=new Promise(r=>{firstCharged=r;});
  const chargeLeader=session(`BEGIN;SET LOCAL ROLE runner;SET statement_timeout='8s';SET idle_in_transaction_session_timeout='8s';${clickQ(ed)};\\echo LOCKED\n`,firstCharged,true);
  await Promise.race([balanceLocked,chargeLeader.then(r=>{if(!r.output.includes('LOCKED'))throw Error(r.output);})]);
  const chargeFollower=session(`SET application_name='paid_banner_wallet_contender';SET ROLE runner;SET statement_timeout='8s';${clickQ(bd)};`);
  try{await observeLock('paid_banner_wallet_contender');}finally{chargeLeader.release();}
  const race=await Promise.all([chargeLeader,chargeFollower]);
  for(const result of race)assert.equal(result.code,0,result.output);
  assert.equal(sql(`SELECT count(*) FROM ads.credit_ledger WHERE account_id=4 AND entry_type='DEBIT'`),'1');
  assert.equal(sql(`SELECT available_balance FROM ads.account_balances WHERE account_id=4`),'0.24');
  assert.equal(sql(`SELECT count(*) FROM ads.events WHERE account_id=4 AND rejection_reason='INSUFFICIENT_BALANCE'`),'1');
  sql(`SELECT ads.change_campaign_status('${banner.campaign_id}','PAUSED',902,'fixture');SELECT ads.change_campaign_status('${ev.campaign_id}','PAUSED',902,'fixture')`);
  console.log('PASS reviewed EVENT regression and concurrent EVENT+BANNER canonical shared-wallet low-balance race');
  for(const kind of ['total','daily']){
    const limited=save(null,902,2,{cpc_bid:0.51,budget_total:kind==='total'?0.51:2,budget_daily:kind==='daily'?0.51:null},true);approve(limited);
    const d1=serve(limited),d2=serve(limited);
    assert.equal(row(clickQ(d1)).billable,true);
    assert.equal(row(clickQ(d2)).rejection_reason,kind==='total'?'TOTAL_BUDGET_EXHAUSTED':'DAILY_BUDGET_EXHAUSTED');
    assert.equal(choose(),'');
    sql(`SELECT ads.change_campaign_status('${limited.campaign_id}','PAUSED',902,'fixture')`);
    fails(`SELECT ads.activate_campaign('${limited.campaign_id}',902,'budget bypass')`,/orcamento/i);
  }
  console.log('PASS total/daily budget stops selection, receipt charging and resume');
  // Real payment credit and chargeback create the hold; no fake financial tables or bypass triggers.
  sql(`INSERT INTO public.tb_contas VALUES(5,'ATIVA');INSERT INTO public.tb_conta_usuarios VALUES(5,902,'ATIVO','OWNER')`);
  const payment=row(`SELECT * FROM ads.create_payment_intent(5,902,5000,'BRL','paid-hold-test',now()+interval '1 hour')`);
  row(`SELECT * FROM ads.attach_payment_checkout('${payment.payment_intent_id}','paid-hold-link','https://example.test/checkout','paid-hold-order')`);
  assert.equal(row(`SELECT * FROM ads.confirm_payment_credit('${payment.payment_intent_id}','${payment.order_code}','paid-hold-order','paid-hold-charge',5000,'BRL','pix')`).status,'PAID');
  const holdBanner=save(null,902,5,{cpc_bid:0.51},true);approve(holdBanner);
  const spent=serve(holdBanner),remaining=serve(holdBanner);assert.equal(row(clickQ(spent)).billable,true);
  const hold=row(`SELECT * FROM ads.reverse_payment_credit('${payment.payment_intent_id}','CHARGEBACK','paid-hold-reversal',901,'fixture chargeback')`);
  assert.equal(Number(hold.pending_amount_cents),51);assert.equal(choose(),'');
  assert.equal(row(clickQ(remaining)).rejection_reason,'ACCOUNT_FINANCIAL_HOLD');
  fails(`SELECT ads.activate_campaign('${holdBanner.campaign_id}',902,'hold bypass')`,/hold/i);
  console.log('PASS real payment chargeback hold prevents banner serving, spending and resume');
  // Delivery must observe a committed edit after waiting on the selected campaign lock.
  const concurrent=save(null,902,2,{},true);approve(concurrent);
  let ready;const locked=new Promise(r=>{ready=r;});
  const editSession=session(`BEGIN;SET statement_timeout='8s';SET idle_in_transaction_session_timeout='8s';SET LOCAL ROLE runner;${saveQ(concurrent.campaign_id,902,2,{destination_url:'https://example.test/new-destination'})};\\echo LOCKED\n`,ready,true);
  await Promise.race([locked,editSession.then(r=>{if(!r.output.includes('LOCKED'))throw Error(r.output);})]);
  const deliverySession=session(`SET application_name='paid_banner_delivery_contender';SET ROLE runner;SET statement_timeout='8s';SELECT * FROM ads.serve_delivery(gen_random_uuid(),'${concurrent.campaign_id}','${concurrent.advertisement_id}','${concurrent.creative_id}','${concurrent.placement_id}',repeat('a',64),now()+interval '5 minutes',now(),1::smallint,NULL,NULL,NULL,'DESKTOP','BR','SC','sidebar','{"banner_page":"home"}');`);
  try{await observeLock('paid_banner_delivery_contender');}finally{editSession.release();}
  const [editResult,deliveryResult]=await Promise.all([editSession,deliverySession]);assert.equal(editResult.code,0,editResult.output);assert.notEqual(deliveryResult.code,0);assert.match(deliveryResult.output,/elegivel|revis|escopo/i);assert.doesNotMatch(deliveryResult.output,/deadlock|timeout/i);
  assert.equal(sql(`SELECT count(*) FROM ads.deliveries WHERE campaign_id='${concurrent.campaign_id}'`),'0');
  assert.equal(sql(`SELECT has_table_privilege('runner','ads.credit_ledger','INSERT') OR has_table_privilege('runner','ads.campaigns','UPDATE')`),'f');
  assert.equal(sql(`SELECT has_function_privilege('ads_delivery','ads.save_paid_banner_campaign(uuid,bigint,integer,jsonb,boolean)','EXECUTE') OR has_function_privilege('ads_business','ads.select_paid_banner_candidate(text,timestamptz,text,character,text,text)','EXECUTE')`),'f');
  assert.equal(sql(`SELECT bool_and(proowner='ads_owner'::regrole AND prosecdef AND proconfig @> ARRAY['search_path=pg_catalog']) FROM pg_proc WHERE pronamespace='ads'::regnamespace AND proname IN('save_paid_banner_campaign','submit_paid_banner_review','review_paid_banner_campaign','select_paid_banner_candidate')`),'t');
  console.log('PASS locked serving revalidation after concurrent edit and runtime least privilege');
  // A new migration must reject future unrelated function bodies atomically on rerun.
  for(const signature of ['ads.charge_cpc_click_token(uuid,uuid,text,timestamptz,integer,text,text,text,jsonb)','ads.refresh_campaign_review_prerequisites(bigint,integer,integer)']){
    const installed=sql(`SELECT pg_get_functiondef('${signature}'::regprocedure)`);
    const drift=installed.replace('BEGIN','BEGIN\n -- future contract');sql(drift);
    fails(read(migration),/diverg|drift|baseline/i);
    assert.equal(sql(`SELECT pg_get_functiondef('${signature}'::regprocedure)`),drift);sql(installed);
  }
  const constraint=sql(`SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid='ads.advertisements'::regclass AND conname='ck_ads_advertisements_product'`);
  sql(`ALTER TABLE ads.advertisements DROP CONSTRAINT ck_ads_advertisements_product;ALTER TABLE ads.advertisements ADD CONSTRAINT ck_ads_advertisements_product CHECK(ad_type IN('EVENT','BANNER'))`);
  fails(read(migration),/diverg|drift|baseline/i);
  sql(`ALTER TABLE ads.advertisements DROP CONSTRAINT ck_ads_advertisements_product;ALTER TABLE ads.advertisements ADD CONSTRAINT ck_ads_advertisements_product ${constraint}`);
  console.log('PASS idempotent migration and future-code drift rejection');
}catch(error){console.error(error.message);process.exitCode=1;}
finally{if(started)run('pg_ctl',['-D',resolve(scratch,'data'),'-m','fast','-w','stop']);console.log(`Isolated fixture retained: ${scratch}`);}
