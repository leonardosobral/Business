from pathlib import Path
import json,shlex,subprocess
root=Path('/Users/Shared/Projects/RunnerHub/Business');p=Path(__file__).resolve().parent
helpers=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql="SELECT jsonb_build_object('fields',(SELECT jsonb_agg(jsonb_build_object('name',column_name,'type',data_type) ORDER BY ordinal_position) FROM information_schema.columns WHERE table_schema='public' AND table_name='tb_evento_corridas'),'geography',(SELECT jsonb_object_agg(key,value) FROM tb_evento_corridas e CROSS JOIN LATERAL jsonb_each(to_jsonb(e)) WHERE id_evento=45651 AND key ~* '(cidade|estado|latitude|longitude|ibge|geo|bloque|tag|id_evento|data_inicial|data_final)'),'triggers',(SELECT jsonb_agg(pg_get_triggerdef(oid)) FROM pg_trigger WHERE tgrelid='public.tb_evento_corridas'::regclass AND NOT tgisinternal))::text payload"
remote=helpers+'\np=json.load(sys.stdin)\nr=bridge(ROOT,raw_query(p["sql"])+"report=deserializeJSON(q.payload[1]);")\nprint(json.dumps(r))'
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'sql':sql}),capture_output=True,text=True,timeout=100)
if cp.returncode:raise RuntimeError(cp.stderr[-2000:])
r=json.loads(cp.stdout);(p/'schema-geography.json').write_text(json.dumps(r,indent=2,ensure_ascii=False));print(json.dumps(r,ensure_ascii=False))
