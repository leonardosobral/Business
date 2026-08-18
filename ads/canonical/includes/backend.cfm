<cfparam name="URL.success" default=""/>
<cfparam name="URL.campaign" default=""/>
<cfparam name="FORM.ads_v1_action" default=""/>
<cfparam name="FORM.ads_v1_csrf" default=""/>

<cfscript>
function adsV1IsUuid(required any value) {
    return reFindNoCase(
        "^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$",
        trim(arguments.value & "")
    ) EQ 1;
}

function adsV1NewIdempotencyToken() {
    return lCase(replace(createUUID(), "-", "", "all"));
}

function adsV1IsIdempotencyToken(required any value) {
    return reFindNoCase("^[0-9a-f]{32}$", trim(arguments.value & "")) EQ 1;
}

function adsV1MoneyValue(required any value) {
    var normalized = trim(arguments.value & "");
    normalized = reReplace(normalized, "[[:space:]]", "", "all");
    if (find(",", normalized)) {
        normalized = replace(normalized, ".", "", "all");
        normalized = replace(normalized, ",", ".", "all");
    }
    if (!isNumeric(normalized)) return -1;
    return val(normalized);
}
</cfscript>

<cfset VARIABLES.adsV1ApiReady = false/>
<cfset VARIABLES.adsV1DataReady = false/>
<cfset VARIABLES.adsV1HasAccount = false/>
<cfset VARIABLES.adsV1CanMutate = false/>
<cfset VARIABLES.adsV1AccountId = 0/>
<cfset VARIABLES.adsV1ActorId = 0/>
<cfset VARIABLES.adsV1Csrf = ""/>
<cfset VARIABLES.adsV1Error = ""/>
<cfset VARIABLES.adsV1Notice = ""/>
<cfset VARIABLES.adsV1ReadinessError = ""/>
<cfset VARIABLES.adsV1SelectedCampaignId = ""/>
<cfset VARIABLES.adsV1CreditIdempotencyKey = ""/>
<cfset VARIABLES.adsV1ReversalIdempotencyKey = ""/>

<cfset qAdsV1Account = QueryNew("id_conta,nome_conta,status,available_balance,currency")/>
<cfset qAdsV1Events = QueryNew("id_evento,nome_evento,tag,data_inicial,data_final,cidade,estado")/>
<cfset qAdsV1Campaigns = QueryNew("campaign_id,account_id,name,status,currency,cpc_bid,budget_total,budget_daily,target_device_class,target_country_code,target_region_code,starts_at,ends_at,created_at,updated_at,advertisement_id,creative_id,core_event_id,destination_url,nome_evento,event_tag,event_date,event_city,event_state,placement_key,spent_total,spent_today,spent_date,served_count,viewable_impression_count,valid_click_count,billable_click_count,conversion_count,reversal_count,reversal_amount,cost")/>
<cfset qAdsV1SelectedCampaign = QueryNew("campaign_id,account_id,name,status,cpc_bid,budget_total,budget_daily,target_device_class,target_country_code,target_region_code,starts_at,ends_at,core_event_id")/>
<cfset qAdsV1Ledger = QueryNew("ledger_entry_id,account_id,campaign_id,entry_type,source_type,amount,currency,balance_after,idempotency_key,reference_entry_id,occurred_at,created_by,metadata,campaign_name")/>
<cfset qAdsV1ReversibleDebits = QueryNew("ledger_entry_id,campaign_id,amount,currency,balance_after,occurred_at,campaign_name")/>
<cfset qAdsV1StatusHistory = QueryNew("campaign_status_history_id,campaign_id,account_id,from_status,to_status,reason,changed_by,changed_at,campaign_name,changed_by_name")/>
<cfset VARIABLES.adsV1Summary = {
    balance = 0,
    campaigns = 0,
    active = 0,
    paused = 0,
    spent = 0,
    views = 0,
    clicks = 0,
    cost = 0
}/>

<cfif isDefined("qPerfil") AND qPerfil.recordcount AND isDefined("qPerfil.id") AND isNumeric(qPerfil.id)>
    <cfset VARIABLES.adsV1ActorId = val(qPerfil.id)/>
</cfif>

<cfif isDefined("VARIABLES.businessActiveAccountId")
    AND isNumeric(VARIABLES.businessActiveAccountId)
    AND val(VARIABLES.businessActiveAccountId) GT 0>
    <cfset VARIABLES.adsV1AccountId = val(VARIABLES.businessActiveAccountId)/>
    <cfset VARIABLES.adsV1HasAccount = true/>
</cfif>

<cfif NOT structKeyExists(SESSION, "adsV1CanonicalCsrf")
    OR NOT len(trim(SESSION.adsV1CanonicalCsrf & ""))>
    <cfset SESSION.adsV1CanonicalCsrf = lCase(hash(createUUID() & now() & getTickCount(), "SHA-256"))/>
</cfif>
<cfset VARIABLES.adsV1Csrf = SESSION.adsV1CanonicalCsrf/>

<cfswitch expression="#trim(URL.success & '')#">
    <cfcase value="campaign-saved"><cfset VARIABLES.adsV1Notice = "Campanha Ads V1 salva como rascunho."/></cfcase>
    <cfcase value="credited"><cfset VARIABLES.adsV1Notice = "Credito Ads V1 registrado."/></cfcase>
    <cfcase value="activated"><cfset VARIABLES.adsV1Notice = "Campanha Ads V1 ativada."/></cfcase>
    <cfcase value="paused"><cfset VARIABLES.adsV1Notice = "Campanha Ads V1 pausada."/></cfcase>
    <cfcase value="ended"><cfset VARIABLES.adsV1Notice = "Campanha Ads V1 encerrada."/></cfcase>
    <cfcase value="reversed"><cfset VARIABLES.adsV1Notice = "Debito CPC estornado."/></cfcase>
</cfswitch>

<cftry>
    <cfquery name="qAdsV1Readiness" datasource="runnerhub">
        WITH expected_functions(signature) AS (
            VALUES
                ('ads.save_event_campaign(uuid,bigint,integer,text,text,text,numeric,numeric,numeric,timestamp with time zone,timestamp with time zone,text,character,text,integer)'),
                ('ads.activate_campaign(uuid,integer,text)'),
                ('ads.change_campaign_status(uuid,text,integer,text)'),
                ('ads.credit_account(bigint,numeric,text,text,integer,jsonb)'),
                ('ads.reverse_click_debit(uuid,text,integer,text)')
        ),
        resolved_functions AS (
            SELECT signature,
                   to_regprocedure(signature) AS procedure_oid
            FROM expected_functions
        ),
        function_check AS (
            SELECT count(*)::integer AS expected_count,
                   count(procedure_oid)::integer AS resolved_count,
                   bool_and(
                       procedure_oid IS NOT NULL
                       AND has_function_privilege(current_user, procedure_oid, 'EXECUTE')
                   ) AS ready
            FROM resolved_functions
        ),
        expected_tables(relation_name) AS (
            VALUES
                ('ads.placements'),
                ('ads.campaigns'),
                ('ads.advertisements'),
                ('ads.creatives'),
                ('ads.campaign_placements'),
                ('ads.account_balances'),
                ('ads.campaign_budget_state'),
                ('ads.credit_ledger'),
                ('ads.daily_metrics'),
                ('ads.campaign_status_history')
        ),
        resolved_tables AS (
            SELECT relation_name,
                   to_regclass(relation_name) AS relation_oid
            FROM expected_tables
        ),
        table_check AS (
            SELECT count(*)::integer AS expected_table_count,
                   count(relation_oid)::integer AS resolved_table_count,
                   bool_and(
                       relation_oid IS NOT NULL
                       AND has_table_privilege(current_user, relation_oid, 'SELECT')
                   ) AS ready
            FROM resolved_tables
        )
        SELECT function_check.expected_count,
               function_check.resolved_count,
               table_check.expected_table_count,
               table_check.resolved_table_count,
               function_check.ready AND table_check.ready AS ready
        FROM function_check
        CROSS JOIN table_check
    </cfquery>

    <cfif qAdsV1Readiness.recordcount>
        <cfset VARIABLES.adsV1ReadinessFlag = qAdsV1Readiness.ready & ""/>
        <cfset VARIABLES.adsV1ApiReady = val(qAdsV1Readiness.expected_count) EQ 5
            AND val(qAdsV1Readiness.resolved_count) EQ 5
            AND val(qAdsV1Readiness.expected_table_count) EQ 10
            AND val(qAdsV1Readiness.resolved_table_count) EQ 10
            AND listFindNoCase("1,true,t,yes,on", trim(VARIABLES.adsV1ReadinessFlag)) GT 0/>
    </cfif>

    <cfcatch type="any">
        <cfset VARIABLES.adsV1ApiReady = false/>
        <cfset VARIABLES.adsV1ReadinessError = "API SQL Ads V1 indisponivel."/>
        <cflog file="business_ads_v1" type="error" text="readiness account=#VARIABLES.adsV1AccountId# actor=#VARIABLES.adsV1ActorId# message=#cfcatch.message#"/>
    </cfcatch>
</cftry>

<cfset VARIABLES.adsV1CanMutate = isDefined("VARIABLES.businessRealIsAdmin")
    AND VARIABLES.businessRealIsAdmin
    AND VARIABLES.adsV1HasAccount
    AND VARIABLES.adsV1ApiReady
    AND VARIABLES.adsV1ActorId GT 0/>

<cfif VARIABLES.adsV1HasAccount AND VARIABLES.adsV1ApiReady>
    <cftry>
        <cfquery name="qAdsV1Account" datasource="runnerhub">
            SELECT cont.id_conta,
                   cont.nome_conta,
                   cont.status::text AS status,
                   coalesce(balance.available_balance, 0)::numeric(14, 2) AS available_balance,
                   coalesce(balance.currency, 'BRL')::character(3) AS currency
            FROM public.tb_contas cont
            LEFT JOIN ads.account_balances balance
              ON balance.account_id = cont.id_conta
            WHERE cont.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
              AND cont.status::text = 'ATIVA'
            LIMIT 1
        </cfquery>

        <cfif NOT qAdsV1Account.recordcount>
            <cfset VARIABLES.adsV1HasAccount = false/>
            <cfset VARIABLES.adsV1CanMutate = false/>
            <cfset VARIABLES.adsV1Error = "A conta selecionada nao esta ativa."/>
        <cfelse>
            <cfset VARIABLES.adsV1Summary.balance = val(qAdsV1Account.available_balance)/>

            <cfquery name="qAdsV1Events" datasource="runnerhub">
                SELECT evt.id_evento,
                       evt.nome_evento,
                       evt.tag,
                       evt.data_inicial,
                       evt.data_final,
                       evt.cidade,
                       evt.estado
                FROM public.tb_conta_eventos ce
                INNER JOIN public.tb_evento_corridas evt
                  ON evt.id_evento = ce.id_evento
                WHERE ce.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
                  AND ce.status::text = 'ATIVO'
                  AND evt.ativo = true
                ORDER BY evt.data_inicial DESC NULLS LAST,
                         evt.nome_evento
            </cfquery>

            <cfquery name="qAdsV1Campaigns" datasource="runnerhub">
                SELECT c.campaign_id,
                       c.account_id,
                       c.name,
                       c.status,
                       c.currency,
                       c.cpc_bid,
                       c.budget_total,
                       c.budget_daily,
                       c.target_device_class,
                       c.target_country_code,
                       c.target_region_code,
                       c.starts_at,
                       c.ends_at,
                       c.created_at,
                       c.updated_at,
                       advertisement.advertisement_id,
                       creative.creative_id,
                       advertisement.core_event_id,
                       advertisement.destination_url,
                       evt.nome_evento,
                       evt.tag AS event_tag,
                       evt.data_inicial AS event_date,
                       evt.cidade AS event_city,
                       evt.estado AS event_state,
                       placement.placement_key,
                       coalesce(budget.spent_total, 0)::numeric(14, 2) AS spent_total,
                       coalesce(budget.spent_today, 0)::numeric(14, 2) AS spent_today,
                       budget.spent_date,
                       coalesce(metrics.served_count, 0)::bigint AS served_count,
                       coalesce(metrics.viewable_impression_count, 0)::bigint AS viewable_impression_count,
                       coalesce(metrics.valid_click_count, 0)::bigint AS valid_click_count,
                       coalesce(metrics.billable_click_count, 0)::bigint AS billable_click_count,
                       coalesce(metrics.conversion_count, 0)::bigint AS conversion_count,
                       coalesce(metrics.reversal_count, 0)::bigint AS reversal_count,
                       coalesce(metrics.reversal_amount, 0)::numeric(14, 2) AS reversal_amount,
                       coalesce(metrics.cost, 0)::numeric(14, 2) AS cost
                FROM ads.campaigns c
                LEFT JOIN LATERAL (
                    SELECT ad.advertisement_id,
                           ad.core_event_id,
                           ad.destination_url
                    FROM ads.advertisements ad
                    WHERE ad.campaign_id = c.campaign_id
                      AND ad.account_id = c.account_id
                      AND ad.billing_model = c.billing_model
                      AND ad.ad_type = 'EVENT'
                    ORDER BY ad.created_at, ad.advertisement_id
                    LIMIT 1
                ) advertisement ON true
                LEFT JOIN LATERAL (
                    SELECT cr.creative_id
                    FROM ads.creatives cr
                    WHERE cr.advertisement_id = advertisement.advertisement_id
                      AND cr.campaign_id = c.campaign_id
                      AND cr.account_id = c.account_id
                    ORDER BY cr.created_at, cr.creative_id
                    LIMIT 1
                ) creative ON true
                LEFT JOIN public.tb_evento_corridas evt
                  ON evt.id_evento = advertisement.core_event_id
                LEFT JOIN LATERAL (
                    SELECT pl.placement_key
                    FROM ads.campaign_placements link
                    INNER JOIN ads.placements pl
                      ON pl.placement_id = link.placement_id
                    WHERE link.campaign_id = c.campaign_id
                      AND link.account_id = c.account_id
                      AND link.status = 'ACTIVE'
                    ORDER BY link.priority DESC, link.created_at
                    LIMIT 1
                ) placement ON true
                LEFT JOIN ads.campaign_budget_state budget
                  ON budget.campaign_id = c.campaign_id
                 AND budget.account_id = c.account_id
                 AND budget.currency = c.currency
                LEFT JOIN LATERAL (
                    SELECT sum(metric.served_count) AS served_count,
                           sum(metric.viewable_impression_count) AS viewable_impression_count,
                           sum(metric.valid_click_count) AS valid_click_count,
                           sum(metric.billable_click_count) AS billable_click_count,
                           sum(metric.conversion_count) AS conversion_count,
                           sum(metric.reversal_count) AS reversal_count,
                           sum(metric.reversal_amount) AS reversal_amount,
                           sum(metric.cost) AS cost
                    FROM ads.daily_metrics metric
                    WHERE metric.campaign_id = c.campaign_id
                      AND metric.account_id = c.account_id
                ) metrics ON true
                WHERE c.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
                  AND c.billing_model = 'CPC'
                ORDER BY c.updated_at DESC, c.created_at DESC
            </cfquery>

            <cfquery name="qAdsV1Ledger" datasource="runnerhub">
                SELECT ledger.ledger_entry_id,
                       ledger.account_id,
                       ledger.campaign_id,
                       ledger.entry_type,
                       ledger.source_type,
                       ledger.amount,
                       ledger.currency,
                       ledger.balance_after,
                       ledger.idempotency_key,
                       ledger.reference_entry_id,
                       ledger.occurred_at,
                       ledger.created_by,
                       ledger.metadata,
                       campaign.name AS campaign_name
                FROM ads.credit_ledger ledger
                LEFT JOIN ads.campaigns campaign
                  ON campaign.campaign_id = ledger.campaign_id
                 AND campaign.account_id = ledger.account_id
                WHERE ledger.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
                ORDER BY ledger.occurred_at DESC, ledger.ledger_entry_id DESC
                LIMIT 50
            </cfquery>

            <cfquery name="qAdsV1ReversibleDebits" datasource="runnerhub">
                SELECT ledger.ledger_entry_id,
                       ledger.campaign_id,
                       ledger.amount,
                       ledger.currency,
                       ledger.balance_after,
                       ledger.occurred_at,
                       campaign.name AS campaign_name
                FROM ads.credit_ledger ledger
                LEFT JOIN ads.campaigns campaign
                  ON campaign.campaign_id = ledger.campaign_id
                 AND campaign.account_id = ledger.account_id
                WHERE ledger.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
                  AND ledger.entry_type = 'DEBIT'
                  AND ledger.source_type = 'CLICK'
                  AND NOT EXISTS (
                      SELECT 1
                      FROM ads.credit_ledger reversal
                      WHERE reversal.reference_entry_id = ledger.ledger_entry_id
                        AND reversal.account_id = ledger.account_id
                        AND reversal.entry_type = 'REVERSAL'
                  )
                ORDER BY ledger.occurred_at DESC, ledger.ledger_entry_id DESC
                LIMIT 20
            </cfquery>

            <cfquery name="qAdsV1StatusHistory" datasource="runnerhub">
                SELECT history.campaign_status_history_id,
                       history.campaign_id,
                       history.account_id,
                       history.from_status,
                       history.to_status,
                       history.reason,
                       history.changed_by,
                       history.changed_at,
                       campaign.name AS campaign_name,
                       usr.name AS changed_by_name
                FROM ads.campaign_status_history history
                INNER JOIN ads.campaigns campaign
                  ON campaign.campaign_id = history.campaign_id
                 AND campaign.account_id = history.account_id
                LEFT JOIN public.tb_usuarios usr
                  ON usr.id = history.changed_by
                WHERE history.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
                ORDER BY history.changed_at DESC,
                         history.campaign_status_history_id DESC
                LIMIT 50
            </cfquery>

            <cfloop query="qAdsV1Campaigns">
                <cfset VARIABLES.adsV1Summary.campaigns = VARIABLES.adsV1Summary.campaigns + 1/>
                <cfif qAdsV1Campaigns.status EQ "ACTIVE"><cfset VARIABLES.adsV1Summary.active = VARIABLES.adsV1Summary.active + 1/></cfif>
                <cfif qAdsV1Campaigns.status EQ "PAUSED"><cfset VARIABLES.adsV1Summary.paused = VARIABLES.adsV1Summary.paused + 1/></cfif>
                <cfset VARIABLES.adsV1Summary.spent = VARIABLES.adsV1Summary.spent + val(qAdsV1Campaigns.spent_total)/>
                <cfset VARIABLES.adsV1Summary.views = VARIABLES.adsV1Summary.views + val(qAdsV1Campaigns.viewable_impression_count)/>
                <cfset VARIABLES.adsV1Summary.clicks = VARIABLES.adsV1Summary.clicks + val(qAdsV1Campaigns.valid_click_count)/>
                <cfset VARIABLES.adsV1Summary.cost = VARIABLES.adsV1Summary.cost + val(qAdsV1Campaigns.cost)/>
            </cfloop>

            <cfif adsV1IsUuid(URL.campaign)>
                <cfset VARIABLES.adsV1SelectedCampaignId = lCase(trim(URL.campaign))/>
                <cfquery name="qAdsV1SelectedCampaign" datasource="runnerhub">
                    SELECT c.campaign_id,
                           c.account_id,
                           c.name,
                           c.status,
                           c.cpc_bid,
                           c.budget_total,
                           c.budget_daily,
                           c.target_device_class,
                           c.target_country_code,
                           c.target_region_code,
                           c.starts_at,
                           c.ends_at,
                           advertisement.core_event_id
                    FROM ads.campaigns c
                    LEFT JOIN LATERAL (
                        SELECT ad.core_event_id
                        FROM ads.advertisements ad
                        WHERE ad.campaign_id = c.campaign_id
                          AND ad.account_id = c.account_id
                          AND ad.ad_type = 'EVENT'
                        ORDER BY ad.created_at, ad.advertisement_id
                        LIMIT 1
                    ) advertisement ON true
                    WHERE c.campaign_id = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1SelectedCampaignId#"/> AS uuid)
                      AND c.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
                      AND c.billing_model = 'CPC'
                    LIMIT 1
                </cfquery>
            </cfif>
            <cfset VARIABLES.adsV1DataReady = true/>
        </cfif>

        <cfcatch type="any">
            <cfset VARIABLES.adsV1DataReady = false/>
            <cfset VARIABLES.adsV1CanMutate = false/>
            <cfset VARIABLES.adsV1Error = "Nao foi possivel carregar os dados canonicos desta conta."/>
            <cflog file="business_ads_v1" type="error" text="read account=#VARIABLES.adsV1AccountId# actor=#VARIABLES.adsV1ActorId# message=#cfcatch.message#"/>
        </cfcatch>
    </cftry>
</cfif>

<cfif len(trim(FORM.ads_v1_action & ""))>
    <cfset VARIABLES.adsV1Action = lCase(trim(FORM.ads_v1_action & ""))/>

    <cftry>
        <cfif NOT VARIABLES.adsV1CanMutate>
            <cfthrow type="AdsV1.Validation" message="A operacao Ads V1 nao esta disponivel para esta conta."/>
        </cfif>
        <cfif compare(trim(FORM.ads_v1_csrf & ""), VARIABLES.adsV1Csrf) NEQ 0>
            <cfthrow type="AdsV1.Validation" message="A sessao do formulario expirou. Recarregue a pagina."/>
        </cfif>

        <cfswitch expression="#VARIABLES.adsV1Action#">
            <cfcase value="save_campaign">
                <cfset VARIABLES.adsV1FormCampaignId = structKeyExists(FORM, "campaign_id") ? lCase(trim(FORM.campaign_id & "")) : ""/>
                <cfset VARIABLES.adsV1FormEventId = structKeyExists(FORM, "core_event_id") AND isNumeric(FORM.core_event_id) ? val(FORM.core_event_id) : 0/>
                <cfset VARIABLES.adsV1FormName = structKeyExists(FORM, "name") ? trim(FORM.name & "") : ""/>
                <cfset VARIABLES.adsV1FormCpcRaw = structKeyExists(FORM, "cpc_bid") ? trim(FORM.cpc_bid & "") : ""/>
                <cfset VARIABLES.adsV1FormBudgetTotalRaw = structKeyExists(FORM, "budget_total") ? trim(FORM.budget_total & "") : ""/>
                <cfset VARIABLES.adsV1FormBudgetDailyRaw = structKeyExists(FORM, "budget_daily") ? trim(FORM.budget_daily & "") : ""/>
                <cfset VARIABLES.adsV1FormCpc = adsV1MoneyValue(VARIABLES.adsV1FormCpcRaw)/>
                <cfset VARIABLES.adsV1FormBudgetTotal = adsV1MoneyValue(VARIABLES.adsV1FormBudgetTotalRaw)/>
                <cfset VARIABLES.adsV1FormBudgetDaily = len(VARIABLES.adsV1FormBudgetDailyRaw) ? adsV1MoneyValue(VARIABLES.adsV1FormBudgetDailyRaw) : 0/>
                <cfset VARIABLES.adsV1FormStartsRaw = structKeyExists(FORM, "starts_at") ? replace(trim(FORM.starts_at & ""), "T", " ", "all") : ""/>
                <cfset VARIABLES.adsV1FormEndsRaw = structKeyExists(FORM, "ends_at") ? replace(trim(FORM.ends_at & ""), "T", " ", "all") : ""/>
                <cfset VARIABLES.adsV1FormDevice = structKeyExists(FORM, "target_device_class") ? uCase(trim(FORM.target_device_class & "")) : "ALL"/>
                <cfset VARIABLES.adsV1FormCountry = structKeyExists(FORM, "target_country_code") ? uCase(trim(FORM.target_country_code & "")) : "BR"/>
                <cfset VARIABLES.adsV1FormRegion = structKeyExists(FORM, "target_region_code") ? uCase(trim(FORM.target_region_code & "")) : ""/>

                <cfif len(VARIABLES.adsV1FormCampaignId) AND NOT adsV1IsUuid(VARIABLES.adsV1FormCampaignId)>
                    <cfthrow type="AdsV1.Validation" message="Campanha invalida."/>
                </cfif>
                <cfif VARIABLES.adsV1FormEventId LTE 0>
                    <cfthrow type="AdsV1.Validation" message="Selecione um evento da conta."/>
                </cfif>
                <cfif len(VARIABLES.adsV1FormName) LT 3 OR len(VARIABLES.adsV1FormName) GT 160>
                    <cfthrow type="AdsV1.Validation" message="Informe um nome de campanha entre 3 e 160 caracteres."/>
                </cfif>
                <cfif NOT reFind("^[0-9]+([.,][0-9]{1,2})?$", VARIABLES.adsV1FormCpcRaw) OR VARIABLES.adsV1FormCpc LTE 0>
                    <cfthrow type="AdsV1.Validation" message="Informe um CPC positivo com no maximo duas casas decimais."/>
                </cfif>
                <cfif NOT reFind("^[0-9]+([.,][0-9]{1,2})?$", VARIABLES.adsV1FormBudgetTotalRaw) OR VARIABLES.adsV1FormBudgetTotal LTE 0>
                    <cfthrow type="AdsV1.Validation" message="Informe um orcamento total positivo com no maximo duas casas decimais."/>
                </cfif>
                <cfif len(VARIABLES.adsV1FormBudgetDailyRaw)
                    AND (NOT reFind("^[0-9]+([.,][0-9]{1,2})?$", VARIABLES.adsV1FormBudgetDailyRaw)
                        OR VARIABLES.adsV1FormBudgetDaily LTE 0
                        OR VARIABLES.adsV1FormBudgetDaily GT VARIABLES.adsV1FormBudgetTotal)>
                    <cfthrow type="AdsV1.Validation" message="O orcamento diario deve ser positivo e nao superar o total."/>
                </cfif>
                <cfif NOT isDate(VARIABLES.adsV1FormStartsRaw) OR NOT isDate(VARIABLES.adsV1FormEndsRaw)>
                    <cfthrow type="AdsV1.Validation" message="Informe o inicio e o fim da campanha."/>
                </cfif>
                <cfset VARIABLES.adsV1FormStarts = parseDateTime(VARIABLES.adsV1FormStartsRaw)/>
                <cfset VARIABLES.adsV1FormEnds = parseDateTime(VARIABLES.adsV1FormEndsRaw)/>
                <cfif dateCompare(VARIABLES.adsV1FormEnds, VARIABLES.adsV1FormStarts, "s") LTE 0>
                    <cfthrow type="AdsV1.Validation" message="O fim da campanha deve ser posterior ao inicio."/>
                </cfif>
                <cfif NOT listFindNoCase("ALL,DESKTOP,MOBILE", VARIABLES.adsV1FormDevice)>
                    <cfthrow type="AdsV1.Validation" message="Dispositivo alvo invalido."/>
                </cfif>
                <cfif NOT reFind("^[A-Z]{2}$", VARIABLES.adsV1FormCountry)>
                    <cfthrow type="AdsV1.Validation" message="Pais alvo invalido."/>
                </cfif>
                <cfif len(VARIABLES.adsV1FormRegion) AND (len(VARIABLES.adsV1FormRegion) GT 40 OR NOT reFind("^[A-Z0-9._ -]+$", VARIABLES.adsV1FormRegion))>
                    <cfthrow type="AdsV1.Validation" message="Regiao alvo invalida."/>
                </cfif>

                <cfquery name="qAdsV1EventTarget" datasource="runnerhub">
                    SELECT evt.id_evento,
                           evt.tag
                    FROM public.tb_conta_eventos ce
                    INNER JOIN public.tb_evento_corridas evt
                      ON evt.id_evento = ce.id_evento
                    WHERE ce.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
                      AND ce.status::text = 'ATIVO'
                      AND evt.ativo = true
                      AND evt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1FormEventId#"/>
                    LIMIT 1
                </cfquery>
                <cfif NOT qAdsV1EventTarget.recordcount OR NOT reFindNoCase("^[a-z0-9._~-]+$", trim(qAdsV1EventTarget.tag & ""))>
                    <cfthrow type="AdsV1.Validation" message="O evento nao esta ativo ou nao pertence a conta selecionada."/>
                </cfif>

                <cfif len(VARIABLES.adsV1FormCampaignId)>
                    <cfquery name="qAdsV1CampaignSaveTarget" datasource="runnerhub">
                        SELECT c.campaign_id,
                               c.status
                        FROM ads.campaigns c
                        WHERE c.campaign_id = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1FormCampaignId#"/> AS uuid)
                          AND c.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
                          AND c.billing_model = 'CPC'
                          AND c.status IN ('DRAFT', 'PAUSED')
                        LIMIT 1
                    </cfquery>
                    <cfif NOT qAdsV1CampaignSaveTarget.recordcount>
                        <cfthrow type="AdsV1.Validation" message="Somente campanhas DRAFT ou PAUSED desta conta podem ser editadas."/>
                    </cfif>
                </cfif>

                <cfset VARIABLES.adsV1DestinationUrl = reReplace(VARIABLES.roadRunnersBaseUrl, "/+$", "", "all")
                    & "/evento/" & trim(qAdsV1EventTarget.tag) & "/"/>

                <cfquery name="qAdsV1CampaignSave" datasource="runnerhub">
                    SELECT *
                    FROM ads.save_event_campaign(
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1FormCampaignId#" null="#NOT len(VARIABLES.adsV1FormCampaignId)#"/> AS uuid),
                        CAST(<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/> AS bigint),
                        CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#qAdsV1EventTarget.id_evento#"/> AS integer),
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="rr-home-upcoming-native"/> AS text),
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1FormName#"/> AS text),
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1DestinationUrl#"/> AS text),
                        CAST(<cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.adsV1FormCpc#" scale="2"/> AS numeric),
                        CAST(<cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.adsV1FormBudgetTotal#" scale="2"/> AS numeric),
                        CAST(<cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.adsV1FormBudgetDaily#" scale="2" null="#NOT len(VARIABLES.adsV1FormBudgetDailyRaw)#"/> AS numeric),
                        CAST(<cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.adsV1FormStarts#"/> AS timestamp with time zone),
                        CAST(<cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.adsV1FormEnds#"/> AS timestamp with time zone),
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1FormDevice#"/> AS text),
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1FormCountry#"/> AS character(2)),
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1FormRegion#" null="#NOT len(VARIABLES.adsV1FormRegion)#"/> AS text),
                        CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1ActorId#"/> AS integer)
                    )
                </cfquery>

                <cflocation addtoken="false" url="./?success=campaign-saved&campaign=#qAdsV1CampaignSave.campaign_id#"/>
            </cfcase>

            <cfcase value="credit_account">
                <cfset VARIABLES.adsV1CreditAmountRaw = structKeyExists(FORM, "amount") ? trim(FORM.amount & "") : ""/>
                <cfset VARIABLES.adsV1CreditAmount = adsV1MoneyValue(VARIABLES.adsV1CreditAmountRaw)/>
                <cfset VARIABLES.adsV1CreditReason = structKeyExists(FORM, "reason") ? trim(FORM.reason & "") : ""/>
                <cfset VARIABLES.adsV1CreditIdempotencyKey = structKeyExists(FORM, "idempotency_key") ? lCase(trim(FORM.idempotency_key & "")) : ""/>
                <cfset VARIABLES.adsV1CreditPrefix = "business:manual-credit:" & VARIABLES.adsV1AccountId & ":"/>
                <cfset VARIABLES.adsV1CreditKeySuffix = left(VARIABLES.adsV1CreditIdempotencyKey, len(VARIABLES.adsV1CreditPrefix)) EQ VARIABLES.adsV1CreditPrefix
                    ? mid(VARIABLES.adsV1CreditIdempotencyKey, len(VARIABLES.adsV1CreditPrefix) + 1, 32) : ""/>

                <cfif NOT reFind("^[0-9]+([.,][0-9]{1,2})?$", VARIABLES.adsV1CreditAmountRaw) OR VARIABLES.adsV1CreditAmount LTE 0>
                    <cfthrow type="AdsV1.Validation" message="Informe um credito positivo com no maximo duas casas decimais."/>
                </cfif>
                <cfif len(VARIABLES.adsV1CreditReason) LT 5 OR len(VARIABLES.adsV1CreditReason) GT 500>
                    <cfthrow type="AdsV1.Validation" message="Informe uma justificativa entre 5 e 500 caracteres."/>
                </cfif>
                <cfif len(VARIABLES.adsV1CreditIdempotencyKey) NEQ len(VARIABLES.adsV1CreditPrefix) + 32
                    OR left(VARIABLES.adsV1CreditIdempotencyKey, len(VARIABLES.adsV1CreditPrefix)) NEQ VARIABLES.adsV1CreditPrefix
                    OR NOT adsV1IsIdempotencyToken(VARIABLES.adsV1CreditKeySuffix)>
                    <cfthrow type="AdsV1.Validation" message="A chave do formulario de credito e invalida. Recarregue a pagina."/>
                </cfif>

                <cfset VARIABLES.adsV1CreditMetadata = serializeJSON({
                    module = "business_ads_v1",
                    reason = VARIABLES.adsV1CreditReason,
                    request_id = VARIABLES.adsV1CreditIdempotencyKey,
                    operator_id = VARIABLES.adsV1ActorId
                })/>

                <cfquery name="qAdsV1CreditResult" datasource="runnerhub">
                    SELECT *
                    FROM ads.credit_account(
                        CAST(<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/> AS bigint),
                        CAST(<cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.adsV1CreditAmount#" scale="2"/> AS numeric),
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1CreditIdempotencyKey#"/> AS text),
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="MANUAL"/> AS text),
                        CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1ActorId#"/> AS integer),
                        CAST(<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.adsV1CreditMetadata#"/> AS jsonb)
                    )
                </cfquery>

                <cflocation addtoken="false" url="./?success=credited"/>
            </cfcase>

            <cfcase value="activate_campaign">
                <cfset VARIABLES.adsV1StatusCampaignId = structKeyExists(FORM, "campaign_id") ? lCase(trim(FORM.campaign_id & "")) : ""/>
                <cfset VARIABLES.adsV1StatusReason = structKeyExists(FORM, "reason") ? trim(FORM.reason & "") : "Ativacao manual pelo Business"/>
                <cfif NOT adsV1IsUuid(VARIABLES.adsV1StatusCampaignId)>
                    <cfthrow type="AdsV1.Validation" message="Campanha invalida."/>
                </cfif>

                <cfquery name="qAdsV1ActivateTarget" datasource="runnerhub">
                    SELECT c.campaign_id,
                           c.status
                    FROM ads.campaigns c
                    WHERE c.campaign_id = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1StatusCampaignId#"/> AS uuid)
                      AND c.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
                      AND c.billing_model = 'CPC'
                      AND c.status IN ('DRAFT', 'PAUSED')
                    LIMIT 1
                </cfquery>
                <cfif NOT qAdsV1ActivateTarget.recordcount>
                    <cfthrow type="AdsV1.Validation" message="A campanha nao pode ser ativada neste estado."/>
                </cfif>

                <cfquery name="qAdsV1ActivateResult" datasource="runnerhub">
                    SELECT *
                    FROM ads.activate_campaign(
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1StatusCampaignId#"/> AS uuid),
                        CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1ActorId#"/> AS integer),
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#left(VARIABLES.adsV1StatusReason, 500)#"/> AS text)
                    )
                </cfquery>

                <cflocation addtoken="false" url="./?success=activated"/>
            </cfcase>

            <cfcase value="change_campaign_status">
                <cfset VARIABLES.adsV1StatusCampaignId = structKeyExists(FORM, "campaign_id") ? lCase(trim(FORM.campaign_id & "")) : ""/>
                <cfset VARIABLES.adsV1TargetStatus = structKeyExists(FORM, "target_status") ? uCase(trim(FORM.target_status & "")) : ""/>
                <cfset VARIABLES.adsV1StatusReason = structKeyExists(FORM, "reason") ? trim(FORM.reason & "") : ""/>
                <cfif NOT adsV1IsUuid(VARIABLES.adsV1StatusCampaignId) OR NOT listFind("PAUSED,ENDED", VARIABLES.adsV1TargetStatus)>
                    <cfthrow type="AdsV1.Validation" message="Campanha ou status invalido."/>
                </cfif>
                <cfif VARIABLES.adsV1TargetStatus EQ "ENDED" AND len(VARIABLES.adsV1StatusReason) LT 5>
                    <cfthrow type="AdsV1.Validation" message="Informe o motivo do encerramento."/>
                </cfif>

                <cfquery name="qAdsV1StatusTarget" datasource="runnerhub">
                    SELECT c.campaign_id,
                           c.status
                    FROM ads.campaigns c
                    WHERE c.campaign_id = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1StatusCampaignId#"/> AS uuid)
                      AND c.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
                      AND c.billing_model = 'CPC'
                    LIMIT 1
                </cfquery>
                <cfif NOT qAdsV1StatusTarget.recordcount
                    OR (VARIABLES.adsV1TargetStatus EQ "PAUSED" AND qAdsV1StatusTarget.status NEQ "ACTIVE")
                    OR (VARIABLES.adsV1TargetStatus EQ "ENDED" AND NOT listFind("DRAFT,ACTIVE,PAUSED", qAdsV1StatusTarget.status))>
                    <cfthrow type="AdsV1.Validation" message="A transicao de status nao e permitida."/>
                </cfif>

                <cfquery name="qAdsV1StatusResult" datasource="runnerhub">
                    SELECT *
                    FROM ads.change_campaign_status(
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1StatusCampaignId#"/> AS uuid),
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1TargetStatus#"/> AS text),
                        CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1ActorId#"/> AS integer),
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#left(VARIABLES.adsV1StatusReason, 500)#" null="#NOT len(VARIABLES.adsV1StatusReason)#"/> AS text)
                    )
                </cfquery>

                <cfif VARIABLES.adsV1TargetStatus EQ "PAUSED">
                    <cflocation addtoken="false" url="./?success=paused"/>
                <cfelse>
                    <cflocation addtoken="false" url="./?success=ended"/>
                </cfif>
            </cfcase>

            <cfcase value="reverse_click_debit">
                <cfset VARIABLES.adsV1ReversalLedgerId = structKeyExists(FORM, "ledger_entry_id") ? lCase(trim(FORM.ledger_entry_id & "")) : ""/>
                <cfset VARIABLES.adsV1ReversalReason = structKeyExists(FORM, "reason") ? trim(FORM.reason & "") : ""/>
                <cfset VARIABLES.adsV1ReversalIdempotencyKey = structKeyExists(FORM, "idempotency_key") ? lCase(trim(FORM.idempotency_key & "")) : ""/>
                <cfset VARIABLES.adsV1ReversalPrefix = "business:click-reversal:" & VARIABLES.adsV1ReversalLedgerId & ":"/>
                <cfset VARIABLES.adsV1ReversalKeySuffix = left(VARIABLES.adsV1ReversalIdempotencyKey, len(VARIABLES.adsV1ReversalPrefix)) EQ VARIABLES.adsV1ReversalPrefix
                    ? mid(VARIABLES.adsV1ReversalIdempotencyKey, len(VARIABLES.adsV1ReversalPrefix) + 1, 32) : ""/>

                <cfif NOT adsV1IsUuid(VARIABLES.adsV1ReversalLedgerId)>
                    <cfthrow type="AdsV1.Validation" message="Lancamento invalido."/>
                </cfif>
                <cfif len(VARIABLES.adsV1ReversalReason) LT 5 OR len(VARIABLES.adsV1ReversalReason) GT 500>
                    <cfthrow type="AdsV1.Validation" message="Informe um motivo de estorno entre 5 e 500 caracteres."/>
                </cfif>
                <cfif len(VARIABLES.adsV1ReversalIdempotencyKey) NEQ len(VARIABLES.adsV1ReversalPrefix) + 32
                    OR left(VARIABLES.adsV1ReversalIdempotencyKey, len(VARIABLES.adsV1ReversalPrefix)) NEQ VARIABLES.adsV1ReversalPrefix
                    OR NOT adsV1IsIdempotencyToken(VARIABLES.adsV1ReversalKeySuffix)>
                    <cfthrow type="AdsV1.Validation" message="A chave do formulario de estorno e invalida. Recarregue a pagina."/>
                </cfif>

                <cfquery name="qAdsV1ReversalTarget" datasource="runnerhub">
                    SELECT ledger.ledger_entry_id
                    FROM ads.credit_ledger ledger
                    WHERE ledger.ledger_entry_id = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1ReversalLedgerId#"/> AS uuid)
                      AND ledger.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
                      AND ledger.entry_type = 'DEBIT'
                      AND ledger.source_type = 'CLICK'
                      AND NOT EXISTS (
                          SELECT 1
                          FROM ads.credit_ledger reversal
                          WHERE reversal.reference_entry_id = ledger.ledger_entry_id
                            AND reversal.account_id = ledger.account_id
                            AND reversal.entry_type = 'REVERSAL'
                      )
                    LIMIT 1
                </cfquery>
                <cfif NOT qAdsV1ReversalTarget.recordcount>
                    <cfthrow type="AdsV1.Validation" message="O debito nao existe, pertence a outra conta ou ja foi estornado."/>
                </cfif>

                <cfquery name="qAdsV1ReversalResult" datasource="runnerhub">
                    SELECT *
                    FROM ads.reverse_click_debit(
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1ReversalLedgerId#"/> AS uuid),
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1ReversalIdempotencyKey#"/> AS text),
                        CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1ActorId#"/> AS integer),
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1ReversalReason#"/> AS text)
                    )
                </cfquery>

                <cflocation addtoken="false" url="./?success=reversed"/>
            </cfcase>

            <cfdefaultcase>
                <cfthrow type="AdsV1.Validation" message="Acao Ads V1 invalida."/>
            </cfdefaultcase>
        </cfswitch>

        <cfcatch type="any">
            <cflog file="business_ads_v1" type="error" text="action=#VARIABLES.adsV1Action# account=#VARIABLES.adsV1AccountId# actor=#VARIABLES.adsV1ActorId# type=#cfcatch.type# message=#left(cfcatch.message & '', 1000)#"/>
            <cfif cfcatch.type EQ "AdsV1.Validation">
                <cfset VARIABLES.adsV1Error = cfcatch.message/>
            <cfelse>
                <cfset VARIABLES.adsV1Error = "Nao foi possivel concluir a operacao Ads V1. Tente novamente e consulte o log se o erro continuar."/>
            </cfif>
        </cfcatch>
    </cftry>
</cfif>

<cfif NOT len(VARIABLES.adsV1CreditIdempotencyKey)>
    <cfset VARIABLES.adsV1CreditIdempotencyKey = "business:manual-credit:"
        & VARIABLES.adsV1AccountId & ":" & adsV1NewIdempotencyToken()/>
</cfif>
