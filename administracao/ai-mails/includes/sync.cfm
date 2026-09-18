<cfscript>
function mailCollect() {
    var cfg=mailConfig();
    if(!cfg.enabled) return {success=true,status="paused",message="Monitoramento pausado."};
    if(!mailAuthorized()) mailFail("Autorize a leitura do Gmail no AI-mails.");
    var lease=agendaRandom();
    var claimed=agendaDb("UPDATE public.tb_ai_mail_config SET collector_token=:lease,collector_lease=now()+interval '140 seconds' WHERE id=1 AND next_attempt_at<=now() AND (collector_lease IS NULL OR collector_lease<now()) RETURNING id",{lease=agendaParam(lease)});
    if(!claimed.recordCount) return {success=true,status="waiting",message="Coleta em andamento ou aguardando nova tentativa."};
    var collected=0;var pages=0;
    try {
        cfg=mailConfig();
        if(!cfg.initial_complete && !len(cfg.initial_history)) {
            var profile=mailGoogle("/profile");
            if(compareNoCase(profile.emailAddress,cfg.email)!=0) mailFail("A conta conectada não corresponde à caixa configurada.");
            // Freeze the search window while paging; include old unread/important messages.
            var cutoff=int(createObject("java","java.lang.System").currentTimeMillis()/1000)-cfg.initial_days*86400;
            agendaDb("UPDATE public.tb_ai_mail_config SET initial_history=:h,initial_query=:q,page_token='',collected=0 WHERE id=1",{h=agendaParam(profile.historyId&""),q=agendaParam("in:inbox {after:"&cutoff&" is:unread is:important}")});
            cfg=mailConfig();
        }
        // One bounded page per run, persisted before advancing its cursor.
        if(!cfg.initial_complete) {
            var args={"q"=cfg.initial_query,"maxResults"=100};if(len(cfg.page_token)) args["pageToken"]=cfg.page_token;
            var result=mailGoogle("/threads",args);
            transaction {
                if(structKeyExists(result,"threads")) for(var thread in result.threads) {mailEnqueue(thread.id);collected++;}
                var next=structKeyExists(result,"nextPageToken")?result.nextPageToken:"";
                agendaDb("UPDATE public.tb_ai_mail_config SET page_token=:page,collected=collected+:count,initial_complete=:done,history_id=CASE WHEN :done THEN initial_history ELSE history_id END,last_error='',failures=0,last_sync_at=CASE WHEN :done THEN now() ELSE last_sync_at END WHERE id=1 AND collector_token=:lease",{page=agendaParam(next),count=mailInt(collected),done=mailBool(!len(next)),lease=agendaParam(lease)});
            }
            pages=1;
        } else {
            var args={"startHistoryId"=cfg.history_id,"maxResults"=100};if(len(cfg.page_token)) args["pageToken"]=cfg.page_token;
            var result=mailGoogle("/history",args,true);
            if(structKeyExists(result,"missing")) {
                transaction {
                    agendaDb("INSERT INTO public.tb_ai_mail_queue(thread_id) SELECT thread_id FROM public.tb_ai_mail_threads WHERE source_available ON CONFLICT(thread_id) DO UPDATE SET revision=tb_ai_mail_queue.revision+1,available_at=now()");
                    agendaDb("UPDATE public.tb_ai_mail_config SET initial_complete=false,initial_history='',page_token='',initial_query='',last_error='Histórico expirado: reconciliando sem apagar decisões.' WHERE id=1");
                }
                return {success=true,status="reconciling",message="Histórico expirado. Reconciliação agendada."};
            }
            transaction {
                var seen={};
                if(structKeyExists(result,"history")) for(var history in result.history) {
                    var refs=[];
                    for(var kind in ["messagesAdded","messagesDeleted","labelsAdded","labelsRemoved"]) if(structKeyExists(history,kind)) for(var event in history[kind]) {
                        if(!structKeyExists(event,"message")) continue;
                        var m=event.message;
                        var inbox=(structKeyExists(m,"labelIds") && arrayFind(m.labelIds,"INBOX")>0) || (kind=="labelsAdded" && structKeyExists(event,"labelIds") && arrayFind(event.labelIds,"INBOX")>0);
                        arrayAppend(refs,{id=m.threadId,inbox=inbox});
                    }
                    if(structKeyExists(history,"messages")) for(var m in history.messages) arrayAppend(refs,{id=m.threadId,inbox=false});
                    for(var ref in refs) {
                        if(structKeyExists(seen,ref.id)) continue;
                        var known=agendaDb("SELECT 1 FROM public.tb_ai_mail_threads WHERE thread_id=:t UNION ALL SELECT 1 FROM public.tb_ai_mail_queue WHERE thread_id=:t LIMIT 1",{t=agendaParam(ref.id)}).recordCount>0;
                        if(ref.inbox || known) {mailEnqueue(ref.id);seen[ref.id]=true;collected++;}
                    }
                }
                var next=structKeyExists(result,"nextPageToken")?result.nextPageToken:"";
                agendaDb("UPDATE public.tb_ai_mail_config SET page_token=:page,history_id=CASE WHEN :done THEN :h ELSE history_id END,last_sync_at=CASE WHEN :done THEN now() ELSE last_sync_at END,last_error='',failures=0 WHERE id=1 AND collector_token=:lease",{page=agendaParam(next),done=mailBool(!len(next)),h=agendaParam(result.historyId&""),lease=agendaParam(lease)});
            }
            pages=1;
        }
        // Resolved summaries and tombstones expire; do not silently erase open work.
        transaction {
            agendaDb("DELETE FROM public.tb_ai_mail_messages WHERE thread_id IN (SELECT thread_id FROM public.tb_ai_mail_threads WHERE (state='resolved' OR NOT source_available) AND updated_at<now()-(:days*interval '1 day'))",{days=mailInt(cfg.retention_days)});
            // Keep a minimal decision tombstone so a future resync cannot recreate resolved work.
            agendaDb("UPDATE public.tb_ai_mail_threads SET subject='Conteúdo expirado pela política de retenção',sender='',summary='',reason='',actions='[]',warnings='[]',sources='[]',note='',rfc_message_id='',source_message_id='',deadline_at=NULL,deadline_text='',content_expired=true,version=version+1 WHERE NOT content_expired AND (state='resolved' OR NOT source_available) AND updated_at<now()-(:days*interval '1 day') AND NOT EXISTS(SELECT 1 FROM public.tb_ai_mail_queue q WHERE q.thread_id=tb_ai_mail_threads.thread_id)",{days=mailInt(cfg.retention_days)});
            agendaDb("DELETE FROM public.tb_ai_mail_audit WHERE created_at<now()-(:days*interval '1 day')",{days=mailInt(cfg.retention_days)});
            agendaDb("DELETE FROM public.tb_ai_mail_usage WHERE created_at<now()-interval '365 days'");
        }
        return {success=true,status="ok",processed=collected,pages=pages,message="Coleta concluída; análise em fila."};
    } catch(any error) {
        var delay=min(3600,60*(2^min(6,cfg.failures)));
        agendaDb("UPDATE public.tb_ai_mail_config SET last_error=:error,failures=failures+1,next_attempt_at=now()+(:delay*interval '1 second') WHERE id=1 AND collector_token=:lease",{error=agendaParam(mailSafeError(error)),delay=mailInt(delay),lease=agendaParam(lease)});
        rethrow;
    } finally {
        agendaDb("UPDATE public.tb_ai_mail_config SET collector_lease=NULL,collector_token='' WHERE id=1 AND collector_token=:lease",{lease=agendaParam(lease)});
    }
}
function mailHeader(required struct payload,required string name) {
    if(structKeyExists(arguments.payload,"headers")) for(var header in arguments.payload.headers) if(compareNoCase(header.name,arguments.name)==0) return left(header.value&"",1000);
    return "";
}
function mailText(required string raw,boolean html=false) {
    var s=arguments.raw;
    if(arguments.html) {
        s=reReplaceNoCase(s,"(?s)<(script|style|head|blockquote)[^>]*>.*?</\1>"," ","all");
        s=reReplaceNoCase(s,"<br\s*/?>|</p>|</div>|</li>",chr(10),"all");
        s=reReplace(s,"<[^>]+>"," ","all");
        s=replace(replace(replace(replace(s,"&nbsp;"," ","all"),"&amp;","&","all"),"&lt;","<","all"),"&gt;",">","all");
    }
    s=reReplace(s,"(?m)^>.*$","","all");
    s=reReplaceNoCase(s,"(?m)^(On .+wrote:|Em .+escreveu:|-----Original Message-----)[\s\S]*$","","one");
    s=reReplace(s,"(?m)^--\s*$[\s\S]*$","","one");
    s=reReplaceNoCase(s,"\b(Bearer\s+)[A-Za-z0-9._-]+|\bsk-[A-Za-z0-9_-]{12,}","[credencial omitida]","all");
    s=reReplaceNoCase(s,"(senha|password|token|api[_ -]?key)\s*[:=]\s*[^\s,;]+","[credencial omitida]","all");
    s=reReplace(s,"\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b","[documento omitido]","all");
    return trim(reReplace(s,"[ \t]+"," ","all"));
}
function mailMime(required struct part,numeric depth=0) {
    var result={text="",attachments=[],truncated=false};
    if(arguments.depth>12) {result.truncated=true;return result;}
    if(structKeyExists(arguments.part,"filename") && len(arguments.part.filename)) {arrayAppend(result.attachments,left(arguments.part.filename,200));return result;}
    if(structKeyExists(arguments.part,"body") && structKeyExists(arguments.part.body,"data") && structKeyExists(arguments.part,"mimeType") && listFindNoCase("text/plain,text/html",arguments.part.mimeType)) {
        var encoded=arguments.part.body.data;
        if(len(encoded)>150000) {encoded=left(encoded,150000);result.truncated=true;}
        try {
            var raw=charsetEncode(createObject("java","java.util.Base64").getUrlDecoder().decode(encoded),"UTF-8");
            result.text=mailText(raw,arguments.part.mimeType=="text/html");
        } catch(any invalidBody) {result.truncated=true;}
    }
    if(structKeyExists(arguments.part,"parts")) {
        var plain="";var html="";
        for(var child in arguments.part.parts) {
            var value=mailMime(child,arguments.depth+1);
            for(var filename in value.attachments) arrayAppend(result.attachments,filename);
            result.truncated=result.truncated || value.truncated;
            if(structKeyExists(child,"mimeType") && child.mimeType=="text/html") html&=value.text&chr(10);else plain&=value.text&chr(10);
        }
        result.text&=len(trim(plain))?plain:html;
    }
    return result;
}
function mailContext(required struct thread,required string email) {
    var context={messages=[],versions=[],subject="",sender="",rfc_message_id="",last_ms=0,last_inbound_ms=0,in_inbox=false,source_available=false,truncated=false,has_attachments=false,ids=[],inbound_ids=[],hash=""};
    if(structKeyExists(arguments.thread,"missing") || !structKeyExists(arguments.thread,"messages")) return context;
    var fingerprints=[];var remaining=26000;
    // Last messages first for budgets, then restore chronology for the model.
    for(var i=arrayLen(arguments.thread.messages);i>=1;i--) {
        var m=arguments.thread.messages[i]; var labels=structKeyExists(m,"labelIds")?m.labelIds:[];
        if(arrayFind(labels,"TRASH") || arrayFind(labels,"SPAM") || arrayFind(labels,"DRAFT")) continue;
        context.source_available=true;context.in_inbox=context.in_inbox || arrayFind(labels,"INBOX")>0;
        // Trust Gmail's SENT label, never a spoofable From display/header.
        var sender=mailHeader(m.payload,"From"); var outgoing=arrayFind(labels,"SENT")>0;
        var mime=mailMime(m.payload);var ms=val(m.internalDate);
        if(ms>context.last_ms) {context.last_ms=ms;context.subject=mailHeader(m.payload,"Subject");context.sender=sender;context.rfc_message_id=mailHeader(m.payload,"Message-ID");}
        if(!outgoing && ms>context.last_inbound_ms) {context.last_inbound_ms=ms;context.sender=sender;}
        arrayAppend(context.ids,m.id);if(!outgoing) arrayAppend(context.inbound_ids,m.id);
        var fingerprint=hash(serializeJSON([m.id,mime.text,mime.attachments]),"SHA-256");
        arrayPrepend(fingerprints,m.id&":"&fingerprint);arrayAppend(context.versions,{id=m.id,hash=fingerprint,ms=ms});
        var body=left(mime.text,min(7000,max(0,remaining))); remaining-=len(body);
        context.truncated=context.truncated || mime.truncated || len(body)<len(mime.text) || arrayLen(context.messages)>=20;
        context.has_attachments=context.has_attachments || arrayLen(mime.attachments)>0;
        if(arrayLen(context.messages)<20 && (len(body) || arrayLen(mime.attachments))) arrayPrepend(context.messages,{id=m.id,date=createObject("java","java.time.Instant").ofEpochMilli(javaCast("long",ms)).toString(),direction=outgoing?"sent":"received",sender=left(sender,200),subject=left(mailHeader(m.payload,"Subject"),300),text=body,attachments=mime.attachments});
    }
    context.hash=hash(arrayToList(fingerprints,"|"),"SHA-256");
    return context;
}
function mailShouldReopen(required struct analysis,required struct context,required struct previous) {
    var sourceAfterResolution=false;
    for(var message in arguments.context.versions) if(message.id==arguments.analysis.source_message_id && arrayFind(arguments.context.inbound_ids,message.id) && message.ms>arguments.previous.resolved_inbound_ms) sourceAfterResolution=true;
    return arguments.previous.state=="resolved" && sourceAfterResolution && arguments.analysis.new_request && arguments.analysis.relevant && !arguments.analysis.needs_review;
}
function mailPurge(required string threadId) {
    transaction {
        agendaDb("UPDATE public.tb_ai_mail_threads SET subject='Origem removida ou indisponível',sender='',summary='',reason='',actions='[]',warnings='[]',sources='[]',note='',rfc_message_id='',source_message_id='',deadline_at=NULL,deadline_text='',source_available=false,needs_review=true,content_hash='',version=version+1,updated_at=now() WHERE thread_id=:id",{id=agendaParam(arguments.threadId)});
        agendaDb("DELETE FROM public.tb_ai_mail_messages WHERE thread_id=:id",{id=agendaParam(arguments.threadId)});
    }
}
</cfscript>
