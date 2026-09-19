<cfsetting showdebugoutput="false" requesttimeout="60"/>
<cfif NOT listFind("127.0.0.1,::1",CGI.REMOTE_ADDR) OR CGI.REQUEST_METHOD NEQ "POST"><cfheader statuscode="404"/><cfabort/></cfif>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfscript>
function curationDb(sql,params={}){return queryExecute(arguments.sql,arguments.params,{datasource="runner_dba"});}
function curationSnapshot(){
    var condition="c.published=false AND c.editorial_status='draft' AND c.published_at IS NULL AND c.created_at=c.updated_at AND EXISTS(SELECT 1 FROM news.tb_content_imports i WHERE i.content_id=c.id)";
    var fn=curationDb("SELECT pg_get_functiondef('news.fn_content_force_hidden_on_insert()'::regprocedure) AS definition").definition;
    var def=curationDb("SELECT column_default FROM information_schema.columns WHERE table_schema='news' AND table_name='tb_content' AND column_name='editorial_status'").column_default;
    var rows=[];for(var row in curationDb("SELECT to_jsonb(v) AS data FROM (SELECT c.id,c.editorial_status,c.published,c.published_at,c.created_at,c.updated_at,c.is_featured FROM news.tb_content c WHERE "&condition&" ORDER BY c.id) v"))arrayAppend(rows,deserializeJSON(row.data&""));
    var signature=curationDb("SELECT md5(coalesce(string_agg(c.id::text||':'||c.editorial_status||':'||c.updated_at::text,'|' ORDER BY c.id),'')) AS signature FROM news.tb_content c WHERE "&condition).signature;
    return {"function"=fn,"default"=def,"rows"=rows,"fingerprint"=lCase(hash(fn&def&signature,"SHA-256"))};
}
try {
    result={"success"=true};
    if(structKeyExists(url,"apply")) {
        transaction {
            curationDb("SET LOCAL lock_timeout='5s'");
            curationDb("LOCK TABLE news.tb_content IN SHARE ROW EXCLUSIVE MODE");
            before=curationSnapshot();
            if(!structKeyExists(url,"expected") || compare(before.fingerprint,url.expected)!=0) throw(message="O baseline de dados mudou. Refazer backup antes da migração.");
            if(!find("NEW.editorial_status := 'draft'",before.function) || !find("'draft'",before.default)) throw(message="Regra de entrada diferente do baseline esperado.");
            curationDb(fileRead(expandPath("/_codex/sql/2026-09-18_content_starts_in_review.sql")));
            result["corrected"]=arrayLen(before.rows);
        }
    }
    if(structKeyExists(url,"test")) {
        checks=[];
        transaction {
            testId=-987654321;
            if(curationDb("SELECT id FROM news.tb_content WHERE id=-987654321").recordCount) throw(message="ID sintético já está em uso.");
            inserted=curationDb("INSERT INTO news.tb_content(id,slug,title,body_html,published,editorial_status,is_featured,published_at) VALUES(-987654321,'codex-curation-regression','Teste de curadoria','','true','published',true,now()) RETURNING published,editorial_status,is_featured,(published_at IS NULL) AS no_publication_date");
            if(inserted.published || inserted.is_featured || inserted.editorial_status!="review" || !inserted.no_publication_date) throw(message="O trigger não protege o estado inicial.");
            arrayAppend(checks,"Novo conteúdo entra em revisão, sem publicação/data/destaque, mesmo se o importador pedir publicação.");
            curationDb("UPDATE news.tb_content SET editorial_status='draft' WHERE id=-987654321");
            if(curationDb("SELECT editorial_status FROM news.tb_content WHERE id=-987654321").editorial_status!="draft") throw(message="Ocultação manual não foi preservada.");
            arrayAppend(checks,"Ocultação manual continua possível após a inserção.");
            curationDb("UPDATE news.tb_content SET published=true,editorial_status='published' WHERE id=-987654321");
            if(!curationDb("SELECT published FROM news.tb_content WHERE id=-987654321").published) throw(message="Aprovação manual bloqueada.");
            arrayAppend(checks,"Aprovação manual continua publicando o conteúdo.");
            curationDb("UPDATE news.tb_content SET published=false,editorial_status='rejected' WHERE id=-987654321");
            if(curationDb("SELECT editorial_status FROM news.tb_content WHERE id=-987654321").editorial_status!="rejected") throw(message="Rejeição alterada.");
            arrayAppend(checks,"Rejeição explícita é preservada.");
            transaction action="rollback";
        }
        if(curationDb("SELECT id FROM news.tb_content WHERE id=-987654321").recordCount) throw(message="Fixture não revertida.");
        result["tests"]=checks;
    }
    result["snapshot"]=curationSnapshot();
    counts=[];for(row in curationDb("SELECT json_build_object('status',editorial_status,'published',published,'total',count(*)) AS data FROM news.tb_content GROUP BY editorial_status,published ORDER BY editorial_status"))arrayAppend(counts,deserializeJSON(row.data&""));
    result["counts"]=counts;
    if(structKeyExists(url,"page_test")) {
        url.status="pendentes";
        include "../portal/includes/content_backend.cfm";
        result["listing"]={"total"=qContentCount.total,"rows"=qContents.recordCount,"pending_counter"=qContentStats.total_pendentes,"statuses"=valueList(qContents.editorial_status)};
        if(qContentCount.total!=qContentStats.total_pendentes || (qContents.recordCount && listRemoveDuplicates(valueList(qContents.editorial_status))!="review")) throw(message="A listagem e o contador de pendências não conferem.");
    }
    writeOutput(serializeJSON(result));
}catch(any error){cfheader(statuscode=500);writeOutput(serializeJSON({"success"=false,"message"=error.message,"detail"=error.detail,"line"=error.tagContext[1].line}));}
</cfscript>
