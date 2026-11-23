CREATE OR REPLACE FUNCTION ads.select_paid_banner_candidate(p_placement_key text, p_requested_at timestamp with time zone DEFAULT clock_timestamp(), p_device_class text DEFAULT 'ALL'::text, p_country_code character DEFAULT 'BR'::bpchar, p_region_code text DEFAULT NULL::text, p_banner_page text DEFAULT NULL::text)
 RETURNS TABLE(campaign_id uuid, account_id bigint, advertisement_id uuid, creative_id uuid, placement_id uuid, placement_key text, ad_type text, core_event_id integer, destination_url text, billing_model text, price_candidate numeric, currency character, creative_type text, title text, body text, image_url text, alt_text text, width integer, height integer, creative_payload jsonb, priority integer, weight integer)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
WITH eligible AS (
 SELECT c.*,a.advertisement_id,a.destination_url,r.creative_id,r.creative_type,r.title,r.body,r.image_url,r.alt_text,r.width,r.height,r.payload,p.placement_id,p.placement_key,cp.priority,cp.weight,
 CASE WHEN c.metadata->'banner_scope_v1'->>'regions_mode'='SELECTED' THEN 2.0 ELSE 1.2 END AS relevance
 FROM ads.campaigns c JOIN public.tb_contas ac ON ac.id_conta=c.account_id AND ac.status::text='ATIVA'
 JOIN ads.campaign_placements cp ON cp.campaign_id=c.campaign_id AND cp.status='ACTIVE'
 JOIN ads.placements p ON p.placement_id=cp.placement_id AND p.status='ACTIVE' AND p.placement_key=p_placement_key AND p.placement_key='rr-sidebar-banner-300x250'
 JOIN ads.advertisements a ON a.campaign_id=c.campaign_id AND a.status='ACTIVE' AND a.ad_type='BANNER'
 JOIN ads.creatives r ON r.advertisement_id=a.advertisement_id AND r.status='ACTIVE'
 JOIN ads.account_balances b ON b.account_id=c.account_id AND b.currency=c.currency AND b.available_balance>=c.cpc_bid
 JOIN ads.campaign_budget_state bs ON bs.campaign_id=c.campaign_id AND bs.spent_total+c.cpc_bid<=c.budget_total
 WHERE c.billing_model='CPC' AND c.status='ACTIVE' AND c.starts_at<=p_requested_at AND c.ends_at>=p_requested_at
 AND p_device_class IN('ALL','DESKTOP','MOBILE') AND (p.device_class='ALL' OR p.device_class=p_device_class)
 AND (c.target_device_class='ALL' OR c.target_device_class=p_device_class) AND (c.target_country_code IS NULL OR c.target_country_code=p_country_code)
 AND (c.target_region_code IS NULL OR c.target_region_code=upper(btrim(p_region_code))) AND c.frequency_cap_count IS NULL
 AND (c.budget_daily IS NULL OR bs.spent_date<ads.business_date(p_requested_at) OR bs.spent_today+c.cpc_bid<=c.budget_daily)
 AND NOT EXISTS(SELECT 1 FROM ads.account_financial_holds h WHERE h.account_id=c.account_id AND h.status='OPEN')
 AND ads.banner_scope_matches(c.metadata,p_region_code,p_banner_page) AND ads.paid_banner_approved(c.campaign_id)
), ranked AS (
 SELECT e.*,lead(e.cpc_bid*e.relevance) OVER(ORDER BY e.cpc_bid*e.relevance DESC,e.campaign_id) AS next_score FROM eligible e
)
SELECT c.campaign_id,c.account_id,c.advertisement_id,c.creative_id,c.placement_id,c.placement_key,'BANNER'::text,NULL::integer,c.destination_url,'CPC'::text,
 ads.event_auction_price(c.cpc_bid,c.relevance,c.next_score,0.51),c.currency,c.creative_type,c.title,c.body,c.image_url,c.alt_text,c.width,c.height,c.payload,c.priority,c.weight
FROM ranked c ORDER BY c.cpc_bid*c.relevance DESC,c.campaign_id LIMIT 1;
$function$
