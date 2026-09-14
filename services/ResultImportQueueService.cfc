component output="false" {
    variables.sqlRoot = getDirectoryFromPath(getCurrentTemplatePath()) & "queries/";
    variables.contextSql = fileRead(variables.sqlRoot & "result_import_context.sql", "utf-8");

    public struct function scopeParams(required boolean unscoped, required numeric accountId) {
        return {unscoped={value=arguments.unscoped,cfsqltype="cf_sql_bit"},
                account_id={value=arguments.accountId,cfsqltype="cf_sql_bigint"}};
    }

    public query function submission(required string submissionId, required boolean unscoped, required numeric accountId) {
        var params=scopeParams(arguments.unscoped,arguments.accountId);
        params.submission_id={value=arguments.submissionId,cfsqltype="cf_sql_varchar"};
        return queryExecute(variables.contextSql & " SELECT * FROM result_import_context WHERE public_id=CAST(:submission_id AS uuid)",params);
    }

    // Call inside the successful import transaction. GETs only derive the archive state.
    public numeric function archivePrevious(required string submissionId, required boolean unscoped, required numeric accountId) {
        var params=scopeParams(arguments.unscoped,arguments.accountId);
        params.submission_id={value=arguments.submissionId,cfsqltype="cf_sql_varchar"};
        var archived=queryExecute(variables.contextSql & fileRead(variables.sqlRoot & "result_import_archive.sql","utf-8"),params);
        return archived.recordcount;
    }

    public struct function queue(required struct filters, required boolean unscoped, required numeric accountId) {
        var f=arguments.filters;
        var params=scopeParams(arguments.unscoped,arguments.accountId);
        var whereSql=" WHERE 1=1";
        var key="";
        if(f.days>0) { params.days={value=f.days,cfsqltype="cf_sql_integer"}; whereSql &= " AND data_recebimento >= now()-(:days*interval '1 day')"; }
        for(key in ["status_publicacao","cod_timer","client_id","event_group"]) {
            if(len(f[key])) { params[key]={value=f[key],cfsqltype="cf_sql_varchar"}; whereSql &= " AND " & key & "=:" & key; }
        }
        if(len(f.search)) {
            params.search={value=f.search,cfsqltype="cf_sql_varchar"};
            whereSql &= " AND position(lower(:search) IN lower(concat_ws(' ',submission_id,id_resultado_importacao::text,suggested_event_id::text,id_evento_informado::text,tag_evento_informada,external_event_id,external_account_id,url_resultado,url_resultado_publica,nome_evento,event_tag)))>0";
        }
        var base=variables.contextSql & ", filtered AS (SELECT * FROM result_import_context" & whereSql & ")";
        var result={};
        result.summary=queryExecute(base & ", active AS (SELECT DISTINCT ON(event_group) * FROM filtered WHERE queue_status NOT IN ('cancelado','arquivado') ORDER BY event_group,data_recebimento DESC,id_resultado_importacao DESC) SELECT count(*) AS total, count(*) FILTER(WHERE queue_status='pendente') AS pendentes, count(*) FILTER(WHERE queue_status='pendente' AND data_recebimento<now()-interval '15 minutes') AS pendentes_atrasadas, count(*) FILTER(WHERE queue_status='processando') AS processando, count(*) FILTER(WHERE queue_status='processado') AS processados, count(*) FILTER(WHERE queue_status='falhou') AS falhas, (SELECT count(*) FROM filtered WHERE queue_status='cancelado') AS cancelados, (SELECT count(*) FROM filtered WHERE queue_status='arquivado') AS arquivados, count(*) FILTER(WHERE status_publicacao='extraoficial') AS extraoficiais, count(*) FILTER(WHERE status_publicacao='final') AS finais, count(*) FILTER(WHERE status_publicacao='atualizacao') AS atualizacoes, coalesce(sum(total_resultados) FILTER(WHERE queue_status='processado'),0) AS total_resultados FROM active",params);
        var history=len(f.event_group)>0 OR listFindNoCase("cancelado,arquivado",f.status)>0;
        var selection=history ? "SELECT * FROM filtered" : "SELECT DISTINCT ON(event_group) * FROM filtered WHERE queue_status NOT IN ('cancelado','arquivado') ORDER BY event_group,data_recebimento DESC,id_resultado_importacao DESC";
        base &= ", selected AS (" & selection & ")";
        var statusSql="";
        if(len(f.status)) {params.status={value=f.status,cfsqltype="cf_sql_varchar"};statusSql=" WHERE queue_status=:status";}
        result.total=queryExecute(base & " SELECT count(*) AS total FROM selected" & statusSql,params).total;
        result.pages=max(1,ceiling(result.total/25));
        result.page=min(max(1,f.page),result.pages);
        params.offset={value=(result.page-1)*25,cfsqltype="cf_sql_integer"};
        result.rows=queryExecute(base & " SELECT * FROM selected" & statusSql & " ORDER BY data_recebimento DESC,id_resultado_importacao DESC LIMIT 25 OFFSET :offset",params);
        result.timers=queryExecute(variables.contextSql & " SELECT DISTINCT cod_timer FROM result_import_context ORDER BY cod_timer",scopeParams(arguments.unscoped,arguments.accountId));
        result.clients=queryExecute(variables.contextSql & " SELECT DISTINCT client_id FROM result_import_context ORDER BY client_id",scopeParams(arguments.unscoped,arguments.accountId));
        return result;
    }
}
