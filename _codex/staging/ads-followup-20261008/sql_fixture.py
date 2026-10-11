from pathlib import Path
import re,json,subprocess,shlex,base64
p=Path(__file__).parent;root=p.parents[2]
s=(p/'candidate/Business/portal/audiencia/queries/advertiser_acquisition.sql').read_text()
fixture=re.search(r'const fixture=`(.*?)`;', (p/'report.test.mjs').read_text(), re.S).group(1)
fixture+=", ads_campaigns(campaign_id,name) AS (VALUES ('ad1','Race')), ads_events(delivery_id,campaign_id,event_type,valid,received_at) AS (VALUES ('d1','ad1','CLICK',true,now()),('d1','ad1','CLICK',true,now()),('d2','ad1','CLICK',false,now()),('d3','ad1','CLICK',true,now()-interval '15 days'),('d4','ad1','CLICK',true,now()),('d2','wrong','CLICK',true,now()))"
s=s.replace('/* AUDIENCE_FILTER */',fixture).replace(':days','7').replace('ads.events','ads_events').replace('ads.campaigns','ads_campaigns')
helpers=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
body='transaction {queryExecute("SET TRANSACTION READ ONLY",{},{datasource="runnerhub"});q=queryExecute(toString(binaryDecode("'+base64.b64encode(s.encode()).decode()+'","base64")),{},{datasource="runnerhub",timeout=15});}report={rows=[]};for(r in q)arrayAppend(report.rows,r);'
remote=helpers+'\nprint(json.dumps(bridge(ROOT,'+repr(body)+')))'
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=120)
if r.returncode:raise SystemExit(r.stderr[-2000:])
rows=json.loads(r.stdout)['ROWS'];v=next(r for r in rows if r['CAMPAIGN']=='test')
assert len(rows)==2
for k,n in [('RENDERED_DELIVERIES',2),('VIEWED_DELIVERIES',3),('VIEW_SESSIONS',2),('CLICKED_DELIVERIES',2),('VIEWED_CLICKED_DELIVERIES',1)]:assert v[k]==n,(k,v)
assert next(r for r in rows if r['CAMPAIGN']=='other')['VIEW_SESSIONS']==1
(p/'sql-tests.json').write_text(json.dumps({'checks_passed':7,'synthetic_CTEs_only':True,'production_writes':False}));print('7 SQL checks passed with synthetic CTEs; no DB writes')
