<!--- Consultas de leitura; autorização no report.cfm. --->
<cfscript>
function generalHas(required struct columns, required string table, required string requiredColumns) {
    if (!structKeyExists(columns,table)) return false;
    for (var name in listToArray(requiredColumns)) if (!listFindNoCase(columns[table],name)) return false;
    return true;
}
VARIABLES.generalToday=dateTimeFormat(now(),"yyyy-mm-dd","America/Sao_Paulo");
VARIABLES.generalMonth=left(VARIABLES.generalToday,7);
if (structKeyExists(URL,"mes")) {
    if (!isSimpleValue(URL.mes)) throw(type="FunnelInput",message="Invalid month");
    VARIABLES.generalMonth=trim(URL.mes & "");
}
if (!reFind("^[0-9]{4}-(0[1-9]|1[0-2])$",VARIABLES.generalMonth) OR val(left(VARIABLES.generalMonth,4)) LT 2000) throw(type="FunnelInput",message="Invalid month");
VARIABLES.generalStart=createDate(val(left(VARIABLES.generalMonth,4)),val(right(VARIABLES.generalMonth,2)),1);
if (dateCompare(VARIABLES.generalStart,createDate(val(left(VARIABLES.generalToday,4)),val(mid(VARIABLES.generalToday,6,2)),1)) GT 0) throw(type="FunnelInput",message="Invalid month");
VARIABLES.generalEnd=dateAdd("m",1,VARIABLES.generalStart);
VARIABLES.generalTomorrow=dateAdd("d",1,createDate(val(left(VARIABLES.generalToday,4)),val(mid(VARIABLES.generalToday,6,2)),val(right(VARIABLES.generalToday,2))));
if (dateCompare(VARIABLES.generalEnd,VARIABLES.generalTomorrow) GT 0) VARIABLES.generalEnd=VARIABLES.generalTomorrow;
VARIABLES.generalThrough=dateFormat(dateAdd("d",-1,VARIABLES.generalEnd),"yyyy-mm-dd");
VARIABLES.generalColumns={}; VARIABLES.generalTypes={};
VARIABLES.generalMetadata=queryExecute("SELECT table_schema,table_name,column_name,data_type FROM information_schema.columns WHERE (table_schema='public' AND table_name IN ('tb_usuarios','desafios','tb_transacoes','tb_contas','tb_conta_usuarios','tb_conta_eventos','tb_leaderboard_config','tb_evento_corridas')) OR (table_schema='crm_interno' AND table_name IN ('conversion_order_state','pagarme_order_audit','challenge_signup_events')) OR (table_schema='gorunners' AND table_name='users') OR (table_schema='ads' AND table_name IN ('payment_intents','credit_ledger'))",{},{datasource="runner_dba",timeout=40});
for (VARIABLES.generalColumn in VARIABLES.generalMetadata) {
    VARIABLES.generalKey=VARIABLES.generalColumn.table_schema & "." & VARIABLES.generalColumn.table_name;
    if (!structKeyExists(VARIABLES.generalColumns,VARIABLES.generalKey)) VARIABLES.generalColumns[VARIABLES.generalKey]="";
    VARIABLES.generalColumns[VARIABLES.generalKey]=listAppend(VARIABLES.generalColumns[VARIABLES.generalKey],VARIABLES.generalColumn.column_name);
    VARIABLES.generalTypes[VARIABLES.generalKey & "." & VARIABLES.generalColumn.column_name]=VARIABLES.generalColumn.data_type;
}
if (!generalHas(VARIABLES.generalColumns,"public.tb_usuarios","id,data_criacao")) throw(type="FunnelSource",message="User source unavailable");
VARIABLES.generalEnroll=generalHas(VARIABLES.generalColumns,"public.desafios","id_usuario,desafio,data_inscricao");
VARIABLES.generalStatus=VARIABLES.generalThrough EQ VARIABLES.generalToday AND generalHas(VARIABLES.generalColumns,"public.desafios","id_usuario,desafio,produto,status");
VARIABLES.generalSignup=generalHas(VARIABLES.generalColumns,"crm_interno.challenge_signup_events","user_id,challenge_code,occurred_at");
VARIABLES.generalFinance=generalHas(VARIABLES.generalColumns,"crm_interno.conversion_order_state","source,account_scope,order_key,user_id,match_basis,product_code,paid_at,status,classification,coverage_kind") AND generalHas(VARIABLES.generalColumns,"crm_interno.pagarme_order_audit","provider_order_id,classification");
VARIABLES.generalLegacy=generalHas(VARIABLES.generalColumns,"public.tb_transacoes","id_usuario,codigo_transacao,origem_transacao,status_atual,valor_transacao,json_transacao");
if (VARIABLES.generalLegacy) VARIABLES.generalLegacy=listFind("json,jsonb",VARIABLES.generalTypes["public.tb_transacoes.json_transacao"]) GT 0;
VARIABLES.generalChallenge=VARIABLES.generalEnroll OR VARIABLES.generalStatus OR VARIABLES.generalSignup OR VARIABLES.generalFinance OR VARIABLES.generalLegacy;
VARIABLES.generalChallengePayments=VARIABLES.generalStatus OR VARIABLES.generalFinance OR VARIABLES.generalLegacy;
VARIABLES.generalTerms=VARIABLES.generalFinance OR VARIABLES.generalLegacy;
VARIABLES.generalGo=generalHas(VARIABLES.generalColumns,"gorunners.users","id,rr_user_id,created_at");
VARIABLES.generalAccounts=generalHas(VARIABLES.generalColumns,"public.tb_contas","id_conta,data_criacao");
VARIABLES.generalOwners=VARIABLES.generalAccounts AND generalHas(VARIABLES.generalColumns,"public.tb_conta_usuarios","id_conta,id_usuario,papel,status,data_criacao");
VARIABLES.generalAds=VARIABLES.generalAccounts AND generalHas(VARIABLES.generalColumns,"ads.payment_intents","payment_intent_id,account_id,status,paid_at,ledger_entry_id") AND generalHas(VARIABLES.generalColumns,"ads.credit_ledger","ledger_entry_id,payment_intent_id,account_id,source_type,entry_type");
VARIABLES.generalLive=VARIABLES.generalAccounts AND generalHas(VARIABLES.generalColumns,"public.tb_leaderboard_config","id_evento,data_inclusao") AND generalHas(VARIABLES.generalColumns,"public.tb_evento_corridas","id_evento") AND generalHas(VARIABLES.generalColumns,"public.tb_conta_eventos","id_evento,id_conta,status,data_criacao");
VARIABLES.generalParams={month_start={value=dateFormat(VARIABLES.generalStart,"yyyy-mm-dd"),cfsqltype="cf_sql_varchar"},end_exclusive={value=dateFormat(VARIABLES.generalEnd,"yyyy-mm-dd"),cfsqltype="cf_sql_varchar"}};
VARIABLES.generalSQL="WITH bounds AS (SELECT CAST(:month_start AS date) AT TIME ZONE 'America/Sao_Paulo' AS month_start,CAST(:end_exclusive AS date) AT TIME ZONE 'America/Sao_Paulo' AS until_at,CAST(:end_exclusive AS date) AS until_local), registered AS (SELECT u.id,u.data_criacao FROM public.tb_usuarios u CROSS JOIN bounds b WHERE u.id>0 AND u.data_criacao<b.until_local), ";
if (VARIABLES.generalFinance) VARIABLES.generalSQL &= "crm_paid AS (SELECT s.user_id,s.order_key,s.product_code,s.paid_at,'crm'::text AS payment_source FROM crm_interno.conversion_order_state s JOIN crm_interno.pagarme_order_audit a ON a.provider_order_id=s.order_key AND a.classification='confirmed' CROSS JOIN bounds b WHERE s.source='pagarme' AND s.account_scope='roadrunners' AND s.coverage_kind IN ('linked_future','provider_historical') AND s.classification='confirmed' AND s.status='confirmed' AND s.match_basis='checkout_authenticated' AND s.user_id IS NOT NULL AND s.paid_at<b.until_at AND s.product_code IN ('todosantodia','todosantodiavip','todosantodiaupg')), ";
else VARIABLES.generalSQL &= "crm_paid AS (SELECT NULL::integer AS user_id,''::text AS order_key,''::text AS product_code,NULL::timestamptz AS paid_at,'crm'::text AS payment_source WHERE false), ";
if (VARIABLES.generalLegacy) {
    VARIABLES.generalParams.is_today={value=VARIABLES.generalThrough EQ VARIABLES.generalToday,cfsqltype="cf_sql_bit"};
    include "legacy_payments.cfm";
    VARIABLES.generalAuditGuard=VARIABLES.generalFinance ? " AND NOT EXISTS (SELECT 1 FROM crm_interno.pagarme_order_audit a WHERE a.provider_order_id=l.order_key AND a.classification<>'confirmed') " : "";
    VARIABLES.generalSQL &= replace(VARIABLES.funnelLegacySQL,"/* FUNNEL_LEGACY_AUDIT_GUARD */",VARIABLES.generalAuditGuard);
} else VARIABLES.generalSQL &= "legacy_paid AS (SELECT NULL::integer AS user_id,''::text AS order_key,''::text AS product_code,NULL::timestamptz AS paid_at,'legacy'::text AS payment_source WHERE false), ";
VARIABLES.generalSQL &= "verified AS (SELECT DISTINCT ON (order_key) user_id,order_key,product_code,paid_at,((paid_at AT TIME ZONE 'America/Sao_Paulo')+interval '1 year') AT TIME ZONE 'America/Sao_Paulo' AS ends_at FROM (SELECT * FROM crm_paid UNION ALL SELECT * FROM legacy_paid) p WHERE product_code IN ('todosantodia','todosantodiavip','todosantodiaupg') ORDER BY order_key,CASE payment_source WHEN 'crm' THEN 0 ELSE 1 END), challenge_links AS (SELECT user_id AS id FROM verified ";
if (VARIABLES.generalEnroll) VARIABLES.generalSQL &= " UNION SELECT d.id_usuario AS id FROM public.desafios d CROSS JOIN bounds b WHERE lower(d.desafio)='todosantodia' AND d.data_inscricao<b.until_at";
if (VARIABLES.generalSignup) VARIABLES.generalSQL &= " UNION SELECT e.user_id AS id FROM crm_interno.challenge_signup_events e CROSS JOIN bounds b WHERE e.challenge_code='todosantodia' AND e.occurred_at<b.until_at";
if (VARIABLES.generalStatus) VARIABLES.generalSQL &= " UNION SELECT d.id_usuario AS id FROM public.desafios d WHERE lower(trim(d.desafio))='todosantodia' AND lower(trim(d.produto)) IN ('todosantodia','todosantodiavip') AND upper(trim(d.status))='C'";
VARIABLES.generalSQL &= "), challenge_paid AS (SELECT user_id AS id FROM verified ";
if (VARIABLES.generalStatus) VARIABLES.generalSQL &= " UNION SELECT d.id_usuario AS id FROM public.desafios d WHERE lower(trim(d.desafio))='todosantodia' AND lower(trim(d.produto)) IN ('todosantodia','todosantodiavip') AND upper(trim(d.status))='C'";
VARIABLES.generalSQL &= "), challenge_month AS (SELECT DISTINCT v.user_id AS id FROM verified v CROSS JOIN bounds b WHERE v.product_code IN ('todosantodia','todosantodiavip') AND v.paid_at IS NOT NULL AND v.paid_at<b.until_at AND v.ends_at>b.month_start), ";
if (VARIABLES.generalGo) VARIABLES.generalSQL &= "go_links AS (SELECT DISTINCT g.rr_user_id AS id FROM gorunners.users g CROSS JOIN bounds b WHERE g.rr_user_id IS NOT NULL AND g.created_at<b.until_at), ";
else VARIABLES.generalSQL &= "go_links AS (SELECT NULL::integer AS id WHERE false), ";
if (VARIABLES.generalAds) VARIABLES.generalSQL &= "ads_accounts AS (SELECT DISTINCT p.account_id AS id FROM ads.payment_intents p JOIN ads.credit_ledger l ON l.ledger_entry_id=p.ledger_entry_id AND l.payment_intent_id=p.payment_intent_id AND l.account_id=p.account_id AND l.source_type='PAYMENT' AND l.entry_type='CREDIT' JOIN public.tb_contas c ON c.id_conta=p.account_id CROSS JOIN bounds b WHERE p.status='PAID' AND p.paid_at IS NOT NULL AND p.paid_at<b.until_at AND c.data_criacao<b.until_at), ";
else VARIABLES.generalSQL &= "ads_accounts AS (SELECT NULL::bigint AS id WHERE false), ";
if (VARIABLES.generalLive) {
    VARIABLES.generalSQL &= "event_links AS (SELECT lc.id_evento,count(DISTINCT ce.id_conta) AS accounts,min(ce.id_conta) AS account_id,coalesce(bool_or(ce.id_conta=27),false) AS voa_linked,coalesce(bool_or(ce.id_conta=38),false) AS global_linked FROM public.tb_leaderboard_config lc JOIN public.tb_evento_corridas evt ON evt.id_evento=lc.id_evento CROSS JOIN bounds b LEFT JOIN public.tb_conta_eventos ce ON ce.id_evento=lc.id_evento AND ce.status::text='ATIVO' AND ce.data_criacao<b.until_at WHERE lc.data_inclusao<b.until_local AND lc.id_evento<>51535 GROUP BY lc.id_evento), resolved_events AS (SELECT e.id_evento,CASE WHEN id_evento IN (40209,40260) THEN 60::bigint WHEN id_evento IN (43381,37310) THEN CASE WHEN voa_linked THEN 27::bigint ELSE NULL::bigint END WHEN id_evento=43657 THEN CASE WHEN global_linked THEN 38::bigint ELSE NULL::bigint END WHEN accounts=1 THEN account_id ELSE NULL::bigint END AS buyer_id FROM event_links e), live_accounts AS (SELECT DISTINCT r.buyer_id AS id FROM resolved_events r JOIN public.tb_contas c ON c.id_conta=r.buyer_id CROSS JOIN bounds b WHERE c.data_criacao<b.until_at), live_unassigned AS (SELECT count(*) AS total FROM resolved_events r CROSS JOIN bounds b LEFT JOIN public.tb_contas c ON c.id_conta=r.buyer_id AND c.data_criacao<b.until_at WHERE c.id_conta IS NULL), ";
} else VARIABLES.generalSQL &= "live_accounts AS (SELECT NULL::bigint AS id WHERE false), live_unassigned AS (SELECT 0::bigint AS total), ";
VARIABLES.generalSQL &= "org_accounts AS (SELECT id FROM ads_accounts UNION SELECT id FROM live_accounts), ";
if (VARIABLES.generalOwners) VARIABLES.generalSQL &= "org_people AS (SELECT DISTINCT cu.id_usuario AS id FROM org_accounts a JOIN public.tb_conta_usuarios cu ON cu.id_conta=a.id AND cu.papel::text='OWNER' AND cu.status::text='ATIVO' CROSS JOIN bounds b WHERE cu.data_criacao<b.until_at), ";
else VARIABLES.generalSQL &= "org_people AS (SELECT NULL::integer AS id WHERE false), ";
VARIABLES.generalSQL &= "all_links AS (SELECT id FROM challenge_links UNION SELECT id FROM go_links UNION SELECT id FROM org_people), all_clients AS (SELECT id FROM challenge_paid UNION SELECT id FROM org_people) SELECT (SELECT count(*) FROM registered) AS total,(SELECT count(*) FROM registered u CROSS JOIN bounds b WHERE u.data_criacao >= (b.month_start AT TIME ZONE 'America/Sao_Paulo')) AS new_users,(SELECT count(*) FROM registered u JOIN all_links l ON l.id=u.id) AS linked_people,(SELECT count(*) FROM registered u JOIN all_clients l ON l.id=u.id) AS paid_people,(SELECT count(*) FROM registered u JOIN (SELECT DISTINCT id FROM challenge_links) l ON l.id=u.id) AS challenge_people,(SELECT count(*) FROM registered u JOIN (SELECT DISTINCT id FROM challenge_paid) l ON l.id=u.id) AS challenge_paid,(SELECT count(*) FROM registered u JOIN challenge_month l ON l.id=u.id) AS challenge_month,(SELECT count(*) FROM registered u JOIN go_links l ON l.id=u.id) AS go_people,(SELECT count(*) FROM registered u JOIN org_people l ON l.id=u.id) AS org_people,(SELECT count(*) FROM ads_accounts) AS ads_accounts,(SELECT count(*) FROM live_accounts) AS live_accounts,(SELECT count(*) FROM org_accounts) AS org_accounts,(SELECT total FROM live_unassigned) AS unassigned_events";
VARIABLES.generalCounts=queryExecute(VARIABLES.generalSQL,VARIABLES.generalParams,{datasource="runner_dba",timeout=40});
VARIABLES.funnelReport={month=VARIABLES.generalMonth,through=VARIABLES.generalThrough,total=val(VARIABLES.generalCounts.total[1]),new_users=val(VARIABLES.generalCounts.new_users[1]),linked_people=val(VARIABLES.generalCounts.linked_people[1]),paid_people=val(VARIABLES.generalCounts.paid_people[1]),challenge_people=val(VARIABLES.generalCounts.challenge_people[1]),challenge_paid=val(VARIABLES.generalCounts.challenge_paid[1]),challenge_month=val(VARIABLES.generalCounts.challenge_month[1]),go_people=val(VARIABLES.generalCounts.go_people[1]),org_people=val(VARIABLES.generalCounts.org_people[1]),ads_accounts=val(VARIABLES.generalCounts.ads_accounts[1]),live_accounts=val(VARIABLES.generalCounts.live_accounts[1]),org_accounts=val(VARIABLES.generalCounts.org_accounts[1]),unassigned_events=val(VARIABLES.generalCounts.unassigned_events[1]),coverage={challenge=VARIABLES.generalChallenge,challenge_payments=VARIABLES.generalChallengePayments,terms=VARIABLES.generalTerms,gorunners=VARIABLES.generalGo,ads=VARIABLES.generalAds,transmission=VARIABLES.generalLive,owners=VARIABLES.generalOwners},generated_at=dateTimeFormat(now(),"dd/mm/yyyy HH:nn","America/Sao_Paulo")};
</cfscript>
