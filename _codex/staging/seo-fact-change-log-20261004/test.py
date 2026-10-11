from pathlib import Path
import json,shlex,subprocess,hashlib
root=Path('/Users/Shared/Projects/RunnerHub/Business');p=Path(__file__).resolve().parent
helpers=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
import sys,time
mode=sys.argv[1];assert mode in ["candidate","published"]
migration_bytes=(root/'_codex/sql/2026-10-04_evento_fatos_historico.sql').read_bytes()
migration=migration_bytes.decode()
migration_sha=hashlib.sha256(migration_bytes).hexdigest()
if mode=='published':
 saved=json.loads((p/'published-definition.json').read_text())
 start=migration.index('CREATE FUNCTION public.registra_evento_fatos_historico()');end=migration.index('CREATE TRIGGER trg_evento_fatos_historico')
 migration=migration[:start]+saved['definition']+';\n'+migration[end:]
migration=migration.replace('CREATE TABLE public.tb_evento_fatos_historico','CREATE TEMP TABLE tb_evento_fatos_historico').replace('public.','pg_temp.').replace("TG_TABLE_SCHEMA <> 'public'","TG_TABLE_SCHEMA <> pg_my_temp_schema()::regnamespace::text")
sql=(p/'test.sql').read_text().replace('-- MIGRATION',migration)
remote=helpers+'\np=json.load(sys.stdin)\nbody=\'transaction {\'+raw_query(p[\'sql\'],\'tests\')+raw_query("SELECT jsonb_agg(jsonb_build_object(\'name\',name,\'passed\',passed) ORDER BY name)::text payload FROM pg_temp.checks",\'results\')+\'report={checks=deserializeJSON(results.payload[1])};transaction action="rollback";}\'\nr=bridge(ROOT,body)\nprint(json.dumps(r))\n'
started=time.monotonic()
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'sql':sql}),capture_output=True,text=True,timeout=90)
if cp.returncode:raise RuntimeError(cp.stderr[-4500:])
r=json.loads(cp.stdout)["CHECKS"];(p/('test-'+mode+'.json')).write_text(json.dumps(r,indent=2));failed=[x for x in r if not x['passed']];print(json.dumps({'checks':len(r),'failed':failed,'elapsed_seconds':round(time.monotonic()-started,2)}));assert not failed

if mode=="candidate":
 import hashlib
 (p/"tested.json").write_text(json.dumps({"sha256":migration_sha,"checks":len(r)}))
