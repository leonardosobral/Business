from pathlib import Path
import json,shlex,subprocess,hashlib
S=Path(__file__).resolve().parent;B=S.parents[3];n='portal/includes/seo_queue_data.cfm'
files={k+'/portal/includes/seo_queue_data.cfm':(S/k/n).read_text() for k in ['baseline','candidate']}
files['run.cfm']='''<cfsetting showdebugoutput="false"/><cfcontent type="application/json" reset="true"/>
<cfset VARIABLES.qPerfil=queryNew("is_admin","bit",[{is_admin=true}])/>
<cfset VARIABLES.businessEffectiveIsAdmin=true/>
<cfinclude template="baseline/portal/includes/seo_queue_data.cfm"/><cfset previous=duplicate(VARIABLES.seoQueueSnapshot)/>
<cfinclude template="candidate/portal/includes/seo_queue_data.cfm"/>
<cfscript>
current=VARIABLES.seoQueueSnapshot;report={legacyItems=0,newItems=0,checks=[]};
function check(required boolean value,required string label){if(!value)throw(message="Queue integrity: " & label);arrayAppend(report.checks,label);}
check(serializeJSON(previous.runs)==serializeJSON(current.runs),"dated audit snapshots unchanged");
check(arrayLen(current.items)==arrayLen(previous.items)+4,"four new items");
ids={};for(item in current.items){check(!structKeyExists(ids,item.id),"unique " & item.id);ids[item.id]=item;}
for(item in previous.items){
 check(structKeyExists(ids,item.id),"preserved " & item.id);
 if(item.id!="RR-36"){check(serializeJSON(item)==serializeJSON(ids[item.id]),"unchanged " & item.id);report.legacyItems++;}
 else {check(ids[item.id].resolved && find("desativada",ids[item.id].stateLabel),"retired shop classified explicitly");}
}
for(id in ["RR-40","RR-41","RR-42","RR-43"]){
 check(structKeyExists(ids,id),"new " & id);
 check(ids[id].resolved==(id!="RR-43"),"new status " & id);
 for(u in ids[id].urls)check(reFindNoCase("^https://roadrunners[.]run/",u.url)>0 && !reFind("[\\x00-\\x20\\x7F]",u.url),"public URL " & id);
 report.newItems++;
}
check(current.updatedAt!="" && current.updatedLabel!="","curation dated");
writeOutput(serializeJSON(report));</cfscript>'''
helpers=(B/'_codex/scripts/deploy_estudo.py').read_text().split('def bridge(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+'''
p=json.load(sys.stdin);root=Path('/var/www/business.roadrunners.run');work=Path(tempfile.mkdtemp(prefix='seo-queue-integrity-',dir=root/'_codex'));os.chmod(work,0o755)
import secrets
key=secrets.token_hex(24)
try:
 (work/'.htaccess').write_text('Require local\\n')
 (work/'Application.cfc').write_text('component{this.name="'+work.name+'";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||compare(cgi.http_x_seo_verify ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 for name,content in p.items():
  dest=work/name;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(content)
 for branch in ['baseline','candidate']:
  dest=work/branch/'includes/backend/require_admin.cfm';dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(root/'includes/backend/require_admin.cfm',dest)
 cp=subprocess.run(['curl','-sS','--fail-with-body','--max-time','40','--resolve','business.roadrunners.run:443:127.0.0.1','-H','X-SEO-Verify: '+key,'https://business.roadrunners.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=45)
 if cp.returncode:raise RuntimeError('Queue private fixture failed: '+cp.stderr[-300:])
 print(cp.stdout)
finally:shutil.rmtree(work)
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],input=json.dumps(files),capture_output=True,text=True,timeout=60);assert cp.returncode==0,cp.stderr[-1500:]
r=json.loads(cp.stdout);r={k.lower():v for k,v in r.items()};r['source_hash']=hashlib.sha256((S/'candidate'/n).read_bytes()).hexdigest();(S/'integrity-passed.json').write_text(json.dumps(r,indent=2));print(json.dumps(dict(checks=len(r['checks']),legacyItems=r['legacyitems'],newItems=r['newitems'])))
