from pathlib import Path
import json,hashlib,shlex,subprocess,sys
P=Path(__file__).resolve().parent;ROOT=P.parents[2];mode=sys.argv[1]
assert mode in ['prepare','rehearse','test_drift','publish','verify','rollback']
migration=(ROOT/'_codex/sql/2026-10-04_evento_fatos_historico.sql').read_text()
checks=json.loads((P/'test-candidate.json').read_text());assert len(checks)>=27 and all(x['passed'] for x in checks)
manifest={'sql':migration,'sha256':hashlib.sha256(migration.encode()).hexdigest()}
assert json.loads((P/'tested.json').read_text())['sha256']==manifest['sha256']
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
snapshot="""SELECT jsonb_build_object(
'source',jsonb_build_object(
 'tables',(SELECT jsonb_agg(jsonb_build_object('name',relname,'owner',pg_get_userbyid(relowner),'acl',relacl) ORDER BY relname) FROM pg_class WHERE oid IN ('public.tb_evento_corridas'::regclass,'public.tb_evento_corridas_percursos'::regclass)),
 'triggers',(SELECT jsonb_agg(jsonb_build_object('name',tgname,'table',tgrelid::regclass::text,'definition',pg_get_triggerdef(oid),'enabled',tgenabled,'body',pg_get_functiondef(tgfoid)) ORDER BY tgname) FROM pg_trigger WHERE NOT tgisinternal AND tgrelid IN ('public.tb_evento_corridas'::regclass,'public.tb_evento_corridas_percursos'::regclass) AND tgname NOT IN ('trg_evento_fatos_historico','trg_percurso_fatos_historico'))),
'new',jsonb_build_object(
 'table',(SELECT jsonb_build_object('name',relname,'owner',pg_get_userbyid(relowner),'acl',relacl) FROM pg_class WHERE oid=to_regclass('public.tb_evento_fatos_historico')),
 'sequence',(SELECT jsonb_build_object('name',relname,'owner',pg_get_userbyid(relowner),'acl',relacl) FROM pg_class WHERE oid=to_regclass('public.tb_evento_fatos_historico_id_historico_seq')),
 'columns',(SELECT jsonb_agg(jsonb_build_object('name',attname,'type',format_type(atttypid,atttypmod),'notnull',attnotnull,'identity',attidentity,'default',(SELECT pg_get_expr(adbin,adrelid) FROM pg_attrdef WHERE adrelid=attrelid AND adnum=attnum)) ORDER BY attnum) FROM pg_attribute WHERE attrelid=to_regclass('public.tb_evento_fatos_historico') AND attnum>0 AND NOT attisdropped),
 'constraints',(SELECT jsonb_agg(pg_get_constraintdef(oid) ORDER BY conname) FROM pg_constraint WHERE conrelid=to_regclass('public.tb_evento_fatos_historico')),
 'indexes',(SELECT jsonb_agg(indexdef ORDER BY indexname) FROM pg_indexes WHERE schemaname='public' AND tablename='tb_evento_fatos_historico'),
 'function',(SELECT jsonb_build_object('definition',pg_get_functiondef(oid),'owner',pg_get_userbyid(proowner),'acl',proacl,'definer',prosecdef,'config',proconfig) FROM pg_proc WHERE oid=to_regprocedure('public.registra_evento_fatos_historico()')),
 'triggers',(SELECT jsonb_agg(jsonb_build_object('definition',pg_get_triggerdef(oid),'enabled',tgenabled) ORDER BY tgname) FROM pg_trigger WHERE tgname IN ('trg_evento_fatos_historico','trg_percurso_fatos_historico') AND tgrelid IN ('public.tb_evento_corridas'::regclass,'public.tb_evento_corridas_percursos'::regclass))))::text payload"""
data_sql="""SELECT jsonb_build_object('events',(SELECT jsonb_build_object('count',count(*),'hash',md5(string_agg(md5(to_jsonb(e)::text),'' ORDER BY id_evento))) FROM public.tb_evento_corridas e),'routes',(SELECT jsonb_build_object('count',count(*),'hash',md5(string_agg(md5(to_jsonb(r)::text),'' ORDER BY id_evento_percurso))) FROM public.tb_evento_corridas_percursos r))::text payload"""
probe="""DO $probe$ DECLARE n bigint; old_final date; old_route date; seen boolean:=false; BEGIN
 SELECT count(*) INTO n FROM public.tb_evento_fatos_historico;
 SELECT data_final INTO STRICT old_final FROM public.tb_evento_corridas WHERE id_evento=37570;
 SELECT data_percurso INTO STRICT old_route FROM public.tb_evento_corridas_percursos WHERE id_evento_percurso=54298;
 BEGIN
  SET LOCAL ROLE runner;
  IF current_user <> 'runner' THEN RAISE EXCEPTION 'Writer role not active'; END IF;
  UPDATE public.tb_evento_corridas SET data_final=old_final+1 WHERE id_evento=37570;
  UPDATE public.tb_evento_corridas_percursos SET data_percurso=old_route+1 WHERE id_evento_percurso=54298;
  RESET ROLE;
  SELECT EXISTS(SELECT 1 FROM public.tb_evento_fatos_historico WHERE entidade='evento' AND id_evento=37570 AND operacao='UPDATE' AND alteracoes=jsonb_build_object('data_final',jsonb_build_object('antes',old_final,'depois',old_final+1))) INTO seen;
  IF NOT seen OR NOT EXISTS(SELECT 1 FROM public.tb_evento_fatos_historico WHERE entidade='percurso' AND id_entidade=54298 AND operacao='UPDATE' AND alteracoes=jsonb_build_object('data_percurso',jsonb_build_object('antes',old_route,'depois',old_route+1))) OR (SELECT count(*) FROM public.tb_evento_fatos_historico)<>n+2 THEN RAISE EXCEPTION 'Real trigger capture failed'; END IF;
  RAISE EXCEPTION 'Rollback real trigger probe' USING ERRCODE='P0002';
 EXCEPTION WHEN SQLSTATE 'P0002' THEN NULL; END;
 IF NOT seen OR (SELECT count(*) FROM public.tb_evento_fatos_historico)<>n OR (SELECT data_final FROM public.tb_evento_corridas WHERE id_evento=37570) IS DISTINCT FROM old_final OR (SELECT data_percurso FROM public.tb_evento_corridas_percursos WHERE id_evento_percurso=54298) IS DISTINCT FROM old_route OR current_user<>'runner_dba' THEN RAISE EXCEPTION 'Real probe rollback failed';END IF;
END;$probe$"""
acl_probe="""DO $acl$ BEGIN
 IF EXISTS(SELECT 1 FROM pg_class c CROSS JOIN LATERAL aclexplode(COALESCE(c.relacl,acldefault(CASE WHEN c.relkind='S' THEN  's'::"char" ELSE 'r'::"char" END,c.relowner))) a WHERE c.oid IN ('public.tb_evento_fatos_historico'::regclass,'public.tb_evento_fatos_historico_id_historico_seq'::regclass) AND a.grantee<>c.relowner) THEN RAISE EXCEPTION 'History has unexpected grants';END IF;
 IF has_table_privilege('runner','public.tb_evento_fatos_historico','SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER') OR has_sequence_privilege('runner','public.tb_evento_fatos_historico_id_historico_seq','USAGE,SELECT,UPDATE') OR has_function_privilege('runner','public.registra_evento_fatos_historico()','EXECUTE') THEN RAISE EXCEPTION 'Writer has direct history access';END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_proc p WHERE p.oid='public.registra_evento_fatos_historico()'::regprocedure AND pg_get_userbyid(proowner)='runner_dba' AND prosecdef AND proconfig=ARRAY['search_path=pg_catalog']) OR EXISTS(SELECT 1 FROM pg_proc p CROSS JOIN LATERAL aclexplode(COALESCE(p.proacl,acldefault('f',p.proowner))) a WHERE p.oid='public.registra_evento_fatos_historico()'::regprocedure AND a.grantee<>p.proowner) THEN RAISE EXCEPTION 'Unexpected history function permissions';END IF;
END;$acl$"""
reviewed=json.loads((P/'production-inspection.json').read_text())
reviewed_source={'tables':sorted([{k:v for k,v in t.items() if k!='rows_estimate'} for t in reviewed['tables']],key=lambda t:t['name']),'triggers':sorted([{k:v for k,v in t.items() if k!='function'} for t in reviewed['triggers']],key=lambda t:t['name'])}
stop_sql="""DROP TRIGGER trg_evento_fatos_historico ON public.tb_evento_corridas;
DROP TRIGGER trg_percurso_fatos_historico ON public.tb_evento_corridas_percursos;
DROP FUNCTION public.registra_evento_fatos_historico();"""
remote=helpers+'''
p=json.load(sys.stdin);stage=Path('/var/backups/seo-fact-change-log-20261004-v2');mode=p['mode']
def read():return bridge(ROOT,raw_query(p['snapshot'])+'report=deserializeJSON(q.payload[1]);')
def lit(v):return "'"+json.dumps(v,ensure_ascii=False).replace("'","''")+"'::jsonb"
def guard(expected):return "DO $guard$ BEGIN IF ("+p['snapshot']+")::jsonb IS DISTINCT FROM "+lit(expected)+" THEN RAISE EXCEPTION 'History schema drift';END IF;END;$guard$"
def execution(invert=False,bad=False,rollback=False,stop=False):
 before=json.loads((stage/('expected.json' if stop else 'baseline.json')).read_text())
 locks="SET LOCAL lock_timeout='3s'; SET LOCAL statement_timeout='45s'; SELECT pg_advisory_xact_lock(20261004,17); LOCK TABLE public.tb_evento_corridas,public.tb_evento_corridas_percursos IN SHARE ROW EXCLUSIVE MODE;"
 body='transaction {'+raw_query(locks,'locks')+raw_query(guard(before),'guard')+raw_query(p['data_sql'],'dataBefore')+'dataBefore=deserializeJSON(dataBefore.payload[1]);'
 body+=raw_query(p['stop'] if stop else p['manifest']['sql'],'migration')
 if not stop:body+=raw_query(p['acl_probe'],'acl')+raw_query(p['probe'],'probe')
 if invert:
  body+=raw_query("DO $empty$ BEGIN IF EXISTS(SELECT 1 FROM public.tb_evento_fatos_historico) THEN RAISE EXCEPTION 'History is not empty';END IF;END;$empty$;"+p['stop']+" DROP TABLE public.tb_evento_fatos_historico;",'inverse')
 body+=raw_query(p['snapshot'],'after')+'after=deserializeJSON(after.payload[1]);'
 body+=raw_query(p['data_sql'],'dataAfter')+'dataAfter=deserializeJSON(dataAfter.payload[1]);if(serializeJSON(dataBefore)!=serializeJSON(dataAfter))throw(message="Source rows changed");'
 if not stop and not invert and (stage/'expected.json').exists():body+=raw_query(guard(json.loads((stage/'expected.json').read_text())),'expected')
 if invert:body+=raw_query(guard(before),'inverseGuard')
 body+='report={metadata=after,dataBefore=dataBefore,dataAfter=dataAfter};'
 if bad:body+='throw(message="Intentional history rollback gate");'
 body+=('transaction action="rollback";' if rollback else '')+'}'
 return bridge(ROOT,body)
if mode=='prepare':
 current=read()
 if current['source']!=p['reviewed_source']:raise RuntimeError('Source changed since review')
 if any(x is not None for x in current['new'].values()):raise RuntimeError('History object already exists')
 stage.mkdir(mode=0o700,exist_ok=False);(stage/'baseline.json').write_text(json.dumps(current,indent=2));(stage/'manifest.json').write_text(json.dumps(p['manifest'],indent=2));(stage/'stop-capture.sql').write_text(p['stop'])
 result={'prepared':True,'backup':str(stage)}
else:
 if json.loads((stage/'manifest.json').read_text())!=p['manifest']:raise RuntimeError('Candidate drift')
 if mode=='rehearse':
  r=execution(rollback=True);expected=r['METADATA'];(stage/'expected.json').write_text(json.dumps(expected,indent=2))
  inverse=execution(invert=True,rollback=True)
  if read()!=json.loads((stage/'baseline.json').read_text()):raise RuntimeError('Rehearsal rollback failed')
  (stage/'rehearsed.json').write_text(json.dumps({'candidate':p['manifest']['sha256'],'real_trigger_probe':True,'writer_role_probe':True,'real_acl_assertions':True,'inverse':True,'source_rows_unchanged':True,'data':r['DATAAFTER']}))
  result={'rehearsed':True,'real_trigger_probe':True,'writer_role_probe':True,'real_acl_assertions':True,'inverse':True,'source_rows_unchanged':True}
 elif mode=='test_drift':
  try:execution(bad=True)
  except RuntimeError as e:
   if 'Intentional history rollback gate' not in str(e):raise
  else:raise RuntimeError('Rollback gate did not fire')
  if read()!=json.loads((stage/'baseline.json').read_text()):raise RuntimeError('Rollback gate left changes')
  (stage/'drift-tested.json').write_text(json.dumps({'candidate':p['manifest']['sha256'],'passed':True}));result={'rollback_gate':True}
 elif mode=='publish':
  r=json.loads((stage/'rehearsed.json').read_text());d=json.loads((stage/'drift-tested.json').read_text())
  if r['candidate']!=p['manifest']['sha256'] or not r['inverse'] or not r['real_trigger_probe'] or not r['writer_role_probe'] or not r['real_acl_assertions'] or not d['passed'] or d['candidate']!=r['candidate']:raise RuntimeError('Unverified candidate')
  result=execution();(stage/'published.json').write_text(json.dumps(result,indent=2));result={'published':True,'real_trigger_probe_rolled_back':True,'source_rows_unchanged':True,'backup':str(stage)}
 elif mode=='verify':
  bridge(ROOT,raw_query(p['acl_probe'])+'report={passed=true};')
  current=read();expected=json.loads((stage/'expected.json').read_text())
  if current!=expected:raise RuntimeError('Published schema mismatch')
  if current['source']!=json.loads((stage/'baseline.json').read_text())['source']:raise RuntimeError('Source metadata changed')
  if current['new']['table']['owner']!='runner_dba' or not current['new']['function']['definer']:raise RuntimeError('Unexpected ownership or execution mode')
  result={'verified':True,'source_metadata_unchanged':True,'definition':current['new']['function']['definition']}
 else:
  # Stop capture without deleting accumulated evidence.
  result=execution(stop=True);(stage/'stopped.json').write_text(json.dumps(result,indent=2));result={'capture_stopped':True,'history_preserved':True,'source_rows_unchanged':True}
print(json.dumps(result))
'''
payload={'mode':mode,'manifest':manifest,'snapshot':snapshot,'data_sql':data_sql,'probe':probe,'stop':stop_sql,'acl_probe':acl_probe,'reviewed_source':reviewed_source}
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=150)
if cp.returncode:raise RuntimeError(cp.stderr[-4500:])
r=json.loads(cp.stdout);(P/('release-'+mode+'.json')).write_text(json.dumps(r,indent=2))
if mode=='verify':(P/'published-definition.json').write_text(json.dumps({'definition':r['definition']}))
print(json.dumps({k:v for k,v in r.items() if k!='definition'}))
