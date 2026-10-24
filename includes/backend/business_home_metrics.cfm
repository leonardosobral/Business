<!--- Aggregate-only source for the global-admin home; never exposes visitor/user identities. --->
<cfinclude template="require_admin.cfm"/>
<cfscript>
VARIABLES.businessHomeMetrics = {
    days = 7,
    audience = {loaded=false, comparison_ready=false, interactions_comparison_ready=false, visitors=0, pageviews=0, interactions=0, previous_visitors=0, previous_pageviews=0, previous_interactions=0},
    ads = {loaded=false, comparison_ready=false, impressions=0, clicks=0, cost=0, event_cost=0, banner_cost=0, previous_impressions=0, previous_clicks=0, previous_cost=0, previous_event_cost=0, previous_banner_cost=0},
    accounts = {loaded=false, comparison_ready=false, new_count=0, previous_new_count=0},
    users = {loaded=false, comparison_ready=false, new_count=0, previous_new_count=0}
};
if (structKeyExists(URL, "periodo") && isSimpleValue(URL.periodo) && reFind("^30$", trim(URL.periodo))) {
    VARIABLES.businessHomeMetrics.days = 30;
}
VARIABLES.businessHomeSql = {};

// Windows include today through now, compared with the preceding full calendar window.
// The view explicitly labels that partial-day comparison. All date boundaries are São Paulo.
// Interactions are exactly content_open, video_start and outbound_click. Engagement,
// visibility, video progress and completion beacons cannot inflate an intentional action.
// Group browser presence with hash aggregation before counting it. Keeping visitor
// identity separate from the four activity kinds avoids sorting every passive beacon
// twice, while still counting browsers whose only observed event is a passive beacon.
// Interaction coverage is independent: a newly observed action cannot suppress an
// otherwise established visitor/pageview comparison or invent comparable actions.
// BEGIN AUDIENCE SQL
VARIABLES.businessHomeSql.audience = "
    WITH clock AS (
        SELECT now() AS until_at, (now() AT TIME ZONE 'America/Sao_Paulo')::date AS today
    ), bounds AS NOT MATERIALIZED (
        SELECT until_at,
               (today - (CAST(:days AS integer) - 1))::timestamp AT TIME ZONE 'America/Sao_Paulo' AS current_at,
               (today - (2 * CAST(:days AS integer) - 1))::timestamp AT TIME ZONE 'America/Sao_Paulo' AS previous_at
        FROM clock
    ), measured AS NOT MATERIALIZED (
        SELECT e.visitor_id, e.page_view_id, e.event_kind, e.occurred_at
        FROM audience.events e CROSS JOIN bounds b
        WHERE e.environment = 'prod' AND e.is_internal = false
          AND e.occurred_at >= b.previous_at - interval '1 day'
          AND e.occurred_at <= b.until_at
    ), visitor_presence AS (
        SELECT e.visitor_id,
               bool_or(e.occurred_at >= b.current_at) AS has_current,
               bool_or(e.occurred_at >= b.previous_at AND e.occurred_at < b.current_at) AS has_previous
        FROM measured e CROSS JOIN bounds b
        WHERE e.visitor_id IS NOT NULL
        GROUP BY e.visitor_id
    ), visitor_totals AS (
        SELECT count(*) FILTER (WHERE has_current) AS visitors,
               count(*) FILTER (WHERE has_previous) AS previous_visitors
        FROM visitor_presence
    ), activity_totals AS (
        SELECT count(DISTINCT e.page_view_id) FILTER (WHERE e.occurred_at >= b.current_at AND e.event_kind = 'page_view') AS pageviews,
               count(*) FILTER (WHERE e.occurred_at >= b.current_at AND e.event_kind IN ('content_open','video_start','outbound_click')) AS interactions,
               count(DISTINCT e.page_view_id) FILTER (WHERE e.occurred_at >= b.previous_at AND e.occurred_at < b.current_at AND e.event_kind = 'page_view') AS previous_pageviews,
               count(*) FILTER (WHERE e.occurred_at >= b.previous_at AND e.occurred_at < b.current_at AND e.event_kind IN ('content_open','video_start','outbound_click')) AS previous_interactions,
               count(DISTINCT (e.occurred_at AT TIME ZONE 'America/Sao_Paulo')::date)
                   FILTER (WHERE e.occurred_at >= b.previous_at AND e.event_kind = 'page_view') AS observed_days,
               count(*) FILTER (WHERE e.occurred_at < b.previous_at AND e.event_kind = 'page_view') > 0 AS established_pages,
               count(DISTINCT e.event_kind) FILTER (WHERE e.occurred_at < b.previous_at
                   AND e.event_kind IN ('page_view','content_open','video_start','outbound_click')) = 4 AS established_interactions
        FROM measured e CROSS JOIN bounds b
        WHERE e.event_kind IN ('page_view','content_open','video_start','outbound_click')
    )
    SELECT visitors, pageviews, interactions, previous_visitors, previous_pageviews, previous_interactions,
           observed_days = 2 * CAST(:days AS integer) AND established_pages AS comparison_ready,
           observed_days = 2 * CAST(:days AS integer) AND established_interactions AS interactions_comparison_ready
    FROM visitor_totals CROSS JOIN activity_totals
";
// END AUDIENCE SQL

// daily_metrics is sparse: zero-activity days need no row. A type with activity must
// have history before the prior window; EVENT and BANNER readiness are checked separately.
// BEGIN ADS SQL
VARIABLES.businessHomeSql.ads = "
    WITH bounds AS (
        SELECT (now() AT TIME ZONE 'America/Sao_Paulo')::date AS today,
               (now() AT TIME ZONE 'America/Sao_Paulo')::date - (CAST(:days AS integer) - 1) AS current_date,
               (now() AT TIME ZONE 'America/Sao_Paulo')::date - (2 * CAST(:days AS integer) - 1) AS previous_date
    ), measured AS MATERIALIZED (
        SELECT m.metric_date, m.ad_type, m.viewable_impression_count, m.valid_click_count, m.cost
        FROM ads.daily_metrics m CROSS JOIN bounds b
        WHERE m.metric_date >= b.previous_date AND m.metric_date <= b.today
          AND m.billing_model = 'CPC' AND m.ad_type IN ('EVENT','BANNER')
    ), coverage AS (
        SELECT EXISTS (
            SELECT 1 FROM ads.daily_metrics old CROSS JOIN bounds b
            WHERE old.metric_date < b.previous_date AND old.billing_model = 'CPC'
              AND old.ad_type IN ('EVENT','BANNER')
        ) AND NOT EXISTS (
            SELECT 1 FROM (VALUES ('EVENT'),('BANNER')) types(ad_type)
            WHERE EXISTS (SELECT 1 FROM measured m WHERE m.ad_type = types.ad_type
                AND (m.viewable_impression_count > 0 OR m.valid_click_count > 0 OR m.cost > 0))
              AND NOT EXISTS (SELECT 1 FROM ads.daily_metrics old CROSS JOIN bounds b
                WHERE old.ad_type = types.ad_type AND old.billing_model = 'CPC' AND old.metric_date < b.previous_date)
        ) AS comparison_ready
    )
    SELECT coalesce(sum(m.viewable_impression_count) FILTER (WHERE m.metric_date >= b.current_date),0) AS impressions,
           coalesce(sum(m.valid_click_count) FILTER (WHERE m.metric_date >= b.current_date),0) AS clicks,
           coalesce(sum(m.cost) FILTER (WHERE m.metric_date >= b.current_date),0) AS cost,
           coalesce(sum(m.cost) FILTER (WHERE m.metric_date >= b.current_date AND m.ad_type = 'EVENT'),0) AS event_cost,
           coalesce(sum(m.cost) FILTER (WHERE m.metric_date >= b.current_date AND m.ad_type = 'BANNER'),0) AS banner_cost,
           coalesce(sum(m.viewable_impression_count) FILTER (WHERE m.metric_date < b.current_date),0) AS previous_impressions,
           coalesce(sum(m.valid_click_count) FILTER (WHERE m.metric_date < b.current_date),0) AS previous_clicks,
           coalesce(sum(m.cost) FILTER (WHERE m.metric_date < b.current_date),0) AS previous_cost,
           coalesce(sum(m.cost) FILTER (WHERE m.metric_date < b.current_date AND m.ad_type = 'EVENT'),0) AS previous_event_cost,
           coalesce(sum(m.cost) FILTER (WHERE m.metric_date < b.current_date AND m.ad_type = 'BANNER'),0) AS previous_banner_cost,
           (SELECT comparison_ready FROM coverage) AS comparison_ready
    FROM measured m CROSS JOIN bounds b
";
// END ADS SQL

// Account creation is timestamptz; all account statuses represent a new registration.
// BEGIN ACCOUNTS SQL
VARIABLES.businessHomeSql.accounts = "
    WITH bounds AS (
        SELECT now() AS until_at,
               ((now() AT TIME ZONE 'America/Sao_Paulo')::date - (CAST(:days AS integer) - 1))::timestamp AT TIME ZONE 'America/Sao_Paulo' AS current_at,
               ((now() AT TIME ZONE 'America/Sao_Paulo')::date - (2 * CAST(:days AS integer) - 1))::timestamp AT TIME ZONE 'America/Sao_Paulo' AS previous_at
    )
    SELECT count(*) FILTER (WHERE c.data_criacao >= b.current_at) AS new_count,
           count(*) FILTER (WHERE c.data_criacao < b.current_at) AS previous_new_count,
           EXISTS (SELECT 1 FROM public.tb_contas older CROSS JOIN bounds history
                   WHERE older.data_criacao < history.previous_at) AS comparison_ready
    FROM public.tb_contas c CROSS JOIN bounds b
    WHERE c.data_criacao >= b.previous_at AND c.data_criacao <= b.until_at
";
// END ACCOUNTS SQL

// User creation is a local timestamp, unlike account creation. Match explicit local
// boundaries and the existing management semantics: absent state means active/not deleted.
// BEGIN USERS SQL
VARIABLES.businessHomeSql.users = "
    WITH bounds AS (
        SELECT now() AT TIME ZONE 'America/Sao_Paulo' AS until_at,
               ((now() AT TIME ZONE 'America/Sao_Paulo')::date - (CAST(:days AS integer) - 1))::timestamp AS current_at,
               ((now() AT TIME ZONE 'America/Sao_Paulo')::date - (2 * CAST(:days AS integer) - 1))::timestamp AS previous_at
    )
    SELECT count(*) FILTER (WHERE u.data_criacao >= b.current_at) AS new_count,
           count(*) FILTER (WHERE u.data_criacao < b.current_at) AS previous_new_count,
           EXISTS (SELECT 1 FROM public.tb_usuarios older CROSS JOIN bounds history
                   WHERE older.data_criacao < history.previous_at
                     AND NOT EXISTS (SELECT 1 FROM public.tb_usuarios_gestao old_state
                         WHERE old_state.id_usuario = older.id
                           AND (NOT coalesce(old_state.ativo,true) OR coalesce(old_state.excluido,false)))) AS comparison_ready
    FROM public.tb_usuarios u CROSS JOIN bounds b
    WHERE u.data_criacao >= b.previous_at AND u.data_criacao <= b.until_at
      AND NOT EXISTS (SELECT 1 FROM public.tb_usuarios_gestao state WHERE state.id_usuario = u.id
                      AND (NOT coalesce(state.ativo,true) OR coalesce(state.excluido,false)))
";
// END USERS SQL

VARIABLES.businessHomeMetricParams = {days={value=VARIABLES.businessHomeMetrics.days,cfsqltype="cf_sql_integer"}};
VARIABLES.businessHomeMetricOptions = {datasource="runnerhub", timeout=5, cachedWithin=createTimeSpan(0,0,1,0)};
for (VARIABLES.businessHomeSource in ["audience","ads","accounts","users"]) {
    try {
        VARIABLES.businessHomeResult = queryExecute(VARIABLES.businessHomeSql[VARIABLES.businessHomeSource], VARIABLES.businessHomeMetricParams, VARIABLES.businessHomeMetricOptions);
        if (VARIABLES.businessHomeResult.recordCount == 1) {
            for (VARIABLES.businessHomeColumn in listToArray(VARIABLES.businessHomeResult.columnList)) {
                if (structKeyExists(VARIABLES.businessHomeMetrics[VARIABLES.businessHomeSource], VARIABLES.businessHomeColumn)) {
                    VARIABLES.businessHomeMetrics[VARIABLES.businessHomeSource][VARIABLES.businessHomeColumn] = VARIABLES.businessHomeResult[VARIABLES.businessHomeColumn][1];
                }
            }
            VARIABLES.businessHomeMetrics[VARIABLES.businessHomeSource].loaded = true;
        }
    } catch (any businessHomeMetricError) {
        // Each source fails independently. The view checks loaded before rendering numbers.
        // Database diagnostics and credentials must never be copied to the response.
    }
}
</cfscript>
