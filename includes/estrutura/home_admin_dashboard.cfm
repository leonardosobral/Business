<cfset qBusinessAdminHomeStats = QueryNew("contas_ativas,contas_pendentes,usuarios_ativos,eventos_ativos,solicitacoes_cadastro,solicitacoes_eventos,campanhas_ativas")/>
<cfset qBusinessAdminHomeRegistrations = QueryNew("id_solicitacao,nome_empresa,tipo_prestador,email_responsavel,data_criacao")/>
<cfset qBusinessAdminHomeEventRequests = QueryNew("id_solicitacao,nome_conta,nome_evento,data_criacao")/>
<cfset qBusinessAdminHomeLegacyPartners = QueryNew("id,name,email,perfil,nome_comercial")/>
<cfset qBusinessAdminHomeContentGaps = QueryNew("id_evento,nome_evento,cidade,estado,tag,data_inicial,missing_count,faltando")/>
<cfset VARIABLES.businessAdminHomeReady = true/>
<cfset VARIABLES.businessAdminHomeError = ""/>
<cfset VARIABLES.businessAdminHomeTablesReady = false/>
<cfset VARIABLES.businessAdminHomeHasLogTable = false/>
<cfset VARIABLES.businessAdminHomeHasSearchTable = false/>
<cfset VARIABLES.businessAdminHomeHasFocoTables = false/>
<cfset VARIABLES.businessAdminHomeHasAgregaTables = false/>
<cfset VARIABLES.businessAdminHomeHasCronTables = false/>
<cfset VARIABLES.businessAdminHomeHasNotificationTable = false/>
<cfset VARIABLES.businessAdminHomeFocoPendingTotal = 0/>
<cfset VARIABLES.businessAdminHomeAgregaPendingTotal = 0/>
<cfset VARIABLES.businessAdminHomePortalErrors = 0/>
<cfset VARIABLES.businessAdminHomePortalNotFound = 0/>
<cfset VARIABLES.businessAdminHomePortalEventViews = 0/>
<cfset VARIABLES.businessAdminHomeSearchErrors = 0/>
<cfset VARIABLES.businessAdminHomeSearchZeroResults = 0/>
<cfset VARIABLES.businessAdminHomeContentIncomplete = 0/>
<cfset VARIABLES.businessAdminHomeContentCritical = 0/>
<cfset VARIABLES.businessAdminHomeContentNext30 = 0/>
<cfset VARIABLES.businessAdminHomeCronActive = 0/>
<cfset VARIABLES.businessAdminHomeCronDue = 0/>
<cfset VARIABLES.businessAdminHomeCronErrors = 0/>
<cfset VARIABLES.businessAdminHomeNotifications7d = 0/>
<cfset VARIABLES.businessAdminHomeNotificationsRead7d = 0/>
<cfset VARIABLES.businessAdminHomeNotificationReadRate7d = 0/>

<cftry>
    <cfquery name="qBusinessAdminHomeTableCheck">
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name IN (
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_contas"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_conta_usuarios"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_conta_eventos"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_conta_cadastro_solicitacoes"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_conta_evento_solicitacoes"/>,
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_ad_eventos"/>,
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
              <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_notifica"/>
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

<cfif VARIABLES.businessAdminHomeTablesReady>
    <cftry>
    <cfquery name="qBusinessAdminHomeStats">
        SELECT
            (SELECT count(*)::integer FROM tb_contas WHERE status::text = 'ATIVA') AS contas_ativas,
            (SELECT count(*)::integer FROM tb_contas WHERE status::text = 'PENDENTE') AS contas_pendentes,
            (SELECT count(*)::integer FROM tb_conta_usuarios WHERE status::text = 'ATIVO') AS usuarios_ativos,
            (SELECT count(*)::integer FROM tb_conta_eventos WHERE status::text = 'ATIVO') AS eventos_ativos,
            (SELECT count(*)::integer FROM tb_conta_cadastro_solicitacoes WHERE status::text = 'PENDENTE') AS solicitacoes_cadastro,
            (SELECT count(*)::integer FROM tb_conta_evento_solicitacoes WHERE status::text = 'PENDENTE') AS solicitacoes_eventos,
            (
                SELECT count(*)::integer
                FROM tb_ad_eventos
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
            <cfcatch type="any">
                <cfset VARIABLES.businessAdminHomeAgregaPendingTotal = 0/>
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
                count(*) FILTER (WHERE missing_count > 0)::integer AS incompletos,
                count(*) FILTER (WHERE missing_count >= 3)::integer AS criticos,
                count(*) FILTER (WHERE missing_count > 0 AND data_inicial <= current_date + interval '30 days')::integer AS proximos30
            FROM scored
        </cfquery>
        <cfset VARIABLES.businessAdminHomeContentIncomplete = val(qBusinessAdminHomeContentStats.incompletos)/>
        <cfset VARIABLES.businessAdminHomeContentCritical = val(qBusinessAdminHomeContentStats.criticos)/>
        <cfset VARIABLES.businessAdminHomeContentNext30 = val(qBusinessAdminHomeContentStats.proximos30)/>

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
                    (count(*) FILTER (WHERE ativo = true))::integer AS ativos,
                    (count(*) FILTER (WHERE ativo = true AND next_run_at <= now()))::integer AS vencidos,
                    (count(*) FILTER (WHERE lower(trim(coalesce(last_status, ''))) IN ('error', 'http_error', 'failed', 'timeout')))::integer AS erros
                FROM tb_cron_jobs
            </cfquery>
            <cfset VARIABLES.businessAdminHomeCronActive = val(qBusinessAdminHomeCronStats.ativos)/>
            <cfset VARIABLES.businessAdminHomeCronDue = val(qBusinessAdminHomeCronStats.vencidos)/>
            <cfset VARIABLES.businessAdminHomeCronErrors = val(qBusinessAdminHomeCronStats.erros)/>
            <cfcatch type="any">
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

<cfset VARIABLES.businessAdminHomeDecisionTotal = VARIABLES.businessAdminHomeFocoPendingTotal + VARIABLES.businessAdminHomeAgregaPendingTotal/>
<cfif qBusinessAdminHomeStats.recordcount>
    <cfset VARIABLES.businessAdminHomeDecisionTotal = VARIABLES.businessAdminHomeDecisionTotal + val(qBusinessAdminHomeStats.solicitacoes_cadastro) + val(qBusinessAdminHomeStats.solicitacoes_eventos)/>
</cfif>
<cfset VARIABLES.businessAdminHomePortalAttentionTotal = VARIABLES.businessAdminHomePortalErrors + VARIABLES.businessAdminHomePortalNotFound + VARIABLES.businessAdminHomeSearchErrors + VARIABLES.businessAdminHomeSearchZeroResults/>

<style>
    .business-admin-home .admin-home-panel {
        height: 100%;
    }

    .business-admin-home .admin-home-metric {
        min-height: 104px;
    }

    .business-admin-home .admin-home-list .list-group-item {
        border-color: rgba(255, 255, 255, .1);
    }

    .business-admin-home .admin-home-list .list-group-item:first-child {
        border-top: 0;
    }

    .business-admin-home .admin-home-list .list-group-item:last-child {
        border-bottom: 0;
    }

    .business-admin-home .admin-home-text {
        overflow-wrap: anywhere;
        word-break: break-word;
    }
</style>

<section class="col-12 business-admin-home business-page">
    <div class="card business-page-card">
        <div class="card-body business-page-body">
            <div class="business-page-header d-flex flex-column flex-lg-row justify-content-between align-items-lg-start gap-3 mb-3">
                <div>
                    <div class="text-warning fw-bold text-uppercase small">Admin interno</div>
                    <h3 class="business-page-title mb-1">Painel Business</h3>
                    <p class="text-muted mb-0">Cockpit operacional para decidir pendencias, acompanhar o portal e manter a base limpa.</p>
                </div>
                <div class="business-page-actions">
                    <a class="btn btn-sm btn-warning" href="/administracao/contas/">Contas</a>
                    <a class="btn btn-sm btn-outline-warning" href="/eventos/">Eventos</a>
                    <a class="btn btn-sm btn-outline-warning" href="/ads/">Ads</a>
                    <a class="btn btn-sm btn-outline-warning" href="/portal/conteudo/">Conteudo</a>
                    <a class="btn btn-sm btn-outline-warning" href="/notificacoes/">Notificacoes</a>
                </div>
            </div>

            <cfif VARIABLES.businessAdminHomeReady AND qBusinessAdminHomeStats.recordcount>
                <div class="row g-3">
                    <div class="col-6 col-xl-2">
                        <div class="admin-home-panel admin-home-metric">
                            <div class="admin-home-label">Fila aberta</div>
                            <div class="fs-3 fw-bold"><cfoutput>#LSNumberFormat(VARIABLES.businessAdminHomeDecisionTotal, "9,999")#</cfoutput></div>
                            <div class="small text-muted">itens para decisao</div>
                        </div>
                    </div>
                    <div class="col-6 col-xl-2">
                        <div class="admin-home-panel admin-home-metric">
                            <div class="admin-home-label">Contas ativas</div>
                            <div class="fs-3 fw-bold"><cfoutput>#LSNumberFormat(qBusinessAdminHomeStats.contas_ativas, "9,999")#</cfoutput></div>
                            <div class="small text-muted"><cfoutput>#LSNumberFormat(qBusinessAdminHomeStats.contas_pendentes, "9,999")# pendentes</cfoutput></div>
                        </div>
                    </div>
                    <div class="col-6 col-xl-2">
                        <div class="admin-home-panel admin-home-metric">
                            <div class="admin-home-label">Eventos ativos</div>
                            <div class="fs-3 fw-bold"><cfoutput>#LSNumberFormat(qBusinessAdminHomeStats.eventos_ativos, "9,999")#</cfoutput></div>
                            <div class="small text-muted">em contas</div>
                        </div>
                    </div>
                    <div class="col-6 col-xl-2">
                        <div class="admin-home-panel admin-home-metric">
                            <div class="admin-home-label">Conteudo</div>
                            <div class="fs-3 fw-bold"><cfoutput>#LSNumberFormat(VARIABLES.businessAdminHomeContentIncomplete, "9,999")#</cfoutput></div>
                            <div class="small text-muted">provas incompletas</div>
                        </div>
                    </div>
                    <div class="col-6 col-xl-2">
                        <div class="admin-home-panel admin-home-metric">
                            <div class="admin-home-label">Portal</div>
                            <div class="fs-3 fw-bold"><cfoutput>#LSNumberFormat(VARIABLES.businessAdminHomePortalAttentionTotal, "9,999")#</cfoutput></div>
                            <div class="small text-muted">sinais de atencao</div>
                        </div>
                    </div>
                    <div class="col-6 col-xl-2">
                        <div class="admin-home-panel admin-home-metric">
                            <div class="admin-home-label">Campanhas</div>
                            <div class="fs-3 fw-bold"><cfoutput>#LSNumberFormat(qBusinessAdminHomeStats.campanhas_ativas, "9,999")#</cfoutput></div>
                            <div class="small text-muted">ads ativos</div>
                        </div>
                    </div>
                </div>
            <cfelse>
                <div class="alert alert-warning mb-0">
                    Nao foi possivel carregar o resumo administrativo agora.
                    <cfif len(trim(VARIABLES.businessAdminHomeError))>
                        <span class="d-block small mt-1"><cfoutput>#htmlEditFormat(VARIABLES.businessAdminHomeError)#</cfoutput></span>
                    </cfif>
                </div>
            </cfif>
        </div>
    </div>
</section>

<cfif VARIABLES.businessAdminHomeReady>
    <section class="col-xl-5 business-admin-home business-page">
        <div class="card h-100 business-page-card">
            <div class="card-body business-page-body">
                <div class="d-flex justify-content-between align-items-start gap-3 mb-3">
                    <div>
                        <div class="admin-home-label mb-1">Agora</div>
                        <h5 class="mb-1">Fila de decisao</h5>
                        <div class="text-muted small">Itens que dependem de revisao humana.</div>
                    </div>
                    <span class="badge rounded-pill badge-warning"><cfoutput>#LSNumberFormat(VARIABLES.businessAdminHomeDecisionTotal, "9,999")#</cfoutput></span>
                </div>

                <div class="list-group list-group-light admin-home-list">
                    <a class="list-group-item list-group-item-action bg-transparent text-reset px-0 d-flex justify-content-between gap-3" href="/administracao/contas/">
                        <span>
                            <span class="fw-bold d-block">Cadastros de conta</span>
                            <span class="small text-muted">Empresas aguardando aprovacao</span>
                        </span>
                        <span class="fw-bold text-warning"><cfoutput>#LSNumberFormat(qBusinessAdminHomeStats.solicitacoes_cadastro, "9,999")#</cfoutput></span>
                    </a>
                    <a class="list-group-item list-group-item-action bg-transparent text-reset px-0 d-flex justify-content-between gap-3" href="/eventos/">
                        <span>
                            <span class="fw-bold d-block">Eventos solicitados</span>
                            <span class="small text-muted">Vinculos pedidos por contas</span>
                        </span>
                        <span class="fw-bold text-warning"><cfoutput>#LSNumberFormat(qBusinessAdminHomeStats.solicitacoes_eventos, "9,999")#</cfoutput></span>
                    </a>
                    <a class="list-group-item list-group-item-action bg-transparent text-reset px-0 d-flex justify-content-between gap-3" href="/administracao/foco-revisao/">
                        <span>
                            <span class="fw-bold d-block">Revisao Foco Radical</span>
                            <span class="small text-muted">Galerias candidatas sem vinculo final</span>
                        </span>
                        <span class="fw-bold text-warning"><cfoutput>#LSNumberFormat(VARIABLES.businessAdminHomeFocoPendingTotal, "9,999")#</cfoutput></span>
                    </a>
                    <a class="list-group-item list-group-item-action bg-transparent text-reset px-0 d-flex justify-content-between gap-3" href="/administracao/agrega-revisao/">
                        <span>
                            <span class="fw-bold d-block">Revisao de agregadores</span>
                            <span class="small text-muted">Edicoes parecidas para consolidar</span>
                        </span>
                        <span class="fw-bold text-warning"><cfoutput>#LSNumberFormat(VARIABLES.businessAdminHomeAgregaPendingTotal, "9,999")#</cfoutput></span>
                    </a>
                </div>
            </div>
        </div>
    </section>

    <section class="col-xl-4 business-admin-home business-page">
        <div class="card h-100 business-page-card">
            <div class="card-body business-page-body">
                <div class="d-flex justify-content-between align-items-start gap-3 mb-3">
                    <div>
                        <div class="admin-home-label mb-1">7/30 dias</div>
                        <h5 class="mb-1">Saude do portal</h5>
                        <div class="text-muted small">Erros, buscas e leitura real de eventos.</div>
                    </div>
                    <a class="btn btn-sm btn-outline-warning" href="/portal/erros/">Abrir</a>
                </div>

                <div class="row g-3">
                    <div class="col-6">
                        <div class="admin-home-panel">
                            <div class="admin-home-label">Erros 7d</div>
                            <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.businessAdminHomePortalErrors, "9,999")#</cfoutput></div>
                        </div>
                    </div>
                    <div class="col-6">
                        <div class="admin-home-panel">
                            <div class="admin-home-label">404 7d</div>
                            <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.businessAdminHomePortalNotFound, "9,999")#</cfoutput></div>
                        </div>
                    </div>
                    <div class="col-6">
                        <div class="admin-home-panel">
                            <div class="admin-home-label">Busca erro</div>
                            <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.businessAdminHomeSearchErrors, "9,999")#</cfoutput></div>
                            <div class="small text-muted">30 dias</div>
                        </div>
                    </div>
                    <div class="col-6">
                        <div class="admin-home-panel">
                            <div class="admin-home-label">Sem resultado</div>
                            <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.businessAdminHomeSearchZeroResults, "9,999")#</cfoutput></div>
                            <div class="small text-muted">30 dias</div>
                        </div>
                    </div>
                    <div class="col-12">
                        <div class="admin-home-panel d-flex justify-content-between align-items-center gap-3">
                            <div>
                                <div class="admin-home-label">Eventos visitados</div>
                                <div class="small text-muted">Pageviews de paginas de evento nos ultimos 7 dias</div>
                            </div>
                            <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.businessAdminHomePortalEventViews, "9,999")#</cfoutput></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <section class="col-xl-3 business-admin-home business-page">
        <div class="card h-100 business-page-card">
            <div class="card-body business-page-body">
                <div class="d-flex justify-content-between align-items-start gap-3 mb-3">
                    <div>
                        <div class="admin-home-label mb-1">Operacao</div>
                        <h5 class="mb-1">Manutencao</h5>
                        <div class="text-muted small">Jobs e notificacoes recentes.</div>
                    </div>
                    <a class="btn btn-sm btn-outline-warning" href="/administracao/cron-jobs/">Jobs</a>
                </div>

                <div class="list-group list-group-light admin-home-list">
                    <a class="list-group-item list-group-item-action bg-transparent text-reset px-0 d-flex justify-content-between gap-3" href="/administracao/cron-jobs/?status=vencidos">
                        <span>
                            <span class="fw-bold d-block">Cron jobs vencidos</span>
                            <span class="small text-muted"><cfoutput>#LSNumberFormat(VARIABLES.businessAdminHomeCronActive, "9,999")# ativos</cfoutput></span>
                        </span>
                        <span class="fw-bold text-warning"><cfoutput>#LSNumberFormat(VARIABLES.businessAdminHomeCronDue, "9,999")#</cfoutput></span>
                    </a>
                    <a class="list-group-item list-group-item-action bg-transparent text-reset px-0 d-flex justify-content-between gap-3" href="/administracao/cron-jobs/?status=erro">
                        <span>
                            <span class="fw-bold d-block">Jobs com erro</span>
                            <span class="small text-muted">Ultimo status de falha</span>
                        </span>
                        <span class="fw-bold text-warning"><cfoutput>#LSNumberFormat(VARIABLES.businessAdminHomeCronErrors, "9,999")#</cfoutput></span>
                    </a>
                    <a class="list-group-item list-group-item-action bg-transparent text-reset px-0 d-flex justify-content-between gap-3" href="/notificacoes/">
                        <span>
                            <span class="fw-bold d-block">Notificacoes 7d</span>
                            <span class="small text-muted"><cfoutput>#LSNumberFormat(VARIABLES.businessAdminHomeNotificationReadRate7d, "9.9")#% lidas</cfoutput></span>
                        </span>
                        <span class="fw-bold text-warning"><cfoutput>#LSNumberFormat(VARIABLES.businessAdminHomeNotifications7d, "9,999")#</cfoutput></span>
                    </a>
                </div>
            </div>
        </div>
    </section>

    <section class="col-12 business-admin-home business-page">
        <div class="card h-100 business-page-card">
            <div class="card-body business-page-body">
                <div class="d-flex flex-column flex-xl-row justify-content-between align-items-xl-start gap-3 mb-3">
                    <div>
                        <div class="admin-home-label mb-1">Proximos 90 dias</div>
                        <h5 class="mb-1">Conteudo incompleto</h5>
                        <div class="text-muted small">Provas ativas sem informacoes importantes para conversao e suporte.</div>
                    </div>
                    <div class="business-page-actions">
                        <span class="badge rounded-pill badge-warning"><cfoutput>#LSNumberFormat(VARIABLES.businessAdminHomeContentIncomplete, "9,999")# incompletas</cfoutput></span>
                        <span class="badge rounded-pill badge-danger"><cfoutput>#LSNumberFormat(VARIABLES.businessAdminHomeContentCritical, "9,999")# criticas</cfoutput></span>
                        <a class="btn btn-sm btn-outline-warning" href="/portal/conteudo/">Abrir KPI</a>
                    </div>
                </div>

                <cfif qBusinessAdminHomeContentGaps.recordcount>
                    <div class="table-responsive">
                        <table class="table table-sm align-middle mb-0 business-table">
                            <thead>
                                <tr>
                                    <th>Evento</th>
                                    <th>Data</th>
                                    <th>Local</th>
                                    <th>Faltando</th>
                                    <th class="text-end">Campos</th>
                                </tr>
                            </thead>
                            <tbody>
                                <cfoutput query="qBusinessAdminHomeContentGaps">
                                    <tr>
                                        <td class="admin-home-text">
                                            <a class="text-reset fw-bold" href="/portal/conteudo/?busca=#urlEncodedFormat(qBusinessAdminHomeContentGaps.tag)#">#htmlEditFormat(qBusinessAdminHomeContentGaps.nome_evento)#</a>
                                            <div class="small text-muted">#htmlEditFormat(qBusinessAdminHomeContentGaps.tag)#</div>
                                        </td>
                                        <td>#lsDateFormat(qBusinessAdminHomeContentGaps.data_inicial, "dd/mm/yyyy")#</td>
                                        <td>#htmlEditFormat(qBusinessAdminHomeContentGaps.cidade)#/#htmlEditFormat(qBusinessAdminHomeContentGaps.estado)#</td>
                                        <td class="admin-home-text small text-muted">#htmlEditFormat(qBusinessAdminHomeContentGaps.faltando)#</td>
                                        <td class="text-end fw-bold text-warning">#qBusinessAdminHomeContentGaps.missing_count#</td>
                                    </tr>
                                </cfoutput>
                            </tbody>
                        </table>
                    </div>
                <cfelse>
                    <p class="text-muted mb-0">Nenhuma prova incompleta nos proximos 90 dias.</p>
                </cfif>
            </div>
        </div>
    </section>

    <section class="col-xl-6 business-admin-home business-page">
        <div class="card h-100 business-page-card">
            <div class="card-body business-page-body">
                <div class="business-page-header d-flex justify-content-between align-items-center gap-3 mb-3">
                    <h5 class="mb-0">Cadastros pendentes</h5>
                    <a class="btn btn-sm btn-outline-warning" href="/administracao/contas/">Revisar</a>
                </div>

                <cfif qBusinessAdminHomeRegistrations.recordcount>
                    <div class="list-group list-group-light">
                        <cfoutput query="qBusinessAdminHomeRegistrations">
                            <a class="list-group-item list-group-item-action bg-transparent text-reset px-0" href="/administracao/contas/">
                                <div class="fw-bold">#htmlEditFormat(qBusinessAdminHomeRegistrations.nome_empresa)#</div>
                                <div class="small text-muted">#htmlEditFormat(qBusinessAdminHomeRegistrations.tipo_prestador)# - #htmlEditFormat(qBusinessAdminHomeRegistrations.email_responsavel)#</div>
                                <div class="small text-muted">#lsDateFormat(qBusinessAdminHomeRegistrations.data_criacao, "dd/mm/yyyy")# #lsTimeFormat(qBusinessAdminHomeRegistrations.data_criacao, "HH:mm")#</div>
                            </a>
                        </cfoutput>
                    </div>
                <cfelse>
                    <p class="text-muted mb-0">Nenhuma solicitacao de cadastro pendente.</p>
                </cfif>
            </div>
        </div>
    </section>

    <section class="col-xl-6 business-admin-home business-page">
        <div class="card h-100 business-page-card">
            <div class="card-body business-page-body">
                <div class="business-page-header d-flex justify-content-between align-items-center gap-3 mb-3">
                    <h5 class="mb-0">Eventos solicitados</h5>
                    <a class="btn btn-sm btn-outline-warning" href="/eventos/">Revisar</a>
                </div>

                <cfif qBusinessAdminHomeEventRequests.recordcount>
                    <div class="list-group list-group-light">
                        <cfoutput query="qBusinessAdminHomeEventRequests">
                            <a class="list-group-item list-group-item-action bg-transparent text-reset px-0" href="/eventos/">
                                <div class="fw-bold">#htmlEditFormat(qBusinessAdminHomeEventRequests.nome_evento)#</div>
                                <div class="small text-muted">#htmlEditFormat(qBusinessAdminHomeEventRequests.nome_conta)#</div>
                                <div class="small text-muted">#lsDateFormat(qBusinessAdminHomeEventRequests.data_criacao, "dd/mm/yyyy")# #lsTimeFormat(qBusinessAdminHomeEventRequests.data_criacao, "HH:mm")#</div>
                            </a>
                        </cfoutput>
                    </div>
                <cfelse>
                    <p class="text-muted mb-0">Nenhuma solicitacao de evento pendente.</p>
                </cfif>
            </div>
        </div>
    </section>

    <cfif qBusinessAdminHomeLegacyPartners.recordcount>
        <section class="col-12 business-admin-home business-page">
            <div class="card business-page-card">
                <div class="card-body business-page-body">
                    <div class="business-page-header d-flex justify-content-between align-items-center gap-3 mb-3">
                        <div>
                            <h5 class="mb-1">Usuarios legados com partner_info</h5>
                            <div class="text-muted small">Amostra para migracao ou limpeza gradual.</div>
                        </div>
                        <a class="btn btn-sm btn-outline-warning" href="/administracao/contas/">Gerenciar contas</a>
                    </div>
                    <div class="table-responsive">
                        <table class="table table-sm align-middle mb-0 business-table">
                            <thead>
                                <tr>
                                    <th>Usuario</th>
                                    <th>E-mail</th>
                                    <th>Perfil</th>
                                    <th>Nome comercial</th>
                                </tr>
                            </thead>
                            <tbody>
                                <cfoutput query="qBusinessAdminHomeLegacyPartners">
                                    <tr>
                                        <td>#htmlEditFormat(qBusinessAdminHomeLegacyPartners.name)#</td>
                                        <td>#htmlEditFormat(qBusinessAdminHomeLegacyPartners.email)#</td>
                                        <td>#htmlEditFormat(qBusinessAdminHomeLegacyPartners.perfil)#</td>
                                        <td>#htmlEditFormat(qBusinessAdminHomeLegacyPartners.nome_comercial)#</td>
                                    </tr>
                                </cfoutput>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </section>
    </cfif>
</cfif>
