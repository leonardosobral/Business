<cfinclude template="banner_dashboard_helpers.cfm"/>
<cfset VARIABLES.bannerDashboardReady = false/>
<cfset qBannerDashboardChoices = queryNew('id_banner,nome')/>
<cfset qBannerDashboardDaily = queryNew('metric_date,impressions,clicks')/>
<cfset VARIABLES.bannerDashboardFilter = bannerDashboardFilters({},qBannerDashboardChoices)/>
<cfset VARIABLES.bannerDashboardRows = []/>
<!--- Read-only HOUSE/BANNER metrics. The chart filter is independent of the list status filter. --->
<cfif VARIABLES.bannerManagementIsAdmin AND VARIABLES.bannerManagementTablesReady AND VARIABLES.bannerManagementResponsiveReady>
    <cftry>
        <cfquery name="qBannerDashboardChoices" datasource="runnerhub">
            SELECT campaign.campaign_id::text AS id_banner, campaign.name AS nome
            FROM ads.campaigns campaign
            WHERE campaign.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.bannerOwnerAccountId#"/>
              AND campaign.billing_model = 'HOUSE'
              AND EXISTS (
                SELECT 1 FROM ads.advertisements advertisement
                WHERE advertisement.campaign_id = campaign.campaign_id
                  AND advertisement.account_id = campaign.account_id
                  AND advertisement.billing_model = 'HOUSE' AND advertisement.ad_type = 'BANNER'
              )
              AND EXISTS (
                SELECT 1 FROM ads.campaign_placements link
                JOIN ads.placements placement ON placement.placement_id = link.placement_id
                WHERE link.campaign_id = campaign.campaign_id AND link.account_id = campaign.account_id
                  AND placement.placement_key = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerPlacementKey#"/>
              )
            ORDER BY lower(campaign.name), campaign.campaign_id
        </cfquery>
        <cfset VARIABLES.bannerDashboardFilter = bannerDashboardFilters(URL,qBannerDashboardChoices)/>
        <cfif NOT VARIABLES.bannerDashboardFilter.invalidBanner>
            <cfquery name="qBannerDashboardDaily" datasource="runnerhub">
                WITH days AS (
                    SELECT generate_series(current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.bannerDashboardFilter.days - 1#"/> * interval '1 day'), current_date, interval '1 day')::date AS metric_date
                ), metrics AS (
                    SELECT metric.metric_date, sum(metric.viewable_impression_count)::bigint AS impressions,
                           sum(metric.valid_click_count)::bigint AS clicks
                    FROM ads.daily_metrics metric
                    WHERE metric.account_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.bannerOwnerAccountId#"/>
                      AND metric.billing_model = 'HOUSE' AND metric.ad_type = 'BANNER'
                      AND metric.metric_date >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.bannerDashboardFilter.days - 1#"/> * interval '1 day')
                      AND metric.metric_date <= current_date
                    <cfif qBannerDashboardChoices.recordcount>
                      AND metric.campaign_id::text IN (<cfqueryparam cfsqltype="cf_sql_varchar" value="#len(VARIABLES.bannerDashboardFilter.banner) ? VARIABLES.bannerDashboardFilter.banner : valueList(qBannerDashboardChoices.id_banner)#" list="true"/>)
                    <cfelse>
                      AND 1 = 0
                    </cfif>
                    GROUP BY metric.metric_date
                )
                SELECT days.metric_date, coalesce(metrics.impressions,0)::bigint AS impressions,
                       coalesce(metrics.clicks,0)::bigint AS clicks
                FROM days LEFT JOIN metrics ON metrics.metric_date = days.metric_date
                ORDER BY days.metric_date
            </cfquery>
            <cfloop query="qBannerDashboardDaily">
                <cfset arrayAppend(VARIABLES.bannerDashboardRows,{'date'=dateFormat(qBannerDashboardDaily.metric_date,'yyyy-mm-dd'),'impressions'=val(qBannerDashboardDaily.impressions),'clicks'=val(qBannerDashboardDaily.clicks)})/>
            </cfloop>
            <cfset VARIABLES.bannerDashboardReady = true/>
        </cfif>
        <cfcatch type="any">
            <cflog file="business_ads_v1" type="error" text="banner dashboard read actor=#VARIABLES.bannerManagementActorId# message=#cfcatch.message#"/>
        </cfcatch>
    </cftry>
</cfif>
<cfset VARIABLES.bannerDashboardSummary = bannerDashboardTotals(qBannerDashboardDaily)/>
