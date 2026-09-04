<cfparam name="URL.success" default=""/>
<cfparam name="URL.campaign" default=""/>
<cfparam name="URL.ads_campaign" default=""/>
<cfparam name="URL.ads_period" default="30"/>
<cfparam name="URL.view" default="overview"/>
<cfparam name="FORM.ads_v1_action" default=""/>
<cfparam name="FORM.ads_v1_csrf" default=""/>
<cfparam name="FORM.voucher_code" default=""/>
<cfparam name="FORM.voucher_scope" default="PROMOTIONAL"/>
<cfparam name="FORM.voucher_account_id" default=""/>
<cfparam name="FORM.voucher_amount" default="100.00"/>
<cfparam name="FORM.voucher_expires_on" default=""/>
<cfparam name="FORM.voucher_redemption_role" default="OWNER"/>
<cfparam name="FORM.voucher_note" default=""/>

<cfinclude template="access.cfm"/>

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

function adsV1FormList(required any value) {
    if (isArray(arguments.value)) {
        return duplicate(arguments.value);
    }
    return len(trim(arguments.value & ""))
        ? listToArray(arguments.value & "")
        : [];
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
<cfset VARIABLES.adsV1PerformanceCampaignId = ""/>
<cfset VARIABLES.adsV1PerformanceCampaignName = ""/>
<cfset VARIABLES.adsV1CreditIdempotencyKey = ""/>
<cfset VARIABLES.adsV1ReversalIdempotencyKey = ""/>
<cfset VARIABLES.adsV1CampaignActions = "save_campaign,prepare_campaign_edit,submit_campaign_review,change_campaign_status"/>
<cfset VARIABLES.adsV1FinanceActions = "credit_account,reverse_click_debit"/>
<cfset VARIABLES.adsV1VoucherActions = "redeem_voucher,reserve_voucher"/>
<cfset VARIABLES.adsV1VoucherAdminActions = "create_admin_voucher"/>
<cfset VARIABLES.adsV1ReviewActions = "approve_campaign_review,request_campaign_changes,cancel_campaign_review"/>
<cfset VARIABLES.adsV1ReviewApiReady = false/>
<cfset VARIABLES.adsV1CanReviewMutate = false/>
<cfset VARIABLES.adsV1AdminVoucherApiReady = false/>
<cfset VARIABLES.adsV1CanAdminVoucherMutate = false/>
<cfset VARIABLES.adsV1PerformanceDays = listFind("7,30", trim(URL.ads_period & ""))
    ? val(URL.ads_period)
    : 30/>
<cfset VARIABLES.adsV1AllowedEventPlacementKeys = [
    "rr-home-upcoming-native",
    "rr-home-upcoming-native-secondary",
    "rr-search-events-native",
    "rr-state-events-native",
    "rr-sidebar-event-native"
]/>
<cfset VARIABLES.adsV1SelectableEventPlacementKeys = [
    "rr-home-upcoming-native",
    "rr-search-events-native",
    "rr-state-events-native",
    "rr-sidebar-event-native"
]/>

<cfset qAdsV1Account = QueryNew("id_conta,nome_conta,status,available_balance,currency")/>
<cfset qAdsV1Events = QueryNew("id_evento,nome_evento,tag,data_inicial,data_final,cidade,estado,url_imagem,url_imagem_listagem,imagem,event_link_status")/>
<cfset qAdsV1Placements = QueryNew("placement_key,surface")/>
<cfset qAdsV1Campaigns = QueryNew("campaign_id,account_id,name,status,currency,cpc_bid,budget_total,budget_daily,target_device_class,target_country_code,target_region_code,starts_at,ends_at,created_at,updated_at,advertisement_id,creative_id,core_event_id,destination_url,nome_evento,event_tag,event_date,event_city,event_state,placement_keys,spent_total,spent_today,spent_date,served_count,viewable_impression_count,valid_click_count,billable_click_count,conversion_count,reversal_count,reversal_amount,cost,campaign_review_request_id,review_status,review_reason,submitted_at,reviewed_at,event_link_status,account_status")/>
<cfset qAdsV1SelectedCampaign = QueryNew("campaign_id,account_id,name,status,currency,cpc_bid,budget_total,budget_daily,target_device_class,target_country_code,target_region_code,starts_at,ends_at,created_at,updated_at,core_event_id,destination_url,event_name,event_tag,event_date,event_city,event_state,placement_keys,spent_total,campaign_review_request_id,review_status,review_reason,submitted_at,reviewed_at")/>
<cfset qAdsV1Ledger = QueryNew("ledger_entry_id,account_id,campaign_id,entry_type,source_type,amount,currency,balance_after,idempotency_key,reference_entry_id,occurred_at,created_by,metadata,campaign_name")/>
<cfset qAdsV1ReversibleDebits = QueryNew("ledger_entry_id,campaign_id,amount,currency,balance_after,occurred_at,campaign_name")/>
<cfset qAdsV1StatusHistory = QueryNew("campaign_status_history_id,campaign_id,account_id,from_status,to_status,reason,changed_by,changed_at,campaign_name,changed_by_name")/>
<cfset qAdsV1VoucherReservation = QueryNew("voucher_reservation_id,id_ad_voucher,id_conta,id_solicitacao_cadastro,status,expires_at,transition_reason,codigo,credito")/>
<cfset qAdsV1CampaignReviewQueue = QueryNew("campaign_review_request_id,campaign_id,account_id,core_event_id,review_status,review_reason,submitted_at,updated_at,campaign_name,campaign_status,cpc_bid,budget_total,budget_daily,starts_at,ends_at,target_device_class,target_country_code,target_region_code,account_name,account_status,event_name,event_tag,event_city,event_state,event_link_status,available_balance,placement_keys")/>
<cfset qAdsV1AdminOperationalCampaigns = QueryNew("campaign_id,account_id,campaign_name,campaign_status,cpc_bid,budget_total,budget_daily,starts_at,ends_at,target_device_class,target_country_code,target_region_code,account_name,event_name,event_tag,event_city,event_state,spent_total,served_count,viewable_impression_count,valid_click_count,billable_click_count,cost,placement_keys,reviewed_at")/>
<cfset qAdsV1AccountPerformanceDaily = QueryNew("metric_date,impressions,clicks,billable_clicks,conversions,cost")/>
<cfset qAdsV1AccountPerformanceComparison = QueryNew("current_impressions,previous_impressions,current_clicks,previous_clicks,current_cost,previous_cost")/>
<cfset qAdsV1CampaignPerformanceDaily = QueryNew("metric_date,impressions,clicks,billable_clicks,conversions,cost")/>
<cfset qAdsV1CampaignPerformanceComparison = QueryNew("current_impressions,previous_impressions,current_clicks,previous_clicks,current_cost,previous_cost")/>
<cfset qAdsV1CampaignStatusHistory = QueryNew("campaign_status_history_id,campaign_id,account_id,from_status,to_status,reason,changed_by,changed_at,campaign_name,changed_by_name")/>
<cfset qAdsV1AdminPerformanceDaily = QueryNew("metric_date,impressions,clicks,billable_clicks,conversions,cost")/>
<cfset qAdsV1AdminPerformanceComparison = QueryNew("current_impressions,previous_impressions,current_clicks,previous_clicks,current_cost,previous_cost")/>
<cfset qAdsV1AdminVoucherAccounts = QueryNew("id_conta,nome_conta,status")/>
<cfset qAdsV1AdminVouchers = QueryNew("id_ad_voucher,codigo,voucher_scope,id_conta,account_name,credito,credito_disponivel,status,data_criacao,data_expiracao,id_usuario_resgate,redeemed_by_name,redeemed_by_email,data_resgate,observacao,reservation_status,reserved_account_name")/>
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

<cfset VARIABLES.adsV1ActorId = VARIABLES.adsAccessActorId/>
<cfset VARIABLES.adsV1AccountId = VARIABLES.adsAccessAccountId/>
<cfset VARIABLES.adsV1HasAccount = VARIABLES.adsAccessHasAccount/>

<cfif NOT structKeyExists(SESSION, "adsV1CanonicalCsrf")
    OR NOT len(trim(SESSION.adsV1CanonicalCsrf & ""))>
    <cfset SESSION.adsV1CanonicalCsrf = lCase(hash(createUUID() & now() & getTickCount(), "SHA-256"))/>
</cfif>
<cfset VARIABLES.adsV1Csrf = SESSION.adsV1CanonicalCsrf/>

<cfset VARIABLES.adsV1PendingAuthorized = false/>
<cfset qAdsV1PendingAuthorization = QueryNew("id_solicitacao,id_conta,id_usuario")/>
<cfif VARIABLES.adsAccessIsPendingNewAccount>
    <cfquery name="qAdsV1PendingAuthorization" datasource="runnerhub">
        SELECT registration.id_solicitacao,
               registration.id_conta,
               registration.id_usuario
        FROM public.tb_conta_cadastro_solicitacoes registration
        INNER JOIN public.tb_contas account
          ON account.id_conta = registration.id_conta
         AND account.status = 'PENDENTE'::status_conta
        INNER JOIN public.tb_conta_usuarios membership
          ON membership.id_conta = registration.id_conta
         AND membership.id_usuario = registration.id_usuario
         AND membership.papel = 'OWNER'::papel_usuario_conta
         AND membership.status = 'ATIVO'::status_usuario_conta
        WHERE registration.id_solicitacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsAccessRegistrationId#"/>
          AND registration.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
          AND registration.id_usuario = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1ActorId#"/>
          AND registration.status = 'PENDENTE'::status_conta_cadastro_solicitacao
        LIMIT 1
    </cfquery>
    <cfset VARIABLES.adsV1PendingAuthorized = qAdsV1PendingAuthorization.recordcount EQ 1/>

    <cfif NOT VARIABLES.adsV1PendingAuthorized>
        <cfset VARIABLES.adsAccessCanView = false/>
        <cfset VARIABLES.adsAccessCanManageCampaign = false/>
        <cfset VARIABLES.adsAccessCanViewPayments = false/>
        <cfset VARIABLES.adsAccessCanReserveVoucher = false/>
        <cfset VARIABLES.adsAccessCanPrepareCampaign = false/>
        <cfif len(trim(FORM.ads_v1_action & ""))>
            <cfheader statuscode="403" statustext="Forbidden"/>
            <cfthrow type="Ads.PendingAccess.Forbidden" message="O workspace provisório não pertence ao usuário autenticado."/>
        </cfif>
    </cfif>
</cfif>

<cfswitch expression="#trim(URL.success & '')#">
    <cfcase value="campaign-saved"><cfset VARIABLES.adsV1Notice = "Campanha salva como rascunho."/></cfcase>
    <cfcase value="campaign-edit-ready"><cfset VARIABLES.adsV1Notice = "Campanha pausada. Faça as alterações e salve o novo rascunho para enviá-lo novamente à análise."/></cfcase>
    <cfcase value="campaign-submitted"><cfset VARIABLES.adsV1Notice = "Campanha enviada. Ela ficará fora do ar até concluir as aprovações e a análise da RunnerHub."/></cfcase>
    <cfcase value="campaign-approved"><cfset VARIABLES.adsV1Notice = "Campanha aprovada e liberada para veiculação."/></cfcase>
    <cfcase value="campaign-changes-requested"><cfset VARIABLES.adsV1Notice = "Ajustes solicitados ao anunciante."/></cfcase>
    <cfcase value="campaign-review-canceled"><cfset VARIABLES.adsV1Notice = "Análise da campanha cancelada."/></cfcase>
    <cfcase value="credited"><cfset VARIABLES.adsV1Notice = "Credito de publicidade registrado."/></cfcase>
    <cfcase value="voucher-redeemed"><cfset VARIABLES.adsV1Notice = "Voucher resgatado e saldo de publicidade atualizado."/></cfcase>
    <cfcase value="voucher-reserved"><cfset VARIABLES.adsV1Notice = "Voucher reservado. O crédito será aplicado após a aprovação da conta."/></cfcase>
    <cfcase value="voucher-created"><cfset VARIABLES.adsV1Notice = "Voucher criado com sucesso."/></cfcase>
    <cfcase value="activated"><cfset VARIABLES.adsV1Notice = "Campanha ativada."/></cfcase>
    <cfcase value="paused"><cfset VARIABLES.adsV1Notice = "Campanha pausada."/></cfcase>
    <cfcase value="ended"><cfset VARIABLES.adsV1Notice = "Campanha encerrada."/></cfcase>
    <cfcase value="reversed"><cfset VARIABLES.adsV1Notice = "Debito CPC estornado."/></cfcase>
</cfswitch>

<cftry>
    <cfquery name="qAdsV1Readiness" datasource="runnerhub">
        WITH expected_functions(signature) AS (
            VALUES
                ('ads.save_event_campaign(uuid,bigint,integer,text,text,text,numeric,numeric,numeric,timestamp with time zone,timestamp with time zone,text,character,text,integer)'),
                ('ads.prepare_campaign_for_edit(uuid,bigint,integer)'),
                ('ads.activate_campaign(uuid,integer,text)'),
                ('ads.change_campaign_status(uuid,text,integer,text)'),
                ('ads.change_voucher_status(integer,bigint,integer,integer)'),
                ('ads.credit_account(bigint,numeric,text,text,integer,jsonb)'),
                ('ads.create_voucher(bigint,text,numeric,date,text,text,integer)'),
                ('ads.redeem_voucher(bigint,text,integer)'),
                ('ads.reverse_click_debit(uuid,text,integer,text)'),
                ('ads.replace_campaign_placements(uuid,text[],integer,text)')
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
        <cfset VARIABLES.adsV1ApiReady = val(qAdsV1Readiness.expected_count) EQ 10
            AND val(qAdsV1Readiness.resolved_count) EQ 10
            AND val(qAdsV1Readiness.expected_table_count) EQ 10
            AND val(qAdsV1Readiness.resolved_table_count) EQ 10
            AND listFindNoCase("1,true,t,yes,on", trim(VARIABLES.adsV1ReadinessFlag)) GT 0/>
    </cfif>

    <cfcatch type="any">
        <cfset VARIABLES.adsV1ApiReady = false/>
        <cfset VARIABLES.adsV1ReadinessError = "API SQL de publicidade indisponivel."/>
        <cflog file="business_ads_v1" type="error" text="readiness account=#VARIABLES.adsV1AccountId# actor=#VARIABLES.adsV1ActorId# message=#cfcatch.message#"/>
    </cfcatch>
</cftry>

<cfset VARIABLES.adsV1PendingApiReady = NOT VARIABLES.adsAccessIsPendingNewAccount/>
<cfif VARIABLES.adsAccessIsPendingNewAccount AND VARIABLES.adsV1ApiReady>
    <cftry>
        <cfquery name="qAdsV1PendingReadiness" datasource="runnerhub">
            WITH expected_functions(signature) AS (
                VALUES
                    ('ads.reserve_voucher(bigint,bigint,text,integer)'),
                    ('ads.save_pending_event_campaign(uuid,bigint,bigint,integer,text,text,text,numeric,numeric,numeric,timestamp with time zone,timestamp with time zone,text,character,text,integer)'),
                    ('ads.submit_campaign_review(uuid,bigint,integer,integer)')
            ),
            function_check AS (
                SELECT count(*)::integer AS expected_count,
                       count(to_regprocedure(signature))::integer AS resolved_count,
                       bool_and(
                           to_regprocedure(signature) IS NOT NULL
                           AND has_function_privilege(current_user, to_regprocedure(signature), 'EXECUTE')
                       ) AS ready
                FROM expected_functions
            ),
            expected_tables(relation_name) AS (
                VALUES
                    ('ads.voucher_reservations'),
                    ('ads.campaign_review_requests'),
                    ('ads.campaign_review_history')
            ),
            table_check AS (
                SELECT count(*)::integer AS expected_count,
                       count(to_regclass(relation_name))::integer AS resolved_count,
                       bool_and(
                           to_regclass(relation_name) IS NOT NULL
                           AND has_table_privilege(current_user, to_regclass(relation_name), 'SELECT')
                       ) AS ready
                FROM expected_tables
            )
            SELECT function_check.expected_count AS expected_functions,
                   function_check.resolved_count AS resolved_functions,
                   table_check.expected_count AS expected_tables,
                   table_check.resolved_count AS resolved_tables,
                   function_check.ready AND table_check.ready AS ready
            FROM function_check
            CROSS JOIN table_check
        </cfquery>
        <cfset VARIABLES.adsV1PendingApiReady = qAdsV1PendingReadiness.recordcount
            AND val(qAdsV1PendingReadiness.expected_functions) EQ 3
            AND val(qAdsV1PendingReadiness.resolved_functions) EQ 3
            AND val(qAdsV1PendingReadiness.expected_tables) EQ 3
            AND val(qAdsV1PendingReadiness.resolved_tables) EQ 3
            AND listFindNoCase("1,true,t,yes,on", trim(qAdsV1PendingReadiness.ready & "")) GT 0/>
        <cfcatch type="any">
            <cfset VARIABLES.adsV1PendingApiReady = false/>
        </cfcatch>
    </cftry>
    <cfset VARIABLES.adsV1ApiReady = VARIABLES.adsV1ApiReady AND VARIABLES.adsV1PendingApiReady/>
</cfif>

<cfif VARIABLES.adsAccessCanReviewCampaign AND VARIABLES.adsV1ApiReady>
    <cftry>
        <cfquery name="qAdsV1ReviewReadiness" datasource="runnerhub">
            SELECT to_regprocedure('ads.review_campaign(uuid,text,integer,text,text)') IS NOT NULL
                       AND has_function_privilege(
                           current_user,
                           to_regprocedure('ads.review_campaign(uuid,text,integer,text,text)'),
                           'EXECUTE'
                       )
                       AND to_regclass('ads.campaign_review_requests') IS NOT NULL
                       AND has_table_privilege(
                           current_user,
                           to_regclass('ads.campaign_review_requests'),
                           'SELECT'
                       ) AS ready
        </cfquery>
        <cfset VARIABLES.adsV1ReviewApiReady = qAdsV1ReviewReadiness.recordcount
            AND listFindNoCase("1,true,t,yes,on", trim(qAdsV1ReviewReadiness.ready & "")) GT 0/>

        <cfif VARIABLES.adsV1ReviewApiReady>
            <cfquery name="qAdsV1CampaignReviewQueue" datasource="runnerhub">
                SELECT review.campaign_review_request_id,
                       review.campaign_id,
                       review.account_id,
                       review.core_event_id,
                       review.status AS review_status,
                       review.review_reason,
                       review.submitted_at,
                       review.updated_at,
                       campaign.name AS campaign_name,
                       campaign.status AS campaign_status,
                       campaign.cpc_bid,
                       campaign.budget_total,
                       campaign.budget_daily,
                       campaign.starts_at,
                       campaign.ends_at,
                       campaign.target_device_class,
                       campaign.target_country_code,
                       campaign.target_region_code,
                       account.nome_conta AS account_name,
                       account.status::text AS account_status,
                       event.nome_evento AS event_name,
                       event.tag AS event_tag,
                       event.cidade AS event_city,
                       event.estado AS event_state,
                       event_link.status::text AS event_link_status,
                       coalesce(balance.available_balance, 0)::numeric(14, 2) AS available_balance,
                       placement.placement_keys
                FROM ads.campaign_review_requests review
                INNER JOIN ads.campaigns campaign
                  ON campaign.campaign_id = review.campaign_id
                 AND campaign.account_id = review.account_id
                INNER JOIN public.tb_contas account
                  ON account.id_conta = review.account_id
                INNER JOIN public.tb_evento_corridas event
                  ON event.id_evento = review.core_event_id
                LEFT JOIN public.tb_conta_eventos event_link
                  ON event_link.id_conta = review.account_id
                 AND event_link.id_evento = review.core_event_id
                LEFT JOIN ads.account_balances balance
                  ON balance.account_id = review.account_id
                 AND balance.currency = campaign.currency
                LEFT JOIN LATERAL (
                    SELECT string_agg(
                               DISTINCT selected.placement_key,
                               ',' ORDER BY selected.placement_key
                           ) AS placement_keys
                    FROM ads.campaign_placements link
                    INNER JOIN ads.placements selected
                      ON selected.placement_id = link.placement_id
                    WHERE link.campaign_id = campaign.campaign_id
                      AND link.account_id = campaign.account_id
                      AND link.status = 'ACTIVE'
                ) placement ON true
                WHERE review.status IN ('WAITING_PREREQUISITES', 'PENDING_REVIEW')
                ORDER BY CASE review.status
                             WHEN 'PENDING_REVIEW' THEN 0
                             ELSE 1
                         END,
                         review.submitted_at,
                         review.campaign_review_request_id
                LIMIT 100
            </cfquery>

            <cfquery name="qAdsV1AdminOperationalCampaigns" datasource="runnerhub">
                SELECT campaign.campaign_id,
                       campaign.account_id,
                       campaign.name AS campaign_name,
                       campaign.status AS campaign_status,
                       campaign.cpc_bid,
                       campaign.budget_total,
                       campaign.budget_daily,
                       campaign.starts_at,
                       campaign.ends_at,
                       campaign.target_device_class,
                       campaign.target_country_code,
                       campaign.target_region_code,
                       account.nome_conta AS account_name,
                       event.nome_evento AS event_name,
                       event.tag AS event_tag,
                       event.cidade AS event_city,
                       event.estado AS event_state,
                       coalesce(budget.spent_total, 0)::numeric(14, 2) AS spent_total,
                       coalesce(metrics.served_count, 0)::bigint AS served_count,
                       coalesce(metrics.viewable_impression_count, 0)::bigint AS viewable_impression_count,
                       coalesce(metrics.valid_click_count, 0)::bigint AS valid_click_count,
                       coalesce(metrics.billable_click_count, 0)::bigint AS billable_click_count,
                       coalesce(metrics.cost, 0)::numeric(14, 2) AS cost,
                       placement.placement_keys,
                       review.reviewed_at
                FROM ads.campaigns campaign
                INNER JOIN public.tb_contas account
                  ON account.id_conta = campaign.account_id
                INNER JOIN LATERAL (
                    SELECT request.status,
                           request.reviewed_at
                    FROM ads.campaign_review_requests request
                    WHERE request.campaign_id = campaign.campaign_id
                      AND request.account_id = campaign.account_id
                    ORDER BY request.campaign_review_request_id DESC
                    LIMIT 1
                ) review ON true
                LEFT JOIN LATERAL (
                    SELECT advertisement.core_event_id
                    FROM ads.advertisements advertisement
                    WHERE advertisement.campaign_id = campaign.campaign_id
                      AND advertisement.account_id = campaign.account_id
                      AND advertisement.billing_model = campaign.billing_model
                      AND advertisement.ad_type = 'EVENT'
                      AND advertisement.status <> 'ARCHIVED'
                    ORDER BY advertisement.created_at, advertisement.advertisement_id
                    LIMIT 1
                ) advertisement ON true
                LEFT JOIN public.tb_evento_corridas event
                  ON event.id_evento = advertisement.core_event_id
                LEFT JOIN ads.campaign_budget_state budget
                  ON budget.campaign_id = campaign.campaign_id
                 AND budget.account_id = campaign.account_id
                 AND budget.currency = campaign.currency
                LEFT JOIN LATERAL (
                    SELECT sum(metric.served_count) AS served_count,
                           sum(metric.viewable_impression_count) AS viewable_impression_count,
                           sum(metric.valid_click_count) AS valid_click_count,
                           sum(metric.billable_click_count) AS billable_click_count,
                           sum(metric.cost) AS cost
                    FROM ads.daily_metrics metric
                    WHERE metric.campaign_id = campaign.campaign_id
                      AND metric.account_id = campaign.account_id
                ) metrics ON true
                LEFT JOIN LATERAL (
                    SELECT string_agg(
                               DISTINCT selected.placement_key,
                               ',' ORDER BY selected.placement_key
                           ) AS placement_keys
                    FROM ads.campaign_placements link
                    INNER JOIN ads.placements selected
                      ON selected.placement_id = link.placement_id
                    WHERE link.campaign_id = campaign.campaign_id
                      AND link.account_id = campaign.account_id
                      AND link.status = 'ACTIVE'
                ) placement ON true
                WHERE campaign.billing_model = 'CPC'
                  AND review.status = 'APPROVED'
                  AND campaign.status IN ('ACTIVE', 'PAUSED')
                ORDER BY CASE campaign.status WHEN 'ACTIVE' THEN 0 ELSE 1 END,
                         campaign.updated_at DESC,
                         campaign.created_at DESC
                LIMIT 200
            </cfquery>

            <cfquery name="qAdsV1AdminPerformanceDaily" datasource="runnerhub">
                WITH days AS (
                    SELECT generate_series(
                        current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1PerformanceDays - 1#"/> * interval '1 day'),
                        current_date,
                        interval '1 day'
                    )::date AS metric_date
                ),
                metrics AS (
                    SELECT metric.metric_date,
                           sum(metric.viewable_impression_count)::bigint AS impressions,
                           sum(metric.valid_click_count)::bigint AS clicks,
                           sum(metric.billable_click_count)::bigint AS billable_clicks,
                           sum(metric.conversion_count)::bigint AS conversions,
                           coalesce(sum(metric.cost), 0)::numeric(14, 2) AS cost
                    FROM ads.daily_metrics metric
                    WHERE metric.metric_date >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1PerformanceDays - 1#"/> * interval '1 day')
                      AND metric.billing_model = 'CPC'
                      AND metric.ad_type = 'EVENT'
                    GROUP BY metric.metric_date
                )
                SELECT days.metric_date,
                       coalesce(metrics.impressions, 0)::bigint AS impressions,
                       coalesce(metrics.clicks, 0)::bigint AS clicks,
                       coalesce(metrics.billable_clicks, 0)::bigint AS billable_clicks,
                       coalesce(metrics.conversions, 0)::bigint AS conversions,
                       coalesce(metrics.cost, 0)::numeric(14, 2) AS cost
                FROM days
                LEFT JOIN metrics ON metrics.metric_date = days.metric_date
                ORDER BY days.metric_date
            </cfquery>

            <cfquery name="qAdsV1AdminPerformanceComparison" datasource="runnerhub">
                WITH metrics AS (
                    SELECT metric.metric_date,
                           sum(metric.viewable_impression_count)::bigint AS impressions,
                           sum(metric.valid_click_count)::bigint AS clicks,
                           coalesce(sum(metric.cost), 0)::numeric(14, 2) AS cost
                    FROM ads.daily_metrics metric
                    WHERE metric.metric_date >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#(VARIABLES.adsV1PerformanceDays * 2) - 1#"/> * interval '1 day')
                      AND metric.billing_model = 'CPC'
                      AND metric.ad_type = 'EVENT'
                    GROUP BY metric.metric_date
                )
                SELECT coalesce(sum(impressions) FILTER (
                           WHERE metric_date >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1PerformanceDays - 1#"/> * interval '1 day')
                       ), 0)::bigint AS current_impressions,
                       coalesce(sum(impressions) FILTER (
                           WHERE metric_date < current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1PerformanceDays - 1#"/> * interval '1 day')
                       ), 0)::bigint AS previous_impressions,
                       coalesce(sum(clicks) FILTER (
                           WHERE metric_date >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1PerformanceDays - 1#"/> * interval '1 day')
                       ), 0)::bigint AS current_clicks,
                       coalesce(sum(clicks) FILTER (
                           WHERE metric_date < current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1PerformanceDays - 1#"/> * interval '1 day')
                       ), 0)::bigint AS previous_clicks,
                       coalesce(sum(cost) FILTER (
                           WHERE metric_date >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1PerformanceDays - 1#"/> * interval '1 day')
                       ), 0)::numeric(14, 2) AS current_cost,
                       coalesce(sum(cost) FILTER (
                           WHERE metric_date < current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1PerformanceDays - 1#"/> * interval '1 day')
                       ), 0)::numeric(14, 2) AS previous_cost
                FROM metrics
            </cfquery>
        </cfif>

        <cfcatch type="any">
            <cfset VARIABLES.adsV1ReviewApiReady = false/>
            <cflog file="business_ads_v1" type="error" text="review_queue actor=#VARIABLES.adsV1ActorId# message=#left(cfcatch.message & '', 1000)#"/>
        </cfcatch>
    </cftry>
</cfif>

<cfif VARIABLES.adsAccessCanAdminVouchers AND VARIABLES.adsV1ApiReady>
    <cftry>
        <cfquery name="qAdsV1AdminVoucherReadiness" datasource="runnerhub">
            SELECT to_regprocedure(
                       'ads.create_voucher(text,bigint,text,numeric,date,text,text,integer)'
                   ) IS NOT NULL
                   AND has_function_privilege(
                       current_user,
                       to_regprocedure(
                           'ads.create_voucher(text,bigint,text,numeric,date,text,text,integer)'
                       ),
                       'EXECUTE'
                   )
                   AND EXISTS (
                       SELECT 1
                       FROM information_schema.columns
                       WHERE table_schema = 'ads'
                         AND table_name = 'tb_ad_vouchers'
                         AND column_name = 'voucher_scope'
                   ) AS ready
        </cfquery>
        <cfset VARIABLES.adsV1AdminVoucherApiReady = qAdsV1AdminVoucherReadiness.recordcount
            AND listFindNoCase("1,true,t,yes,on", trim(qAdsV1AdminVoucherReadiness.ready & "")) GT 0/>

        <cfif VARIABLES.adsV1AdminVoucherApiReady>
            <cfquery name="qAdsV1AdminVoucherAccounts" datasource="runnerhub">
                SELECT account.id_conta,
                       account.nome_conta,
                       account.status::text AS status
                FROM public.tb_contas account
                WHERE account.status::text IN ('ATIVA', 'PENDENTE')
                ORDER BY account.nome_conta, account.id_conta
            </cfquery>

            <cfquery name="qAdsV1AdminVouchers" datasource="runnerhub">
                SELECT voucher.id_ad_voucher,
                       voucher.codigo,
                       voucher.voucher_scope,
                       voucher.id_conta,
                       account.nome_conta AS account_name,
                       voucher.credito,
                       voucher.credito_disponivel,
                       voucher.status,
                       voucher.data_criacao,
                       voucher.data_expiracao,
                       voucher.id_usuario_resgate,
                       redeemed_by.name AS redeemed_by_name,
                       redeemed_by.email AS redeemed_by_email,
                       voucher.data_resgate,
                       voucher.observacao,
                       reservation.status AS reservation_status,
                       reserved_account.nome_conta AS reserved_account_name
                FROM ads.tb_ad_vouchers voucher
                LEFT JOIN public.tb_contas account
                  ON account.id_conta = voucher.id_conta
                LEFT JOIN public.tb_usuarios redeemed_by
                  ON redeemed_by.id = voucher.id_usuario_resgate
                LEFT JOIN LATERAL (
                    SELECT stored.id_conta,
                           stored.status
                    FROM ads.voucher_reservations stored
                    WHERE stored.id_ad_voucher = voucher.id_ad_voucher
                    ORDER BY stored.voucher_reservation_id DESC
                    LIMIT 1
                ) reservation ON true
                LEFT JOIN public.tb_contas reserved_account
                  ON reserved_account.id_conta = reservation.id_conta
                ORDER BY voucher.data_criacao DESC,
                         voucher.id_ad_voucher DESC
                LIMIT 200
            </cfquery>
        </cfif>

        <cfcatch type="any">
            <cfset VARIABLES.adsV1AdminVoucherApiReady = false/>
            <cflog file="business_ads_v1" type="error" text="voucher_admin_read actor=#VARIABLES.adsV1ActorId# message=#left(cfcatch.message & '', 1000)#"/>
        </cfcatch>
    </cftry>
</cfif>

<cfset VARIABLES.adsV1CanMutate = VARIABLES.adsV1HasAccount
    AND VARIABLES.adsV1ApiReady
    AND VARIABLES.adsV1ActorId GT 0/>
<cfset VARIABLES.adsV1CanReviewMutate = VARIABLES.adsAccessCanReviewCampaign
    AND VARIABLES.adsV1ReviewApiReady
    AND VARIABLES.adsV1ActorId GT 0/>
<cfset VARIABLES.adsV1CanAdminVoucherMutate = VARIABLES.adsAccessCanAdminVouchers
    AND VARIABLES.adsV1AdminVoucherApiReady
    AND VARIABLES.adsV1ActorId GT 0/>

<cfif VARIABLES.adsAccessCanView AND VARIABLES.adsV1HasAccount AND VARIABLES.adsV1ApiReady>
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
              <cfif VARIABLES.adsAccessIsPendingNewAccount>
                AND cont.status::text = 'PENDENTE'
              <cfelse>
                AND cont.status::text = 'ATIVA'
              </cfif>
            LIMIT 1
        </cfquery>

        <cfif NOT qAdsV1Account.recordcount>
            <cfset VARIABLES.adsV1HasAccount = false/>
            <cfset VARIABLES.adsV1CanMutate = false/>
            <cfset VARIABLES.adsV1Error = "A conta selecionada não está disponível para publicidade."/>
        <cfelse>
            <cfset VARIABLES.adsV1Summary.balance = val(qAdsV1Account.available_balance)/>

            <cfif VARIABLES.adsAccessIsPendingNewAccount>
                <cfquery name="qAdsV1VoucherReservation" datasource="runnerhub">
                    SELECT reservation.voucher_reservation_id,
                           reservation.id_ad_voucher,
                           reservation.id_conta,
                           reservation.id_solicitacao_cadastro,
                           reservation.status,
                           reservation.expires_at,
                           reservation.transition_reason,
                           voucher.codigo,
                           coalesce(voucher.credito_disponivel, voucher.credito, 0)::numeric(14, 2) AS credito
                    FROM ads.voucher_reservations reservation
                    INNER JOIN ads.tb_ad_vouchers voucher
                      ON voucher.id_ad_voucher = reservation.id_ad_voucher
                    WHERE reservation.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
                      AND reservation.id_solicitacao_cadastro = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsAccessRegistrationId#"/>
                    ORDER BY reservation.voucher_reservation_id DESC
                    LIMIT 1
                </cfquery>
            </cfif>

            <cfquery name="qAdsV1Events" datasource="runnerhub">
                SELECT evt.id_evento,
                       evt.nome_evento,
                       evt.tag,
                       evt.data_inicial,
                       evt.data_final,
                       evt.cidade,
                       evt.estado,
                       evt.url_imagem,
                       evt.url_imagem_listagem,
                       evt.imagem,
                       ce.status::text AS event_link_status
                FROM public.tb_conta_eventos ce
                INNER JOIN public.tb_evento_corridas evt
                  ON evt.id_evento = ce.id_evento
                WHERE ce.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
                  AND ce.status::text IN ('ATIVO', 'PENDENTE')
                  AND (
                    ce.status::text = 'ATIVO'
                    <cfif VARIABLES.adsAccessIsPendingNewAccount>
                      OR (
                        ce.status::text = 'PENDENTE'
                        AND EXISTS (
                            SELECT 1
                            FROM public.tb_conta_evento_solicitacoes req
                            WHERE req.id_conta = ce.id_conta
                              AND req.id_evento = ce.id_evento
                              AND req.id_usuario_solicitante = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1ActorId#"/>
                              AND req.status = 'PENDENTE'
                        )
                      )
                    </cfif>
                  )
                  AND evt.ativo = true
                ORDER BY evt.data_inicial DESC NULLS LAST,
                         evt.nome_evento
            </cfquery>

            <cfquery name="qAdsV1Placements" datasource="runnerhub">
                SELECT placement.placement_key,
                       placement.surface
                FROM ads.placements placement
                WHERE placement.status = 'ACTIVE'
                  AND placement.format_key = 'NATIVE_EVENT'
                  AND placement.placement_key IN (
                      'rr-home-upcoming-native',
                      'rr-search-events-native',
                      'rr-state-events-native',
                      'rr-sidebar-event-native'
                  )
                ORDER BY array_position(
                    ARRAY[
                        'rr-home-upcoming-native',
                        'rr-search-events-native',
                        'rr-state-events-native',
                        'rr-sidebar-event-native'
                    ]::text[],
                    placement.placement_key
                )
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
                       placement.placement_keys,
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
                       coalesce(metrics.cost, 0)::numeric(14, 2) AS cost,
                       review.campaign_review_request_id,
                       review.status AS review_status,
                       review.review_reason,
                       review.submitted_at,
                       review.reviewed_at,
                       event_link.status::text AS event_link_status,
                       account.status::text AS account_status
                FROM ads.campaigns c
                INNER JOIN public.tb_contas account
                  ON account.id_conta = c.account_id
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
                LEFT JOIN public.tb_conta_eventos event_link
                  ON event_link.id_conta = c.account_id
                 AND event_link.id_evento = advertisement.core_event_id
                LEFT JOIN LATERAL (
                    SELECT request.campaign_review_request_id,
                           request.status,
                           request.review_reason,
                           request.submitted_at,
                           request.reviewed_at
                    FROM ads.campaign_review_requests request
                    WHERE request.campaign_id = c.campaign_id
                      AND request.account_id = c.account_id
                    ORDER BY request.campaign_review_request_id DESC
                    LIMIT 1
                ) review ON true
                LEFT JOIN LATERAL (
                    SELECT string_agg(
                               DISTINCT pl.placement_key,
                               ',' ORDER BY pl.placement_key
                           ) AS placement_keys
                    FROM ads.campaign_placements link
                    INNER JOIN ads.placements pl
                      ON pl.placement_id = link.placement_id
                    WHERE link.campaign_id = c.campaign_id
                      AND link.account_id = c.account_id
                      AND link.status = 'ACTIVE'
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

            <cfif lCase(trim(URL.view & "")) EQ "overview" AND adsV1IsUuid(URL.ads_campaign)>
                <cfloop query="qAdsV1Campaigns">
                    <cfif compareNoCase(trim(qAdsV1Campaigns.campaign_id & ""), trim(URL.ads_campaign & "")) EQ 0>
                        <cfset VARIABLES.adsV1PerformanceCampaignId = lCase(trim(qAdsV1Campaigns.campaign_id & ""))/>
                        <cfset VARIABLES.adsV1PerformanceCampaignName = trim(qAdsV1Campaigns.name & "")/>
                        <cfbreak/>
                    </cfif>
                </cfloop>
            </cfif>

            <cfquery name="qAdsV1AccountPerformanceDaily" datasource="runnerhub">
                WITH days AS (
                    SELECT generate_series(
                        current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1PerformanceDays - 1#"/> * interval '1 day'),
                        current_date,
                        interval '1 day'
                    )::date AS metric_date
                ),
                metrics AS (
                    SELECT metric.metric_date,
                           sum(metric.viewable_impression_count)::bigint AS impressions,
                           sum(metric.valid_click_count)::bigint AS clicks,
                           sum(metric.billable_click_count)::bigint AS billable_clicks,
                           sum(metric.conversion_count)::bigint AS conversions,
                           coalesce(sum(metric.cost), 0)::numeric(14, 2) AS cost
                    FROM ads.daily_metrics metric
                    WHERE metric.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
                      <cfif len(VARIABLES.adsV1PerformanceCampaignId)>AND metric.campaign_id = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1PerformanceCampaignId#"/> AS uuid)</cfif>
                      AND metric.metric_date >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1PerformanceDays - 1#"/> * interval '1 day')
                      AND metric.billing_model = 'CPC'
                      AND metric.ad_type = 'EVENT'
                    GROUP BY metric.metric_date
                )
                SELECT days.metric_date,
                       coalesce(metrics.impressions, 0)::bigint AS impressions,
                       coalesce(metrics.clicks, 0)::bigint AS clicks,
                       coalesce(metrics.billable_clicks, 0)::bigint AS billable_clicks,
                       coalesce(metrics.conversions, 0)::bigint AS conversions,
                       coalesce(metrics.cost, 0)::numeric(14, 2) AS cost
                FROM days
                LEFT JOIN metrics ON metrics.metric_date = days.metric_date
                ORDER BY days.metric_date
            </cfquery>

            <cfquery name="qAdsV1AccountPerformanceComparison" datasource="runnerhub">
                WITH metrics AS (
                    SELECT metric.metric_date,
                           sum(metric.viewable_impression_count)::bigint AS impressions,
                           sum(metric.valid_click_count)::bigint AS clicks,
                           coalesce(sum(metric.cost), 0)::numeric(14, 2) AS cost
                    FROM ads.daily_metrics metric
                    WHERE metric.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
                      <cfif len(VARIABLES.adsV1PerformanceCampaignId)>AND metric.campaign_id = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1PerformanceCampaignId#"/> AS uuid)</cfif>
                      AND metric.metric_date >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#(VARIABLES.adsV1PerformanceDays * 2) - 1#"/> * interval '1 day')
                      AND metric.billing_model = 'CPC'
                      AND metric.ad_type = 'EVENT'
                    GROUP BY metric.metric_date
                )
                SELECT coalesce(sum(impressions) FILTER (
                           WHERE metric_date >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1PerformanceDays - 1#"/> * interval '1 day')
                       ), 0)::bigint AS current_impressions,
                       coalesce(sum(impressions) FILTER (
                           WHERE metric_date < current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1PerformanceDays - 1#"/> * interval '1 day')
                       ), 0)::bigint AS previous_impressions,
                       coalesce(sum(clicks) FILTER (
                           WHERE metric_date >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1PerformanceDays - 1#"/> * interval '1 day')
                       ), 0)::bigint AS current_clicks,
                       coalesce(sum(clicks) FILTER (
                           WHERE metric_date < current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1PerformanceDays - 1#"/> * interval '1 day')
                       ), 0)::bigint AS previous_clicks,
                       coalesce(sum(cost) FILTER (
                           WHERE metric_date >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1PerformanceDays - 1#"/> * interval '1 day')
                       ), 0)::numeric(14, 2) AS current_cost,
                       coalesce(sum(cost) FILTER (
                           WHERE metric_date < current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1PerformanceDays - 1#"/> * interval '1 day')
                       ), 0)::numeric(14, 2) AS previous_cost
                FROM metrics
            </cfquery>

            <cfif VARIABLES.adsAccessCanAdminFinance>
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
            </cfif>

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
                           advertisement.core_event_id,
                           advertisement.destination_url,
                           evt.nome_evento AS event_name,
                           evt.tag AS event_tag,
                           evt.data_inicial AS event_date,
                           evt.cidade AS event_city,
                           evt.estado AS event_state,
                           placement.placement_keys,
                           coalesce(budget.spent_total, 0)::numeric(14, 2) AS spent_total,
                           review.campaign_review_request_id,
                           review.status AS review_status,
                           review.review_reason,
                           review.submitted_at,
                           review.reviewed_at
                    FROM ads.campaigns c
                    LEFT JOIN LATERAL (
                        SELECT ad.core_event_id,
                               ad.destination_url
                        FROM ads.advertisements ad
                        WHERE ad.campaign_id = c.campaign_id
                          AND ad.account_id = c.account_id
                          AND ad.ad_type = 'EVENT'
                        ORDER BY ad.created_at, ad.advertisement_id
                        LIMIT 1
                    ) advertisement ON true
                    LEFT JOIN public.tb_evento_corridas evt
                      ON evt.id_evento = advertisement.core_event_id
                    LEFT JOIN LATERAL (
                        SELECT string_agg(
                                   DISTINCT pl.placement_key,
                                   ',' ORDER BY pl.placement_key
                               ) AS placement_keys
                        FROM ads.campaign_placements link
                        INNER JOIN ads.placements pl
                          ON pl.placement_id = link.placement_id
                        WHERE link.campaign_id = c.campaign_id
                          AND link.account_id = c.account_id
                          AND link.status = 'ACTIVE'
                    ) placement ON true
                    LEFT JOIN LATERAL (
                        SELECT request.campaign_review_request_id,
                               request.status,
                               request.review_reason,
                               request.submitted_at,
                               request.reviewed_at
                        FROM ads.campaign_review_requests request
                        WHERE request.campaign_id = c.campaign_id
                          AND request.account_id = c.account_id
                        ORDER BY request.campaign_review_request_id DESC
                        LIMIT 1
                    ) review ON true
                    LEFT JOIN ads.campaign_budget_state budget
                      ON budget.campaign_id = c.campaign_id
                     AND budget.account_id = c.account_id
                     AND budget.currency = c.currency
                    WHERE c.campaign_id = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1SelectedCampaignId#"/> AS uuid)
                      AND c.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
                      AND c.billing_model = 'CPC'
                    LIMIT 1
                </cfquery>

                <cfif qAdsV1SelectedCampaign.recordcount AND lCase(trim(URL.view & "")) EQ "campaign-detail">
                    <cfquery name="qAdsV1CampaignPerformanceDaily" datasource="runnerhub">
                        WITH days AS (
                            SELECT generate_series(
                                current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1PerformanceDays - 1#"/> * interval '1 day'),
                                current_date,
                                interval '1 day'
                            )::date AS metric_date
                        ),
                        metrics AS (
                            SELECT metric.metric_date,
                                   sum(metric.viewable_impression_count)::bigint AS impressions,
                                   sum(metric.valid_click_count)::bigint AS clicks,
                                   sum(metric.billable_click_count)::bigint AS billable_clicks,
                                   sum(metric.conversion_count)::bigint AS conversions,
                                   coalesce(sum(metric.cost), 0)::numeric(14, 2) AS cost
                            FROM ads.daily_metrics metric
                            WHERE metric.campaign_id = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1SelectedCampaignId#"/> AS uuid)
                              AND metric.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
                              AND metric.metric_date >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1PerformanceDays - 1#"/> * interval '1 day')
                              AND metric.billing_model = 'CPC'
                              AND metric.ad_type = 'EVENT'
                            GROUP BY metric.metric_date
                        )
                        SELECT days.metric_date,
                               coalesce(metrics.impressions, 0)::bigint AS impressions,
                               coalesce(metrics.clicks, 0)::bigint AS clicks,
                               coalesce(metrics.billable_clicks, 0)::bigint AS billable_clicks,
                               coalesce(metrics.conversions, 0)::bigint AS conversions,
                               coalesce(metrics.cost, 0)::numeric(14, 2) AS cost
                        FROM days
                        LEFT JOIN metrics ON metrics.metric_date = days.metric_date
                        ORDER BY days.metric_date
                    </cfquery>

                    <cfquery name="qAdsV1CampaignPerformanceComparison" datasource="runnerhub">
                        WITH metrics AS (
                            SELECT metric.metric_date,
                                   sum(metric.viewable_impression_count)::bigint AS impressions,
                                   sum(metric.valid_click_count)::bigint AS clicks,
                                   coalesce(sum(metric.cost), 0)::numeric(14, 2) AS cost
                            FROM ads.daily_metrics metric
                            WHERE metric.campaign_id = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1SelectedCampaignId#"/> AS uuid)
                              AND metric.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
                              AND metric.metric_date >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#(VARIABLES.adsV1PerformanceDays * 2) - 1#"/> * interval '1 day')
                              AND metric.billing_model = 'CPC'
                              AND metric.ad_type = 'EVENT'
                            GROUP BY metric.metric_date
                        )
                        SELECT coalesce(sum(impressions) FILTER (
                                   WHERE metric_date >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1PerformanceDays - 1#"/> * interval '1 day')
                               ), 0)::bigint AS current_impressions,
                               coalesce(sum(impressions) FILTER (
                                   WHERE metric_date < current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1PerformanceDays - 1#"/> * interval '1 day')
                               ), 0)::bigint AS previous_impressions,
                               coalesce(sum(clicks) FILTER (
                                   WHERE metric_date >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1PerformanceDays - 1#"/> * interval '1 day')
                               ), 0)::bigint AS current_clicks,
                               coalesce(sum(clicks) FILTER (
                                   WHERE metric_date < current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1PerformanceDays - 1#"/> * interval '1 day')
                               ), 0)::bigint AS previous_clicks,
                               coalesce(sum(cost) FILTER (
                                   WHERE metric_date >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1PerformanceDays - 1#"/> * interval '1 day')
                               ), 0)::numeric(14, 2) AS current_cost,
                               coalesce(sum(cost) FILTER (
                                   WHERE metric_date < current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1PerformanceDays - 1#"/> * interval '1 day')
                               ), 0)::numeric(14, 2) AS previous_cost
                        FROM metrics
                    </cfquery>

                    <cfquery name="qAdsV1CampaignStatusHistory" datasource="runnerhub">
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
                        WHERE history.campaign_id = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1SelectedCampaignId#"/> AS uuid)
                          AND history.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
                        ORDER BY history.changed_at DESC,
                                 history.campaign_status_history_id DESC
                        LIMIT 20
                    </cfquery>
                </cfif>
            </cfif>
            <cfset VARIABLES.adsV1DataReady = true/>
        </cfif>

        <cfcatch type="any">
            <cfset VARIABLES.adsV1DataReady = false/>
            <cfset VARIABLES.adsV1CanMutate = false/>
            <cfset VARIABLES.adsV1Error = "Nao foi possivel carregar os dados de publicidade desta conta."/>
            <cflog file="business_ads_v1" type="error" text="read account=#VARIABLES.adsV1AccountId# actor=#VARIABLES.adsV1ActorId# message=#cfcatch.message#"/>
        </cfcatch>
    </cftry>
</cfif>

<cfinclude template="payments_backend.cfm"/>

<cfif len(trim(FORM.ads_v1_action & "")) AND NOT VARIABLES.adsPaymentActionHandled>
    <cfset VARIABLES.adsV1Action = lCase(trim(FORM.ads_v1_action & ""))/>

    <cftry>
        <cfif NOT VARIABLES.adsV1CanMutate
            AND NOT (
                listFindNoCase(VARIABLES.adsV1ReviewActions, VARIABLES.adsV1Action)
                AND VARIABLES.adsV1CanReviewMutate
            )
            AND NOT (
                listFindNoCase(VARIABLES.adsV1VoucherAdminActions, VARIABLES.adsV1Action)
                AND VARIABLES.adsV1CanAdminVoucherMutate
            )>
            <cfthrow type="AdsV1.Validation" message="A operacao de publicidade nao esta disponivel para esta conta."/>
        </cfif>
        <cfif listFindNoCase(VARIABLES.adsV1CampaignActions, VARIABLES.adsV1Action)
            AND NOT VARIABLES.adsAccessCanManageCampaign>
            <cfheader statuscode="403" statustext="Forbidden"/>
            <cfthrow type="AdsV1.Forbidden" message="Seu papel nesta conta nao permite administrar campanhas."/>
        </cfif>
        <cfif listFindNoCase(VARIABLES.adsV1FinanceActions, VARIABLES.adsV1Action)
            AND NOT VARIABLES.adsAccessCanAdminFinance>
            <cfheader statuscode="403" statustext="Forbidden"/>
            <cfthrow type="AdsV1.Forbidden" message="Esta operacao financeira exige um administrador interno real e uma conta selecionada."/>
        </cfif>
        <cfif listFindNoCase(VARIABLES.adsV1ReviewActions, VARIABLES.adsV1Action)
            AND NOT VARIABLES.adsAccessCanReviewCampaign>
            <cfheader statuscode="403" statustext="Forbidden"/>
            <cfthrow type="AdsV1.Forbidden" message="Somente um administrador RunnerHub pode revisar campanhas."/>
        </cfif>
        <cfif listFindNoCase(VARIABLES.adsV1VoucherAdminActions, VARIABLES.adsV1Action)
            AND NOT VARIABLES.adsAccessCanAdminVouchers>
            <cfheader statuscode="403" statustext="Forbidden"/>
            <cfthrow type="AdsV1.Forbidden" message="Somente um administrador RunnerHub pode criar vouchers."/>
        </cfif>
        <cfif VARIABLES.adsV1Action EQ "redeem_voucher"
            AND NOT VARIABLES.adsAccessCanPurchaseCredit>
            <cfheader statuscode="403" statustext="Forbidden"/>
            <cfthrow type="AdsV1.Forbidden" message="Somente OWNER ou ADMIN da conta pode resgatar vouchers."/>
        </cfif>
        <cfif VARIABLES.adsV1Action EQ "reserve_voucher"
            AND NOT VARIABLES.adsAccessCanReserveVoucher>
            <cfheader statuscode="403" statustext="Forbidden"/>
            <cfthrow type="AdsV1.Forbidden" message="Somente o OWNER da conta provisória pode reservar vouchers."/>
        </cfif>
        <cfif compare(trim(FORM.ads_v1_csrf & ""), VARIABLES.adsV1Csrf) NEQ 0>
            <cfthrow type="AdsV1.Validation" message="A sessao do formulario expirou. Recarregue a pagina."/>
        </cfif>

        <cfswitch expression="#VARIABLES.adsV1Action#">
            <cfcase value="create_admin_voucher">
                <cfset VARIABLES.adsV1AdminVoucherScope = uCase(trim(FORM.voucher_scope & ""))/>
                <cfset VARIABLES.adsV1AdminVoucherAccountId = isNumeric(FORM.voucher_account_id) ? val(FORM.voucher_account_id) : 0/>
                <cfset VARIABLES.adsV1AdminVoucherCode = uCase(trim(FORM.voucher_code & ""))/>
                <cfset VARIABLES.adsV1AdminVoucherAmount = adsV1MoneyValue(FORM.voucher_amount)/>
                <cfset VARIABLES.adsV1AdminVoucherExpiresOn = trim(FORM.voucher_expires_on & "")/>
                <cfset VARIABLES.adsV1AdminVoucherRole = uCase(trim(FORM.voucher_redemption_role & ""))/>
                <cfset VARIABLES.adsV1AdminVoucherNote = trim(FORM.voucher_note & "")/>

                <cfif NOT listFind("PROMOTIONAL,ACCOUNT", VARIABLES.adsV1AdminVoucherScope)>
                    <cfthrow type="AdsV1.Validation" message="Escolha se o voucher é promocional ou restrito a uma conta."/>
                </cfif>
                <cfif VARIABLES.adsV1AdminVoucherScope EQ "ACCOUNT"
                    AND VARIABLES.adsV1AdminVoucherAccountId LTE 0>
                    <cfthrow type="AdsV1.Validation" message="Escolha a conta do voucher restrito."/>
                </cfif>
                <cfif VARIABLES.adsV1AdminVoucherScope EQ "PROMOTIONAL">
                    <cfset VARIABLES.adsV1AdminVoucherAccountId = 0/>
                </cfif>
                <cfif NOT len(VARIABLES.adsV1AdminVoucherCode)>
                    <cfset VARIABLES.adsV1AdminVoucherCode = "RUNPRO-" & left(uCase(hash(createUUID(), "SHA-256")), 10)/>
                </cfif>
                <cfif len(VARIABLES.adsV1AdminVoucherCode) LT 3
                    OR len(VARIABLES.adsV1AdminVoucherCode) GT 80
                    OR NOT reFind("^[A-Z0-9-]+$", VARIABLES.adsV1AdminVoucherCode)>
                    <cfthrow type="AdsV1.Validation" message="Informe um código com letras, números e hífen."/>
                </cfif>
                <cfif VARIABLES.adsV1AdminVoucherAmount LTE 0>
                    <cfthrow type="AdsV1.Validation" message="Informe um crédito maior que zero."/>
                </cfif>
                <cfif len(VARIABLES.adsV1AdminVoucherExpiresOn)
                    AND NOT isDate(VARIABLES.adsV1AdminVoucherExpiresOn)>
                    <cfthrow type="AdsV1.Validation" message="Informe uma validade correta."/>
                </cfif>
                <cfif NOT listFind("OWNER,ADMIN,OPERADOR,VISUALIZADOR", VARIABLES.adsV1AdminVoucherRole)>
                    <cfthrow type="AdsV1.Validation" message="Escolha um papel válido para o resgate."/>
                </cfif>
                <cfif len(VARIABLES.adsV1AdminVoucherNote) GT 500>
                    <cfthrow type="AdsV1.Validation" message="A observação deve ter no máximo 500 caracteres."/>
                </cfif>

                <cfquery name="qAdsV1AdminVoucherCreate" datasource="runnerhub">
                    SELECT *
                    FROM ads.create_voucher(
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1AdminVoucherScope#"/> AS text),
                        CAST(<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AdminVoucherAccountId#" null="#VARIABLES.adsV1AdminVoucherScope EQ 'PROMOTIONAL'#"/> AS bigint),
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1AdminVoucherCode#" maxlength="80"/> AS text),
                        CAST(<cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.adsV1AdminVoucherAmount#" scale="2"/> AS numeric),
                        CAST(<cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.adsV1AdminVoucherExpiresOn#" null="#NOT len(VARIABLES.adsV1AdminVoucherExpiresOn)#"/> AS date),
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1AdminVoucherRole#"/> AS text),
                        CAST(<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.adsV1AdminVoucherNote#" null="#NOT len(VARIABLES.adsV1AdminVoucherNote)#"/> AS text),
                        CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1ActorId#"/> AS integer)
                    )
                </cfquery>

                <cflocation addtoken="false" url="./?view=vouchers&amp;success=voucher-created##admin-vouchers"/>
            </cfcase>

            <cfcase value="approve_campaign_review,request_campaign_changes,cancel_campaign_review">
                <cfset VARIABLES.adsV1ReviewCampaignId = structKeyExists(FORM, "campaign_id") ? lCase(trim(FORM.campaign_id & "")) : ""/>
                <cfset VARIABLES.adsV1ReviewRequestId = structKeyExists(FORM, "campaign_review_request_id") AND isNumeric(FORM.campaign_review_request_id) ? val(FORM.campaign_review_request_id) : 0/>
                <cfset VARIABLES.adsV1ReviewReason = structKeyExists(FORM, "review_reason") ? trim(FORM.review_reason & "") : ""/>
                <cfset VARIABLES.adsV1ReviewDecision = VARIABLES.adsV1Action EQ "approve_campaign_review"
                    ? "APPROVE"
                    : (VARIABLES.adsV1Action EQ "request_campaign_changes" ? "REQUEST_CHANGES" : "CANCEL")/>

                <cfif NOT adsV1IsUuid(VARIABLES.adsV1ReviewCampaignId) OR VARIABLES.adsV1ReviewRequestId LTE 0>
                    <cfthrow type="AdsV1.Validation" message="Solicitação de análise inválida."/>
                </cfif>
                <cfif listFind("REQUEST_CHANGES,CANCEL", VARIABLES.adsV1ReviewDecision)
                    AND (len(VARIABLES.adsV1ReviewReason) LT 5 OR len(VARIABLES.adsV1ReviewReason) GT 1000)>
                    <cfthrow type="AdsV1.Validation" message="Informe um motivo entre 5 e 1000 caracteres."/>
                </cfif>
                <cfif VARIABLES.adsV1ReviewDecision EQ "APPROVE" AND len(VARIABLES.adsV1ReviewReason) GT 1000>
                    <cfthrow type="AdsV1.Validation" message="A nota da aprovação deve ter no máximo 1000 caracteres."/>
                </cfif>

                <cfquery name="qAdsV1ReviewDecisionTarget" datasource="runnerhub">
                    SELECT review.campaign_review_request_id,
                           review.campaign_id,
                           review.status
                    FROM ads.campaign_review_requests review
                    WHERE review.campaign_review_request_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1ReviewRequestId#"/>
                      AND review.campaign_id = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1ReviewCampaignId#"/> AS uuid)
                      AND review.status IN ('WAITING_PREREQUISITES', 'PENDING_REVIEW', 'CHANGES_REQUESTED')
                    LIMIT 1
                </cfquery>

                <cfif NOT qAdsV1ReviewDecisionTarget.recordcount>
                    <cfthrow type="AdsV1.Validation" message="Esta solicitação de análise não está mais disponível."/>
                </cfif>
                <cfif VARIABLES.adsV1ReviewDecision EQ "APPROVE"
                    AND qAdsV1ReviewDecisionTarget.status NEQ "PENDING_REVIEW">
                    <cfthrow type="AdsV1.Validation" message="A campanha ainda não concluiu os pré-requisitos para aprovação."/>
                </cfif>

                <cfset VARIABLES.adsV1ReviewApprovalKey = VARIABLES.adsV1ReviewDecision EQ "APPROVE"
                    ? "business:campaign-review:" & VARIABLES.adsV1ReviewRequestId
                    : ""/>

                <cfquery name="qAdsV1ReviewDecisionResult" datasource="runnerhub">
                    SELECT *
                    FROM ads.review_campaign(
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1ReviewCampaignId#"/> AS uuid),
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1ReviewDecision#"/> AS text),
                        CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1ActorId#"/> AS integer),
                        CAST(<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.adsV1ReviewReason#" null="#NOT len(VARIABLES.adsV1ReviewReason)#"/> AS text),
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1ReviewApprovalKey#" null="#NOT len(VARIABLES.adsV1ReviewApprovalKey)#"/> AS text)
                    )
                </cfquery>

                <cfif VARIABLES.adsV1ReviewDecision EQ "APPROVE">
                    <cflocation addtoken="false" url="./?view=admin&amp;success=campaign-approved"/>
                <cfelseif VARIABLES.adsV1ReviewDecision EQ "REQUEST_CHANGES">
                    <cflocation addtoken="false" url="./?view=admin&amp;success=campaign-changes-requested"/>
                <cfelse>
                    <cflocation addtoken="false" url="./?view=admin&amp;success=campaign-review-canceled"/>
                </cfif>
            </cfcase>

            <cfcase value="prepare_campaign_edit">
                <cfset VARIABLES.adsV1PrepareEditCampaignId = structKeyExists(FORM, "campaign_id") ? lCase(trim(FORM.campaign_id & "")) : ""/>
                <cfif NOT adsV1IsUuid(VARIABLES.adsV1PrepareEditCampaignId)>
                    <cfthrow type="AdsV1.Validation" message="Campanha inválida."/>
                </cfif>

                <cfquery name="qAdsV1PrepareEditResult" datasource="runnerhub">
                    SELECT *
                    FROM ads.prepare_campaign_for_edit(
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1PrepareEditCampaignId#"/> AS uuid),
                        CAST(<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/> AS bigint),
                        CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1ActorId#"/> AS integer)
                    )
                </cfquery>

                <cflocation addtoken="false" url="./?view=campaigns&status=draft&campaign=#urlEncodedFormat(VARIABLES.adsV1PrepareEditCampaignId)#&success=campaign-edit-ready##campaign-form"/>
            </cfcase>

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
                <cfset VARIABLES.adsV1FormPlacementInput = structKeyExists(FORM, "placement_keys") ? FORM.placement_keys : ""/>
                <cfset VARIABLES.adsV1FormPlacementCandidates = adsV1FormList(VARIABLES.adsV1FormPlacementInput)/>
                <cfset VARIABLES.adsV1FormPlacementKeys = []/>

                <cfloop array="#VARIABLES.adsV1FormPlacementCandidates#" index="VARIABLES.adsV1FormPlacementCandidate">
                    <cfset VARIABLES.adsV1FormPlacementKey = lCase(trim(VARIABLES.adsV1FormPlacementCandidate & ""))/>
                    <cfif listFindNoCase(arrayToList(VARIABLES.adsV1SelectableEventPlacementKeys), VARIABLES.adsV1FormPlacementKey)
                        AND NOT arrayFindNoCase(VARIABLES.adsV1FormPlacementKeys, VARIABLES.adsV1FormPlacementKey)>
                        <cfset arrayAppend(VARIABLES.adsV1FormPlacementKeys, VARIABLES.adsV1FormPlacementKey)/>
                    </cfif>
                </cfloop>

                <cfif NOT arrayLen(VARIABLES.adsV1FormPlacementKeys)>
                    <cfthrow type="AdsV1.Validation" message="Selecione ao menos um spot de publicidade valido."/>
                </cfif>
                <cfif arrayLen(VARIABLES.adsV1FormPlacementKeys) NEQ arrayLen(VARIABLES.adsV1FormPlacementCandidates)>
                    <cfthrow type="AdsV1.Validation" message="A lista de spots de publicidade e invalida ou contem duplicidades."/>
                </cfif>
                <cfif arrayFindNoCase(VARIABLES.adsV1FormPlacementKeys, "rr-home-upcoming-native")
                    AND NOT arrayFindNoCase(VARIABLES.adsV1FormPlacementKeys, "rr-home-upcoming-native-secondary")>
                    <cfset arrayAppend(VARIABLES.adsV1FormPlacementKeys, "rr-home-upcoming-native-secondary")/>
                </cfif>
                <cfset VARIABLES.adsV1FormPlacementArrayLiteral = "{" & arrayToList(VARIABLES.adsV1FormPlacementKeys) & "}"/>

                <cfif len(VARIABLES.adsV1FormCampaignId) AND NOT adsV1IsUuid(VARIABLES.adsV1FormCampaignId)>
                    <cfthrow type="AdsV1.Validation" message="Campanha invalida."/>
                </cfif>
                <cfif VARIABLES.adsV1FormEventId LTE 0>
                    <cfthrow type="AdsV1.Validation" message="Selecione um evento da conta."/>
                </cfif>
                <cfif len(VARIABLES.adsV1FormName) LT 3 OR len(VARIABLES.adsV1FormName) GT 160>
                    <cfthrow type="AdsV1.Validation" message="Informe um nome de campanha entre 3 e 160 caracteres."/>
                </cfif>
                <cfif NOT reFind("^[0-9]+([.,][0-9]{1,2})?$", VARIABLES.adsV1FormCpcRaw) OR VARIABLES.adsV1FormCpc LT 0.51>
                    <cfthrow type="AdsV1.Validation" message="O lance mínimo por clique é R$ 0,51."/>
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
                      AND ce.status::text IN ('ATIVO', 'PENDENTE')
                      AND (
                        ce.status::text = 'ATIVO'
                        <cfif VARIABLES.adsAccessIsPendingNewAccount>
                          OR (
                            ce.status::text = 'PENDENTE'
                            AND EXISTS (
                                SELECT 1
                                FROM public.tb_conta_evento_solicitacoes req
                                WHERE req.id_conta = ce.id_conta
                                  AND req.id_evento = ce.id_evento
                                  AND req.id_usuario_solicitante = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1ActorId#"/>
                                  AND req.status = 'PENDENTE'
                            )
                          )
                        </cfif>
                      )
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
                               c.status,
                               review.status AS review_status
                        FROM ads.campaigns c
                        LEFT JOIN LATERAL (
                            SELECT request.status
                            FROM ads.campaign_review_requests request
                            WHERE request.campaign_id = c.campaign_id
                              AND request.account_id = c.account_id
                            ORDER BY request.campaign_review_request_id DESC
                            LIMIT 1
                        ) review ON true
                        WHERE c.campaign_id = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1FormCampaignId#"/> AS uuid)
                          AND c.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
                          AND c.billing_model = 'CPC'
                          AND c.status IN ('DRAFT', 'PAUSED')
                        LIMIT 1
                    </cfquery>
                    <cfif NOT qAdsV1CampaignSaveTarget.recordcount
                        OR listFind("PENDING_REVIEW,APPROVED", uCase(trim(qAdsV1CampaignSaveTarget.review_status & "")))>
                        <cfthrow type="AdsV1.Validation" message="Somente campanhas em rascunho ou pausadas e fora de análise podem ser editadas."/>
                    </cfif>
                </cfif>

                <cfset VARIABLES.adsV1DestinationUrl = reReplace(VARIABLES.roadRunnersBaseUrl, "/+$", "", "all")
                    & "/evento/" & trim(qAdsV1EventTarget.tag) & "/"/>

                <cftransaction>
                    <cfquery name="qAdsV1CampaignSave" datasource="runnerhub">
                        SELECT *
                        <cfif VARIABLES.adsAccessIsPendingNewAccount>
                        FROM ads.save_pending_event_campaign(
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1FormCampaignId#" null="#NOT len(VARIABLES.adsV1FormCampaignId)#"/> AS uuid),
                            CAST(<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/> AS bigint),
                            CAST(<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsAccessRegistrationId#"/> AS bigint),
                        <cfelse>
                        FROM ads.save_event_campaign(
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1FormCampaignId#" null="#NOT len(VARIABLES.adsV1FormCampaignId)#"/> AS uuid),
                            CAST(<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/> AS bigint),
                        </cfif>
                            CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#qAdsV1EventTarget.id_evento#"/> AS integer),
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1FormPlacementKeys[1]#"/> AS text),
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

                    <cfquery name="qAdsV1CampaignPlacementSave" datasource="runnerhub">
                        SELECT *
                        FROM ads.replace_campaign_placements(
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#qAdsV1CampaignSave.campaign_id#"/> AS uuid),
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1FormPlacementArrayLiteral#"/> AS text[]),
                            CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1ActorId#"/> AS integer),
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="Spots salvos pelo Business"/> AS text)
                        )
                    </cfquery>
                </cftransaction>

                <cflocation addtoken="false" url="./?view=campaigns&amp;status=draft&amp;success=campaign-saved"/>
            </cfcase>

            <cfcase value="submit_campaign_review">
                <cfset VARIABLES.adsV1ReviewCampaignId = structKeyExists(FORM, "campaign_id") ? lCase(trim(FORM.campaign_id & "")) : ""/>
                <cfif NOT adsV1IsUuid(VARIABLES.adsV1ReviewCampaignId)>
                    <cfthrow type="AdsV1.Validation" message="Campanha inválida."/>
                </cfif>

                <cfquery name="qAdsV1ReviewTarget" datasource="runnerhub">
                    SELECT campaign.campaign_id,
                           advertisement.core_event_id
                    FROM ads.campaigns campaign
                    INNER JOIN ads.advertisements advertisement
                      ON advertisement.campaign_id = campaign.campaign_id
                     AND advertisement.account_id = campaign.account_id
                     AND advertisement.ad_type = 'EVENT'
                    WHERE campaign.campaign_id = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1ReviewCampaignId#"/> AS uuid)
                      AND campaign.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
                      AND campaign.billing_model = 'CPC'
                      AND campaign.status = 'DRAFT'
                    LIMIT 1
                </cfquery>

                <cfif NOT qAdsV1ReviewTarget.recordcount>
                    <cfthrow type="AdsV1.Validation" message="Somente um rascunho desta conta pode ser enviado para análise."/>
                </cfif>

                <cfquery name="qAdsV1ReviewSubmit" datasource="runnerhub">
                    SELECT *
                    FROM ads.submit_campaign_review(
                        CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1ReviewCampaignId#"/> AS uuid),
                        CAST(<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/> AS bigint),
                        CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1ActorId#"/> AS integer),
                        CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#qAdsV1ReviewTarget.core_event_id#"/> AS integer)
                    )
                </cfquery>

                <cflocation addtoken="false" url="./?view=campaigns&amp;success=campaign-submitted"/>
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

                <cflocation addtoken="false" url="./?view=admin&amp;success=credited"/>
            </cfcase>

            <cfcase value="redeem_voucher">
                <cfset VARIABLES.adsV1VoucherCode = uCase(trim(FORM.voucher_code & ""))/>

                <cfif len(VARIABLES.adsV1VoucherCode) LT 3
                    OR len(VARIABLES.adsV1VoucherCode) GT 160
                    OR NOT reFind("^[A-Z0-9-]+$", VARIABLES.adsV1VoucherCode)>
                    <cfthrow type="AdsV1.Validation" message="Informe um codigo de voucher valido."/>
                </cfif>

                <cftry>
                    <cfquery name="qAdsV1VoucherResult" datasource="runnerhub">
                        SELECT *
                        FROM ads.redeem_voucher(
                            CAST(<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/> AS bigint),
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1VoucherCode#" maxlength="160"/> AS text),
                            CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1ActorId#"/> AS integer)
                        )
                    </cfquery>

                    <cfcatch type="database">
                        <cflog file="business_ads_v1" type="warning" text="voucher_redeem account=#VARIABLES.adsV1AccountId# actor=#VARIABLES.adsV1ActorId# message=#left(cfcatch.message & '', 1000)#"/>
                        <cfthrow type="AdsV1.Validation" message="O voucher nao foi encontrado, expirou ou nao esta disponivel para esta conta."/>
                    </cfcatch>
                </cftry>

                <cflocation addtoken="false" url="./?view=payments&amp;success=voucher-redeemed##payment-credit"/>
            </cfcase>

            <cfcase value="reserve_voucher">
                <cfset VARIABLES.adsV1VoucherCode = uCase(trim(FORM.voucher_code & ""))/>

                <cfif len(VARIABLES.adsV1VoucherCode) LT 3
                    OR len(VARIABLES.adsV1VoucherCode) GT 160
                    OR NOT reFind("^[A-Z0-9-]+$", VARIABLES.adsV1VoucherCode)>
                    <cfthrow type="AdsV1.Validation" message="Informe um código de voucher válido."/>
                </cfif>

                <cftry>
                    <cfquery name="qAdsV1VoucherReservationResult" datasource="runnerhub">
                        SELECT *
                        FROM ads.reserve_voucher(
                            CAST(<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/> AS bigint),
                            CAST(<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsAccessRegistrationId#"/> AS bigint),
                            CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsV1VoucherCode#" maxlength="160"/> AS text),
                            CAST(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsV1ActorId#"/> AS integer)
                        )
                    </cfquery>

                    <cfcatch type="database">
                        <cflog file="business_ads_v1" type="warning" text="voucher_reserve account=#VARIABLES.adsV1AccountId# registration=#VARIABLES.adsAccessRegistrationId# actor=#VARIABLES.adsV1ActorId# message=#left(cfcatch.message & '', 1000)# detail=#left(cfcatch.detail & '', 2000)#"/>
                        <cfthrow type="AdsV1.Validation" message="O voucher não foi encontrado, expirou ou já está reservado."/>
                    </cfcatch>
                </cftry>

                <cflocation addtoken="false" url="./?view=payments&amp;success=voucher-reserved##ads-voucher-form"/>
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
                    <cflocation addtoken="false" url="./?view=campaigns&amp;success=paused"/>
                <cfelse>
                    <cflocation addtoken="false" url="./?view=campaigns&amp;success=ended"/>
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

                <cflocation addtoken="false" url="./?view=admin&amp;success=reversed"/>
            </cfcase>

            <cfdefaultcase>
                <cfthrow type="AdsV1.Validation" message="Acao de publicidade invalida."/>
            </cfdefaultcase>
        </cfswitch>

        <cfcatch type="any">
            <cflog file="business_ads_v1" type="error" text="action=#VARIABLES.adsV1Action# account=#VARIABLES.adsV1AccountId# actor=#VARIABLES.adsV1ActorId# type=#cfcatch.type# message=#left(cfcatch.message & '', 1000)# detail=#left(cfcatch.detail & '', 3000)#"/>
            <cfif cfcatch.type EQ "AdsV1.Validation" OR cfcatch.type EQ "AdsV1.Forbidden">
                <cfset VARIABLES.adsV1Error = cfcatch.message/>
            <cfelse>
                <cfset VARIABLES.adsV1Error = "Nao foi possivel concluir a operacao de publicidade. Tente novamente e consulte o log se o erro continuar."/>
            </cfif>
        </cfcatch>
    </cftry>
</cfif>

<cfif NOT len(VARIABLES.adsV1CreditIdempotencyKey)>
    <cfset VARIABLES.adsV1CreditIdempotencyKey = "business:manual-credit:"
        & VARIABLES.adsV1AccountId & ":" & adsV1NewIdempotencyToken()/>
</cfif>
