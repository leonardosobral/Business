"""Adobe render and access checks, using a temporary localhost-only fixture."""
from pathlib import Path
import base64,hashlib,json,shlex,subprocess,sys
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business');STAGE=Path(__file__).resolve().parent
mode=sys.argv[1];assert mode in ('candidate','published')
NAMES=['portal/includes/seo_queue_data.cfm']
remote='''from pathlib import Path
import base64,hashlib,json,os,secrets,shutil,subprocess,sys,tempfile
p=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run')
work=Path(tempfile.mkdtemp(prefix='seo-semrush-verify-',dir=root/'_codex'));os.chmod(work,0o755);key=secrets.token_hex(24)
names=['portal/conteudo/seo.cfm','portal/conteudo/seo_report.cfm','portal/conteudo/seo_ai.cfm','portal/includes/seo_score_backend.cfm','portal/includes/seo_queue_backend.cfm','portal/includes/seo_score_data.cfm','portal/includes/seo_queue_data.cfm','includes/backend/require_admin.cfm','portal/includes/seo_search_evidence.cfm','portal/includes/seo_semrush_data.cfm','portal/conteudo/seo_semrush.cfm']
try:
 for name in names:
  dest=work/name;dest.parent.mkdir(parents=True,exist_ok=True)
  if p['mode']=='candidate' and name in p['files']:dest.write_text(p['files'][name])
  else:shutil.copyfile(root/name,dest)
 (work/'.htaccess').write_text('Require local\\n')
 (work/'Application.cfc').write_text('component {this.name="'+work.name+'";this.sessionManagement=false;boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(cgi.http_x_seo_verify ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 auth='<cfset VARIABLES.qPerfil=queryNew("is_admin","bit",[{is_admin=true}])/><cfset VARIABLES.businessEffectiveIsAdmin=true/>'
 cases={'opportunities':'URL.aba="semrush";', 'keywords':'URL.aba="semrush";URL.secao="palavras";', 'competitors':'URL.aba="semrush";URL.secao="concorrentes";', 'empty':'URL.aba="semrush";URL.secao="palavras";URL.busca="zzzz_no_match_123";', 'search':'URL.aba="semrush";URL.secao="palavras";URL.busca="corrida em sp";', 'escaped':'URL.aba="semrush";URL.secao="palavras";URL.busca="<script>alert(1)</script>";', 'openresults':'URL.aba="semrush";URL.site="openresults";', 'technical':'URL.aba="relatorio";', 'queue':'URL.aba="fila";', 'ai':'URL.aba="ia";', 'invalid':'URL.aba="<script>";'}
 for name,setup in cases.items():
  (work/(name+'.cfm')).write_text('<cfsetting showdebugoutput="false"/><cfset setLocale("Portuguese (Brazilian)")/>'+auth+'<cfscript>'+setup+'</cfscript><cfinclude template="portal/conteudo/seo.cfm"/>')
 for n in ['view','data']:
  path='portal/conteudo/seo_semrush.cfm' if n=='view' else 'portal/includes/seo_semrush_data.cfm'
  (work/('anonymous-'+n+'.cfm')).write_text('<cfinclude template="'+path+'"/>')
  (work/('delegated-'+n+'.cfm')).write_text(auth+'<cfset VARIABLES.businessEffectiveIsAdmin=false/><cfinclude template="'+path+'"/>')
  (work/('post-'+n+'.cfm')).write_text(auth+'<cfinclude template="'+path+'"/>')
  # Direct templates still execute the real guard, with fixture admin data only.
  q=work/path;q.write_text(auth+q.read_text())
 result={}
 for name in list(cases)+['anonymous-view','anonymous-data','delegated-view','delegated-data','post-view','post-data','portal/conteudo/seo_semrush','portal/includes/seo_semrush_data']:
  # Remove injected auth from copies while checking denied includes.
  for path in ['portal/conteudo/seo_semrush.cfm','portal/includes/seo_semrush_data.cfm']:
   q=work/path;s=q.read_text()
   if s.startswith(auth):q.write_text(s[len(auth):])
  if name.startswith('portal/'):
   q=work/(name+'.cfm');q.write_text(auth+q.read_text())
  method='POST' if name.startswith('post-') else 'GET'
  cp=subprocess.run(['curl','-sS','--max-time','45','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-SEO-Verify: '+key,'-X',method,'-w','\\n%{http_code}','https://business.roadrunners.run/_codex/'+work.name+'/'+name+'.cfm'],capture_output=True,text=True,timeout=50)
  if cp.returncode:raise RuntimeError('Request failed: '+name)
  html,status=cp.stdout.rsplit('\\n',1)
  result[name]={'status':int(status),'html':base64.b64encode(html.encode()).decode()}
 print(json.dumps(result))
finally:shutil.rmtree(work)
'''
payload={'mode':mode,'files':{n:(STAGE/'candidate/business'/n).read_text() for n in NAMES}}
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=230)
if cp.returncode:raise RuntimeError(cp.stderr[-5000:])
r=json.loads(cp.stdout);rendered={n:base64.b64decode(v['html']).decode() for n,v in r.items()}
import html
for n in ['opportunities','keywords','competitors','empty','search','escaped','openresults','technical','queue','ai','invalid']:
 assert r[n]['status']==200 and 'Error Occurred While Processing Request' not in rendered[n],n
h=html.unescape(rendered['opportunities']);q=html.unescape(rendered['queue']);receipt=json.loads((STAGE/'import-receipt.json').read_text())
for value in ['39 ocorrências de erro','35.227 avisos','5.846 observações','75%','78%','08/10/2026, 20:20 (Brasília)','2.088','27.591','51','993','1.234','26661911','interface autenticada do Semrush no Chrome','24,0%']:assert value in h,value
assert 'data-semrush-audit="complete"' in h and h.count('id="SR-')==6
assert 'Os números acima continuam os da conclusão de 06/10' not in h
for id in ['RR-28','RR-29','RR-30','RR-31','RR-32','RR-33','RR-34','RR-35','RR-36','RR-37','RR-38','RR-39']:assert 'id="'+id+'"' in q,id
assert receipt['queue_updatedLabel'] in q
assert 'Heroku' in q and 'Nenhum nome, data, tag' in q
assert 'Otimizar a consulta das edições anteriores' in q and 'A nota permanece 75%' in q
assert 'SR-01' not in rendered['openresults'] and 'Nenhuma coleta do Open Results' in rendered['openresults']
assert '1 de 51' in rendered['search'] and '0 de 51' in rendered['empty']
assert '<script>alert(1)</script>' not in rendered['escaped']
assert 'corridasbr.com.br' in rendered['competitors'] and 'Não há nota geral de SEO' in rendered['technical']
for n in ['anonymous-view','anonymous-data','delegated-view','delegated-data']:
 assert 'Acesso restrito' in rendered[n] and 'SR-01' not in rendered[n] and '993' not in rendered[n],n
for n in ['post-view','post-data']:assert r[n]['status']==405,n
for n in ['portal/conteudo/seo_semrush','portal/includes/seo_semrush_data']:assert r[n]['status']==403,n
out=STAGE/'preview';out.mkdir(exist_ok=True)
for n in ['opportunities','queue']:(out/(n+'.html')).write_text(rendered[n])
receipt={'hashes':{n:hashlib.sha256((STAGE/'candidate/business'/n).read_bytes()).hexdigest() for n in NAMES},'scenarios':len(r),'mode':mode}
(STAGE/(mode+'-render-passed.json')).write_text(json.dumps(receipt,indent=2))
print(json.dumps({'mode':mode,'scenarios_passed':len(r),'keywords':51,'opportunities':6,'access_checks':8}))
