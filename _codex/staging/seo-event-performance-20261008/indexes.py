from pathlib import Path
import json, shlex, subprocess
S=Path(__file__).resolve().parent;B=S.parents[2]
helpers=(B/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql="SELECT jsonb_build_object('version',current_setting('server_version_num'),'tables',(SELECT jsonb_agg(jsonb_build_object('table',relname,'estimated_rows',reltuples,'table_bytes',pg_relation_size(oid),'all_bytes',pg_total_relation_size(oid))) FROM pg_class WHERE oid IN ('public.tb_resultados'::regclass,'public.tb_paginas_usuarios'::regclass)),'indexes',(SELECT jsonb_agg(jsonb_build_object('table',tablename,'index',indexname,'definition',indexdef)) FROM pg_indexes WHERE schemaname='public' AND tablename IN ('tb_resultados','tb_paginas_usuarios')))::text AS payload"
code=helpers+'''\nprint(json.dumps(bridge(ROOT,'transaction {'+raw_query('SET TRANSACTION READ ONLY')+raw_query("'''+sql+'''")+'report=deserializeJSON(q.payload[1]);}')))\n'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
p=subprocess.run(ssh+['python3 -c '+shlex.quote(code)],capture_output=True,text=True,timeout=110)
if p.returncode:raise RuntimeError(p.stderr[-2000:])
r=json.loads(p.stdout);(S/'indexes.json').write_text(json.dumps(r,indent=2));print(json.dumps(r))
