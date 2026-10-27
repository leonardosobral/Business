from pathlib import Path
import json,hashlib,subprocess,shlex
S=Path(__file__).resolve().parent;b=json.loads((S/'baseline.json').read_text());groups={g:{'root':v['root'],'files':{n:(S/'candidate'/g/n).read_text() for n in v['names']}} for g,v in b.items()}
remote=r'''
from pathlib import Path
import json,sys,os,tempfile,shutil,secrets,subprocess,pwd,re
p=json.load(sys.stdin);results={}
for group,data in p.items():
 root=Path(data['root']);host='roadrunners.run' if group=='RoadRunners' else 'business.roadrunners.run';key=secrets.token_hex(24);work=Path(tempfile.mkdtemp(prefix='seo-measure-verify-',dir=root/'_codex'));os.chmod(work,0o755)
 try:
  (work/'.htaccess').write_text('Require local\n');prefix='/_codex/'+work.name+'/'
  guard='<cfsetting showdebugoutput="false"/><cfif NOT listFind("127.0.0.1,::1",cgi.remote_addr) OR compare(cgi.http_x_verify ?: "","'+key+'") NEQ 0><cfheader statuscode="404"/><cfabort/></cfif>'
  for n,c in data['files'].items():
   f=work/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_text(c)
  if group=='RoadRunners':
   f=work/'calculadora-de-pace/index.cfm';f.write_text(f.read_text().replace('template="../includes/','template="/includes/'))
   (work/'view.cfm').write_text(guard+'<cfinclude template="calculadora-de-pace/index.cfm"/>');cases={'view':('view.cfm','GET')}
  else:
   (work/'Application.cfc').write_text('component{this.name="'+work.name+'";this.sessionManagement=true;boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(cgi.http_x_verify ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
   auth=work/'includes/backend/require_admin.cfm';auth.parent.mkdir(parents=True);auth.write_text((root/'includes/backend/require_admin.cfm').read_text())
   for name,site,admin in [('view','roadrunners',True),('openresults','openresults',True),('denied','roadrunners',False)]:
    (work/(name+'.cfm')).write_text(guard+'<cfset VARIABLES.businessEffectiveIsAdmin='+str(admin).lower()+'/><cfset VARIABLES.seoQueueSiteFilter="'+site+'"/><cfinclude template="portal/conteudo/seo_ga4.cfm"/>')
   cases={n:(n+'.cfm','GET') for n in ['view','openresults','denied']};cases.update({'post':('view.cfm','POST'),'direct':('portal/conteudo/seo_growth_baseline.cfm','GET')})
  result={}
  for label,(url,method) in cases.items():
   cp=subprocess.run(['curl','-sS','--max-time','60','--resolve',host+':443:127.0.0.1','-H','X-Verify: '+key,'-X',method,'-w','\n%{http_code}','https://'+host+prefix+url],capture_output=True,text=True,timeout=65)
   body,status=cp.stdout.rsplit('\n',1);result[label]={'status':int(status),'body':body}
  results[group]=result
 finally:shutil.rmtree(work)
with tempfile.TemporaryDirectory(prefix='seo-measure-compile-',dir='/var/tmp') as tmp:
 src=Path(tmp)/'src';src.mkdir();os.chmod(tmp,0o755)
 for group,data in p.items():
  for n,c in data['files'].items():
   if not n.endswith('.cfm'):continue
   f=src/group/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_text(c)
 out=Path(tmp)/'out';out.mkdir();os.chmod(out,0o777);exe=list(Path('/opt').glob('*/cfusion/bin/cfcompile.sh'))[0];user=pwd.getpwuid((exe.parent.parent/'lib/seed.properties').stat().st_uid).pw_name
 cp=subprocess.run([str(exe),'-deploy','-cfruntimeuser',user,'-webroot',str(src),'-dir',str(src),'-deploydir',str(out)],capture_output=True,text=True,timeout=170);output=cp.stdout+cp.stderr;count=len(list(out.rglob('*.cfm')))
 results['compile']={'ok':cp.returncode==0 and 'Error compiling' not in output and count==3,'templates':count,'error':output[-2000:] if count!=3 or 'Error compiling' in output else ''}
print(json.dumps(results))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(groups),capture_output=True,text=True,timeout=300)
assert cp.returncode==0,cp.stderr[-2500:];r=json.loads(cp.stdout)
for group in groups:
 for name,item in r[group].items():
  (S/('candidate-'+group+'-'+name+'.html')).write_text(item['body']);assert item['status']==({'denied':403,'direct':403,'post':405}.get(name,200)),(group,name,item['status'],item['body'][:1000]);assert 'Error Occurred' not in item['body']
assert r['compile']['ok'],r['compile']
assert 'seo-regional-baseline-title' in r['Business']['view']['body'] and '316 cliques' in r['Business']['view']['body']
assert 'seo-regional-baseline-title' not in r['Business']['openresults']['body']
assert '20261025measure' in r['RoadRunners']['view']['body']
hashes={g:{n:hashlib.sha256(c.encode()).hexdigest() for n,c in d['files'].items()} for g,d in groups.items()}
(S/'candidate-verified.json').write_text(json.dumps({'hashes':hashes,'compiledTemplates':3,'scenarios':6},indent=2));print(json.dumps({'compiledTemplates':3,'scenarios':6,'status':'passed'}))
