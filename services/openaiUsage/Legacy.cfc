component output=false {
    variables.datasource="runner_dba";
    public any function init(string datasource="runner_dba"){variables.datasource=datasource;return this;}
    private struct function legacyUsage(required struct record){
        if(structKeyExists(record,"usage") AND isJSON(record.usage & ""))return deserializeJSON(record.usage & "");
        if(structKeyExists(record,"input_tokens") AND structKeyExists(record,"output_tokens") AND isNumeric(record.input_tokens) AND isNumeric(record.output_tokens) AND record.input_tokens+record.output_tokens GT 0)return {input_tokens=record.input_tokens+0,output_tokens=record.output_tokens+0};
        return {};
    }
    public struct function load(required struct f,required numeric cutoff){
        var result={rows=[],warnings=[]};if(cutoff LTE f.fromMs)return result;
        var specs=[
            {module="ai-mails",source="legacy-ai-mail",sql="SELECT id::text AS id,extract(epoch FROM created_at)*1000 AS at_ms,model,status,input_tokens,output_tokens,operation FROM public.tb_ai_mail_usage WHERE created_at>=to_timestamp(:start/1000.0) AND created_at<to_timestamp(:finish/1000.0) ORDER BY created_at DESC LIMIT 5001"},
            {module="vicky",source="legacy-vicky",sql="SELECT id_vicky_execucao::text AS id,extract(epoch FROM created_at AT TIME ZONE 'America/Sao_Paulo')*1000 AS at_ms,model,status,input_tokens,output_tokens,'conversation' AS operation FROM public.tb_vicky_execucao WHERE created_at AT TIME ZONE 'America/Sao_Paulo'>=to_timestamp(:start/1000.0) AND created_at AT TIME ZONE 'America/Sao_Paulo'<to_timestamp(:finish/1000.0) ORDER BY created_at DESC LIMIT 5001"},
            {module="geolocation",source="legacy-cache",sql="SELECT cache_key AS id,extract(epoch FROM updated_at)*1000 AS at_ms,COALESCE(response->>'model',response->>'MODEL','unknown') AS model,'completed' AS status,COALESCE(response->'usage',response->'USAGE','{}'::jsonb)::text AS usage,'extract' AS operation FROM public.tb_geocoding_cache WHERE updated_at>=to_timestamp(:start/1000.0) AND updated_at<to_timestamp(:finish/1000.0) AND (jsonb_exists(response,'facts') OR jsonb_exists(response,'FACTS')) ORDER BY updated_at DESC LIMIT 5001"},
            {module="event-descriptions",source="legacy-description",sql="SELECT id::text AS id,extract(epoch FROM created_at)*1000 AS at_ms,model,status,'rewrite' AS operation FROM public.tb_evento_descricao_rewrites WHERE created_at>=to_timestamp(:start/1000.0) AND created_at<to_timestamp(:finish/1000.0) UNION ALL SELECT 'tr-'||id::text AS id,extract(epoch FROM created_at)*1000 AS at_ms,model,status,'translation' AS operation FROM public.tb_evento_descricao_translations WHERE created_at>=to_timestamp(:start/1000.0) AND created_at<to_timestamp(:finish/1000.0) ORDER BY at_ms DESC LIMIT 5001"},
            {module="news-summaries",source="legacy-news",sql="SELECT id::text AS id,extract(epoch FROM updated_at AT TIME ZONE 'America/Sao_Paulo')*1000 AS at_ms,COALESCE(model,'unknown') AS model,status,'summary' AS operation FROM news.tb_article_summary_jobs WHERE updated_at AT TIME ZONE 'America/Sao_Paulo'>=to_timestamp(:start/1000.0) AND updated_at AT TIME ZONE 'America/Sao_Paulo'<to_timestamp(:finish/1000.0) ORDER BY updated_at DESC LIMIT 5001"}
        ];
        var params={start={value=f.fromMs,cfsqltype="cf_sql_bigint"},finish={value=min(f.toMs,cutoff),cfsqltype="cf_sql_bigint"}};
        for(var spec in specs){
            if(f.module NEQ "all" AND f.module NEQ spec.module)continue;
            try{
                var records=queryExecute(spec.sql,params,{datasource=variables.datasource,timeout=10});
                if(records.recordCount GT 5000)arrayAppend(result.warnings,"Histórico antigo limitado a 5.000 registros em " & new services.openaiUsage.Catalog().modules()[spec.module].label & ". Reduza o período.");
                for(var i=1;i LTE min(records.recordCount,5000);i++){
                    var record=records.getRow(i);var usage=legacyUsage(record);
                    var price=new services.openaiUsage.Pricing().estimate(record.model,usage,"default");var m=price.meter;
                    arrayAppend(result.rows,{id=record.id,at_ms=record.at_ms+0,module=spec.module,model=record.model,operation=record.operation,status=listFind("completed,received,updated,done",record.status) ? "success" : (listFind("failed,rejected,fallback,error",record.status) ? "error" : "incomplete"),http_status=0,tokens_known=m.known,input_tokens=m.input,output_tokens=m.output,cached_tokens=m.cached,write_30m_tokens=m.write30,write_12h_tokens=m.write12,cost_known=price.known,estimated_usd=price.usd,partial_cost=true,source=spec.source});
                }
            }catch(any unavailable){arrayAppend(result.warnings,"O histórico antigo de " & new services.openaiUsage.Catalog().modules()[spec.module].label & " não pôde ser consultado.");}
        }
        return result;
    }
}
