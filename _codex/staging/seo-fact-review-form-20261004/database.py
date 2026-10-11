from pathlib import Path
import json,hashlib,shlex,subprocess,sys,ast
p=Path(__file__).resolve().parent;root=p.parents[2];mode=sys.argv[1];assert mode in ['prepare','rehearse','publish','verify']
sql=(root/'_codex/sql/2026-10-04_evento_fatos_revisao.sql').read_text();sha=hashlib.sha256(sql.encode()).hexdigest();assert json.loads((p/'tested.json').read_text())['sql']==sha
helpers=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
prior=ast.parse((p.parent/'seo-fact-change-log-20261004/release.py').read_text());data_sql=next(ast.literal_eval(n.value) for n in prior.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='data_sql' for t in n.targets))
meta="""SELECT jsonb_build_object(
 'objects',(SELECT jsonb_agg(jsonb_build_object('name',relname,'owner',pg_get_userbyid(relowner),'acl',relacl) ORDER BY relname) FROM pg_class WHERE oid IN (to_regclass('public.tb_evento_fatos_revisao'),to_regclass('public.tb_evento_fatos_revisao_id_revisao_seq'))),
 'columns',(SELECT jsonb_agg(jsonb_build_object('name',attname,'type',format_type(atttypid,atttypmod),'notnull',attnotnull,'identity',attidentity,'default',(SELECT pg_get_expr(adbin,adrelid) FROM pg_attrdef WHERE adrelid=attrelid AND adnum=attnum)) ORDER BY attnum) FROM pg_attribute WHERE attrelid=to_regclass('public.tb_evento_fatos_revisao') AND attnum>0 AND NOT attisdropped),
 'constraints',(SELECT jsonb_agg(pg_get_constraintdef(oid) ORDER BY conname) FROM pg_constraint WHERE conrelid=to_regclass('public.tb_evento_fatos_revisao')),
 'indexes',(SELECT jsonb_agg(indexdef ORDER BY indexname) FROM pg_indexes WHERE schemaname='public' AND tablename='tb_evento_fatos_revisao'),
 'source_triggers',(SELECT jsonb_agg(jsonb_build_object('name',tgname,'definition',pg_get_triggerdef(oid),'body',pg_get_functiondef(tgfoid),'enabled',tgenabled) ORDER BY tgname) FROM pg_trigger WHERE NOT tgisinternal AND tgrelid IN ('public.tb_evento_corridas'::regclass,'public.tb_evento_corridas_percursos'::regclass)))::text payload"""
acl="""DO $acl$ BEGIN IF EXISTS(SELECT 1 FROM pg_class c CROSS JOIN LATERAL aclexplode(COALESCE(c.relacl,acldefault(CASE WHEN c.relkind='S' THEN 's'::"char" ELSE 'r'::"char" END,c.relowner))) a WHERE c.oid IN ('public.tb_evento_fatos_revisao'::regclass,'public.tb_evento_fatos_revisao_id_revisao_seq'::regclass) AND (a.grantee<>c.relowner OR pg_get_userbyid(c.relowner)<>'runner_dba')) OR has_table_privilege('runner','public.tb_evento_fatos_revisao','SELECT,INSERT,UPDATE,DELETE') OR has_sequence_privilege('runner','public.tb_evento_fatos_revisao_id_revisao_seq','USAGE,SELECT,UPDATE') THEN RAISE EXCEPTION 'Review table permissions incorrect';END IF; END;$acl$"""
remote=helpers+'''
p=json.load(sys.stdin);stage=Path('/var/backups/seo-fact-review-form-db-20261004');mode=p['mode']
def read():return bridge(ROOT,raw_query(p['meta'])+'report=deserializeJSON(q.payload[1]);')
def guard(expected):return "DO $g$ BEGIN IF ("+p['meta']+")::jsonb IS DISTINCT FROM '"+json.dumps(expected).replace("'","''")+"'::jsonb THEN RAISE EXCEPTION 'Review schema drift';END IF;END;$g$;"
def execute(rollback=False,inverse=False,bad=False):
 before=json.loads((stage/'baseline.json').read_text());body='transaction {'+raw_query("SET LOCAL lock_timeout='3s';SELECT pg_advisory_xact_lock(20261004,18);LOCK TABLE public.tb_evento_corridas,public.tb_evento_corridas_percursos IN SHARE ROW EXCLUSIVE MODE;"+guard(before),'guard')+raw_query(p['data_sql'],'beforeData')+'beforeData=beforeData.payload[1];'+raw_query(p['sql']+p['acl'],'migration')
 if inverse:body+=raw_query('DROP TABLE public.tb_evento_fatos_revisao;','inverse')+raw_query(guard(before),'guardInverse')
 elif (stage/'expected.json').exists():body+=raw_query(guard(json.loads((stage/'expected.json').read_text())),'guardAfter')
 body+=raw_query(p['meta'],'after')+raw_query(p['data_sql'],'afterData')+'if(compare(beforeData,afterData.payload[1])!=0)throw(message="Source rows changed");report={metadata=deserializeJSON(after.payload[1]),data=deserializeJSON(beforeData)};'
 if bad:body+='throw(message="Intentional review rollback gate");'
 if rollback:body+='transaction action="rollback";'
 return bridge(ROOT,body+'}')
if mode=='prepare':
 before=read()
 if any(before[k] is not None for k in ['objects','columns','constraints','indexes']):raise RuntimeError('Review schema already exists')
 stage.mkdir(mode=0o700,exist_ok=False);(stage/'baseline.json').write_text(json.dumps(before));(stage/'migration.sql').write_text(p['sql']);(stage/'manifest.json').write_text(json.dumps({'sha':p['sha']}));result={'prepared':True,'backup':str(stage)}
else:
 if json.loads((stage/'manifest.json').read_text())['sha']!=p['sha']:raise RuntimeError('Migration drift')
 if mode=='rehearse':
  r=execute(rollback=True);(stage/'expected.json').write_text(json.dumps(r['METADATA']));execute(rollback=True,inverse=True)
  try:execute(bad=True)
  except RuntimeError as e:
   if 'Intentional review rollback gate' not in str(e):raise
  else:raise RuntimeError('Rollback did not fail')
  if read()!=json.loads((stage/'baseline.json').read_text()):raise RuntimeError('Rollback left schema changes')
  (stage/'rehearsed.json').write_text(json.dumps({'sha':p['sha'],'source_data':r['DATA']}));result={'rehearsed':True,'inverse':True,'forced_rollback':True,'source_rows_unchanged':True}
 elif mode=='publish':
  if json.loads((stage/'rehearsed.json').read_text())['sha']!=p['sha']:raise RuntimeError('Not rehearsed')
  result=execute();(stage/'published.json').write_text(json.dumps(result));result={'published':True,'source_rows_unchanged':True,'backup':str(stage)}
 else:
  if read()!=json.loads((stage/'expected.json').read_text()):raise RuntimeError('Published schema mismatch')
  bridge(ROOT,raw_query(p['acl'])+'report={private=true};');result={'verified':True,'private_permissions':True,'existing_triggers_preserved':True}
print(json.dumps(result))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'mode':mode,'sql':sql,'sha':sha,'meta':meta,'acl':acl,'data_sql':data_sql}),capture_output=True,text=True,timeout=150)
if cp.returncode:raise RuntimeError(cp.stderr[-4000:])
r=json.loads(cp.stdout);(p/f'database-{mode}.json').write_text(json.dumps(r,indent=2));print(json.dumps(r))
