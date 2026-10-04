<cfinclude template="banner_dashboard_helpers.cfm"/>
<cfset VARIABLES.paidBannerSection=paidBannerWorkspaceSection(URL,VARIABLES.paidBannerShowForm,VARIABLES.paidBannerContext.canManage)/>
<cfif VARIABLES.paidBannerSection EQ "form" AND NOT structKeyExists(VARIABLES,"paidBannerFormData")><cfset VARIABLES.paidBannerSection="banners"/></cfif>
<cfset VARIABLES.paidBannerReturnQuery=paidBannerFilterQuery(VARIABLES.paidBannerFilter,VARIABLES.paidBannerDays)/>
<cfset VARIABLES.paidBannerPerformanceUrl="/portal/banners/?section=performance&" & VARIABLES.paidBannerReturnQuery/>
<cfset VARIABLES.paidBannerBannersUrl="/portal/banners/?section=banners&" & VARIABLES.paidBannerReturnQuery/>
<cfset VARIABLES.paidBannerFormUrl="/portal/banners/?section=form&novo=1&" & VARIABLES.paidBannerReturnQuery & "##paid-banner-form"/>
<cfset VARIABLES.paidBannerListActionUrl="/portal/banners/?section=banners&" & VARIABLES.paidBannerReturnQuery/>
<cfset VARIABLES.paidBannerFormActionUrl="/portal/banners/?section=form&" & VARIABLES.paidBannerReturnQuery & "##paid-banner-form"/>
<link rel="stylesheet" href="/assets/css/portal-banner-dashboard.css?v=2026091601"/>
<link rel="stylesheet" href="/assets/css/paid-banner-workspace.css?v=20260916"/>
<section class="banner-dashboard">
<cfoutput>
    <header class="banner-header"><div><div class="banner-eyebrow">Marketing · marcas e parceiros</div><h1 class="h3 mb-1">Banners</h1><p class="text-muted mb-0">Divulgue sua marca, pague por cliques e acompanhe os resultados.</p></div><cfif VARIABLES.paidBannerReady AND VARIABLES.paidBannerContext.canManage><a class="btn btn-info" href="#encodeForHTMLAttribute(VARIABLES.paidBannerFormUrl)#">Criar banner</a></cfif></header>
    <cfif VARIABLES.paidBannerContext.canReview><nav class="mb-4 d-flex gap-3"><span class="text-info">Banners pagos</span><a href="/portal/banners/?view=house">Institucionais (HOUSE)</a></nav></cfif>
    <cfif len(VARIABLES.paidBannerError)><div class="alert alert-danger">#htmlEditFormat(VARIABLES.paidBannerError)#</div></cfif>
    <cfif len(VARIABLES.paidBannerNotice)><div class="alert alert-success">#htmlEditFormat(VARIABLES.paidBannerNotice)#</div></cfif>
    <cfif NOT VARIABLES.paidBannerContext.canView AND NOT VARIABLES.paidBannerContext.canReview><div class="alert alert-warning">Selecione uma conta autorizada no topo para acessar os banners.</div>
    <cfelseif NOT VARIABLES.paidBannerReady><div class="alert alert-info">O módulo de banners pagos está em preparação. O cadastro será liberado após a atualização da estrutura de publicidade.</div>
    <cfelse>
        <nav class="nav nav-tabs mb-4" aria-label="Seções dos banners pagos">
            <a class="nav-link<cfif VARIABLES.paidBannerSection EQ 'performance'> active</cfif>" href="#encodeForHTMLAttribute(VARIABLES.paidBannerPerformanceUrl)#"<cfif VARIABLES.paidBannerSection EQ 'performance'> aria-current="page"</cfif>>Desempenho</a>
            <a class="nav-link<cfif VARIABLES.paidBannerSection EQ 'banners'> active</cfif>" href="#encodeForHTMLAttribute(VARIABLES.paidBannerBannersUrl)#"<cfif VARIABLES.paidBannerSection EQ 'banners'> aria-current="page"</cfif>>Banners</a>
            <cfif VARIABLES.paidBannerContext.canManage><a class="nav-link<cfif VARIABLES.paidBannerSection EQ 'form'> active</cfif>" href="#encodeForHTMLAttribute(VARIABLES.paidBannerFormUrl)#"<cfif VARIABLES.paidBannerSection EQ 'form'> aria-current="page"</cfif>>Cadastro</a></cfif>
        </nav>
        <cfif VARIABLES.paidBannerContext.accountId GT 0><section class="banner-panel py-3"><div class="d-flex flex-wrap justify-content-between align-items-center gap-3"><div><span class="text-muted">Saldo compartilhado da conta</span><strong class="h4 d-block mb-0">R$ #LSNumberFormat(VARIABLES.paidBannerBalanceValue,'9,999.00')#</strong></div><cfif VARIABLES.adsAccessCanViewPayments><a href="/ads/?view=payments" class="btn btn-sm btn-outline-info">Saldo e pagamentos</a></cfif></div><p class="small text-muted mt-2 mb-0">O mesmo saldo atende banners e anúncios de eventos. Cada campanha tem seu próprio orçamento.</p></section></cfif>
        <cfif VARIABLES.paidBannerSection EQ 'performance'>
        <section class="banner-panel" id="paid-banner-performance">
            <div class="banner-section-heading"><div><div class="banner-eyebrow">Resultados</div><h2 class="h5">Performance dos banners</h2></div>
                <form method="get" action="/portal/banners/##paid-banner-performance" class="banner-chart-filters"><input type="hidden" name="section" value="performance"/><div><label for="paid-filter">Banner</label><select class="form-select form-select-sm" name="banner" id="paid-filter"><option value="">Todos os banners</option><cfloop array="#VARIABLES.paidBannerRows#" index="paidBannerChoice"><option value="#htmlEditFormat(paidBannerChoice.campaign_id)#"<cfif VARIABLES.paidBannerFilter EQ paidBannerChoice.campaign_id> selected</cfif>>#htmlEditFormat(paidBannerChoice.name)#</option></cfloop></select></div><div><label for="paid-period">Período</label><select class="form-select form-select-sm" name="periodo" id="paid-period"><cfloop list="7,30,90" index="paidDays"><option value="#paidDays#"<cfif VARIABLES.paidBannerDays EQ val(paidDays)> selected</cfif>>Últimos #paidDays# dias</option></cfloop></select></div><button class="btn btn-sm btn-outline-info">Aplicar</button></form>
            </div>
            <div class="banner-kpis mb-3"><div class="banner-kpi"><span>Impressões visíveis</span><strong>#LSNumberFormat(VARIABLES.paidBannerTotals.impressions,'9,999')#</strong></div><div class="banner-kpi"><span>Cliques válidos</span><strong>#LSNumberFormat(VARIABLES.paidBannerTotals.clicks,'9,999')#</strong></div><div class="banner-kpi"><span>CTR</span><strong><cfif VARIABLES.paidBannerTotals.impressions GT 0>#LSNumberFormat(VARIABLES.paidBannerTotals.clicks*100/VARIABLES.paidBannerTotals.impressions,'9.99')#%<cfelse>—</cfif></strong></div><div class="banner-kpi"><span>Investimento no período</span><strong>R$ #LSNumberFormat(VARIABLES.paidBannerTotals.cost,'9,999.00')#</strong></div></div>
            <div class="banner-chart-wrap"><canvas id="paid-banner-chart" role="img" aria-label="Impressões, cliques e investimento dos banners por dia"></canvas></div><p id="paid-banner-chart-error" hidden>Gráfico indisponível. Consulte os dados diários abaixo.</p>
            <script type="application/json" id="paid-banner-chart-data">#replace(serializeJSON(VARIABLES.paidBannerChartRows),'<','\u003c','all')#</script>
            <details class="banner-technical"><summary>Dados diários</summary><div class="table-responsive"><table class="table table-sm"><thead><tr><th>Data</th><th>Impressões</th><th>Cliques</th><th>Investimento</th></tr></thead><tbody><cfloop array="#VARIABLES.paidBannerChartRows#" index="paidDay"><tr><td>#htmlEditFormat(paidDay.date)#</td><td>#val(paidDay.impressions)#</td><td>#val(paidDay.clicks)#</td><td>R$ #LSNumberFormat(paidDay.cost,'9,999.00')#</td></tr></cfloop></tbody></table></div></details>
        </section>
        </cfif>
        <cfif VARIABLES.paidBannerSection EQ 'banners'>
        <section class="banner-panel"><div class="banner-eyebrow">Acompanhamento</div><h2 class="h5">#VARIABLES.paidBannerContext.accountId GT 0 ? 'Banners da conta' : 'Banners de todas as contas'#</h2><p class="small text-muted">Resultados acumulados. Banners aguardando análise aparecem primeiro. Expanda para ver as peças, o escopo e as ações.</p><cfinclude template="paid_banner_list.cfm"/></section>
        </cfif>
        <cfif VARIABLES.paidBannerSection EQ 'form' AND VARIABLES.paidBannerContext.canManage><cfinclude template="paid_banner_form.cfm"/></cfif>
    </cfif>
</cfoutput>
</section>
<script src="/assets/js/ads-performance-dashboard.js?2026090203"></script>
<script type="module">
const canvas=document.getElementById('paid-banner-chart');
if(canvas){try{const {Chart}=await import('/assets/js/chart.es.min.js');const rows=JSON.parse(document.getElementById('paid-banner-chart-data').textContent);const config=window.AdsPerformanceDashboard.buildChartConfig(rows);const [data,options]=window.AdsPerformanceDashboard.toMdbChartArguments(config);new Chart(canvas,data,options);canvas.dataset.ready='true';}catch(e){canvas.hidden=true;document.getElementById('paid-banner-chart-error').hidden=false;}}
</script>
