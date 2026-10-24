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
 sql=fileRead(dir&"NAME.sql");sql=replace(sql,"/* AUDIENCE_FILTER */",toString(binaryDecode("V0lUSCByZWdpb25hbCBBUyBOT1QgTUFURVJJQUxJWkVEICgKICAgIFNFTEVDVCBlLiosIGNvYWxlc2NlKG51bGxpZihDQVNFIDpyZWdpb25fZGltZW5zaW9uCiAgICAgICAgV0hFTiAndmlzaXRvcicgVEhFTiB2aXNpdG9yX3VmIFdIRU4gJ3Byb2ZpbGUnIFRIRU4gcHJvZmlsZV91ZgogICAgICAgIFdIRU4gJ2NvbnRleHQnIFRIRU4gY29udGV4dF91ZiBFTFNFIG1hcmtldF91ZiBFTkQsICcnKSwgcmVwZWF0KCctJywgMikpIEFTIGF1ZGllbmNlX3VmCiAgICBGUk9NIGF1ZGllbmNlLmV2ZW50cyBlCiAgICBXSEVSRSBlLm9jY3VycmVkX2F0ID49IChkYXRlX3RydW5jKCdkYXknLCBub3coKSBBVCBUSU1FIFpPTkUgJ0FtZXJpY2EvU2FvX1BhdWxvJykKICAgICAgICAtIChDQVNUKDpkYXlzIEFTIGludGVnZXIpIC0gMSkgKiBpbnRlcnZhbCAnMSBkYXknKSBBVCBUSU1FIFpPTkUgJ0FtZXJpY2EvU2FvX1BhdWxvJwogICAgICBBTkQgZS5vY2N1cnJlZF9hdCA8PSBub3coKQogICAgICBBTkQgZS5lbnZpcm9ubWVudCA9IDplbnZpcm9ubWVudAogICAgICBBTkQgKDppbmNsdWRlX2ludGVybmFsID0gdHJ1ZSBPUiBlLmlzX2ludGVybmFsID0gZmFsc2UpCiksIGZpbHRlcmVkIEFTIE5PVCBNQVRFUklBTElaRUQgKAogICAgU0VMRUNUICogRlJPTSByZWdpb25hbAogICAgV0hFUkUgKDp1ZiA9ICcnIE9SIGF1ZGllbmNlX3VmID0gOnVmKQogICAgICBBTkQgKDpwYWdlX2ZhbWlseSA9ICcnIE9SIHBhZ2VfZmFtaWx5ID0gOnBhZ2VfZmFtaWx5KQogICAgICBBTkQgKDpkZXZpY2VfY2xhc3MgPSAnJyBPUiBkZXZpY2VfY2xhc3MgPSA6ZGV2aWNlX2NsYXNzKQopLCBwYWdlX2lkZW50aXR5IEFTICgKICAgIC0tIE9ubHkgdGhlIG9yaWdpbmFsIHBhZ2Ugb3BlbmluZyBpZGVudGlmaWVzIHRoZSBwYWdlLCBuZXZlciB2aWRlbyBtb2RhbHMuCiAgICAtLSBSZXNvbHZlIGJlZm9yZSBVRiBmaWx0ZXJpbmcgc28gbGF0ZXIgc2xvdCBjb250ZXh0cyBrZWVwIHRoYXQgc2FtZSBpZGVudGl0eS4KICAgIFNFTEVDVCBwYWdlX3ZpZXdfaWQsIG1heChjb250ZW50X3R5cGUpIEFTIHBhZ2VfY29udGVudF90eXBlLAogICAgICAgICAgIG1heChjb250ZW50X2lkKSBBUyBwYWdlX2NvbnRlbnRfaWQKICAgIEZST00gcmVnaW9uYWwgV0hFUkUgZXZlbnRfa2luZCA9ICdwYWdlX3ZpZXcnCiAgICBHUk9VUCBCWSBwYWdlX3ZpZXdfaWQKKSwgcGFnZV9tZXRyaWNzIEFTICgKICAgIFNFTEVDVCBmLnBhZ2Vfdmlld19pZCwgdmlzaXRvcl9pZCwgc2Vzc2lvbl9pZCwgcGFnZV9mYW1pbHksIHBhZ2VfcGF0aCwKICAgICAgICAgICBjb2FsZXNjZShpLnBhZ2VfY29udGVudF90eXBlLCAnJykgQVMgcGFnZV9jb250ZW50X3R5cGUsCiAgICAgICAgICAgY29hbGVzY2UoaS5wYWdlX2NvbnRlbnRfaWQsICcnKSBBUyBwYWdlX2NvbnRlbnRfaWQsCiAgICAgICAgICAgc291cmNlLCBtZWRpdW0sIGNhbXBhaWduLCBjcmVhdGl2ZSwKICAgICAgICAgICBib29sX29yKGV2ZW50X2tpbmQgPSAncGFnZV92aWV3JykgQVMgaGFzX3ZpZXcsCiAgICAgICAgICAgY29hbGVzY2UobWF4KGFjdGl2ZV9tcykgRklMVEVSIChXSEVSRSBldmVudF9raW5kID0gJ3BhZ2VfZW5nYWdlbWVudCcpLCAwKSBBUyBhY3RpdmVfbXMKICAgIEZST00gZmlsdGVyZWQgZiBMRUZUIEpPSU4gcGFnZV9pZGVudGl0eSBpIE9OIGkucGFnZV92aWV3X2lkID0gZi5wYWdlX3ZpZXdfaWQKICAgIEdST1VQIEJZIGYucGFnZV92aWV3X2lkLCB2aXNpdG9yX2lkLCBzZXNzaW9uX2lkLCBwYWdlX2ZhbWlseSwgcGFnZV9wYXRoLAogICAgICAgICAgICAgaS5wYWdlX2NvbnRlbnRfdHlwZSwgaS5wYWdlX2NvbnRlbnRfaWQsCiAgICAgICAgICAgICBzb3VyY2UsIG1lZGl1bSwgY2FtcGFpZ24sIGNyZWF0aXZlCikK","base64")));sql=replace(sql,"/* AUDIENCE_OCCUPANCY_BASE */",fileRead(dir&"occupancy_base.sql"));
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
