<!--- Rendering only. The global-admin controller supplies independent sources and actionable signals. --->
<cfinclude template="../backend/require_admin.cfm"/>
<cfscript>
VARIABLES.businessDecisionArea = "audiencia";
if (structKeyExists(URL, "home_area") AND isSimpleValue(URL.home_area) AND listFind("audiencia,contas,conteudo,comunicacao", URL.home_area)) {
    VARIABLES.businessDecisionArea = URL.home_area;
}
VARIABLES.businessDecisionDays = VARIABLES.businessHomeMetrics.days;
VARIABLES.businessDecisionNumber = function(required numeric value, boolean loaded=true) {
    return arguments.loaded ? LSNumberFormat(arguments.value, "9,999") : "—";
};
VARIABLES.businessDecisionDelta = function(required numeric current, required numeric previous, boolean loaded=true, boolean comparable=true) {
    if (!arguments.loaded) return "Dados indisponíveis";
    if (!arguments.comparable) return "Histórico insuficiente";
    if (arguments.previous EQ 0) return arguments.current EQ 0 ? "Sem movimento nos dois períodos" : "Sem base anterior";
    var change = (arguments.current - arguments.previous) * 100 / arguments.previous;
    if (abs(change) LT 0.05) return "Sem variação";
    return (change GT 0 ? "↑ " : "↓ ") & LSNumberFormat(abs(change), "9.9") & "% vs. período anterior";
};
VARIABLES.businessDecisionSignals = [];
VARIABLES.businessDecisionUnavailable = [];
for (VARIABLES.businessDecisionSignal in VARIABLES.businessHomeSignals) {
    if (!VARIABLES.businessDecisionSignal.loaded) arrayAppend(VARIABLES.businessDecisionUnavailable, VARIABLES.businessDecisionSignal);
    else if (VARIABLES.businessDecisionSignal.value GT 0) arrayAppend(VARIABLES.businessDecisionSignals, VARIABLES.businessDecisionSignal);
}
arraySort(VARIABLES.businessDecisionSignals, function(a,b) { return a.priority - b.priority; });
VARIABLES.businessDecisionKpis = [
 {key="audience",label="Usuários do site",description="Visitantes únicos por navegador",icon="fa-users",source=VARIABLES.businessHomeMetrics.audience,metric="visitors",href="/portal/audiencia/?dias=" & VARIABLES.businessDecisionDays & "##audience-overview",link="Ver audiência"},
 {key="interactions",label="Interações",description="Aberturas, inícios de vídeo e saídas",icon="fa-arrow-pointer",source=VARIABLES.businessHomeMetrics.audience,metric="interactions",href="/portal/audiencia/?dias=" & VARIABLES.businessDecisionDays & "##audience-content",link="Ver interesse no conteúdo"},
 {key="advertising",label="Publicidade",description="Exibições visíveis · eventos e banners",icon="fa-bullhorn",source=VARIABLES.businessHomeMetrics.ads,metric="impressions",href="/ads/?view=admin&ads_period=" & VARIABLES.businessDecisionDays,link="Eventos"},
 {key="investment",label="Investimento",description="Consumo dos anunciantes · Ads e banners",icon="fa-wallet",source=VARIABLES.businessHomeMetrics.ads,metric="cost",href="/ads/?view=admin&ads_period=" & VARIABLES.businessDecisionDays,link="Eventos"}
];
VARIABLES.businessDecisionSecondary = [
 {label="Acessos ao site",value=VARIABLES.businessHomeMetrics.audience.pageviews,loaded=VARIABLES.businessHomeMetrics.audience.loaded,href="/portal/audiencia/?dias=" & VARIABLES.businessDecisionDays & "##audience-overview"},
 {label="Novos usuários cadastrados",value=VARIABLES.businessHomeMetrics.users.new_count,loaded=VARIABLES.businessHomeMetrics.users.loaded,href="/administracao/usuarios/"},
 {label="Cliques em anúncios",value=VARIABLES.businessHomeMetrics.ads.clicks,loaded=VARIABLES.businessHomeMetrics.ads.loaded,href="/?periodo=" & VARIABLES.businessDecisionDays & "&home_area=audiencia##business-home-ad-details"},
 {label="Novas contas Business",value=VARIABLES.businessHomeMetrics.accounts.new_count,loaded=VARIABLES.businessHomeMetrics.accounts.loaded,href="/?periodo=" & VARIABLES.businessDecisionDays & "&home_area=contas##business-admin-areas"}
];
VARIABLES.businessDecisionAreas = [{key="audiencia",label="Audiência"},{key="contas",label="Contas"},{key="conteudo",label="Conteúdo"},{key="comunicacao",label="Comunicação"}];
</cfscript>

<section class="gd-decision-performance" aria-labelledby="business-home-performance-title">
    <div class="gd-section-heading gd-decision-heading">
        <div><h2 id="business-home-performance-title">Como o negócio está andando</h2><p class="gd-caption">Últimos <cfoutput>#VARIABLES.businessDecisionDays#</cfoutput> dias, incluindo hoje · comparação com os <cfoutput>#VARIABLES.businessDecisionDays#</cfoutput> dias anteriores.</p></div>
        <nav class="gd-period-switch" aria-label="Período dos indicadores">
            <cfloop list="7,30" index="businessDecisionPeriod"><cfoutput><a href="/?periodo=#businessDecisionPeriod#&amp;home_area=#VARIABLES.businessDecisionArea#" data-home-period<cfif val(businessDecisionPeriod) EQ VARIABLES.businessDecisionDays> aria-current="true"</cfif>>#businessDecisionPeriod# dias</a></cfoutput></cfloop>
        </nav>
    </div>
    <div class="gd-overview">
        <cfloop array="#VARIABLES.businessDecisionKpis#" index="businessDecisionKpi"><cfoutput>
            <article class="gd-kpi gd-decision-kpi" data-business-home-kpi="#businessDecisionKpi.key#">
                <a class="gd-decision-kpi-main" href="#encodeForHtmlAttribute(businessDecisionKpi.href)#">
                    <span class="gd-kpi-top"><span>#businessDecisionKpi.label#</span><i class="fa-solid #businessDecisionKpi.icon#" aria-hidden="true"></i></span>
                    <strong class="gd-kpi-value<cfif businessDecisionKpi.metric EQ 'cost'> gd-currency</cfif>"><cfif NOT businessDecisionKpi.source.loaded>—<cfelseif businessDecisionKpi.metric EQ "cost">#LSCurrencyFormat(businessDecisionKpi.source.cost)#<cfelse>#VARIABLES.businessDecisionNumber(businessDecisionKpi.source[businessDecisionKpi.metric])#</cfif></strong>
                    <span class="gd-decision-description">#businessDecisionKpi.description#</span>
                    <span class="gd-decision-delta">#VARIABLES.businessDecisionDelta(businessDecisionKpi.source[businessDecisionKpi.metric],businessDecisionKpi.source["previous_" & businessDecisionKpi.metric],businessDecisionKpi.source.loaded,businessDecisionKpi.metric EQ "interactions" ? businessDecisionKpi.source.interactions_comparison_ready : businessDecisionKpi.source.comparison_ready)#</span>
                </a>
                <div class="gd-decision-kpi-links"><a href="#encodeForHtmlAttribute(businessDecisionKpi.href)#">#businessDecisionKpi.link# <i class="fa-solid fa-arrow-up-right-from-square" aria-hidden="true"></i></a><cfif listFind("advertising,investment",businessDecisionKpi.key)><a href="/portal/banners/?section=performance&amp;periodo=#VARIABLES.businessDecisionDays###paid-banner-performance">Banners <i class="fa-solid fa-arrow-up-right-from-square" aria-hidden="true"></i></a></cfif></div>
            </article>
        </cfoutput></cfloop>
    </div>
    <div class="gd-decision-secondary"><cfloop array="#VARIABLES.businessDecisionSecondary#" index="businessDecisionStat"><cfoutput><a href="#encodeForHtmlAttribute(businessDecisionStat.href)#"><span>#businessDecisionStat.label#</span><strong>#VARIABLES.businessDecisionNumber(businessDecisionStat.value,businessDecisionStat.loaded)#</strong></a></cfoutput></cfloop></div>
    <p class="gd-caption gd-period-caveat">Hoje está em andamento; a comparação é parcial. Audiência exclui acessos internos e ambientes de teste. Investimento não inclui Google ou Meta.</p>
</section>

<section class="gd-decision-attention" id="business-admin-pending" aria-labelledby="business-home-attention-title">
    <cfif arrayLen(VARIABLES.businessDecisionSignals) OR arrayLen(VARIABLES.businessDecisionUnavailable)>
        <div class="gd-panel">
            <header class="gd-panel-heading"><div><span class="gd-eyebrow">Aprovações, atendimento e problemas</span><h2 id="business-home-attention-title">Precisa da sua atenção</h2></div><span class="gd-decision-badge"><cfoutput>#arrayLen(VARIABLES.businessDecisionSignals)#</cfoutput> <cfif arrayLen(VARIABLES.businessDecisionSignals) EQ 1>frente<cfelse>frentes</cfif></span></header>
            <div class="gd-queue">
                <cfloop array="#VARIABLES.businessDecisionSignals#" index="businessDecisionSignal"><cfoutput>
                    <a class="gd-queue-row" href="#encodeForHtmlAttribute(businessDecisionSignal.href)#" data-source-state="attention"><i class="fa-solid #businessDecisionSignal.icon# gd-queue-icon" aria-hidden="true"></i><span class="gd-queue-copy"><strong>#encodeForHtml(businessDecisionSignal.label)#</strong><small><span class="gd-queue-kind">#encodeForHtml(businessDecisionSignal.kind)#</span>#encodeForHtml(businessDecisionSignal.description)#</small></span><strong class="gd-count <cfif businessDecisionSignal.priority LTE 10>gd-danger<cfelse>gd-warning</cfif>">#VARIABLES.businessDecisionNumber(businessDecisionSignal.value)#</strong><i class="fa-solid fa-chevron-right gd-chevron" aria-hidden="true"></i></a>
                </cfoutput></cfloop>
                <cfloop array="#VARIABLES.businessDecisionUnavailable#" index="businessDecisionSignal"><cfoutput>
                    <a class="gd-queue-row gd-decision-unavailable" href="#encodeForHtmlAttribute(businessDecisionSignal.href)#" data-source-state="unavailable"><i class="fa-solid fa-circle-question gd-queue-icon" aria-hidden="true"></i><span class="gd-queue-copy"><strong>#encodeForHtml(businessDecisionSignal.label)#</strong><small>Não foi possível consultar esta fonte.</small></span><span class="gd-unavailable-label">Não consultado</span><i class="fa-solid fa-chevron-right gd-chevron" aria-hidden="true"></i></a>
                </cfoutput></cfloop>
            </div>
            <p class="gd-caption">Cada sinal abre a seção responsável. Filas sem pendência ficam fora desta lista.</p>
        </div>
    <cfelse><div class="gd-decision-clear" role="status"><i class="fa-solid fa-circle-check" aria-hidden="true"></i><h2 id="business-home-attention-title">Nenhuma pendência nas fontes consultadas.</h2></div></cfif>
</section>

<section class="gd-decision-areas" id="business-admin-areas" aria-labelledby="business-home-areas-title">
    <h2 id="business-home-areas-title">Acompanhar por área</h2>
    <nav class="gd-decision-tabs" data-home-tabs aria-label="Resumos por área"><cfloop array="#VARIABLES.businessDecisionAreas#" index="businessDecisionTab"><cfoutput><a id="home-tab-#businessDecisionTab.key#" href="/?periodo=#VARIABLES.businessDecisionDays#&amp;home_area=#businessDecisionTab.key###business-admin-areas" data-home-tab="#businessDecisionTab.key#"<cfif VARIABLES.businessDecisionArea EQ businessDecisionTab.key> class="is-active" aria-current="true"</cfif>>#businessDecisionTab.label#</a></cfoutput></cfloop></nav>

    <div id="home-area-audiencia" class="gd-area-panel" data-home-panel="audiencia"<cfif VARIABLES.businessDecisionArea NEQ "audiencia"> hidden</cfif>>
        <div class="gd-area-summary"><h3>Audiência e interesse no site</h3><p>Visitantes são identificados por navegador. Interações contam aberturas de conteúdo, inícios de vídeo e cliques em links externos, incluindo ações de cupons registradas como abertura.</p><cfoutput><a class="gd-text-link" href="/portal/audiencia/?dias=#VARIABLES.businessDecisionDays#">Explorar audiência <i class="fa-solid fa-arrow-right" aria-hidden="true"></i></a></cfoutput></div>
        <dl class="gd-area-metrics"><div><dt>Visitantes no período</dt><dd><cfoutput>#VARIABLES.businessDecisionNumber(VARIABLES.businessHomeMetrics.audience.visitors,VARIABLES.businessHomeMetrics.audience.loaded)#</cfoutput></dd></div><div><dt>Visitantes no período anterior</dt><dd><cfoutput>#VARIABLES.businessDecisionNumber(VARIABLES.businessHomeMetrics.audience.previous_visitors,VARIABLES.businessHomeMetrics.audience.loaded AND VARIABLES.businessHomeMetrics.audience.comparison_ready)#</cfoutput></dd></div></dl>
        <div class="gd-area-ad-detail" id="business-home-ad-details"><h3>Publicidade por formato</h3><cfoutput><a href="/ads/?view=admin&amp;ads_period=#VARIABLES.businessDecisionDays#"><span>Eventos</span><strong>#VARIABLES.businessHomeMetrics.ads.loaded ? LSCurrencyFormat(VARIABLES.businessHomeMetrics.ads.event_cost) : '—'#</strong><i class="fa-solid fa-arrow-up-right-from-square" aria-hidden="true"></i></a><a href="/portal/banners/?section=performance&amp;periodo=#VARIABLES.businessDecisionDays###paid-banner-performance"><span>Banners</span><strong>#VARIABLES.businessHomeMetrics.ads.loaded ? LSCurrencyFormat(VARIABLES.businessHomeMetrics.ads.banner_cost) : '—'#</strong><i class="fa-solid fa-arrow-up-right-from-square" aria-hidden="true"></i></a></cfoutput><p class="gd-caption">Consumo dos anunciantes no período. Cada formato tem seu relatório de exibições, cliques e investimento.</p></div>
    </div>
    <div id="home-area-contas" class="gd-area-panel" data-home-panel="contas"<cfif VARIABLES.businessDecisionArea NEQ "contas"> hidden</cfif>>
        <div class="gd-area-summary"><h3>Novas contas no Business</h3><p>Contas criadas nos últimos <cfoutput>#VARIABLES.businessDecisionDays#</cfoutput> dias. Solicitações que aguardam decisão aparecem nas pendências acima.</p><a class="gd-text-link" href="/administracao/contas/">Abrir contas <i class="fa-solid fa-arrow-right" aria-hidden="true"></i></a></div>
        <dl class="gd-area-metrics"><div><dt>Contas criadas</dt><dd><cfoutput>#VARIABLES.businessDecisionNumber(VARIABLES.businessHomeMetrics.accounts.new_count,VARIABLES.businessHomeMetrics.accounts.loaded)#</cfoutput></dd></div><div><dt>No período anterior</dt><dd><cfoutput>#VARIABLES.businessDecisionNumber(VARIABLES.businessHomeMetrics.accounts.previous_new_count,VARIABLES.businessHomeMetrics.accounts.loaded AND VARIABLES.businessHomeMetrics.accounts.comparison_ready)#</cfoutput></dd></div></dl>
        <p class="gd-caption gd-area-wide"><cfoutput>#VARIABLES.businessDecisionDelta(VARIABLES.businessHomeMetrics.accounts.new_count,VARIABLES.businessHomeMetrics.accounts.previous_new_count,VARIABLES.businessHomeMetrics.accounts.loaded,VARIABLES.businessHomeMetrics.accounts.comparison_ready)#</cfoutput></p>
    </div>
    <div id="home-area-conteudo" class="gd-area-panel" data-home-panel="conteudo"<cfif VARIABLES.businessDecisionArea NEQ "conteudo"> hidden</cfif>>
        <div class="gd-area-summary"><h3>Conteúdo dos próximos eventos</h3><p>Eventos ativos, ainda não encerrados, com início até 90 dias. Cadastro completo considera descrição, inscrição, categorias, organizador, local, endereço e imagem.</p><a class="gd-text-link" href="/portal/conteudo/">Revisar conteúdo <i class="fa-solid fa-arrow-right" aria-hidden="true"></i></a></div>
        <dl class="gd-area-metrics"><div><dt>Cadastros completos</dt><dd><cfif VARIABLES.businessAdminHomeContentLoaded AND VARIABLES.businessAdminHomeContentTotal GT 0><cfoutput>#LSNumberFormat(VARIABLES.businessAdminHomeContentComplete * 100 / VARIABLES.businessAdminHomeContentTotal,"9.9")#%</cfoutput><cfelse>—</cfif></dd></div><div><dt>Incompletos até 30 dias</dt><dd><cfoutput>#VARIABLES.businessDecisionNumber(VARIABLES.businessAdminHomeContentNext30,VARIABLES.businessAdminHomeContentLoaded)#</cfoutput></dd></div></dl>
        <cfif NOT VARIABLES.businessAdminHomeContentLoaded><p class="gd-unavailable gd-area-wide">Dados de conteúdo indisponíveis.</p></cfif>
    </div>
    <div id="home-area-comunicacao" class="gd-area-panel" data-home-panel="comunicacao"<cfif VARIABLES.businessDecisionArea NEQ "comunicacao"> hidden</cfif>>
        <div class="gd-area-summary"><h3>As notificações estão sendo lidas?</h3><p>Leituras confirmadas das notificações publicadas para usuários nos últimos 7 dias. Administradores excluídos.</p><a class="gd-text-link" href="/notificacoes/">Ver comunicação <i class="fa-solid fa-arrow-right" aria-hidden="true"></i></a></div>
        <dl class="gd-area-metrics"><div><dt>Taxa de leitura · 7 dias</dt><dd><cfif VARIABLES.businessAdminHomeNotificationsLoaded AND VARIABLES.businessAdminHomeNotifications7d GT 0><cfoutput>#LSNumberFormat(VARIABLES.businessAdminHomeNotificationReadRate7d,"9.9")#%</cfoutput><cfelse>—</cfif></dd></div><div><dt>Lidas / publicadas</dt><dd><cfoutput>#VARIABLES.businessDecisionNumber(VARIABLES.businessAdminHomeNotificationsRead7d,VARIABLES.businessAdminHomeNotificationsLoaded)# / #VARIABLES.businessDecisionNumber(VARIABLES.businessAdminHomeNotifications7d,VARIABLES.businessAdminHomeNotificationsLoaded)#</cfoutput></dd></div></dl>
        <cfif NOT VARIABLES.businessAdminHomeNotificationsLoaded><p class="gd-unavailable gd-area-wide">Dados de notificações indisponíveis.</p><cfelseif VARIABLES.businessAdminHomeNotifications7d EQ 0><p class="gd-caption gd-area-wide">Nenhuma notificação publicada para usuários nos últimos 7 dias.</p></cfif>
    </div>
</section>
<div class="gd-decision-footer"><p class="gd-caption">KPIs com cache de até 1 minuto · filas consultadas ao abrir a página.</p><cfoutput><a class="gd-refresh" href="/?periodo=#VARIABLES.businessDecisionDays#&amp;home_area=#VARIABLES.businessDecisionArea#" data-home-period><i class="fa-solid fa-rotate" aria-hidden="true"></i> Atualizar <small>#timeFormat(now(),"HH:nn")#</small></a></cfoutput></div>
