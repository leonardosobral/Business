<cfset qBusinessAdminHomeStats = QueryNew("solicitacoes_cadastro,solicitacoes_eventos")/>
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
<cfset VARIABLES.businessAdminHomeHasMedicalAccessTable = false/>
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
<cfset VARIABLES.businessAdminHomeMedicalAccessPendingTotal = 0/>
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
<cfset VARIABLES.businessAdminHomeCronOverdue = 0/>
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
<cfset VARIABLES.businessAdminHomeMedicalAccessLoaded = false/>
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
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_evento_saude_acesso_solicitacoes"/>,
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
    <cfset VARIABLES.businessAdminHomeHasMedicalAccessTable = ListFindNoCase(VARIABLES.businessAdminHomeTableNames, "tb_evento_saude_acesso_solicitacoes")/>
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
            (SELECT count(*)::integer FROM tb_conta_cadastro_solicitacoes WHERE status::text = 'PENDENTE') AS solicitacoes_cadastro,
            (SELECT count(*)::integer FROM tb_conta_evento_solicitacoes WHERE status::text = 'PENDENTE') AS solicitacoes_eventos
    </cfquery>

    <cfcatch type="any">
        <cfset VARIABLES.businessAdminHomeReady = false/>
        <cfset VARIABLES.businessAdminHomeError = cfcatch.message/>
        <cfset qBusinessAdminHomeStats = QueryNew("solicitacoes_cadastro,solicitacoes_eventos")/>
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

    <cfif VARIABLES.businessAdminHomeHasMedicalAccessTable>
        <cftry>
            <cfquery name="qBusinessAdminHomeMedicalAccessPending" datasource="runnerhub">
                SELECT count(*)::integer AS total
                FROM public.tb_evento_saude_acesso_solicitacoes
                WHERE status = 'PENDENTE'
            </cfquery>
            <cfset VARIABLES.businessAdminHomeMedicalAccessPendingTotal = val(qBusinessAdminHomeMedicalAccessPending.total)/>
            <cfset VARIABLES.businessAdminHomeMedicalAccessLoaded = true/>
            <cfcatch type="any">
                <cfset VARIABLES.businessAdminHomeMedicalAccessPendingTotal = 0/>
            </cfcatch>
        </cftry>
    </cfif>

    <cfif VARIABLES.businessAdminHomeHasLogTable>
        <cftry>
            <cfquery name="qBusinessAdminHomePortalHealth">
                SELECT
                    (count(*) FILTER (WHERE log_item = 'erro'))::integer AS erros,
                    (count(*) FILTER (WHERE log_item = '404'))::integer AS not_found
                FROM tb_log
                WHERE log_timestamp >= now() - interval '7 days'
                  AND log_item IN ('erro', '404')
            </cfquery>
            <cfset VARIABLES.businessAdminHomePortalErrors = val(qBusinessAdminHomePortalHealth.erros)/>
            <cfset VARIABLES.businessAdminHomePortalNotFound = val(qBusinessAdminHomePortalHealth.not_found)/>
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
        <cfset VARIABLES.businessAdminHomeContentLoaded = true/>
        <cfcatch type="any">
            <cfset VARIABLES.businessAdminHomeContentIncomplete = 0/>
            <cfset VARIABLES.businessAdminHomeContentCritical = 0/>
            <cfset VARIABLES.businessAdminHomeContentNext30 = 0/>
        </cfcatch>
    </cftry>

    <cfif VARIABLES.businessAdminHomeHasCronTables>
        <cftry>
            <cfquery name="qBusinessAdminHomeCronStats">
                SELECT
                    count(*)::integer AS total_jobs,
                    (count(*) FILTER (WHERE ativo = true))::integer AS ativos,
                    (count(*) FILTER (WHERE ativo = true AND next_run_at <= (now() AT TIME ZONE 'UTC')))::integer AS vencidos,
                    (count(*) FILTER (WHERE ativo = true AND next_run_at <= (now() AT TIME ZONE 'UTC') - interval '15 minutes' AND lower(trim(coalesce(last_status, ''))) <> 'running'))::integer AS atrasados,
                    (count(*) FILTER (WHERE lower(trim(coalesce(last_status, ''))) IN ('error', 'http_error', 'failed', 'timeout')))::integer AS erros
                FROM tb_cron_jobs
            </cfquery>
            <cfset VARIABLES.businessAdminHomeCronTotal = val(qBusinessAdminHomeCronStats.total_jobs)/>
            <cfset VARIABLES.businessAdminHomeCronActive = val(qBusinessAdminHomeCronStats.ativos)/>
            <cfset VARIABLES.businessAdminHomeCronDue = val(qBusinessAdminHomeCronStats.vencidos)/>
            <cfset VARIABLES.businessAdminHomeCronOverdue = val(qBusinessAdminHomeCronStats.atrasados)/>
            <cfset VARIABLES.businessAdminHomeCronErrors = val(qBusinessAdminHomeCronStats.erros)/>
            <cfset VARIABLES.businessAdminHomeCronLoaded = true/>
            <cfcatch type="any">
                <cfset VARIABLES.businessAdminHomeCronLoaded = false/>
                <cfset VARIABLES.businessAdminHomeCronTotal = 0/>
                <cfset VARIABLES.businessAdminHomeCronActive = 0/>
                <cfset VARIABLES.businessAdminHomeCronDue = 0/>
                <cfset VARIABLES.businessAdminHomeCronOverdue = 0/>
                <cfset VARIABLES.businessAdminHomeCronErrors = 0/>
            </cfcatch>
        </cftry>
    </cfif>

    <cfif VARIABLES.businessAdminHomeHasNotificationTable>
        <cftry>
            <cfquery name="qBusinessAdminHomeNotificationStats">
                SELECT
                    count(*)::integer AS total,
                    (count(*) FILTER (WHERE ntf.data_leitura IS NOT NULL))::integer AS lidas
                FROM tb_notifica ntf
                INNER JOIN tb_usuarios usr ON usr.id = ntf.id_usuario
                WHERE ntf.data_publicacao >= now() - interval '7 days'
                  AND ntf.data_publicacao <= now()
                  AND coalesce(usr.is_admin, false) = false
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
        WHERE analyzed_at IS NOT NULL
           OR last_inbound_ms > (SELECT monitor_since_ms FROM public.tb_ai_mail_config WHERE id=1)
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
    if (VARIABLES.businessAdminHomeHasMedicalAccessTable) {
        arrayAppend(VARIABLES.businessAdminHomeQueue, {kind="Aprovação", label="Acesso médico", description="Pedidos para operar Centrais de Saúde", value=VARIABLES.businessAdminHomeMedicalAccessPendingTotal, loaded=VARIABLES.businessAdminHomeMedicalAccessLoaded, href="/administracao/contas/?tab=solicitacoes-saude##solicitacoes-saude", icon="fa-user-doctor"});
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
    VARIABLES.businessAdminHomePayments = [
        {label="Sem atualização", description="Pendentes há mais de 30 min", value=VARIABLES.businessAdminHomeAdsPendingOld, icon="fa-clock"},
        {label="Revisão manual", description="Pagamentos que exigem decisão", value=VARIABLES.businessAdminHomeAdsReview, icon="fa-magnifying-glass"},
        {label="Bloqueios abertos", description="Restrições financeiras em contas", value=VARIABLES.businessAdminHomeAdsOpenHolds, icon="fa-lock"},
        {label="Pagos sem crédito", description="Pagamento sem lançamento válido", value=VARIABLES.businessAdminHomeAdsPaidWithoutLedger, icon="fa-receipt"},
        {label="Créditos sem pagamento", description="Lançamento sem pagamento válido", value=VARIABLES.businessAdminHomeAdsLedgerWithoutIntent, icon="fa-link-slash"}
    ];
</cfscript>

<cfinclude template="../backend/business_home_metrics.cfm"/>
<cfinclude template="../backend/uptime_status.cfm"/>
<cfscript>
VARIABLES.businessHomeSignals = [];
for (VARIABLES.businessHomeQueueSignal in VARIABLES.businessAdminHomeQueue) {
    VARIABLES.businessHomeQueueSignal = duplicate(VARIABLES.businessHomeQueueSignal);
    VARIABLES.businessHomeQueueSignal.priority = VARIABLES.businessHomeQueueSignal.kind EQ "Operação" ? 10 : (VARIABLES.businessHomeQueueSignal.kind EQ "Aprovação" ? 20 : 30);
    if (VARIABLES.businessHomeQueueSignal.label EQ "Cadastros de conta") VARIABLES.businessHomeQueueSignal.label = "Contas para aprovar";
    if (VARIABLES.businessHomeQueueSignal.label EQ "Vínculos de eventos") VARIABLES.businessHomeQueueSignal.href = "/eventos/##event-request-panel";
    arrayAppend(VARIABLES.businessHomeSignals, VARIABLES.businessHomeQueueSignal);
}
arrayAppend(VARIABLES.businessHomeSignals,{kind="Infraestrutura",label="Rotinas com falha",description="Última execução terminou com erro",value=VARIABLES.businessAdminHomeCronErrors,loaded=VARIABLES.businessAdminHomeCronLoaded,href="/administracao/cron-jobs/?status=erro",icon="fa-clock",priority=5});
arrayAppend(VARIABLES.businessHomeSignals,{kind="Infraestrutura",label="Rotinas atrasadas",description="Aguardando execução há mais de 15 min",value=VARIABLES.businessAdminHomeCronOverdue,loaded=VARIABLES.businessAdminHomeCronLoaded,href="/administracao/cron-jobs/?status=vencidos",icon="fa-clock",priority=10});
if (VARIABLES.uptimeStatus.configured) {
    arrayAppend(VARIABLES.businessHomeSignals,{kind="Infraestrutura",label="Serviços indisponíveis",description="Monitores fora do ar ou instáveis",value=VARIABLES.uptimeStatus.down + VARIABLES.uptimeStatus.warning,loaded=VARIABLES.uptimeStatus.loaded,href="/administracao/status/",icon="fa-server",priority=1});
}
arrayAppend(VARIABLES.businessHomeSignals,{kind="Portal",label="Erros registrados",description="Ocorrências nos últimos 7 dias",value=VARIABLES.businessAdminHomePortalErrors,loaded=VARIABLES.businessAdminHomePortalLoaded,href="/portal/erros/?aba=logs&dias=7&item=erro",icon="fa-triangle-exclamation",priority=10});
arrayAppend(VARIABLES.businessHomeSignals,{kind="Portal",label="Páginas não encontradas",description="Respostas 404 nos últimos 7 dias",value=VARIABLES.businessAdminHomePortalNotFound,loaded=VARIABLES.businessAdminHomePortalLoaded,href="/portal/erros/?aba=logs&dias=7&item=404",icon="fa-file-circle-question",priority=35});
arrayAppend(VARIABLES.businessHomeSignals,{kind="Busca",label="Erros de interpretação",description="Falhas de busca nos últimos 30 dias",value=VARIABLES.businessAdminHomeSearchErrors,loaded=VARIABLES.businessAdminHomeSearchLoaded,href="/portal/busca/",icon="fa-magnifying-glass",priority=15});
arrayAppend(VARIABLES.businessHomeSignals,{kind="Busca",label="Buscas sem resultado",description="Consultas sem retorno nos últimos 30 dias",value=VARIABLES.businessAdminHomeSearchZeroResults,loaded=VARIABLES.businessAdminHomeSearchLoaded,href="/portal/busca/",icon="fa-magnifying-glass",priority=35});
for (VARIABLES.businessHomePaymentSignal in VARIABLES.businessAdminHomePayments) {
    arrayAppend(VARIABLES.businessHomeSignals,{kind="Pagamentos",label=VARIABLES.businessHomePaymentSignal.label,description=VARIABLES.businessHomePaymentSignal.description & " · conferir por conta",value=VARIABLES.businessHomePaymentSignal.value,loaded=VARIABLES.businessAdminHomeAdsPaymentsLoaded,href="/ads/?view=admin",icon=VARIABLES.businessHomePaymentSignal.icon,priority=5});
}
if (VARIABLES.businessAdminAiMailLoaded AND val(qBusinessAdminAiMail.errors) GT 0) {
    arrayAppend(VARIABLES.businessHomeSignals,{kind="Comunicação",label="Falhas de análise de AI-mails",description="Itens que não puderam ser analisados",value=val(qBusinessAdminAiMail.errors),loaded=true,href="/administracao/ai-mails/",icon="fa-envelope-circle-check",priority=10});
}
if (!VARIABLES.businessAdminHomeContentLoaded) {
    arrayAppend(VARIABLES.businessHomeSignals,{kind="Conteúdo",label="Qualidade dos eventos",description="Resumo de conteúdo indisponível",value=0,loaded=false,href="/portal/conteudo/",icon="fa-flag-checkered",priority=40});
}
</cfscript>
<link rel="stylesheet" href="/assets/css/admin-suite.css?v=20260917-aimails"/>
<link rel="stylesheet" href="/assets/css/admin-dashboard.css?v=20261024-decision1"/>
<div class="col-12 business-global-dashboard admin-suite-page" data-business-home>
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
    <cfinclude template="home_admin_decision_view.cfm"/>
</div>
<script src="/assets/js/business-home-dashboard.js?v=20261024-1" defer></script>
