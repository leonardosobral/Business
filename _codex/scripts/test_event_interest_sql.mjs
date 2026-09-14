import assert from 'node:assert/strict';
import {mkdtempSync,readFileSync,rmSync,existsSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
// Fail before starting a database when implementation is absent.
const report=readFileSync(process.env.EVENT_INTEREST_SQL_SOURCE||resolve(root,'portal/audiencia/queries/event_interest.sql'),'utf8');
const agenda=readFileSync(resolve(root,'portal/audiencia/queries/event_agenda.sql'),'utf8');
const agendaRankingPath=resolve(root,'portal/audiencia/queries/event_agenda_ranking.sql');
assert.ok(existsSync(agendaRankingPath),'agenda requires its own ranking, including events with no measured views');
const agendaRanking=readFileSync(agendaRankingPath,'utf8');
// Keep the indexed catalog key numeric: casting it forced repeated full-table
// scans on production. Convert only the untrusted audience identifier instead.
assert.doesNotMatch(report,/c\.id_evento::text\s*=/,'catalog lookup must preserve the integer index');
const scratch=mkdtempSync(resolve(tmpdir(),'event-interest-pg-'));
const bin='/opt/homebrew/opt/postgresql@16/bin';
function run(name,args,input){const r=spawnSync(resolve(bin,name),args,{input,encoding:'utf8',env:{PATH:process.env.PATH,LC_ALL:'C',TMPDIR:tmpdir()}});if(r.status!==0)process.stderr.write(r.stdout+r.stderr);assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout.trim();}
const sql=s=>run('psql',['-X','-qAt','-v','ON_ERROR_STOP=1','-h',scratch,'-U','postgres','-d','postgres'],s.replaceAll('now()',"TIMESTAMPTZ '2026-11-16 15:00:00+00'").replaceAll('current_date',"DATE '2026-11-16'"));
function bind(s,p){for(const [k,v] of Object.entries(p))s=s.replace(new RegExp(`(?<!:):${k}\\b`,'g'),typeof v==='string'?`'${v.replaceAll("'","''")}'`:String(v));return s;}
const params={days:7,include_internal:false,term:'',uf:'',stage:'all',event_id:'',offset:0};
const query=(p={})=>JSON.parse(sql(bind(report,{...params,...p})));
let started=false;
try{
 run('initdb',['-D',resolve(scratch,'data'),'-U','postgres','-A','trust','--no-locale']);
 run('pg_ctl',['-D',resolve(scratch,'data'),'-l',resolve(scratch,'postgres.log'),'-o',`-F -k ${scratch} -c listen_addresses=''`,'-w','start']);started=true;
 sql(`CREATE SCHEMA audience;
 CREATE TABLE audience.events(page_view_id text,event_key text,event_kind text,occurred_at timestamptz,received_at timestamptz DEFAULT now(),visitor_id text,session_id text,environment text DEFAULT 'prod',is_internal boolean DEFAULT false,site_host text DEFAULT 'roadrunners.run',page_family text DEFAULT 'event',content_type text DEFAULT 'event',content_id text,source text DEFAULT 'direct',medium text DEFAULT '(none)',campaign text DEFAULT '',referrer_host text DEFAULT '',device_class text DEFAULT 'MOBILE',visitor_uf text DEFAULT 'SP');
 CREATE TABLE public.tb_evento_corridas(id_evento integer,nome_evento text,tag text,cidade text,estado text,data_inicial date,data_final date,descricao text,imagem text,url_imagem text,url_inscricao text,ativo boolean DEFAULT true);
 CREATE TABLE public.tb_evento_corridas_percursos(id_evento integer);
 CREATE TABLE public.tb_evento_corridas_checkin(id_evento integer,id_usuario integer,tipo_checkin text,id_fornecedor integer);
 INSERT INTO tb_evento_corridas VALUES(1,'Prova <quente>','quente','Florianópolis','SC',current_date+10,current_date+10,'Descrição','','','','t'),(2,'Prova completa','completa','Rio Branco','AC',current_date+20,current_date+20,'Descrição','foto','','https://inscricao','t'),(3,'Prova passada','passada','São Paulo','SP',current_date-30,current_date-30,'Descrição','foto','','','t');
 INSERT INTO tb_evento_corridas_percursos VALUES(2);
 INSERT INTO audience.events(page_view_id,event_key,event_kind,occurred_at,visitor_id,session_id,content_id)
 SELECT 'p'||n,'page','page_view',((now() AT TIME ZONE 'America/Sao_Paulo')::date-1+time '12:00') AT TIME ZONE 'America/Sao_Paulo','v'||n,'s'||n,'1' FROM generate_series(1,12)n;
 INSERT INTO audience.events(page_view_id,event_key,event_kind,occurred_at,visitor_id,session_id,content_id)
 SELECT 'prev'||n,'page','page_view',((now() AT TIME ZONE 'America/Sao_Paulo')::date-3+time '12:00') AT TIME ZONE 'America/Sao_Paulo','v'||n,'s'||n,'1' FROM generate_series(1,6)n;
 INSERT INTO audience.events(page_view_id,event_key,event_kind,occurred_at,visitor_id,session_id,content_id)
 SELECT 'coverage'||n,'page','page_view',((now() AT TIME ZONE 'America/Sao_Paulo')::date-n+time '12:00') AT TIME ZONE 'America/Sao_Paulo','coverage','coverage','2' FROM generate_series(1,5)n;
 INSERT INTO audience.events SELECT page_view_id,'content','content_open',occurred_at,received_at,visitor_id,session_id,environment,is_internal,site_host,page_family,content_type,content_id,source,medium,campaign,referrer_host,device_class,visitor_uf FROM audience.events WHERE page_view_id='p1';
 INSERT INTO audience.events SELECT page_view_id,'duplicate','page_view',occurred_at,received_at,visitor_id,session_id,environment,is_internal,site_host,page_family,content_type,content_id,source,medium,campaign,referrer_host,device_class,visitor_uf FROM audience.events WHERE page_view_id='p1' AND event_key='page';
 INSERT INTO audience.events(page_view_id,event_key,event_kind,occurred_at,visitor_id,session_id,content_id,source) VALUES('missing','page','page_view',now(),'v1','s1','99999999999999999999999','openresults');
 INSERT INTO audience.events(page_view_id,event_key,event_kind,occurred_at,visitor_id,session_id,content_id,is_internal) VALUES('internal','page','page_view',now(),'internal','internal','1',true);
 INSERT INTO audience.events(page_view_id,event_key,event_kind,occurred_at,visitor_id,session_id,content_id,site_host) VALUES('otherhost','page','page_view',now(),'other','other','1','openresults.run');
 INSERT INTO audience.events(page_view_id,event_key,event_kind,occurred_at,visitor_id,session_id,content_id,environment) VALUES('dev','page','page_view',now(),'dev','dev','1','dev');
 INSERT INTO tb_evento_corridas_checkin VALUES(1,1,'calendario',NULL),(1,1,'inscricao',NULL),(1,2,'calendario',NULL),(1,3,'calendario',99),(1,4,'desconhecido',NULL),(2,1,'inscricao',NULL);`);
 let r=query();
 assert.equal(r.summary.flow_transitions,1,'navigation denominator counts the real filtered sequences');
 assert.equal(r.summary.pageviews,24);assert.equal(r.summary.visitors,13);assert.equal(r.summary.sessions,13);assert.equal(r.summary.events,3);
 assert.equal(r.ranking.find(e=>e.content_id==='1').pageviews,18);assert.equal(r.ranking.find(e=>e.content_id==='1').visitors,12);
 assert.equal(r.ranking.find(e=>e.content_id==='1').missing_fields.length,3);
 assert.equal(r.hot[0].content_id,'1');assert.equal(r.hot[0].growth_pct,null,'incomplete weekly history cannot produce a percentage');assert.equal(r.meta.comparison_ready,false);
 assert.equal(r.meta.trend_days,7);assert.equal(r.hot[0].recent_visitors,12);
 assert.equal(r.gaps[0].content_id,'1');assert.equal(r.sources.find(s=>s.source==='openresults').pageviews,1);
 assert.equal(query({include_internal:true}).summary.pageviews,25);
 assert.equal(query({uf:'SC'}).summary.pageviews,18);assert.equal(query({term:'Prova completa'}).summary.pageviews,5);
 assert.equal(query({term:"' OR true"}).summary.pageviews,0);
 assert.equal(query({event_id:'1'}).summary.pageviews,18);assert.equal(query({stage:'past'}).summary.pageviews,0);
 assert.equal(r.daily.reduce((s,d)=>s+d.pageviews,0),24);
 let a=JSON.parse(sql(bind(agenda,{ids:'["1","2","99999999999999999999999"]'})));
 assert.equal(a.find(e=>e.content_id==='1').athletes,2);assert.equal(a.find(e=>e.content_id==='1').saved,2);assert.equal(a.find(e=>e.content_id==='1').registered,1);
 sql(`DELETE FROM audience.events WHERE page_view_id='coverage5';`);
 assert.equal(query().meta.comparison_ready,false);assert.equal(query().hot.length,1,'observed highlights remain useful without comparable history');
 sql(`INSERT INTO audience.events(page_view_id,event_key,event_kind,occurred_at,visitor_id,session_id,content_id) SELECT 'bulk'||n,'page','page_view',now(),'bulk','bulk',n::text FROM generate_series(100,159)n;`);
 r=query();assert.equal(r.summary.pageviews,83);assert.equal(r.ranking.length,50);assert.equal(query({offset:50}).ranking.length,13);assert.equal(query({offset:50}).summary.pageviews,83,'pagination must not sample headline');
 // Separate trend fixture: tiny audiences, stable/decreasing/new interest, and
 // rows just outside the current week. The clock is fixed at noon in Brasília.
 sql(`TRUNCATE audience.events;
 INSERT INTO tb_evento_corridas(id_evento,nome_evento,cidade,estado,data_inicial,data_final,ativo)
 VALUES (4,'Inativa','Cidade','SC',current_date+10,current_date+10,false),
 (5,'Só no mês','Cidade','SC',current_date+10,current_date+10,true),
 (6,'Estável','Cidade','SC',current_date+10,current_date+10,true),
 (7,'Só dois','Cidade','SC',current_date+10,current_date+10,true),
 (8,'Novo interesse','Cidade','SC',current_date+10,current_date+10,true);
 INSERT INTO audience.events(page_view_id,event_key,event_kind,occurred_at,visitor_id,session_id,content_id)
 SELECT 'coverage-long'||n,'page','page_view',((now() AT TIME ZONE 'America/Sao_Paulo')::date-n+time '09:00') AT TIME ZONE 'America/Sao_Paulo','coverage','coverage','2' FROM generate_series(0,61)n;
 INSERT INTO audience.events(page_view_id,event_key,event_kind,occurred_at,visitor_id,session_id,content_id)
 SELECT 'trend-'||id||'-'||day||'-'||n,'page','page_view',((now() AT TIME ZONE 'America/Sao_Paulo')::date-day+time '09:00') AT TIME ZONE 'America/Sao_Paulo','trend-'||id||'-'||day||'-'||n,'trend-session-'||id||'-'||day||'-'||n,id::text
 FROM (VALUES(1,1,3),(1,8,4),(1,35,2),(3,1,20),(4,1,20),(5,10,6),(6,1,3),(6,8,3),(7,1,2),(8,1,3))v(id,day,qty) CROSS JOIN LATERAL generate_series(1,qty)n;`);
 r=query();assert.equal(r.meta.comparison_ready,true);assert.equal(r.meta.trend_days,7);
 assert.deepEqual(r.hot.map(e=>e.content_id),['1','6','8'],'three visitors qualify, even without growth; two, past and inactive do not');
 assert.equal(r.hot[0].growth_pct,-25,'declining interest remains a highlight');
 assert.equal(r.hot.find(e=>e.content_id==='6').growth_pct,0,'stable interest remains visible');
 assert.equal(r.hot.find(e=>e.content_id==='8').growth_pct,null,'zero prior audience is not an infinite percentage');
 assert.equal(r.summary.hot,3);assert.equal(query({uf:'AC'}).hot.length,0);
 const monthly=query({days:30});assert.equal(monthly.meta.trend_days,30);assert.equal(monthly.meta.comparison_ready,true);
 assert.deepEqual(monthly.hot.map(e=>e.content_id),['1','5','6','8'],'monthly visitors determine the order, with deterministic ties');
 assert.equal(monthly.hot[0].recent_visitors,7);assert.equal(monthly.hot[0].previous_visitors,2);assert.equal(monthly.hot[0].growth_pct,250);
 assert.equal(query({days:90}).meta.trend_days,30);assert.equal(query({days:1}).meta.trend_days,7);
 sql(`INSERT INTO audience.events(page_view_id,event_key,event_kind,occurred_at,visitor_id,session_id,content_id)
 SELECT 'boundary-'||n,'page','page_view',at::timestamptz,'boundary-'||n,'boundary-'||n,'1'
 FROM (VALUES(1,'2026-11-10 03:00:00+00'),(2,'2026-11-10 02:59:59+00'),
 (3,'2026-11-09 15:00:00+00'),(4,'2026-11-09 15:00:01+00'),
 (5,'2026-11-16 15:00:00+00'),(6,'2026-11-16 15:00:01+00'),
 (7,'2026-11-03 03:00:00+00'),(8,'2026-11-03 02:59:59+00'))v(n,at);`);
 const boundary=query({event_id:'1'}).hot[0];
 assert.equal(boundary.recent_visitors,5,'current range includes midnight start and now, not before start or future');
 assert.equal(boundary.previous_visitors,6,'prior range includes its own midnight and matched noon, not a second later');
 assert.equal(boundary.growth_pct,-16.7);
 sql(`DELETE FROM audience.events WHERE page_view_id LIKE 'boundary-%';`);
 sql(`DELETE FROM audience.events WHERE occurred_at < ((now() AT TIME ZONE 'America/Sao_Paulo')::date-10)::timestamp AT TIME ZONE 'America/Sao_Paulo';`);
 const partial=query({days:30});assert.equal(partial.meta.comparison_ready,false);assert.equal(partial.hot.length,4);
 assert.ok(partial.hot.every(e=>e.growth_pct===null),'partial month has volume but no fabricated growth');
 // Navigation denominator includes all matching pairs before the top-20 limit.
 sql(`TRUNCATE audience.events;
 INSERT INTO audience.events(page_view_id,event_key,event_kind,occurred_at,visitor_id,session_id,content_id)
 SELECT 'flow-source-'||n,'page','page_view',now()-interval '1 minute','fv'||n,'fs'||n,'1' FROM generate_series(100,129)n;
 INSERT INTO audience.events(page_view_id,event_key,event_kind,occurred_at,visitor_id,session_id,content_id)
 SELECT 'flow-dest-'||n,'page','page_view',now(),'fv'||n,'fs'||n,n::text FROM generate_series(100,129)n;`);
 const flows=query();
 assert.equal(flows.summary.flow_transitions,30);
 assert.equal(flows.flows.length,20);
 assert.equal(flows.flows.reduce((sum,row)=>sum+row.transitions,0),20);
 assert.equal(query({event_id:'100'}).summary.flow_transitions,1,'destination filter applies to navigation denominator');
 assert.equal(query({term:'nothing here'}).summary.flow_transitions,0);
 // Agenda must be driven by current saved relationships, not by audience IDs.
 // Hand-counted: five eligible events, nine pairs and seven distinct athletes.
 sql(`TRUNCATE audience.events,tb_evento_corridas,tb_evento_corridas_checkin,tb_evento_corridas_percursos;
 ALTER TABLE tb_evento_corridas ADD COLUMN status_evento text;
 INSERT INTO tb_evento_corridas(id_evento,nome_evento,tag,cidade,estado,data_inicial,data_final,ativo,descricao,imagem,url_inscricao,status_evento)
 SELECT id,name,'prova-'||id,'Cidade',uf,current_date+start_day,current_date+end_day,active,'Descrição','foto','https://inscricao',status
 FROM (VALUES(11,'Mais salva <quente>','SC',10,10,true,NULL::text),
 (12,'Uma agenda','AC',5,5,true,NULL),(13,'Passada','SC',-1,-1,true,NULL),
 (14,'Inativa','SC',10,10,false,NULL),(15,'Hoje','SC',0,0,true,NULL),
 (16,'Uma agenda depois','SC',10,10,true,NULL),(17,'Cancelada','SC',10,10,true,'cancelado'),
 (18,'Sem agenda','SC',10,10,true,NULL),(19,'Sem data','SC',NULL,NULL,true,NULL),
 (20,'Em andamento','SC',-1,1,true,NULL))v(id,name,uf,start_day,end_day,active,status);
 INSERT INTO tb_evento_corridas_percursos SELECT id_evento FROM tb_evento_corridas;
 UPDATE tb_evento_corridas SET imagem=NULL,descricao=NULL WHERE id_evento=11;
 INSERT INTO tb_evento_corridas_checkin VALUES
 (11,1,'calendario',NULL),(11,1,'inscricao',NULL),(11,2,'inscricao',NULL),(11,3,'calendario',NULL),(11,4,'inscricao',NULL),
 (11,5,'inscricao',99),(11,6,'desconhecido',NULL),(12,1,'calendario',NULL),
 (13,8,'inscricao',NULL),(14,8,'inscricao',NULL),(15,2,'inscricao',NULL),(15,5,'calendario',NULL),
 (16,6,'inscricao',NULL),(17,8,'inscricao',NULL),(19,8,'inscricao',NULL),(20,7,'inscricao',NULL),
 (999,8,'inscricao',NULL);
 INSERT INTO audience.events(page_view_id,event_key,event_kind,occurred_at,visitor_id,session_id,content_id)
 VALUES('a1','page','page_view',now(),'v1','s1','15'),('a1','duplicate','page_view',now(),'v1','s1','15'),
 ('a1','open','content_open',now(),'v1','s1','15'),('month','page','page_view',now()-interval '10 days','v2','s2','15'),
 ('future','page','page_view',now()+interval '1 second','v3','s3','15'),
 ('no-agenda','page','page_view',now(),'v1','s1','18');
 INSERT INTO audience.events(page_view_id,event_key,event_kind,occurred_at,visitor_id,session_id,content_id,is_internal)
 VALUES('ai','page','page_view',now(),'vi','si','15',true);
 INSERT INTO audience.events(page_view_id,event_key,event_kind,occurred_at,visitor_id,session_id,content_id,site_host)
 VALUES('ao','page','page_view',now(),'vo','so','15','openresults.run');
 INSERT INTO audience.events(page_view_id,event_key,event_kind,occurred_at,visitor_id,session_id,content_id,environment)
 VALUES('ad','page','page_view',now(),'vd','sd','15','dev');`);
 const agendaQuery=(p={})=>JSON.parse(sql(bind(agendaRanking,{...params,...p})));
 const ar=agendaQuery();
 assert.deepEqual(ar.ranking.map(e=>e.content_id),['11','15','20','12','16']);
 assert.deepEqual(ar.summary,{events:5,athletes:7,gaps:1});
 assert.equal(ar.ranking.reduce((s,e)=>s+e.athletes,0),9,'per-event athletes must not be used as the distinct headline');
 assert.equal(ar.ranking[0].athletes,4,'both saved statuses count once per athlete; providers and unknown statuses excluded');
 assert.equal(ar.ranking[0].pageviews,0,'most-saved event is eligible without any audience row');
 assert.equal(ar.ranking[0].visitors,0);assert.deepEqual(ar.ranking[0].missing_fields,['Descrição','Imagem']);
 assert.equal(ar.ranking[1].pageviews,1,'one opening, not its duplicate or content interaction');
 assert.equal(agendaQuery({days:30}).ranking[1].pageviews,2);
 assert.deepEqual(agendaQuery({days:30}).summary,ar.summary,'period only changes audience, not agenda stock');
 assert.equal(agendaQuery({include_internal:true}).ranking[1].pageviews,2);
 assert.deepEqual(agendaQuery({include_internal:true}).summary,ar.summary,'traffic filter must not relabel agenda as public-only');
 assert.deepEqual(agendaQuery({uf:'AC'}).summary,{events:1,athletes:1,gaps:0});
 assert.equal(agendaQuery({term:'mais salva'}).ranking[0].content_id,'11');
 assert.equal(agendaQuery({term:"' OR true"}).ranking.length,0);
 assert.deepEqual(agendaQuery({event_id:'15'}).summary,{events:1,athletes:2,gaps:0});
 assert.equal(agendaQuery({event_id:'999999999999999999999999'}).ranking.length,0);
 sql(`TRUNCATE audience.events;`);
 assert.deepEqual(agendaQuery().summary,ar.summary,'absence of audience cannot hide saved future events');
 assert.ok(agendaQuery().ranking.every(e=>e.pageviews===0&&e.visitors===0));
 sql(`INSERT INTO tb_evento_corridas(id_evento,nome_evento,data_inicial,data_final,ativo)
 SELECT n,'Agenda extra '||n,current_date+10,current_date+10,true FROM generate_series(100,159)n;
 INSERT INTO tb_evento_corridas_checkin SELECT n,n,'inscricao',NULL FROM generate_series(100,159)n;`);
 const ap=agendaQuery();const ap2=agendaQuery({offset:50});
 assert.equal(ap.summary.events,65);assert.equal(ap.summary.athletes,67);
 assert.equal(ap.ranking.length,50);assert.equal(ap2.ranking.length,15);
 assert.deepEqual(ap2.summary,ap.summary);assert.equal(new Set([...ap.ranking,...ap2.ranking].map(e=>e.content_id)).size,65);
 console.log('Event interest SQL: audience, pagination, agenda and weekly/monthly low-volume behavior passed with isolated PostgreSQL.');
}finally{if(started)run('pg_ctl',['-D',resolve(scratch,'data'),'-m','immediate','-w','stop']);rmSync(scratch,{recursive:true,force:true});}
