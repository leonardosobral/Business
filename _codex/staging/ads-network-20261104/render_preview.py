from pathlib import Path
import json,subprocess,shlex
stage=Path(__file__).resolve().parent;root=stage.parents[2]
helper=(root/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
view=(root/'portal/banners/sites/home.cfm').read_text().replace('<cfinclude template="backend.cfm"/>','')
functions=(root/'portal/banners/sites/backend.cfm').read_text().split('function inventoryText',1)[1].split("if(!structKeyExists(SESSION",1)[0]
functions='function inventoryText'+functions
helper=helper.replace("  (work/'run.cfm').write_text", "  (work/'fixture.cfm').write_text("+repr(view)+")\n  (work/'run.cfm').write_text")
body=functions+'''invReady=true;invCsrf='synthetic-preview';invError='';invEdit={};
invSites=[{site_id='00000000-0000-4000-8000-000000000001',site_key='site-demo',name='Site de demonstração',origins='https://example.test',status='ACTIVE',version=1}];
invSpots=[{spot_id='00000000-0000-4000-8000-000000000002',site_id=invSites[1].site_id,site_key='site-demo',site_name='Site de demonstração',site_status='ACTIVE',spot_key='lateral-home',name='Lateral da página inicial',page_key='home',region_code='SC',width=300,height=250,status='ACTIVE',version=1}];
report={pages={}};
for(invTab in ['sites','spots','install']) {savecontent variable='markup' {include 'fixture.cfm';} report.pages[invTab]=markup;}
'''
remote=helper+'\nr=bridge(Path("/var/www/business.roadrunners.run"),'+repr(body)+')\nprint(json.dumps(r))'
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=110,check=True)
a=json.loads(r.stdout);pages=a.get('PAGES',a.get('pages'))
if not pages:raise SystemExit(str(a)[:1800])
out=stage/'preview';out.mkdir(exist_ok=True)
for name,markup in pages.items():
 links=''.join('<link rel="stylesheet" href="https://business.roadrunners.run/assets/css/'+c+'">' for c in ['mdb.min.css','style.css','cores_admin.css','business-ui.css'])
 html='<!doctype html><html lang="pt-br"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'+links+'<body data-mdb-theme="dark" class="bg-dark-subtle"><main style="max-width:1250px;margin:20px auto;padding:16px">'+markup.replace('href="/assets/','href="https://business.roadrunners.run/assets/')+'</main></body></html>'
 (out/(name.lower()+'.html')).write_text(html)
print('Rendered synthetic forms:',list(pages))
