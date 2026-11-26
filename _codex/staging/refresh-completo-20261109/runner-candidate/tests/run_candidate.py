from pathlib import Path
import importlib.util,json,sys
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business');P=Path(__file__).resolve().parents[1]
s=importlib.util.spec_from_file_location('q',ROOT/'_codex/staging/fechamento-q3-20261109/comparativo-profissional/inspect.py');h=importlib.util.module_from_spec(s);s.loader.exec_module(h)
def instrument(source):
 # Only ledger operations are bypassed; the guard, transaction, SQL transport,
 # quotas and serialization execute unchanged against the real CF datasource.
 start=source.index('        var cell=one(db(',source.index('public struct function execute'))
 end=source.index('\n        if(cell.version',start)
 source=source[:start]+'        var cell={id="1",content=arguments.sql,version=arguments.version,cell_type="code",lang="sql"};'+source[end:]
 start=source.index('        var run=one(db(',source.index('public struct function execute'))
 end=source.index('\n        var started=',start)
 source=source[:start]+'        var run={id="1"};'+source[end:]
 start=source.index('        var params={id=idp(run.id)',source.index('public struct function execute'))
 end=source.index('\n    }\n    public struct function freeze',start)
 source=source[:start]+'        return {"status":len(errorMessage)?"error":"ok","row_count":count,"truncated":truncated,"result_json":resultJSON,"error_message":errorMessage};'+source[end:]
 return source
CF='''
function resultCheck(required string name,required boolean ok,string detail="") {arrayAppend(report.checks,{"name":name,"ok":ok,"detail":detail});}
report={"checks":[]};
subject=createObject("component",payloadPackage&".Subject").init();
executor=createObject("component",payloadPackage&".Instrumented").init();
large=executor.execute(1,1,"SELECT jsonb_build_object('text',lpad('',4500000,'x'),'big',9007199254740993::bigint,'decimal',12345678901234567890.1234567890123456789::numeric,'nothing',NULL,'unicode','ação') AS payload",139);
resultCheck("one JSON row over datasource cap is complete",large.status=="ok" && large.row_count==1 && !large.truncated && len(large.result_json)>4500000 && isJSON(large.result_json) && len(deserializeJSON(large.result_json).rows[1].payload.text)==4500000,"status="&large.status&" length="&len(large.result_json)&" error="&large.error_message);
resultCheck("bigint decimal NULL and unicode remain exact",find('9007199254740993',large.result_json)>0 && find('12345678901234567890.1234567890123456789',large.result_json)>0 && find('"nothing": null',large.result_json)>0 && find('ação',large.result_json)>0);
limited=executor.execute(1,1,"SELECT generate_series(1,1001) AS n",139);
resultCheck("1001 rows truncate to first 1000",limited.status=="ok" && limited.row_count==1000 && limited.truncated && isJSON(limited.result_json));
budget=executor.execute(1,1,"SELECT n,lpad('',2600000,'x') AS text FROM generate_series(1,2) AS n",139);
resultCheck("5MB payload budget excludes whole overflowing row",budget.status=="ok" && budget.row_count==1 && budget.truncated && len(budget.result_json)>2600000 && len(budget.result_json)<2700000 && isJSON(budget.result_json),"rows="&budget.row_count&" length="&len(budget.result_json)&" error="&budget.error_message);
oversize=executor.execute(1,1,"SELECT lpad('',5000001,'x') AS text",139);
resultCheck("single row above budget returns empty complete JSON and truncates",oversize.status=="ok" && oversize.row_count==0 && oversize.truncated && isJSON(oversize.result_json));
empty=executor.execute(1,1,"SELECT 1 AS n WHERE false",139);
resultCheck("zero rows preserve columns",empty.status=="ok" && empty.row_count==0 && !empty.truncated && isJSON(empty.result_json) && find('"n"',lCase(empty.result_json))>0);
raw=subject.getRun(226);
expected=queryExecute("SELECT char_length(result::text) AS chars,octet_length(result::text) AS bytes,encode(sha256(convert_to(result::text,'UTF8')),'hex') AS sha FROM estudo.notebook_runs WHERE id=226",{}, {datasource="runner_dba",timeout=10});
resultCheck("getRun reconstructs frozen 4.3MB result",expected.bytes[1]>4300000 && lCase(hash(raw.result_json,"SHA-256","UTF-8"))==expected.sha[1] && isJSON(raw.result_json) && raw.id=="226" && raw.cell_id=="384" && raw.status=="ok" && raw.frozen && !raw.truncated && raw.row_count==1 && raw.error_message=="","chars="&len(raw.result_json)&" expected_chars="&expected.chars[1]&" bytes="&expected.bytes[1]&" sha="&lCase(hash(raw.result_json,"SHA-256","UTF-8"))&" expected_sha="&expected.sha[1]&" frozen="&raw.frozen&" truncated="&raw.truncated&" status="&raw.status&" rows="&raw.row_count&" error="&raw.error_message&" ids="&raw.id&","&raw.cell_id);
nullRows=queryExecute("SELECT id FROM estudo.notebook_runs WHERE result IS NULL AND status='error' ORDER BY id DESC LIMIT 1",{}, {datasource="runner_dba",timeout=10});
if(nullRows.recordCount){nullRun=subject.getRun(nullRows.id[1]);resultCheck("getRun preserves NULL result and metadata",structKeyExists(nullRun,"result_json") && nullRun.result_json=="" && structKeyExists(nullRun,"error_message") && structKeyExists(nullRun,"finished_at") && structKeyExists(nullRun,"frozen_at") && structKeyExists(nullRun,"title") && structKeyExists(nullRun,"note"),"status="&nullRun.status);}
else resultCheck("getRun preserves NULL result and metadata",false,"No existing NULL result fixture; no fixture was persisted.");
manyColumns=[];for(col=1;col<=101;col++)arrayAppend(manyColumns,"1 AS c"&col);
wide=executor.execute(1,1,"SELECT "&arrayToList(manyColumns,","),139);
resultCheck("101 columns are rejected",wide.status=="error" && find("100 colunas",wide.error_message)>0);
guarded=false;try{executor.execute(1,1,"SELECT pg_sleep(1)",139);}catch(Study.Validation blocked){guarded=true;}
resultCheck("SQL function guard remains active",guarded);
queryExecute("SELECT current_user AS user_name",{}, {datasource="runner_dba",timeout=10});
resultCheck("role restored after test transactions",queryExecute("SELECT current_user AS u",{}, {datasource="runner_dba",timeout=10}).u[1]=="runner_dba");
'''
BODY=r'''
import secrets
work=Path(tempfile.mkdtemp(prefix='notebook-runner-20261109-',dir=ROOT/'_codex'));os.chmod(work,0o755)
token=secrets.token_hex(24)
try:
 (work/'.htaccess').write_text('Require local\n')
 (work/'Application.cfc').write_text('component {this.name="'+work.name+'";this.datasource="runner_dba";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.request_method!="POST"||compare(form.key ?: "","'+token+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 (work/'Subject.cfc').write_text(payload['source']);(work/'Instrumented.cfc').write_text(payload['instrumented'])
 cf='payloadPackage="_codex.'+work.name+'";'+payload['cf']
 (work/'run.cfm').write_text('<cfsetting requesttimeout="90" showdebugoutput="false"/><cfcontent type="application/json" reset="true"/><cftry><cfscript>'+cf+'writeOutput(serializeJSON(report));</cfscript><cfcatch><cfheader statuscode="500"/><cfoutput>#serializeJSON({error=cfcatch.message,detail=cfcatch.detail})#</cfoutput></cfcatch></cftry>')
 p=subprocess.run(['curl','-sS','--max-time','95','--resolve','business.roadrunners.run:443:127.0.0.1','-X','POST','--data-urlencode','key='+token,'https://business.roadrunners.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=100)
 result=json.loads(p.stdout)
finally:
 shutil.rmtree(work)
print(json.dumps({'result':result,'temporary_directory_removed':not work.exists()}))
'''
if __name__=='__main__':
 which=sys.argv[1] if len(sys.argv)>1 else 'candidate'
 source=(P/which/'estudo/includes/StudyNotebook.cfc').read_text()
 result=h.h.h.remote(BODY,{'source':source,'instrumented':instrument(source),'cf':CF})
 out=P/('test-'+which+'.json');out.write_text(json.dumps(result,ensure_ascii=False,indent=2));print(json.dumps(result,ensure_ascii=False,indent=2))
 if 'error' in result['result'] or not all(x['ok'] for x in result['result'].get('CHECKS',result['result'].get('checks',[]))):sys.exit(1)
