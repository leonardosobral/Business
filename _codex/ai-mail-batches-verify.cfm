<cfsetting showdebugoutput="false" requesttimeout="120"/>
<cfif NOT listFind("127.0.0.1,::1",CGI.REMOTE_ADDR) OR CGI.REQUEST_METHOD NEQ "POST"><cfheader statuscode="404"/><cfabort/></cfif>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfinclude template="../administracao/agenda/includes/service.cfm"/>
<cfinclude template="../administracao/ai-mails/includes/service.cfm"/>
<cfinclude template="../administracao/ai-mails/includes/sync.cfm"/>
<cfinclude template="../administracao/ai-mails/includes/ai.cfm"/>
<cfinclude template="../administracao/ai-mails/includes/batch.cfm"/>
<cfscript>
tests=[];
function batchAssert(required boolean condition,required string message) {
    if(!arguments.condition) throw(type="BatchVerify.Failed",message=arguments.message);
    arrayAppend(tests,arguments.message);
}
try {
    if(structKeyExists(url,"migrate")) transaction {agendaDb(fileRead(expandPath("/administracao/ai-mails/ai_mails_schema.sql")));}
    batchAssert(mailBatchReady(),"Estrutura de lotes disponível");
    usageColumn=agendaDb("SELECT count(*)::int AS total FROM information_schema.columns WHERE table_schema='public' AND table_name='tb_ai_mail_usage' AND column_name='operation'");
    batchAssert(usageColumn.total==1,"Cota de lotes separada da triagem automática");
    invalidSelection=false;try{mailBatchIds("1");}catch(any expected){invalidSelection=expected.type=="AIMail.Validation";}
    batchAssert(invalidSelection,"Seleção exige ao menos duas conversas");
    realBatchAnalyze=variables.mailBatchAnalyze;
    variables.mailBatchAnalyze=function(items,cfg,instruction="") {
        var map={};var ids=[];
        for(var item in arguments.items) {map[item.id&""]={relationship=arrayLen(ids)?"duplicate":"primary",finding="Relação sintética para teste transacional."};arrayAppend(ids,item.id);}
        return {title="Lote sintético",priority="high",category="operacao",summary="Duas falhas sintéticas relacionadas.",pattern="Mesmo componente e mesma assinatura de erro.",impact="Falha operacional de teste.",needs_review=false,actions=[{text="Investigar a causa comum.",evidence_thread_ids=ids}],item_map=map};
    };
    transaction {
        marker=replace(createUUID(),"-","","all");
        id1=agendaDb("INSERT INTO public.tb_ai_mail_threads(thread_id,subject,sender,summary,reason,actions,priority,category,source_available,content_expired,analyzed_at,last_inbound_ms) VALUES(:t,'Falha sintética A','fixture@example.com','Erro A','Teste','[]','normal','operacao',true,false,now(),100) RETURNING id",{t=agendaParam("codexbatcha"&marker)}).id;
        id2=agendaDb("INSERT INTO public.tb_ai_mail_threads(thread_id,subject,sender,summary,reason,actions,priority,category,source_available,content_expired,analyzed_at,last_inbound_ms) VALUES(:t,'Falha sintética B','fixture@example.com','Erro B','Teste','[]','normal','operacao',true,false,now(),200) RETURNING id",{t=agendaParam("codexbatchb"&marker)}).id;
        created=mailBatchCreate(id1&","&id2,"Lote sintético","Compare as assinaturas",0,"Teste Codex");
        detail=mailBatchDetail(created.batch_id);
        batchAssert(detail.batch.member_count==2 && arrayLen(detail.items)==2,"Lote persiste duas conversas vinculadas");
        batchAssert(arrayLen(detail.batch.actions)==1 && detail.batch.actions[1].evidence_thread_ids[1]==id1,"Plano mantém evidência nas conversas do lote");
        mailBatchUpdate("batch_start",created.batch_id,detail.batch.version,0,"Teste Codex");
        detail=mailBatchDetail(created.batch_id);batchAssert(detail.batch.state=="in_progress","Início do lote atualiza o conjunto");
        form.priority="high";mailBatchUpdate("batch_classify",created.batch_id,detail.batch.version,0,"Teste Codex");
        priorities=agendaDb("SELECT count(*) FILTER(WHERE priority='high' AND manual_priority)::int AS updated FROM public.tb_ai_mail_threads WHERE id IN(:ids)",{ids={value=id1&","&id2,cfsqltype="cf_sql_bigint",list=true}});
        batchAssert(priorities.updated==2,"Prioridade do lote é aplicada às conversas");
        detail=mailBatchDetail(created.batch_id);form.note="Observação sintética";mailBatchUpdate("batch_note",created.batch_id,detail.batch.version,0,"Teste Codex");
        detail=mailBatchDetail(created.batch_id);batchAssert(detail.batch.note=="Observação sintética","Observação do lote é independente");
        mailBatchUpdate("batch_resolve",created.batch_id,detail.batch.version,0,"Teste Codex");
        resolved=agendaDb("SELECT count(*) FILTER(WHERE state='resolved' AND resolved_inbound_ms=last_inbound_ms)::int AS updated FROM public.tb_ai_mail_threads WHERE id IN(:ids)",{ids={value=id1&","&id2,cfsqltype="cf_sql_bigint",list=true}});
        batchAssert(resolved.updated==2,"Resolução do lote preserva o marco de novas mensagens");
        batchAssert(arrayLen(mailBatchList().items)>=1,"Listagem de lotes retorna estrutura tipada");
        transaction action="rollback";
    }
    variables.mailBatchAnalyze=realBatchAnalyze;
    writeOutput(serializeJSON(mailWire({success=true,tests=tests})));
} catch(any error) {
    if(isDefined("realBatchAnalyze")) variables.mailBatchAnalyze=realBatchAnalyze;
    cfheader(statuscode=500);
    writeOutput(serializeJSON(mailWire({success=false,type=error.type,message=error.message,detail=error.detail,line=arrayLen(error.tagContext)?error.tagContext[1].line:0,template=arrayLen(error.tagContext)?error.tagContext[1].template:""})));
}
</cfscript>
