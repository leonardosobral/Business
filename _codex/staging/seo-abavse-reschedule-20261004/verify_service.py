from pathlib import Path
import json,subprocess,shlex,hashlib
P=Path(__file__).resolve().parent;ROOT=P.parents[2]
name='services/EventRedirectService.cfc'
if not (P/'candidate'/name).exists():
 raise SystemExit('RED: redirect service missing; eligibility/target/reschedule contracts are not implemented')
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('runner_dba','runnerhub').replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
helpers=helpers.replace("(work/'run.cfm').write_text", '(work/\'services\').mkdir();(work/\'services/EventRedirectService.cfc\').write_text(fixture_inputs[\'service\']);(work/\'redirect.cfm\').write_text(fixture_inputs[\'include\'].replace(\'new services.EventRedirectService()\', \'createObject("component","_codex.\'+work.name+\'.services.EventRedirectService")\'))\n  body=body.replace(\'FIXTURE_COMPONENT\',\'_codex.\'+work.name+\'.services.EventRedirectService\')\n  (work/\'run.cfm\').write_text')
body='''
service=createObject("component","FIXTURE_COMPONENT");report={checks=0};
function check(required boolean condition,required string message){if(!condition)throw(message=message);report.checks++;}
check(service.isReadRequest("GET",{tag="old",i18n_lang="en",route_geometry=""}),"GET blocked");
check(service.isReadRequest("HEAD",{tag="old"}),"HEAD blocked");
for(method in ["POST","PUT","DELETE"])check(!service.isReadRequest(method,{tag="old"}),"Mutation redirected");
for(args in [{tag="old",acao="remover"},{tag="old",route_geometry="1"},{tag="old",route_geometry="0"},{tag="old",unknown="1"}])check(!service.isReadRequest("GET",args),"Action/query redirected");
transaction {
 queryExecute("CREATE TEMP TABLE tb_evento_corridas(id_evento integer,tag text,tag_301 text,ativo boolean) ON COMMIT DROP");
 queryExecute("INSERT INTO tb_evento_corridas VALUES (1,'old','new',true),(2,'new',NULL,true),(3,'inactive-source','inactive-target',true),(4,'inactive-target',NULL,false),(5,'missing','not-found',true),(6,'self','self',true),(7,'chain','old',true),(8,'external','https://evil.test',true),(9,'cycle-a','cycle-b',true),(10,'cycle-b','cycle-a',true),(11,'duplicate','new',true),(12,'duplicate','new',true),(13,'ambiguous','same-target',true),(14,'same-target',NULL,true),(15,'same-target',NULL,true)");
 check(service.resolveTarget("old")=="new","Valid redirect not resolved");
 check(service.resolveTarget("old/")=="new","Portuguese trailing slash not normalized");
 check(service.resolveTarget("old//")=="","Multiple path segments accepted");
 for(tag in ['inactive-source','missing','self','chain','external','cycle-a','cycle-b','duplicate','ambiguous','new','absent'])check(service.resolveTarget(tag)=="","Unsafe/missing redirect: " & tag);
 filter=service.validTargetSql("source_event");
 eligible=queryExecute("SELECT tag FROM tb_evento_corridas source_event WHERE " & filter);
 check(eligible.recordCount==1 && eligible.tag[1]=="old","Sitemap/resolver policies diverge");
 try {service.validTargetSql("x;DROP");throw(type="FixtureUnexpected",message="Invalid SQL alias accepted");}catch(any e){if(e.type=="FixtureUnexpected")rethrow;check(e.type=="EventRedirect.InvalidAlias","Alias validation wrong");}
 for(lang in ["pt","en","es"]){
  structClear(URL);structAppend(URL,{tag="old",route_geometry="",i18n_lang=lang});REQUEST.currentRouteParams={tag="old"};
  REQUEST.i18nBuildPath=function(required string routeKey,string languageCode=""){
   return (URL.i18n_lang=="en" ? "/en/event/" : (URL.i18n_lang=="es" ? "/es/evento/" : "/evento/")) & REQUEST.currentRouteParams.tag & "/";
  };
  savecontent variable="silent" {include "redirect.cfm";}
  if(!structKeyExists(report,"status"))throw(message="Fixture did not redirect",detail=serializeJSON({url=URL,eligible=service.isReadRequest("GET",URL),resolved=service.resolveTarget("old"),requestkeys=structKeyList(REQUEST)}));
  check(report.status==301 && report.addtoken==false,"Redirect status/token wrong");
  check(report.target==REQUEST.i18nBuildPath("event") && find("/new/",report.target),"Localized path wrong");
 }
 structClear(URL);structAppend(URL,{tag="old",acao="remover"});REQUEST.currentRouteParams={tag="old"};report.target="";
 savecontent variable="silent" {include "redirect.cfm";}
 check(report.target=="" && REQUEST.currentRouteParams.tag=="old","Action changed request state");
 transaction action="rollback";
}
proof=service.rescheduleEvidenceFor("2027-4-corrida-do-turismo-abavse-2026","2027-05-02","2027-05-02");
check(proof.eventStatus=="https://schema.org/EventRescheduled" && proof.previousStartDate=="2026-08-09","Reschedule source missing");
for(tag in ["unrelated","2026-4-corrida-do-turismo-abavse-2026"])check(structIsEmpty(service.rescheduleEvidenceFor(tag,"2027-05-02","2027-05-02")),"Unrelated inferred reschedule");
check(structIsEmpty(service.rescheduleEvidenceFor("2027-4-corrida-do-turismo-abavse-2026","2027-05-03","2027-05-02")),"Changed start ignored");
check(structIsEmpty(service.rescheduleEvidenceFor("2027-4-corrida-do-turismo-abavse-2026","2027-05-02","2027-05-03")),"Changed end ignored");
'''
remote=helpers+'\nfixture_inputs=json.load(sys.stdin);print(json.dumps(bridge(Path("/var/www/business.roadrunners.run"),fixture_inputs["body"])))'
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'body':body,'service':(P/'candidate'/name).read_text(),'include':(P/'candidate/includes/estrutura/event_redirect.cfm').read_text().replace('CGI.REQUEST_METHOD', '"GET"').replace('location(url=VARIABLES.eventRedirectPath, addtoken=false, statuscode=301);','report.target=VARIABLES.eventRedirectPath;report.addtoken=false;report.status=301;')}),capture_output=True,text=True,timeout=110)
if cp.returncode:raise RuntimeError(cp.stderr[-3000:])
r=json.loads(cp.stdout);r['hashes']={str(f.relative_to(P/'candidate')):hashlib.sha256(f.read_bytes()).hexdigest() for f in (P/'candidate').rglob('*') if f.is_file()};r['watch']=json.loads((P/'watch.json').read_text());(P/'service-passed.json').write_text(json.dumps(r,indent=2));print(json.dumps(r))
