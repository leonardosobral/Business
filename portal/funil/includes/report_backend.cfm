<!--- This include is intentionally read-only and uses the existing CF datasource. --->
<cfinclude template="../../../includes/backend/require_admin.cfm"/>
<cfinclude template="../../../includes/backend/require_real_platform_context.cfm"/>
<cfscript>
function funnelInput(required string key, string fallback="") {
    if (!structKeyExists(URL,key)) return fallback;
    if (!isSimpleValue(URL[key])) throw(type="FunnelInput",message="Invalid filter");
    return trim(URL[key] & "");
}
function funnelParam(required any value, string type="cf_sql_varchar") {
    return {value=value,cfsqltype=type};
}
function funnelQuery(required string sql, struct params={}) {
    try {
        return queryExecute(sql,params,{datasource="runner_dba",timeout=40});
    } catch (any failure) {
        // Log categories only: database details may contain SQL or personal data.
        var detail=(structKeyExists(failure,"detail") ? failure.detail & " " : "") & failure.message;
        var state=structKeyExists(failure,"sqlState") AND reFind("^[A-Z0-9]{5}$",failure.sqlState & "") ? failure.sqlState : "unknown";
        writeLog(file="application",type="error",text="Business funnel database diagnostic: state=" & state & "; timeout=" & (reFindNoCase("timeout|timed out|canceling statement",detail)>0) & "; parameter=" & (reFindNoCase("parameter|parametro",detail)>0) & "; column=" & (reFindNoCase("column.*does not exist|column.*ambiguous",detail)>0) & "; syntax=" & (reFindNoCase("syntax error",detail)>0) & "; permission=" & (reFindNoCase("permission denied",detail)>0));
        rethrow;
    }
}
function funnelDay(required string value) {
    if (!reFind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",value)) throw(type="FunnelInput",message="Invalid date");
    try {
        var d=createDate(val(left(value,4)),val(mid(value,6,2)),val(right(value,2)));
        if (dateFormat(d,"yyyy-mm-dd") NEQ value OR year(d) LT 2000) throw(type="FunnelInput",message="Invalid date");
        return d;
    } catch (any invalid) { throw(type="FunnelInput",message="Invalid date"); }
}
function funnelHas(required string table, required string columns) {
    if (!structKeyExists(VARIABLES.funnelColumns,table)) return false;
    for (var col in listToArray(columns)) if (!listFindNoCase(VARIABLES.funnelColumns[table],col)) return false;
    return true;
}
function funnelBuildReport() {
VARIABLES.funnelToday=dateTimeFormat(now(),"yyyy-mm-dd","America/Sao_Paulo");
VARIABLES.funnelFrom=funnelInput("de",left(VARIABLES.funnelToday,4) & "-01-01");
VARIABLES.funnelTo=funnelInput("ate",VARIABLES.funnelToday);
VARIABLES.funnelStart=funnelDay(VARIABLES.funnelFrom);
VARIABLES.funnelFinish=funnelDay(VARIABLES.funnelTo);
if (dateCompare(VARIABLES.funnelStart,VARIABLES.funnelFinish) GT 0 OR dateCompare(VARIABLES.funnelFinish,funnelDay(VARIABLES.funnelToday)) GT 0) throw(type="FunnelInput",message="Invalid range");
VARIABLES.funnelAudience=funnelInput("publico","athletes");
VARIABLES.funnelProduct=funnelInput("produto","desafio");
VARIABLES.funnelReading=funnelInput("leitura","base");
VARIABLES.funnelStage=funnelInput("etapa","base");
VARIABLES.funnelPage=funnelInput("pagina","1");
VARIABLES.funnelSearch=left(funnelInput("busca"),80);
if (!listFind("athletes,organizers",VARIABLES.funnelAudience) OR !listFind("all,desafio,selo,assinatura,gorunners,comparador,estudo,patrocinio,transmissao,perfil,dados",VARIABLES.funnelProduct) OR !listFind("base,cohort",VARIABLES.funnelReading) OR !listFind("base,related,paid,unpaid,unproven,active,monthly,renewed,expired,coupon,status_c",VARIABLES.funnelStage) OR !reFind("^[1-9][0-9]{0,4}$",VARIABLES.funnelPage)) throw(type="FunnelInput",message="Invalid filter");
VARIABLES.funnelColumns={};
VARIABLES.funnelMetadata=funnelQuery("SELECT table_schema,table_name,column_name,data_type FROM information_schema.columns WHERE (table_schema='public' AND table_name IN ('tb_usuarios','tb_transacoes','tb_webhook','desafios','tb_contas','tb_conta_usuarios','tb_conta_eventos','tb_ticketsports_participantes','tb_ticketsports_pedidos')) OR (table_schema='crm_interno' AND table_name IN ('conversion_order_state','pagarme_order_audit','challenge_signup_events')) OR (table_schema='gorunners' AND table_name='users')");
VARIABLES.funnelTypes={};
for (var column in VARIABLES.funnelMetadata) {
    var key=column.table_schema & "." & column.table_name;
    if (!structKeyExists(VARIABLES.funnelColumns,key)) VARIABLES.funnelColumns[key]="";
    VARIABLES.funnelColumns[key]=listAppend(VARIABLES.funnelColumns[key],column.column_name);
    VARIABLES.funnelTypes[key & "." & column.column_name]=column.data_type;
}
if (!funnelHas("public.tb_usuarios","id,name,data_criacao")) throw(type="FunnelSource",message="User source unavailable");
VARIABLES.funnelAccounts=funnelHas("public.tb_contas","id_conta,data_criacao,nome_conta") AND funnelHas("public.tb_conta_usuarios","id_conta,id_usuario,papel,status,data_criacao");
VARIABLES.funnelEnrollments=funnelHas("public.desafios","id_usuario,desafio,data_inscricao");
VARIABLES.funnelFinance=funnelHas("crm_interno.conversion_order_state","source,account_scope,order_key,user_id,match_basis,product_code,paid_at,status,classification,coverage_kind") AND funnelHas("crm_interno.pagarme_order_audit","provider_order_id,classification");
VARIABLES.funnelLegacy=funnelHas("public.tb_transacoes","id_usuario,codigo_transacao,origem_transacao,status_atual,valor_transacao,json_transacao");
if (VARIABLES.funnelLegacy) VARIABLES.funnelLegacy=listFind("json,jsonb",VARIABLES.funnelTypes["public.tb_transacoes.json_transacao"]) GT 0;
VARIABLES.funnelWebhook=funnelHas("public.tb_webhook","referencia,body,call_date") AND funnelHas("public.desafios","id_usuario,desafio,produto,num_pedido");
VARIABLES.funnelSignup=funnelHas("crm_interno.challenge_signup_events","user_id,challenge_code,occurred_at,method,campaign_id");
VARIABLES.funnelCouponsMapped=false; // Coupon commission is outside the current funnel scope.
VARIABLES.funnelChallenge=VARIABLES.funnelAudience EQ "athletes" AND listFind("all,desafio",VARIABLES.funnelProduct) GT 0;
VARIABLES.funnelGoRunners=VARIABLES.funnelAudience EQ "athletes" AND VARIABLES.funnelProduct EQ "gorunners";
VARIABLES.funnelGoMapped=VARIABLES.funnelGoRunners AND funnelHas("gorunners.users","id,rr_user_id,created_at");
// Status C is the current operational state, not a dated payment event.
VARIABLES.funnelStatusCMapped=VARIABLES.funnelChallenge AND VARIABLES.funnelTo EQ VARIABLES.funnelToday AND funnelHas("public.desafios","id_usuario,desafio,produto,status");
VARIABLES.funnelPaymentsMapped=VARIABLES.funnelChallenge AND (VARIABLES.funnelFinance OR VARIABLES.funnelLegacy OR VARIABLES.funnelStatusCMapped);
VARIABLES.funnelTermsMapped=VARIABLES.funnelChallenge AND (VARIABLES.funnelFinance OR VARIABLES.funnelLegacy);
VARIABLES.funnelRelatedMapped=VARIABLES.funnelGoMapped OR (VARIABLES.funnelChallenge AND (VARIABLES.funnelEnrollments OR VARIABLES.funnelSignup OR VARIABLES.funnelFinance OR VARIABLES.funnelLegacy OR VARIABLES.funnelWebhook));
if (VARIABLES.funnelAudience EQ "organizers" AND !VARIABLES.funnelAccounts) throw(type="FunnelSource",message="Account source unavailable");
VARIABLES.funnelParams={from_day=funnelParam(VARIABLES.funnelFrom),to_day=funnelParam(VARIABLES.funnelTo)};
// End of day is exclusive, in the Business timezone. Calendar-year arithmetic
// matches the existing Desafio membership service, including leap years.
VARIABLES.funnelSQL="WITH bounds AS (SELECT CAST(:from_day AS date) AT TIME ZONE 'America/Sao_Paulo' AS starts_at,(CAST(:to_day AS date)+1) AT TIME ZONE 'America/Sao_Paulo' AS until_at,date_trunc('month',CAST(:to_day AS timestamp)) AT TIME ZONE 'America/Sao_Paulo' AS month_starts_at), ";
if (VARIABLES.funnelAccounts AND VARIABLES.funnelAudience EQ "organizers") {
    VARIABLES.funnelSQL &= " owners AS (SELECT cu.id_usuario,string_agg(DISTINCT c.nome_conta,', ' ORDER BY c.nome_conta) AS accounts FROM public.tb_contas c JOIN public.tb_conta_usuarios cu ON cu.id_conta=c.id_conta CROSS JOIN bounds b WHERE cu.papel::text='OWNER' AND cu.status::text='ATIVO' AND c.data_criacao<b.until_at AND cu.data_criacao<b.until_at GROUP BY cu.id_usuario), ";
}
VARIABLES.funnelSQL &= " base AS (SELECT u.id,coalesce(u.name,'') AS name,u.data_criacao";
VARIABLES.funnelSQL &= VARIABLES.funnelAudience EQ "organizers" ? ",o.accounts" : ",''::text AS accounts";
VARIABLES.funnelSQL &= " FROM public.tb_usuarios u " & (VARIABLES.funnelAudience EQ "organizers" ? " JOIN owners o ON o.id_usuario=u.id " : "") & " CROSS JOIN bounds b WHERE u.id>0 AND u.data_criacao<b.until_at ";
if (VARIABLES.funnelReading EQ "cohort") VARIABLES.funnelSQL &= " AND u.data_criacao>=b.starts_at ";
VARIABLES.funnelSQL &= "), ";
if (VARIABLES.funnelCouponsMapped) {
    VARIABLES.funnelParams.coupon_cohort=funnelParam(VARIABLES.funnelReading EQ "cohort","cf_sql_bit");
    include "ticketsports_coupons.cfm";
    VARIABLES.funnelSQL &= VARIABLES.funnelCouponSQL;
} else {
    VARIABLES.funnelSQL &= " coupon_people AS (SELECT NULL::integer AS user_id,0::bigint AS registrations,0::bigint AS events,''::text AS last_event,''::text AS last_modality,NULL::timestamp AS last_at WHERE false), coupon_stats AS (SELECT 0::bigint AS registrations,0::bigint AS matched,0::bigint AS unmatched,0::bigint AS ambiguous,0::bigint AS conflicting,0::bigint AS invalid,0::bigint AS outside_base), ";
}
if (VARIABLES.funnelPaymentsMapped) {
    if (VARIABLES.funnelFinance) {
        VARIABLES.funnelSQL &= " crm_paid AS (SELECT s.user_id,s.order_key,s.product_code,s.paid_at,'crm'::text AS payment_source FROM crm_interno.conversion_order_state s JOIN crm_interno.pagarme_order_audit a ON a.provider_order_id=s.order_key AND a.classification='confirmed' CROSS JOIN bounds b WHERE s.source='pagarme' AND s.account_scope='roadrunners' AND s.coverage_kind IN ('linked_future','provider_historical') AND s.classification='confirmed' AND s.status='confirmed' AND s.match_basis='checkout_authenticated' AND s.user_id IS NOT NULL AND s.paid_at<b.until_at AND s.product_code IN ('todosantodia','todosantodiavip','todosantodiaupg')), ";
    } else VARIABLES.funnelSQL &= " crm_paid AS (SELECT NULL::integer AS user_id,''::text AS order_key,''::text AS product_code,NULL::timestamptz AS paid_at,'crm'::text AS payment_source WHERE false), ";
    if (VARIABLES.funnelLegacy) {
        VARIABLES.funnelParams.is_today=funnelParam(VARIABLES.funnelTo EQ VARIABLES.funnelToday,"cf_sql_bit");
        include "legacy_payments.cfm";
        VARIABLES.funnelAuditGuard=VARIABLES.funnelFinance ? " AND NOT EXISTS (SELECT 1 FROM crm_interno.pagarme_order_audit a WHERE a.provider_order_id=l.order_key AND a.classification<>'confirmed') " : "";
        VARIABLES.funnelSQL &= replace(VARIABLES.funnelLegacySQL,"/* FUNNEL_LEGACY_AUDIT_GUARD */",VARIABLES.funnelAuditGuard);
    } else VARIABLES.funnelSQL &= " legacy_paid AS (SELECT NULL::integer AS user_id,''::text AS order_key,''::text AS product_code,NULL::timestamptz AS paid_at,'legacy'::text AS payment_source WHERE false), ";
    VARIABLES.funnelSQL &= " webhook_paid AS (SELECT NULL::integer AS user_id,''::text AS order_key,''::text AS product_code,NULL::timestamptz AS paid_at,'webhook'::text AS payment_source WHERE false), ";
    VARIABLES.funnelSQL &= " verified AS (SELECT DISTINCT ON (order_key) user_id,order_key,product_code,paid_at,((paid_at AT TIME ZONE 'America/Sao_Paulo')+interval '1 year') AT TIME ZONE 'America/Sao_Paulo' AS ends_at,payment_source FROM (SELECT * FROM crm_paid UNION ALL SELECT * FROM legacy_paid UNION ALL SELECT * FROM webhook_paid) combined WHERE product_code IN ('todosantodia','todosantodiavip','todosantodiaupg') ORDER BY order_key,CASE payment_source WHEN 'crm' THEN 0 WHEN 'legacy' THEN 1 ELSE 2 END), annual AS (SELECT * FROM verified WHERE product_code IN ('todosantodia','todosantodiavip') AND paid_at IS NOT NULL), payments AS (SELECT v.user_id,count(*) AS orders,string_agg(DISTINCT v.payment_source,',') AS payment_sources,count(*) FILTER(WHERE v.product_code IN ('desafio365','desafio365vip','inscricao365','inscricao365vip')) AS orders_365,count(*) FILTER(WHERE v.product_code IN ('todosantodia','todosantodiavip')) AS tsd_orders,count(*) FILTER(WHERE v.product_code IN ('todosantodia','todosantodiavip') AND v.paid_at IS NOT NULL) AS annual_orders,count(*) FILTER(WHERE v.product_code IN ('todosantodia','todosantodiavip') AND v.paid_at IS NULL) AS undated_tsd_orders,max(v.ends_at) FILTER(WHERE v.product_code IN ('todosantodia','todosantodiavip')) AS ends_at,max(v.paid_at) FILTER(WHERE v.product_code IN ('todosantodia','todosantodiavip')) AS starts_at FROM verified v GROUP BY v.user_id), term_ordered AS (SELECT a.*,max(a.ends_at) OVER(PARTITION BY a.user_id ORDER BY a.paid_at,a.order_key ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS previous_end FROM annual a), term_groups AS (SELECT t.*,sum(CASE WHEN previous_end IS NULL OR paid_at>previous_end THEN 1 ELSE 0 END) OVER(PARTITION BY user_id ORDER BY paid_at,order_key) AS term_group FROM term_ordered t), spans AS (SELECT user_id,min(paid_at) AS starts_at,max(ends_at) AS ends_at FROM term_groups GROUP BY user_id,term_group), continuous AS (SELECT DISTINCT s.user_id FROM spans s CROSS JOIN bounds b WHERE s.starts_at<=b.starts_at AND s.ends_at>=b.until_at), monthly_active AS (SELECT DISTINCT s.user_id FROM spans s CROSS JOIN bounds b WHERE s.starts_at<b.until_at AND s.ends_at>b.month_starts_at), renewals AS (SELECT NULL::integer AS user_id WHERE false), ";
} else {
    VARIABLES.funnelSQL &= " payments AS (SELECT NULL::integer AS user_id,0::bigint AS orders,0::bigint AS orders_365,0::bigint AS tsd_orders,0::bigint AS annual_orders,0::bigint AS undated_tsd_orders,''::text AS payment_sources,NULL::timestamptz AS ends_at,NULL::timestamptz AS starts_at WHERE false), continuous AS (SELECT NULL::integer AS user_id WHERE false), monthly_active AS (SELECT NULL::integer AS user_id WHERE false), renewals AS (SELECT NULL::integer AS user_id WHERE false), ";
}
if (VARIABLES.funnelChallenge AND VARIABLES.funnelEnrollments) {
    VARIABLES.funnelSQL &= " enrollments AS (SELECT DISTINCT d.id_usuario FROM public.desafios d CROSS JOIN bounds b WHERE lower(d.desafio)='todosantodia' AND d.data_inscricao<b.until_at), ";
} else VARIABLES.funnelSQL &= " enrollments AS (SELECT NULL::integer AS id_usuario WHERE false), ";
if (VARIABLES.funnelChallenge AND VARIABLES.funnelSignup) {
    VARIABLES.funnelSQL &= " signup AS (SELECT DISTINCT ON (e.user_id) e.user_id,e.method,e.campaign_id FROM crm_interno.challenge_signup_events e CROSS JOIN bounds b WHERE e.challenge_code='todosantodia' AND e.occurred_at<b.until_at ORDER BY e.user_id,e.occurred_at), ";
} else VARIABLES.funnelSQL &= " signup AS (SELECT NULL::integer AS user_id,''::text AS method,NULL::bigint AS campaign_id WHERE false), ";
if (VARIABLES.funnelGoMapped) {
    // This is a current stored identity link, not proof that a plan was purchased.
    VARIABLES.funnelSQL &= " go_accounts AS (SELECT DISTINCT g.rr_user_id AS user_id FROM gorunners.users g CROSS JOIN bounds b WHERE g.rr_user_id IS NOT NULL AND g.created_at<b.until_at), ";
} else VARIABLES.funnelSQL &= " go_accounts AS (SELECT NULL::integer AS user_id WHERE false), ";
if (VARIABLES.funnelStatusCMapped) {
    VARIABLES.funnelSQL &= " status_c AS (SELECT DISTINCT id_usuario FROM public.desafios WHERE lower(trim(desafio))='todosantodia' AND lower(trim(produto)) IN ('todosantodia','todosantodiavip') AND upper(trim(status))='C'), ";
} else VARIABLES.funnelSQL &= " status_c AS (SELECT NULL::integer AS id_usuario WHERE false), ";
VARIABLES.funnelSQL &= " people AS (SELECT u.*,sc.id_usuario IS NOT NULL AS status_c,cp.user_id IS NOT NULL AS coupon,coalesce(cp.registrations,0) AS coupon_registrations,coalesce(cp.events,0) AS coupon_events,coalesce(cp.last_event,'') AS coupon_last_event,coalesce(cp.last_modality,'') AS coupon_last_modality,cp.last_at AS coupon_last_at,(coalesce(p.tsd_orders,0)>0 OR sc.id_usuario IS NOT NULL) AS paid,false AS paid_365,coalesce(p.ends_at>=b.until_at,false) AS active,false AS renewed,coalesce(p.annual_orders,0) AS annual_orders,coalesce(p.payment_sources,'') AS payment_sources,p.starts_at,p.ends_at,coalesce(p.ends_at>=b.until_at,false) AS term_active,p.ends_at IS NOT NULL AND coalesce(p.undated_tsd_orders,0)=0 AS expiry_known,(e.id_usuario IS NOT NULL OR s.user_id IS NOT NULL OR go.user_id IS NOT NULL OR coalesce(p.tsd_orders,0)>0 OR sc.id_usuario IS NOT NULL) AS related,coalesce(s.method,'unknown') AS origin,coalesce(s.campaign_id,0) AS campaign_id,c.user_id IS NOT NULL AS continuous,ma.user_id IS NOT NULL AS monthly_active,r.user_id IS NOT NULL AS renewed_period,coalesce(p.undated_tsd_orders,0)=0 AND coalesce(p.ends_at>=b.starts_at AND p.ends_at<b.until_at,false) AS expired_period FROM base u CROSS JOIN bounds b LEFT JOIN status_c sc ON sc.id_usuario=u.id LEFT JOIN coupon_people cp ON cp.user_id=u.id LEFT JOIN payments p ON p.user_id=u.id LEFT JOIN enrollments e ON e.id_usuario=u.id LEFT JOIN signup s ON s.user_id=u.id LEFT JOIN go_accounts go ON go.user_id=u.id LEFT JOIN continuous c ON c.user_id=u.id LEFT JOIN monthly_active ma ON ma.user_id=u.id LEFT JOIN renewals r ON r.user_id=u.id) ";
VARIABLES.funnelConditions={base="true",related="related",paid="paid",unpaid="related AND NOT paid",unproven="paid AND NOT term_active",active="active",monthly="monthly_active",renewed="renewed",coupon="coupon",status_c="status_c",expired="paid AND expiry_known AND NOT term_active"};
VARIABLES.funnelWhere=" WHERE " & VARIABLES.funnelConditions[VARIABLES.funnelStage];
if ((VARIABLES.funnelStage EQ "related" AND !VARIABLES.funnelRelatedMapped) OR (VARIABLES.funnelStage EQ "paid" AND !VARIABLES.funnelPaymentsMapped)) VARIABLES.funnelWhere=" WHERE false ";
if (VARIABLES.funnelStage EQ "unpaid" AND (!VARIABLES.funnelRelatedMapped OR !VARIABLES.funnelPaymentsMapped)) VARIABLES.funnelWhere=" WHERE false ";
if (VARIABLES.funnelStage EQ "unproven" AND (!VARIABLES.funnelPaymentsMapped OR !VARIABLES.funnelTermsMapped)) VARIABLES.funnelWhere=" WHERE false ";
if (listFind("active,monthly,expired",VARIABLES.funnelStage) AND !VARIABLES.funnelTermsMapped) VARIABLES.funnelWhere=" WHERE false ";
if (VARIABLES.funnelStage EQ "coupon" AND !VARIABLES.funnelCouponsMapped) VARIABLES.funnelWhere=" WHERE false ";
if (VARIABLES.funnelStage EQ "status_c" AND !VARIABLES.funnelStatusCMapped) VARIABLES.funnelWhere=" WHERE false ";
// A compra dos dois produtos não é renovação. A definição de renovação permanece indisponível.
if (VARIABLES.funnelStage EQ "renewed") VARIABLES.funnelWhere=" WHERE false ";
if (len(VARIABLES.funnelSearch)) {
    // strpos treats % and _ literally, with no wildcard ambiguity.
    VARIABLES.funnelWhere &= " AND (strpos(lower(name),lower(:search))>0 OR CAST(id AS text)=:search) ";
    VARIABLES.funnelParams.search=funnelParam(VARIABLES.funnelSearch);
}
VARIABLES.funnelParams.offset=funnelParam((val(VARIABLES.funnelPage)-1)*25,"cf_sql_integer");
VARIABLES.funnelMetricsSQL="SELECT count(*) AS base,count(*) FILTER(WHERE status_c) AS status_c,count(*) FILTER(WHERE coupon) AS coupon,coalesce(sum(coupon_registrations),0) AS coupon_registrations,count(*) FILTER(WHERE related) AS related,count(*) FILTER(WHERE paid) AS paid,count(*) FILTER(WHERE active) AS active,count(*) FILTER(WHERE monthly_active) AS monthly_active,count(*) FILTER(WHERE renewed) AS renewed,count(*) FILTER(WHERE term_active) AS term_active,count(*) FILTER(WHERE NOT related) AS registered_only,count(*) FILTER(WHERE related AND NOT paid) AS related_unpaid,count(*) FILTER(WHERE paid AND NOT term_active) AS paid_without_term,count(*) FILTER(WHERE related AND NOT term_active) AS related_without_term,count(*) FILTER(WHERE continuous) AS continuous,count(*) FILTER(WHERE renewed_period) AS renewed_period,count(*) FILTER(WHERE expired_period) AS expired_period,count(*) FILTER(WHERE origin='last_recorded_click_7d') AS campaign_origin,count(*) FILTER(WHERE origin='none') AS no_click_origin,count(*) FILTER(WHERE related AND origin='unknown') AS unknown_origin FROM people";
VARIABLES.funnelPageSQL="SELECT id,name,accounts,status_c,related,paid,paid_365,active,monthly_active,renewed,term_active,annual_orders,payment_sources,origin,campaign_id,coupon,coupon_registrations,coupon_events,coupon_last_event,coupon_last_modality,coalesce(to_char(coupon_last_at,'DD/MM/YYYY'),'') AS coupon_last_day,coalesce(to_char(starts_at AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY'),'') AS term_start,coalesce(to_char(ends_at AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY'),'') AS term_end FROM matching ORDER BY name,id LIMIT 25 OFFSET :offset";
// Reuse the same people CTE for metrics, count and page; historical webhook
// events must not be rescanned three times for one screen update.
VARIABLES.funnelResult=funnelQuery(VARIABLES.funnelSQL & ", matching AS (SELECT * FROM people" & VARIABLES.funnelWhere & ") SELECT (SELECT row_to_json(m) FROM (" & VARIABLES.funnelMetricsSQL & ") m) AS metrics_json,(SELECT count(*) FROM matching) AS matched_total,(SELECT row_to_json(cs) FROM coupon_stats cs) AS coupon_stats_json,(SELECT coalesce(json_agg(p ORDER BY p.name,p.id),'[]'::json) FROM (" & VARIABLES.funnelPageSQL & ") p) AS people_json",VARIABLES.funnelParams);
VARIABLES.funnelMetrics=deserializeJSON(VARIABLES.funnelResult.metrics_json[1] & "");
for (var key in VARIABLES.funnelMetrics) VARIABLES.funnelMetrics[key]=val(VARIABLES.funnelMetrics[key]);
if (!VARIABLES.funnelRelatedMapped) for (var key in ["related","registered_only","related_unpaid","related_without_term","campaign_origin","no_click_origin","unknown_origin"]) VARIABLES.funnelMetrics[key]=-1;
if (!VARIABLES.funnelPaymentsMapped) for (var key in ["paid","active","renewed","term_active","continuous","renewed_period","expired_period","related_without_term","related_unpaid","paid_without_term"]) VARIABLES.funnelMetrics[key]=-1;
if (!VARIABLES.funnelTermsMapped) for (var key in ["active","monthly_active","term_active","continuous","expired_period","related_without_term","paid_without_term"]) VARIABLES.funnelMetrics[key]=-1;
if (!VARIABLES.funnelCouponsMapped) for (var key in ["coupon","coupon_registrations"]) VARIABLES.funnelMetrics[key]=-1;
if (!VARIABLES.funnelStatusCMapped) VARIABLES.funnelMetrics.status_c=-1;
VARIABLES.funnelMetrics.renewed=-1;
VARIABLES.funnelMetrics.renewed_period=-1;
VARIABLES.funnelCouponStats=deserializeJSON(VARIABLES.funnelResult.coupon_stats_json[1] & "");
for (var key in VARIABLES.funnelCouponStats) VARIABLES.funnelCouponStats[key]=val(VARIABLES.funnelCouponStats[key]);
VARIABLES.funnelPeopleTotal=val(VARIABLES.funnelResult.matched_total[1]);
VARIABLES.funnelPeople=deserializeJSON(VARIABLES.funnelResult.people_json[1] & "");
VARIABLES.funnelNotes=[
    "Todo Santo Dia: inscrição básica ou VIP com status C indica compra e acesso no estado atual, inclusive sem número de pedido. Não fornece data de pagamento ou vigência nem garante ausência de reembolso. Em datas anteriores, apenas pagamentos com data são considerados.",
    "Os grupos são distintos: sem vínculo conhecido; com vínculo e sem compra identificada; comprador sem vigência comprovada; e vigência comprovada. Sem compra identificada não significa que não houve pagamento.",
    "Ativos no mês: pessoas com vigência anual confirmada em qualquer momento do mês da data final, até o fim dessa data. Status C sem data financeira não estabelece vigência; a inscrição é uma data de cadastro, não prova de pagamento.",
    "Pagamentos identificados por CRM e transações legadas usam o estado financeiro atualmente conhecido e podem ser parciais. A ausência de pagamento registrado não prova que a pessoa nunca pagou.",
    "Vigência comprovada: 12 meses a partir do pagamento anual identificável e datado. Datas sem fuso na resposta Pagar.me são interpretadas como UTC e exibidas no horário de São Paulo. Upgrade isolado não inicia uma nova vigência. Compras sem data não recebem vigência inventada.",
    "Renovação do mesmo produto será exibida quando os pedidos e a regra de renovação estiverem reconciliados. O Desafio 365 é outro produto e não faz parte deste recorte.",
    "Os filtros de data não restauram reembolsos posteriores nem o histórico de status. As datas de inscrição podem ser atualizadas; a origem geral do cadastro pode ser desconhecida.",
    "A leitura Cadastros no período limita a base pelo cadastro, enquanto as compras são acumuladas até a data final. Os percentuais referem-se a pessoas únicas dessa base."
];
if (!VARIABLES.funnelChallenge) VARIABLES.funnelNotes=VARIABLES.funnelGoMapped ? ["Go Runners: pessoas únicas do RunnerHub com cadastro Go Runners e vínculo rr_user_id correspondente. Contas Go Runners sem este identificador ou com referência inválida não entram; e-mail não é usado para associação automática.","O cadastro Go Runners precisa existir até a data final, mas a data do vínculo atual não é conhecida: filtros históricos não reconstituem quando as contas foram vinculadas nem registros removidos.","Este é um indicador de cadastro, não de pagamento ou atividade. Assinaturas, vigências e renovações ainda dependem da validação das fontes."] : ["Esta fonte de produto ainda não foi reconciliada para o público selecionado. O total de cadastros pode ser consultado, mas os pagamentos, a vigência e a renovação permanecem indisponíveis."];
if (VARIABLES.funnelAudience EQ "organizers") arrayPrepend(VARIABLES.funnelNotes,"Organizadores: pessoas com vínculo OWNER ativo em tb_conta_usuarios e conta criada até a data final. Uma pessoa é contada uma vez, mesmo com várias contas. Funcionários são excluídos. As contas também podem incluir parceiros; o papel e o status atuais não reconstituem todos os donos anteriores. Pagamentos por produto de organizadores ainda não estão mapeados.");
if (VARIABLES.funnelChallenge AND !VARIABLES.funnelFinance AND !VARIABLES.funnelLegacy) arrayPrepend(VARIABLES.funnelNotes,"As fontes de confirmação financeira necessárias não estão disponíveis neste datasource. Cadastros podem ser exibidos; pagamentos e vigências permanecem indisponíveis.");
return {
    metrics=VARIABLES.funnelMetrics,people=VARIABLES.funnelPeople,total=VARIABLES.funnelPeopleTotal,page=val(VARIABLES.funnelPage),page_size=25,
    coverage={gorunners_mapped=VARIABLES.funnelGoMapped,status_c_mapped=VARIABLES.funnelStatusCMapped,coupons_mapped=VARIABLES.funnelCouponsMapped,coupon_stats=VARIABLES.funnelCouponStats,related_mapped=VARIABLES.funnelRelatedMapped,payments_mapped=VARIABLES.funnelPaymentsMapped,signup_mapped=VARIABLES.funnelChallenge AND VARIABLES.funnelSignup,legacy_mapped=VARIABLES.funnelLegacy,webhook_mapped=VARIABLES.funnelWebhook,crm_mapped=VARIABLES.funnelFinance,partial=true,notes=VARIABLES.funnelNotes},
    filters={publico=VARIABLES.funnelAudience,produto=VARIABLES.funnelProduct,leitura=VARIABLES.funnelReading,de=VARIABLES.funnelFrom,ate=VARIABLES.funnelTo},
    generated_at=dateTimeFormat(now(),"dd/mm/yyyy HH:nn","America/Sao_Paulo")
};
}
VARIABLES.funnelReport=funnelBuildReport();
</cfscript>
