<cfset VARIABLES.businessHomeAccountIds = "0"/>
<cfif isDefined("VARIABLES.businessEffectiveAccountIds")
    AND len(trim(VARIABLES.businessEffectiveAccountIds))
    AND VARIABLES.businessEffectiveAccountIds NEQ "0">
    <cfset VARIABLES.businessHomeAccountIds = VARIABLES.businessEffectiveAccountIds/>
</cfif>

<cfset VARIABLES.businessHomeDashboardReady = VARIABLES.businessHomeAccountIds NEQ "0"/>
<cfset VARIABLES.businessHomeDashboardError = ""/>
<cfset VARIABLES.businessHomeAccountTitle = "Conta Business"/>
<cfset VARIABLES.businessHomeAccountSubtitle = "Resumo da operacao da conta"/>
<cfset VARIABLES.businessHomeSaldoAds = 0/>
<cfset VARIABLES.businessHomeVouchersResgatados = 0/>
<cfset VARIABLES.businessHomeAdsAtivos = 0/>
<cfset VARIABLES.businessHomeAdsTotal = 0/>
<cfset VARIABLES.businessHomeAdsBudgetTotal = 0/>
<cfset VARIABLES.businessHomeAdsDailyLimit = 0/>
<cfset VARIABLES.businessHomeVoucherColumnsReady = false/>

<cfset qBusinessHomeAccounts = QueryNew("id_conta,nome_conta,status")/>
<cfset qBusinessHomeSummary = QueryNew("eventos_ativos,eventos_proximos,eventos_pendentes,usuarios_ativos,solicitacoes_pendentes")/>
<cfset qBusinessHomeUpcomingEvents = QueryNew("id_evento,nome_evento,tag,data_inicial,data_final,cidade,estado,status_vinculo,missing_count")/>
<cfset qBusinessHomeContentAttention = QueryNew("id_evento,nome_evento,tag,data_inicial,data_final,cidade,estado,has_descricao,has_inscricao,has_categorias,has_organizador,has_local,has_imagem,missing_count")/>
<cfset qBusinessHomeAdCampaigns = QueryNew("id_ad_evento,nome_evento,tag,status,cpc_max,limite_diario,limite_ad,inicio_ad,final_ad")/>

<cfif VARIABLES.businessHomeDashboardReady>
    <cftry>
        <cfquery name="qBusinessHomeAccounts">
            SELECT id_conta,
                   nome_conta,
                   status::text AS status
            FROM public.tb_contas
            WHERE id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessHomeAccountIds#" list="true"/>)
            ORDER BY nome_conta
        </cfquery>

        <cfif qBusinessHomeAccounts.recordcount EQ 1>
            <cfset VARIABLES.businessHomeAccountTitle = qBusinessHomeAccounts.nome_conta/>
            <cfset VARIABLES.businessHomeAccountSubtitle = "Conta " & lCase(qBusinessHomeAccounts.status)/>
        <cfelseif qBusinessHomeAccounts.recordcount GT 1>
            <cfset VARIABLES.businessHomeAccountTitle = qBusinessHomeAccounts.recordcount & " contas Business"/>
            <cfset VARIABLES.businessHomeAccountSubtitle = "Resumo consolidado das contas vinculadas"/>
        </cfif>

        <cfquery name="qBusinessHomeSummary">
            WITH event_summary AS (
                SELECT count(DISTINCT ce.id_evento) FILTER (WHERE ce.status::text = 'ATIVO') AS eventos_ativos,
                       count(DISTINCT ce.id_evento) FILTER (WHERE ce.status::text = 'ATIVO' AND evt.data_final >= current_date) AS eventos_proximos,
                       count(DISTINCT ce.id_evento) FILTER (WHERE ce.status::text <> 'ATIVO') AS eventos_pendentes
                FROM public.tb_conta_eventos ce
                INNER JOIN public.tb_evento_corridas evt ON evt.id_evento = ce.id_evento
                WHERE ce.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessHomeAccountIds#" list="true"/>)
            ),
            user_summary AS (
                SELECT count(DISTINCT cu.id_usuario) FILTER (WHERE cu.status::text = 'ATIVO') AS usuarios_ativos
                FROM tb_conta_usuarios cu
                WHERE cu.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessHomeAccountIds#" list="true"/>)
            ),
            request_summary AS (
                SELECT count(*) AS solicitacoes_pendentes
                FROM tb_conta_evento_solicitacoes
                WHERE id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessHomeAccountIds#" list="true"/>)
                  AND status::text = 'PENDENTE'
            )
            SELECT coalesce(event_summary.eventos_ativos, 0) AS eventos_ativos,
                   coalesce(event_summary.eventos_proximos, 0) AS eventos_proximos,
                   coalesce(event_summary.eventos_pendentes, 0) AS eventos_pendentes,
                   coalesce(user_summary.usuarios_ativos, 0) AS usuarios_ativos,
                   coalesce(request_summary.solicitacoes_pendentes, 0) AS solicitacoes_pendentes
            FROM event_summary, user_summary, request_summary
        </cfquery>

        <cfquery name="qBusinessHomeUpcomingEvents">
            WITH linked_events AS (
                SELECT DISTINCT id_evento
                FROM public.tb_conta_eventos
                WHERE id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessHomeAccountIds#" list="true"/>)
                  AND status::text = 'ATIVO'
            )
            SELECT evt.id_evento,
                   evt.nome_evento,
                   evt.tag,
                   evt.data_inicial,
                   evt.data_final,
                   evt.cidade,
                   evt.estado,
                   'ATIVO' AS status_vinculo,
                   (
                       CASE WHEN length(trim(coalesce(evt.descricao, ''))) > 0 THEN 0 ELSE 1 END +
                       CASE WHEN length(trim(coalesce(evt.url_inscricao, evt.url_hotsite, ''))) > 0 THEN 0 ELSE 1 END +
                       CASE WHEN length(trim(coalesce(evt.categorias, ''))) > 0 THEN 0 ELSE 1 END +
                       CASE WHEN length(trim(coalesce(evt.organizador, evt.realizacao, ''))) > 0 THEN 0 ELSE 1 END +
                       CASE WHEN length(trim(coalesce(evt.cidade, ''))) > 0 AND length(trim(coalesce(evt.estado, ''))) > 0 THEN 0 ELSE 1 END +
                       CASE WHEN length(trim(coalesce(evt.imagem, evt.url_imagem, evt.url_imagem_listagem, ''))) > 0 THEN 0 ELSE 1 END
                   ) AS missing_count
            FROM linked_events ce
            INNER JOIN public.tb_evento_corridas evt ON evt.id_evento = ce.id_evento
            WHERE evt.ativo = true
              AND evt.data_final >= current_date
            ORDER BY evt.data_inicial ASC, evt.nome_evento
            LIMIT 8
        </cfquery>

        <cfquery name="qBusinessHomeContentAttention">
            WITH linked_events AS (
                SELECT DISTINCT id_evento
                FROM public.tb_conta_eventos
                WHERE id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessHomeAccountIds#" list="true"/>)
                  AND status::text = 'ATIVO'
            ),
            base AS (
                SELECT evt.id_evento,
                       evt.nome_evento,
                       evt.tag,
                       evt.data_inicial,
                       evt.data_final,
                       evt.cidade,
                       evt.estado,
                       CASE WHEN length(trim(coalesce(evt.descricao, ''))) > 0 THEN 1 ELSE 0 END AS has_descricao,
                       CASE WHEN length(trim(coalesce(evt.url_inscricao, evt.url_hotsite, ''))) > 0 THEN 1 ELSE 0 END AS has_inscricao,
                       CASE WHEN length(trim(coalesce(evt.categorias, ''))) > 0 THEN 1 ELSE 0 END AS has_categorias,
                       CASE WHEN length(trim(coalesce(evt.organizador, evt.realizacao, ''))) > 0 THEN 1 ELSE 0 END AS has_organizador,
                       CASE WHEN length(trim(coalesce(evt.cidade, ''))) > 0 AND length(trim(coalesce(evt.estado, ''))) > 0 THEN 1 ELSE 0 END AS has_local,
                       CASE WHEN length(trim(coalesce(evt.imagem, evt.url_imagem, evt.url_imagem_listagem, ''))) > 0 THEN 1 ELSE 0 END AS has_imagem
                FROM linked_events ce
                INNER JOIN public.tb_evento_corridas evt ON evt.id_evento = ce.id_evento
                WHERE evt.ativo = true
                  AND evt.data_final >= current_date
            ),
            scored AS (
                SELECT *,
                       (6 - (has_descricao + has_inscricao + has_categorias + has_organizador + has_local + has_imagem)) AS missing_count
                FROM base
            )
            SELECT *
            FROM scored
            WHERE missing_count > 0
            ORDER BY data_inicial ASC, missing_count DESC, nome_evento
            LIMIT 8
        </cfquery>

        <cfcatch type="any">
            <cfset VARIABLES.businessHomeDashboardReady = false/>
            <cfset VARIABLES.businessHomeDashboardError = cfcatch.message/>
        </cfcatch>
    </cftry>

    <cftry>
        <cfquery name="qBusinessHomeMarketingSummary" datasource="runnerhub">
            WITH wallet AS (
                SELECT coalesce(sum(available_balance), 0) AS saldo_ads
                FROM ads.account_balances
                WHERE account_id IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessHomeAccountIds#" list="true"/>)
            ), vouchers AS (
                SELECT count(*) AS vouchers_resgatados
                FROM ads.credit_ledger
                WHERE account_id IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessHomeAccountIds#" list="true"/>)
                  AND source_type='VOUCHER' AND entry_type='CREDIT'
            ), campaigns AS (
                SELECT count(*) AS ads_total,
                       count(*) FILTER (WHERE status='ACTIVE') AS ads_ativos,
                       coalesce(sum(budget_total) FILTER (WHERE status IN ('ACTIVE','PAUSED','DRAFT')),0) AS ads_budget_total,
                       coalesce(sum(budget_daily) FILTER (WHERE status='ACTIVE'),0) AS ads_daily_limit
                FROM ads.campaigns c
                WHERE account_id IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessHomeAccountIds#" list="true"/>)
                  AND billing_model='CPC'
                  AND EXISTS(SELECT 1 FROM ads.advertisements a WHERE a.campaign_id=c.campaign_id AND a.ad_type='EVENT')
            )
            SELECT wallet.saldo_ads,vouchers.vouchers_resgatados,campaigns.*
            FROM wallet,vouchers,campaigns
        </cfquery>

        <cfif qBusinessHomeMarketingSummary.recordcount>
            <cfset VARIABLES.businessHomeSaldoAds = val(qBusinessHomeMarketingSummary.saldo_ads)/>
            <cfset VARIABLES.businessHomeVouchersResgatados = val(qBusinessHomeMarketingSummary.vouchers_resgatados)/>
            <cfset VARIABLES.businessHomeAdsTotal = val(qBusinessHomeMarketingSummary.ads_total)/>
            <cfset VARIABLES.businessHomeAdsAtivos = val(qBusinessHomeMarketingSummary.ads_ativos)/>
            <cfset VARIABLES.businessHomeAdsBudgetTotal = val(qBusinessHomeMarketingSummary.ads_budget_total)/>
            <cfset VARIABLES.businessHomeAdsDailyLimit = val(qBusinessHomeMarketingSummary.ads_daily_limit)/>
        </cfif>

        <cfquery name="qBusinessHomeAdCampaigns" datasource="runnerhub">
            SELECT campaign.campaign_id AS id_ad_evento,campaign.name AS nome_evento,
                   campaign.status,campaign.cpc_bid AS cpc_max,campaign.budget_daily AS limite_diario,
                   campaign.budget_total AS limite_ad,campaign.starts_at AS inicio_ad,campaign.ends_at AS final_ad,
                   (campaign.status IN ('ACTIVE','PAUSED') AND coalesce(budget.spent_total,0)+campaign.cpc_bid > campaign.budget_total) AS budget_exhausted
            FROM ads.campaigns campaign
            LEFT JOIN ads.campaign_budget_state budget ON budget.campaign_id=campaign.campaign_id
            WHERE campaign.account_id IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessHomeAccountIds#" list="true"/>)
              AND campaign.billing_model='CPC'
              AND EXISTS(SELECT 1 FROM ads.advertisements a WHERE a.campaign_id=campaign.campaign_id AND a.ad_type='EVENT')
            ORDER BY CASE campaign.status WHEN 'ACTIVE' THEN 0 WHEN 'PAUSED' THEN 1 WHEN 'DRAFT' THEN 2 ELSE 3 END,
                     campaign.updated_at DESC
            LIMIT 5
        </cfquery>

        <cfcatch type="any">
            <cfset VARIABLES.businessHomeSaldoAds = 0/>
            <cfset VARIABLES.businessHomeVouchersResgatados = 0/>
            <cfset VARIABLES.businessHomeAdsTotal = 0/>
            <cfset VARIABLES.businessHomeAdsAtivos = 0/>
            <cfset VARIABLES.businessHomeAdsBudgetTotal = 0/>
            <cfset VARIABLES.businessHomeAdsDailyLimit = 0/>
            <cfset qBusinessHomeAdCampaigns = QueryNew("id_ad_evento,nome_evento,tag,status,cpc_max,limite_diario,limite_ad,inicio_ad,final_ad")/>
        </cfcatch>
    </cftry>
</cfif>

<cfif VARIABLES.businessHomeDashboardReady>
    <cfset VARIABLES.businessHomeActiveEvents = 0/>
    <cfset VARIABLES.businessHomeUpcomingEventsCount = 0/>
    <cfset VARIABLES.businessHomePendingItems = 0/>
    <cfif qBusinessHomeSummary.recordcount>
        <cfset VARIABLES.businessHomeActiveEvents = val(qBusinessHomeSummary.eventos_ativos)/>
        <cfset VARIABLES.businessHomeUpcomingEventsCount = val(qBusinessHomeSummary.eventos_proximos)/>
        <cfset VARIABLES.businessHomePendingItems = val(qBusinessHomeSummary.solicitacoes_pendentes) + val(qBusinessHomeSummary.eventos_pendentes)/>
    </cfif>
    <cfset VARIABLES.businessHomeHasActiveEvents = VARIABLES.businessHomeActiveEvents GT 0/>
    <cfset VARIABLES.businessHomeHasPendingEvents = VARIABLES.businessHomePendingItems GT 0/>
    <cfset VARIABLES.businessHomeHasContentPending = qBusinessHomeContentAttention.recordcount GT 0/>
    <cfset VARIABLES.businessHomeContentReady = VARIABLES.businessHomeHasActiveEvents AND NOT VARIABLES.businessHomeHasContentPending/>
    <cfset VARIABLES.businessHomeMarketingStarted = VARIABLES.businessHomeAdsTotal GT 0 OR VARIABLES.businessHomeVouchersResgatados GT 0/>
    <cfset VARIABLES.businessHomeActivationScore = 0/>
    <cfif VARIABLES.businessHomeHasActiveEvents>
        <cfset VARIABLES.businessHomeActivationScore = VARIABLES.businessHomeActivationScore + 1/>
    </cfif>
    <cfif VARIABLES.businessHomeContentReady>
        <cfset VARIABLES.businessHomeActivationScore = VARIABLES.businessHomeActivationScore + 1/>
    </cfif>
    <cfif VARIABLES.businessHomeMarketingStarted>
        <cfset VARIABLES.businessHomeActivationScore = VARIABLES.businessHomeActivationScore + 1/>
    </cfif>
    <cfset VARIABLES.businessHomeFirstEventId = ""/>
    <cfif qBusinessHomeUpcomingEvents.recordcount>
        <cfset VARIABLES.businessHomeFirstEventId = qBusinessHomeUpcomingEvents.id_evento/>
    </cfif>
    <cfset VARIABLES.businessHomeFirstContentEventId = VARIABLES.businessHomeFirstEventId/>
    <cfif qBusinessHomeContentAttention.recordcount>
        <cfset VARIABLES.businessHomeFirstContentEventId = qBusinessHomeContentAttention.id_evento/>
    </cfif>

    <style>
        .business-account-dashboard .dashboard-kpi {
            min-height: 120px;
        }

        .business-account-dashboard .dashboard-kpi-value {
            font-size: 1.7rem;
            font-weight: 700;
            line-height: 1;
        }

        .business-account-dashboard .dashboard-list {
            display: grid;
            gap: .75rem;
        }

        .business-account-dashboard .dashboard-list-limited {
            max-height: 245px;
            overflow-y: auto;
            padding-right: .25rem;
        }

        .business-account-dashboard .dashboard-list-limited:not(.is-expanded) {
            max-height: none;
            overflow: visible;
            padding-right: 0;
        }

        .business-account-dashboard .dashboard-list-limited:not(.is-expanded) .dashboard-list-item:nth-child(n+3) {
            display: none;
        }

        .business-account-dashboard .dashboard-list-item {
            border-top: 1px solid rgba(255,255,255,.08);
            padding-top: .75rem;
        }

        .business-account-dashboard .dashboard-list-item:first-child {
            border-top: 0;
            padding-top: 0;
        }

        .business-account-dashboard .dashboard-actions {
            display: flex;
            flex-wrap: wrap;
            gap: .5rem;
        }

        .business-account-dashboard .dashboard-list-toggle {
            border: 0;
            background: transparent;
            color: var(--mdb-warning);
            font-size: .85rem;
            font-weight: 700;
            padding: .75rem 0 0;
        }

        .business-account-dashboard .dashboard-first-action {
            display: grid;
            grid-template-columns: minmax(0, 1fr) auto;
            gap: 1rem;
            align-items: center;
            border: 1px solid rgba(244,177,32,.38);
            border-radius: .5rem;
            background: rgba(244,177,32,.06);
            padding: 1rem;
        }

        .business-account-dashboard .dashboard-next-list {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: .5rem;
            margin-top: .75rem;
        }

        .business-account-dashboard .dashboard-next-item {
            border: 1px solid rgba(255,255,255,.1);
            border-radius: .5rem;
            background: rgba(255,255,255,.025);
            padding: .75rem;
            color: var(--mdb-secondary-color);
        }

        .business-account-dashboard .dashboard-operational-empty {
            border: 1px solid rgba(255,255,255,.1);
            border-radius: .5rem;
            background: rgba(255,255,255,.025);
            padding: 1rem;
        }

        @media (max-width: 991.98px) {
            .business-account-dashboard .dashboard-first-action,
            .business-account-dashboard .dashboard-next-list {
                grid-template-columns: 1fr;
            }
        }
    </style>

    <section class="business-account-dashboard business-page mb-4">
        <div class="d-flex flex-column flex-lg-row justify-content-between align-items-lg-end gap-3 mb-3">
            <div>
                <cfoutput>
                    <div class="text-warning fw-bold text-uppercase small">Dashboard da conta</div>
                    <h3 class="mb-1">#encodeForHTML(VARIABLES.businessHomeAccountTitle)#</h3>
                    <p class="text-muted mb-0">#encodeForHTML(VARIABLES.businessHomeAccountSubtitle)#</p>
                </cfoutput>
            </div>
            <div class="dashboard-actions">
                <a class="btn btn-outline-light btn-sm" href="/eventos/"><i class="fa-solid fa-person-running me-2"></i>Eventos</a>
                <cfif VARIABLES.businessHomeHasActiveEvents>
                    <a class="btn btn-outline-light btn-sm" href="/ads/"><i class="fa-solid fa-rectangle-ad me-2"></i>Publicidade</a>
                    <a class="btn btn-outline-light btn-sm" href="/inscricoes/"><i class="fa-solid fa-ticket me-2"></i>Inscrições</a>
                </cfif>
            </div>
        </div>

        <div class="card business-page-card mb-3">
            <div class="card-body business-page-body">
                <div class="business-page-header d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
                    <div>
                        <div class="business-label mb-1">Comece por aqui</div>
                        <h4 class="mb-1">Ative a operação da sua conta</h4>
                        <p class="text-muted mb-0">Siga o próximo passo disponível para liberar eventos, conteúdo, divulgação e acompanhamento comercial.</p>
                    </div>
                    <span class="badge rounded-pill badge-warning align-self-lg-start">
                        <cfif VARIABLES.businessHomeHasActiveEvents>
                            <cfoutput>#VARIABLES.businessHomeActivationScore#</cfoutput>/3 etapas concluídas
                        <cfelseif VARIABLES.businessHomeHasPendingEvents>
                            Em análise
                        <cfelse>
                            Primeiro passo
                        </cfif>
                    </span>
                </div>

                <cfif NOT VARIABLES.businessHomeHasActiveEvents>
                    <div class="dashboard-first-action">
                        <div>
                            <h5 class="mb-2"><cfif VARIABLES.businessHomeHasPendingEvents>Pedido de vínculo em análise<cfelse>Vincule a primeira prova</cfif></h5>
                            <p class="text-muted mb-0">
                                <cfif VARIABLES.businessHomeHasPendingEvents>
                                    Assim que a aprovação sair, a home libera conteúdo, marketing e acompanhamento comercial.
                                <cfelse>
                                    Encontre a prova no RoadRunners e peça o vínculo com esta conta para começar a operar.
                                </cfif>
                            </p>
                        </div>
                        <a class="btn btn-warning" href="/eventos/#primeiro-evento">
                            <cfif VARIABLES.businessHomeHasPendingEvents>Acompanhar pedido<cfelse>Solicitar vínculo</cfif>
                        </a>
                    </div>

                    <div class="dashboard-next-list">
                        <div class="dashboard-next-item">
                            <div class="fw-bold mb-1">Depois: conteúdo</div>
                            <div class="small">Complete página, inscrição, local e imagem.</div>
                        </div>
                        <div class="dashboard-next-item">
                            <div class="fw-bold mb-1">Depois: divulgação</div>
                            <div class="small">Crie campanhas e cupons quando houver evento.</div>
                        </div>
                        <div class="dashboard-next-item">
                            <div class="fw-bold mb-1">Depois: vendas</div>
                            <div class="small">Acompanhe inscrições e sinais comerciais.</div>
                        </div>
                    </div>
                <cfelse>
                    <div class="business-step-grid">
                        <div class="business-step is-complete">
                            <div class="business-step-top">
                                <span class="business-step-marker"><i class="fa-solid fa-check"></i></span>
                                <span class="business-step-status">Concluído</span>
                            </div>
                            <h5 class="mb-2">Evento vinculado</h5>
                            <p class="text-muted mb-0">Sua conta já possui eventos ativos para operar.</p>
                            <div class="business-step-action">
                                <a class="btn btn-sm btn-outline-warning w-100" href="/eventos/">Ver eventos</a>
                            </div>
                        </div>

                        <div class="business-step <cfif VARIABLES.businessHomeContentReady>is-complete<cfelse>is-current</cfif>">
                            <div class="business-step-top">
                                <span class="business-step-marker"><cfif VARIABLES.businessHomeContentReady><i class="fa-solid fa-check"></i><cfelse>2</cfif></span>
                                <span class="business-step-status"><cfif VARIABLES.businessHomeContentReady>Concluído<cfelse>Pendente</cfif></span>
                            </div>
                            <h5 class="mb-2">Completar a página</h5>
                            <p class="text-muted mb-0"><cfif VARIABLES.businessHomeContentReady>As próximas provas estão com o conteúdo principal completo.<cfelse>Complete inscrição, descrição, local, organizador e imagem.</cfif></p>
                            <div class="business-step-action">
                                <cfif len(trim(VARIABLES.businessHomeFirstContentEventId))>
                                    <cfoutput><a class="btn btn-sm <cfif VARIABLES.businessHomeContentReady>btn-outline-warning<cfelse>btn-warning</cfif> w-100" href="/eventos/?id_evento=#VARIABLES.businessHomeFirstContentEventId#"><cfif VARIABLES.businessHomeContentReady>Revisar conteúdo<cfelse>Completar agora</cfif></a></cfoutput>
                                <cfelse>
                                    <a class="btn btn-sm btn-outline-warning w-100" href="/eventos/">Revisar eventos</a>
                                </cfif>
                            </div>
                        </div>

                        <div class="business-step <cfif VARIABLES.businessHomeMarketingStarted>is-complete<cfelse>is-current</cfif>">
                            <div class="business-step-top">
                                <span class="business-step-marker"><cfif VARIABLES.businessHomeMarketingStarted><i class="fa-solid fa-check"></i><cfelse>3</cfif></span>
                                <span class="business-step-status"><cfif VARIABLES.businessHomeMarketingStarted>Ativo<cfelse>Disponível</cfif></span>
                            </div>
                            <h5 class="mb-2">Divulgar e vender</h5>
                            <p class="text-muted mb-0"><cfif VARIABLES.businessHomeMarketingStarted>Já existe crédito, voucher ou campanha conectado à conta.<cfelse>Use Publicidade, Cupons e Inscrições para acompanhar a operação.</cfif></p>
                            <div class="business-step-action d-grid gap-2">
                                <a class="btn btn-sm btn-warning" href="/ads/">Publicidade</a>
                                <a class="btn btn-sm btn-outline-warning" href="/inscricoes/">Ver inscrições</a>
                            </div>
                        </div>
                    </div>
                </cfif>
            </div>
        </div>

        <cfif VARIABLES.businessHomeHasActiveEvents>
            <div class="row g-3 mb-3">
                <div class="col-6 col-xl">
                    <div class="card dashboard-kpi">
                        <div class="card-body p-3">
                            <div class="text-muted small">Eventos ativos</div>
                            <div class="dashboard-kpi-value mt-2"><cfoutput>#numberFormat(val(qBusinessHomeSummary.eventos_ativos), "9,999")#</cfoutput></div>
                            <div class="small text-muted mt-2"><cfoutput>#numberFormat(val(qBusinessHomeSummary.eventos_proximos), "9,999")# próximos</cfoutput></div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-xl">
                    <div class="card dashboard-kpi">
                        <div class="card-body p-3">
                            <div class="text-muted small">Usuários</div>
                            <div class="dashboard-kpi-value mt-2"><cfoutput>#numberFormat(val(qBusinessHomeSummary.usuarios_ativos), "9,999")#</cfoutput></div>
                            <div class="small text-muted mt-2">ativos na conta</div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-xl">
                    <div class="card dashboard-kpi">
                        <div class="card-body p-3">
                            <div class="text-muted small">Saldo de publicidade</div>
                            <div class="dashboard-kpi-value mt-2"><cfoutput>#lsCurrencyFormat(VARIABLES.businessHomeSaldoAds)#</cfoutput></div>
                            <div class="small text-muted mt-2"><cfoutput>#numberFormat(VARIABLES.businessHomeVouchersResgatados, "9,999")# vouchers</cfoutput></div>
                        </div>
                    </div>
                </div>
                <div class="col-6 col-xl">
                    <div class="card dashboard-kpi">
                        <div class="card-body p-3">
                            <div class="text-muted small">Campanhas</div>
                            <div class="dashboard-kpi-value mt-2"><cfoutput>#numberFormat(VARIABLES.businessHomeAdsAtivos, "9,999")#</cfoutput></div>
                            <div class="small text-muted mt-2"><cfoutput>#lsCurrencyFormat(VARIABLES.businessHomeAdsBudgetTotal)# planejado</cfoutput></div>
                        </div>
                    </div>
                </div>
                <div class="col-12 col-xl">
                    <div class="card dashboard-kpi">
                        <div class="card-body p-3">
                            <div class="text-muted small">Pendências</div>
                            <div class="dashboard-kpi-value mt-2"><cfoutput>#numberFormat(val(qBusinessHomeSummary.solicitacoes_pendentes) + val(qBusinessHomeSummary.eventos_pendentes), "9,999")#</cfoutput></div>
                            <div class="small text-muted mt-2">vínculos e solicitações</div>
                        </div>
                    </div>
                </div>
            </div>
        <cfelse>
            <div class="dashboard-operational-empty mb-3">
                <div class="d-flex flex-column flex-lg-row justify-content-between gap-2 align-items-lg-center">
                    <div>
                        <h5 class="mb-1">Operação ainda não liberada</h5>
                        <p class="text-muted mb-0">Métricas, campanhas e vendas aparecem aqui depois que uma prova estiver vinculada e aprovada.</p>
                    </div>
                    <a class="btn btn-sm btn-outline-warning" href="/eventos/#primeiro-evento">Abrir eventos</a>
                </div>
            </div>
        </cfif>

        <cfif VARIABLES.businessHomeHasActiveEvents>
        <div class="row g-3">
            <div class="col-xl-6">
                <div class="card h-100">
                    <div class="card-body p-3">
                        <div class="d-flex justify-content-between align-items-center mb-3">
                            <h5 class="mb-0">Proximas provas</h5>
                            <a class="btn btn-sm btn-outline-warning" href="/eventos/">Ver eventos</a>
                        </div>

                        <cfif qBusinessHomeUpcomingEvents.recordcount>
                            <div class="dashboard-list dashboard-list-limited" id="businessHomeUpcomingList">
                                <cfoutput query="qBusinessHomeUpcomingEvents">
                                    <div class="dashboard-list-item">
                                        <div class="d-flex justify-content-between gap-3">
                                            <div>
                                                <div class="fw-bold">#encodeForHTML(qBusinessHomeUpcomingEvents.nome_evento)#</div>
                                                <div class="small text-muted">
                                                    #dateFormat(qBusinessHomeUpcomingEvents.data_inicial, "dd/mm/yyyy")#
                                                    <cfif len(trim(qBusinessHomeUpcomingEvents.cidade)) OR len(trim(qBusinessHomeUpcomingEvents.estado))>
                                                        - #encodeForHTML(qBusinessHomeUpcomingEvents.cidade)#<cfif len(trim(qBusinessHomeUpcomingEvents.estado))>/#encodeForHTML(qBusinessHomeUpcomingEvents.estado)#</cfif>
                                                    </cfif>
                                                </div>
                                            </div>
                                            <span class="badge bg-success align-self-start">#encodeForHTML(qBusinessHomeUpcomingEvents.status_vinculo)#</span>
                                        </div>
                                        <div class="dashboard-actions mt-2">
                                            <a class="btn btn-sm btn-dark" href="/eventos/?id_evento=#qBusinessHomeUpcomingEvents.id_evento#">Editar</a>
                                            <a class="btn btn-sm btn-dark" href="/ads/">Nova campanha</a>
                                        </div>
                                    </div>
                                </cfoutput>
                            </div>
                            <cfif qBusinessHomeUpcomingEvents.recordcount GT 2>
                                <button class="dashboard-list-toggle" type="button" data-business-list-toggle="businessHomeUpcomingList" data-label-open="Ver menos" data-label-closed="Ver mais">
                                    Ver mais
                                </button>
                            </cfif>
                        <cfelse>
                            <p class="text-muted mb-0">Nenhuma prova futura vinculada a esta conta.</p>
                        </cfif>
                    </div>
                </div>
            </div>

            <div class="col-xl-6">
                <div class="card h-100">
                    <div class="card-body p-3">
                        <div class="d-flex justify-content-between align-items-center mb-3">
                            <h5 class="mb-0">Completar conteudo</h5>
                            <a class="btn btn-sm btn-outline-warning" href="/portal/conteudo/">Ver conteudo</a>
                        </div>

                        <cfif qBusinessHomeContentAttention.recordcount>
                            <div class="dashboard-list dashboard-list-limited" id="businessHomeContentList">
                                <cfoutput query="qBusinessHomeContentAttention">
                                    <div class="dashboard-list-item">
                                        <div class="fw-bold">#encodeForHTML(qBusinessHomeContentAttention.nome_evento)#</div>
                                        <div class="small text-muted mb-2">#numberFormat(qBusinessHomeContentAttention.missing_count, "9")# campos pendentes</div>
                                        <div class="dashboard-actions">
                                            <cfif NOT val(qBusinessHomeContentAttention.has_descricao)><span class="badge bg-warning text-dark">Descricao</span></cfif>
                                            <cfif NOT val(qBusinessHomeContentAttention.has_inscricao)><span class="badge bg-warning text-dark">Inscricao</span></cfif>
                                            <cfif NOT val(qBusinessHomeContentAttention.has_categorias)><span class="badge bg-warning text-dark">Categorias</span></cfif>
                                            <cfif NOT val(qBusinessHomeContentAttention.has_organizador)><span class="badge bg-warning text-dark">Organizador</span></cfif>
                                            <cfif NOT val(qBusinessHomeContentAttention.has_local)><span class="badge bg-warning text-dark">Local</span></cfif>
                                            <cfif NOT val(qBusinessHomeContentAttention.has_imagem)><span class="badge bg-warning text-dark">Imagem</span></cfif>
                                        </div>
                                        <div class="dashboard-actions mt-2">
                                            <a class="btn btn-sm btn-dark" href="/eventos/?id_evento=#qBusinessHomeContentAttention.id_evento#">Atualizar prova</a>
                                        </div>
                                    </div>
                                </cfoutput>
                            </div>
                            <cfif qBusinessHomeContentAttention.recordcount GT 2>
                                <button class="dashboard-list-toggle" type="button" data-business-list-toggle="businessHomeContentList" data-label-open="Ver menos" data-label-closed="Ver mais">
                                    Ver mais
                                </button>
                            </cfif>
                        <cfelse>
                            <p class="text-muted mb-0">As proximas provas vinculadas estao com o conteudo principal completo.</p>
                        </cfif>
                    </div>
                </div>
            </div>

            <div class="col-xl-12">
                <div class="card">
                    <div class="card-body p-3">
                        <div class="d-flex flex-column flex-lg-row justify-content-between gap-2 mb-3">
                            <div>
                                <h5 class="mb-1">Marketing e vendas</h5>
                                <div class="text-muted small">O saldo da conta é compartilhado entre campanhas de eventos e banners. Cada campanha tem seu próprio limite de investimento.</div>
                            </div>
                            <div class="dashboard-actions">
                                <a class="btn btn-sm btn-warning" href="/ads/">Nova campanha</a>
                                <a class="btn btn-sm btn-outline-warning" href="/cupons-rr/">Cupons</a>
                            </div>
                        </div>

                        <div class="row g-2 mb-3">
                            <div class="col-md-4">
                                <div class="border rounded p-2 h-100">
                                    <div class="text-muted small">Credito disponivel</div>
                                    <div class="fw-bold"><cfoutput>#lsCurrencyFormat(VARIABLES.businessHomeSaldoAds)#</cfoutput></div>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="border rounded p-2 h-100">
                                    <div class="text-muted small">Orcamento planejado</div>
                                    <div class="fw-bold"><cfoutput>#lsCurrencyFormat(VARIABLES.businessHomeAdsBudgetTotal)#</cfoutput></div>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="border rounded p-2 h-100">
                                    <div class="text-muted small">Limite diario ativo</div>
                                    <div class="fw-bold"><cfif VARIABLES.businessHomeAdsAtivos EQ 0>Sem campanhas ativas<cfelseif VARIABLES.businessHomeAdsDailyLimit EQ 0>Sem limite diário<cfelse><cfoutput>#lsCurrencyFormat(VARIABLES.businessHomeAdsDailyLimit)#</cfoutput></cfif></div>
                                </div>
                            </div>
                        </div>

                        <cfif qBusinessHomeAdCampaigns.recordcount>
                            <div class="table-responsive">
                                <table class="table table-sm table-hover align-middle mb-0">
                                    <thead>
                                        <tr>
                                            <th>Campanha</th>
                                            <th>Status</th>
                                            <th>Periodo</th>
                                            <th class="text-end">CPC</th>
                                            <th class="text-end">Limite/dia</th>
                                            <th class="text-end">Orçamento total</th><th class="text-end">Ações</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <cfoutput query="qBusinessHomeAdCampaigns">
                                            <cfset VARIABLES.businessHomeAdStatusClass = "bg-secondary"/>
                                            <cfset VARIABLES.businessHomeAdStatusLabel = "Status " & qBusinessHomeAdCampaigns.status/>
                                            <cfif qBusinessHomeAdCampaigns.status EQ "ACTIVE">
                                                <cfset VARIABLES.businessHomeAdStatusClass = "bg-success"/>
                                                <cfset VARIABLES.businessHomeAdStatusLabel = "Ativa"/>
                                            <cfelseif qBusinessHomeAdCampaigns.status EQ "PAUSED">
                                                <cfset VARIABLES.businessHomeAdStatusLabel = "Pausada"/>
                                            <cfelseif qBusinessHomeAdCampaigns.status EQ "ENDED">
                                                <cfset VARIABLES.businessHomeAdStatusLabel = "Finalizada"/>
                                            </cfif>
                                            <cfif qBusinessHomeAdCampaigns.status EQ "DRAFT"><cfset VARIABLES.businessHomeAdStatusLabel = "Rascunho"/></cfif>
                                            <cfif qBusinessHomeAdCampaigns.status EQ "ACTIVE" AND qBusinessHomeAdCampaigns.budget_exhausted><cfset VARIABLES.businessHomeAdStatusClass = "bg-warning text-dark"/><cfset VARIABLES.businessHomeAdStatusLabel = "Orçamento esgotado"/></cfif>
                                            <cfset VARIABLES.businessHomeAdPeriod = "Sem periodo"/>
                                            <cfif isDate(qBusinessHomeAdCampaigns.inicio_ad) AND isDate(qBusinessHomeAdCampaigns.final_ad)>
                                                <cfset VARIABLES.businessHomeAdPeriod = dateFormat(qBusinessHomeAdCampaigns.inicio_ad, "dd/mm/yyyy") & " a " & dateFormat(qBusinessHomeAdCampaigns.final_ad, "dd/mm/yyyy")/>
                                            <cfelseif isDate(qBusinessHomeAdCampaigns.inicio_ad)>
                                                <cfset VARIABLES.businessHomeAdPeriod = "Desde " & dateFormat(qBusinessHomeAdCampaigns.inicio_ad, "dd/mm/yyyy")/>
                                            <cfelseif isDate(qBusinessHomeAdCampaigns.final_ad)>
                                                <cfset VARIABLES.businessHomeAdPeriod = "Ate " & dateFormat(qBusinessHomeAdCampaigns.final_ad, "dd/mm/yyyy")/>
                                            </cfif>
                                            <cfset VARIABLES.businessHomeAdManageUrl = "/ads/?view=campaigns&amp;status=" & (qBusinessHomeAdCampaigns.status EQ "ENDED" ? "ended" : (qBusinessHomeAdCampaigns.status EQ "DRAFT" ? "draft" : "ongoing")) & "&amp;manage=" & urlEncodedFormat(qBusinessHomeAdCampaigns.id_ad_evento) & "##campaign-" & qBusinessHomeAdCampaigns.id_ad_evento/>
                                            <tr>
                                                <td><a href="#VARIABLES.businessHomeAdManageUrl#">#encodeForHTML(qBusinessHomeAdCampaigns.nome_evento)#</a></td>
                                                <td><span class="badge #VARIABLES.businessHomeAdStatusClass#">#encodeForHTML(VARIABLES.businessHomeAdStatusLabel)#</span></td>
                                                <td>#encodeForHTML(VARIABLES.businessHomeAdPeriod)#</td>
                                                <td class="text-end">#lsCurrencyFormat(val(qBusinessHomeAdCampaigns.cpc_max))#</td>
                                                <td class="text-end"><cfif isNumeric(qBusinessHomeAdCampaigns.limite_diario)>#lsCurrencyFormat(qBusinessHomeAdCampaigns.limite_diario)#<cfelse>Sem limite diário</cfif></td>
                                                <td class="text-end">#lsCurrencyFormat(val(qBusinessHomeAdCampaigns.limite_ad))#</td><td class="text-end"><a class="btn btn-sm btn-outline-info" href="#VARIABLES.businessHomeAdManageUrl#">Gerenciar</a></td>
                                            </tr>
                                        </cfoutput>
                                    </tbody>
                                </table>
                            </div>
                        <cfelse>
                            <p class="text-muted mb-0">Nenhuma campanha encontrada para os eventos vinculados.</p>
                        </cfif>
                    </div>
                </div>
            </div>
        </div>
        </cfif>
        <script>
            document.querySelectorAll("[data-business-list-toggle]").forEach(function (button) {
                button.addEventListener("click", function () {
                    var list = document.getElementById(button.getAttribute("data-business-list-toggle"));

                    if (!list) {
                        return;
                    }

                    var isExpanded = list.classList.toggle("is-expanded");
                    button.textContent = isExpanded ? button.getAttribute("data-label-open") : button.getAttribute("data-label-closed");
                });
            });
        </script>
    </section>
<cfelseif len(VARIABLES.businessHomeDashboardError)>
    <div class="alert alert-warning">
        Nao foi possivel carregar o resumo da conta agora.
    </div>
</cfif>
