from pathlib import Path
import json,subprocess,shlex
S=Path(__file__).resolve().parent;B=S.parents[2]
helpers=(B/'_codex/scripts/deploy_estudo.py').read_text().split('def raw_query(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
body='transaction {cfquery(name="readOnly",datasource="runnerhub",timeout=10){writeOutput("SET TRANSACTION READ ONLY");}cfquery(name="images",datasource="runnerhub",timeout=10){writeOutput("SELECT evt.id_evento,evt.nome_evento,eve.url_imagem,eve.url_imagem_listagem FROM vw_evento_corridas evt INNER JOIN tb_evento_corridas eve ON eve.id_evento=evt.id_evento WHERE evt.id_evento IN (39399,43657) ORDER BY evt.id_evento");}report={rows=[]};for(i=1;i<=images.recordCount;i++){arrayAppend(report.rows,{id=images.id_evento[i],name=images.nome_evento[i],image=images.url_imagem[i],listingImage=images.url_imagem_listagem[i]});}}'
code=helpers+'\np=json.load(sys.stdin)\nprint(json.dumps(bridge(ROOT,p["body"])))'
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(code)],input=json.dumps({'body':body}),capture_output=True,text=True,timeout=110);assert cp.returncode==0,cp.stderr[-1800:]
r=json.loads(cp.stdout);(S/'image-variants.json').write_text(json.dumps(r,ensure_ascii=False,indent=2));print(json.dumps(r,ensure_ascii=False,indent=2))
