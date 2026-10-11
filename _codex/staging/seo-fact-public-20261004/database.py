from pathlib import Path
import json,shlex,subprocess,hashlib,sys
p=Path(__file__).resolve().parent;root=p.parents[2];mode=sys.argv[1]
helpers=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql=(root/'_codex/sql/2026-10-04_evento_fonte_datas_publica.sql').read_text()
meta="""SELECT jsonb_build_object('column',(SELECT jsonb_build_object('type',format_type(atttypid,atttypmod),'notnull',attnotnull,'default',(SELECT pg_get_expr(adbin,adrelid) FROM pg_attrdef WHERE adrelid=attrelid AND adnum=attnum),'comment',col_description(attrelid,attnum)) FROM pg_attribute WHERE attrelid='public.tb_evento_corridas'::regclass AND attname='conferencia_datas_publica' AND NOT attisdropped),'permissions',(SELECT jsonb_agg(jsonb_build_object('name',relname,'owner',relowner,'acl',relacl) ORDER BY relname) FROM pg_class WHERE oid IN ('public.tb_evento_corridas'::regclass,'public.tb_evento_fatos_revisao'::regclass,'public.tb_evento_fatos_historico'::regclass)),'triggers',(SELECT jsonb_agg(jsonb_build_object('name',tgname,'def',pg_get_triggerdef(oid),'function',pg_get_functiondef(tgfoid)) ORDER BY tgname) FROM pg_trigger WHERE tgrelid='public.tb_evento_corridas'::regclass AND NOT tgisinternal))::text payload"""
data="""SELECT jsonb_build_object('events',(SELECT md5(string_agg((to_jsonb(e)-'conferencia_datas_publica')::text,'' ORDER BY id_evento)) FROM public.tb_evento_corridas e),'reviews',(SELECT md5(coalesce(string_agg(to_jsonb(r)::text,'' ORDER BY id_revisao),'')) FROM public.tb_evento_fatos_revisao r),'history',(SELECT md5(coalesce(string_agg(to_jsonb(h)::text,'' ORDER BY id_historico),'')) FROM public.tb_evento_fatos_historico h))::text payload"""
remote=helpers+'''
p=json.load(sys.stdin);stage=Path('/var/backups/seo-fact-public-db-20261004');mode=p['mode']
def read():return bridge(ROOT,raw_query(p['meta'])+'report=deserializeJSON(q.payload);')
def execute(undo=False,commit=False):
 before=json.loads((stage/'before.json').read_text())
 guard="DO $g$ BEGIN IF ("+p['meta']+")::jsonb IS DISTINCT FROM '"+json.dumps(before).replace("'","''")+"'::jsonb THEN RAISE EXCEPTION 'Schema drift';END IF;END;$g$;"
 body='transaction {'+raw_query("SET LOCAL lock_timeout='3s';LOCK TABLE public.tb_evento_corridas IN ACCESS EXCLUSIVE MODE;"+guard,'gate')+raw_query(p['data'],'b')+'before=b.payload;'+raw_query(p['sql'],'ddl')
 if undo:body+=raw_query('ALTER TABLE public.tb_evento_corridas DROP COLUMN conferencia_datas_publica;','undo')
 body+=raw_query(p['data'],'a')+'if(before!=a.payload)throw(message="Existing data changed");'+raw_query(p['meta'],'m')+'report={metadata=deserializeJSON(m.payload),preserved=true};'
 if not commit:body+='transaction action="rollback";'
 return bridge(ROOT,body+'}')
if mode=='prepare':
 before=read()
 if before['column'] is not None:raise RuntimeError('Column already exists')
 stage.mkdir(mode=0o700,exist_ok=False);(stage/'before.json').write_text(json.dumps(before));(stage/'migration.sql').write_text(p['sql']);result={'backup':str(stage),'prepared':True}
else:
 if (stage/'migration.sql').read_text()!=p['sql']:raise RuntimeError('Migration changed')
 if mode=='rehearse':
  expected=execute()['METADATA'];assert execute(undo=True)['METADATA']==json.loads((stage/'before.json').read_text());assert read()==json.loads((stage/'before.json').read_text())
  assert expected['permissions']==read()['permissions'] and expected['triggers']==read()['triggers']
  (stage/'expected.json').write_text(json.dumps(expected));result={'rehearsed':True,'inverse_tested':True,'data_preserved':True,'permissions_triggers_preserved':True}
 elif mode=='publish':
  expected=json.loads((stage/'expected.json').read_text());r=execute(commit=True);assert r['METADATA']==expected;result={'published':True,'data_preserved':True}
 elif mode=='verify':
  assert read()==json.loads((stage/'expected.json').read_text());result={'verified':True,'permissions_triggers_preserved':True}
print(json.dumps(result))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(dict(mode=mode,sql=sql,meta=meta,data=data)),capture_output=True,text=True,timeout=110)
if cp.returncode:raise RuntimeError(cp.stderr[-3000:])
r=json.loads(cp.stdout);(p/('database-'+mode+'.json')).write_text(json.dumps(r,indent=2));print(json.dumps(r))
