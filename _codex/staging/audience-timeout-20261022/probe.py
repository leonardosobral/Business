"""Run on server: one bounded read-only audience diagnostic per temporary request."""
from pathlib import Path
import json,os,secrets,shutil,subprocess,sys,tempfile
mode=sys.argv[1] if len(sys.argv)>1 else 'meta'
name=sys.argv[2] if len(sys.argv)>2 else 'summary'
days=int(sys.argv[3]) if len(sys.argv)>3 else 30
assert mode in ['meta','plan','query'] and name.replace('_','').isalnum() and days in [7,30,90]
root=Path('/var/www/business.roadrunners.run');work=Path(tempfile.mkdtemp(prefix='audience-read-',dir=root/'_codex'));os.chmod(work,0o755)
key=secrets.token_hex(32)
body='''<cfsetting showdebugoutput="false" requesttimeout="40"/><cfcontent type="application/json" reset="true"/><cfscript>
out={};opts={datasource="runnerhub",timeout=18};
transaction {
 queryExecute("SET TRANSACTION READ ONLY",{},opts);
 queryExecute("SET LOCAL statement_timeout = '16s'",{},opts);
 started=getTickCount();
 try {
 MODE_BODY
 out.elapsed_ms=getTickCount()-started;
 }catch(any e){out={error_type=e.type,elapsed_ms=getTickCount()-started}; if(structKeyExists(e,"sqlState"))out.sqlstate=e.sqlState;}
}
writeOutput(serializeJSON(out));</cfscript>'''
if mode=='meta':
 code='''out.indexes=queryExecute("SELECT indexname,indexdef FROM pg_indexes WHERE schemaname='audience' AND tablename='events'",{},opts);
 out.table=queryExecute("SELECT n_live_tup,n_dead_tup,last_analyze,last_autoanalyze,pg_total_relation_size(relid) AS bytes FROM pg_stat_user_tables WHERE schemaname='audience' AND relname='events'",{},opts);
 out.work_mem=queryExecute("SHOW work_mem",{},opts);
 out.waits=queryExecute("SELECT state,wait_event_type,wait_event,count(*) FROM pg_stat_activity WHERE datname=current_database() GROUP BY state,wait_event_type,wait_event",{},opts);'''
else:
 code='''params={days={value=DAYS,cfsqltype="cf_sql_integer"},environment={value="prod",cfsqltype="cf_sql_varchar"},include_internal={value=false,cfsqltype="cf_sql_bit"},region_dimension={value="market",cfsqltype="cf_sql_varchar"},uf={value="",cfsqltype="cf_sql_varchar"},page_family={value="",cfsqltype="cf_sql_varchar"},device_class={value="",cfsqltype="cf_sql_varchar"},live_source={value="",cfsqltype="cf_sql_varchar"},live_campaign={value="",cfsqltype="cf_sql_varchar"},live_city={value="",cfsqltype="cf_sql_varchar"},live_event={value="",cfsqltype="cf_sql_varchar"}};
 dir="/var/www/business.roadrunners.run/portal/audiencia/queries/";
 sql=fileRead(dir&"NAME.sql");sql=replace(sql,"/* AUDIENCE_FILTER */",fileRead(dir&"filter.sql"));sql=replace(sql,"/* AUDIENCE_OCCUPANCY_BASE */",fileRead(dir&"occupancy_base.sql"));
 PREFIX
 q=queryExecute(sql,params,opts);out.rows=q.recordCount;
 OUTPUT'''.replace('DAYS',str(days)).replace('NAME',name).replace('PREFIX','sql="EXPLAIN (FORMAT JSON) "&sql;' if mode=='plan' else '').replace('OUTPUT','out.plan=deserializeJSON(q["QUERY PLAN"][1]);' if mode=='plan' else 'if("'+name+'"=="summary")out.summary=queryGetRow(q,1);')
try:
 (work/'.htaccess').write_text('Require local\n')
 (work/'Application.cfc').write_text('component {this.name="'+work.name+'";this.datasource="runnerhub";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.request_method!="POST"||compare(form.key ?: "","'+key+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 (work/'run.cfm').write_text(body.replace('MODE_BODY',code))
 for p in work.iterdir():os.chmod(p,0o644)
 r=subprocess.run(['curl','-sS','--max-time','35','--resolve','business.roadrunners.run:443:127.0.0.1','-X','POST','--data-urlencode','key='+key,'https://business.roadrunners.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=38)
 try:out=json.loads(r.stdout)
 except ValueError:raise RuntimeError('Diagnostic returned non-JSON; response withheld')
 print(json.dumps(out,indent=2))
finally:shutil.rmtree(work)
