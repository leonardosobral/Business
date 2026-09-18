<cfsetting showdebugoutput="false" requesttimeout="120"/>
<cfif NOT listFind("127.0.0.1,::1",CGI.REMOTE_ADDR) OR CGI.REQUEST_METHOD NEQ "POST"><cfheader statuscode="404"/><cfabort/></cfif>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfinclude template="../administracao/agenda/includes/service.cfm"/>
<cfinclude template="../administracao/ai-mails/includes/service.cfm"/>
<cfinclude template="../administracao/ai-mails/includes/sync.cfm"/>
<cfinclude template="../administracao/ai-mails/includes/ai.cfm"/>
<cftry>
    <cfinclude template="tests/ai-mails-service.cfm"/>
    <cfscript>
    if(structKeyExists(url,"migrate")) {
        transaction {agendaDb(fileRead(expandPath("/administracao/ai-mails/ai_mails_schema.sql")));}
    }
    if(mailReady()) {
        transaction {
            mailEnqueue("codexsyntheticfixture");mailEnqueue("codexsyntheticfixture");
            q=agendaDb("SELECT revision FROM public.tb_ai_mail_queue WHERE thread_id='codexsyntheticfixture'");
            mailAssert(q.recordCount==1 && q.revision==2,"Queue idempotent / revision bumped");
            id=agendaDb("INSERT INTO public.tb_ai_mail_threads(thread_id,summary) VALUES('codexsyntheticfixture','Synthetic test only') RETURNING id").id;
            mailUpdate("resolve",id,1,0,"Teste sintético");
            state=agendaDb("SELECT state FROM public.tb_ai_mail_threads WHERE id=:id",{id=mailInt(id)}).state;
            mailAssert(state=="resolved","Explicit resolution stored");
            mailPurge("codexsyntheticfixture");
            empty=agendaDb("SELECT summary,source_available FROM public.tb_ai_mail_threads WHERE id=:id",{id=mailInt(id)});
            mailAssert(!empty.source_available && empty.summary=="","Unavailable source content purged");
            // A failed nested CF transaction rolls the fixture back; assert conflict last.
            stale=false;try{mailUpdate("reopen",id,1,0,"Teste");}catch(any e){stale=e.type=="AIMail.Conflict";}
            mailAssert(stale,"Concurrent stale update rejected");
            transaction action="rollback";
        }
        snapshot=mailStatus();
        mailAssert(arrayLen(snapshot.jobs)==2,"Both scheduled jobs registered");
        mailAssert(isArray(mailList({view="pending"}).items),"Filter query returns typed list");
        realGoogle=variables.mailGoogle;realAnalyze=variables.mailAnalyze;realAuthorized=variables.mailAuthorized;
        googleMode="initial";analysisCalls=0;
        variables.mailAuthorized=function(){return true;};
        variables.mailGoogle=function(path,params={},missing=false){
            if(path=="/profile") return {emailAddress="contato@runnerhub.run",historyId="100"};
            if(path=="/threads") return {threads=[{id="fixturethread"}]};
            if(path=="/history") return {historyId="101",history=[{messagesAdded=[{message={id="msg1",threadId="fixturethread",labelIds=["INBOX"]}}]}]};
            if(googleMode=="deleted") return {missing=true};
            return {messages=[base]};
        };
        variables.mailAnalyze=function(context,previous,cfg){analysisCalls++;var a=duplicate(analysis);a.warnings=[];a.sources=[];return a;};
        transaction {
            agendaDb("UPDATE public.tb_ai_mail_config SET enabled=true,initial_complete=false,initial_history='',page_token='',history_id='',collector_lease=NULL,next_attempt_at=now() WHERE id=1");
            collected=mailCollect();mailAssert(collected.processed==1,"Initial collector enqueues thread before cursor");
            processed=mailProcessOne();mailAssert(processed.processed==1,"Processor writes typed analysis to database");
            row=agendaDb("SELECT state,summary,priority,version FROM public.tb_ai_mail_threads WHERE thread_id='fixturethread'");
            mailAssert(row.recordCount==1 && row.priority=="high" && len(row.summary),"Structured summary and priority persisted");
            collected=mailCollect();processed=mailProcessOne();
            mailAssert(analysisCalls==1,"Incremental label-only event avoids duplicate AI call");
            mailAssert(mailConfig().history_id=="101","Incremental cursor advanced after enqueue");
            googleMode="deleted";mailEnqueue("fixturethread");mailProcessOne();
            row=agendaDb("SELECT source_available,summary FROM public.tb_ai_mail_threads WHERE thread_id='fixturethread'");
            mailAssert(!row.source_available && !len(row.summary),"Deleted source reconciled by worker");
            transaction action="rollback";
        }
        variables.mailGoogle=realGoogle;variables.mailAnalyze=realAnalyze;variables.mailAuthorized=realAuthorized;
        if(structKeyExists(url,"model_test")) {
            samples=[
                {name="Cobrança automática relevante",body="Aviso automático: o pagamento da produção de kits está pendente. Sem a confirmação do pagamento, a entrega do material para o evento será suspensa. Precisamos do comprovante da equipe.",check="action"},
                {name="Newsletter de rotina",body="Newsletter semanal: veja fotos de paisagens e curiosidades. Não há pedidos, compromissos ou ações para sua empresa. Você está recebendo nosso boletim de novidades recreativas.",check="low"},
                {name="Agradecimento após resolução",body="Obrigado pela confirmação. Recebemos tudo e está tudo certo. Nenhuma outra providência é necessária.",check="thanks"}
            ];
            for(sample in samples) {
                msg=mailFixtureMessage("msg1",sample.body,1700000060000,["INBOX"],"Aviso automático <no-reply@example.com>");
                ctx=mailContext({messages=[msg]},"contato@runnerhub.run");ctx.subject=sample.name;
                prediction=realAnalyze(ctx,{state=sample.check=="thanks"?"resolved":"pending",summary="",resolved_inbound_ms=1700000000000},mailConfig());
                mailAssert(sample.check=="action" ? prediction.relevant && arrayLen(prediction.actions)>0 : (sample.check=="thanks" ? !prediction.new_request : !prediction.relevant),"Real model: "&sample.name);
            }
        }
    }
    if(structKeyExists(url,"activate_jobs")) agendaDb("UPDATE public.tb_cron_jobs SET ativo=true,next_run_at=now() WHERE endpoint_url IN ('https://business.roadrunners.run/administracao/ai-mails/jobs/collect.cfm','https://business.roadrunners.run/administracao/ai-mails/jobs/process.cfm')");
    writeOutput(serializeJSON({"success"=true,"tests"=mailTests}));
    </cfscript>
    <cfcatch type="any"><cfheader statuscode="500"/><cfoutput>#serializeJSON({"success"=false,"type"=cfcatch.type,"message"=cfcatch.message,"detail"=cfcatch.detail,"line"=cfcatch.tagContext[1].line,"template"=cfcatch.tagContext[1].template})#</cfoutput></cfcatch>
</cftry>
