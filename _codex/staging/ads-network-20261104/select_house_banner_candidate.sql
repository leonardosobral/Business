CREATE OR REPLACE FUNCTION ads.select_house_banner_candidate(p_placement_key text, p_requested_at timestamp with time zone DEFAULT clock_timestamp(), p_device_class text DEFAULT 'ALL'::text, p_country_code character DEFAULT 'BR'::bpchar, p_region_code text DEFAULT NULL::text, p_banner_page text DEFAULT NULL::text)
 RETURNS TABLE(campaign_id uuid, account_id bigint, advertisement_id uuid, creative_id uuid, placement_id uuid, placement_key text, ad_type text, core_event_id integer, destination_url text, billing_model text, price_candidate numeric, currency character, creative_type text, title text, body text, image_url text, alt_text text, width integer, height integer, creative_payload jsonb, priority integer, weight integer)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
WITH raw_context AS (
    SELECT nullif(trim(p_placement_key), '') AS placement_key,
           coalesce(p_requested_at, clock_timestamp()) AS requested_at,
           upper(coalesce(nullif(trim(p_device_class), ''), 'ALL'))
               AS device_class,
           upper(coalesce(nullif(trim(p_country_code), ''), 'BR'))
               AS country_code,
           upper(nullif(trim(p_region_code), '')) AS region_code,
           nullif(trim(NULL::text), '') AS anonymous_id_hash,
           ARRAY(
               SELECT DISTINCT upper(trim(value))
                 FROM unnest(coalesce(
                     ARRAY['BANNER']::text[],
                     ARRAY[]::text[]
                 )) value
                WHERE nullif(trim(value), '') IS NOT NULL
           ) AS allowed_ad_types,
           coalesce(
               ARRAY[]::uuid[],
               ARRAY[]::uuid[]
           ) AS excluded_campaign_ids
),
normalized AS (
    SELECT raw.*,
           raw.device_class IN ('ALL', 'DESKTOP', 'MOBILE')
           AND raw.country_code ~ '^[A-Z]{2}$'
           AND cardinality(raw.allowed_ad_types) > 0
           AND NOT EXISTS (
               SELECT 1
                 FROM unnest(raw.allowed_ad_types) allowed(ad_type)
                WHERE allowed.ad_type NOT IN ('EVENT', 'BANNER')
           ) AS valid_context
      FROM raw_context raw
),
eligible_campaigns AS (
    SELECT campaign.campaign_id,
           campaign.account_id,
           campaign.billing_model,
           campaign.cpc_bid,
           campaign.currency,
           campaign.target_region_code,
           campaign.metadata AS banner_scope_metadata,
           campaign.frequency_cap_count,
           campaign.frequency_cap_window_minutes,
           placement.placement_id,
           placement.placement_key,
           placement.format_key,
           link.priority,
           link.weight,
           normalized.requested_at,
           normalized.region_code,
           normalized.anonymous_id_hash,
           normalized.allowed_ad_types
      FROM normalized
      JOIN ads.placements placement
        ON placement.placement_key = normalized.placement_key
       AND placement.status = 'ACTIVE'
       AND (
           placement.device_class = 'ALL'
           OR placement.device_class = normalized.device_class
       )
      JOIN ads.campaign_placements link
        ON link.placement_id = placement.placement_id
       AND link.status = 'ACTIVE'
      JOIN ads.campaigns campaign
        ON campaign.campaign_id = link.campaign_id
       AND campaign.account_id = link.account_id
       AND campaign.billing_model = link.billing_model
       AND campaign.status = 'ACTIVE'
       AND campaign.starts_at <= normalized.requested_at
       AND campaign.ends_at >= normalized.requested_at
       AND campaign.campaign_id <>
           ALL(normalized.excluded_campaign_ids)
       AND (
           campaign.target_device_class = 'ALL'
           OR campaign.target_device_class = normalized.device_class
       )
       AND (
           campaign.target_country_code IS NULL
           OR campaign.target_country_code::text = normalized.country_code
       )
       AND (
           campaign.target_region_code IS NULL
           OR campaign.target_region_code = normalized.region_code
       )
      JOIN public.tb_contas account
        ON account.id_conta = campaign.account_id
       AND account.status::text = 'ATIVA'
     WHERE normalized.valid_context
       AND (
           campaign.billing_model = 'HOUSE'
           OR (
               NOT EXISTS (
                   SELECT 1
                     FROM ads.account_financial_holds hold
                    WHERE hold.account_id = campaign.account_id
                      AND hold.status = 'OPEN'
               )
               AND EXISTS (
                   SELECT 1
                     FROM ads.account_balances balance
                    WHERE balance.account_id = campaign.account_id
                      AND balance.currency = campaign.currency
                      AND balance.available_balance >= campaign.cpc_bid
               )
               AND EXISTS (
                   SELECT 1
                     FROM ads.campaign_budget_state budget
                    WHERE budget.campaign_id = campaign.campaign_id
                      AND budget.account_id = campaign.account_id
                      AND budget.currency = campaign.currency
                      AND budget.spent_total + campaign.cpc_bid
                          <= campaign.budget_total
                      AND (
                          campaign.budget_daily IS NULL
                          OR budget.spent_date <
                             ads.business_date(normalized.requested_at)
                          OR budget.spent_today + campaign.cpc_bid
                             <= campaign.budget_daily
                      )
               )
           )
       )
),
frequency_eligible AS (
    SELECT candidate.*
      FROM eligible_campaigns candidate
     WHERE candidate.frequency_cap_count IS NULL
        OR (
            (NULL::integer IS NOT NULL OR candidate.anonymous_id_hash IS NOT NULL)
            AND (
                SELECT count(*)
                  FROM ads.deliveries prior_delivery
                  JOIN ads.delivery_payloads prior_payload
                    ON prior_payload.delivery_id = prior_delivery.delivery_id
                 WHERE prior_delivery.campaign_id = candidate.campaign_id
                   AND prior_delivery.served_at >= candidate.requested_at
                       - make_interval(
                           mins => candidate.frequency_cap_window_minutes
                       )
                   AND prior_delivery.served_at <= candidate.requested_at
                   AND (
                       (
                           NULL::integer IS NOT NULL
                           AND prior_payload.user_id = NULL::integer
                       )
                       OR (
                           NULL::integer IS NULL
                           AND prior_payload.anonymous_id_hash =
                               candidate.anonymous_id_hash
                       )
                   )
            ) < candidate.frequency_cap_count
        )
),
campaign_creatives AS (
    SELECT candidate.*,
           selected.advertisement_id,
           selected.creative_id,
           selected.ad_type,
           selected.core_event_id,
           selected.event_region_code,
           selected.destination_url,
           selected.creative_type,
           selected.title,
           selected.body,
           selected.image_url,
           selected.alt_text,
           selected.width,
           selected.height,
           selected.creative_payload
      FROM frequency_eligible candidate
      CROSS JOIN LATERAL (
          SELECT advertisement.advertisement_id,
                 creative.creative_id,
                 advertisement.ad_type,
                 advertisement.core_event_id,
                 upper(nullif(trim(core_event.estado), ''))
                     AS event_region_code,
                 advertisement.destination_url,
                 creative.creative_type,
                 creative.title,
                 creative.body,
                 creative.image_url,
                 creative.alt_text,
                 creative.width,
                 creative.height,
                 creative.payload AS creative_payload
            FROM ads.advertisements advertisement
            JOIN ads.creatives creative
              ON creative.advertisement_id = advertisement.advertisement_id
             AND creative.campaign_id = advertisement.campaign_id
             AND creative.account_id = advertisement.account_id
             AND creative.billing_model = advertisement.billing_model
             AND creative.ad_type = advertisement.ad_type
             AND creative.status = 'ACTIVE'
            LEFT JOIN public.tb_evento_corridas core_event
              ON core_event.id_evento = advertisement.core_event_id
           WHERE advertisement.campaign_id = candidate.campaign_id
             AND advertisement.account_id = candidate.account_id
             AND advertisement.billing_model = candidate.billing_model
             AND advertisement.ad_type = ANY(candidate.allowed_ad_types)
             AND advertisement.status = 'ACTIVE'
             AND (
                 (
                     advertisement.ad_type = 'EVENT'
                     AND candidate.format_key = 'NATIVE_EVENT'
                     AND core_event.id_evento IS NOT NULL
                     AND core_event.ativo
                 )
                 OR (
                     advertisement.ad_type = 'BANNER'
                     AND candidate.format_key = 'IMAGE'
                     AND advertisement.billing_model = 'HOUSE'
                     AND ads.banner_scope_matches(candidate.banner_scope_metadata, candidate.region_code, p_banner_page)
                 )
             )
           ORDER BY advertisement.created_at,
                    advertisement.advertisement_id,
                    creative.created_at,
                    creative.creative_id
           LIMIT 1
      ) selected
),
scored_candidates AS MATERIALIZED (
    SELECT candidate.*,
           CASE
               WHEN candidate.billing_model = 'CPC'
                AND candidate.ad_type = 'EVENT'
                   THEN ads.event_auction_relevance_factor(
                       candidate.target_region_code,
                       candidate.event_region_code,
                       candidate.region_code
                   )
               ELSE 1::numeric
           END AS relevance_factor,
           CASE
               WHEN candidate.billing_model = 'CPC'
                AND candidate.ad_type = 'EVENT'
                   THEN candidate.cpc_bid
                        * ads.event_auction_relevance_factor(
                            candidate.target_region_code,
                            candidate.event_region_code,
                            candidate.region_code
                        )
               ELSE 0::numeric
           END AS auction_score,
           ads.event_auction_tie_break(
               candidate.campaign_id::text
               || ':' || candidate.placement_id::text
               || ':' || candidate.requested_at::text,
               candidate.weight
           ) AS tie_breaker
      FROM campaign_creatives candidate
),
ranked_candidates AS (
    SELECT candidate.*,
           lead(candidate.auction_score) OVER (
               ORDER BY
                   CASE
                       WHEN candidate.billing_model = 'CPC'
                        AND candidate.ad_type = 'EVENT'
                           THEN 1
                       ELSE 0
                   END DESC,
                   candidate.auction_score DESC,
                   candidate.priority DESC,
                   candidate.tie_breaker,
                   candidate.campaign_id
           ) AS next_auction_score
      FROM scored_candidates candidate
)
SELECT candidate.campaign_id,
       candidate.account_id,
       candidate.advertisement_id,
       candidate.creative_id,
       candidate.placement_id,
       candidate.placement_key,
       candidate.ad_type,
       candidate.core_event_id,
       candidate.destination_url,
       candidate.billing_model,
       CASE
           WHEN candidate.billing_model = 'CPC'
            AND candidate.ad_type = 'EVENT'
               THEN ads.event_auction_price(
                   candidate.cpc_bid,
                   candidate.relevance_factor,
                   candidate.next_auction_score
               )
           ELSE 0::numeric
       END AS price_candidate,
       candidate.currency,
       candidate.creative_type,
       candidate.title,
       candidate.body,
       candidate.image_url,
       candidate.alt_text,
       candidate.width,
       candidate.height,
       candidate.creative_payload,
       candidate.priority,
       candidate.weight
  FROM ranked_candidates candidate
 ORDER BY
       CASE
           WHEN candidate.billing_model = 'CPC'
            AND candidate.ad_type = 'EVENT'
               THEN 1
           ELSE 0
       END DESC,
       candidate.auction_score DESC,
       candidate.priority DESC,
       candidate.tie_breaker,
       candidate.campaign_id
 LIMIT 1;
$function$
