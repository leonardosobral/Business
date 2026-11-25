<!--- Leitura exclusiva das fontes de contas, publicidade e leaderboard. --->
<cfscript>
function orgInput(required string key, string fallback="") {
    if (!structKeyExists(URL,key)) return fallback;
    if (!isSimpleValue(URL[key])) throw(type="FunnelInput",message="Invalid filter");
    return trim(URL[key] & "");
}
function orgDay(required string value) {
    if (!reFind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",value)) throw(type="FunnelInput",message="Invalid date");
    try {
        var result=createDate(val(left(value,4)),val(mid(value,6,2)),val(right(value,2)));
        if (dateFormat(result,"yyyy-mm-dd") NEQ value OR year(result) LT 2000) throw(type="FunnelInput",message="Invalid date");
        return result;
    } catch (any invalid) { throw(type="FunnelInput",message="Invalid date"); }
}
function orgParam(required any value, string type="cf_sql_varchar") { return {value=value,cfsqltype=type}; }
function orgReport() {
    var today=dateTimeFormat(now(),"yyyy-mm-dd","America/Sao_Paulo");
    var fromDay=orgInput("de",left(today,4) & "-01-01");
    var toDay=orgInput("ate",today);
    var product=orgInput("produto","desafio");
    var reading=orgInput("leitura","base");
    var stage=orgInput("etapa","base");
    var page=orgInput("pagina","1");
    var search=left(orgInput("busca"),80);
    if (dateCompare(orgDay(fromDay),orgDay(toDay)) GT 0 OR dateCompare(orgDay(toDay),orgDay(today)) GT 0 OR !listFind("all,desafio,selo,assinatura,gorunners,comparador,estudo,patrocinio,transmissao,perfil,dados",product) OR !listFind("base,cohort",reading) OR !listFind("base,related,paid,active,renewed,expired,coupon,status_c",stage) OR !reFind("^[1-9][0-9]{0,4}$",page)) throw(type="FunnelInput",message="Invalid filter");
    var metadata=queryExecute("SELECT table_schema,table_name,column_name FROM information_schema.columns WHERE (table_schema='public' AND table_name IN ('tb_contas','tb_conta_usuarios','tb_usuarios','tb_conta_eventos','tb_leaderboard_config','tb_evento_corridas')) OR (table_schema='ads' AND table_name IN ('payment_intents','credit_ledger'))",{},{datasource="runner_dba",timeout=40});
    var cols={};
    for (var col in metadata) {
        var key=col.table_schema & "." & col.table_name;
        if (!structKeyExists(cols,key)) cols[key]="";
        cols[key]=listAppend(cols[key],col.column_name);
    }
    var requiredColumns={"public.tb_contas"="id_conta,nome_conta,data_criacao","public.tb_conta_usuarios"="id_conta,id_usuario,papel,status,data_criacao","public.tb_usuarios"="id,name"};
    for (var tableName in requiredColumns) for (var columnName in listToArray(requiredColumns[tableName])) if (!structKeyExists(cols,tableName) OR !listFindNoCase(cols[tableName],columnName)) throw(type="FunnelSource",message="Account source unavailable");
    var mapped=false;
    var sources=product EQ "patrocinio" ? {"ads.payment_intents"="payment_intent_id,account_id,status,paid_at,ledger_entry_id","ads.credit_ledger"="ledger_entry_id,payment_intent_id,account_id,source_type,entry_type"} : product EQ "transmissao" ? {"public.tb_leaderboard_config"="id_evento,titulo,data_inicio,data_inclusao","public.tb_evento_corridas"="id_evento,nome_evento,data_inicial","public.tb_conta_eventos"="id_evento,id_conta,status,data_criacao"} : {};
    if (product EQ "patrocinio" OR product EQ "transmissao") {
        mapped=true;
        for (var sourceName in sources) for (var sourceColumn in listToArray(sources[sourceName])) if (!structKeyExists(cols,sourceName) OR !listFindNoCase(cols[sourceName],sourceColumn)) mapped=false;
    }
    var params={from_day=orgParam(fromDay),to_day=orgParam(toDay),offset=orgParam((val(page)-1)*25,"cf_sql_integer")};
    var sql="WITH bounds AS (SELECT CAST(:from_day AS date) AT TIME ZONE 'America/Sao_Paulo' AS starts_at,(CAST(:to_day AS date)+1) AT TIME ZONE 'America/Sao_Paulo' AS until_at), base AS (SELECT c.id_conta AS id,c.nome_conta AS name,string_agg(DISTINCT coalesce(u.name,''),', ' ORDER BY coalesce(u.name,'')) AS owners FROM public.tb_contas c JOIN public.tb_conta_usuarios cu ON cu.id_conta=c.id_conta AND cu.papel::text='OWNER' AND cu.status::text='ATIVO' JOIN public.tb_usuarios u ON u.id=cu.id_usuario CROSS JOIN bounds b WHERE c.data_criacao<b.until_at AND cu.data_criacao<b.until_at";
    if (reading EQ "cohort") sql &= " AND c.data_criacao>=b.starts_at";
    sql &= " GROUP BY c.id_conta,c.nome_conta), ";
    if (mapped AND product EQ "patrocinio") {
        sql &= " purchases AS (SELECT DISTINCT p.account_id AS id,''::text AS evidence,0::bigint AS event_count,'[]'::jsonb AS event_details FROM ads.payment_intents p JOIN ads.credit_ledger l ON l.ledger_entry_id=p.ledger_entry_id AND l.payment_intent_id=p.payment_intent_id AND l.account_id=p.account_id AND l.source_type='PAYMENT' AND l.entry_type='CREDIT' CROSS JOIN bounds b WHERE p.status='PAID' AND p.paid_at IS NOT NULL AND p.paid_at<b.until_at), issues AS (SELECT 0::bigint AS unlinked,0::bigint AS ambiguous), ";
    } else if (mapped AND product EQ "transmissao") {
        // The public leaderboard identifies event 51535 as a RunTV demonstration, not a sale.
        // Other events remain visible regardless of whether their leaderboard is currently active.
        // The user identified Voa Esportes for 43381 and 37310, Global Vita for 43657, and Vega Sports for the two ASICS events;
        // this commercial attribution does not change either operational account link.
        sql &= " event_links AS (SELECT lc.id_evento,coalesce(nullif(trim(lc.titulo),''),evt.nome_evento) AS event_name,evt.data_inicial AS event_day,count(DISTINCT ce.id_conta) AS accounts,min(ce.id_conta) AS account_id,coalesce(bool_or(ce.id_conta=27),false) AS voa_linked,coalesce(bool_or(ce.id_conta=38),false) AS global_linked,coalesce(string_agg(DISTINCT concat(c.nome_conta,' (ID ',c.id_conta,')'),', ' ORDER BY concat(c.nome_conta,' (ID ',c.id_conta,')')) FILTER (WHERE ce.id_conta IS NOT NULL),'') AS account_names FROM public.tb_leaderboard_config lc JOIN public.tb_evento_corridas evt ON evt.id_evento=lc.id_evento CROSS JOIN bounds b LEFT JOIN public.tb_conta_eventos ce ON ce.id_evento=lc.id_evento AND ce.status::text='ATIVO' AND ce.data_criacao<b.until_at LEFT JOIN public.tb_contas c ON c.id_conta=ce.id_conta WHERE lc.data_inclusao<(CAST(:to_day AS date)+1) GROUP BY lc.id_evento,lc.titulo,lc.data_inicio,evt.nome_evento,evt.data_inicial), resolved_events AS (SELECT e.*,CASE WHEN id_evento IN (40209,40260) THEN 60::bigint WHEN id_evento IN (43381,37310) THEN CASE WHEN voa_linked THEN 27::bigint ELSE NULL::bigint END WHEN id_evento=43657 THEN CASE WHEN global_linked THEN 38::bigint ELSE NULL::bigint END WHEN accounts=1 THEN account_id ELSE NULL::bigint END AS buyer_id FROM event_links e), period_events AS (SELECT r.*,c.nome_conta AS buyer_name,(b.id IS NOT NULL) AS in_base FROM resolved_events r LEFT JOIN public.tb_contas c ON c.id_conta=r.buyer_id LEFT JOIN base b ON b.id=r.buyer_id WHERE r.id_evento<>51535 AND r.event_day BETWEEN CAST(:from_day AS date) AND CAST(:to_day AS date)), purchases AS (SELECT r.buyer_id AS id,string_agg(r.id_evento::text,', ' ORDER BY r.id_evento) AS evidence,count(*) FILTER (WHERE r.event_day BETWEEN CAST(:from_day AS date) AND CAST(:to_day AS date)) AS event_count,coalesce(jsonb_agg(jsonb_build_object('id',r.id_evento,'name',r.event_name,'day',to_char(r.event_day,'DD/MM/YYYY')) ORDER BY r.event_day DESC,r.id_evento) FILTER (WHERE r.event_day BETWEEN CAST(:from_day AS date) AND CAST(:to_day AS date)),'[]'::jsonb) AS event_details FROM resolved_events r WHERE r.buyer_id IS NOT NULL AND r.id_evento<>51535 GROUP BY r.buyer_id), issues AS (SELECT count(*) FILTER (WHERE accounts=0 AND buyer_id IS NULL AND id_evento<>51535) AS unlinked,count(*) FILTER (WHERE accounts>1 AND buyer_id IS NULL AND id_evento<>51535) AS ambiguous,count(*) FILTER (WHERE (id_evento IN (43381,37310) AND NOT voa_linked) OR (id_evento=43657 AND NOT global_linked)) AS missing_buyer_link,count(*) FILTER (WHERE id_evento=51535) AS demos,coalesce((SELECT json_agg(row_to_json(pending) ORDER BY pending.event_day DESC,pending.id_evento) FROM (SELECT id_evento,event_name,to_char(event_day,'DD/MM/YYYY') AS event_day,account_names,accounts FROM resolved_events WHERE buyer_id IS NULL AND id_evento<>51535 ORDER BY event_day DESC,id_evento LIMIT 100) pending),'[]'::json) AS events,coalesce((SELECT json_agg(row_to_json(outside_event) ORDER BY outside_event.id_evento) FROM (SELECT r.id_evento,r.event_name,r.account_names,r.buyer_id,coalesce(buyer.nome_conta,'') AS buyer_name FROM resolved_events r LEFT JOIN public.tb_contas buyer ON buyer.id_conta=r.buyer_id WHERE r.buyer_id IS NOT NULL AND r.id_evento<>51535 AND NOT EXISTS (SELECT 1 FROM base b WHERE b.id=r.buyer_id) ORDER BY r.id_evento LIMIT 100) outside_event),'[]'::json) AS outside_events FROM resolved_events), ";
    } else sql &= " purchases AS (SELECT NULL::bigint AS id,''::text AS evidence,0::bigint AS event_count,'[]'::jsonb AS event_details WHERE false), issues AS (SELECT 0::bigint AS unlinked,0::bigint AS ambiguous), ";
    sql &= " people AS (SELECT b.*,p.id IS NOT NULL AS paid,coalesce(p.evidence,'') AS evidence,coalesce(p.event_count,0) AS event_count,coalesce(p.event_details,'[]'::jsonb) AS event_details FROM base b LEFT JOIN purchases p ON p.id=b.id), matching AS (SELECT * FROM people WHERE ";
    sql &= stage EQ "base" ? "true" : stage EQ "paid" AND mapped ? "paid" : "false";
    if (len(search)) { sql &= " AND (strpos(lower(name),lower(:search))>0 OR strpos(lower(owners),lower(:search))>0 OR CAST(id AS text)=:search)"; params.search=orgParam(search); }
    var eventProjection=mapped AND product EQ "transmissao" ? "(SELECT count(*) FROM period_events) AS transmission_count,(SELECT coalesce(json_agg(json_build_object('id',id_evento,'name',event_name,'day',to_char(event_day,'DD/MM/YYYY'),'buyer',coalesce(buyer_name,''),'buyer_id',buyer_id,'account_names',account_names,'accounts',accounts,'in_base',in_base,'manual',id_evento IN (43381,37310,43657,40209,40260)) ORDER BY event_day DESC,id_evento),'[]'::json) FROM period_events) AS transmission_events_json," : "-1::bigint AS transmission_count,'[]'::json AS transmission_events_json,";
    sql &= ") SELECT (SELECT count(*) FROM people) AS base,(SELECT count(*) FROM people WHERE paid) AS paid,(SELECT count(*) FROM matching) AS total,(SELECT row_to_json(i) FROM issues i) AS issues_json," & eventProjection & "(SELECT coalesce(json_agg(p ORDER BY p.name,p.id),'[]'::json) FROM (SELECT id,name,owners,paid,evidence,event_count,event_details FROM matching ORDER BY name,id LIMIT 25 OFFSET :offset) p) AS people_json";
    var result=queryExecute(sql,params,{datasource="runner_dba",timeout=40});
    var issues=deserializeJSON(result.issues_json[1] & "");
    var paid=mapped ? val(result.paid[1]) : -1;
    var notes=["A base conta contas com ao menos um dono ativo; funcionários ficam de fora. Uma mesma pessoa pode ser dona de mais de uma conta. A leitura por cadastro usa a data de criação da conta.","Os vínculos atuais de donos e eventos não permitem reconstruir integralmente o passado. Contas sem dono ativo atual ficam fora da base."];
    if (product EQ "patrocinio") arrayAppend(notes,"Patrocinado: intenção atualmente PAID, com data e lançamento de crédito PAYMENT correspondente. Reembolsos e alterações posteriores podem afetar a leitura histórica; vouchers não são compras. A ausência de compra nessa fonte não prova que nunca houve contratação.");
    else if (product EQ "transmissao") {
        arrayAppend(notes,"Transmissão: conforme a regra comercial informada, evento cadastrado no leaderboard representa um fechamento pago. A configuração não comprova separadamente valor, data de pagamento ou reembolso; sua data é de cadastro no leaderboard.");
        arrayAppend(notes,"As transmissões por evento incluem provas com data entre De e Até e configuradas no leaderboard até a data final, inclusive sem conta ou com várias contas. Elas são uma medida independente da coorte de contas. O total de contas que contrataram é acumulado até a data final; cada conta é contada uma vez. A data da prova não é data de pagamento.");
        if (mapped) {
            arrayAppend(notes,"Eventos no leaderboard sem atribuição comercial e sem conta ativa identificada: " & val(issues.unlinked) & "; com mais de uma conta ativa e sem atribuição: " & val(issues.ambiguous) & ". Esses eventos não são atribuídos a uma conta até conciliação. São considerados registros do leaderboard até a data final, inclusive de provas passadas e configurações inativas, independentemente da coorte. A data da prova não é data de pagamento.");
            if (val(issues.demos)) arrayAppend(notes,"O evento 51535, identificado no leaderboard como RunTV - Demonstração, foi excluído das contratações. Outros ambientes de teste dependem de identificação.");
            arrayAppend(notes,"Atribuição comercial informada pela equipe: Maringá (43381) e Maratona do Paraná (37310) pertencem à Voa Esportes (conta 27); Curitiba (43657) à Global Vita (conta 38); ASICS RJ (40209) e SP (40260) à Vega Sports (conta 60). Os vínculos operacionais das outras contas foram preservados. As atribuições da Voa e da Global exigem vínculo operacional ativo; a Vega foi atribuída pela informação da equipe, mesmo sem vínculo operacional. Essas atribuições não comprovam a data do pagamento nem o histórico do responsável.");
            if (val(issues.missing_buyer_link)) arrayAppend(notes,"Eventos com atribuição comercial informada, mas sem vínculo ativo da conta indicada: " & val(issues.missing_buyer_link) & ".");
            for (var outside in issues.outside_events) arrayAppend(notes,"Evento " & outside.id_evento & " — " & outside.event_name & ": atribuição comercial para " & (len(trim(outside.buyer_name)) ? outside.buyer_name : "conta " & outside.buyer_id) & ", mas a conta está fora da base selecionada de contas com dono ativo ou fora das datas.");
            for (var item in issues.events) arrayAppend(notes,"Evento " & item.id_evento & " — " & item.event_name & " (" & item.event_day & "): " & (val(item.accounts) EQ 0 ? "sem conta ativa identificada" : "contas vinculadas: " & item.account_names) & ".");
            if (val(issues.unlinked)+val(issues.ambiguous) GT 100) arrayAppend(notes,"A lista acima apresenta até 100 eventos pendentes; os totais incluem todos.");
        }
    } else arrayAppend(notes,"Selecione Patrocínio ou Transmissão para consultar as fontes desse produto. Os demais produtos não foram consolidados nesta visão.");
    if (!mapped AND (product EQ "patrocinio" OR product EQ "transmissao")) arrayAppend(notes,"As colunas necessárias não estão disponíveis neste datasource; a contratação não foi calculada.");
    return {metrics={base=val(result.base[1]),paid=paid,transmissions=val(result.transmission_count[1]),related=-1,active=-1,monthly_active=-1,renewed=-1,registered_only=-1,related_without_term=-1,term_active=-1,continuous=-1,renewed_period=-1,expired_period=-1},people=deserializeJSON(result.people_json[1] & ""),transmission_events=deserializeJSON(result.transmission_events_json[1] & ""),total=val(result.total[1]),page=val(page),page_size=25,coverage={payments_mapped=mapped,related_mapped=false,signup_mapped=false,status_c_mapped=false,notes=notes},filters={publico="organizers",produto=product,leitura=reading,de=fromDay,ate=toDay},generated_at=dateTimeFormat(now(),"dd/mm/yyyy HH:nn","America/Sao_Paulo")};
}
VARIABLES.funnelReport=orgReport();
</cfscript>
