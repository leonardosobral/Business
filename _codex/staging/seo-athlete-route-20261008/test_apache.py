from pathlib import Path
import hashlib,json,shlex,subprocess
S=Path(__file__).resolve().parent
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
files={group:{n:(S/group/n).read_text() for n in ['.htaccess','atleta/.htaccess']} for group in ['baseline','candidate']}
cases=[]
for prefix,lang in [('atleta',''),('en/athlete','en'),('es/atleta','es')]:
 for method in ['GET','HEAD']:
  cases.append(dict(name=method+' space '+prefix,path=prefix+'/leonardo%20muniz/',method=method,status=200,tag='leonardo muniz',lang=lang,baseline_status=403))
 for encoded,decoded in [('runner-hub','runner-hub'),('a%2Bb','a+b'),('a%26b','a&b'),('Jos%C3%A9','José'),('a%2520b','a%20b')]:
  cases.append(dict(name=prefix+' '+encoded,path=prefix+'/'+encoded+'/?filtro=resultados&utm_source=seo',method='GET',status=200,tag=decoded,lang=lang,query=True))
cases += [dict(name='static file',path='atleta/control.txt',method='GET',status=200,static=True),dict(name='direct entry',path='atleta/index.cfm?tag=direct&filtro=resultados&utm_source=seo',method='GET',status=200,tag='direct',lang='',query=True),dict(name='existing directory',path='atleta/',method='GET',status=200,tag='',lang='')]
remote='''from pathlib import Path
import json,tempfile,os,sys,shutil,subprocess,re
p=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run');work=Path(tempfile.mkdtemp(prefix='seo-athlete-apache-',dir=root/'_codex'));os.chmod(work,0o755)
try:
 result=[]
 (work/'.htaccess').write_text('Require local\\nErrorDocument 403 default\\nErrorDocument 404 default\\n')
 (work/'Application.cfc').write_text('component {this.name="'+work.name+'";this.sessionManagement=false;boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)){cfheader(statuscode=404);abort;}return true;}}')
 for group in ['baseline','candidate']:
  g=work/group;g.mkdir(mode=0o755);(g/'atleta').mkdir(mode=0o755)
  # Extract the exact two root rules and preserve the real child guards. Only the fixture destination changes.
  rules=[line.strip() for line in p['files'][group]['.htaccess'].splitlines() if line.strip().startswith(('RewriteRule ^en/athlete/([^/]+)/?$', 'RewriteRule ^es/atleta/([^/]+)/?$'))]
  assert len(rules)==2
  rules=[line.replace('/atleta/index.cfm','/_codex/'+work.name+'/'+group+'/atleta/index.cfm') for line in rules]
  (g/'.htaccess').write_text('Require local\\nErrorDocument 403 default\\nErrorDocument 404 default\\n<IfModule mod_rewrite.c>\\nRewriteEngine on\\n'+'\\n'.join(rules)+'\\n</IfModule>\\n')
  (g/'atleta/.htaccess').write_text(p['files'][group]['atleta/.htaccess'].replace('ErrorDocument 404 /404/','ErrorDocument 404 default'))
  (g/'atleta/control.txt').write_text('routing static control')
  (g/'atleta/index.cfm').write_text('<cfsetting showdebugoutput="false"/><cfcontent type="application/json; charset=utf-8" reset="true"/><cfscript>report={tag=trim(replace(url.tag ?: "","/","")),lang=url.i18n_lang ?: "",route=url.i18n_route ?: "",filtro=url.filtro ?: "",utm=url.utm_source ?: "",injected=structKeyExists(url,"b")};writeOutput(serializeJSON(report));</cfscript>')
 for c in p['cases']:
  responses={}
  for group in ['baseline','candidate']:
   cmd=['curl','-sS','--path-as-is','--max-time','15','--resolve','business.roadrunners.run:443:127.0.0.1']
   if c['method']=='HEAD':cmd+=['-I']
   cmd+=['-w','\\n%{http_code}','https://business.roadrunners.run/_codex/'+work.name+'/'+group+'/'+c['path']]
   cp=subprocess.run(cmd,capture_output=True,text=True,timeout=19);body,_,status=cp.stdout.rpartition('\\n');response={'status':int(status or 0),'returncode':cp.returncode}
   if response['status']==200 and c['method']=='GET' and not c.get('static'):response['data']={k.lower():v for k,v in json.loads(body).items()}
   responses[group]=response
  old=responses['baseline'];new=responses['candidate'];ok=not old['returncode'] and not new['returncode'] and new['status']==c['status']
  if 'baseline_status' in c:ok=ok and old['status']==c['baseline_status']
  if c['method']=='GET' and not c.get('static'):
   d=new.get('data',{});ok=ok and d.get('tag')==c['tag'] and d.get('lang')==c['lang'] and d.get('injected')==False
   if c.get('query'):ok=ok and d.get('filtro')=='resultados' and d.get('utm')=='seo'
   if c['lang']:ok=ok and d.get('route')=='athlete'
  if c.get('static') or c['name'] in ['direct entry','existing directory'] or 'runner-hub' in c['name']:ok=ok and old==new
  result.append({'name':c['name'],'before':old,'after':new,'passed':ok})
 print(json.dumps({'checks':result}))
finally:shutil.rmtree(work)
'''
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps({'files':files,'cases':cases}),capture_output=True,text=True,timeout=220)
if cp.returncode:raise RuntimeError(cp.stderr[-3500:])
r=json.loads(cp.stdout);r['hashes']={n:hashlib.sha256((S/'candidate'/n).read_bytes()).hexdigest() for n in ['.htaccess','atleta/.htaccess']};r['failed']=[x for x in r['checks'] if not x['passed']]
(S/'apache-tests.json').write_text(json.dumps(r,indent=2,ensure_ascii=False));print(json.dumps({'scenarios':len(r['checks']),'failed':r['failed']},ensure_ascii=False));assert not r['failed']
