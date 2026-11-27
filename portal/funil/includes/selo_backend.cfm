<!--- Leitura das compras diretas do Selo; autorização no report.cfm. --->
<cfscript>
function seloInput(required string key, string fallback="") {
    if (!structKeyExists(URL,key)) return fallback;
    if (!isSimpleValue(URL[key])) throw(type="FunnelInput",message="Invalid filter");
    return trim(URL[key] & "");
}
function seloDay(required string value) {
    if (!reFind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",value)) throw(type="FunnelInput",message="Invalid date");
    try {
        var day=createDate(val(left(value,4)),val(mid(value,6,2)),val(right(value,2)));
        if (dateFormat(day,"yyyy-mm-dd") NEQ value OR year(day) LT 2000) throw(type="FunnelInput",message="Invalid date");
        return day;
    } catch (any invalid) { throw(type="FunnelInput",message="Invalid date"); }
}
function seloParam(required any value, string type="cf_sql_varchar") { return {value=value,cfsqltype=type}; }
function seloOrderSources(required boolean snapshots, required boolean legacy) {
    var sources = [];
    if (snapshots) arrayAppend(sources, "
        SELECT e.order_id, 1 AS priority, e.id, e.created_at AS observed_at,
               CASE WHEN lower(e.details->>'source')='referral' THEN coalesce(nullif(lower(e.details->>'referrer_host'),''),'referral') ELSE lower(e.details->>'source') END AS channel,
               e.details->>'campaign' AS campaign, e.details->>'page_view_id' AS page_key, e.details->>'entry' AS entry,
               coalesce(e.details->>'is_internal','false')='true' OR e.details->>'environment'<>'prod' AS internal
        FROM rr_verified.payment_events e JOIN selo_paid p ON p.id=e.order_id
        WHERE e.event_type='offer_attribution_v1'");
    if (legacy) arrayAppend(sources, "
        SELECT a.order_id, 2, a.id, a.observed_at, lower(a.channel), a.campaign, NULL::text, NULL::text, false
        FROM rr_verified.order_attributions a JOIN selo_paid p ON p.id=a.order_id
        WHERE a.observed_at<=p.paid_at AND a.observed_at>=p.paid_at-interval '7 days'");
    if (!arrayLen(sources)) arrayAppend(sources,"SELECT NULL::uuid AS order_id,2 AS priority,0 AS id,NULL::timestamptz AS observed_at,NULL::text AS channel,NULL::text AS campaign,NULL::text AS page_key,NULL::text AS entry,false AS internal WHERE false");
    return "selo_source_candidates(order_id,priority,id,observed_at,channel,campaign,page_key,entry,internal) AS (" & arrayToList(sources," UNION ALL ") & "),
            selo_source_latest AS (SELECT DISTINCT ON (order_id) order_id,channel,campaign,page_key,entry,internal FROM selo_source_candidates ORDER BY order_id,priority,observed_at DESC,id DESC),
            selo_order_sources AS (SELECT p.id,p.user_id,p.paid_at,coalesce(a.channel,'') AS channel,coalesce(a.campaign,'') AS campaign,a.page_key,a.entry,coalesce(a.internal,false) AS internal FROM selo_paid p LEFT JOIN selo_source_latest a ON a.order_id=p.id)";
}
function seloReport() {
    var today=dateTimeFormat(now(),"yyyy-mm-dd","America/Sao_Paulo");
    var fromDay=seloInput("de",left(today,4) & "-01-01");
    var toDay=seloInput("ate",today);
    var reading=seloInput("leitura","base");
    var stage=seloInput("etapa","base");
    var page=seloInput("pagina","1");
    var search=left(seloInput("busca"),80);
    if (dateCompare(seloDay(fromDay),seloDay(toDay)) GT 0 OR dateCompare(seloDay(toDay),seloDay(today)) GT 0 OR !listFind("base,cohort",reading) OR !listFind("base,related,paid,unpaid,unproven,active,monthly,renewed,expired",stage) OR !reFind("^[1-9][0-9]{0,4}$",page)) throw(type="FunnelInput",message="Invalid filter");
    var metadata=queryExecute("SELECT table_schema,table_name,column_name FROM information_schema.columns WHERE (table_schema='public' AND table_name='tb_usuarios') OR (table_schema='rr_verified' AND table_name IN ('orders','grants','payment_events','order_attributions'))",{},{datasource="runner_dba",timeout=40});
    var cols={};
    for (var col in metadata) {
        var key=col.table_schema & "." & col.table_name;
        if (!structKeyExists(cols,key)) cols[key]="";
        cols[key]=listAppend(cols[key],col.column_name);
    }
    var required={"public.tb_usuarios"="id,name,data_criacao"};
    for (var tableName in required) for (var columnName in listToArray(required[tableName])) if (!structKeyExists(cols,tableName) OR !listFindNoCase(cols[tableName],columnName)) throw(type="FunnelSource",message="User source unavailable");
    var ordersMapped=structKeyExists(cols,"rr_verified.orders");
    for (var c in listToArray("id,user_id,profile_id,product_code,state,paid_at,created_at")) if (!ordersMapped OR !listFindNoCase(cols["rr_verified.orders"],c)) ordersMapped=false;
    var eventsMapped=structKeyExists(cols,"rr_verified.payment_events");
    for (var c in listToArray("order_id,event_type")) if (!eventsMapped OR !listFindNoCase(cols["rr_verified.payment_events"],c)) eventsMapped=false;
    ordersMapped=ordersMapped AND eventsMapped;
    var termsMapped=ordersMapped AND structKeyExists(cols,"rr_verified.grants");
    for (var c in listToArray("order_id,profile_id,origin,starts_at,ends_at,revoked_at")) if (!termsMapped OR !listFindNoCase(cols["rr_verified.grants"],c)) termsMapped=false;
    var legacyAttribution=ordersMapped AND structKeyExists(cols,"rr_verified.order_attributions");
    for (var c in listToArray("id,order_id,channel,campaign,observed_at")) if (!legacyAttribution OR !listFindNoCase(cols["rr_verified.order_attributions"],c)) legacyAttribution=false;
    var snapshots=ordersMapped AND listFindNoCase(cols["rr_verified.payment_events"],"details") AND listFindNoCase(cols["rr_verified.payment_events"],"created_at") AND listFindNoCase(cols["rr_verified.payment_events"],"id");
    var attributionMapped=snapshots OR legacyAttribution;
    var params={from_day=seloParam(fromDay),to_day=seloParam(toDay),offset=seloParam((val(page)-1)*25,"cf_sql_integer")};
    var sql="WITH bounds AS (SELECT CAST(:from_day AS date) AT TIME ZONE 'America/Sao_Paulo' AS starts_at,(CAST(:to_day AS date)+1) AT TIME ZONE 'America/Sao_Paulo' AS until_at,date_trunc('month',CAST(:to_day AS timestamp)) AT TIME ZONE 'America/Sao_Paulo' AS month_start), base AS (SELECT u.id,coalesce(u.name,'') AS name FROM public.tb_usuarios u CROSS JOIN bounds b WHERE u.id>0 AND u.data_criacao<b.until_at";
    if (reading EQ "cohort") sql &= " AND u.data_criacao>=b.starts_at";
    sql &= "), ";
    if (ordersMapped) {
        params.is_today=seloParam(toDay EQ today,"cf_sql_bit");
        sql &= "selo_attempts AS (SELECT DISTINCT o.user_id FROM rr_verified.orders o CROSS JOIN bounds b WHERE o.product_code='rr_selo_verificado_anual' AND o.state<>'refunded' AND NOT EXISTS (SELECT 1 FROM rr_verified.payment_events e WHERE e.order_id=o.id AND e.event_type='refunded') AND o.created_at<b.until_at), selo_paid AS (SELECT o.id,o.user_id,o.profile_id,o.paid_at FROM rr_verified.orders o CROSS JOIN bounds b WHERE o.product_code='rr_selo_verificado_anual' AND o.state='paid' AND NOT EXISTS (SELECT 1 FROM rr_verified.payment_events e WHERE e.order_id=o.id AND e.event_type='refunded') AND (o.paid_at<b.until_at OR (o.paid_at IS NULL AND :is_today))), ";
    } else sql &= "selo_attempts AS (SELECT NULL::integer AS user_id WHERE false), selo_paid AS (SELECT NULL::uuid AS id,NULL::integer AS user_id,NULL::integer AS profile_id,NULL::timestamptz AS paid_at WHERE false), ";
    if (termsMapped) sql &= "selo_terms AS (SELECT o.user_id,g.starts_at,least(g.ends_at,coalesce(g.revoked_at,'infinity'::timestamptz)) AS ends_at FROM selo_paid o JOIN rr_verified.grants g ON g.order_id=o.id AND g.profile_id=o.profile_id AND g.origin='paid' WHERE o.paid_at IS NOT NULL AND g.starts_at IS NOT NULL AND g.ends_at IS NOT NULL AND least(g.ends_at,coalesce(g.revoked_at,'infinity'::timestamptz))>g.starts_at), ";
    else sql &= "selo_terms AS (SELECT NULL::integer AS user_id,NULL::timestamptz AS starts_at,NULL::timestamptz AS ends_at WHERE false), ";
    sql &= seloOrderSources(snapshots,legacyAttribution) & ", ";
    sql &= "paid_users AS (SELECT user_id,count(*) AS orders FROM selo_paid GROUP BY user_id), latest_source AS (SELECT DISTINCT ON (user_id) user_id,channel,campaign FROM selo_order_sources ORDER BY user_id,paid_at DESC NULLS LAST,id DESC), latest_term AS (SELECT DISTINCT ON (t.user_id) t.user_id,t.starts_at,t.ends_at FROM selo_terms t CROSS JOIN bounds b ORDER BY t.user_id,CASE WHEN t.starts_at<b.until_at AND t.ends_at>=b.until_at THEN 0 WHEN t.starts_at<b.until_at THEN 1 ELSE 2 END,CASE WHEN t.starts_at<b.until_at THEN t.ends_at END DESC NULLS LAST,t.starts_at ASC), current_term AS (SELECT DISTINCT t.user_id FROM selo_terms t CROSS JOIN bounds b WHERE t.starts_at<b.until_at AND t.ends_at>=b.until_at), monthly_term AS (SELECT DISTINCT t.user_id FROM selo_terms t CROSS JOIN bounds b WHERE t.starts_at<b.until_at AND t.ends_at>b.month_start), people AS (SELECT b.id,b.name,''::text AS accounts,(a.user_id IS NOT NULL OR p.user_id IS NOT NULL) AS related,p.user_id IS NOT NULL AS paid,ct.user_id IS NOT NULL AS active,mt.user_id IS NOT NULL AS monthly_active,ct.user_id IS NOT NULL AS term_active,lt.starts_at,lt.ends_at,coalesce(p.orders,0) AS annual_orders,coalesce(ls.channel,'') AS campaign_channel,coalesce(ls.campaign,'') AS campaign_name FROM base b LEFT JOIN selo_attempts a ON a.user_id=b.id LEFT JOIN paid_users p ON p.user_id=b.id LEFT JOIN latest_source ls ON ls.user_id=b.id LEFT JOIN latest_term lt ON lt.user_id=b.id LEFT JOIN current_term ct ON ct.user_id=b.id LEFT JOIN monthly_term mt ON mt.user_id=b.id), matching AS (SELECT * FROM people WHERE ";
    var conditions={base="true",related="related",paid="paid",unpaid="related AND NOT paid",unproven="paid AND NOT term_active",active="active",monthly="monthly_active",renewed="false",expired="paid AND ends_at IS NOT NULL AND ends_at < (SELECT until_at FROM bounds)"};
    if ((listFind("related,paid,unpaid",stage) AND !ordersMapped) OR (listFind("unproven,active,monthly,expired",stage) AND !termsMapped)) sql &= "false";
    else sql &= conditions[stage];
    if (len(search)) { sql &= " AND (strpos(lower(name),lower(:search))>0 OR CAST(id AS text)=:search)"; params.search=seloParam(search); }
    var attributionProjection=attributionMapped ? "(SELECT coalesce(json_agg(row_to_json(a) ORDER BY a.orders DESC,a.channel,a.campaign),'[]'::json) FROM (SELECT coalesce(nullif(s.channel,''),'unknown') AS channel,s.campaign,count(*) AS orders,count(DISTINCT s.user_id) AS users FROM selo_order_sources s JOIN matching b ON b.id=s.user_id GROUP BY 1,2) a)" : "'[]'::json";
    sql &= ") SELECT (SELECT row_to_json(m) FROM (SELECT count(*) AS base,count(*) FILTER (WHERE related) AS related,count(*) FILTER (WHERE paid) AS paid,count(*) FILTER (WHERE active) AS active,count(*) FILTER (WHERE monthly_active) AS monthly_active,count(*) FILTER (WHERE term_active) AS term_active,count(*) FILTER (WHERE NOT related) AS registered_only,count(*) FILTER (WHERE related AND NOT paid) AS related_unpaid,count(*) FILTER (WHERE paid AND NOT term_active) AS paid_without_term,count(*) FILTER (WHERE related AND NOT term_active) AS related_without_term,-1::integer AS renewed,-1::integer AS continuous,-1::integer AS renewed_period,-1::integer AS expired_period,-1::integer AS coupon,-1::integer AS status_c FROM people) m) AS metrics_json,(SELECT count(*) FROM matching) AS total," & attributionProjection & " AS attribution_json,(SELECT coalesce(json_agg(row_to_json(p) ORDER BY p.name,p.id),'[]'::json) FROM (SELECT id,name,accounts,related,paid,term_active,monthly_active,annual_orders,campaign_channel,campaign_name,'selo'::text AS payment_sources,'unknown'::text AS origin,coalesce(to_char(starts_at AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY'),'') AS term_start,coalesce(to_char(ends_at AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY'),'') AS term_end FROM matching ORDER BY name,id LIMIT 25 OFFSET :offset) p) AS people_json";
    var result=queryExecute(sql,params,{datasource="runner_dba",timeout=40});
    var metrics=deserializeJSON(result.metrics_json[1] & "");
    for (var key in metrics) metrics[key]=val(metrics[key]);
    if (!ordersMapped) for (var key in ["related","paid","registered_only","related_unpaid"]) metrics[key]=-1;
    if (!termsMapped) for (var key in ["active","monthly_active","term_active","related_without_term","paid_without_term"]) metrics[key]=-1;
    var notes=["Selo Verificado: somente compra direta de rr_verified.orders com estado atual pago. Pedidos reembolsados são excluídos inclusive do histórico; outro pedido pago da mesma pessoa continua válido.","A vigência usa a concessão paga vinculada ao mesmo pedido e perfil. O fim é o término da concessão ou a revogação, o que acontecer primeiro. O mês inclui qualquer sobreposição até a data final.","Selos de origem legada e benefícios por VIP ou upgrade do Desafio não são compras diretas do Selo e não entram neste produto. O estado financeiro atual não reconstitui reembolsos posteriores para uma data passada.","Cada ID de usuário é contado uma vez. Um pedido pago sem data só aparece quando a data final é hoje e não comprova uma vigência."];
    arrayAppend(notes,"A origem vem da sessão registrada ao criar o pedido. Quando existe histórico de campanha legado, vale o último vínculo registrado até sete dias antes do pagamento. A lista de pessoas mostra a origem do pedido pago mais recente; o resumo agrupa pedidos, que podem repetir pessoas. Compras antigas sem registro ficam como não identificadas.");
    if (!ordersMapped) arrayPrepend(notes,"As tabelas de pedidos ou eventos de pagamento do Selo não estão disponíveis neste datasource; as compras não foram calculadas.");
    else if (!termsMapped) arrayPrepend(notes,"A tabela de concessões do Selo não está disponível neste datasource; a vigência não foi calculada.");
    var offer={available=false};
    try {
        if (ordersMapped AND snapshots) {
            var statement=fileRead(expandPath("/portal/funil/includes/offer_conversion.sql"),"UTF-8");
            statement=replace(statement,"/* ORDER_SOURCES */",seloOrderSources(snapshots,legacyAttribution));
            var conversion=queryExecute(statement,{from_day=params.from_day,to_day=params.to_day},{datasource="runner_dba",timeout=18,cachedwithin=createTimeSpan(0,0,1,0)});
            offer={available=true,totals=deserializeJSON(conversion.totals[1] & ""),channels=deserializeJSON(conversion.channels[1] & "")};
        }
    } catch(any conversionError) {
        writeLog(file="application",type="error",text="Business offer conversion read unavailable: " & left(conversionError.type,90));
    }
    return {offer_conversion=offer,metrics=metrics,people=deserializeJSON(result.people_json[1] & ""),attribution=deserializeJSON(result.attribution_json[1] & ""),total=val(result.total[1]),page=val(page),page_size=25,coverage={related_mapped=ordersMapped,payments_mapped=ordersMapped,terms_mapped=termsMapped,attribution_mapped=attributionMapped,signup_mapped=false,status_c_mapped=false,notes=notes},filters={publico="athletes",produto="selo",leitura=reading,de=fromDay,ate=toDay},generated_at=dateTimeFormat(now(),"dd/mm/yyyy HH:nn","America/Sao_Paulo")};
}
VARIABLES.funnelReport=seloReport();
</cfscript>
