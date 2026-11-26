from pathlib import Path
import subprocess,base64,json,sys
root=Path(__file__).resolve().parents[3]
helper=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
id='299a6236-7e69-43cd-b2b2-65c4b1288b04'
sql="SELECT jsonb_build_object('campaign',(SELECT to_jsonb(c) FROM ads.campaigns c WHERE campaign_id='"+id+"'),'metrics',(SELECT jsonb_agg(to_jsonb(m)) FROM ads.daily_metrics m WHERE campaign_id='"+id+"'),'ledger_count',(SELECT count(*) FROM ads.credit_ledger WHERE campaign_id='"+id+"'),'deliveries',(SELECT jsonb_agg(jsonb_build_object('id',delivery_id,'billing',billing_model,'price',price_snapshot,'served_at',served_at)) FROM ads.deliveries WHERE campaign_id='"+id+"'),'events',(SELECT jsonb_agg(to_jsonb(e)) FROM ads.events e WHERE campaign_id='"+id+"'))::text AS payload"
body='transaction {queryExecute("SET TRANSACTION READ ONLY",{}, {datasource="runnerhub"}); q=queryExecute(toString(binaryDecode("'+base64.b64encode(sql.encode()).decode()+'","base64")),{}, {datasource="runnerhub",timeout=15});}report=deserializeJSON(q.payload[1]);'
remote=helper+'\nprint(json.dumps(bridge(ROOT,'+repr(body)+')))'
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -'],input=remote,text=True,capture_output=True,check=True)
result=json.loads(r.stdout)
(Path(__file__).parent/('evidence-'+sys.argv[1]+'.json')).write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
