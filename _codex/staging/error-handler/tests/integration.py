# Executed inside a private remote fixture by test_rr_error_handler_integration.py.
import concurrent.futures,hashlib,io,json,os,pathlib,re,secrets,shutil,subprocess,sys,tarfile,tempfile
root=pathlib.Path(tempfile.mkdtemp(prefix='rr-handler-test-',dir='/var/www/roadrunners.com.br/_codex'))
nonce=secrets.token_hex(12);schema='rr_error_test_'+nonce;state='rrErrorTest'+nonce
checks=[]
def request(path,mode='normal'):
 p=subprocess.run(['curl','-sS','--max-time','15','--resolve','roadrunners.run:443:127.0.0.1','-H',('Accept: application/json' if mode=='json' else 'Accept: text/html'),'-X','POST','--data-urlencode','key='+nonce,'--data-urlencode','mode='+mode,'-D','-','https://roadrunners.run/_codex/'+root.name+'/'+path],capture_output=True,text=True,timeout=20)
 if p.returncode:raise RuntimeError('HTTP fixture failed')
 headers,_,body=p.stdout.partition('\n\n');return headers,body
try:
 with tarfile.open(fileobj=io.BytesIO(sys.stdin.buffer.read())) as tar:
  for m in tar.getmembers():
   name=pathlib.Path(m.name);assert m.isfile() and not name.is_absolute() and '..' not in name.parts
   p=root/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(tar.extractfile(m).read());os.chmod(p,0o644)
 (root/'.htaccess').write_text('Require local\n');os.chmod(root,0o755)
 for p in root.rglob('*.cfm'):
  p.write_text(p.read_text().replace('INSERT INTO tb_log','INSERT INTO '+schema+'.tb_log').replace('datasource="runnerhub"','datasource="runner_dba"'))
 # Replace only external effects in the test copy; real handler and rate limiter still run.
 mailstub='<cfset SERVER.'+state+'.mail++/><cfif FORM.mode EQ "smtp"><cfthrow message="Synthetic SMTP unavailable"/></cfif>'
 parent=(root/'Application.cfc').read_text();parent=re.sub(r'<cfmail\b[\s\S]*?</cfmail>',mailstub,parent,flags=re.I).replace('INSERT INTO tb_log','INSERT INTO '+schema+'.tb_log')
 (root/'PortalApplication.cfc').write_text(parent)
 if (root/'includes/errors/handle.cfm').exists():
  p=root/'includes/errors/handle.cfm';p.write_text(p.read_text().replace('<!--- Reporting is best effort; response below is independent. --->','<cfset SERVER.'+state+'.reportingError={message=cfcatch.message,line=cfcatch.tagContext[1].line}/>' ))
 if (root/'includes/errors/notify.cfm').exists():(root/'includes/errors/notify.cfm').write_text(mailstub)
 if (root/'services/ErrorReporter.cfc').exists():
  impl=root/'implementation';impl.mkdir()
  source=(root/'services/ErrorReporter.cfc').read_text().replace('rrErrorAlertBudgetV1',state+'Budget').replace('rr-error-alert-budget-v1',state+'Lock')
  (impl/'ErrorReporter.cfc').write_text(source)
  (root/'services/ErrorReporter.cfc').write_text('''component extends="implementation.ErrorReporter" {
  public numeric function writeDatabase(required struct event,string datasource="runnerhub",string schema="public") {if(listFind("database,all",FORM.mode))throw(message="Synthetic database unavailable");return super.writeDatabase(event,"runner_dba","SCHEMA");}
  public void function writeLocal(required struct event,string reason="database_unavailable"){if(FORM.mode=="all")throw(message="Synthetic logger unavailable");SERVER.STATE.local++;}
 }'''.replace('SCHEMA',schema).replace('STATE',state))
 app='''component extends="PortalApplication" {
 this.name="NAME";this.datasource="runner_dba";this.mappings["/services"]=getDirectoryFromPath(getCurrentTemplatePath()) & "services";this.mappings["/implementation"]=getDirectoryFromPath(getCurrentTemplatePath()) & "implementation";
 boolean function onApplicationStart(){APPLICATION.codSite="RR";return true;}
 void function onSessionStart(){}
 boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(form.key ?: "","TOKEN")!=0){cfheader(statuscode=404);abort;}SESSION.SESSIONID="isolated-test-session";REQUEST.requestId=lCase(createUUID());if(listLast(target,"/")=="bootstrap.cfm")throw(type="expression",message="Variable BOOTSTRAP is undefined.");return true;}
 }'''.replace('NAME',root.name).replace('TOKEN',nonce)
 (root/'Application.cfc').write_text(app)
 micro=root/'maratonadefloripa'
 (micro/'MicrositeApplication.cfc').write_text((micro/'Application.cfc').read_text())
 (micro/'Application.cfc').write_text(app.replace('extends="PortalApplication"','extends="MicrositeApplication"').replace('this.name="'+root.name+'"','this.name="'+root.name+'micro"').replace('getDirectoryFromPath(getCurrentTemplatePath()) & "services"','getDirectoryFromPath(getCurrentTemplatePath()) & "../services"').replace('getDirectoryFromPath(getCurrentTemplatePath()) & "implementation"','getDirectoryFromPath(getCurrentTemplatePath()) & "../implementation"'))
 (micro/'fail.cfm').write_text('<cfthrow type="expression" message="Variable MICROSITE is undefined."/>')
 (root/'setup.cfm').write_text('<cfscript>queryExecute("CREATE SCHEMA '+schema+'; CREATE TABLE '+schema+'.tb_log(id_log serial PRIMARY KEY,log_item text,log_item_id text,log_user text,site text)",{},{datasource="runner_dba"});SERVER.'+state+'={mail=0,local=0};writeOutput("ready");</cfscript>')
 (root/'stats.cfm').write_text('<cfscript>q=queryExecute("SELECT count(*) n FROM '+schema+'.tb_log",{},{datasource="runner_dba"});writeOutput(serializeJSON({logs=q.n[1],mail=SERVER.'+state+'.mail,local=SERVER.'+state+'.local,reportingError=SERVER.'+state+'.reportingError ?: {}}));</cfscript>')
 (root/'cleanup.cfm').write_text('<cfscript>queryExecute("DROP SCHEMA IF EXISTS '+schema+' CASCADE",{},{datasource="runner_dba"});structDelete(SERVER,"'+state+'");structDelete(SERVER,"'+state+'Budget");writeOutput("removed");</cfscript>')
 for name in ['fail','bootstrap']:(root/(name+'.cfm')).write_text('<cfthrow type="expression" message="Variable CART is undefined."/>')
 (root/'burst.cfm').write_text('<cfthrow type="expression" message="Variable BURST is undefined."/>')
 (root/'other.cfm').write_text('<cfthrow type="expression" message="Variable OTHER is undefined."/>')
 (root/'fatal.cfm').write_text('<cfthrow type="expression" message="Variable FATAL is undefined."/>')
 (root/'reentrant.cfm').write_text('<cfset REQUEST.rrHandlingError=true/><cfthrow type="expression" message="Variable SECONDARY is undefined."/>')
 assert 'ready' in request('setup.cfm')[1]
 def check(ok,label):
  if not ok:raise AssertionError(label)
  checks.append(label)
 h,b=request('fail.cfm');check(' 500 ' in h and '\nlocation:' not in h.lower(),'Internal error returns 500 without redirect')
 check('CART' not in b and 'coldfusion' not in b.lower() and 'Uma pausa no percurso' in b,'Friendly page hides internals')
 check('X-Request-ID:' in h or 'x-request-id:' in h.lower(),'Failure response exposes correlation ID')
 h,b=request('fail.cfm');stats=json.loads(request('stats.cfm')[1]);check(stats['logs']==2 and stats['mail']==1,'Repeat logs twice but notifies once')
 h,b=request('other.cfm','smtp');check(' 500 ' in h,'SMTP failure preserves 500 response')
 stats=json.loads(request('stats.cfm')[1]);check(stats['logs']==3 and stats['mail']==2,'Log persists before SMTP failure')
 h,b=request('other.cfm','smtp');stats=json.loads(request('stats.cfm')[1]);check(stats['mail']==2,'Failed SMTP attempt consumes reservation')
 h,b=request('fatal.cfm','database');check(' 500 ' in h,'Database failure preserves friendly response');stats=json.loads(request('stats.cfm')[1]);check(stats['local']>=1,'Database failure uses local fallback')
 h,b=request('fatal.cfm','all');check(' 500 ' in h and 'Uma pausa no percurso' in b,'Database and local logger failures still respond safely')
 h,b=request('bootstrap.cfm');check(' 500 ' in h and 'BOOTSTRAP' not in b,'Bootstrap failure needs no user or session data')
 stats=json.loads(request('stats.cfm')[1]);before=stats.copy();h,b=request('reentrant.cfm');after=json.loads(request('stats.cfm')[1]);check(' 500 ' in h and before==after,'Reentrant handler skips logging and alerting')
 def make_concurrent_request(_):return request('burst.cfm')[0]
 with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:responses=list(pool.map(make_concurrent_request,range(12)))
 after=json.loads(request('stats.cfm')[1]);check(all(' 500 ' in x for x in responses) and after['mail']==before['mail']+1 and after['logs']==before['logs']+12,'Concurrent first occurrences reserve exactly one alert and retain all logs')
 h,b=request('missing-template.cfm');check(' 404 ' in h and '\nlocation:' not in h.lower(),'Missing CF template remains a true 404')
 h,b=request('fail.cfm','json');check(' 500 ' in h and 'application/json' in h and json.loads(b)['error']=='internal_error','JSON clients receive JSON 500 without HTML redirect')
 h,b=request('maratonadefloripa/fail.cfm');check(' 500 ' in h and 'Uma pausa no percurso' in b,'Microsite uses shared friendly handler')
 h,b=request('maratonadefloripa/absent.cfm');check(' 404 ' in h,'Microsite missing template remains 404')
 h,b=request('404/index.cfm?i18n_lang=en');check(' 404 ' in h and 'This path could not be found' in b and 'href="/en/"' in b,'Isolated 404 preserves English without main bootstrap')
 h,b=request('404/index.cfm?i18n_lang=es');check(' 404 ' in h and 'No encontramos este camino' in b,'Isolated 404 preserves Spanish')
 # Inject DB failure in only the fixture's optional 404 logger.
 p=root/'includes/errors/notfound.cfm';p.write_text(p.read_text().replace('datasource="runner_dba"','datasource="synthetic_missing_datasource"'))
 h,b=request('404/index.cfm');check(' 404 ' in h and 'Esse caminho' in b,'404 works without database')
 h,b=request('includes/errors/handle.cfm');check(' 404 ' in h,'Direct handler include is inaccessible')
 print(json.dumps({'ok':True,'checks':checks}))
except Exception as e:
 if 'stats' in locals():print(json.dumps({'diagnostic_stats':stats}),file=sys.stderr)
 if 'b' in locals() and not checks:print(re.sub('<[^>]+>',' ',b)[:800],file=sys.stderr)
 print(json.dumps({'ok':False,'checks':checks,'error':str(e)}));sys.exit(1)
finally:
 try:
  h,b=request('cleanup.cfm');assert 'removed' in b
 except Exception:print('Synthetic cleanup failed',file=sys.stderr)
 shutil.rmtree(root)
