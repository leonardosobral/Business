"""Render the actual admin includes in an isolated localhost-only application."""
from pathlib import Path
import base64, hashlib, json, shlex, subprocess, sys
from html import unescape
S=Path(__file__).resolve().parent
mode=sys.argv[1];assert mode in ('candidate','published')
names=['portal/includes/seo_search_evidence.cfm','portal/conteudo/seo_growth_baseline.cfm']
remote=r'''
from pathlib import Path
import base64,json,os,secrets,shutil,subprocess,sys,tempfile
p=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run')
work=Path(tempfile.mkdtemp(prefix='seo-gsc-verify-',dir=root/'_codex'));os.chmod(work,0o755);key=secrets.token_hex(24)
copies=['portal/conteudo/seo.cfm','portal/conteudo/seo_report.cfm','portal/conteudo/seo_ai.cfm','portal/conteudo/seo_ga4.cfm','portal/conteudo/seo_semrush.cfm','portal/conteudo/seo_growth_baseline.cfm','portal/includes/seo_score_backend.cfm','portal/includes/seo_queue_backend.cfm','portal/includes/seo_score_data.cfm','portal/includes/seo_queue_data.cfm','includes/backend/require_admin.cfm','portal/includes/seo_search_evidence.cfm','portal/includes/seo_semrush_data.cfm']
try:
 for n in copies:
  q=work/n;q.parent.mkdir(parents=True,exist_ok=True)
  if p['mode']=='candidate' and n in p['files']:q.write_text(p['files'][n])
  else:shutil.copyfile(root/n,q)
 (work/'.htaccess').write_text('Require local\n'.replace('\\n','\n'))
 (work/'Application.cfc').write_text('component{this.name="'+work.name+'";this.sessionManagement=true;boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(cgi.http_x_verify ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 auth='<cfset VARIABLES.qPerfil=queryNew("is_admin","bit",[{is_admin=true}])/>'
 cases={
  'technical':('URL.aba="relatorio";',True,'GET'),
  'technical-rr':('URL.aba="relatorio";URL.site="roadrunners";',True,'GET'),
  'technical-or':('URL.aba="relatorio";URL.site="openresults";',True,'GET'),
  'technical-warnings':('URL.aba="relatorio";URL.verificacao="warning";',True,'GET'),
  'google':('URL.aba="ga4";URL.site="roadrunners";',True,'GET'),
  'google-or':('URL.aba="ga4";URL.site="openresults";',True,'GET'),
  'semrush':('URL.aba="semrush";',True,'GET'),
  'denied-report':('URL.aba="relatorio";',False,'GET'),
  'denied-google':('URL.aba="ga4";',False,'GET'),
  'post-google':('URL.aba="ga4";',True,'POST'),
  'post-report':('URL.aba="relatorio";',True,'POST'),
 }
 for n,(setup,admin,method) in cases.items():
  (work/(n+'.cfm')).write_text('<cfsetting showdebugoutput="false"/><cfset setLocale("Portuguese (Brazilian)")/>'+auth+'<cfset VARIABLES.businessEffectiveIsAdmin='+str(admin).lower()+'/><cfscript>'+setup+'</cfscript><cfinclude template="portal/conteudo/seo.cfm"/>')
 for n,admin,method in [('denied-data',False,'GET'),('post-data',True,'POST')]:
  (work/(n+'.cfm')).write_text(auth+'<cfset VARIABLES.businessEffectiveIsAdmin='+str(admin).lower()+'/><cfinclude template="portal/includes/seo_search_evidence.cfm"/>');cases[n]=('',admin,method)
 for n,path in [('direct-data','portal/includes/seo_search_evidence.cfm'),('direct-growth','portal/conteudo/seo_growth_baseline.cfm')]:
  cases[n]=(path,True,'GET')
 results={}
 for n,(path,admin,method) in cases.items():
  route=path if n.startswith('direct-') else n+'.cfm'
  if n.startswith('direct-'):
   q=work/path;original=q.read_text();q.write_text(auth+'<cfset VARIABLES.businessEffectiveIsAdmin=true/>'+original)
  cp=subprocess.run(['curl','-sS','--max-time','45','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-Verify: '+key,'-X',method,'-w','\n%{http_code}'.replace('\\n','\n'),'https://business.roadrunners.run/_codex/'+work.name+'/'+route],capture_output=True,text=True,timeout=50)
  assert cp.returncode==0,'Request failed: '+n
  html,status=cp.stdout.rsplit('\n'.replace('\\n','\n'),1);results[n]={'status':int(status),'html':base64.b64encode(html.encode()).decode()}
  if n.startswith('direct-'):q.write_text(original)
 print(json.dumps(results))
finally:shutil.rmtree(work)
'''
payload={'mode':mode,'files':{n:(S/'candidate'/n).read_text() for n in names}}
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=230)
assert cp.returncode==0,cp.stderr[-3500:]
r=json.loads(cp.stdout);html={n:unescape(base64.b64decode(v['html']).decode()) for n,v in r.items()}
for n,item in r.items():
 expected=403 if n.startswith(('denied-','direct-')) else 405 if n.startswith('post-') else 200
 if item['status']!=expected or 'Error Occurred While Processing Request' in html[n]:
  (S/(mode+'-failed-'+n+'.html')).write_text(html[n]);raise AssertionError((n,item['status'],expected))
for n in ['technical','technical-rr','technical-warnings']:
 for text in ['107.352','21.335','116.687','22/10','28/10','926','391','incluindo subdomínios','Não há nota geral de SEO']:
  assert text in html[n],(n,text)
assert '34.319 URLs' in html['technical-or'] and '135.791 URLs' in html['technical-or']
for text in ['10.026','3.220','461.935','125.907','+211,4%','293 ms','2,5 s','1.317','1.490','Não mede tráfego direto','não comprova o impacto','316 cliques','26/09 a 23/10','ga4-app']:
 assert text in html['google'],text
assert 'seo-search-main-title' not in html['google-or'] and 'seo-regional-baseline-title' not in html['google-or']
assert '73%' in html['semrush'] and '8.388' in html['semrush']
for n in ['denied-google','denied-report','denied-data','direct-growth','direct-data','post-google','post-report','post-data']:
 assert '10.026' not in html[n] and '21.335' not in html[n],n
receipt={'mode':mode,'scenarios':len(r),'accessChecks':8,'hashes':{n:hashlib.sha256((S/'candidate'/n).read_bytes()).hexdigest() for n in names}}
(S/(mode+'-render-passed.json')).write_text(json.dumps(receipt,indent=2))
print(json.dumps(receipt,indent=2))
