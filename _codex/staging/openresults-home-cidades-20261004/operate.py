from pathlib import Path
import json,subprocess,shlex,hashlib,sys
stage=Path(__file__).resolve().parent
mode=sys.argv[1]
assert mode in ('baseline','red','test','render','publish','verify','rollback')
names=['includes/backend_home_cidades.cfm','assets/css/openresults-home-cidades.css','assets/js/openresults-home-cidades.js','includes/form_busca_principal.cfm','index.cfm']
root=Path('/Users/Shared/Projects/RunnerHub/OpenResults')
watch_names=['includes/backend.cfm','includes/backend_estado_cidades.cfm','includes/head.cfm','includes/variaveis.cfm','includes/footer.cfm','includes/header.cfm','includes/lista_de_eventos_simple.cfm','includes/location.cfm','assets/js/openresults-estado-cidades.js','assets/css/openresults-estado-cidades.css','estado/index.cfm','api/eventos_por_estado.cfm','Application.cfc','.htaccess','robots.txt']
digest=lambda b:hashlib.sha256(b).hexdigest()
if mode=='baseline':
 manifest={'order':names,'before':{n:digest((root/n).read_bytes()) if (root/n).exists() else None for n in names},'watch':{n:digest((root/n).read_bytes()) for n in watch_names},'git_ref':subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()}
 (stage/'manifest.json').write_text(json.dumps(manifest,indent=2))
 patch=subprocess.check_output(['git','diff','HEAD','--','index.cfm','includes/form_busca_principal.cfm'],cwd=root,text=True)
 (stage/'baseline.patch').write_text(patch)
m=json.loads((stage/'manifest.json').read_text())
files={n:(stage/'candidate'/n).read_text() for n in names if (stage/'candidate'/n).exists()}
if mode in ('test','render','publish','verify'):m['after']={n:digest(v.encode()) for n,v in files.items()};(stage/'manifest.json').write_text(json.dumps(m,indent=2))
helpers=Path('/Users/Shared/Projects/RunnerHub/Business/_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/openresults.run')")
remote=helpers+'''
import secrets
p=json.load(sys.stdin);root=Path('/var/www/openresults.run');m=p['manifest'];mode=p['mode']
def check_before():
 expected=m.get('runtime_before',m['before'])
 baseline(root,m['order'],{n:v for n,v in expected.items() if v is not None});baseline(root,m['watch'],m['watch'])
def candidate_in(work):
 candidate=work/'candidate';candidate.mkdir()
 for source in root.iterdir():
  if source.name in ('index.cfm','Application.cfc','_codex'):continue
  if source.name in ('includes','assets'):
   target=candidate/source.name;target.mkdir()
   for child in source.iterdir():
    if child.name in ('js','css') and child.is_dir():
     nested=target/child.name;nested.mkdir()
     for asset in child.iterdir():
      if str(asset.relative_to(root)) not in p['files']:(nested/asset.name).symlink_to(asset)
    elif str(child.relative_to(root)) not in p['files']:(target/child.name).symlink_to(child)
  else:(candidate/source.name).symlink_to(source)
 for name,content in p['files'].items():
  target=candidate/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(content)
 return candidate
if mode=='baseline':check_before();result={'baseline_confirmed':True,'runtime_files':len(m['before']),'watched_dependencies':len(m['watch'])}
elif mode in ('red','test','render'):
 check_before()
 compiled_count=0
 if mode=='test':
  with tempfile.TemporaryDirectory(prefix='or-home-city-compile-',dir='/var/tmp') as d:
   work=Path(d);os.chmod(work,0o755);source=work/'source';source.mkdir()
   for name,content in p['files'].items():
    target=source/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(content)
   compiled=work/'compiled';compiled.mkdir(mode=0o777);os.chmod(compiled,0o777)
   cp=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(source),'-dir',str(source),'-deploydir',str(compiled)],capture_output=True,text=True,timeout=150)
   compiled_count=len(list(compiled.rglob('*.cfm')))
   if cp.returncode or 'Error compiling' in cp.stdout+cp.stderr or compiled_count!=3:raise RuntimeError('Compile failed: '+cp.stdout+cp.stderr)
 work=Path(tempfile.mkdtemp(prefix='or-home-city-fixture-',dir=root/'_codex'));os.chmod(work,0o755);token=secrets.token_hex(24)
 try:
  (work/'.htaccess').write_text('Require local\\n')
  (work/'Application.cfc').write_text('component {this.name="'+work.name+'";this.datasource="runnerhub";this.sessionManagement=true;this.setClientCookies=false;boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.request_method!="POST"||compare(form.key ?: "","'+token+'")!=0){cfheader(statuscode=404);abort;}application.nomeSite="Open Results";application.baseCanonica="https://openresults.run";application.dominio="openresults.run";application.codSite="OR";application.ga="";return true;}}')
  candidate_in(work)
  if mode=='render':
   body='<cfset URL.tag=""/><cfsavecontent variable="html"><cfinclude template="candidate/index.cfm"/></cfsavecontent><cfoutput>#serializeJSON({html=html,cities=arrayLen(VARIABLES.homeCityCatalog.cities),recent=VARIABLES.homeCityCatalog.recent,popular=VARIABLES.homeCityCatalog.popular,jsonBytes=len(VARIABLES.homeCityJson)})#</cfoutput>'
  else:
   (work/'catalog.cfm').write_text(p['fixture'])
   body='<cfsavecontent variable="out"><cfinclude template="catalog.cfm"/></cfsavecontent><cfoutput>#serializeJSON({output=trim(out)})#</cfoutput>'
  (work/'run.cfm').write_text('<cfsetting requesttimeout="90" showdebugoutput="false"/><cfcontent type="application/json" reset="true"/><cftry>'+body+'<cfcatch><cfheader statuscode="500"/><cfoutput>#serializeJSON({error=cfcatch.message,detail=cfcatch.detail,trace=cfcatch.tagContext})#</cfoutput></cfcatch></cftry>')
  cp=subprocess.run(['curl','-sS','--max-time','95','--resolve','openresults.run:443:127.0.0.1','-X','POST','--data-urlencode','key='+token,'https://openresults.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=100)
  value={k.lower():v for k,v in json.loads(cp.stdout).items()}
  if mode=='red':
   if value.get('error')!='Home city catalog not implemented':raise RuntimeError(json.dumps(value))
   result={'red_confirmed':value['error']}
  else:
   if 'error' in value:raise RuntimeError(json.dumps(value))
   if mode=='render':result=value
   else:
    assert value['output'].startswith('HOME_CITY_PASSED:');result={'cfml':value['output'],'compiled':compiled_count}
    (work/'guard.cfm').write_text('<cfinclude template="candidate/includes/backend_home_cidades.cfm"/>')
    cp=subprocess.run(['curl','-sS','--max-time','15','--resolve','openresults.run:443:127.0.0.1','-X','POST','--data-urlencode','key='+token,'-w','\\n%{http_code}','https://openresults.run/_codex/'+work.name+'/guard.cfm?qEventosBase=x&template=/'],capture_output=True,text=True,timeout=20)
    assert cp.stdout.rsplit('\\n',1)[-1]=='403',cp.stdout[-300:];result['guard']=403
 finally:shutil.rmtree(work)
elif mode=='publish':
 assert p['tested'];check_before();reference=(root/'index.cfm').stat()
 with tempfile.TemporaryDirectory(prefix='or-home-city-transport-',dir='/var/tmp') as d:
  for name,content in p['files'].items():
   assert digest(content.encode())==m['after'][name];target=Path(d)/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(content)
  for name in m['order']:replace_file(Path(d)/name,root/name,reference)
 baseline(root,m['after'],m['after']);baseline(root,m['watch'],m['watch'])
 result={'published':m['order'],'hashes_verified':len(m['after']),'dependencies_unchanged':len(m['watch']),'no_deploy_backups':True}
elif mode=='verify':
 baseline(root,m['after'],m['after']);baseline(root,m['watch'],m['watch']);result={'hashes_verified':len(m['after']),'dependencies_unchanged':len(m['watch'])}
else:
 for name in m['order']:
  if (root/name).exists() and digest((root/name).read_bytes())!=m['after'][name]:raise RuntimeError('Concurrent runtime change: '+name)
 reference=(root/'index.cfm').stat()
 with tempfile.TemporaryDirectory(prefix='or-home-city-restore-',dir='/var/tmp') as d:
  for name in reversed(m['order']):
   if m['before'][name] is None:(root/name).unlink()
   else:
    content=p['restore'][name].encode();assert digest(content)==m['before'][name]
    target=Path(d)/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(content);replace_file(target,root/name,reference)
 result={'restored_from_git_and_baseline_patch':True}
print(json.dumps(result))
'''
payload={'mode':mode,'manifest':m,'files':files,'fixture':(stage/'tests/catalog.cfm').read_text()}
if mode=='publish':
 receipt=json.loads((stage/'test.json').read_text());assert receipt['manifest']['after']==m['after'];payload['tested']=True
if mode=='rollback':
 import tempfile
 with tempfile.TemporaryDirectory() as d:
  restore=Path(d)
  for n in m['before']:
   if m['before'][n] is not None:
    target=restore/n;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(subprocess.check_output(['git','show',m['git_ref']+':'+n],cwd=root))
  patch=(stage/'baseline.patch').read_text()
  if patch:subprocess.run(['git','apply'],cwd=restore,input=patch,text=True,check=True)
  payload['restore']={n:(restore/n).read_text() for n,v in m['before'].items() if v is not None}
  for n,v in payload['restore'].items():assert digest(v.encode())==m['before'][n]
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=250)
if cp.returncode:raise RuntimeError(cp.stderr[-6000:])
result=json.loads(cp.stdout)
if mode=='render':(stage/'tests/candidate-render.html').write_text(result.pop('html'))
(stage/(mode+'.json')).write_text(json.dumps({'manifest':m,'result':result},ensure_ascii=False,indent=2))
print(json.dumps(result,ensure_ascii=False))
