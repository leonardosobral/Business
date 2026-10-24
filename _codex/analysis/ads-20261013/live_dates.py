from pathlib import Path
import json,subprocess,shlex,base64
p=Path(__file__).parent;root=p.parents[2]
helpers=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
s="""SELECT e.id_evento,e.nome_evento,e.cidade,e.estado,e.tag,e.data_inicial::date::text AS date,e.data_final::date::text AS end_date FROM public.tb_evento_corridas e WHERE e.nome_evento ILIKE '%LIVE%'  AND e.data_inicial >= DATE '2026-01-01' AND e.data_inicial < DATE '2027-01-01' ORDER BY e.data_inicial"""
body='transaction {queryExecute("SET TRANSACTION READ ONLY",{},{datasource="runnerhub"});q=queryExecute(toString(binaryDecode("'+base64.b64encode(s.encode()).decode()+'","base64")),{},{datasource="runnerhub",timeout=20});}report={rows=[]};for(r in q)arrayAppend(report.rows,r);'
remote=helpers+'\nprint(json.dumps(bridge(ROOT,'+repr(body)+')))'
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=90)
if r.returncode:raise SystemExit(r.stderr[-1500:])
p.joinpath('live-dates.json').write_text(r.stdout);print(r.stdout)
