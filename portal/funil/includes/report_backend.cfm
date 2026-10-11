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
if (!listFind("athletes,organizers",VARIABLES.funnelAudience) OR !listFind("all,desafio,patrocinio,transmissao,perfil,dados",VARIABLES.funnelProduct) OR !listFind("base,cohort",VARIABLES.funnelReading) OR !listFind("base,related,paid,active,renewed,expired,coupon",VARIABLES.funnelStage) OR !reFind("^[1-9][0-9]{0,4}$",VARIABLES.funnelPage)) throw(type="FunnelInput",message="Invalid filter");
VARIABLES.funnelColumns={};
VARIABLES.funnelMetadata=funnelQuery("SELECT table_schema,table_name,column_name,data_type FROM information_schema.columns WHERE (table_schema='public' AND table_name IN ('tb_usuarios','tb_transacoes','tb_webhook','desafios','tb_contas','tb_conta_usuarios','tb_conta_eventos','tb_ticketsports_participantes','tb_ticketsports_pedidos')) OR (table_schema='crm_interno' AND table_name IN ('conversion_order_state','pagarme_order_audit','challenge_signup_events'))");
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
VARIABLES.funnelCouponsMapped=VARIABLES.funnelAudience EQ "athletes" AND funnelHas("public.tb_usuarios","id,email") AND funnelHas("public.tb_ticketsports_participantes","cod_evento,numero_inscricao,numero_pedido,body,data_pedido,email,modalidade") AND funnelHas("public.tb_ticketsports_pedidos","cod_evento,numero_pedido,body");
if (VARIABLES.funnelCouponsMapped) VARIABLES.funnelCouponsMapped=listFind("json,jsonb",VARIABLES.funnelTypes["public.tb_ticketsports_participantes.body"]) GT 0 AND listFind("json,jsonb",VARIABLES.funnelTypes["public.tb_ticketsports_pedidos.body"]) GT 0;
VARIABLES.funnelChallenge=VARIABLES.funnelAudience EQ "athletes" AND listFind("all,desafio",VARIABLES.funnelProduct) GT 0;
VARIABLES.funnelPaymentsMapped=VARIABLES.funnelChallenge AND (VARIABLES.funnelFinance OR VARIABLES.funnelLegacy OR VARIABLES.funnelWebhook);
VARIABLES.funnelRelatedMapped=VARIABLES.funnelChallenge AND (VARIABLES.funnelEnrollments OR VARIABLES.funnelSignup OR VARIABLES.funnelFinance OR VARIABLES.funnelLegacy OR VARIABLES.funnelWebhook);
if (VARIABLES.funnelAudience EQ "organizers" AND !VARIABLES.funnelAccounts) throw(type="FunnelSource",message="Account source unavailable");
VARIABLES.funnelParams={from_day=funnelParam(VARIABLES.funnelFrom),to_day=funnelParam(VARIABLES.funnelTo)};
// End of day is exclusive, in the Business timezone. Calendar-year arithmetic
// matches the existing Desafio membership service, including leap years.
VARIABLES.funnelSQL="WITH bounds AS (SELECT CAST(:from_day AS date) AT TIME ZONE 'America/Sao_Paulo' AS starts_at,(CAST(:to_day AS date)+1) AT TIME ZONE 'America/Sao_Paulo' AS until_at), ";
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
        VARIABLES.funnelSQL &= " crm_paid AS (SELECT s.user_id,s.order_key,s.product_code,s.paid_at,'crm'::text AS payment_source FROM crm_interno.conversion_order_state s JOIN crm_interno.pagarme_order_audit a ON a.provider_order_id=s.order_key AND a.classification='confirmed' CROSS JOIN bounds b WHERE s.source='pagarme' AND s.account_scope='roadrunners' AND s.coverage_kind IN ('linked_future','provider_historical') AND s.classification='confirmed' AND s.status='confirmed' AND s.match_basis='checkout_authenticated' AND s.user_id IS NOT NULL AND s.paid_at<b.until_at AND s.product_code IN ('desafio365','desafio365vip','inscricao365','inscricao365vip','todosantodia','todosantodiavip','todosantodiaupg')), ";
    } else VARIABLES.funnelSQL &= " crm_paid AS (SELECT NULL::integer AS user_id,''::text AS order_key,''::text AS product_code,NULL::timestamptz AS paid_at,'crm'::text AS payment_source WHERE false), ";
    if (VARIABLES.funnelLegacy) {
        VARIABLES.funnelParams.is_today=funnelParam(VARIABLES.funnelTo EQ VARIABLES.funnelToday,"cf_sql_bit");
        include "legacy_payments.cfm";
        VARIABLES.funnelAuditGuard=VARIABLES.funnelFinance ? " AND NOT EXISTS (SELECT 1 FROM crm_interno.pagarme_order_audit a WHERE a.provider_order_id=l.order_key AND a.classification<>'confirmed') " : "";
        VARIABLES.funnelSQL &= replace(VARIABLES.funnelLegacySQL,"/* FUNNEL_LEGACY_AUDIT_GUARD */",VARIABLES.funnelAuditGuard);
    } else VARIABLES.funnelSQL &= " legacy_paid AS (SELECT NULL::integer AS user_id,''::text AS order_key,''::text AS product_code,NULL::timestamptz AS paid_at,'legacy'::text AS payment_source WHERE false), ";
    if (VARIABLES.funnelWebhook) {
        include "webhook_365_payments.cfm";
        VARIABLES.funnelSQL &= VARIABLES.funnelWebhookSQL;
    } else VARIABLES.funnelSQL &= " webhook_paid AS (SELECT NULL::integer AS user_id,''::text AS order_key,''::text AS product_code,NULL::timestamptz AS paid_at,'webhook'::text AS payment_source WHERE false), ";
    VARIABLES.funnelSQL &= " verified AS (SELECT DISTINCT ON (order_key) user_id,order_key,product_code,paid_at,((paid_at AT TIME ZONE 'America/Sao_Paulo')+interval '1 year') AT TIME ZONE 'America/Sao_Paulo' AS ends_at,payment_source FROM (SELECT * FROM crm_paid UNION ALL SELECT * FROM legacy_paid UNION ALL SELECT * FROM webhook_paid) combined ORDER BY order_key,CASE payment_source WHEN 'crm' THEN 0 WHEN 'legacy' THEN 1 ELSE 2 END), annual AS (SELECT * FROM verified WHERE product_code IN ('todosantodia','todosantodiavip') AND paid_at IS NOT NULL), payments AS (SELECT v.user_id,count(*) AS orders,string_agg(DISTINCT v.payment_source,',') AS payment_sources,count(*) FILTER(WHERE v.product_code IN ('desafio365','desafio365vip','inscricao365','inscricao365vip')) AS orders_365,count(*) FILTER(WHERE v.product_code IN ('todosantodia','todosantodiavip')) AS tsd_orders,count(*) FILTER(WHERE v.product_code IN ('todosantodia','todosantodiavip') AND v.paid_at IS NOT NULL) AS annual_orders,count(*) FILTER(WHERE v.product_code IN ('todosantodia','todosantodiavip') AND v.paid_at IS NULL) AS undated_tsd_orders,max(v.ends_at) FILTER(WHERE v.product_code IN ('todosantodia','todosantodiavip')) AS ends_at FROM verified v GROUP BY v.user_id), term_ordered AS (SELECT a.*,max(a.ends_at) OVER(PARTITION BY a.user_id ORDER BY a.paid_at,a.order_key ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS previous_end FROM annual a), term_groups AS (SELECT t.*,sum(CASE WHEN previous_end IS NULL OR paid_at>previous_end THEN 1 ELSE 0 END) OVER(PARTITION BY user_id ORDER BY paid_at,order_key) AS term_group FROM term_ordered t), spans AS (SELECT user_id,min(paid_at) AS starts_at,max(ends_at) AS ends_at FROM term_groups GROUP BY user_id,term_group), continuous AS (SELECT DISTINCT s.user_id FROM spans s CROSS JOIN bounds b WHERE s.starts_at<=b.starts_at AND s.ends_at>=b.until_at), renewals AS (SELECT DISTINCT a.user_id FROM annual a JOIN payments p ON p.user_id=a.user_id CROSS JOIN bounds b WHERE a.paid_at>=b.starts_at AND p.orders_365>0), ";
} else {
    VARIABLES.funnelSQL &= " payments AS (SELECT NULL::integer AS user_id,0::bigint AS orders,0::bigint AS orders_365,0::bigint AS tsd_orders,0::bigint AS annual_orders,0::bigint AS undated_tsd_orders,''::text AS payment_sources,NULL::timestamptz AS ends_at WHERE false), continuous AS (SELECT NULL::integer AS user_id WHERE false), renewals AS (SELECT NULL::integer AS user_id WHERE false), ";
}
if (VARIABLES.funnelRelatedMapped AND VARIABLES.funnelEnrollments) {
    VARIABLES.funnelSQL &= " enrollments AS (SELECT DISTINCT d.id_usuario FROM public.desafios d CROSS JOIN bounds b WHERE lower(d.desafio) IN ('todosantodia','desafio365') AND d.data_inscricao<b.until_at), ";
} else VARIABLES.funnelSQL &= " enrollments AS (SELECT NULL::integer AS id_usuario WHERE false), ";
if (VARIABLES.funnelChallenge AND VARIABLES.funnelSignup) {
    VARIABLES.funnelSQL &= " signup AS (SELECT DISTINCT ON (e.user_id) e.user_id,e.method,e.campaign_id FROM crm_interno.challenge_signup_events e CROSS JOIN bounds b WHERE e.challenge_code='todosantodia' AND e.occurred_at<b.until_at ORDER BY e.user_id,e.occurred_at), ";
} else VARIABLES.funnelSQL &= " signup AS (SELECT NULL::integer AS user_id,''::text AS method,NULL::bigint AS campaign_id WHERE false), ";
VARIABLES.funnelSQL &= " people AS (SELECT u.*,cp.user_id IS NOT NULL AS coupon,coalesce(cp.registrations,0) AS coupon_registrations,coalesce(cp.events,0) AS coupon_events,coalesce(cp.last_event,'') AS coupon_last_event,coalesce(cp.last_modality,'') AS coupon_last_modality,cp.last_at AS coupon_last_at,(coalesce(p.orders_365,0)>0 OR coalesce(p.tsd_orders,0)>0) AS paid,coalesce(p.orders_365,0)>0 AS paid_365,coalesce(p.tsd_orders,0)>0 AS active,coalesce(p.tsd_orders,0)>0 AND coalesce(p.orders_365,0)>0 AS renewed,coalesce(p.annual_orders,0) AS annual_orders,coalesce(p.payment_sources,'') AS payment_sources,p.ends_at,coalesce(p.ends_at>=b.until_at,false) AS term_active,p.ends_at IS NOT NULL AND coalesce(p.undated_tsd_orders,0)=0 AS expiry_known,(e.id_usuario IS NOT NULL OR s.user_id IS NOT NULL OR coalesce(p.orders,0)>0) AS related,coalesce(s.method,'unknown') AS origin,coalesce(s.campaign_id,0) AS campaign_id,c.user_id IS NOT NULL AS continuous,r.user_id IS NOT NULL AS renewed_period,coalesce(p.undated_tsd_orders,0)=0 AND coalesce(p.ends_at>=b.starts_at AND p.ends_at<b.until_at,false) AS expired_period FROM base u CROSS JOIN bounds b LEFT JOIN coupon_people cp ON cp.user_id=u.id LEFT JOIN payments p ON p.user_id=u.id LEFT JOIN enrollments e ON e.id_usuario=u.id LEFT JOIN signup s ON s.user_id=u.id LEFT JOIN continuous c ON c.user_id=u.id LEFT JOIN renewals r ON r.user_id=u.id) ";
VARIABLES.funnelConditions={base="true",related="related",paid="paid",active="active",renewed="renewed",coupon="coupon",expired="active AND expiry_known AND NOT term_active"};
VARIABLES.funnelWhere=" WHERE " & VARIABLES.funnelConditions[VARIABLES.funnelStage];
if ((VARIABLES.funnelStage EQ "related" AND !VARIABLES.funnelRelatedMapped) OR (listFind("paid,active,renewed,expired",VARIABLES.funnelStage) AND !VARIABLES.funnelPaymentsMapped)) VARIABLES.funnelWhere=" WHERE false ";
if (VARIABLES.funnelStage EQ "coupon" AND !VARIABLES.funnelCouponsMapped) VARIABLES.funnelWhere=" WHERE false ";
if (len(VARIABLES.funnelSearch)) {
    // strpos treats % and _ literally, with no wildcard ambiguity.
    VARIABLES.funnelWhere &= " AND (strpos(lower(name),lower(:search))>0 OR CAST(id AS text)=:search) ";
    VARIABLES.funnelParams.search=funnelParam(VARIABLES.funnelSearch);
}
VARIABLES.funnelParams.offset=funnelParam((val(VARIABLES.funnelPage)-1)*25,"cf_sql_integer");
VARIABLES.funnelMetricsSQL="SELECT count(*) AS base,count(*) FILTER(WHERE coupon) AS coupon,coalesce(sum(coupon_registrations),0) AS coupon_registrations,count(*) FILTER(WHERE related) AS related,count(*) FILTER(WHERE paid) AS paid,count(*) FILTER(WHERE active) AS active,count(*) FILTER(WHERE renewed) AS renewed,count(*) FILTER(WHERE term_active) AS term_active,count(*) FILTER(WHERE NOT related) AS registered_only,count(*) FILTER(WHERE related AND NOT term_active) AS related_without_term,count(*) FILTER(WHERE continuous) AS continuous,count(*) FILTER(WHERE renewed_period) AS renewed_period,count(*) FILTER(WHERE expired_period) AS expired_period,count(*) FILTER(WHERE origin='last_recorded_click_7d') AS campaign_origin,count(*) FILTER(WHERE origin='none') AS no_click_origin,count(*) FILTER(WHERE related AND origin='unknown') AS unknown_origin FROM people";
VARIABLES.funnelPageSQL="SELECT id,name,accounts,related,paid,paid_365,active,renewed,term_active,annual_orders,payment_sources,origin,campaign_id,coupon,coupon_registrations,coupon_events,coupon_last_event,coupon_last_modality,coalesce(to_char(coupon_last_at,'DD/MM/YYYY'),'') AS coupon_last_day,coalesce(to_char(ends_at AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY'),'') AS term_end FROM matching ORDER BY name,id LIMIT 25 OFFSET :offset";
// Reuse the same people CTE for metrics, count and page; historical webhook
// events must not be rescanned three times for one screen update.
VARIABLES.funnelResult=funnelQuery(VARIABLES.funnelSQL & ", matching AS (SELECT * FROM people" & VARIABLES.funnelWhere & ") SELECT (SELECT row_to_json(m) FROM (" & VARIABLES.funnelMetricsSQL & ") m) AS metrics_json,(SELECT count(*) FROM matching) AS matched_total,(SELECT row_to_json(cs) FROM coupon_stats cs) AS coupon_stats_json,(SELECT coalesce(json_agg(p ORDER BY p.name,p.id),'[]'::json) FROM (" & VARIABLES.funnelPageSQL & ") p) AS people_json",VARIABLES.funnelParams);
VARIABLES.funnelMetrics=deserializeJSON(VARIABLES.funnelResult.metrics_json[1] & "");
for (var key in VARIABLES.funnelMetrics) VARIABLES.funnelMetrics[key]=val(VARIABLES.funnelMetrics[key]);
if (!VARIABLES.funnelRelatedMapped) for (var key in ["related","registered_only","related_without_term","campaign_origin","no_click_origin","unknown_origin"]) VARIABLES.funnelMetrics[key]=-1;
if (!VARIABLES.funnelPaymentsMapped) for (var key in ["paid","active","renewed","term_active","continuous","renewed_period","expired_period","related_without_term"]) VARIABLES.funnelMetrics[key]=-1;
if (!VARIABLES.funnelCouponsMapped) for (var key in ["coupon","coupon_registrations"]) VARIABLES.funnelMetrics[key]=-1;
VARIABLES.funnelCouponStats=deserializeJSON(VARIABLES.funnelResult.coupon_stats_json[1] & "");
for (var key in VARIABLES.funnelCouponStats) VARIABLES.funnelCouponStats[key]=val(VARIABLES.funnelCouponStats[key]);
VARIABLES.funnelPeopleTotal=val(VARIABLES.funnelResult.matched_total[1]);
VARIABLES.funnelPeople=deserializeJSON(VARIABLES.funnelResult.people_json[1] & "");
VARIABLES.funnelNotes=[
    "Cadastro: data_criacao de tb_usuarios. O primeiro estágio sempre preserva a base de pessoas do público escolhido; o produto filtra as etapas seguintes.",
    "Pagamento: confirmações Pagar.me do CRM, registros order.paid em tb_transacoes e pedidos 365 em tb_webhook ligados ao número de pedido da inscrição. Para o 365, entram desafio365, desafio365vip, inscricao365 e inscricao365vip; para o Todo Santo Dia, todosantodia, todosantodiavip e todosantodiaupg. Inscrição, status do cadastro ou acesso não comprovam pagamento.",
    "Pedidos repetidos por reenvio de webhook são contados uma vez. Quando o mesmo pedido aparece nas duas fontes, o CRM tem prioridade. Registros de cancelamento e reembolso encontrados são excluídos.",
    "Legado: o vínculo de pessoa usa o id_usuario da transação existente, sem procurar usuários por email nesta tela. Essa identificação antiga não tem a mesma garantia do checkout autenticado atual. A vigência usa paid_at da cobrança ou, se ausente, a data do evento order.paid; pagamentos sem data utilizável não recebem uma vigência inventada.",
    "Funil: Já pagaram inclui compra anual do Desafio 365 ou do Todo Santo Dia. Pagantes Todo Santo Dia exige compra básica ou VIP deste produto. Renovados identifica pessoas com compra confirmada dos dois desafios, mesmo se a anuidade atual terminou. A ordem das compras não é presumida quando faltam datas.",
    "Vigência comprovada: 12 meses desde cada compra anual do Todo Santo Dia com data utilizável. Compras sem essa data entram entre os pagantes, mas não recebem vigência inventada. Upgrade não inicia outra vigência nem, sozinho, torna a pessoa pagante Todo Santo Dia.",
    "As consultas usam o estado atual dos registros e pagamentos. Datas passadas são uma reconstrução da base conhecida, não um retrato histórico completo. Reembolsos posteriores podem alterar o resultado.",
    "O histórico financeiro e a identificação de compradores podem ser parciais. Ausência de confirmação não prova que uma pessoa nunca pagou. Produtos ainda não mapeados aparecem com travessão.",
    "Vínculo aos desafios: inscrições do Desafio 365 ou do Todo Santo Dia e eventos de inscrição registrados. data_inscricao pode ser atualizada; inscrições antigas não garantem a data original. Uso ou teste de funcionalidades ainda não tem uma fonte validada neste MVP.",
    "Cupom: inscrições da TicketSports com pedido em estado Pago, código ROADRUNNERS ou título exato revisado quando o código estiver ausente. O vínculo usa somente o e-mail do participante, sem diferenciar maiúsculas/minúsculas e espaços nas extremidades, com uma única conta correspondente em toda a base. E-mails ausentes, inválidos, duplicados ou divergentes entre payload e coluna não geram vínculo. Nome, e-mail do comprador e CPF não são usados para presumir uma correspondência.",
    "A etapa do cupom mostra pessoas únicas da base escolhida, independentemente de compra do desafio ou produto selecionado. Uma pessoa com várias inscrições conta uma vez. Inscrições são acumuladas até a data final pela data_pedido do participante; em Cadastros no período, apenas a base de usuários é limitada à data inicial. Inscrições sem data utilizável ficam fora. O estado Pago é o estado importado da TicketSports, não receita auditada ou confirmação de cashback. A cobertura depende das provas já importadas e não comprova que a pessoa correu a prova.",
    "Origem: atribuição do vínculo ao Desafio por clique de campanha registrado nos 7 dias anteriores. Sem clique registrado não significa orgânico; a origem do cadastro geral ainda não está mapeada."
];
if (VARIABLES.funnelAudience EQ "organizers") arrayPrepend(VARIABLES.funnelNotes,"Organizadores: pessoas com vínculo OWNER ativo em tb_conta_usuarios e conta criada até a data final. Uma pessoa é contada uma vez, mesmo com várias contas. Funcionários são excluídos. As contas também podem incluir parceiros; o papel e o status atuais não reconstituem todos os donos anteriores. Pagamentos por produto de organizadores ainda não estão mapeados.");
if (!VARIABLES.funnelFinance AND !VARIABLES.funnelLegacy AND !VARIABLES.funnelWebhook) arrayPrepend(VARIABLES.funnelNotes,"As fontes de confirmação financeira necessárias não estão disponíveis neste datasource. Cadastros podem ser exibidos; pagamentos e vigências permanecem indisponíveis.");
return {
    metrics=VARIABLES.funnelMetrics,people=VARIABLES.funnelPeople,total=VARIABLES.funnelPeopleTotal,page=val(VARIABLES.funnelPage),page_size=25,
    coverage={coupons_mapped=VARIABLES.funnelCouponsMapped,coupon_stats=VARIABLES.funnelCouponStats,related_mapped=VARIABLES.funnelRelatedMapped,payments_mapped=VARIABLES.funnelPaymentsMapped,signup_mapped=VARIABLES.funnelChallenge AND VARIABLES.funnelSignup,legacy_mapped=VARIABLES.funnelLegacy,webhook_mapped=VARIABLES.funnelWebhook,crm_mapped=VARIABLES.funnelFinance,partial=true,notes=VARIABLES.funnelNotes},
    filters={publico=VARIABLES.funnelAudience,produto=VARIABLES.funnelProduct,leitura=VARIABLES.funnelReading,de=VARIABLES.funnelFrom,ate=VARIABLES.funnelTo},
    generated_at=dateTimeFormat(now(),"dd/mm/yyyy HH:nn","America/Sao_Paulo")
};
}
VARIABLES.funnelReport=funnelBuildReport();
</cfscript>
