"""Test profile image storage with disposable PNGs, without changing profile records."""
import hashlib,json,pathlib,re,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2]
WORK=pathlib.Path('/private/tmp/profile-photo-prod-20261114')
MODE=sys.argv[1] if len(sys.argv)>1 else 'candidate'
if MODE not in ('baseline','candidate','published'):raise SystemExit('Use baseline, candidate, or published')
base=WORK/('baseline' if MODE=='baseline' else 'candidate')
files={}
for host in ['dev.roadrunners.run','roadrunners.com.br']:
 for rel in ['api/upload_foto_atleta.cfm','includes/backend/backend_perfil_edicao.cfm']:
  text=(base/host/rel).read_text(encoding='utf-8-sig')
  if 'expandpath("../assets/paginas/")' in text:raise SystemExit('FAIL: upload ainda usa a pasta do ambiente: '+host+'/'+rel)
  if '"/var/www/roadrunners.com.br/assets/paginas/"' not in text:raise SystemExit('FAIL: armazenamento de produção não definido: '+rel)
  files[host+'/'+rel]=text
remote=r"""
import base64,hashlib,json,os,pathlib,secrets,shutil,struct,subprocess,sys,tempfile,zlib
p=json.load(sys.stdin);sources=p['files'];checks=[]
if p['mode']=='published':
 for rel,source in sources.items():
  if (pathlib.Path('/var/www')/rel).read_bytes()!=source.encode():raise SystemExit('Runtime changed: '+rel)
name='profile_photo_test_'+secrets.token_hex(8);nonce=secrets.token_hex(24)
root=pathlib.Path('/var/www/dev.roadrunners.run');stage=root/'_codex'/name
work=pathlib.Path(tempfile.mkdtemp(prefix='profile-photo-test-',dir='/run'));os.chmod(work,0o700)
prefix='codex_profile_test_'+secrets.token_hex(12)
production=pathlib.Path('/var/www/roadrunners.com.br/assets/paginas')
if any(production.glob(prefix+'*')):raise SystemExit('Fixture name collision')
def chunk(t,b):return struct.pack('!I',len(b))+t+b+struct.pack('!I',zlib.crc32(t+b)&0xffffffff)
png=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('!2I5B',32,24,8,2,0,0,0))+chunk(b'IDAT',zlib.compress((b'\0'+b'\xf4\xb1\x20'*32)*24))+chunk(b'IEND',b'')
image=work/'input.png';image.write_bytes(png)
try:
 stage.mkdir(mode=0o755);(stage/'.htaccess').write_text('Require local\n')
 (stage/'Application.cfc').write_text('component {this.name="'+name+'";this.sessionManagement=false;}')
 for host in ['dev.roadrunners.run','roadrunners.com.br']:
  for kind,rel,field in [('editor','api/upload_foto_atleta.cfm','croppedImage'),('legacy','includes/backend/backend_perfil_edicao.cfm','arquivo')]:
   source=sources[host+'/'+rel]
   if kind=='editor':
    a=source.index('<cftry>')+len('<cftry>');b=source.index('<cfquery datasource="runner_dba"',a)
    opening=source[source.index('<cfset VARIABLES.profilePhotoStorageDirectory'):source.index('<cftry>')]
    code=opening+source[a:b]
   else:
    a=source.index('<cfif isDefined("FORM.action") AND FORM.action EQ "upload_foto">')+len('<cfif isDefined("FORM.action") AND FORM.action EQ "upload_foto">');b=source.index('<cfquery datasource="runner_dba"',a)
    code=source[a:b]
   if kind=='editor':pathExpr='uploadResult.serverDirectory & "/" & uploadResult.serverFile'
   else:pathExpr='VARIABLES.profilePhotoStorageDirectory & FORM.id_pagina & "." & cffile.serverFileExt'
   code='''<cfsetting showdebugoutput="false" requesttimeout="30"><cfscript>
if(!listFind("127.0.0.1,::1",CGI.remote_addr) OR (CGI.http_x_photo_test ?: "") NEQ "'''+nonce+'''"){cfheader(statuscode=404);abort;}
cfcontent(type="application/json; charset=utf-8",reset=true);cfheader(name="Cache-Control",value="no-store");
</cfscript><cftry>'''+code+'''<cfscript>
fixturePath='''+pathExpr+''';
if(getDirectoryFromPath(fixturePath) NEQ "/var/www/roadrunners.com.br/assets/paginas/" OR !find("'''+prefix+'''",listLast(fixturePath,"/")))throw(message="Storage path differs from production fixture");
writeOutput(serializeJSON({ok=true,file=listLast(fixturePath,"/"),sha=hash(fileReadBinary(fixturePath),"SHA-256"),width='''+('imageGetWidth(myImage)' if kind=='editor' else '32')+'''}));
</cfscript><cfcatch><cfoutput>#serializeJSON({ok=false,message=cfcatch.message,detail=left(cfcatch.detail,200)})#</cfoutput></cfcatch></cftry>'''
   script=stage/(host+'-'+kind+'.cfm');script.write_text(code);os.chmod(script,0o644)
   args=['curl','-sS','--max-time','35','--resolve','dev.roadrunners.run:443:127.0.0.1','-H','X-Photo-Test: '+nonce,'-F','id_pagina='+prefix,'-F',field+'=@'+str(image)+';filename='+prefix+'_'+kind+'.png;type=image/png','https://dev.roadrunners.run/_codex/'+name+'/'+script.name]
   # The modern API requires a numeric page ID; it never reaches the database in this fixture.
   if kind=='editor':args[args.index('id_pagina='+prefix)]='id_pagina=2147483647'
   result=subprocess.run(args,capture_output=True,timeout=40)
   try:report={k.lower():v for k,v in json.loads(result.stdout).items()}
   except Exception:raise RuntimeError('Non-JSON response from '+host+' '+kind)
   if not report.get('ok'):raise RuntimeError(json.dumps(report,ensure_ascii=False))
   if kind=='editor' and report['width']!=512:raise RuntimeError('Image was not resized')
   get=subprocess.run(['curl','-sS','--max-time','12','--resolve','roadrunners.run:443:127.0.0.1','https://roadrunners.run/assets/paginas/'+report['file']],capture_output=True,timeout=15)
   if get.returncode or hashlib.sha256(get.stdout).hexdigest()!=report['sha'].lower():raise RuntimeError('Production URL does not serve uploaded image')
   checks.append({'host':host,'flow':kind,'written_to_production':True,'public_url_validated':True,'width':report['width']})
finally:
 for fixture in production.glob(prefix+'*'):
  if fixture.is_file() and not fixture.is_symlink():fixture.unlink()
 if stage.exists():shutil.rmtree(stage)
 shutil.rmtree(work)
print(json.dumps({'ok':True,'checks':checks,'fixtures_removed':not any(production.glob(prefix+'*')),'stage_removed':not stage.exists(),'account_data_mutations':False}))
"""
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=10','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps({'files':files,'mode':MODE}).encode(),capture_output=True,timeout=210)
if not r.stdout:raise SystemExit(r.stderr.decode(errors='replace')[-1200:])
result=json.loads(r.stdout);result['mode']=MODE;result['hashes']={rel:hashlib.sha256(s.encode()).hexdigest() for rel,s in files.items()}
(WORK/('tests-'+MODE+'.json')).write_text(json.dumps(result,ensure_ascii=False,indent=2))
print(json.dumps(result,ensure_ascii=False))
raise SystemExit(0 if not r.returncode and result.get('ok') else 1)
