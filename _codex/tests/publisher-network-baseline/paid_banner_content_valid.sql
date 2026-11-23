CREATE OR REPLACE FUNCTION ads.paid_banner_content_valid(p_campaign_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
SELECT EXISTS(SELECT 1 FROM ads.campaigns c
 JOIN ads.advertisements a ON a.campaign_id=c.campaign_id AND a.account_id=c.account_id AND a.billing_model='CPC' AND a.ad_type='BANNER' AND a.core_event_id IS NULL AND a.status='ACTIVE'
 JOIN ads.creatives r ON r.advertisement_id=a.advertisement_id AND r.status='ACTIVE' AND r.creative_type='IMAGE'
 JOIN ads.campaign_placements cp ON cp.campaign_id=c.campaign_id AND cp.status='ACTIVE'
 JOIN ads.placements p ON p.placement_id=cp.placement_id AND p.placement_key='rr-sidebar-banner-300x250' AND p.status='ACTIVE' AND p.format_key='IMAGE'
 WHERE c.campaign_id=p_campaign_id AND c.billing_model='CPC' AND c.cpc_bid>=0.51 AND c.budget_total>=c.cpc_bid AND (c.budget_daily IS NULL OR c.budget_daily>=c.cpc_bid)
 AND c.starts_at IS NOT NULL AND c.ends_at>c.starts_at AND ads.normalize_banner_scope(c.metadata->'banner_scope_v1') IS NOT NULL
 AND ads.paid_banner_public_https(a.destination_url) AND ads.paid_banner_public_https(r.image_url) AND ads.paid_banner_public_https(r.payload->>'mobile_image_url')
 AND length(btrim(r.alt_text)) BETWEEN 1 AND 500 AND r.width BETWEEN 1 AND 8192 AND r.height BETWEEN 1 AND 8192
 AND (r.payload->>'mobile_width')::integer BETWEEN 1 AND 8192 AND (r.payload->>'mobile_height')::integer BETWEEN 1 AND 8192 AND jsonb_typeof(r.payload->'open_in_new_tab')='boolean'
 AND (SELECT count(*) FROM ads.advertisements x WHERE x.campaign_id=c.campaign_id AND x.status<>'ARCHIVED')=1
 AND (SELECT count(*) FROM ads.creatives x WHERE x.campaign_id=c.campaign_id AND x.status<>'ARCHIVED')=1
 AND (SELECT count(*) FROM ads.campaign_placements x WHERE x.campaign_id=c.campaign_id AND x.status='ACTIVE')=1);
$function$
