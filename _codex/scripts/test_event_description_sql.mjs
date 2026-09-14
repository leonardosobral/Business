// Execute the endpoint's actual SQL against a new, socket-only PostgreSQL cluster.
import assert from 'node:assert/strict';
import {mkdtempSync,readFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
const scratch=mkdtempSync(resolve(tmpdir(),'event-description-sql-'));
const bin='/opt/homebrew/opt/postgresql@16/bin';
const run=(name,args,input)=>{
  const r=spawnSync(resolve(bin,name),args,{input,encoding:'utf8',timeout:30000,
    env:{PATH:process.env.PATH,LC_ALL:'C',TMPDIR:tmpdir()}});
  assert.equal(r.status,0,`${name}: ${r.stdout}${r.stderr}`); return r.stdout.trim();
};
const sql=input=>run('psql',['-X','-qAt','-v','ON_ERROR_STOP=1','-h',scratch,'-U','postgres','-d','postgres'],input);
const quote=v=>`'${String(v).replaceAll("'","''")}'`;
const source=readFileSync(resolve(root,'api/eventos/jobs/rewrite-descriptions.cfm'),'utf8');
const queueSource=readFileSync(resolve(root,'api/eventos/jobs/queue.cfm'),'utf8');
const queries=[...source.matchAll(/queryExecute\("([\s\S]*?)"\s*,/g)].map(m=>m[1]);
const pick=part=>{const q=queries.find(q=>q.includes(part));assert.ok(q,part);return q;};
const bind=(q,values)=>q.replace(/:([a-z_]+)/g,(_,name)=>{assert.ok(name in values,`Missing ${name}`);return values[name];});
const queueSql=queueSource.match(/return "([\s\S]*?)";/)[1];
const select=queueSql+"SELECT * FROM work WHERE queue_status='ready' ORDER BY date_rank,id_evento,language_rank LIMIT 1";
const update=pick('UPDATE public.tb_evento_corridas SET descricao =');
const original='Corrida de 5km, largada às 07:00 na Praça Central. '.repeat(6);
let started=false;
try {
  run('initdb',['-D',resolve(scratch,'data'),'-U','postgres','-A','trust','--no-locale','--encoding=UTF8']);
  run('pg_ctl',['-D',resolve(scratch,'data'),'-l',resolve(scratch,'postgres.log'),'-o',`-F -k ${scratch} -c listen_addresses=''`,'-w','start']); started=true;
  sql(`CREATE TABLE public.tb_evento_corridas(id_evento integer PRIMARY KEY,descricao_original text,descricao text,categorias text,data_inicial date,data_final date);
    CREATE TABLE public.tb_usuarios(id bigint PRIMARY KEY);`);
  sql(readFileSync(resolve(root,'administracao/cron-jobs/cron_jobs_schema.sql'),'utf8'));
  const schema=readFileSync(resolve(root,'api/eventos/jobs/schema.sql'),'utf8'); sql(schema);sql(schema);
  const job=readFileSync(resolve(root,'administracao/cron-jobs/event_description_rewrite_job.sql'),'utf8');sql(job);sql(job);
  assert.equal(sql('SELECT count(*) FROM public.tb_cron_jobs'),'1');
  assert.equal(sql('SELECT ativo FROM public.tb_cron_jobs'),'f');
  sql("UPDATE public.tb_cron_jobs SET ativo=true,interval_minutes=7");sql(job);
  assert.equal(sql('SELECT ativo::text||\',\'||interval_minutes FROM public.tb_cron_jobs'),'true,7');
  sql(`INSERT INTO public.tb_evento_corridas (id_evento,descricao_original,descricao,categorias,data_inicial,data_final) VALUES
    (1,${quote(original)},NULL,'5km',current_date+1,current_date+1),
    (2,${quote(original)},'Texto manual','5km',current_date+1,current_date+1),
    (3,${quote(original)},'','5km',current_date-1,current_date-1);`);
  assert.match(sql(bind(select,{event_id:0,language:quote('pt-BR')})),/^1\|/);
  const write=values=>sql(bind(update,{event_id:1,source_text:quote(original),description:quote('Texto validado 5km às 07:00.'),...values}));
  assert.equal(write({event_id:2}),'','Manual description must never be overwritten');
  assert.equal(write({source_text:quote(original+'alterado')}),'','Changed source must not be published');
  assert.equal(write({}),'1');
  assert.equal(write({}),'','Retry must be idempotent');
  assert.equal(sql('SELECT descricao_original FROM public.tb_evento_corridas WHERE id_evento=1'),original.trim());
  assert.equal(sql('SELECT categorias FROM public.tb_evento_corridas WHERE id_evento=1'),'5km');
  sql(`INSERT INTO public.tb_evento_descricao_rewrites(id_evento,source_hash,source_text,status,model)
    VALUES(3,md5(${quote(original)}),${quote(original)},'rejected','fixture');`);
  assert.equal(sql(bind(select,{event_id:0,language:quote('pt-BR')})),'','A rejected source must not consume the next scheduled call');
  sql(`UPDATE public.tb_evento_corridas SET descricao_original=descricao_original||' Nova informação.' WHERE id_evento=3`);
  assert.match(sql(bind(select,{event_id:0,language:quote('pt-BR')})),/^3\|/,'A new source version becomes eligible');
  assert.equal(sql("SELECT count(*) FROM information_schema.columns WHERE table_name='tb_evento_corridas' AND column_name IN ('descricao_en','descricao_es') AND data_type='text'"),'2');
  assert.equal(sql("SELECT count(*) FROM information_schema.columns WHERE table_name='tb_evento_corridas' AND column_name='descricao_traducoes_meta' AND data_type='jsonb'"),'1');
  assert.equal(sql("SELECT count(*) FROM information_schema.columns WHERE table_name='tb_evento_descricao_translations' AND column_name='metadata_before' AND data_type='jsonb'"),'1');
  assert.match(sql(bind(select,{event_id:1,language:quote('en')})),/^1\|/,'Existing Portuguese text is eligible for English');
  assert.equal(sql(bind(queueSql+"SELECT count(*) FROM work WHERE language='en' AND queue_status='ready'",{event_id:0,language:quote('auto')})),'2','Queue counters use the same translation eligibility');
  sql("UPDATE public.tb_evento_corridas SET descricao_en='Manual English' WHERE id_evento=1");
  assert.equal(sql(bind(select,{event_id:1,language:quote('en')})),'','Nonempty translation without cron ownership is preserved');
  assert.match(sql(bind(select,{event_id:1,language:quote('es')})),/^1\|/,'Manual English does not block missing Spanish');
  console.log('PASS: schema/registration idempotence, preserved activation, PT/EN/ES eligibility and shared counters, manual-edit/source guards, unchanged original/categories, retry exclusion and new-source eligibility.');
} finally {
  if(started)run('pg_ctl',['-D',resolve(scratch,'data'),'-m','fast','-w','stop']);
  console.log(`Disposable cluster stopped: ${scratch}`);
}
