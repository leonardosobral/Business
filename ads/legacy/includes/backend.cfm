<cfset VARIABLES.adsLegacyRealUserId = 0/>
<cfset VARIABLES.adsLegacyRealUserName = ""/>
<cfset VARIABLES.adsLegacyReady = false/>
<cfset VARIABLES.adsLegacyError = ""/>

<cfset qAdsLegacySummary = QueryNew("campaigns_total,campaigns_active,campaigns_paused,campaigns_archived,views_total,clicks_total,cost_total")/>
<cfset qAdsLegacyCampaigns = QueryNew("id_ad_evento,nome_evento,tag,cidade,estado,status,cpc_max,limite_diario,limite_ad,inicio_ad,final_ad,contas,views,clicks,cost_total")/>

<cfif isDefined("qPerfil") AND qPerfil.recordcount AND isDefined("qPerfil.id") AND isNumeric(qPerfil.id)>
    <cfset VARIABLES.adsLegacyRealUserId = val(qPerfil.id)/>
    <cfif isDefined("qPerfil.name")>
        <cfset VARIABLES.adsLegacyRealUserName = trim(qPerfil.name & "")/>
    </cfif>
</cfif>

<cftry>
    <cfquery name="qAdsLegacySummary" datasource="runnerhub">
        WITH campaign_metrics AS (
            SELECT ad.id_ad_evento,
                   count(log.id_ad_log) FILTER (WHERE log.status <= 2) AS views,
                   count(log.id_ad_log) FILTER (WHERE log.status = 2) AS clicks,
                   coalesce(sum(log.valor_ad) FILTER (WHERE log.status = 2), 0) AS cost_total
            FROM ads.tb_ad_eventos ad
            LEFT JOIN ads.tb_ad_log log ON log.id_ad = ad.id_ad_evento
            GROUP BY ad.id_ad_evento
        )
        SELECT count(*)::integer AS campaigns_total,
               count(*) FILTER (WHERE ad.status < 3)::integer AS campaigns_active,
               count(*) FILTER (WHERE ad.status = 3)::integer AS campaigns_paused,
               count(*) FILTER (WHERE ad.status = 4)::integer AS campaigns_archived,
               coalesce(sum(metric.views), 0)::bigint AS views_total,
               coalesce(sum(metric.clicks), 0)::bigint AS clicks_total,
               coalesce(sum(metric.cost_total), 0)::numeric(14, 2) AS cost_total
        FROM ads.tb_ad_eventos ad
        LEFT JOIN campaign_metrics metric ON metric.id_ad_evento = ad.id_ad_evento
    </cfquery>

    <cfquery name="qAdsLegacyCampaigns" datasource="runnerhub">
        SELECT ad.id_ad_evento,
               evt.nome_evento,
               evt.tag,
               evt.cidade,
               evt.estado,
               ad.status,
               ad.cpc_max,
               ad.limite_diario,
               ad.limite_ad,
               ad.inicio_ad,
               ad.final_ad,
               account_scope.contas,
               coalesce(metric.views, 0)::bigint AS views,
               coalesce(metric.clicks, 0)::bigint AS clicks,
               coalesce(metric.cost_total, 0)::numeric(14, 2) AS cost_total
        FROM ads.tb_ad_eventos ad
        INNER JOIN public.tb_evento_corridas evt ON evt.id_evento = ad.id_evento
        LEFT JOIN LATERAL (
            SELECT string_agg(DISTINCT cont.nome_conta, ', ' ORDER BY cont.nome_conta) AS contas
            FROM public.tb_conta_eventos ce
            INNER JOIN public.tb_contas cont ON cont.id_conta = ce.id_conta
            WHERE ce.id_evento = ad.id_evento
        ) account_scope ON true
        LEFT JOIN LATERAL (
            SELECT count(log.id_ad_log) FILTER (WHERE log.status <= 2) AS views,
                   count(log.id_ad_log) FILTER (WHERE log.status = 2) AS clicks,
                   coalesce(sum(log.valor_ad) FILTER (WHERE log.status = 2), 0) AS cost_total
            FROM ads.tb_ad_log log
            WHERE log.id_ad = ad.id_ad_evento
        ) metric ON true
        ORDER BY ad.id_ad_evento DESC
        LIMIT 100
    </cfquery>

    <cfset VARIABLES.adsLegacyReady = true/>

    <cfcatch type="any">
        <cfset VARIABLES.adsLegacyReady = false/>
        <cfset VARIABLES.adsLegacyError = "Nao foi possivel carregar o historico anterior."/>
        <cflog file="business_ads_legacy" type="error" text="read-only user=#VARIABLES.adsLegacyRealUserId# message=#left(cfcatch.message & '', 1000)#"/>
    </cfcatch>
</cftry>
