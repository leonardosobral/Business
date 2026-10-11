"""Adobe render and access checks, using a temporary localhost-only fixture."""
from pathlib import Path
import base64,hashlib,json,shlex,subprocess,sys
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business');STAGE=Path(__file__).resolve().parent
mode=sys.argv[1];assert mode in ('candidate','published')
NAMES=['portal/includes/seo_queue_data.cfm','portal/conteudo/seo_semrush.cfm','portal/includes/seo_semrush_data.cfm']
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
r=json.loads(cp.stdout); rendered={n:base64.b64decode(v['html']).decode() for n,v in r.items()}
for n in ['opportunities','keywords','competitors','empty','search','escaped','openresults','technical','queue','ai','invalid']:
 assert r[n]['status']==200,(n,r[n]['status'],rendered[n][:2000])
 assert 'Error Occurred While Processing Request' not in rendered[n],n
h=rendered['opportunities']
assert 'Semrush · Road Runners' in h and '993' in h and '1.234' in h
assert h.count('id="SR-')==6
assert 'data-semrush-audit="complete"' in h
assert '5.000 páginas rastreadas' in h and '126 ocorrências de erro' in h
assert '37.581 avisos' in h and '3.455 observações' in h
assert 'Site Health Semrush · amostra técnica' in h and '69%' in h and '81%' in h
assert '26.249' in h and '6.394' in h and '69,8%' in h
assert '05/10/2026, 01:37 (Brasília)' in __import__('html').unescape(h)
assert '04/10/2026, 14:15 (Brasília)' in __import__('html').unescape(h), 'Organic collection date changed'
assert '6ac31bf647d73ceec1b0b861' in h
assert 'sem renderização JavaScript' in h and 'rastreador móvel' in h
assert 'Os nove erros restantes' not in h
assert 'id="RR-28"' in rendered['queue']
assert 'id="RR-29"' in rendered['queue']
assert 'Revisão por URL em 05/10' in rendered['opportunities']
assert 'Páginas com títulos duplicados' in __import__('html').unescape(rendered['opportunities'])
assert '62 grupos de títulos duplicados' not in rendered['opportunities']
assert 'Tratar os achados da auditoria Semrush de 5.000 páginas' in __import__('html').unescape(rendered['queue'])
assert 'Resolver os nove erros restantes' not in __import__('html').unescape(rendered['queue'])
assert '/portal/seo/?aba=fila&amp;site=roadrunners#RR-28' in h
assert '9 ocorrências de erro' not in h
assert 'Não há nota geral de SEO' in rendered['technical']
assert 'RR-30' in rendered['queue'] and 'cidade' in rendered['queue']
assert 'RR-30' in rendered['opportunities'] and '62 endereços' in rendered['opportunities']
assert 'SR-01' not in rendered['openresults'] and 'Nenhuma coleta do Open Results' in rendered['openresults']
assert 'corrida em sp' in rendered['search'] and '1 de 51' in rendered['search']
assert '0 de 51' in rendered['empty']
assert '<script>alert(1)</script>' not in rendered['escaped']
assert '&lt;script&gt;' in rendered['escaped'] or '&##x3c;' in rendered['escaped'] or '&##x3c;script' in rendered['escaped'] or '&##60;' in rendered['escaped'] or '&##x3C;' in rendered['escaped'] or '&##X3C;' in rendered['escaped'] or '&#x3c;' in rendered['escaped'] or '&#x3C;' in rendered['escaped']
assert 'corridasbr.com.br' in rendered['competitors']
assert 'Primeiras oportunidades de melhoria' not in rendered['invalid']
for n in ['anonymous-view','anonymous-data','delegated-view','delegated-data']:
 assert 'Acesso restrito' in rendered[n],n
 assert 'SR-01' not in rendered[n] and '993' not in rendered[n],n
for n in ['post-view','post-data']:assert r[n]['status']==405,(n,r[n]['status'])
for n in ['portal/conteudo/seo_semrush','portal/includes/seo_semrush_data']:assert r[n]['status']==403,(n,r[n]['status'])
out=STAGE/'preview';out.mkdir(exist_ok=True)
for n in ['opportunities','keywords','competitors','search','empty','openresults']:
 (out/(n+'.html')).write_text('<!doctype html><html lang="pt-br"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>SEO · Semrush</title><link rel="stylesheet" href="/assets/css/mdb.min.css"><link rel="stylesheet" href="/assets/css/business-ui.css"></head><body data-mdb-theme="dark" class="bg-dark-subtle"><main class="container-fluid px-4 py-4">'+rendered[n]+'</main></body></html>')
receipt={'hashes':{n:hashlib.sha256((STAGE/'candidate/business'/n).read_bytes()).hexdigest() for n in NAMES},'scenarios':len(r),'mode':mode}
(STAGE/(mode+'-render-passed.json')).write_text(json.dumps(receipt,indent=2))
print(json.dumps({'mode':mode,'scenarios_passed':len(r),'keywords':51,'opportunities':6,'access_checks':8}))
