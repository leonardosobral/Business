<cfinclude template="../includes/paid_banner_helpers.cfm"/>
<cfset VARIABLES.paidBannerWorkspaceView = paidBannerWorkspaceView(URL, FORM, VARIABLES.adsAccessCanReviewCampaign)/>
<cfif VARIABLES.paidBannerWorkspaceView EQ "paid">
<cfinclude template="../includes/paid_banner_backend.cfm"/>
<cfinclude template="../includes/paid_banner_home.cfm"/>
<cfelse>
<cfinclude template="../includes/banner_management_backend.cfm"/>
<cfinclude template="../includes/banner_dashboard_backend.cfm"/>
<cfset VARIABLES.bannerShowForm = qBannerManagementEdit.recordcount OR (isDefined('URL.banner_novo') AND URL.banner_novo) OR (isDefined('FORM.acao') AND FORM.acao EQ 'salvar_banner')/>
<link rel="stylesheet" href="/assets/css/portal-banner-dashboard.css?v=2026091601"/>
<section class="banner-dashboard">
    <header class="banner-header">
        <div><div class="banner-eyebrow">Marketing</div><h1 class="h3 mb-1">Banners</h1><p class="text-muted mb-0">Acompanhe a exibição dos banners e gerencie onde cada um aparece.</p></div>
        <cfif VARIABLES.bannerManagementIsAdmin AND VARIABLES.bannerManagementTablesReady><a class="btn btn-info" href="./?view=house&amp;banner_novo=1">Novo banner</a></cfif>
    </header>
    <nav class="mb-4 d-flex gap-3"><a href="/portal/banners/">Banners pagos</a><span class="text-info">Institucionais (HOUSE)</span></nav>
    <cfif NOT VARIABLES.bannerManagementIsAdmin>
        <div class="alert alert-warning">Você não tem permissão para gerenciar banners do Portal.</div>
    <cfelseif NOT VARIABLES.bannerManagementTablesReady OR NOT VARIABLES.bannerManagementResponsiveReady>
        <div class="alert alert-warning">Não foi possível carregar os banners. Verifique a disponibilidade da estrutura de banners no datasource runnerhub.</div>
    <cfelse>
        <cfif len(trim(VARIABLES.bannerManagementAlert.type)) AND len(trim(VARIABLES.bannerManagementAlert.message))>
            <cfoutput><div class="alert alert-#htmlEditFormat(VARIABLES.bannerManagementAlert.type)#">#htmlEditFormat(VARIABLES.bannerManagementAlert.message)#</div></cfoutput>
        </cfif>
        <cfif VARIABLES.bannerShowForm><cfinclude template="../includes/banner_form.cfm"/></cfif>
        <div class="banner-eyebrow mb-2">Resumo geral · todo o histórico</div>
        <cfoutput>
            <div class="banner-kpis">
                <div class="banner-kpi"><span>Banners</span><strong>#LSNumberFormat(qBannerManagementStats.total_banners,'9,999')#</strong></div>
                <div class="banner-kpi"><span>Ativos</span><strong>#LSNumberFormat(qBannerManagementStats.total_ativos,'9,999')#</strong></div>
                <div class="banner-kpi"><span>Impressões</span><strong>#LSNumberFormat(qBannerManagementStats.total_views,'9,999,999')#</strong></div>
                <div class="banner-kpi"><span>Cliques</span><strong>#LSNumberFormat(qBannerManagementStats.total_clicks,'9,999,999')#</strong></div>
                <div class="banner-kpi"><span>Taxa de cliques (CTR)</span><strong><cfif qBannerManagementStats.total_views GT 0>#LSNumberFormat(qBannerManagementStats.total_clicks*100/qBannerManagementStats.total_views,'9.99')#%<cfelse>—</cfif></strong></div>
            </div>
        </cfoutput>
        <section class="banner-panel" id="banner-performance" aria-labelledby="banner-performance-title">
            <div class="banner-section-heading">
                <div><div class="banner-eyebrow">Resultados</div><h2 class="h5 mb-1" id="banner-performance-title">Performance dos banners</h2><p class="text-muted small mb-0">Impressões visíveis e cliques válidos por dia, no período selecionado.</p></div>
                <form action="./#banner-performance" method="get" class="banner-chart-filters">
                    <input type="hidden" name="view" value="house"/>
                    <input type="hidden" name="filtro_status" value="<cfoutput>#htmlEditFormat(URL.filtro_status)#</cfoutput>"/>
                    <div><label for="banner-performance-select">Banner</label><select class="form-select form-select-sm" id="banner-performance-select" name="banner">
                        <option value="">Todos os banners</option>
                        <cfoutput query="qBannerDashboardChoices"><option value="#htmlEditFormat(qBannerDashboardChoices.id_banner)#"<cfif VARIABLES.bannerDashboardFilter.banner EQ qBannerDashboardChoices.id_banner> selected</cfif>>#htmlEditFormat(qBannerDashboardChoices.nome)#</option></cfoutput>
                    </select></div>
                    <div><label for="banner-period">Período</label><select class="form-select form-select-sm" id="banner-period" name="periodo"><option value="7"<cfif VARIABLES.bannerDashboardFilter.days EQ 7> selected</cfif>>Últimos 7 dias</option><option value="30"<cfif VARIABLES.bannerDashboardFilter.days EQ 30> selected</cfif>>Últimos 30 dias</option></select></div>
                    <button class="btn btn-sm btn-outline-info" type="submit">Aplicar</button>
                </form>
            </div>
            <cfif VARIABLES.bannerDashboardFilter.invalidBanner>
                <div class="alert alert-warning mb-0">O banner selecionado não está disponível. Selecione outro banner e aplique o filtro.</div>
            <cfelseif NOT VARIABLES.bannerDashboardReady>
                <div class="alert alert-warning mb-0">Não foi possível carregar a performance dos banners. Tente novamente.</div>
            <cfelse>
                <cfoutput><div class="banner-period-totals">
                    <div><span>Impressões no período</span><strong>#LSNumberFormat(VARIABLES.bannerDashboardSummary.impressions,'9,999,999')#</strong></div>
                    <div><span>Cliques no período</span><strong>#LSNumberFormat(VARIABLES.bannerDashboardSummary.clicks,'9,999,999')#</strong></div>
                    <div><span>CTR no período</span><strong><cfif VARIABLES.bannerDashboardSummary.impressions GT 0>#LSNumberFormat(VARIABLES.bannerDashboardSummary.ctr,'9.99')#%<cfelse>—</cfif></strong></div>
                </div></cfoutput>
                <cfif NOT VARIABLES.bannerDashboardSummary.impressions AND NOT VARIABLES.bannerDashboardSummary.clicks><p class="small text-muted">Nenhuma impressão ou clique registrado para este filtro no período.</p></cfif>
                <div class="banner-chart-wrap"><canvas id="banner-performance-chart" role="img" aria-label="Gráfico diário de impressões e cliques dos banners. Os valores também estão disponíveis em Dados diários."></canvas></div>
                <div id="banner-chart-error" class="alert alert-warning mt-2" hidden>Não foi possível exibir o gráfico. Consulte os dados diários abaixo.</div>
                <script type="application/json" id="banner-performance-data"><cfoutput>#serializeJSON(VARIABLES.bannerDashboardRows)#</cfoutput></script>
                <details class="banner-technical"><summary>Dados diários</summary><div class="table-responsive mt-2"><table class="table table-sm"><caption class="visually-hidden">Impressões e cliques do filtro selecionado</caption><thead><tr><th scope="col">Data</th><th scope="col">Impressões</th><th scope="col">Cliques</th></tr></thead><tbody><cfoutput query="qBannerDashboardDaily"><tr><td>#dateFormat(qBannerDashboardDaily.metric_date,'dd/mm/yyyy')#</td><td>#LSNumberFormat(qBannerDashboardDaily.impressions,'9,999,999')#</td><td>#LSNumberFormat(qBannerDashboardDaily.clicks,'9,999,999')#</td></tr></cfoutput></tbody></table></div></details>
            </cfif>
        </section>
        <section class="banner-panel" aria-labelledby="banner-list-title">
            <div class="banner-section-heading">
                <div><div class="banner-eyebrow">Acompanhamento</div><h2 class="h5 mb-1" id="banner-list-title">Seus banners</h2><p class="text-muted small mb-0">Resultados acumulados em todo o histórico. Expanda uma linha para ver as peças, o escopo e as ações.</p></div>
                <form action="./#banner-list-title" method="get" class="banner-chart-filters">
                    <input type="hidden" name="view" value="house"/>
                    <cfoutput><input type="hidden" name="banner" value="#htmlEditFormat(VARIABLES.bannerDashboardFilter.banner)#"/><input type="hidden" name="periodo" value="#VARIABLES.bannerDashboardFilter.days#"/></cfoutput>
                    <div><label for="banner-list-status">Status</label><select class="form-select form-select-sm" id="banner-list-status" name="filtro_status"><option value="">Todos</option><option value="DRAFT"<cfif URL.filtro_status EQ 'DRAFT'> selected</cfif>>Rascunho</option><option value="ACTIVE"<cfif URL.filtro_status EQ 'ACTIVE'> selected</cfif>>Ativo</option><option value="PAUSED"<cfif URL.filtro_status EQ 'PAUSED'> selected</cfif>>Pausado</option><option value="ENDED"<cfif URL.filtro_status EQ 'ENDED'> selected</cfif>>Encerrado</option></select></div>
                    <button class="btn btn-sm btn-outline-info" type="submit">Filtrar</button>
                </form>
            </div>
            <cfinclude template="../includes/banner_dashboard_list.cfm"/>
        </section>
        <details class="banner-technical mb-4"><summary>Sobre a entrega dos banners</summary><p class="mt-2">Banners HOUSE são espaços institucionais, sem cobrança. A exibição respeita status, período, páginas e estados configurados. Uma entrega não equivale a uma impressão: o gráfico conta impressões visíveis e cliques válidos.</p><cfif qBannerManagementLegacyRollback.recordcount><cfoutput><p>Histórico legado preservado para recuperação: #val(qBannerManagementLegacyRollback.legacy_banners)# banners, #val(qBannerManagementLegacyRollback.legacy_views)# impressões e #val(qBannerManagementLegacyRollback.legacy_clicks)# cliques. Esses registros não compõem os indicadores atuais.</p></cfoutput></cfif></details>
    </cfif>
</section>
<script src="/assets/js/ads-performance-dashboard.js?2026090203"></script>
<script src="/assets/js/portal-banner-dashboard.js?v=2026091601"></script>
<script type="module">
    const canvas = document.getElementById('banner-performance-chart');
    if (canvas) {
        try {
            const {Chart} = await import('/assets/js/chart.es.min.js');
            const rows = JSON.parse(document.getElementById('banner-performance-data').textContent);
            const config = window.BannerPerformanceDashboard.buildChartConfig(rows);
            const [data, options] = window.AdsPerformanceDashboard.toMdbChartArguments(config);
            new Chart(canvas, data, options);
            canvas.dataset.ready = 'true';
        } catch (error) {
            canvas.hidden = true;
            document.getElementById('banner-chart-error').hidden = false;
        }
    }
</script>
</cfif>
