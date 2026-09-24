<cfscript>
function paidBannerReadParams(required struct context) {
    var globalScope=context.canReview AND context.accountId==0;
    if(!globalScope AND (!context.canView OR context.accountId<=0)) throw(type='AdsV1.Validation',message='Selecione uma conta autorizada para consultar banners.');
    return {account={value=context.accountId,cfsqltype='cf_sql_bigint'},global={value=globalScope,cfsqltype='cf_sql_bit'}};
}
function paidBannerCampaigns(required struct context,string campaignId='') {
    var p=paidBannerReadParams(context);
    if(len(campaignId) AND !paidBannerUuid(campaignId)) throw(type='AdsV1.Validation',message='Banner inválido.');
    p.campaign={value=campaignId,cfsqltype='cf_sql_varchar'};
    return queryExecute("SELECT c.campaign_id::text,c.account_id,ac.nome_conta AS account_name,c.name,c.status,c.version,
        c.starts_at,c.ends_at,c.cpc_bid,c.budget_total,c.budget_daily,c.target_device_class AS target_device,c.metadata::text,
        a.destination_url,cr.alt_text,coalesce(cr.payload->>'desktop_image_url',cr.image_url) AS image_url_desktop,
        cr.payload->>'mobile_image_url' AS image_url_mobile,
        coalesce(cr.payload->>'desktop_width',cr.width::text) AS width_desktop,
        coalesce(cr.payload->>'desktop_height',cr.height::text) AS height_desktop,
        cr.payload->>'mobile_width' AS width_mobile,cr.payload->>'mobile_height' AS height_mobile,
        CASE WHEN cr.payload->>'open_in_new_tab'='false' THEN '0' ELSE '1' END AS open_new_tab,
        coalesce(r.status,'NONE') AS review_status,r.campaign_review_request_id AS review_id,r.review_reason,
        coalesce(b.spent_total,0) AS spent_total,
        coalesce(m.impressions,0) AS impressions,coalesce(m.clicks,0) AS clicks,coalesce(m.billable_clicks,0) AS billable_clicks,coalesce(m.deliveries,0) AS deliveries,coalesce(m.cost,0) AS cost
      FROM ads.campaigns c JOIN public.tb_contas ac ON ac.id_conta=c.account_id
      JOIN LATERAL (SELECT a.* FROM ads.advertisements a WHERE a.campaign_id=c.campaign_id AND a.account_id=c.account_id AND a.ad_type='BANNER' AND a.billing_model='CPC' ORDER BY a.created_at DESC,a.advertisement_id LIMIT 1) a ON true
      JOIN LATERAL (SELECT cr.* FROM ads.creatives cr WHERE cr.advertisement_id=a.advertisement_id AND cr.campaign_id=c.campaign_id AND cr.account_id=c.account_id AND cr.ad_type='BANNER' AND cr.billing_model='CPC' ORDER BY cr.created_at DESC,cr.creative_id LIMIT 1) cr ON true
      LEFT JOIN LATERAL (SELECT r.* FROM ads.campaign_review_requests r WHERE r.campaign_id=c.campaign_id AND r.account_id=c.account_id AND r.ad_type='BANNER' ORDER BY r.campaign_review_request_id DESC LIMIT 1) r ON true
      LEFT JOIN ads.campaign_budget_state b ON b.campaign_id=c.campaign_id AND b.account_id=c.account_id
      LEFT JOIN LATERAL (SELECT sum(m.viewable_impression_count) AS impressions,sum(m.valid_click_count) AS clicks,sum(m.billable_click_count) AS billable_clicks,sum(m.served_count) AS deliveries,sum(m.cost) AS cost FROM ads.daily_metrics m WHERE m.campaign_id=c.campaign_id AND m.account_id=c.account_id AND m.ad_type='BANNER' AND m.billing_model='CPC') m ON true
      WHERE c.billing_model='CPC' AND (:global OR c.account_id=:account) AND (:campaign='' OR c.campaign_id::text=:campaign)
      ORDER BY CASE WHEN r.status='PENDING_REVIEW' THEN 0 ELSE 1 END,c.updated_at DESC,c.campaign_id",p,{datasource='runnerhub'});
}
function paidBannerDaily(required struct context,numeric days=30,string campaignId='') {
    var p=paidBannerReadParams(context);
    if(!listFind('7,30,90',days) OR (len(campaignId) AND !paidBannerUuid(campaignId))) throw(type='AdsV1.Validation',message='Filtro de desempenho inválido.');
    p.days={value=days-1,cfsqltype='cf_sql_integer'};p.campaign={value=campaignId,cfsqltype='cf_sql_varchar'};
    return queryExecute("WITH days AS (SELECT generate_series(current_date-(:days * interval '1 day'),current_date,interval '1 day')::date AS metric_date),
      metrics AS (SELECT m.metric_date,sum(m.viewable_impression_count)::bigint AS impressions,sum(m.valid_click_count)::bigint AS clicks,sum(m.cost) AS cost
        FROM ads.daily_metrics m WHERE m.ad_type='BANNER' AND m.billing_model='CPC' AND (:global OR m.account_id=:account)
          AND (:campaign='' OR m.campaign_id::text=:campaign) AND m.metric_date BETWEEN current_date-(:days * interval '1 day') AND current_date GROUP BY m.metric_date)
      SELECT d.metric_date,coalesce(m.impressions,0) AS impressions,coalesce(m.clicks,0) AS clicks,coalesce(m.cost,0) AS cost FROM days d LEFT JOIN metrics m ON m.metric_date=d.metric_date ORDER BY d.metric_date",p,{datasource='runnerhub'});
}
function paidBannerBalance(required struct context) {
    paidBannerReadParams(context);
    if(context.accountId<=0) return queryNew('available_balance');
    return queryExecute("SELECT coalesce((SELECT available_balance FROM ads.account_balances WHERE account_id=:account AND currency='BRL'),0) AS available_balance",{account={value=context.accountId,cfsqltype='cf_sql_bigint'}},{datasource='runnerhub'});
}
</cfscript>
