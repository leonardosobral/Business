from pathlib import Path
import json, shlex, subprocess
S=Path(__file__).resolve().parent
B=S.parents[2]
helpers=(B/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
sql="""SELECT coalesce(jsonb_agg(to_jsonb(t) ORDER BY id_evento),'[]'::jsonb)::text AS payload
FROM (SELECT id_evento,tag,nome_evento,cidade,estado,data_inicial::text,data_final::text,ativo
      FROM tb_evento_corridas
      WHERE lower(nome_evento) LIKE '%cores da amaz%' OR tag LIKE '%together-run%'
         OR tag LIKE '%corrida-da-virada%' OR tag LIKE '%corrida-e-caminhada-outub%') t"""
remote=helpers+"\np=json.load(sys.stdin);r=bridge(ROOT,'transaction {'+raw_query('SET TRANSACTION READ ONLY')+raw_query(p['sql'])+'report={events=deserializeJSON(q.payload[1])};}');print(json.dumps(r))\n"
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps({'sql':sql}),capture_output=True,text=True,timeout=115)
assert cp.returncode==0,cp.stderr[-2200:]
r=json.loads(cp.stdout);(S/'events.json').write_text(json.dumps(r,ensure_ascii=False,indent=2));print(json.dumps(r,ensure_ascii=False))
