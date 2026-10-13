<!--- Execute only from the private loopback runner; temporary tables roll back. --->
<cfif NOT listFind("127.0.0.1,::1",CGI.REMOTE_ADDR) OR CGI.REQUEST_METHOD NEQ "POST"><cfheader statuscode="404"/><cfabort/></cfif>
<cfsetting showdebugoutput="false" requesttimeout="60"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfscript>
checks=0; failures=[];
function check(required boolean condition,required string label){checks++;if(!arguments.condition)arrayAppend(failures,arguments.label);}
function db(required string sql,struct params={}){return queryExecute(arguments.sql,arguments.params,{datasource='runner_dba'});}
candidate=structKeyExists(URL,'candidate') && URL.candidate=='1';
helper=candidate?'/__vicky_audit_stage/administracao/vicky/includes/audit_helpers.cfm':'/administracao/vicky/includes/audit_helpers.cfm';
hasFeature=fileExists(expandPath(helper));
if(hasFeature) include helper;
function loadAudit(struct params={}){
    if(hasFeature)return vickyAuditLoad(vickyAuditState(arguments.params),900001);
    // Execute the real legacy listing SQL, including its 100-run truncation.
    var source=fileRead(expandPath('/administracao/vicky/includes/backend.cfm'));
    var block=reMatch('(?s)<cfquery name="qVickyRuns"[^>]*>.*?</cfquery>',source)[1];
    var sql=reReplace(reReplace(block,'(?s)^.*?>|</cfquery>$','','all'),'<cfqueryparam[^>]*/>',':since','all');
    var runs=db(sql,{since={value=dateAdd('d',-30,now()),cfsqltype='cf_sql_timestamp'}});
    return {users=runs,turns=queryNew(''),tools=queryNew(''),userTotal=runs.recordCount,turnTotal=0,state={userId=0},selected=queryNew('')};
}
try{
transaction {
    db("CREATE TEMP TABLE tb_usuarios AS SELECT * FROM public.tb_usuarios WITH NO DATA");
    db("CREATE TEMP TABLE tb_paginas AS SELECT * FROM public.tb_paginas WITH NO DATA");
    db("CREATE TEMP TABLE tb_paginas_usuarios AS SELECT * FROM public.tb_paginas_usuarios WITH NO DATA");
    db("CREATE TEMP TABLE tb_vicky_conversa AS SELECT * FROM public.tb_vicky_conversa WITH NO DATA");
    db("CREATE TEMP TABLE tb_vicky_mensagem AS SELECT * FROM public.tb_vicky_mensagem WITH NO DATA");
    db("CREATE TEMP TABLE tb_vicky_execucao AS SELECT * FROM public.tb_vicky_execucao WITH NO DATA");
    db("CREATE TEMP TABLE tb_vicky_tool_call AS SELECT * FROM public.tb_vicky_tool_call WITH NO DATA");
    db("CREATE TEMP TABLE tb_vicky_audit_access AS SELECT * FROM public.tb_vicky_audit_access WITH NO DATA");
    db("INSERT INTO tb_usuarios(id,name,imagem_usuario,strava_profile) SELECT n,'Atleta '||n,'/assets/user.png','' FROM generate_series(1,31) n");
    db("INSERT INTO tb_paginas(id_pagina,nome,tag_prefix,path_imagem) VALUES(1,'Nome publico','atleta','teste.png'),(2,'Outra pagina','atleta','outra.png')");
    db("INSERT INTO tb_paginas_usuarios(id_usuario,id_pagina) VALUES(1,1),(1,2)");
    db("INSERT INTO tb_vicky_conversa(id_vicky_conversa,id_usuario,channel) SELECT n,n,CASE WHEN n=2 THEN 'whatsapp' ELSE 'web' END FROM generate_series(1,31)n");
    db("INSERT INTO tb_vicky_execucao(id_vicky_execucao,id_usuario,id_vicky_conversa,id_mensagem_usuario,id_mensagem_assistente,created_at,status,model,tool_calls,input_tokens,output_tokens,latency_ms,error_code,fallback_reason) SELECT n,CASE WHEN n<=45 THEN 1 ELSE 2+(n-46)%30 END,CASE WHEN n<=45 THEN 1 ELSE 2+(n-46)%30 END,n*2,n*2+1,now()-n*interval '1 minute',CASE WHEN n%4=0 THEN 'fallback' ELSE 'completed' END,'test-model',1,10,5,100,CASE WHEN n%4=0 THEN 'test_error' ELSE NULL END,NULL FROM generate_series(1,155)n");
    db("INSERT INTO tb_vicky_mensagem(id_vicky_mensagem,content,created_at) SELECT id_mensagem_usuario,'<script>user</script> '||id_vicky_execucao,created_at FROM tb_vicky_execucao UNION ALL SELECT id_mensagem_assistente,'Resposta '||id_vicky_execucao,created_at+interval '1 second' FROM tb_vicky_execucao");
    db("INSERT INTO tb_vicky_tool_call(id_vicky_tool_call,id_vicky_execucao,tool_name,status,arguments_summary,result_summary,latency_ms,error_code,created_at) SELECT id_vicky_execucao,id_vicky_execucao,'test_tool','completed','{}','{}',10,NULL,created_at FROM tb_vicky_execucao");
    db("INSERT INTO tb_vicky_execucao(id_vicky_execucao,id_usuario,id_vicky_conversa,id_mensagem_usuario,id_mensagem_assistente,created_at,status,model,tool_calls,input_tokens,output_tokens,latency_ms,error_code,fallback_reason) VALUES(1000,31,31,NULL,NULL,now()-interval '100 days','fallback','test-model',0,0,0,0,'old_error',NULL)");
    a=loadAudit();
    check(a.userTotal==31,'all distinct users are counted before the page limit, not last 100 runs');
    check(a.users.recordCount==25,'user list is bounded to 25 unique users');
    check(a.users.id_usuario[1]==1 && a.users.id_usuario[2]==2,'users are ordered by their latest interaction');
    check(listLen(listRemoveDuplicates(valueList(a.users.id_usuario)))==a.users.recordCount,'multiple turns and duplicate profile pages do not duplicate a user');
    check(db('SELECT count(*) total FROM tb_vicky_audit_access').total==0,'listing metadata does not access private content');
    a=loadAudit({usuario=1});
    check(a.turnTotal==45 && a.turns.recordCount==20,'selected user loads only the newest 20 interactions');
    if(a.turns.recordCount){
      check(a.turns.id_vicky_execucao[1]==20 && a.turns.id_vicky_execucao[20]==1,'newest batch is displayed oldest to newest');
      check(find('<script>',a.turns.user_content[1])>0,'message content remains data until escaped by the view');
      check(a.tools.recordCount==20,'tools are scoped to exactly the opened batch');
    }else{check(false,'newest batch is displayed oldest to newest');check(false,'message content remains data until escaped by the view');check(false,'tools are scoped to exactly the opened batch');}
    check(db('SELECT count(*) total FROM tb_vicky_audit_access').total==20,'every opened interaction receives an audit record');
    check(db('SELECT count(*) total FROM tb_vicky_audit_access WHERE id_operador=900001').total==20,'logged accesses identify the operator');
    snapshot=hasFeature?a.state.snapshot:155;
    a=loadAudit({usuario=1,historico=2,snapshot=snapshot});
    check(a.turns.recordCount==20 && a.turnTotal==45,'older history remains bounded');
    check(a.turns.recordCount && a.turns.id_vicky_execucao[1]==40 && a.turns.id_vicky_execucao[20]==21,'older batch neither duplicates nor skips initial turns');
    db("INSERT INTO tb_vicky_execucao(id_vicky_execucao,id_usuario,id_vicky_conversa,id_mensagem_usuario,id_mensagem_assistente,created_at,status,model,tool_calls,input_tokens,output_tokens,latency_ms,error_code,fallback_reason) VALUES(1001,1,1,NULL,NULL,now(),'started','test-model',0,0,0,0,NULL,NULL)");
    a=loadAudit({usuario=1,historico=3,snapshot=snapshot});
    check(a.turns.recordCount==5 && a.turns.id_vicky_execucao[1]==45,'snapshot prevents new turns shifting pagination');
    a=loadAudit({usuario=1,situacao='falhas',snapshot=snapshot});
    if(a.turns.recordCount){
      cursor=a.turns.id_vicky_execucao[1];
      // Add >20 issues, then let a newer pending execution complete between pages.
      db("UPDATE tb_vicky_execucao SET status='started' WHERE id_usuario=1");
      first=loadAudit({usuario=1,situacao='falhas',snapshot=snapshot});
      cursor=first.turns.id_vicky_execucao[1];
      db("UPDATE tb_vicky_execucao SET status='completed' WHERE id_vicky_execucao=1");
      older=loadAudit({usuario=1,situacao='falhas',snapshot=snapshot,historico=2,antes=cursor});
      check(older.turns.recordCount==20 && older.turns.id_vicky_execucao[20]==21,'history cursor does not skip a turn when a pending run completes');
      db("UPDATE tb_vicky_execucao SET status=CASE WHEN id_vicky_execucao%4=0 THEN 'fallback' ELSE 'completed' END WHERE id_usuario=1 AND id_vicky_execucao<=155");
    }else check(false,'history cursor does not skip a turn when a pending run completes');
    a=loadAudit({busca='Nome publico'});
    check(a.userTotal==1 && a.users.id_usuario[1]==1,'search uses the public profile name');
    a=loadAudit({busca='31'});check(a.userTotal==1,'search accepts an exact user id');
    a=loadAudit({busca="' OR 1=1 --"});check(a.userTotal==0,'search input is parameterized');
    a=loadAudit({canal='whatsapp'});check(a.userTotal==1 && a.users.id_usuario[1]==2,'channel filter scopes the users');
    a=loadAudit({usuario=1,situacao='falhas'});check(a.turnTotal==12,'issues filter scopes selected interactions, including the newly started turn');
    a=loadAudit({pagina_usuarios=2});check(a.users.recordCount==6,'second user page contains the remaining users');
    a=loadAudit({usuario=999});check(a.selected.recordCount==0 && a.turns.recordCount==0,'unknown user cannot leak another conversation');
    a=loadAudit({execucao=45});check(a.state.userId==1 && a.turns.recordCount==6,'legacy execution link opens the right user and historical batch');
    a=loadAudit({execucao=1000});check(a.turns.recordCount==4 && listFind(valueList(a.turns.id_vicky_execucao),'1000')>0,'legacy link outside the selected period still opens that execution');
    a=loadAudit({execucao=4,canal='web',situacao='falhas'});
    check(a.state.channel=='web' && a.state.status=='falhas','direct execution links preserve filters matching their target');
    if(hasFeature){
      s=vickyAuditState({usuario='1 OR 1=1',periodo=400,canal='evil',situacao='evil',historico='-2',pagina_usuarios='9999999999999999999'});
      check(s.userId==0 && s.period==30 && s.channel=='' && s.status=='todos' && s.historyPage==1 && s.userPage==1,'malformed filters fall back safely');
      link=vickyAuditUrl(vickyAuditState({usuario=1,busca='Ana & Bia',canal='web',periodo=7}),{historico=2});
      check(find('busca=Ana%20%26%20Bia',link)>0 && find('usuario=1',link)>0 && find('periodo=7',link)>0,'navigation preserves filters with URL escaping');
      check(vickyAuditAvatar('javascript:alert(1)')=='/assets/user.png' && vickyAuditAvatar('//evil.test/pixel')=='/assets/user.png','unsafe avatar schemes are rejected');
      check(vickyAuditAvatar('https://example.test/avatar.jpg')=='https://example.test/avatar.jpg','HTTPS avatars are preserved');
      check(vickyAuditStatus('fallback').label=='Resposta alternativa' && vickyAuditStatus('completed').label=='Concluída','technical statuses receive readable labels');
    }else{for(i=1;i<=5;i++)check(false,'safe filters, links, avatars and friendly statuses');}
    if(hasFeature){
      VARIABLES.vickyAudit=loadAudit({usuario=1});
      view=candidate?'/__vicky_audit_stage/administracao/vicky/includes/audit_view.cfm':'/administracao/vicky/includes/audit_view.cfm';
      if(fileExists(expandPath(view))){
        savecontent variable='rendered' {include view;}
        check(find('data-vp-turn=',rendered)>0 && find('data-vp-user=',rendered)>0,'rendered page offers a grouped user list and chat timeline');
        check(!find('<script>user</script>',rendered) && reFindNoCase('(&lt;|&##x3c;|&##60;)script',rendered)>0,'private message HTML is escaped, not executed');
        check(find('Carregar interações anteriores',rendered)>0 && find('historico=2',canonicalize(rendered,false,false))>0,'rendered page links to the next bounded history batch');
        check(find('data-vp-older',rendered)>0 && find('Detalhes técnicos',rendered)>0,'older-history control and technical details are accessible');
        VARIABLES.vickyAudit=loadAudit();savecontent variable='rendered' {include view;}
        check(!reFindNoCase('(&lt;|&##x3c;|&##60;)script',rendered),'unselected user list has no private message content');
      }else{for(i=1;i<=5;i++)check(false,'chat view, escaped messages, progressive history and metadata privacy');}
    }
    transaction action='rollback';
}
writeOutput(serializeJSON({success=arrayLen(failures)==0,checks=checks,failures=failures,feature=hasFeature}));
}catch(any e){cfheader(statuscode=500);writeOutput(serializeJSON({success=false,message=e.message,detail=e.detail,line=e.tagContext[1].line}));}
</cfscript>
