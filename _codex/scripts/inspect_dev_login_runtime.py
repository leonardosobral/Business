"""Read-only credential propagation probe; never emits credentials or tokens."""
import json,shlex,subprocess
REMOTE=r"""
import json,os,pathlib,secrets,subprocess,tempfile
out={};nonce=secrets.token_hex(24);archive=pathlib.Path(tempfile.mkdtemp(prefix='dev-login-probe-',dir='/var/backups'));os.chmod(archive,0o700)
for host,kind in [('business.roadrunners.run','business'),('dev.roadrunners.run','dev')]:
 root=pathlib.Path('/var/www')/host;name='dev_login_probe_'+secrets.token_hex(8);stage=root/'_codex'/name
 stage.mkdir(mode=0o755);(stage/'.htaccess').write_text('Require local\n')
 code='''<cfsetting showdebugoutput="false" requesttimeout="120"><cfscript>
 if(!listFind("127.0.0.1,::1",CGI.remote_addr)||!structKeyExists(CGI,"http_x_dev_probe")||CGI.http_x_dev_probe!="'''+nonce+'''"){cfheader(statuscode=404);abort;}
 cfcontent(type="application/json",reset=true);
 '''
 if kind=='business':
  code+='''businessLocalConfig={};include "/config/business.local.cfm";
 localSecret=businessLocalConfig.notificationDispatchSecret?:"";
 report={configured=len(APPLICATION.notificationDispatch.secret)>=32,matches_file=compare(APPLICATION.notificationDispatch.secret,localSecret)==0,
 runtime_default=compareNoCase(APPLICATION.notificationDispatch.secret,hash("RoadRunners::handoff::roadrunners.run::v1","SHA-256"))==0};
 users=queryExecute("SELECT usr.id,usr.email,coalesce(usr.is_admin,false) is_admin,coalesce(usr.is_dev,false) is_dev,
 coalesce(gest.ativo,true) gestao_ativo,coalesce(gest.excluido,false) gestao_excluido,true has_active_page
 FROM tb_usuarios usr LEFT JOIN tb_usuarios_gestao gest ON gest.id_usuario=usr.id WHERE usr.id IN (142,143272) ORDER BY usr.id",{},{datasource="runner_dba"});
 handoff=new services.BusinessDevLogin().createHandoff(queryGetRow(users,1),queryGetRow(users,2),APPLICATION.notificationDispatch.secret,"POST","probe-csrf","probe-csrf","1");
 cfhttp(url=handoff.url,method="get",redirect=false,result="exchange",timeout=20,throwonerror=false);
 report.exchange_status=val(exchange.statusCode);
 report.exchange_location=structKeyExists(exchange.responseHeader,"Location")?reReplace(exchange.responseHeader.Location,"[?].*$",""):"";
 report.identity_cookie_for_target=structKeyExists(exchange.responseHeader,"Set-Cookie") AND findNoCase("id=143272",serializeJSON(exchange.responseHeader["Set-Cookie"]))>0;
 function cookieLines(value){var lines=[];if(isSimpleValue(value)){arrayAppend(lines,value & "");}else if(isArray(value)){for(var item in value)arrayAppend(lines,cookieLines(item),true);}else if(isStruct(value)){for(var key in value)arrayAppend(lines,cookieLines(value[key]),true);}return lines;}
 receivedCookies=cookieLines(exchange.responseHeader["Set-Cookie"]);
 sessionPairs=[];for(line in receivedCookies){pair=listFirst(line,";");if(!reFindNoCase("^id=",pair))arrayAppend(sessionPairs,pair);}
 cfhttp(url="https://dev.roadrunners.run/atleta/",method="get",redirect=true,result="profile",timeout=30,throwonerror=false){cfhttpparam(type="header",name="Cookie",value=arrayToList(sessionPairs,"; ") & "; id=142");}
 profileIds=reMatch("USR[0-9]+",profile.fileContent & "");report.profile_status=val(profile.statusCode);report.authenticated_target=profileIds;report.target_profile_visible=findNoCase("Givaldo Oliveira do Nascimento",profile.fileContent & "")>0;report.return_button=find("?action=dev_auth_back",profile.fileContent & "")>0;
 cfhttp(url="https://dev.roadrunners.run/?action=dev_auth_back",method="get",redirect=false,result="returned",timeout=30,throwonerror=false){cfhttpparam(type="header",name="Cookie",value=arrayToList(sessionPairs,"; ") & "; id=143272");}
 report.return_status=val(returned.statusCode);
 cfhttp(url="https://dev.roadrunners.run/atleta/",method="get",redirect=true,result="adminProfile",timeout=30,throwonerror=false){cfhttpparam(type="header",name="Cookie",value=arrayToList(sessionPairs,"; ") & "; id=143272");}
 report.restored_admin=reMatch("USR[0-9]+",adminProfile.fileContent & "");
 writeOutput(serializeJSON(report));'''
 else:
  code+='''localStravaConfig={};include "/config/strava.local.cfm";
 report={configured=APPLICATION.handoff.configured,base=APPLICATION.baseCanonica,matches_file=compare(APPLICATION.handoff.secret,localStravaConfig.handoffSecret?:"")==0,
 runtime_default=compareNoCase(APPLICATION.handoff.secret,hash("RoadRunners::handoff::roadrunners.run::v1","SHA-256"))==0};
 rows=queryExecute("SELECT usr.id,coalesce(usr.is_admin,false) is_admin,pag.tag FROM tb_usuarios usr JOIN tb_paginas_usuarios pu ON pu.id_usuario=usr.id JOIN tb_paginas pag ON pag.id_pagina=pu.id_pagina WHERE usr.id IN (142,143272) ORDER BY usr.id",{},{});
 report.lookup_ids=[];for(row in rows) arrayAppend(report.lookup_ids,row.id);
 writeOutput(serializeJSON(report));'''
 code+='</cfscript>'
 try:
  (stage/'probe.cfm').write_text(code);os.chmod(stage/'probe.cfm',0o644)
  p=subprocess.run(['curl','--silent','--show-error','--max-time','110','--resolve',host+':443:127.0.0.1','--header','X-Dev-Probe: '+nonce,'https://'+host+'/_codex/'+name+'/probe.cfm'],capture_output=True,timeout=115)
  raw=p.stdout;(archive/(kind+'.txt')).write_bytes(raw);os.chmod(archive/(kind+'.txt'),0o600)
  try:out[kind]={k.lower():v for k,v in json.loads(raw).items()}
  except Exception:out[kind]={'error':'Non-JSON response; private artifact retained'}
 finally:stage.rename(archive/kind)
out['archive']=str(archive);print(json.dumps(out))
"""
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(REMOTE)],capture_output=True,timeout=150)
try:print(json.dumps(json.loads(p.stdout),ensure_ascii=False))
except Exception:print(json.dumps({'ok':False,'error':'Probe transport failed; output suppressed'}))
