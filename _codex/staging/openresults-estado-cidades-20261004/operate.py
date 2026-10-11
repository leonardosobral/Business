from pathlib import Path
import base64,hashlib,json,shlex,subprocess,sys
stage=Path(__file__).resolve().parent
m=json.loads((stage/'manifest.json').read_text());mode=sys.argv[1]
assert mode in ('test','publish','verify','rollback')
helpers=Path('/Users/Shared/Projects/RunnerHub/Business/_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/openresults.run')")
remote=helpers+'''
payload=json.load(sys.stdin);root=Path('/var/www/openresults.run');m=payload['manifest'];mode=payload['mode']
watch=payload['watch']
def validate_before():
 baseline(root,m['order'],m.get('runtime_before',m['before']));baseline(root,watch,watch)
def test():
 validate_before()
 with tempfile.TemporaryDirectory(prefix='or-city-compile-',dir='/var/tmp') as d:
  work=Path(d);os.chmod(work,0o755);source=work/'source';source.mkdir()
  for name,content in payload['files'].items():
   p=source/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(content)
  compiled=work/'compiled';compiled.mkdir(mode=0o777);os.chmod(compiled,0o777)
  cp=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(source),'-dir',str(source),'-deploydir',str(compiled)],capture_output=True,text=True,timeout=150)
  output=cp.stdout+cp.stderr;count=len(list(compiled.rglob('*.cfm')))
  if cp.returncode!=0 or 'Error compiling' in output or count!=4:raise RuntimeError('Compile failed: '+output)
 work=Path(tempfile.mkdtemp(prefix='or-city-fixture-',dir=root/'_codex'));os.chmod(work,0o755)
 import secrets
 token=secrets.token_hex(24)
 try:
  (work/'.htaccess').write_text('Require local\\n')
  (work/'Application.cfc').write_text('component {this.name="'+work.name+'";this.datasource="runnerhub";this.sessionManagement=true;this.setClientCookies=false;boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.request_method!="POST"||compare(form.key ?: "","'+token+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
  for name,content in payload['files'].items():
   p=work/'candidate'/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(content)
  city_source=work/'candidate/includes/backend_estado_cidades.cfm'
  import re
  city_source.write_text(re.sub(r'<cfquery name="qEstadoCidadesNomes"[^>]*>.*?</cfquery>',lambda _:payload['names_fixture'],city_source.read_text(),count=1,flags=re.S))
  (work/'counts.cfm').write_text(payload['fixture'])
  (work/'run.cfm').write_text('<cfsetting requesttimeout="60" showdebugoutput="false"/><cfcontent type="application/json" reset="true"/><cftry><cfsavecontent variable="out"><cfinclude template="counts.cfm"/></cfsavecontent><cfoutput>#serializeJSON({output=trim(out)})#</cfoutput><cfcatch><cfheader statuscode="500"/><cfoutput>#serializeJSON({error=cfcatch.message,detail=cfcatch.detail})#</cfoutput></cfcatch></cftry>')
  cp=subprocess.run(['curl','-sS','--max-time','65','--resolve','openresults.run:443:127.0.0.1','-X','POST','--data-urlencode','key='+token,'https://openresults.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=70)
  result=json.loads(cp.stdout)
  if any(k.lower()=='error' for k in result):raise RuntimeError(json.dumps(result))
  output=result.get('OUTPUT',result.get('output',''))
  if not output.startswith('OR_CITY_PASSED:'):raise RuntimeError(output)
  (work/'guard.cfm').write_text('<cfinclude template="candidate/includes/backend_estado_cidades.cfm"/>')
  (work/'invalid.cfm').write_text('<cfset URL.tag="XX"/><cfinclude template="candidate/estado/index.cfm"/>')
  checks={}
  for endpoint,want in [('guard.cfm?qEventosBase=x&qEventos=x',403),('invalid.cfm',404)]:
   cp=subprocess.run(['curl','-sS','--max-time','15','--resolve','openresults.run:443:127.0.0.1','-X','POST','--data-urlencode','key='+token,'-w','\\n%{http_code}','https://openresults.run/_codex/'+work.name+'/'+endpoint],capture_output=True,text=True,timeout=20)
   status=int(cp.stdout.rsplit('\\n',1)[-1])
   if status!=want:raise RuntimeError('Guard status mismatch: '+cp.stdout[-300:])
   checks[endpoint.split('?')[0]]=status
  return {'compiled':4,'cfml':output,'guards':checks,'private_fixture_removed':True}
 finally:shutil.rmtree(work)
if mode=='test':result=test()
elif mode=='publish':
 if not payload.get('tested'):raise RuntimeError('Not verified')
 validate_before();reference=(root/'estado/index.cfm').stat()
 for name in m['order']:
  content=payload['files'][name].encode()
  if digest(content)!=m['after'][name]:raise RuntimeError('Candidate drift')
 # Transport only; no backup copies. Existing files are exactly recoverable from the confirmed Git ref.
 with tempfile.TemporaryDirectory(prefix='or-city-transport-',dir='/var/tmp') as d:
  for name in m['order']:
   p=Path(d)/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(payload['files'][name])
  for name in ['includes/backend_estado_cidades.cfm','assets/js/openresults-estado-cidades.js','assets/css/openresults-estado-cidades.css','includes/backend.cfm','api/eventos_por_estado.cfm','estado/index.cfm']:replace_file(Path(d)/name,root/name,reference)
 baseline(root,m['after'],m['after']);baseline(root,watch,watch)
 result={'published':m['order'],'verified_hashes':len(m['after']),'unchanged_dependencies':len(watch),'recovery_git_ref':m['git_ref'],'no_deploy_backup':True}
elif mode=='verify':
 baseline(root,m['after'],m['after']);baseline(root,watch,watch)
 result={'verified_hashes':len(m['after']),'unchanged_dependencies':len(watch)}
else:
 for name in m['order']:
  if (root/name).exists() and digest((root/name).read_bytes()) not in (m['after'][name],m['before'].get(name)):raise RuntimeError('Concurrent change: '+name)
 reference=(root/'estado/index.cfm').stat()
 with tempfile.TemporaryDirectory(prefix='or-city-restore-',dir='/var/tmp') as d:
  for name in reversed(m['order']):
   if name in m['before']:
    b=base64.b64decode(payload['git_files'][name]);assert digest(b)==m['before'][name]
    p=Path(d)/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(b);replace_file(p,root/name,reference)
   elif (root/name).exists():(root/name).unlink()
 result={'restored_from_git':m['git_ref']}
print(json.dumps(result))
'''
watch={
 'includes/variaveis.cfm':'9790ca79fa19aa84ffb82a1463ed4bc0a9a9babf955dec94b8876f439fa39e13',
 'includes/lista_de_eventos_simple.cfm':'74fbcc36f85201068a0b92f7fafc689d108d80b84793b73c0f75eeaac0f7dd03',
 'includes/head.cfm':'59b902f8432dc97f5c30dbbae8e54e51532e806259bc6d9e0a27c5e9a1e0d39b',
 'Application.cfc':'1cf609c526b7fbae1a7baad4d8910038df41519e0c393ade41d31e9132daf1d4',
 '.htaccess':'5b1475755c02b5efa9e777df97df4831050f252f05cf005f10a7802ddef93e4e',
 'robots.txt':'8e4bd5112e36b26ac104efe0e382b7ceac690c30f2fb87c9d360b6d9ebb810d3',
 'index.cfm':'1d092604d797a90c860c632155dedfab43dea56fddd1bece7bd22e38aee19901',
 'api/eventos.cfm':'3837e00db0cb61a28a35fec8b02157b985ee89a2f3fc0e14207fe31dfbc7007d'}
payload={'mode':mode,'manifest':m,'watch':watch,'files':{n:(stage/'candidate'/n).read_text() for n in m['order']},'fixture':(stage/'tests/counts.cfm').read_text(),'names_fixture':(stage/'tests/names-fixture.cfm').read_text()}
if mode=='publish':
 receipt=json.loads((stage/'test.json').read_text());assert receipt['manifest']==m
 payload['tested']=True
if mode=='rollback':payload['git_files']={n:base64.b64encode(subprocess.check_output(['git','show',m['git_ref']+':'+n],cwd='/Users/Shared/Projects/RunnerHub/OpenResults')).decode() for n in m['before']}
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=220)
if cp.returncode:raise RuntimeError(cp.stderr[-4500:])
result=json.loads(cp.stdout)
(stage/(mode+'.json')).write_text(json.dumps({'manifest':m,'result':result},indent=2,ensure_ascii=False))
print(json.dumps(result,ensure_ascii=False))
