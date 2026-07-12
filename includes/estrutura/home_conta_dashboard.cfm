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
        <cfquery name="qBusinessHomeVoucherColumnCheck">
            SELECT count(*)::integer AS total_columns
            FROM information_schema.columns
            WHERE table_schema = 'ads'
              AND table_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_ad_vouchers"/>
              AND column_name IN (
                  <cfqueryparam cfsqltype="cf_sql_varchar" value="id_conta"/>,
                  <cfqueryparam cfsqltype="cf_sql_varchar" value="credito"/>,
                  <cfqueryparam cfsqltype="cf_sql_varchar" value="credito_disponivel"/>,
                  <cfqueryparam cfsqltype="cf_sql_varchar" value="status"/>,
                  <cfqueryparam cfsqltype="cf_sql_varchar" value="data_resgate"/>
              )
        </cfquery>
        <cfset VARIABLES.businessHomeVoucherColumnsReady = qBusinessHomeVoucherColumnCheck.recordcount GT 0 AND val(qBusinessHomeVoucherColumnCheck.total_columns) GTE 5/>

        <cfquery name="qBusinessHomeMarketingSummary">
            WITH linked_events AS (
                SELECT DISTINCT id_evento
                FROM public.tb_conta_eventos
                WHERE id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessHomeAccountIds#" list="true"/>)
                  AND status::text = 'ATIVO'
            ),
            <cfif VARIABLES.businessHomeVoucherColumnsReady>
            voucher_summary AS (
                SELECT coalesce(sum(CASE WHEN status = 2 AND data_resgate IS NOT NULL THEN coalesce(credito_disponivel, credito, 0) ELSE 0 END), 0) AS saldo_ads,
                       count(*) FILTER (WHERE status = 2 AND data_resgate IS NOT NULL) AS vouchers_resgatados
                FROM ads.tb_ad_vouchers
                WHERE id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessHomeAccountIds#" list="true"/>)
            ),
            <cfelse>
            voucher_summary AS (
                SELECT 0::numeric AS saldo_ads,
                       0::integer AS vouchers_resgatados
            ),
            </cfif>
            ad_summary AS (
                SELECT count(DISTINCT ad.id_ad_evento) AS ads_total,
                       count(DISTINCT ad.id_ad_evento) FILTER (
                           WHERE ad.status = 1
                             AND (ad.inicio_ad IS NULL OR ad.inicio_ad <= now())
                             AND (ad.final_ad IS NULL OR ad.final_ad >= now())
                       ) AS ads_ativos,
                       coalesce(sum(coalesce(ad.limite_ad, 0)), 0) AS ads_budget_total,
                       coalesce(sum(coalesce(ad.limite_diario, 0)) FILTER (
                           WHERE ad.status = 1
                             AND (ad.inicio_ad IS NULL OR ad.inicio_ad <= now())
                             AND (ad.final_ad IS NULL OR ad.final_ad >= now())
                       ), 0) AS ads_daily_limit
                FROM ads.tb_ad_eventos ad
                INNER JOIN linked_events evt ON evt.id_evento = ad.id_evento
            )
            SELECT coalesce(voucher_summary.saldo_ads, 0) AS saldo_ads,
                   coalesce(voucher_summary.vouchers_resgatados, 0) AS vouchers_resgatados,
                   coalesce(ad_summary.ads_total, 0) AS ads_total,
                   coalesce(ad_summary.ads_ativos, 0) AS ads_ativos,
                   coalesce(ad_summary.ads_budget_total, 0) AS ads_budget_total,
                   coalesce(ad_summary.ads_daily_limit, 0) AS ads_daily_limit
            FROM voucher_summary, ad_summary
        </cfquery>

        <cfif qBusinessHomeMarketingSummary.recordcount>
            <cfset VARIABLES.businessHomeSaldoAds = val(qBusinessHomeMarketingSummary.saldo_ads)/>
            <cfset VARIABLES.businessHomeVouchersResgatados = val(qBusinessHomeMarketingSummary.vouchers_resgatados)/>
            <cfset VARIABLES.businessHomeAdsTotal = val(qBusinessHomeMarketingSummary.ads_total)/>
            <cfset VARIABLES.businessHomeAdsAtivos = val(qBusinessHomeMarketingSummary.ads_ativos)/>
            <cfset VARIABLES.businessHomeAdsBudgetTotal = val(qBusinessHomeMarketingSummary.ads_budget_total)/>
            <cfset VARIABLES.businessHomeAdsDailyLimit = val(qBusinessHomeMarketingSummary.ads_daily_limit)/>
        </cfif>

        <cfquery name="qBusinessHomeAdCampaigns">
            WITH linked_events AS (
                SELECT DISTINCT id_evento
                FROM public.tb_conta_eventos
                WHERE id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessHomeAccountIds#" list="true"/>)
                  AND status::text = 'ATIVO'
            )
            SELECT ad.id_ad_evento,
                   evt.nome_evento,
                   evt.tag,
                   ad.status,
                   ad.cpc_max,
                   ad.limite_diario,
                   ad.limite_ad,
                   ad.inicio_ad,
                   ad.final_ad
            FROM ads.tb_ad_eventos ad
            INNER JOIN public.tb_evento_corridas evt ON evt.id_evento = ad.id_evento
            INNER JOIN linked_events ce ON ce.id_evento = evt.id_evento
            ORDER BY ad.status ASC, ad.final_ad DESC NULLS LAST, evt.nome_evento
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
                    <h3 class="mb-1">#htmlEditFormat(VARIABLES.businessHomeAccountTitle)#</h3>
                    <p class="text-muted mb-0">#htmlEditFormat(VARIABLES.businessHomeAccountSubtitle)#</p>
                </cfoutput>
            </div>
            <div class="dashboard-actions">
                <a class="btn btn-outline-light btn-sm" href="/eventos/"><i class="fa-solid fa-person-running me-2"></i>Eventos</a>
                <cfif VARIABLES.businessHomeHasActiveEvents>
                    <a class="btn btn-outline-light btn-sm" href="/ads/"><i class="fa-solid fa-rocket me-2"></i>Ads</a>
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
                            <div class="small">Use turbinados e cupons quando houver evento.</div>
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
                            <p class="text-muted mb-0"><cfif VARIABLES.businessHomeMarketingStarted>Já existe crédito, voucher ou campanha conectado à conta.<cfelse>Use Turbinados, Cupons e Inscrições para acompanhar a operação.</cfif></p>
                            <div class="business-step-action d-grid gap-2">
                                <a class="btn btn-sm btn-warning" href="/ads/">Abrir marketing</a>
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
                            <div class="text-muted small">Saldo Ads</div>
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
                                                <div class="fw-bold">#htmlEditFormat(qBusinessHomeUpcomingEvents.nome_evento)#</div>
                                                <div class="small text-muted">
                                                    #dateFormat(qBusinessHomeUpcomingEvents.data_inicial, "dd/mm/yyyy")#
                                                    <cfif len(trim(qBusinessHomeUpcomingEvents.cidade)) OR len(trim(qBusinessHomeUpcomingEvents.estado))>
                                                        - #htmlEditFormat(qBusinessHomeUpcomingEvents.cidade)#<cfif len(trim(qBusinessHomeUpcomingEvents.estado))>/#htmlEditFormat(qBusinessHomeUpcomingEvents.estado)#</cfif>
                                                    </cfif>
                                                </div>
                                            </div>
                                            <span class="badge bg-success align-self-start">#htmlEditFormat(qBusinessHomeUpcomingEvents.status_vinculo)#</span>
                                        </div>
                                        <div class="dashboard-actions mt-2">
                                            <a class="btn btn-sm btn-dark" href="/eventos/?id_evento=#qBusinessHomeUpcomingEvents.id_evento#">Editar</a>
                                            <a class="btn btn-sm btn-dark" href="/ads/">Turbinar evento</a>
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
                                        <div class="fw-bold">#htmlEditFormat(qBusinessHomeContentAttention.nome_evento)#</div>
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
                                <div class="text-muted small">Credito, campanhas e orcamento de anuncios.</div>
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
                                    <div class="fw-bold"><cfoutput>#lsCurrencyFormat(VARIABLES.businessHomeAdsDailyLimit)#</cfoutput></div>
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
                                            <th class="text-end">Orcamento</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <cfoutput query="qBusinessHomeAdCampaigns">
                                            <cfset VARIABLES.businessHomeAdStatusClass = "bg-secondary"/>
                                            <cfset VARIABLES.businessHomeAdStatusLabel = "Status " & qBusinessHomeAdCampaigns.status/>
                                            <cfif qBusinessHomeAdCampaigns.status EQ 1>
                                                <cfset VARIABLES.businessHomeAdStatusClass = "bg-success"/>
                                                <cfset VARIABLES.businessHomeAdStatusLabel = "Ativa"/>
                                            <cfelseif qBusinessHomeAdCampaigns.status EQ 3>
                                                <cfset VARIABLES.businessHomeAdStatusLabel = "Pausada"/>
                                            <cfelseif qBusinessHomeAdCampaigns.status EQ 4>
                                                <cfset VARIABLES.businessHomeAdStatusLabel = "Arquivada"/>
                                            </cfif>
                                            <cfset VARIABLES.businessHomeAdPeriod = "Sem periodo"/>
                                            <cfif isDate(qBusinessHomeAdCampaigns.inicio_ad) AND isDate(qBusinessHomeAdCampaigns.final_ad)>
                                                <cfset VARIABLES.businessHomeAdPeriod = dateFormat(qBusinessHomeAdCampaigns.inicio_ad, "dd/mm") & " a " & dateFormat(qBusinessHomeAdCampaigns.final_ad, "dd/mm")/>
                                            <cfelseif isDate(qBusinessHomeAdCampaigns.inicio_ad)>
                                                <cfset VARIABLES.businessHomeAdPeriod = "Desde " & dateFormat(qBusinessHomeAdCampaigns.inicio_ad, "dd/mm")/>
                                            <cfelseif isDate(qBusinessHomeAdCampaigns.final_ad)>
                                                <cfset VARIABLES.businessHomeAdPeriod = "Ate " & dateFormat(qBusinessHomeAdCampaigns.final_ad, "dd/mm")/>
                                            </cfif>
                                            <tr>
                                                <td>#htmlEditFormat(qBusinessHomeAdCampaigns.nome_evento)#</td>
                                                <td><span class="badge #VARIABLES.businessHomeAdStatusClass#">#htmlEditFormat(VARIABLES.businessHomeAdStatusLabel)#</span></td>
                                                <td>#htmlEditFormat(VARIABLES.businessHomeAdPeriod)#</td>
                                                <td class="text-end">#lsCurrencyFormat(val(qBusinessHomeAdCampaigns.cpc_max))#</td>
                                                <td class="text-end">#lsCurrencyFormat(val(qBusinessHomeAdCampaigns.limite_diario))#</td>
                                                <td class="text-end">#lsCurrencyFormat(val(qBusinessHomeAdCampaigns.limite_ad))#</td>
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
