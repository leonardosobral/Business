from pathlib import Path
import hashlib,json,shlex,subprocess
P=Path(__file__).resolve().parent
rrnames=['includes/estrutura/event_title_date.cfm','includes/card_evento_individual.cfm','includes/estrutura/header_tema.cfm','services/EventRedirectService.cfc','includes/estrutura/head.cfm','evento/index.cfm','includes/estrutura/event_redirect.cfm']
rr={n:hashlib.sha256((P/('redirect-candidate' if n=='includes/estrutura/event_redirect.cfm' else 'canonical-candidate' if n in ['services/EventRedirectService.cfc','includes/estrutura/head.cfm','evento/index.cfm'] else 'candidate/rr')/n).read_bytes()).hexdigest() for n in rrnames}
business={n:hashlib.sha256((P/'candidate/business'/n).read_bytes()).hexdigest() for n in ['portal/includes/seo_semrush_data.cfm','portal/includes/seo_queue_data.cfm','portal/conteudo/seo_semrush.cfm']}
remote='''from pathlib import Path
import hashlib,json,sys
p=json.load(sys.stdin);r=Path('/var/www/roadrunners.com.br');b=Path('/var/www/business.roadrunners.run')
for root,group in [(r,'rr'),(b,'business')]:
 for n,h in p[group].items():assert hashlib.sha256((root/n).read_bytes()).hexdigest()==h,n
 watch=json.loads(Path('/var/backups/seo-semrush-5000-20261005-'+group+'/watch.json').read_text())
 if group=='rr':watch.pop('evento/index.cfm')
 for n,h in watch.items():assert hashlib.sha256((root/n).read_bytes()).hexdigest()==h,n
print(json.dumps({'roadrunners_runtime':7,'business_runtime':3,'preserved_dependencies':13}))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'rr':rr,'business':business}),capture_output=True,text=True,timeout=25);assert cp.returncode==0,cp.stderr[-2000:]
(P/'final-runtime-verified.json').write_text(cp.stdout);print(cp.stdout)
