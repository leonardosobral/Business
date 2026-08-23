<!---
    Historico do sistema anterior, incorporado ao painel atual.
    Este include e estritamente somente leitura e usa a conta efetiva ja
    autenticada pelo backend de Publicidade.
--->
<cfset VARIABLES.adsLegacyHistoryReady = false/>
<cfset VARIABLES.adsLegacyHistoryError = ""/>
<cfset qAdsLegacyHistoryCampaigns = QueryNew("id_ad_evento,id_evento,nome_evento,tag,cidade,estado,status,cpc_max,inicio_ad,final_ad,views,clicks,conversions,cost_total")/>
<cfset qAdsLegacyHistoryVouchers = QueryNew("id_ad_voucher,codigo,credito,credito_disponivel,status,data_criacao,data_expiracao,data_resgate,observacao")/>

<cfif VARIABLES.adsAccessCanView
    AND VARIABLES.adsV1HasAccount
    AND VARIABLES.adsV1AccountId GT 0>
    <cftry>
        <cfquery name="qAdsLegacyHistoryCampaigns" datasource="runnerhub">
            SELECT ad.id_ad_evento,
                   ad.id_evento,
                   event.nome_evento,
                   event.tag,
                   event.cidade,
                   event.estado,
                   ad.status,
                   coalesce(ad.cpc_max, 0)::numeric(14, 2) AS cpc_max,
                   ad.inicio_ad,
                   ad.final_ad,
                   coalesce(metric.views, 0)::bigint AS views,
                   coalesce(metric.clicks, 0)::bigint AS clicks,
                   coalesce(conversion.conversions, 0)::bigint AS conversions,
                   coalesce(metric.cost_total, 0)::numeric(14, 2) AS cost_total
            FROM ads.tb_ad_eventos ad
            INNER JOIN public.tb_evento_corridas event
              ON event.id_evento = ad.id_evento
            LEFT JOIN LATERAL (
                SELECT coalesce(sum(metric_day.views), 0)::bigint AS views,
                       coalesce(sum(metric_day.clicks), 0)::bigint AS clicks,
                       coalesce(sum(metric_day.custo), 0)::numeric(14, 2) AS cost_total
                FROM ads.tb_ad_evento_metricas_dia metric_day
                WHERE metric_day.id_ad_evento = ad.id_ad_evento
                  AND metric_day.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
            ) metric ON true
            LEFT JOIN LATERAL (
                SELECT count(*)::bigint AS conversions
                FROM ads.tb_ad_conversion_log conversion_log
                WHERE conversion_log.id_ad_evento = ad.id_ad_evento
                  AND conversion_log.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
            ) conversion ON true
            WHERE EXISTS (
                SELECT 1
                FROM public.tb_conta_eventos account_event
                WHERE account_event.id_evento = ad.id_evento
                  AND account_event.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
            )
            ORDER BY coalesce(ad.final_ad, ad.inicio_ad) DESC NULLS LAST,
                     ad.id_ad_evento DESC
            LIMIT 100
        </cfquery>

        <cfquery name="qAdsLegacyHistoryVouchers" datasource="runnerhub">
            SELECT voucher.id_ad_voucher,
                   voucher.codigo,
                   coalesce(voucher.credito, 0)::numeric(14, 2) AS credito,
                   coalesce(voucher.credito_disponivel, voucher.credito, 0)::numeric(14, 2) AS credito_disponivel,
                   voucher.status,
                   voucher.data_criacao,
                   voucher.data_expiracao,
                   voucher.data_resgate,
                   voucher.observacao
            FROM ads.tb_ad_vouchers voucher
            WHERE voucher.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.adsV1AccountId#"/>
              AND (
                  voucher.data_resgate IS NOT NULL
                  OR voucher.status <> 1
              )
            ORDER BY voucher.data_resgate DESC NULLS LAST,
                     voucher.data_criacao DESC,
                     voucher.id_ad_voucher DESC
            LIMIT 50
        </cfquery>

        <cfset VARIABLES.adsLegacyHistoryReady = true/>

        <cfcatch type="any">
            <cfset VARIABLES.adsLegacyHistoryReady = false/>
            <cfset VARIABLES.adsLegacyHistoryError = "O historico do sistema anterior nao pode ser carregado agora."/>
            <cflog file="business_ads_legacy" type="error" text="embedded-read account=#VARIABLES.adsV1AccountId# actor=#VARIABLES.adsV1ActorId# message=#left(cfcatch.message & '', 1000)#"/>
        </cfcatch>
    </cftry>
</cfif>

<section class="card shadow-0 mb-4">
    <details class="ads-legacy-history">
        <summary class="card-body p-3 p-lg-4">
            <span class="badge badge-secondary mb-2">Sistema anterior</span>
            <span class="d-block h5 mb-1">Historico de publicidade</span>
            <span class="d-block text-muted small">Campanhas e vouchers anteriores, preservados somente para consulta.</span>
        </summary>

        <div class="card-body border-top p-3 p-lg-4">
            <p class="text-muted mb-4">
                Este historico e somente leitura e nao altera o saldo atual. Para uma nova veiculacao, crie uma nova campanha no sistema atual.
            </p>

            <cfif NOT VARIABLES.adsLegacyHistoryReady>
                <div class="alert alert-warning mb-0">
                    <cfoutput>#htmlEditFormat(VARIABLES.adsLegacyHistoryError)#</cfoutput>
                </div>
            <cfelse>
                <h3 class="h6 mb-3">Campanhas anteriores</h3>
                <cfif qAdsLegacyHistoryCampaigns.recordcount>
                    <div class="table-responsive mb-4">
                        <table class="table table-sm align-middle mb-0" style="min-width: 900px;">
                            <thead>
                                <tr><th>Campanha / evento</th><th>Status</th><th>Periodo</th><th class="text-end">CPC</th><th class="text-end">Views</th><th class="text-end">Cliques</th><th class="text-end">Conversoes</th><th class="text-end">Custo</th></tr>
                            </thead>
                            <tbody>
                                <cfoutput query="qAdsLegacyHistoryCampaigns">
                                    <cfset VARIABLES.adsLegacyHistoryStatus = "Status " & qAdsLegacyHistoryCampaigns.status/>
                                    <cfif qAdsLegacyHistoryCampaigns.status LT 3><cfset VARIABLES.adsLegacyHistoryStatus = "Ativa na epoca"/></cfif>
                                    <cfif qAdsLegacyHistoryCampaigns.status EQ 3><cfset VARIABLES.adsLegacyHistoryStatus = "Pausada"/></cfif>
                                    <cfif qAdsLegacyHistoryCampaigns.status EQ 4><cfset VARIABLES.adsLegacyHistoryStatus = "Finalizada"/></cfif>
                                    <tr>
                                        <td><strong>Destaque ###numberFormat(id_ad_evento, "0")#</strong><div>#htmlEditFormat(nome_evento)#</div><div class="small text-muted">#htmlEditFormat(cidade)#<cfif len(trim(estado & ""))>/#htmlEditFormat(estado)#</cfif></div></td>
                                        <td><span class="badge badge-secondary">#htmlEditFormat(VARIABLES.adsLegacyHistoryStatus)#</span></td>
                                        <td><cfif isDate(inicio_ad)>#lsDateFormat(inicio_ad, "dd/mm/yyyy")#<cfelse>-</cfif> a <cfif isDate(final_ad)>#lsDateFormat(final_ad, "dd/mm/yyyy")#<cfelse>-</cfif></td>
                                        <td class="text-end">#lsCurrencyFormat(cpc_max)#</td>
                                        <td class="text-end">#numberFormat(views, "9,999,999")#</td>
                                        <td class="text-end">#numberFormat(clicks, "9,999,999")#</td>
                                        <td class="text-end">#numberFormat(conversions, "9,999,999")#</td>
                                        <td class="text-end">#lsCurrencyFormat(cost_total)#</td>
                                    </tr>
                                </cfoutput>
                            </tbody>
                        </table>
                    </div>
                <cfelse>
                    <p class="text-muted">Nenhuma campanha anterior encontrada para esta conta.</p>
                </cfif>

                <h3 class="h6 mb-3">Vouchers anteriores</h3>
                <cfif qAdsLegacyHistoryVouchers.recordcount>
                    <div class="table-responsive">
                        <table class="table table-sm align-middle mb-0">
                            <thead>
                                <tr><th>Codigo</th><th>Status</th><th class="text-end">Credito inicial</th><th class="text-end">Saldo historico</th><th>Resgate</th><th>Expiracao</th></tr>
                            </thead>
                            <tbody>
                                <cfoutput query="qAdsLegacyHistoryVouchers">
                                    <cfset VARIABLES.adsLegacyVoucherStatus = "Status " & qAdsLegacyHistoryVouchers.status/>
                                    <cfif qAdsLegacyHistoryVouchers.status EQ 2><cfset VARIABLES.adsLegacyVoucherStatus = "Resgatado"/></cfif>
                                    <cfif qAdsLegacyHistoryVouchers.status EQ 3><cfset VARIABLES.adsLegacyVoucherStatus = "Encerrado"/></cfif>
                                    <tr>
                                        <td><strong>#htmlEditFormat(codigo)#</strong></td>
                                        <td><span class="badge badge-secondary">#htmlEditFormat(VARIABLES.adsLegacyVoucherStatus)#</span></td>
                                        <td class="text-end">#lsCurrencyFormat(credito)#</td>
                                        <td class="text-end">#lsCurrencyFormat(credito_disponivel)#</td>
                                        <td><cfif isDate(data_resgate)>#lsDateFormat(data_resgate, "dd/mm/yyyy")#<cfelse>-</cfif></td>
                                        <td><cfif isDate(data_expiracao)>#lsDateFormat(data_expiracao, "dd/mm/yyyy")#<cfelse>-</cfif></td>
                                    </tr>
                                </cfoutput>
                            </tbody>
                        </table>
                    </div>
                <cfelse>
                    <p class="text-muted mb-0">Nenhum voucher anterior resgatado ou encerrado para esta conta.</p>
                </cfif>
            </cfif>
        </div>
    </details>
</section>
