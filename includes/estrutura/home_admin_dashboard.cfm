<cfset qBusinessAdminHomeStats = QueryNew("contas_ativas,contas_pendentes,usuarios_ativos,eventos_ativos,solicitacoes_cadastro,solicitacoes_eventos,campanhas_ativas")/>
<cfset qBusinessAdminHomeRegistrations = QueryNew("id_solicitacao,nome_empresa,tipo_prestador,email_responsavel,data_criacao")/>
<cfset qBusinessAdminHomeEventRequests = QueryNew("id_solicitacao,nome_conta,nome_evento,data_criacao")/>
<cfset qBusinessAdminHomeLegacyPartners = QueryNew("id,name,email,perfil,nome_comercial")/>
<cfset qBusinessAdminHomeContentGaps = QueryNew("id_evento,nome_evento,cidade,estado,tag,data_inicial,missing_count,faltando")/>
<cfset qBusinessAdminHomeAdsPayments = QueryNew("pending_old,review,open_holds,paid_without_ledger,ledger_without_intent")/>
<cfset qBusinessAdminHomeAdsReconcileJob = QueryNew("last_run_at,last_duration_ms,last_status")/>
<cfset VARIABLES.businessAdminHomeReady = true/>
<cfset VARIABLES.businessAdminHomeError = ""/>
<cfset VARIABLES.businessAdminHomeTablesReady = false/>
<cfset VARIABLES.businessAdminHomeHasLogTable = false/>
<cfset VARIABLES.businessAdminHomeHasSearchTable = false/>
<cfset VARIABLES.businessAdminHomeHasFocoTables = false/>
<cfset VARIABLES.businessAdminHomeHasAgregaTables = false/>
<cfset VARIABLES.businessAdminHomeHasCronTables = false/>
<cfset VARIABLES.businessAdminHomeCronLoaded = false/>
<cfset VARIABLES.businessAdminHomeHasNotificationTable = false/>
<cfset VARIABLES.businessAdminHomeHasHelpdeskTable = false/>
<cfset VARIABLES.businessAdminHomeHasEditorialTable = false/>
<cfset VARIABLES.businessAdminHomeHasAdsReviewTable = false/>
<cfset VARIABLES.businessAdminHomeHasChallengeTable = false/>
<cfset VARIABLES.businessAdminHomeHasResultImportTable = false/>
<cfset VARIABLES.businessAdminHomeHasAthleteReviewTable = false/>
<cfset VARIABLES.businessAdminHomeHasCrmPendingTable = false/>
<cfset VARIABLES.businessAdminHomeHasStravaMigrationTable = false/>
<cfset VARIABLES.businessAdminHomeHasPushQueueTable = false/>
<cfset VARIABLES.businessAdminHomeHasEmailQueueTable = false/>
<cfset VARIABLES.businessAdminHomeHasVickyProactiveTable = false/>
<cfset VARIABLES.businessAdminHomeHasVickyDocumentTable = false/>
<cfset VARIABLES.businessAdminHomeFocoPendingTotal = 0/>
<cfset VARIABLES.businessAdminHomeAgregaPendingTotal = 0/>
<cfset VARIABLES.businessAdminHomeHelpdeskPendingTotal = 0/>
<cfset VARIABLES.businessAdminHomeHelpdeskReplyTotal = 0/>
<cfset VARIABLES.businessAdminHomeHelpdeskStaleTotal = 0/>
<cfset VARIABLES.businessAdminHomeEditorialPendingTotal = 0/>
<cfset VARIABLES.businessAdminHomeAdsReviewPendingTotal = 0/>
<cfset VARIABLES.businessAdminHomeChallengePendingTotal = 0/>
<cfset VARIABLES.businessAdminHomeResultImportFailureTotal = 0/>
<cfset VARIABLES.businessAdminHomeResultImportDelayedTotal = 0/>
<cfset VARIABLES.businessAdminHomeAthleteReviewPendingTotal = 0/>
<cfset VARIABLES.businessAdminHomeCrmPendingTotal = 0/>
<cfset VARIABLES.businessAdminHomeStravaPendingTotal = 0/>
<cfset VARIABLES.businessAdminHomeStravaReviewTotal = 0/>
<cfset VARIABLES.businessAdminHomeStravaErrorTotal = 0/>
<cfset VARIABLES.businessAdminHomeStravaStuckTotal = 0/>
<cfset VARIABLES.businessAdminHomePushPendingStuckTotal = 0/>
<cfset VARIABLES.businessAdminHomePushRetryStuckTotal = 0/>
<cfset VARIABLES.businessAdminHomePushProcessingStuckTotal = 0/>
<cfset VARIABLES.businessAdminHomeEmailPendingTotal = 0/>
<cfset VARIABLES.businessAdminHomeEmailErrorTotal = 0/>
<cfset VARIABLES.businessAdminHomeVickyDeliveryFailureTotal = 0/>
<cfset VARIABLES.businessAdminHomeVickyDocumentFailureTotal = 0/>
<cfset VARIABLES.businessAdminHomePortalErrors = 0/>
<cfset VARIABLES.businessAdminHomePortalNotFound = 0/>
<cfset VARIABLES.businessAdminHomePortalEventViews = 0/>
<cfset VARIABLES.businessAdminHomeSearchErrors = 0/>
<cfset VARIABLES.businessAdminHomeSearchZeroResults = 0/>
<cfset VARIABLES.businessAdminHomeContentIncomplete = 0/>
<cfset VARIABLES.businessAdminHomeContentCritical = 0/>
<cfset VARIABLES.businessAdminHomeContentNext30 = 0/>
<cfset VARIABLES.businessAdminHomeCronTotal = 0/>
<cfset VARIABLES.businessAdminHomeCronActive = 0/>
<cfset VARIABLES.businessAdminHomeCronDue = 0/>
<cfset VARIABLES.businessAdminHomeCronErrors = 0/>
<cfset VARIABLES.businessAdminHomeNotifications7d = 0/>
<cfset VARIABLES.businessAdminHomeNotificationsRead7d = 0/>
<cfset VARIABLES.businessAdminHomeNotificationReadRate7d = 0/>
<cfset VARIABLES.businessAdminHomeAdsPaymentsLoaded = false/>
<cfset VARIABLES.businessAdminHomeAdsPendingOld = 0/>
<cfset VARIABLES.businessAdminHomeAdsReview = 0/>
<cfset VARIABLES.businessAdminHomeAdsOpenHolds = 0/>
<cfset VARIABLES.businessAdminHomeAdsPaidWithoutLedger = 0/>
<cfset VARIABLES.businessAdminHomeAdsLedgerWithoutIntent = 0/>
<cfset VARIABLES.businessAdminHomeAdsReconcileLastDuration = 0/>
<cfset VARIABLES.businessAdminHomeAdsReconcileLastRunAt = ""/>
<cfset VARIABLES.businessAdminHomeAdsReconcileLastStatus = ""/>
<!--- Availability is separate from zero: a failed source must not look healthy. --->
<cfset VARIABLES.businessAdminHomeFocoLoaded = false/>
<cfset VARIABLES.businessAdminHomeAgregaLoaded = false/>
<cfset VARIABLES.businessAdminHomeHelpdeskLoaded = false/>
<cfset VARIABLES.businessAdminHomeEditorialLoaded = false/>
<cfset VARIABLES.businessAdminHomeAdsReviewLoaded = false/>
<cfset VARIABLES.businessAdminHomeChallengeLoaded = false/>
<cfset VARIABLES.businessAdminHomeResultImportLoaded = false/>
<cfset VARIABLES.businessAdminHomeAthleteReviewLoaded = false/>
<cfset VARIABLES.businessAdminHomeCrmPendingLoaded = false/>
<cfset VARIABLES.businessAdminHomeStravaMigrationLoaded = false/>
<cfset VARIABLES.businessAdminHomePushQueueLoaded = false/>
<cfset VARIABLES.businessAdminHomeEmailQueueLoaded = false/>
<cfset VARIABLES.businessAdminHomeVickyProactiveLoaded = false/>
<cfset VARIABLES.businessAdminHomeVickyDocumentLoaded = false/>
<cfset VARIABLES.businessAdminHomePortalLoaded = false/>
<cfset VARIABLES.businessAdminHomeSearchLoaded = false/>
<cfset VARIABLES.businessAdminHomeContentLoaded = false/>
<cfset VARIABLES.businessAdminHomeNotificationsLoaded = false/>
<cfset VARIABLES.businessAdminHomeContentTotal = 0/>

<cftry>
    <cfquery name="qBusinessAdminHomeTableCheck">
        SELECT table_name
        FROM information_schema.tables
        WHERE (
          table_schema = 'public'
          AND table_name IN (
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_contas"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_conta_usuarios"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_conta_eventos"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_conta_cadastro_solicitacoes"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_conta_evento_solicitacoes"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_evento_corridas"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_usuarios"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_log"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_busca_log"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_foco_event_match_state"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_foco_event_match_candidates"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_evento_foco_vinculos"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_evento_agrega_review_groups"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_evento_agrega_review_candidates"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_cron_jobs"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_cron_job_runs"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_notifica"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_helpdesk_chamados"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="desafios"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_resultados_importacoes"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_atleta_verificacao_solicitacao"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_percurso_migracoes_strava"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_push_delivery_queue"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_mailing"/>
          )) OR (
              table_schema = 'ads'
              AND table_name IN (
                  <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_ad_eventos"/>,
                  <cfqueryparam cfsqltype="cf_sql_varchar" value="campaign_review_requests"/>
              )
          ) OR (
              table_schema = 'news'
              AND table_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_content"/>
          ) OR (
              table_schema = 'crm'
              AND table_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_crm_participacoes"/>
          )
    </cfquery>

    <cfset VARIABLES.businessAdminHomeTableNames = ValueList(qBusinessAdminHomeTableCheck.table_name)/>
    <cfset VARIABLES.businessAdminHomeTablesReady = ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_contas")
        AND ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_conta_usuarios")
        AND ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_conta_eventos")
        AND ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_conta_cadastro_solicitacoes")
        AND ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_conta_evento_solicitacoes")
        AND ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_ad_eventos")
        AND ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_evento_corridas")
        AND ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_usuarios")/>
    <cfset VARIABLES.businessAdminHomeHasLogTable = ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_log")/>
    <cfset VARIABLES.businessAdminHomeHasSearchTable = ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_busca_log")/>
    <cfset VARIABLES.businessAdminHomeHasFocoTables = ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_foco_event_match_state")
        AND ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_foco_event_match_candidates")
        AND ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_evento_foco_vinculos")/>
    <cfset VARIABLES.businessAdminHomeHasAgregaTables = ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_evento_agrega_review_groups")/>
    <cfset VARIABLES.businessAdminHomeHasCronTables = ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_cron_jobs")
        AND ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_cron_job_runs")/>
    <cfset VARIABLES.businessAdminHomeHasNotificationTable = ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_notifica")/>
    <cfset VARIABLES.businessAdminHomeHasHelpdeskTable = ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_helpdesk_chamados")/>
    <cfset VARIABLES.businessAdminHomeHasEditorialTable = ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_content")/>
    <cfset VARIABLES.businessAdminHomeHasAdsReviewTable = ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "campaign_review_requests")/>
    <cfset VARIABLES.businessAdminHomeHasChallengeTable = ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "desafios")/>
    <cfset VARIABLES.businessAdminHomeHasResultImportTable = ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_resultados_importacoes")/>
    <cfset VARIABLES.businessAdminHomeHasAthleteReviewTable = ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_atleta_verificacao_solicitacao")/>
    <cfset VARIABLES.businessAdminHomeHasCrmPendingTable = ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_crm_participacoes")/>
    <cfset VARIABLES.businessAdminHomeHasStravaMigrationTable = ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_percurso_migracoes_strava")/>
    <cfset VARIABLES.businessAdminHomeHasPushQueueTable = ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_push_delivery_queue")/>
    <cfset VARIABLES.businessAdminHomeHasEmailQueueTable = ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_mailing")/>

    <cfif NOT VARIABLES.businessAdminHomeTablesReady>
        <cfset VARIABLES.businessAdminHomeReady = false/>
        <cfset VARIABLES.businessAdminHomeError = "Estrutura de contas Business incompleta no banco."/>
    </cfif>

    <cfcatch type="any">
        <cfset VARIABLES.businessAdminHomeReady = false/>
        <cfset VARIABLES.businessAdminHomeTablesReady = false/>
        <cfset VARIABLES.businessAdminHomeError = cfcatch.message/>
    </cfcatch>
</cftry>

<!--- Vicky uses the privileged datasource; include its queues only when that module is installed. --->
<cftry>
    <cfquery name="qBusinessAdminHomeVickyTableCheck" datasource="runner_dba">
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name IN (
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_vicky_notificacao_fila"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_vicky_documento"/>
          )
    </cfquery>
    <cfset VARIABLES.businessAdminHomeVickyTableNames = ValueList(qBusinessAdminHomeVickyTableCheck.table_name)/>
    <cfset VARIABLES.businessAdminHomeHasVickyProactiveTable = ListFindNoCase(VARIABLES.businessAdminHomeVickyTableNames, "tb_vicky_notificacao_fila")/>
    <cfset VARIABLES.businessAdminHomeHasVickyDocumentTable = ListFindNoCase(VARIABLES.businessAdminHomeVickyTableNames, "tb_vicky_documento")/>
    <cfcatch type="any">
        <cfset VARIABLES.businessAdminHomeHasVickyProactiveTable = false/>
        <cfset VARIABLES.businessAdminHomeHasVickyDocumentTable = false/>
    </cfcatch>
</cftry>

<cfif VARIABLES.businessAdminHomeTablesReady>
    <cftry>
    <cfquery name="qBusinessAdminHomeStats" datasource="runnerhub">
        SELECT
            (SELECT count(*)::integer FROM tb_contas WHERE status::text = 'ATIVA') AS contas_ativas,
            (SELECT count(*)::integer FROM tb_contas WHERE status::text = 'PENDENTE') AS contas_pendentes,
            (SELECT count(*)::integer FROM tb_conta_usuarios WHERE status::text = 'ATIVO') AS usuarios_ativos,
            (SELECT count(*)::integer FROM tb_conta_eventos WHERE status::text = 'ATIVO') AS eventos_ativos,
            (SELECT count(*)::integer FROM tb_conta_cadastro_solicitacoes WHERE status::text = 'PENDENTE') AS solicitacoes_cadastro,
            (SELECT count(*)::integer FROM tb_conta_evento_solicitacoes WHERE status::text = 'PENDENTE') AS solicitacoes_eventos,
            (
                SELECT count(*)::integer
                FROM ads.tb_ad_eventos
                WHERE status = 1
                  AND (inicio_ad IS NULL OR inicio_ad <= now())
                  AND (final_ad IS NULL OR final_ad >= now())
            ) AS campanhas_ativas
    </cfquery>

    <cfquery name="qBusinessAdminHomeRegistrations">
        SELECT id_solicitacao,
               nome_empresa,
               tipo_prestador,
               email_responsavel,
               data_criacao
        FROM tb_conta_cadastro_solicitacoes
        WHERE status::text = 'PENDENTE'
        ORDER BY data_criacao DESC
        LIMIT 5
    </cfquery>

    <cfquery name="qBusinessAdminHomeEventRequests">
        SELECT sol.id_solicitacao,
               cont.nome_conta,
               evt.nome_evento,
               sol.data_criacao
        FROM tb_conta_evento_solicitacoes sol
        INNER JOIN tb_contas cont ON cont.id_conta = sol.id_conta
        INNER JOIN tb_evento_corridas evt ON evt.id_evento = sol.id_evento
        WHERE sol.status::text = 'PENDENTE'
        ORDER BY sol.data_criacao DESC
        LIMIT 5
    </cfquery>

    <cfquery name="qBusinessAdminHomeLegacyPartners">
        SELECT id,
               name,
               email,
               partner_info ->> 'perfil' AS perfil,
               partner_info ->> 'nome_comercial' AS nome_comercial
        FROM tb_usuarios
        WHERE partner_info IS NOT NULL
        ORDER BY id DESC
        LIMIT 5
    </cfquery>

    <cfcatch type="any">
        <cfset VARIABLES.businessAdminHomeReady = false/>
        <cfset VARIABLES.businessAdminHomeError = cfcatch.message/>
        <cfset qBusinessAdminHomeStats = QueryNew("contas_ativas,contas_pendentes,usuarios_ativos,eventos_ativos,solicitacoes_cadastro,solicitacoes_eventos,campanhas_ativas")/>
        <cfset qBusinessAdminHomeRegistrations = QueryNew("id_solicitacao,nome_empresa,tipo_prestador,email_responsavel,data_criacao")/>
        <cfset qBusinessAdminHomeEventRequests = QueryNew("id_solicitacao,nome_conta,nome_evento,data_criacao")/>
        <cfset qBusinessAdminHomeLegacyPartners = QueryNew("id,name,email,perfil,nome_comercial")/>
        <cfset qBusinessAdminHomeContentGaps = QueryNew("id_evento,nome_evento,cidade,estado,tag,data_inicial,missing_count,faltando")/>
    </cfcatch>
</cftry>
</cfif>

<cfif VARIABLES.businessAdminHomeReady>
    <cfif VARIABLES.businessAdminHomeHasFocoTables>
        <cftry>
            <cfquery name="qBusinessAdminHomeFocoPending">
                SELECT count(*)::integer AS total
                FROM tb_foco_event_match_state state
                WHERE state.status IN ('review', 'linked')
                  AND EXISTS (
                      SELECT 1
                      FROM tb_foco_event_match_candidates pending_candidate
                      WHERE pending_candidate.id_evento = state.id_evento
                        AND pending_candidate.status = 'active'
                        AND pending_candidate.exact_place = true
                        AND pending_candidate.score >= 60
                        AND NOT EXISTS (
                            SELECT 1
                            FROM tb_evento_foco_vinculos pending_link
                            WHERE pending_link.status = 'active'
                              AND pending_link.competition_id = pending_candidate.competition_id
                        )
                  )
            </cfquery>
            <cfset VARIABLES.businessAdminHomeFocoPendingTotal = val(qBusinessAdminHomeFocoPending.total)/>
            <cfset VARIABLES.businessAdminHomeFocoLoaded = true/>
            <cfcatch type="any">
                <cfset VARIABLES.businessAdminHomeFocoPendingTotal = 0/>
            </cfcatch>
        </cftry>
    </cfif>

    <cfif VARIABLES.businessAdminHomeHasAgregaTables>
        <cftry>
            <cfquery name="qBusinessAdminHomeAgregaPending">
                SELECT count(*)::integer AS total
                FROM tb_evento_agrega_review_groups
                WHERE status = 'review'
            </cfquery>
            <cfset VARIABLES.businessAdminHomeAgregaPendingTotal = val(qBusinessAdminHomeAgregaPending.total)/>
            <cfset VARIABLES.businessAdminHomeAgregaLoaded = true/>
            <cfcatch type="any">
                <cfset VARIABLES.businessAdminHomeAgregaPendingTotal = 0/>
            </cfcatch>
        </cftry>
    </cfif>

    <cfif VARIABLES.businessAdminHomeHasHelpdeskTable>
        <cftry>
            <cfquery name="qBusinessAdminHomeHelpdeskPending">
                SELECT
                    (count(*) FILTER (WHERE status IN ('aberto', 'cliente_respondeu')))::integer AS a_responder,
                    (count(*) FILTER (
                        WHERE status NOT IN ('resolvido', 'fechado')
                          AND updated_at < now() - interval '48 hours'
                    ))::integer AS sem_atualizacao,
                    (count(*) FILTER (
                        WHERE status IN ('aberto', 'cliente_respondeu')
                           OR (
                               status NOT IN ('resolvido', 'fechado')
                               AND updated_at < now() - interval '48 hours'
                           )
                    ))::integer AS pendentes
                FROM public.tb_helpdesk_chamados
            </cfquery>
            <cfset VARIABLES.businessAdminHomeHelpdeskPendingTotal = val(qBusinessAdminHomeHelpdeskPending.pendentes)/>
            <cfset VARIABLES.businessAdminHomeHelpdeskReplyTotal = val(qBusinessAdminHomeHelpdeskPending.a_responder)/>
            <cfset VARIABLES.businessAdminHomeHelpdeskStaleTotal = val(qBusinessAdminHomeHelpdeskPending.sem_atualizacao)/>
            <cfset VARIABLES.businessAdminHomeHelpdeskLoaded = true/>
            <cfcatch type="any">
                <cfset VARIABLES.businessAdminHomeHelpdeskPendingTotal = 0/>
                <cfset VARIABLES.businessAdminHomeHelpdeskReplyTotal = 0/>
                <cfset VARIABLES.businessAdminHomeHelpdeskStaleTotal = 0/>
            </cfcatch>
        </cftry>
    </cfif>

    <cfif VARIABLES.businessAdminHomeHasEditorialTable>
        <cftry>
            <cfquery name="qBusinessAdminHomeEditorialPending">
                SELECT count(*)::integer AS total
                FROM news.tb_content
                WHERE published = false
                  AND lower(coalesce(editorial_status, '')) = 'review'
            </cfquery>
            <cfset VARIABLES.businessAdminHomeEditorialPendingTotal = val(qBusinessAdminHomeEditorialPending.total)/>
            <cfset VARIABLES.businessAdminHomeEditorialLoaded = true/>
            <cfcatch type="any">
                <cfset VARIABLES.businessAdminHomeEditorialPendingTotal = 0/>
            </cfcatch>
        </cftry>
    </cfif>

    <cfif VARIABLES.businessAdminHomeHasAdsReviewTable>
        <cftry>
            <cfquery name="qBusinessAdminHomeAdsReviewPending" datasource="runnerhub">
                SELECT count(*)::integer AS total
                FROM ads.campaign_review_requests
                WHERE status = 'PENDING_REVIEW'
            </cfquery>
            <cfset VARIABLES.businessAdminHomeAdsReviewPendingTotal = val(qBusinessAdminHomeAdsReviewPending.total)/>
            <cfset VARIABLES.businessAdminHomeAdsReviewLoaded = true/>
            <cfcatch type="any">
                <cfset VARIABLES.businessAdminHomeAdsReviewPendingTotal = 0/>
            </cfcatch>
        </cftry>
    </cfif>

    <cfif VARIABLES.businessAdminHomeHasChallengeTable>
        <cftry>
            <cfquery name="qBusinessAdminHomeChallengePending">
                SELECT count(*)::integer AS total
                FROM public.desafios challenge
                CROSS JOIN LATERAL jsonb_array_elements(
                    CASE
                        WHEN jsonb_typeof(challenge.body -> 'validacoes_documentais') = 'array'
                            THEN challenge.body -> 'validacoes_documentais'
                        ELSE '[]'::jsonb
                    END
                ) AS validation
                WHERE challenge.produto = 'circuitobrasilgigante'
                  AND coalesce(nullif(lower(trim(validation ->> 'status_analise')), ''), 'pendente') = 'pendente'
            </cfquery>
            <cfset VARIABLES.businessAdminHomeChallengePendingTotal = val(qBusinessAdminHomeChallengePending.total)/>
            <cfset VARIABLES.businessAdminHomeChallengeLoaded = true/>
            <cfcatch type="any">
                <cfset VARIABLES.businessAdminHomeChallengePendingTotal = 0/>
            </cfcatch>
        </cftry>
    </cfif>

    <cfif VARIABLES.businessAdminHomeHasResultImportTable>
        <cftry>
            <cfquery name="qBusinessAdminHomeResultImportPending">
                WITH source_rows AS (
                    SELECT imp.*,
                           nullif(regexp_replace(trim(imp.url_resultado), '[/##]+$', ''), '') AS data_url_key,
                           nullif(regexp_replace(trim(imp.url_resultado_publica), '[/##]+$', ''), '') AS public_url_key
                    FROM public.tb_resultados_importacoes imp
                ), identified AS (
                    SELECT source_rows.*,
                           md5(jsonb_build_array(
                               lower(trim(client_id)),
                               lower(trim(cod_timer)),
                               nullif(trim(external_account_id), ''),
                               CASE
                                   WHEN data_url_key ~ '^https://[^/]+/.*/data/[^/]+/event\.json$'
                                       OR data_url_key ~ '^https://[^/]+/data/[^/]+/event\.json$'
                                       THEN 'data:' || data_url_key
                                   WHEN public_url_key ~ '^https://[^/]+/.*[^/##]$'
                                       THEN 'public:' || public_url_key
                                   WHEN nullif(trim(external_event_id), '') IS NOT NULL
                                       THEN 'external:' || trim(external_event_id)
                                   ELSE 'submission:' || public_id::text
                               END
                           )::text) AS event_group
                    FROM source_rows
                ), latest_active AS (
                    SELECT DISTINCT ON (event_group)
                           status_processamento,
                           data_recebimento
                    FROM identified
                    WHERE status_processamento <> 'cancelado'
                    ORDER BY event_group, data_recebimento DESC, id_resultado_importacao DESC
                )
                SELECT
                    (count(*) FILTER (WHERE status_processamento = 'falhou'))::integer AS falhas,
                    (count(*) FILTER (
                        WHERE status_processamento = 'pendente'
                          AND data_recebimento < now() - interval '15 minutes'
                    ))::integer AS atrasadas
                FROM latest_active
            </cfquery>
            <cfset VARIABLES.businessAdminHomeResultImportFailureTotal = val(qBusinessAdminHomeResultImportPending.falhas)/>
            <cfset VARIABLES.businessAdminHomeResultImportDelayedTotal = val(qBusinessAdminHomeResultImportPending.atrasadas)/>
            <cfset VARIABLES.businessAdminHomeResultImportLoaded = true/>
            <cfcatch type="any">
                <cfset VARIABLES.businessAdminHomeResultImportFailureTotal = 0/>
                <cfset VARIABLES.businessAdminHomeResultImportDelayedTotal = 0/>
            </cfcatch>
        </cftry>
    </cfif>

    <cfif VARIABLES.businessAdminHomeHasCrmPendingTable>
        <cftry>
            <cfquery name="qBusinessAdminHomeCrmPending">
                SELECT count(*)::integer AS total
                FROM (
                    SELECT DISTINCT fonte, cod_evento_externo
                    FROM crm.tb_crm_participacoes
                    WHERE id_evento IS NULL
                      AND cod_evento_externo IS NOT NULL
                      AND trim(cod_evento_externo) <> ''
                ) pending_sources
            </cfquery>
            <cfset VARIABLES.businessAdminHomeCrmPendingTotal = val(qBusinessAdminHomeCrmPending.total)/>
            <cfset VARIABLES.businessAdminHomeCrmPendingLoaded = true/>
            <cfcatch type="any">
                <cfset VARIABLES.businessAdminHomeCrmPendingTotal = 0/>
            </cfcatch>
        </cftry>
    </cfif>

    <cfif VARIABLES.businessAdminHomeHasStravaMigrationTable>
        <cftry>
            <cfquery name="qBusinessAdminHomeStravaMigrationPending">
                SELECT
                    (count(*) FILTER (WHERE status = 'pendente'))::integer AS pendentes,
                    (count(*) FILTER (WHERE status = 'revisao'))::integer AS revisao,
                    (count(*) FILTER (WHERE status = 'erro'))::integer AS erros,
                    (count(*) FILTER (
                        WHERE status = 'processando'
                          AND data_atualizacao < now() - interval '15 minutes'
                    ))::integer AS travados
                FROM public.tb_percurso_migracoes_strava
            </cfquery>
            <cfset VARIABLES.businessAdminHomeStravaPendingTotal = val(qBusinessAdminHomeStravaMigrationPending.pendentes)/>
            <cfset VARIABLES.businessAdminHomeStravaReviewTotal = val(qBusinessAdminHomeStravaMigrationPending.revisao)/>
            <cfset VARIABLES.businessAdminHomeStravaErrorTotal = val(qBusinessAdminHomeStravaMigrationPending.erros)/>
            <cfset VARIABLES.businessAdminHomeStravaStuckTotal = val(qBusinessAdminHomeStravaMigrationPending.travados)/>
            <cfset VARIABLES.businessAdminHomeStravaMigrationLoaded = true/>
            <cfcatch type="any">
                <cfset VARIABLES.businessAdminHomeStravaPendingTotal = 0/>
                <cfset VARIABLES.businessAdminHomeStravaReviewTotal = 0/>
                <cfset VARIABLES.businessAdminHomeStravaErrorTotal = 0/>
                <cfset VARIABLES.businessAdminHomeStravaStuckTotal = 0/>
            </cfcatch>
        </cftry>
    </cfif>

    <cfif VARIABLES.businessAdminHomeHasPushQueueTable>
        <cftry>
            <cfquery name="qBusinessAdminHomePushQueuePending">
                SELECT
                    (count(*) FILTER (
                        WHERE status = 'pending'
                          AND updated_at < now() - interval '15 minutes'
                    ))::integer AS pendentes,
                    (count(*) FILTER (
                        WHERE status = 'retry'
                          AND updated_at < now() - interval '15 minutes'
                    ))::integer AS retentativas,
                    (count(*) FILTER (
                        WHERE status = 'processing'
                          AND updated_at < now() - interval '15 minutes'
                    ))::integer AS processando
                FROM public.tb_push_delivery_queue
            </cfquery>
            <cfset VARIABLES.businessAdminHomePushPendingStuckTotal = val(qBusinessAdminHomePushQueuePending.pendentes)/>
            <cfset VARIABLES.businessAdminHomePushRetryStuckTotal = val(qBusinessAdminHomePushQueuePending.retentativas)/>
            <cfset VARIABLES.businessAdminHomePushProcessingStuckTotal = val(qBusinessAdminHomePushQueuePending.processando)/>
            <cfset VARIABLES.businessAdminHomePushQueueLoaded = true/>
            <cfcatch type="any">
                <cfset VARIABLES.businessAdminHomePushPendingStuckTotal = 0/>
                <cfset VARIABLES.businessAdminHomePushRetryStuckTotal = 0/>
                <cfset VARIABLES.businessAdminHomePushProcessingStuckTotal = 0/>
            </cfcatch>
        </cftry>
    </cfif>

    <cfif VARIABLES.businessAdminHomeHasEmailQueueTable>
        <cftry>
            <cfquery name="qBusinessAdminHomeEmailQueuePending">
                SELECT
                    (count(*) FILTER (
                        WHERE data_envio IS NULL
                          AND bounce IS NULL
                          AND data_disparo < now()
                    ))::integer AS atrasados,
                    (count(*) FILTER (
                        WHERE data_envio IS NULL
                          AND bounce IS NOT NULL
                    ))::integer AS erros
                FROM public.tb_mailing
            </cfquery>
            <cfset VARIABLES.businessAdminHomeEmailPendingTotal = val(qBusinessAdminHomeEmailQueuePending.atrasados)/>
            <cfset VARIABLES.businessAdminHomeEmailErrorTotal = val(qBusinessAdminHomeEmailQueuePending.erros)/>
            <cfset VARIABLES.businessAdminHomeEmailQueueLoaded = true/>
            <cfcatch type="any">
                <cfset VARIABLES.businessAdminHomeEmailPendingTotal = 0/>
                <cfset VARIABLES.businessAdminHomeEmailErrorTotal = 0/>
            </cfcatch>
        </cftry>
    </cfif>

    <cfif VARIABLES.businessAdminHomeHasVickyProactiveTable>
        <cftry>
            <cfquery name="qBusinessAdminHomeVickyDeliveryPending" datasource="runner_dba">
                SELECT (count(*) FILTER (
                    WHERE status IN ('failed', 'dead_letter')
                      AND created_at >= now() - interval '30 days'
                ))::integer AS falhas
                FROM public.tb_vicky_notificacao_fila
            </cfquery>
            <cfset VARIABLES.businessAdminHomeVickyDeliveryFailureTotal = val(qBusinessAdminHomeVickyDeliveryPending.falhas)/>
            <cfset VARIABLES.businessAdminHomeVickyProactiveLoaded = true/>
            <cfcatch type="any">
                <cfset VARIABLES.businessAdminHomeVickyDeliveryFailureTotal = 0/>
            </cfcatch>
        </cftry>
    </cfif>

    <cfif VARIABLES.businessAdminHomeHasVickyDocumentTable>
        <cftry>
            <cfquery name="qBusinessAdminHomeVickyDocumentPending" datasource="runner_dba">
                SELECT (count(*) FILTER (WHERE status = 'failed'))::integer AS falhas
                FROM public.tb_vicky_documento
            </cfquery>
            <cfset VARIABLES.businessAdminHomeVickyDocumentFailureTotal = val(qBusinessAdminHomeVickyDocumentPending.falhas)/>
            <cfset VARIABLES.businessAdminHomeVickyDocumentLoaded = true/>
            <cfcatch type="any">
                <cfset VARIABLES.businessAdminHomeVickyDocumentFailureTotal = 0/>
            </cfcatch>
        </cftry>
    </cfif>

    <!--- This queue is optional until the verified-athlete request workflow is installed. --->
    <cfif VARIABLES.businessAdminHomeHasAthleteReviewTable>
        <cftry>
            <cfquery name="qBusinessAdminHomeAthleteReviewPending">
                SELECT count(*)::integer AS total
                FROM public.tb_atleta_verificacao_solicitacao
                WHERE status = 'pendente'
            </cfquery>
            <cfset VARIABLES.businessAdminHomeAthleteReviewPendingTotal = val(qBusinessAdminHomeAthleteReviewPending.total)/>
            <cfset VARIABLES.businessAdminHomeAthleteReviewLoaded = true/>
            <cfcatch type="any">
                <cfset VARIABLES.businessAdminHomeAthleteReviewPendingTotal = 0/>
            </cfcatch>
        </cftry>
    </cfif>

    <cfif VARIABLES.businessAdminHomeHasLogTable>
        <cftry>
            <cfquery name="qBusinessAdminHomePortalHealth">
                SELECT
                    (count(*) FILTER (WHERE log_item = 'erro'))::integer AS erros,
                    (count(*) FILTER (WHERE log_item = '404'))::integer AS not_found,
                    (count(*) FILTER (WHERE log_item = 'evento'))::integer AS event_views
                FROM tb_log
                WHERE log_timestamp >= now() - interval '7 days'
                  AND log_item IN ('erro', '404', 'evento')
            </cfquery>
            <cfset VARIABLES.businessAdminHomePortalErrors = val(qBusinessAdminHomePortalHealth.erros)/>
            <cfset VARIABLES.businessAdminHomePortalNotFound = val(qBusinessAdminHomePortalHealth.not_found)/>
            <cfset VARIABLES.businessAdminHomePortalEventViews = val(qBusinessAdminHomePortalHealth.event_views)/>
            <cfset VARIABLES.businessAdminHomePortalLoaded = true/>
            <cfcatch type="any">
                <cfset VARIABLES.businessAdminHomePortalErrors = 0/>
                <cfset VARIABLES.businessAdminHomePortalNotFound = 0/>
                <cfset VARIABLES.businessAdminHomePortalEventViews = 0/>
            </cfcatch>
        </cftry>
    </cfif>

    <cfif VARIABLES.businessAdminHomeHasSearchTable>
        <cftry>
            <cfquery name="qBusinessAdminHomeSearchHealth">
                WITH execucoes AS (
                    SELECT
                        id_busca_log_parent,
                        sum(coalesce((contagens_json->>'eventos')::numeric, 0)
                            + coalesce((contagens_json->>'resultados')::numeric, 0)
                            + coalesce((contagens_json->>'atletas')::numeric, 0)
                            + coalesce((contagens_json->>'noticias')::numeric, 0)
                            + coalesce((contagens_json->>'videos')::numeric, 0))::integer AS total_resultados
                    FROM tb_busca_log
                    WHERE etapa = 'execucao'
                      AND log_timestamp >= now() - interval '30 days'
                    GROUP BY id_busca_log_parent
                )
                SELECT
                    (count(*) FILTER (WHERE p.etapa = 'interpretacao' AND p.erro IS NOT NULL AND length(trim(p.erro)) > 0))::integer AS erros,
                    (count(*) FILTER (WHERE p.etapa = 'interpretacao' AND coalesce(e.total_resultados, -1) = 0))::integer AS sem_resultado
                FROM tb_busca_log p
                LEFT JOIN execucoes e ON e.id_busca_log_parent = p.id_busca_log
                WHERE p.log_timestamp >= now() - interval '30 days'
            </cfquery>
            <cfset VARIABLES.businessAdminHomeSearchErrors = val(qBusinessAdminHomeSearchHealth.erros)/>
            <cfset VARIABLES.businessAdminHomeSearchZeroResults = val(qBusinessAdminHomeSearchHealth.sem_resultado)/>
            <cfset VARIABLES.businessAdminHomeSearchLoaded = true/>
            <cfcatch type="any">
                <cfset VARIABLES.businessAdminHomeSearchErrors = 0/>
                <cfset VARIABLES.businessAdminHomeSearchZeroResults = 0/>
            </cfcatch>
        </cftry>
    </cfif>

    <cftry>
        <cfquery name="qBusinessAdminHomeContentStats">
            WITH scored AS (
                SELECT
                    evt.id_evento,
                    evt.nome_evento,
                    coalesce(evt.cidade, '') AS cidade,
                    coalesce(evt.estado, '') AS estado,
                    coalesce(evt.tag, '') AS tag,
                    evt.data_inicial,
                    (
                        CASE WHEN length(trim(coalesce(evt.descricao, ''))) > 0 THEN 0 ELSE 1 END
                        + CASE WHEN length(trim(coalesce(evt.url_inscricao, ''))) > 0 THEN 0 ELSE 1 END
                        + CASE WHEN length(trim(coalesce(evt.categorias, ''))) > 0 THEN 0 ELSE 1 END
                        + CASE WHEN length(trim(coalesce(evt.organizador, ''))) > 0 THEN 0 ELSE 1 END
                        + CASE WHEN length(trim(coalesce(evt.cidade, ''))) > 0 AND length(trim(coalesce(evt.estado, ''))) > 0 THEN 0 ELSE 1 END
                        + CASE WHEN length(trim(coalesce(evt.endereco, ''))) > 0 THEN 0 ELSE 1 END
                        + CASE
                            WHEN length(trim(coalesce(evt.imagem, ''))) > 0 THEN 0
                            WHEN length(trim(coalesce(evt.url_imagem, ''))) > 0 THEN 0
                            WHEN length(trim(coalesce(evt.url_imagem_listagem, ''))) > 0 THEN 0
                            ELSE 1
                        END
                    )::integer AS missing_count,
                    concat_ws(', ',
                        CASE WHEN length(trim(coalesce(evt.descricao, ''))) = 0 THEN 'Descricao' END,
                        CASE WHEN length(trim(coalesce(evt.url_inscricao, ''))) = 0 THEN 'Inscricao' END,
                        CASE WHEN length(trim(coalesce(evt.categorias, ''))) = 0 THEN 'Categorias' END,
                        CASE WHEN length(trim(coalesce(evt.organizador, ''))) = 0 THEN 'Organizador' END,
                        CASE WHEN length(trim(coalesce(evt.cidade, ''))) = 0 OR length(trim(coalesce(evt.estado, ''))) = 0 THEN 'Local' END,
                        CASE WHEN length(trim(coalesce(evt.endereco, ''))) = 0 THEN 'Endereco' END,
                        CASE
                            WHEN length(trim(coalesce(evt.imagem, ''))) = 0
                             AND length(trim(coalesce(evt.url_imagem, ''))) = 0
                             AND length(trim(coalesce(evt.url_imagem_listagem, ''))) = 0 THEN 'Imagem'
                        END
                    ) AS faltando
                FROM tb_evento_corridas evt
                WHERE evt.ativo = true
                  AND evt.data_final >= current_date
                  AND evt.data_inicial <= current_date + interval '90 days'
            )
            SELECT
                count(*)::integer AS total,
                count(*) FILTER (WHERE missing_count > 0)::integer AS incompletos,
                count(*) FILTER (WHERE missing_count >= 3)::integer AS criticos,
                count(*) FILTER (WHERE missing_count > 0 AND data_inicial <= current_date + interval '30 days')::integer AS proximos30
            FROM scored
        </cfquery>
        <cfset VARIABLES.businessAdminHomeContentIncomplete = val(qBusinessAdminHomeContentStats.incompletos)/>
        <cfset VARIABLES.businessAdminHomeContentCritical = val(qBusinessAdminHomeContentStats.criticos)/>
        <cfset VARIABLES.businessAdminHomeContentNext30 = val(qBusinessAdminHomeContentStats.proximos30)/>
        <cfset VARIABLES.businessAdminHomeContentTotal = val(qBusinessAdminHomeContentStats.total)/>

        <cfquery name="qBusinessAdminHomeContentGaps">
            WITH scored AS (
                SELECT
                    evt.id_evento,
                    evt.nome_evento,
                    coalesce(evt.cidade, '') AS cidade,
                    coalesce(evt.estado, '') AS estado,
                    coalesce(evt.tag, '') AS tag,
                    evt.data_inicial,
                    (
                        CASE WHEN length(trim(coalesce(evt.descricao, ''))) > 0 THEN 0 ELSE 1 END
                        + CASE WHEN length(trim(coalesce(evt.url_inscricao, ''))) > 0 THEN 0 ELSE 1 END
                        + CASE WHEN length(trim(coalesce(evt.categorias, ''))) > 0 THEN 0 ELSE 1 END
                        + CASE WHEN length(trim(coalesce(evt.organizador, ''))) > 0 THEN 0 ELSE 1 END
                        + CASE WHEN length(trim(coalesce(evt.cidade, ''))) > 0 AND length(trim(coalesce(evt.estado, ''))) > 0 THEN 0 ELSE 1 END
                        + CASE WHEN length(trim(coalesce(evt.endereco, ''))) > 0 THEN 0 ELSE 1 END
                        + CASE
                            WHEN length(trim(coalesce(evt.imagem, ''))) > 0 THEN 0
                            WHEN length(trim(coalesce(evt.url_imagem, ''))) > 0 THEN 0
                            WHEN length(trim(coalesce(evt.url_imagem_listagem, ''))) > 0 THEN 0
                            ELSE 1
                        END
                    )::integer AS missing_count,
                    concat_ws(', ',
                        CASE WHEN length(trim(coalesce(evt.descricao, ''))) = 0 THEN 'Descricao' END,
                        CASE WHEN length(trim(coalesce(evt.url_inscricao, ''))) = 0 THEN 'Inscricao' END,
                        CASE WHEN length(trim(coalesce(evt.categorias, ''))) = 0 THEN 'Categorias' END,
                        CASE WHEN length(trim(coalesce(evt.organizador, ''))) = 0 THEN 'Organizador' END,
                        CASE WHEN length(trim(coalesce(evt.cidade, ''))) = 0 OR length(trim(coalesce(evt.estado, ''))) = 0 THEN 'Local' END,
                        CASE WHEN length(trim(coalesce(evt.endereco, ''))) = 0 THEN 'Endereco' END,
                        CASE
                            WHEN length(trim(coalesce(evt.imagem, ''))) = 0
                             AND length(trim(coalesce(evt.url_imagem, ''))) = 0
                             AND length(trim(coalesce(evt.url_imagem_listagem, ''))) = 0 THEN 'Imagem'
                        END
                    ) AS faltando
                FROM tb_evento_corridas evt
                WHERE evt.ativo = true
                  AND evt.data_final >= current_date
                  AND evt.data_inicial <= current_date + interval '90 days'
            )
            SELECT *
            FROM scored
            WHERE missing_count > 0
            ORDER BY data_inicial ASC, missing_count DESC, nome_evento
            LIMIT 5
        </cfquery>
        <cfset VARIABLES.businessAdminHomeContentLoaded = true/>
        <cfcatch type="any">
            <cfset VARIABLES.businessAdminHomeContentIncomplete = 0/>
            <cfset VARIABLES.businessAdminHomeContentCritical = 0/>
            <cfset VARIABLES.businessAdminHomeContentNext30 = 0/>
            <cfset qBusinessAdminHomeContentGaps = QueryNew("id_evento,nome_evento,cidade,estado,tag,data_inicial,missing_count,faltando")/>
        </cfcatch>
    </cftry>

    <cfif VARIABLES.businessAdminHomeHasCronTables>
        <cftry>
            <cfquery name="qBusinessAdminHomeCronStats">
                SELECT
                    count(*)::integer AS total_jobs,
                    (count(*) FILTER (WHERE ativo = true))::integer AS ativos,
                    (count(*) FILTER (WHERE ativo = true AND next_run_at <= now()))::integer AS vencidos,
                    (count(*) FILTER (WHERE lower(trim(coalesce(last_status, ''))) IN ('error', 'http_error', 'failed', 'timeout')))::integer AS erros
                FROM tb_cron_jobs
            </cfquery>
            <cfset VARIABLES.businessAdminHomeCronTotal = val(qBusinessAdminHomeCronStats.total_jobs)/>
            <cfset VARIABLES.businessAdminHomeCronActive = val(qBusinessAdminHomeCronStats.ativos)/>
            <cfset VARIABLES.businessAdminHomeCronDue = val(qBusinessAdminHomeCronStats.vencidos)/>
            <cfset VARIABLES.businessAdminHomeCronErrors = val(qBusinessAdminHomeCronStats.erros)/>
            <cfset VARIABLES.businessAdminHomeCronLoaded = true/>
            <cfcatch type="any">
                <cfset VARIABLES.businessAdminHomeCronLoaded = false/>
                <cfset VARIABLES.businessAdminHomeCronTotal = 0/>
                <cfset VARIABLES.businessAdminHomeCronActive = 0/>
                <cfset VARIABLES.businessAdminHomeCronDue = 0/>
                <cfset VARIABLES.businessAdminHomeCronErrors = 0/>
            </cfcatch>
        </cftry>
    </cfif>

    <cfif VARIABLES.businessAdminHomeHasNotificationTable>
        <cftry>
            <cfquery name="qBusinessAdminHomeNotificationStats">
                SELECT
                    count(*)::integer AS total,
                    (count(*) FILTER (WHERE data_leitura IS NOT NULL))::integer AS lidas
                FROM tb_notifica
                WHERE data_publicacao >= now() - interval '7 days'
            </cfquery>
            <cfset VARIABLES.businessAdminHomeNotifications7d = val(qBusinessAdminHomeNotificationStats.total)/>
            <cfset VARIABLES.businessAdminHomeNotificationsRead7d = val(qBusinessAdminHomeNotificationStats.lidas)/>
            <cfset VARIABLES.businessAdminHomeNotificationsLoaded = true/>
            <cfif VARIABLES.businessAdminHomeNotifications7d GT 0>
                <cfset VARIABLES.businessAdminHomeNotificationReadRate7d = (VARIABLES.businessAdminHomeNotificationsRead7d * 100) / VARIABLES.businessAdminHomeNotifications7d/>
            </cfif>
            <cfcatch type="any">
                <cfset VARIABLES.businessAdminHomeNotifications7d = 0/>
                <cfset VARIABLES.businessAdminHomeNotificationsRead7d = 0/>
                <cfset VARIABLES.businessAdminHomeNotificationReadRate7d = 0/>
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<cftry>
    <cfquery name="qBusinessAdminHomeAdsPayments" datasource="runnerhub">
        WITH payment_health AS (
            SELECT
                count(*) FILTER (
                    WHERE intent.status IN ('CREATED', 'CHECKOUT_READY', 'PENDING')
                      AND intent.updated_at < clock_timestamp() - interval '30 minutes'
                )::integer AS pending_old,
                count(*) FILTER (WHERE intent.status = 'REVIEW')::integer AS review,
                count(*) FILTER (
                    WHERE intent.status = 'PAID'
                      AND (
                          intent.ledger_entry_id IS NULL
                          OR NOT EXISTS (
                              SELECT 1
                              FROM ads.credit_ledger ledger
                              WHERE ledger.ledger_entry_id = intent.ledger_entry_id
                                AND ledger.payment_intent_id = intent.payment_intent_id
                                AND ledger.source_type = 'PAYMENT'
                                AND ledger.entry_type = 'CREDIT'
                          )
                      )
                )::integer AS paid_without_ledger
            FROM ads.payment_intents intent
        ),
        ledger_health AS (
            SELECT count(*)::integer AS ledger_without_intent
            FROM ads.credit_ledger ledger
            WHERE ledger.source_type = 'PAYMENT'
              AND (
                  ledger.payment_intent_id IS NULL
                  OR NOT EXISTS (
                      SELECT 1
                      FROM ads.payment_intents intent
                      WHERE intent.payment_intent_id = ledger.payment_intent_id
                        AND intent.ledger_entry_id = ledger.ledger_entry_id
                        AND intent.status = 'PAID'
                  )
              )
        ),
        hold_health AS (
            SELECT count(*) FILTER (WHERE hold.status = 'OPEN')::integer AS open_holds
            FROM ads.account_financial_holds hold
        )
        SELECT payment_health.pending_old,
               payment_health.review,
               hold_health.open_holds,
               payment_health.paid_without_ledger,
               ledger_health.ledger_without_intent
        FROM payment_health
        CROSS JOIN ledger_health
        CROSS JOIN hold_health
    </cfquery>
    <cfif qBusinessAdminHomeAdsPayments.recordcount>
        <cfset VARIABLES.businessAdminHomeAdsPendingOld = val(qBusinessAdminHomeAdsPayments.pending_old)/>
        <cfset VARIABLES.businessAdminHomeAdsReview = val(qBusinessAdminHomeAdsPayments.review)/>
        <cfset VARIABLES.businessAdminHomeAdsOpenHolds = val(qBusinessAdminHomeAdsPayments.open_holds)/>
        <cfset VARIABLES.businessAdminHomeAdsPaidWithoutLedger = val(qBusinessAdminHomeAdsPayments.paid_without_ledger)/>
        <cfset VARIABLES.businessAdminHomeAdsLedgerWithoutIntent = val(qBusinessAdminHomeAdsPayments.ledger_without_intent)/>
        <cfset VARIABLES.businessAdminHomeAdsPaymentsLoaded = true/>
    </cfif>
    <cfcatch type="any">
        <cfset VARIABLES.businessAdminHomeAdsPaymentsLoaded = false/>
    </cfcatch>
</cftry>

<cftry>
    <cfquery name="qBusinessAdminHomeAdsReconcileJob">
        SELECT job.last_run_at,
               coalesce(job.last_duration_ms, 0)::integer AS last_duration_ms,
               coalesce(job.last_status, '') AS last_status
        FROM public.tb_cron_jobs job
        WHERE job.endpoint_url =
              'https://business.roadrunners.run/api/ads/payments/reconcile.cfm'
        ORDER BY job.id_cron_job
        LIMIT 1
    </cfquery>
    <cfif qBusinessAdminHomeAdsReconcileJob.recordcount>
        <cfset VARIABLES.businessAdminHomeAdsReconcileLastDuration = val(qBusinessAdminHomeAdsReconcileJob.last_duration_ms)/>
        <cfset VARIABLES.businessAdminHomeAdsReconcileLastRunAt = isNull(qBusinessAdminHomeAdsReconcileJob.last_run_at) ? "" : qBusinessAdminHomeAdsReconcileJob.last_run_at/>
        <cfset VARIABLES.businessAdminHomeAdsReconcileLastStatus = qBusinessAdminHomeAdsReconcileJob.last_status & ""/>
    </cfif>
    <cfcatch type="any"></cfcatch>
</cftry>

<cfset VARIABLES.businessAdminAiMailLoaded=false/>
<cfset VARIABLES.businessAdminAiMailCount=0/>
<cfset VARIABLES.businessAdminAiMailDescription="Conversas importantes aguardando atenção"/>
<cftry>
    <cfquery name="qBusinessAdminAiMail">
        SELECT count(*) FILTER(WHERE state<>'resolved' AND source_available AND (relevant OR needs_review))::int AS total,
               (SELECT count(*) FROM public.tb_ai_mail_queue WHERE last_error<>'')::int AS errors,
               (SELECT enabled FROM public.tb_ai_mail_config WHERE id=1) AS enabled
        FROM public.tb_ai_mail_threads
    </cfquery>
    <cfset VARIABLES.businessAdminAiMailCount=val(qBusinessAdminAiMail.total)/>
    <cfset VARIABLES.businessAdminAiMailLoaded=true/>
    <cfset VARIABLES.businessAdminAiMailDescription=qBusinessAdminAiMail.enabled ? "Conversas importantes · " & val(qBusinessAdminAiMail.errors) & " falhas de análise" : "Monitor pausado: confira a autorização e ativação"/>
    <cfcatch type="any"></cfcatch>
</cftry>
<cfscript>
    // This include is reached only by the existing global-admin branch in home_logado.cfm.
    function businessAdminMetric(required numeric value, boolean available = true) {
        return arguments.available ? LSNumberFormat(arguments.value, "9,999") : "—";
    }
    function businessAdminPercent(required numeric value, required numeric total) {
        return arguments.total > 0 ? max(0, min(100, arguments.value * 100 / arguments.total)) : 0;
    }
    function businessAdminTone(required numeric value, boolean available = true) {
        return !arguments.available ? "muted" : (arguments.value > 0 ? "warning" : "success");
    }
    VARIABLES.businessAdminHomeStatsLoaded = VARIABLES.businessAdminHomeReady AND qBusinessAdminHomeStats.recordcount > 0;
    VARIABLES.businessAdminHomeRegistrationTotal = VARIABLES.businessAdminHomeStatsLoaded ? val(qBusinessAdminHomeStats.solicitacoes_cadastro) : 0;
    VARIABLES.businessAdminHomeEventRequestTotal = VARIABLES.businessAdminHomeStatsLoaded ? val(qBusinessAdminHomeStats.solicitacoes_eventos) : 0;
    VARIABLES.businessAdminHomeContentComplete = max(0, VARIABLES.businessAdminHomeContentTotal - VARIABLES.businessAdminHomeContentIncomplete);
    VARIABLES.businessAdminHomeContentModerate = max(0, VARIABLES.businessAdminHomeContentIncomplete - VARIABLES.businessAdminHomeContentCritical);
    VARIABLES.businessAdminHomeReconcileLabel = VARIABLES.businessAdminHomeAdsReconcileLastStatus;
    if (listFindNoCase("success,ok,completed", VARIABLES.businessAdminHomeAdsReconcileLastStatus)) VARIABLES.businessAdminHomeReconcileLabel = "Concluída";
    else if (listFindNoCase("error,http_error,failed,timeout", VARIABLES.businessAdminHomeAdsReconcileLastStatus)) VARIABLES.businessAdminHomeReconcileLabel = "Falha na execução";
    else if (VARIABLES.businessAdminHomeAdsReconcileLastStatus == "running") VARIABLES.businessAdminHomeReconcileLabel = "Em execução";
    VARIABLES.businessAdminHomeHelpdeskDescription = "Abertos, com nova resposta ou parados há 48 h";
    if (VARIABLES.businessAdminHomeHelpdeskLoaded) {
        VARIABLES.businessAdminHomeHelpdeskDescription = LSNumberFormat(VARIABLES.businessAdminHomeHelpdeskReplyTotal, "9,999") & " a responder · " & LSNumberFormat(VARIABLES.businessAdminHomeHelpdeskStaleTotal, "9,999") & " sem atualização há 48 h";
    }
    VARIABLES.businessAdminHomeResultImportTotal = VARIABLES.businessAdminHomeResultImportFailureTotal + VARIABLES.businessAdminHomeResultImportDelayedTotal;
    VARIABLES.businessAdminHomeResultImportDescription = "Falhas e itens parados há mais de 15 min";
    if (VARIABLES.businessAdminHomeResultImportLoaded) {
        VARIABLES.businessAdminHomeResultImportDescription = LSNumberFormat(VARIABLES.businessAdminHomeResultImportFailureTotal, "9,999") & " falhas · " & LSNumberFormat(VARIABLES.businessAdminHomeResultImportDelayedTotal, "9,999") & " atrasadas";
    }
    VARIABLES.businessAdminHomeStravaMigrationTotal = VARIABLES.businessAdminHomeStravaPendingTotal + VARIABLES.businessAdminHomeStravaReviewTotal + VARIABLES.businessAdminHomeStravaErrorTotal + VARIABLES.businessAdminHomeStravaStuckTotal;
    VARIABLES.businessAdminHomeStravaMigrationDescription = "Pendentes, revisões, erros e processos parados";
    if (VARIABLES.businessAdminHomeStravaMigrationLoaded) {
        VARIABLES.businessAdminHomeStravaMigrationDescription = LSNumberFormat(VARIABLES.businessAdminHomeStravaPendingTotal, "9,999") & " pendentes · " & LSNumberFormat(VARIABLES.businessAdminHomeStravaReviewTotal, "9,999") & " revisão · " & LSNumberFormat(VARIABLES.businessAdminHomeStravaErrorTotal, "9,999") & " erros · " & LSNumberFormat(VARIABLES.businessAdminHomeStravaStuckTotal, "9,999") & " travados";
    }
    VARIABLES.businessAdminHomePushQueueTotal = VARIABLES.businessAdminHomePushPendingStuckTotal + VARIABLES.businessAdminHomePushRetryStuckTotal + VARIABLES.businessAdminHomePushProcessingStuckTotal;
    VARIABLES.businessAdminHomePushQueueDescription = "Entregas paradas há mais de 15 min";
    if (VARIABLES.businessAdminHomePushQueueLoaded) {
        VARIABLES.businessAdminHomePushQueueDescription = LSNumberFormat(VARIABLES.businessAdminHomePushPendingStuckTotal, "9,999") & " pendentes · " & LSNumberFormat(VARIABLES.businessAdminHomePushRetryStuckTotal, "9,999") & " retentativas · " & LSNumberFormat(VARIABLES.businessAdminHomePushProcessingStuckTotal, "9,999") & " processando";
    }
    VARIABLES.businessAdminHomeEmailQueueTotal = VARIABLES.businessAdminHomeEmailPendingTotal + VARIABLES.businessAdminHomeEmailErrorTotal;
    VARIABLES.businessAdminHomeEmailQueueDescription = "Envios vencidos e falhas sem conclusão";
    if (VARIABLES.businessAdminHomeEmailQueueLoaded) {
        VARIABLES.businessAdminHomeEmailQueueDescription = LSNumberFormat(VARIABLES.businessAdminHomeEmailPendingTotal, "9,999") & " vencidos · " & LSNumberFormat(VARIABLES.businessAdminHomeEmailErrorTotal, "9,999") & " com erro";
    }
    VARIABLES.businessAdminHomeQueue = [
        {kind="Comunicação", label="AI-mails", description=VARIABLES.businessAdminAiMailDescription, value=VARIABLES.businessAdminAiMailCount, loaded=VARIABLES.businessAdminAiMailLoaded, href="/administracao/ai-mails/", icon="fa-envelope-open-text"},
        {kind="Atendimento", label="Help Desk", description=VARIABLES.businessAdminHomeHelpdeskDescription, value=VARIABLES.businessAdminHomeHelpdeskPendingTotal, loaded=VARIABLES.businessAdminHomeHelpdeskLoaded, href="/helpdesk/?ordem=prioridade", icon="fa-headset"},
        {kind="Curadoria", label="Conteúdos editoriais", description="Matérias ocultas aguardando decisão", value=VARIABLES.businessAdminHomeEditorialPendingTotal, loaded=VARIABLES.businessAdminHomeEditorialLoaded, href="/portal/conteudos/?status=pendentes", icon="fa-newspaper"},
        {kind="Aprovação", label="Cadastros de conta", description="Empresas aguardando aprovação", value=VARIABLES.businessAdminHomeRegistrationTotal, loaded=VARIABLES.businessAdminHomeStatsLoaded, href="/administracao/contas/", icon="fa-building"},
        {kind="Aprovação", label="Vínculos de eventos", description="Pedidos de associação a uma conta", value=VARIABLES.businessAdminHomeEventRequestTotal, loaded=VARIABLES.businessAdminHomeStatsLoaded, href="/eventos/", icon="fa-link"},
        {kind="Aprovação", label="Anúncios", description="Campanhas prontas para análise", value=VARIABLES.businessAdminHomeAdsReviewPendingTotal, loaded=VARIABLES.businessAdminHomeAdsReviewLoaded, href="/ads/?view=admin", icon="fa-rectangle-ad"},
        {kind="Validação", label="Brasil Gigante", description="Documentos de participantes para conferir", value=VARIABLES.businessAdminHomeChallengePendingTotal, loaded=VARIABLES.businessAdminHomeChallengeLoaded, href="/desafios/circuitobrasilgigante/?tela=validacoes", icon="fa-file-shield"},
        {kind="Curadoria", label="Foco Radical", description="Eventos com galerias para revisar", value=VARIABLES.businessAdminHomeFocoPendingTotal, loaded=VARIABLES.businessAdminHomeFocoLoaded, href="/administracao/foco-revisao/", icon="fa-camera"},
        {kind="Curadoria", label="Agregadores", description="Grupos de edições para consolidar", value=VARIABLES.businessAdminHomeAgregaPendingTotal, loaded=VARIABLES.businessAdminHomeAgregaLoaded, href="/administracao/agrega-revisao/", icon="fa-layer-group"},
        {kind="Operação", label="Importações de resultados", description=VARIABLES.businessAdminHomeResultImportDescription, value=VARIABLES.businessAdminHomeResultImportTotal, loaded=VARIABLES.businessAdminHomeResultImportLoaded, href="/administracao/importacoes-resultados/?periodo=0", icon="fa-stopwatch"}
    ];
    if (VARIABLES.businessAdminHomeHasCrmPendingTable) {
        arrayAppend(VARIABLES.businessAdminHomeQueue, {kind="Validação", label="Vínculos do CRM", description="Fontes importadas sem vínculo com evento RR", value=VARIABLES.businessAdminHomeCrmPendingTotal, loaded=VARIABLES.businessAdminHomeCrmPendingLoaded, href="/crm/", icon="fa-address-book"});
    }
    if (VARIABLES.businessAdminHomeHasStravaMigrationTable) {
        arrayAppend(VARIABLES.businessAdminHomeQueue, {kind="Operação", label="Migração Strava", description=VARIABLES.businessAdminHomeStravaMigrationDescription, value=VARIABLES.businessAdminHomeStravaMigrationTotal, loaded=VARIABLES.businessAdminHomeStravaMigrationLoaded, href="/percursos/migracao-strava.cfm", icon="fa-route"});
    }
    if (VARIABLES.businessAdminHomeHasPushQueueTable) {
        arrayAppend(VARIABLES.businessAdminHomeQueue, {kind="Operação", label="Fila de Push", description=VARIABLES.businessAdminHomePushQueueDescription, value=VARIABLES.businessAdminHomePushQueueTotal, loaded=VARIABLES.businessAdminHomePushQueueLoaded, href="/notificacoes/envio/?view=push", icon="fa-mobile-screen-button"});
    }
    if (VARIABLES.businessAdminHomeHasEmailQueueTable) {
        arrayAppend(VARIABLES.businessAdminHomeQueue, {kind="Operação", label="E-mail marketing", description=VARIABLES.businessAdminHomeEmailQueueDescription, value=VARIABLES.businessAdminHomeEmailQueueTotal, loaded=VARIABLES.businessAdminHomeEmailQueueLoaded, href="/emailmkt/", icon="fa-envelope"});
    }
    if (VARIABLES.businessAdminHomeHasVickyProactiveTable) {
        arrayAppend(VARIABLES.businessAdminHomeQueue, {kind="Operação", label="Entregas da Vicky", description="Falhas e itens sem entrega nos últimos 30 dias", value=VARIABLES.businessAdminHomeVickyDeliveryFailureTotal, loaded=VARIABLES.businessAdminHomeVickyProactiveLoaded, href="/administracao/vicky/?secao=interacoes", icon="fa-comments"});
    }
    if (VARIABLES.businessAdminHomeHasVickyDocumentTable) {
        arrayAppend(VARIABLES.businessAdminHomeQueue, {kind="Operação", label="Base da Vicky", description="Documentos com falha de processamento", value=VARIABLES.businessAdminHomeVickyDocumentFailureTotal, loaded=VARIABLES.businessAdminHomeVickyDocumentLoaded, href="/administracao/vicky/?secao=conhecimento", icon="fa-book-open"});
    }
    if (VARIABLES.businessAdminHomeHasAthleteReviewTable) {
        arrayAppend(VARIABLES.businessAdminHomeQueue, {kind="Aprovação", label="Atletas verificados", description="Solicitações de selo aguardando decisão", value=VARIABLES.businessAdminHomeAthleteReviewPendingTotal, loaded=VARIABLES.businessAdminHomeAthleteReviewLoaded, href="/portal/verificados/?status=pendentes", icon="fa-circle-check"});
    }
    VARIABLES.businessAdminHomeDecisionLoaded = true;
    VARIABLES.businessAdminHomeDecisionTotal = 0;
    for (VARIABLES.businessAdminHomeQueueItem in VARIABLES.businessAdminHomeQueue) {
        if (VARIABLES.businessAdminHomeQueueItem.loaded) {
            VARIABLES.businessAdminHomeDecisionTotal += VARIABLES.businessAdminHomeQueueItem.value;
        } else {
            VARIABLES.businessAdminHomeDecisionLoaded = false;
        }
    }
    VARIABLES.businessAdminHomeOverview = [
        {label="Contas ativas", description="Empresas com acesso ativo", value=VARIABLES.businessAdminHomeStatsLoaded ? val(qBusinessAdminHomeStats.contas_ativas) : 0, href="/administracao/contas/", icon="fa-building"},
        {label="Usuários nas contas", description="Vínculos ativos de usuários", value=VARIABLES.businessAdminHomeStatsLoaded ? val(qBusinessAdminHomeStats.usuarios_ativos) : 0, href="/administracao/usuarios/", icon="fa-users"},
        {label="Eventos nas contas", description="Vínculos ativos de eventos", value=VARIABLES.businessAdminHomeStatsLoaded ? val(qBusinessAdminHomeStats.eventos_ativos) : 0, href="/eventos/", icon="fa-flag-checkered"},
        {label="Campanhas no ar", description="Ativas e dentro da vigência", value=VARIABLES.businessAdminHomeStatsLoaded ? val(qBusinessAdminHomeStats.campanhas_ativas) : 0, href="/ads/", icon="fa-bullhorn"}
    ];
    VARIABLES.businessAdminHomePayments = [
        {label="Sem atualização", description="Pendentes há mais de 30 min", value=VARIABLES.businessAdminHomeAdsPendingOld, icon="fa-clock"},
        {label="Revisão manual", description="Pagamentos que exigem decisão", value=VARIABLES.businessAdminHomeAdsReview, icon="fa-magnifying-glass"},
        {label="Bloqueios abertos", description="Restrições financeiras em contas", value=VARIABLES.businessAdminHomeAdsOpenHolds, icon="fa-lock"},
        {label="Pagos sem crédito", description="Pagamento sem lançamento válido", value=VARIABLES.businessAdminHomeAdsPaidWithoutLedger, icon="fa-receipt"},
        {label="Créditos sem pagamento", description="Lançamento sem pagamento válido", value=VARIABLES.businessAdminHomeAdsLedgerWithoutIntent, icon="fa-link-slash"}
    ];
</cfscript>

<link rel="stylesheet" href="/assets/css/admin-suite.css?v=20260917-aimails"/>
<link rel="stylesheet" href="/assets/css/admin-dashboard.css?v=20260917-1"/>

<div class="col-12 business-global-dashboard admin-suite-page">
    <header class="admin-suite-header">
        <div class="admin-suite-heading">
            <span class="admin-suite-heading-icon" aria-hidden="true"><i class="fa-solid fa-chart-pie"></i></span>
            <div class="admin-suite-heading-copy">
                <div class="admin-suite-kicker">Operação RunnerHub · Admin global</div>
                <h1 class="admin-suite-title">Visão geral do Business</h1>
                <p class="admin-suite-subtitle">O que está acontecendo e o que precisa da sua atenção.</p>
            </div>
        </div>
        <cfinclude template="admin_suite_nav.cfm"/>
    </header>

    <div class="gd-toolbar">
        <nav class="gd-shortcuts" aria-label="Seções do dashboard">
            <a href="#business-admin-pending">Pendências</a>
            <a href="#business-admin-content">Conteúdo</a>
            <a href="#business-admin-health">Portal</a>
            <a href="#business-admin-payments">Pagamentos</a>
            <a href="#business-admin-infra">Infraestrutura</a>
        </nav>
        <a class="gd-refresh" href="/" aria-label="Atualizar os indicadores do dashboard">
            <i class="fa-solid fa-rotate" aria-hidden="true"></i>
            <span>Atualizar <small><cfoutput>#timeFormat(now(), "HH:nn")#</cfoutput></small></span>
        </a>
    </div>

    <cfif NOT VARIABLES.businessAdminHomeStatsLoaded>
        <div class="gd-notice" role="status"><i class="fa-solid fa-circle-info" aria-hidden="true"></i> Parte do resumo está indisponível. Indicadores sem dados aparecem como “—”. Tente atualizar a página.</div>
    </cfif>

    <section class="gd-overview" aria-label="Panorama atual do Business">
        <cfloop array="#VARIABLES.businessAdminHomeOverview#" index="businessOverviewItem">
            <cfoutput>
                <a class="gd-kpi" href="#businessOverviewItem.href#">
                    <span class="gd-kpi-top"><span>#businessOverviewItem.label#</span><i class="fa-solid #businessOverviewItem.icon#" aria-hidden="true"></i></span>
                    <strong class="gd-kpi-value">#businessAdminMetric(businessOverviewItem.value, VARIABLES.businessAdminHomeStatsLoaded)#</strong>
                    <span class="gd-kpi-foot">#businessOverviewItem.description# <i class="fa-solid fa-arrow-up-right-from-square" aria-hidden="true"></i></span>
                </a>
            </cfoutput>
        </cfloop>
    </section>
    <p class="gd-overview-note">Posição atual · Uma pessoa ou evento pode estar vinculado a mais de uma conta.
        <cfif VARIABLES.businessAdminHomeStatsLoaded><a href="/administracao/contas/"><cfoutput>#businessAdminMetric(val(qBusinessAdminHomeStats.contas_pendentes))#</cfoutput> contas com status pendente</a></cfif>
    </p>

    <section class="gd-meet" id="businessMeetRoom" data-status-url="/administracao/meet/status.cfm" data-poll-ms="20000" aria-labelledby="gd-meet-title">
        <span class="gd-meet-icon" aria-hidden="true"><i class="fa-solid fa-video"></i></span>
        <div class="gd-meet-copy">
            <div class="gd-meet-heading"><h2 id="gd-meet-title">Sala virtual da equipe</h2><span class="badge rounded-pill badge-secondary" id="businessMeetBadge">Verificando…</span></div>
            <p id="businessMeetSummary" role="status" aria-live="polite">Consultando o Google Meet…</p>
            <div class="business-meet-room-people" id="businessMeetPeople" role="list" aria-label="Pessoas conectadas" hidden></div>
        </div>
        <small id="businessMeetUpdated"></small>
        <div class="gd-meet-actions">
            <button class="btn btn-sm btn-success disabled" id="businessMeetJoin" type="button" disabled aria-disabled="true"><i class="fa-solid fa-right-to-bracket me-1" aria-hidden="true"></i>Entrar na sala</button>
            <button class="btn btn-sm btn-outline-light" id="businessMeetRefresh" type="button" aria-label="Atualizar presença na sala"><i class="fa-solid fa-rotate" aria-hidden="true"></i></button>
        </div>
    </section>

    <div class="gd-section-heading"><h2>Prioridades da operação</h2><span>Da visão geral à próxima ação</span></div>
    <div class="gd-priorities">
        <section class="gd-panel" id="business-admin-pending" aria-labelledby="gd-pending-title">
            <header class="gd-panel-heading">
                <div><span class="gd-eyebrow">Ações humanas · Fila atual</span><h2 id="gd-pending-title">Central de pendências</h2><p>Atendimento, aprovações, curadoria, validações e exceções operacionais.</p></div>
                <span class="gd-icon" aria-hidden="true"><i class="fa-solid fa-list-check"></i></span>
            </header>
            <div class="gd-headline"><strong><cfoutput>#businessAdminMetric(VARIABLES.businessAdminHomeDecisionTotal, VARIABLES.businessAdminHomeDecisionLoaded)#</cfoutput></strong><span>itens que pedem ação<br><small>cada item é contado em uma única fila</small></span></div>
            <cfif NOT VARIABLES.businessAdminHomeDecisionLoaded><p class="gd-unavailable">Total indisponível: uma das filas não pôde ser consultada.</p>
            <cfelseif VARIABLES.businessAdminHomeDecisionTotal EQ 0><p class="gd-success-note"><i class="fa-solid fa-circle-check" aria-hidden="true"></i> Nenhuma ação humana pendente.</p></cfif>
            <div class="gd-queue">
                <cfloop array="#VARIABLES.businessAdminHomeQueue#" index="businessQueueItem">
                    <cfoutput>
                        <a class="gd-queue-row" href="#businessQueueItem.href#">
                            <i class="fa-solid #businessQueueItem.icon# gd-queue-icon" aria-hidden="true"></i>
                            <span class="gd-queue-copy"><strong>#businessQueueItem.label#</strong><small><span class="gd-queue-kind">#businessQueueItem.kind#</span>#businessQueueItem.description#</small></span>
                            <strong class="gd-count gd-#businessAdminTone(businessQueueItem.value, businessQueueItem.loaded)#">#businessAdminMetric(businessQueueItem.value, businessQueueItem.loaded)#</strong>
                            <i class="fa-solid fa-chevron-right gd-chevron" aria-hidden="true"></i>
                        </a>
                    </cfoutput>
                </cfloop>
            </div>
            <p class="gd-caption">O total reúne somente filas acionáveis e evita duplicar indicadores de qualidade, pagamentos, cron e disponibilidade exibidos nos painéis próprios.</p>
        </section>

        <section class="gd-panel" id="business-admin-content" aria-labelledby="gd-content-title">
            <header class="gd-panel-heading"><div><span class="gd-eyebrow">Conteúdo · Em andamento e até 90 dias</span><h2 id="gd-content-title">Eventos prontos para o público</h2></div><a class="gd-icon-link" href="/portal/conteudo/" aria-label="Gerenciar conteúdo dos eventos"><i class="fa-solid fa-arrow-up-right-from-square" aria-hidden="true"></i></a></header>
            <cfif VARIABLES.businessAdminHomeContentLoaded>
                <div class="gd-headline"><strong><cfoutput>#VARIABLES.businessAdminHomeContentTotal GT 0 ? LSNumberFormat(businessAdminPercent(VARIABLES.businessAdminHomeContentComplete, VARIABLES.businessAdminHomeContentTotal), "9.9") & '<small>%</small>' : '—'#</cfoutput></strong><span>com os 7 campos preenchidos<br><small><cfoutput>#businessAdminMetric(VARIABLES.businessAdminHomeContentComplete)# de #businessAdminMetric(VARIABLES.businessAdminHomeContentTotal)# eventos</cfoutput></small></span></div>
                <cfif VARIABLES.businessAdminHomeContentTotal GT 0>
                    <div class="gd-segments" aria-hidden="true">
                        <cfoutput><span class="gd-bg-success" style="width:#numberFormat(businessAdminPercent(VARIABLES.businessAdminHomeContentComplete, VARIABLES.businessAdminHomeContentTotal), '0.00')#%"></span><span class="gd-bg-warning" style="width:#numberFormat(businessAdminPercent(VARIABLES.businessAdminHomeContentModerate, VARIABLES.businessAdminHomeContentTotal), '0.00')#%"></span><span class="gd-bg-danger" style="width:#numberFormat(businessAdminPercent(VARIABLES.businessAdminHomeContentCritical, VARIABLES.businessAdminHomeContentTotal), '0.00')#%"></span></cfoutput>
                    </div>
                    <p class="gd-caption"><cfoutput>#businessAdminMetric(VARIABLES.businessAdminHomeContentIncomplete)#</cfoutput> eventos com informações incompletas, distribuídos abaixo.</p>
                    <dl class="gd-legend">
                        <div><dt><span class="gd-dot gd-bg-success"></span>Completos <small>7 campos preenchidos</small></dt><dd><cfoutput>#businessAdminMetric(VARIABLES.businessAdminHomeContentComplete)#</cfoutput></dd></div>
                        <div><dt><span class="gd-dot gd-bg-warning"></span>A completar <small>1 ou 2 campos ausentes</small></dt><dd><cfoutput>#businessAdminMetric(VARIABLES.businessAdminHomeContentModerate)#</cfoutput></dd></div>
                        <div><dt><span class="gd-dot gd-bg-danger"></span>Críticos <small>3 ou mais campos ausentes</small></dt><dd><cfoutput>#businessAdminMetric(VARIABLES.businessAdminHomeContentCritical)#</cfoutput></dd></div>
                    </dl>
                    <a class="gd-callout" href="#business-admin-content-list"><i class="fa-regular fa-calendar" aria-hidden="true"></i><span><strong><cfoutput>#businessAdminMetric(VARIABLES.businessAdminHomeContentNext30)#</cfoutput> incompletos até os próximos 30 dias</strong><small>Inclui eventos em andamento, conforme a data de encerramento</small></span><i class="fa-solid fa-arrow-down" aria-hidden="true"></i></a>
                <cfelse><p class="gd-empty">Nenhum evento ativo neste período.</p></cfif>
                <p class="gd-caption">Eventos ativos e ainda não encerrados, com início até 90 dias. Completude do cadastro, não avaliação editorial.</p>
            <cfelse><p class="gd-empty">Não foi possível consultar a qualidade do conteúdo.</p></cfif>
            <details class="gd-definition"><summary>Quais são os 7 campos?</summary><p>Descrição, link de inscrição, categorias, organizador, cidade e estado, endereço e imagem. Cidade e estado formam um único item.</p></details>
        </section>
    </div>

    <div class="gd-health-grid">
        <section class="gd-panel" id="business-admin-health" aria-labelledby="gd-health-title">
            <header class="gd-panel-heading"><div><span class="gd-eyebrow">Experiência no portal</span><h2 id="gd-health-title">Acessos e pontos de atenção</h2></div><a class="gd-icon-link" href="/portal/erros/" aria-label="Investigar erros do portal"><i class="fa-solid fa-arrow-up-right-from-square" aria-hidden="true"></i></a></header>
            <div class="gd-portal-grid">
                <div class="gd-traffic">
                    <span class="gd-period">Últimos 7 dias</span>
                    <strong><cfoutput>#businessAdminMetric(VARIABLES.businessAdminHomePortalEventViews, VARIABLES.businessAdminHomePortalLoaded)#</cfoutput></strong>
                    <span>visualizações de eventos</span>
                    <small>Acessos registrados no log do portal; não são pessoas únicas.</small>
                </div>
                <div class="gd-health-period">
                    <span class="gd-period">Portal · Últimos 7 dias</span>
                    <a class="gd-stat-row" href="/portal/erros/"><span>Erros registrados</span><strong class="gd-warning"><cfoutput>#businessAdminMetric(VARIABLES.businessAdminHomePortalErrors, VARIABLES.businessAdminHomePortalLoaded)#</cfoutput></strong></a>
                    <a class="gd-stat-row" href="/portal/erros/"><span>Páginas não encontradas <small>404</small></span><strong class="gd-warning"><cfoutput>#businessAdminMetric(VARIABLES.businessAdminHomePortalNotFound, VARIABLES.businessAdminHomePortalLoaded)#</cfoutput></strong></a>
                </div>
                <div class="gd-health-period">
                    <span class="gd-period">Busca · Últimos 30 dias</span>
                    <a class="gd-stat-row" href="/portal/busca/"><span>Erros de interpretação</span><strong class="gd-warning"><cfoutput>#businessAdminMetric(VARIABLES.businessAdminHomeSearchErrors, VARIABLES.businessAdminHomeSearchLoaded)#</cfoutput></strong></a>
                    <a class="gd-stat-row" href="/portal/busca/"><span>Buscas sem resultado</span><strong class="gd-warning"><cfoutput>#businessAdminMetric(VARIABLES.businessAdminHomeSearchZeroResults, VARIABLES.businessAdminHomeSearchLoaded)#</cfoutput></strong></a>
                </div>
            </div>
            <p class="gd-caption">Cada grupo tem seu próprio período. As ocorrências não representam usuários únicos.</p>
        </section>

        <section class="gd-panel" aria-labelledby="gd-notifications-title">
            <header class="gd-panel-heading"><div><span class="gd-eyebrow">Comunicação · Últimos 7 dias</span><h2 id="gd-notifications-title">Leitura de notificações</h2></div><a class="gd-icon-link" href="/notificacoes/" aria-label="Gerenciar notificações"><i class="fa-regular fa-bell" aria-hidden="true"></i></a></header>
            <cfif VARIABLES.businessAdminHomeNotificationsLoaded AND VARIABLES.businessAdminHomeNotifications7d GT 0>
                <div class="gd-notification-result">
                    <cfoutput><div class="gd-ring" style="--progress:#numberFormat(VARIABLES.businessAdminHomeNotificationReadRate7d, '0.00')#%"><strong>#LSNumberFormat(VARIABLES.businessAdminHomeNotificationReadRate7d, "9.9")#<small>%</small></strong><span>lidas</span></div></cfoutput>
                    <dl class="gd-notification-counts"><div><dt>Lidas</dt><dd><cfoutput>#businessAdminMetric(VARIABLES.businessAdminHomeNotificationsRead7d)#</cfoutput></dd></div><div><dt>Publicadas</dt><dd><cfoutput>#businessAdminMetric(VARIABLES.businessAdminHomeNotifications7d)#</cfoutput></dd></div></dl>
                </div>
                <p class="gd-caption">Registros com leitura confirmada entre as notificações publicadas nos últimos 7 dias.</p>
            <cfelseif VARIABLES.businessAdminHomeNotificationsLoaded><p class="gd-empty"><i class="fa-regular fa-bell-slash" aria-hidden="true"></i>Nenhuma notificação publicada nos últimos 7 dias.</p>
            <cfelse><p class="gd-empty">Dados de notificações indisponíveis.</p></cfif>
        </section>
    </div>

    <section class="gd-panel gd-payments" id="business-admin-payments" aria-labelledby="gd-payments-title">
        <header class="gd-panel-heading"><div><span class="gd-eyebrow">Publicidade · Posição atual</span><h2 id="gd-payments-title">Saúde dos pagamentos</h2><p>Contagens de pendências e inconsistências. O esperado é zero em cada indicador.</p></div><a class="gd-text-link" href="/ads/">Abrir Publicidade <i class="fa-solid fa-arrow-right" aria-hidden="true"></i></a></header>
        <div class="gd-payment-grid">
            <cfloop array="#VARIABLES.businessAdminHomePayments#" index="businessPaymentItem">
                <cfoutput><div class="gd-payment-item gd-#businessAdminTone(businessPaymentItem.value, VARIABLES.businessAdminHomeAdsPaymentsLoaded)#"><div><i class="fa-solid #businessPaymentItem.icon#" aria-hidden="true"></i><strong>#businessAdminMetric(businessPaymentItem.value, VARIABLES.businessAdminHomeAdsPaymentsLoaded)#</strong></div><h3>#businessPaymentItem.label#</h3><p>#businessPaymentItem.description#</p><span class="gd-payment-state">#NOT VARIABLES.businessAdminHomeAdsPaymentsLoaded ? 'Indisponível' : (businessPaymentItem.value GT 0 ? 'Requer atenção' : 'Sem pendências')#</span></div></cfoutput>
            </cfloop>
        </div>
        <div class="gd-reconcile"><span><i class="fa-solid fa-arrows-rotate" aria-hidden="true"></i> Última conciliação:
            <cfif isDate(VARIABLES.businessAdminHomeAdsReconcileLastRunAt)><cfoutput><strong>#encodeForHtml(VARIABLES.businessAdminHomeReconcileLabel)#</strong> · #dateTimeFormat(VARIABLES.businessAdminHomeAdsReconcileLastRunAt, "dd/mm HH:nn")# · #businessAdminMetric(VARIABLES.businessAdminHomeAdsReconcileLastDuration)# ms</cfoutput><cfelse>Sem execução registrada</cfif></span><a href="/administracao/cron-jobs/">Ver execuções <i class="fa-solid fa-arrow-right" aria-hidden="true"></i></a></div>
    </section>

    <div class="gd-section-heading" id="business-admin-infra"><h2>Infraestrutura</h2><span>Disponibilidade e rotinas automáticas</span></div>
    <div class="gd-infra-grid">
        <cfinclude template="uptime_status.cfm"/>
        <cfinclude template="cron_jobs_status.cfm"/>
    </div>

    <section class="gd-panel gd-content-list" id="business-admin-content-list" aria-labelledby="gd-content-list-title">
        <header class="gd-panel-heading"><div><span class="gd-eyebrow">Próximas correções · Em andamento e até 90 dias</span><h2 id="gd-content-list-title">Conteúdo para completar</h2><p>Até 5 eventos, por data de início. Inclui eventos ainda não encerrados no cadastro.</p></div><a class="gd-text-link" href="/portal/conteudo/">Ver todos <i class="fa-solid fa-arrow-right" aria-hidden="true"></i></a></header>
        <cfif VARIABLES.businessAdminHomeContentLoaded AND qBusinessAdminHomeContentGaps.recordcount>
            <div class="gd-table-scroll" role="region" aria-label="Eventos com conteúdo incompleto" tabindex="0">
                <table class="gd-table"><thead><tr><th scope="col">Evento</th><th scope="col">Data / Local</th><th scope="col">Informações ausentes</th><th scope="col">Completude</th></tr></thead><tbody>
                <cfoutput query="qBusinessAdminHomeContentGaps">
                    <tr><td><a href="/portal/conteudo/?busca=#urlEncodedFormat(qBusinessAdminHomeContentGaps.tag)#"><strong>#encodeForHtml(qBusinessAdminHomeContentGaps.nome_evento)#</strong><small>#encodeForHtml(qBusinessAdminHomeContentGaps.tag)#</small></a></td><td><span class="gd-nowrap">#dateFormat(qBusinessAdminHomeContentGaps.data_inicial, "dd/mm/yyyy")#</span><small>#encodeForHtml(qBusinessAdminHomeContentGaps.cidade)# / #encodeForHtml(qBusinessAdminHomeContentGaps.estado)#</small></td><td class="gd-missing">#encodeForHtml(qBusinessAdminHomeContentGaps.faltando)#</td><td><span class="gd-field-status #qBusinessAdminHomeContentGaps.missing_count GTE 3 ? 'gd-danger' : 'gd-warning'#">#7 - qBusinessAdminHomeContentGaps.missing_count# de 7 campos</span><span class="gd-track gd-completeness" aria-hidden="true"><span style="width:#numberFormat(businessAdminPercent(7 - qBusinessAdminHomeContentGaps.missing_count, 7), '0.00')#%"></span></span></td></tr>
                </cfoutput>
                </tbody></table>
            </div>
        <cfelseif VARIABLES.businessAdminHomeContentLoaded><p class="gd-empty"><i class="fa-solid fa-circle-check gd-success" aria-hidden="true"></i>Nenhum evento com campos pendentes neste período.</p>
        <cfelse><p class="gd-empty">A lista de eventos está indisponível no momento.</p></cfif>
    </section>

    <cfif VARIABLES.businessAdminHomeStatsLoaded>
        <div class="gd-details-grid">
            <details class="gd-panel gd-detail-panel" <cfif qBusinessAdminHomeRegistrations.recordcount>open</cfif>>
                <summary><span><span class="gd-eyebrow">Últimas solicitações</span><strong>Cadastros de conta</strong></span><span class="gd-detail-count"><cfoutput>#businessAdminMetric(VARIABLES.businessAdminHomeRegistrationTotal)#</cfoutput></span></summary>
                <div class="gd-detail-body">
                    <cfif qBusinessAdminHomeRegistrations.recordcount>
                        <cfoutput query="qBusinessAdminHomeRegistrations"><a class="gd-request" href="/administracao/contas/"><span><strong>#encodeForHtml(qBusinessAdminHomeRegistrations.nome_empresa)#</strong><small>#encodeForHtml(qBusinessAdminHomeRegistrations.tipo_prestador)# · #encodeForHtml(qBusinessAdminHomeRegistrations.email_responsavel)#</small></span><time>#dateFormat(qBusinessAdminHomeRegistrations.data_criacao, "dd/mm")#<small>#timeFormat(qBusinessAdminHomeRegistrations.data_criacao, "HH:nn")#</small></time></a></cfoutput>
                        <a class="gd-text-link" href="/administracao/contas/">Revisar todos os cadastros <i class="fa-solid fa-arrow-right" aria-hidden="true"></i></a>
                    <cfelse><p class="gd-empty">Nenhuma solicitação de cadastro pendente.</p></cfif>
                </div>
            </details>
            <details class="gd-panel gd-detail-panel" <cfif qBusinessAdminHomeEventRequests.recordcount>open</cfif>>
                <summary><span><span class="gd-eyebrow">Últimas solicitações</span><strong>Vínculos de eventos</strong></span><span class="gd-detail-count"><cfoutput>#businessAdminMetric(VARIABLES.businessAdminHomeEventRequestTotal)#</cfoutput></span></summary>
                <div class="gd-detail-body">
                    <cfif qBusinessAdminHomeEventRequests.recordcount>
                        <cfoutput query="qBusinessAdminHomeEventRequests"><a class="gd-request" href="/eventos/"><span><strong>#encodeForHtml(qBusinessAdminHomeEventRequests.nome_evento)#</strong><small>#encodeForHtml(qBusinessAdminHomeEventRequests.nome_conta)#</small></span><time>#dateFormat(qBusinessAdminHomeEventRequests.data_criacao, "dd/mm")#<small>#timeFormat(qBusinessAdminHomeEventRequests.data_criacao, "HH:nn")#</small></time></a></cfoutput>
                        <a class="gd-text-link" href="/eventos/">Revisar todos os vínculos <i class="fa-solid fa-arrow-right" aria-hidden="true"></i></a>
                    <cfelse><p class="gd-empty">Nenhuma solicitação de evento pendente.</p></cfif>
                </div>
            </details>
        </div>
        <cfif qBusinessAdminHomeLegacyPartners.recordcount>
            <details class="gd-panel gd-detail-panel gd-legacy">
                <summary><span><span class="gd-eyebrow">Manutenção da base</span><strong>Parceiros do cadastro anterior</strong></span><span class="gd-detail-count">Até 5 recentes</span></summary>
                <div class="gd-detail-body"><p class="gd-caption">Amostra de usuários com informações de parceiro no cadastro antigo, para migração ou revisão.</p>
                    <div class="gd-table-scroll" role="region" aria-label="Parceiros do cadastro anterior" tabindex="0"><table class="gd-table"><thead><tr><th scope="col">Usuário</th><th scope="col">E-mail</th><th scope="col">Perfil</th><th scope="col">Nome comercial</th></tr></thead><tbody>
                    <cfoutput query="qBusinessAdminHomeLegacyPartners"><tr><td>#encodeForHtml(qBusinessAdminHomeLegacyPartners.name)#</td><td>#encodeForHtml(qBusinessAdminHomeLegacyPartners.email)#</td><td>#encodeForHtml(qBusinessAdminHomeLegacyPartners.perfil)#</td><td>#encodeForHtml(qBusinessAdminHomeLegacyPartners.nome_comercial)#</td></tr></cfoutput>
                    </tbody></table></div><a class="gd-text-link" href="/administracao/contas/">Gerenciar contas <i class="fa-solid fa-arrow-right" aria-hidden="true"></i></a>
                </div>
            </details>
        </cfif>
    </cfif>
    <p class="gd-footer-note">Dados consultados ao abrir ou atualizar esta página. A presença na sala é atualizada automaticamente; a infraestrutura indica seu próprio horário de consulta.</p>
</div>
