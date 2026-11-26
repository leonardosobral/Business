"""Render actual CFML and verify the archive/access/download contracts in isolation."""
from pathlib import Path
import base64, hashlib, json, shlex, subprocess, sys
S=Path(__file__).resolve().parent; B=S.parents[2]
mode=sys.argv[1];assert mode in ('candidate','published')
names=['portal/conteudo/seo_semrush.cfm','portal/conteudo/seo_semrush_archive.cfm','portal/includes/seo_semrush_archive_backend.cfm','portal/seo/arquivo.cfm']
payload={'mode':mode,'files':{n:(B/n).read_text() for n in names}}
remote=r'''
from pathlib import Path
import base64,hashlib,json,os,re,secrets,shutil,subprocess,sys,tempfile
from urllib.parse import quote
p=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run');private=Path('/var/lib/runnerhub/seo/semrush/20261104')
manifest=json.loads((private/'manifest.json').read_text())
work=Path(tempfile.mkdtemp(prefix='seo-semrush-archive-verify-',dir=root/'_codex'));os.chmod(work,0o755);key=secrets.token_hex(24)
cases={
 'all':('VARIABLES.seoQueueSiteFilter="all";',True,'GET',200),'rr':('URL.site="roadrunners";',True,'GET',200),
 'or':('URL.site="openresults";',True,'GET',200),
 'pass':('URL.gravidade="pass";',True,'GET',200),
 'unmeasured':('URL.gravidade="unmeasured";',True,'GET',200),
 'rr-pages':('URL.arquivo_visao="paginas";',True,'GET',200),
 'or-pages':('URL.site="openresults";URL.arquivo_visao="paginas";',True,'GET',200),
 'or-duplicate':('URL.site="openresults";URL.arquivo_visao="paginas";URL.problema="15";',True,'GET',200),
 'rr-last':('URL.arquivo_visao="paginas";URL.pagina="99999";',True,'GET',200),
 'or-last':('URL.site="openresults";URL.arquivo_visao="paginas";URL.pagina="400";',True,'GET',200),
 'none':('URL.arquivo_visao="paginas";URL.busca="seo-no-match-7f19a3";',True,'GET',200),
 'xss':('URL.busca="<img src=x onerror=alert(1)>";',True,'GET',200),
 'invalid':('URL.problema={bad=true};URL.pagina="-1";URL.gravidade="bad";',True,'GET',200),
 'rr-files':('URL.arquivo_visao="arquivos";',True,'GET',200),
 'or-files':('URL.site="openresults";URL.arquivo_visao="arquivos";',True,'GET',200),
 'rr-keywords':('URL.arquivo_visao="palavras";',True,'GET',200),
 'or-keywords':('URL.site="openresults";URL.arquivo_visao="palavras";',True,'GET',200),
 'keyword-none':('URL.arquivo_visao="palavras";URL.busca="seo-no-match-7f19a3";',True,'GET',200),
 'legacy-words':('URL.secao="palavras";',True,'GET',200),
 'legacy-opportunities':('URL.secao="oportunidades";',True,'GET',200),
 'denied-view':('',False,'GET',403),'post-view':('',True,'POST',405),
}
try:
 copies=list(p['files'])+['includes/backend/require_admin.cfm','portal/includes/seo_semrush_data.cfm']
 for n in copies:
  f=work/n;f.parent.mkdir(parents=True,exist_ok=True)
  if p['mode']=='candidate' and n in p['files']:f.write_text(p['files'][n])
  else:shutil.copyfile(root/n,f)
 (work/'includes/backend/backend_login.cfm').write_text('<!--- Isolated fixture authentication; real require_admin.cfm retained. --->')
 (work/'.htaccess').write_text('Require local\n')
 (work/'Application.cfc').write_text('component{this.name="'+work.name+'";this.sessionManagement=true;boolean function onRequestStart(string t){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(cgi.http_x_verify ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 base='<cfsetting showdebugoutput="false" requesttimeout="60"/><cfset setLocale("Portuguese (Brazilian)")/>'
 for n,(setup,admin,method,status) in list(cases.items()):
  wrapper=base+'<cfset VARIABLES.businessEffectiveIsAdmin='+str(admin).lower()+'/><cfscript>VARIABLES.seoQueueSiteFilter="roadrunners";VARIABLES.seoQueuePriorityFilter="all";VARIABLES.seoScoreFilter="all";VARIABLES.seoTabFilters="";'+setup+'if(structKeyExists(URL,"site") AND isSimpleValue(URL.site)) VARIABLES.seoQueueSiteFilter=URL.site;</cfscript><cfinclude template="portal/conteudo/seo_semrush.cfm"/>'
  (work/(n+'.cfm')).write_text(wrapper)
 for n,admin,method,route in [('denied-data',False,'GET','portal/includes/seo_semrush_archive_backend.cfm'),('post-data',True,'POST','portal/includes/seo_semrush_archive_backend.cfm'),('denied-download',False,'GET','portal/seo/arquivo.cfm'),('post-download',True,'POST','portal/seo/arquivo.cfm'),('download-valid',True,'GET','portal/seo/arquivo.cfm'),('download-bad',True,'GET','portal/seo/arquivo.cfm'),('download-path',True,'GET','portal/seo/arquivo.cfm')]:
  fid='roadrunners-issues' if n=='download-valid' else '../../manifest.json' if n=='download-path' else 'unknown'
  (work/(n+'.cfm')).write_text(base+'<cfset VARIABLES.businessEffectiveIsAdmin='+str(admin).lower()+'/><cfset URL.arquivo="'+fid+'"/><cfinclude template="'+route+'"/>')
  cases[n]=('',admin,method,403 if not admin else 405 if method=='POST' else 200 if n=='download-valid' else 404)
 for n,path in [('direct-view','portal/conteudo/seo_semrush_archive.cfm'),('direct-data','portal/includes/seo_semrush_archive_backend.cfm')]:
  cases[n]=(path,True,'GET',403)
 results={};html={}
 for n,(setup,admin,method,expected) in cases.items():
  route=setup if n.startswith('direct-') else n+'.cfm'
  if n.startswith('direct-'):
   direct=work/route;original=direct.read_text();direct.write_text('<cfset VARIABLES.businessEffectiveIsAdmin=true/>'+original)
  cp=subprocess.run(['curl','-sS','--max-time','65','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-Verify: '+key,'-X',method,'-w','\n%{http_code}','https://business.roadrunners.run/_codex/'+work.name+'/'+route],capture_output=True,timeout=70)
  assert cp.returncode==0,'Request failed: '+n
  body,status=cp.stdout.rsplit(b'\n',1);status=int(status);content=body.decode('utf-8',errors='replace')
  if status!=expected or 'Error Occurred While Processing Request' in content:
   error_at=content.find('Error Occurred While Processing Request');snippet=content[max(0,error_at):max(0,error_at)+12000]
   raise AssertionError((n,status,expected,re.sub('<[^>]+>',' ',snippet)[:4500]))
  results[n]={'status':status,'bytes':len(body),'sha256':hashlib.sha256(body).hexdigest()};html[n]=content
  if n.startswith('direct-'):direct.write_text(original)
 for n in ['all','rr','or']:
  for text in ['72%','76%','305','1.166','22.051','74.693','101 tipos','Auditorias Semrush preservadas']:
   assert text in html[n],(n,text)
 assert '20.000 URLs encontradas' in html['rr-pages'] and '20.000 URLs encontradas' in html['or-pages']
 assert '831 URLs encontradas' in html['or-duplicate']
 assert 'página 400 de 400' in html['rr-last'] and 'página 400 de 400' in html['or-last']
 assert 'Nenhuma URL corresponde' in html['none']
 assert '<img src=x onerror=alert(1)>' not in html['xss'] and '&lt;img' in html['xss']
 for n in ['rr-files','or-files']:assert 'SHA-256:' in html[n] and 'Baixar CSV' in html[n]
 assert '1.376 linhas de posições' in html['rr-keywords'] and '535 linhas de posições' in html['or-keywords']
 assert 'Nenhuma palavra corresponde' in html['keyword-none']
 assert 'palavras' in html['legacy-words'] and 'Oportunidades' in html['legacy-opportunities']
 for n in results:
  if n.startswith(('denied-','post-','direct-')):assert '20.000 URLs encontradas' not in html[n] and 'SHA-256:' not in html[n]
 assert results['download-valid']['sha256']==manifest['files']['roadrunners-issues']['sha256']
 (work/'download-all.cfm').write_text(base+'<cfset VARIABLES.businessEffectiveIsAdmin=true/><cfinclude template="portal/seo/arquivo.cfm"/>')
 for fid,entry in manifest['files'].items():
  cp=subprocess.run(['curl','-sS','--max-time','45','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-Verify: '+key,'-w','\n%{http_code}','https://business.roadrunners.run/_codex/'+work.name+'/download-all.cfm?arquivo='+quote(fid)],capture_output=True,timeout=50)
  assert cp.returncode==0
  body,status=cp.stdout.rsplit(b'\n',1)
  assert status==b'200' and len(body)==entry['bytes'] and hashlib.sha256(body).hexdigest()==entry['sha256'],('download',fid,status)
 print(json.dumps({'scenarios':len(results),'results':results,'verifiedDownloads':len(manifest['files']),'cleanup':True}))
finally:shutil.rmtree(work)
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=650)
assert cp.returncode==0,cp.stderr[-5000:]
r=json.loads(cp.stdout);r['hashes']={n:hashlib.sha256((B/n).read_bytes()).hexdigest() for n in names}
(S/(mode+'-verified.json')).write_text(json.dumps(r,indent=2));print(json.dumps({'mode':mode,'scenarios':r['scenarios'],'cleanup':r['cleanup']}))
