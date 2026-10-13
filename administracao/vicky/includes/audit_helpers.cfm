<cfscript>
function vickyAuditInteger(any value='',numeric fallback=0,numeric maximum=2147483647){
    var raw=trim(arguments.value&'');
    if(!reFind('^[0-9]{1,10}$',raw) || val(raw)>arguments.maximum)return arguments.fallback;
    return val(raw);
}
function vickyAuditState(required struct input){
    var p=arguments.input;
    var state={period=30,search='',channel='',status='todos',userId=0,executionId=0,userPage=1,historyPage=1,snapshot=0,beforeId=0};
    if(structKeyExists(p,'periodo') && listFind('7,30,90',p.periodo&''))state.period=val(p.periodo);
    if(structKeyExists(p,'busca'))state.search=left(trim(p.busca&''),100);
    if(structKeyExists(p,'canal') && listFindNoCase('web,manychat,whatsapp,instagram',p.canal&''))state.channel=lCase(p.canal&'');
    if(structKeyExists(p,'situacao') && listFindNoCase('todos,falhas',p.situacao&''))state.status=lCase(p.situacao&'');
    if(structKeyExists(p,'usuario'))state.userId=vickyAuditInteger(p.usuario);
    if(structKeyExists(p,'execucao'))state.executionId=vickyAuditInteger(p.execucao);
    if(structKeyExists(p,'pagina_usuarios'))state.userPage=max(1,vickyAuditInteger(p.pagina_usuarios,1,100000));
    if(structKeyExists(p,'historico'))state.historyPage=max(1,vickyAuditInteger(p.historico,1,100000));
    if(structKeyExists(p,'snapshot'))state.snapshot=vickyAuditInteger(p.snapshot);
    if(structKeyExists(p,'antes'))state.beforeId=vickyAuditInteger(p.antes);
    return state;
}
function vickyAuditUrl(required struct state,struct changes={}){
    var p={secao='auditoria',periodo=arguments.state.period,busca=arguments.state.search,canal=arguments.state.channel,situacao=arguments.state.status,usuario=arguments.state.userId,pagina_usuarios=arguments.state.userPage,historico=arguments.state.historyPage,snapshot=arguments.state.snapshot,antes=arguments.state.beforeId};
    structAppend(p,arguments.changes,true);
    var parts=[];
    for(var key in ['secao','periodo','busca','canal','situacao','usuario','pagina_usuarios','historico','snapshot','antes','execucao']){
        if(structKeyExists(p,key) && len(p[key]&'') && (listFind('usuario,snapshot,antes,execucao',key)==0 || val(p[key])>0))arrayAppend(parts,key&'='&replace(urlEncodedFormat(p[key]&''),'+','%20','all'));
    }
    return '?'&arrayToList(parts,'&')&'##vp-audit-chat';
}
function vickyAuditAvatar(any value=''){
    var image=trim(arguments.value&'');
    if(len(image)>1000 || reFind('[\x00-\x20\\]',image))return '/assets/user.png';
    if(reFindNoCase('^https://[^/@]+(/|$)',image) || reFind('^/[a-zA-Z0-9_-]',image))return image;
    return '/assets/user.png';
}
function vickyAuditStatus(required string value){
    switch(arguments.value){
      case 'completed':return {label='Concluída',tone='success'};
      case 'started':return {label='Em processamento',tone='info'};
      case 'fallback':return {label='Resposta alternativa',tone='warning'};
      case 'blocked':return {label='Bloqueada por segurança',tone='danger'};
      case 'failed':case 'error':return {label='Falha',tone='danger'};
      default:return {label=arguments.value,tone='secondary'};
    }
}
function vickyAuditProfileSql(){
    return "SELECT u.id AS id_usuario,coalesce(nullif(trim(p.nome),''),u.name,'Usuário '||u.id::text) AS user_name,
      coalesce('https://roadrunners.run/assets/paginas/'||nullif(trim(p.path_imagem),''),nullif(trim(u.strava_profile),''),nullif(trim(u.imagem_usuario),''),'/assets/user.png') AS avatar
      FROM tb_usuarios u LEFT JOIN LATERAL(
        SELECT pg.nome,pg.path_imagem FROM tb_paginas_usuarios pu JOIN tb_paginas pg ON pg.id_pagina=pu.id_pagina
        WHERE pu.id_usuario=u.id AND pg.tag_prefix='atleta' ORDER BY pg.id_pagina LIMIT 1
      ) p ON true";
}
function vickyAuditLoad(required struct state,required numeric operatorId){
    if(arguments.operatorId<=0)throw(type='Vicky.AuditDenied',message='Operador de auditoria inválido.');
    var s=duplicate(arguments.state);
    var options={datasource='runner_dba',timeout=15};
    var since=dateAdd('d',-s.period,now());
    var result={state=s,users=queryNew(''),selected=queryNew(''),turns=queryNew(''),tools=queryNew(''),userTotal=0,turnTotal=0,userPages=1,historyPages=1,hasOlder=false,outsidePeriod=false};
    var execution=queryNew('');
    if(s.executionId>0){
        execution=queryExecute('SELECT e.id_usuario,e.created_at,e.status,c.channel FROM tb_vicky_execucao e JOIN tb_vicky_conversa c ON c.id_vicky_conversa=e.id_vicky_conversa WHERE e.id_vicky_execucao=:execution',{execution={value=s.executionId,cfsqltype='cf_sql_bigint'}},options);
        if(execution.recordCount){
            s.userId=val(execution.id_usuario);
            if(len(s.channel) && s.channel!=execution.channel)s.channel='';
            if(s.status=='falhas' && execution.status=='completed')s.status='todos';
        }
    }
    var params={since={value=since,cfsqltype='cf_sql_timestamp'},channel={value=s.channel,cfsqltype='cf_sql_varchar'},issues={value=s.status=='falhas'?1:0,cfsqltype='cf_sql_integer'},search={value=s.search,cfsqltype='cf_sql_varchar'}};
    var filter="e.created_at>=:since AND (:channel='' OR c.channel=:channel) AND (:issues=0 OR e.status<>'completed')";
    var grouped="WITH grouped AS(SELECT e.id_usuario,count(*) AS interactions,max(e.created_at) AS last_at,
      max(e.id_vicky_execucao) AS last_id,sum(CASE WHEN e.status<>'completed' THEN 1 ELSE 0 END) AS issues,
      (array_agg(e.status ORDER BY e.created_at DESC,e.id_vicky_execucao DESC))[1] AS last_status,
      string_agg(DISTINCT c.channel,', ' ORDER BY c.channel) AS channels
      FROM tb_vicky_execucao e JOIN tb_vicky_conversa c ON c.id_vicky_conversa=e.id_vicky_conversa
      WHERE "&filter&" GROUP BY e.id_usuario),profiles AS("&vickyAuditProfileSql()&"),matches AS(
      SELECT g.*,p.user_name,p.avatar FROM grouped g JOIN profiles p ON p.id_usuario=g.id_usuario
      WHERE :search='' OR strpos(lower(p.user_name),lower(:search))>0 OR g.id_usuario::text=:search) ";
    var countUsers=queryExecute(grouped&'SELECT count(*) total FROM matches',params,options);
    result.userTotal=val(countUsers.total);result.userPages=max(1,ceiling(result.userTotal/25));s.userPage=min(s.userPage,result.userPages);
    params.take={value=25,cfsqltype='cf_sql_integer'};params.skip={value=(s.userPage-1)*25,cfsqltype='cf_sql_integer'};
    result.users=queryExecute(grouped&'SELECT * FROM matches ORDER BY last_at DESC,last_id DESC,id_usuario LIMIT :take OFFSET :skip',params,options);
    if(s.userId<=0)return result;
    result.selected=queryExecute(vickyAuditProfileSql()&' WHERE u.id=:user',{user={value=s.userId,cfsqltype='cf_sql_integer'}},options);
    if(!result.selected.recordCount)return result;
    if(execution.recordCount && dateCompare(execution.created_at,since)<0){since=execution.created_at;result.outsidePeriod=true;}
    if(s.snapshot<=0){var latest=queryExecute('SELECT coalesce(max(id_vicky_execucao),0) id FROM tb_vicky_execucao',{},options);s.snapshot=val(latest.id);}
    params={since={value=since,cfsqltype='cf_sql_timestamp'},channel={value=s.channel,cfsqltype='cf_sql_varchar'},issues={value=s.status=='falhas'?1:0,cfsqltype='cf_sql_integer'},user={value=s.userId,cfsqltype='cf_sql_integer'},snapshot={value=s.snapshot,cfsqltype='cf_sql_bigint'}};
    filter&=' AND e.id_usuario=:user AND e.id_vicky_execucao<=:snapshot';
    var scope=' FROM tb_vicky_execucao e JOIN tb_vicky_conversa c ON c.id_vicky_conversa=e.id_vicky_conversa WHERE '&filter;
    var countTurns=queryExecute('SELECT count(*) total'&scope,params,options);
    result.turnTotal=val(countTurns.total);result.historyPages=max(1,ceiling(result.turnTotal/20));
    if(execution.recordCount){
        params.targetDate={value=execution.created_at,cfsqltype='cf_sql_timestamp'};params.targetId={value=s.executionId,cfsqltype='cf_sql_bigint'};
        var newer=queryExecute('SELECT count(*) total'&scope&' AND (e.created_at>:targetDate OR (e.created_at=:targetDate AND e.id_vicky_execucao>:targetId))',params,options);
        s.historyPage=1+floor(val(newer.total)/20);
    }
    if(s.beforeId>0 && !execution.recordCount){
        // A cursor remains valid if its status changes; never OFFSET a mutable issue list.
        var boundary=queryExecute('SELECT created_at FROM tb_vicky_execucao WHERE id_vicky_execucao=:before AND id_usuario=:user AND id_vicky_execucao<=:snapshot',
          {before={value=s.beforeId,cfsqltype='cf_sql_bigint'},user=params.user,snapshot=params.snapshot},options);
        if(!boundary.recordCount)return result;
        params.beforeDate={value=boundary.created_at,cfsqltype='cf_sql_timestamp'};params.beforeId={value=s.beforeId,cfsqltype='cf_sql_bigint'};
        scope&=' AND (e.created_at<:beforeDate OR (e.created_at=:beforeDate AND e.id_vicky_execucao<:beforeId))';
        var remaining=queryExecute('SELECT count(*) total'&scope,params,options);
        result.hasOlder=val(remaining.total)>20;
        params.skip={value=0,cfsqltype='cf_sql_integer'};
    }else{
        s.historyPage=min(s.historyPage,result.historyPages);s.beforeId=0;
        result.hasOlder=result.turnTotal>(s.historyPage*20);
        params.skip={value=(s.historyPage-1)*20,cfsqltype='cf_sql_integer'};
    }
    params.take={value=20,cfsqltype='cf_sql_integer'};
    var batch=queryExecute('SELECT e.id_vicky_execucao'&scope&' ORDER BY e.created_at DESC,e.id_vicky_execucao DESC LIMIT :take OFFSET :skip',params,options);
    if(!batch.recordCount)return result;
    var opened={ids={value=valueList(batch.id_vicky_execucao),cfsqltype='cf_sql_bigint',list=true},operator={value=arguments.operatorId,cfsqltype='cf_sql_integer'}};
    // Fail closed: record EACH opened execution before fetching any private content.
    transaction {
        queryExecute("INSERT INTO tb_vicky_audit_access(id_vicky_execucao,id_operador,reason)
          SELECT id_vicky_execucao,:operator,'business_admin_chat_review' FROM tb_vicky_execucao WHERE id_vicky_execucao IN(:ids)",opened,options);
        result.turns=queryExecute("SELECT e.*,c.channel,um.content AS user_content,am.content AS assistant_content,
          um.created_at AS user_created_at,am.created_at AS assistant_created_at
          FROM tb_vicky_execucao e JOIN tb_vicky_conversa c ON c.id_vicky_conversa=e.id_vicky_conversa
          LEFT JOIN tb_vicky_mensagem um ON um.id_vicky_mensagem=e.id_mensagem_usuario
          LEFT JOIN tb_vicky_mensagem am ON am.id_vicky_mensagem=e.id_mensagem_assistente
          WHERE e.id_vicky_execucao IN(:ids) ORDER BY e.created_at,e.id_vicky_execucao",opened,options);
        result.tools=queryExecute('SELECT * FROM tb_vicky_tool_call WHERE id_vicky_execucao IN(:ids) ORDER BY id_vicky_execucao,id_vicky_tool_call',opened,options);
    }
    return result;
}
</cfscript>
