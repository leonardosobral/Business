/* AUDIENCE_FILTER */
, deliveries AS (
 SELECT source, medium, campaign, campaign_id, delivery_id,
        bool_or(event_kind='ad_render') AS rendered,
        bool_or(event_kind='ad_viewable') AS viewed,
        count(DISTINCT session_id) FILTER (WHERE event_kind='ad_viewable') AS view_sessions
 FROM filtered
 WHERE campaign <> '' AND campaign_id IS NOT NULL AND delivery_id IS NOT NULL
   AND event_kind IN ('ad_render','ad_viewable') AND slot_state='filled'
 GROUP BY source,medium,campaign,campaign_id,delivery_id
), clicks AS (
 SELECT DISTINCT e.delivery_id, e.campaign_id
 FROM ads.events e
 JOIN (SELECT DISTINCT delivery_id,campaign_id FROM deliveries) d USING(delivery_id,campaign_id)
 WHERE e.event_type='CLICK' AND e.valid
   AND e.received_at >= (date_trunc('day',now() AT TIME ZONE 'America/Sao_Paulo')
       - (CAST(:days AS integer)-1)*interval '1 day') AT TIME ZONE 'America/Sao_Paulo'
   AND e.received_at <= now()
), reach AS (
 SELECT source,medium,campaign,campaign_id,count(DISTINCT session_id) AS view_sessions
 FROM filtered WHERE campaign<>'' AND campaign_id IS NOT NULL AND delivery_id IS NOT NULL
   AND event_kind='ad_viewable' AND slot_state='filled'
 GROUP BY source,medium,campaign,campaign_id
)
SELECT d.source,d.medium,d.campaign,d.campaign_id::text AS advertiser_id,
       coalesce(nullif(c.name,''),d.campaign_id::text) AS advertiser_name,
       count(*) FILTER(WHERE d.rendered) AS rendered_deliveries,
       count(*) FILTER(WHERE d.viewed) AS viewed_deliveries,
       coalesce(max(r.view_sessions),0) AS view_sessions,
       count(*) FILTER(WHERE k.delivery_id IS NOT NULL) AS clicked_deliveries,
       count(*) FILTER(WHERE k.delivery_id IS NOT NULL AND d.viewed) AS viewed_clicked_deliveries
FROM deliveries d
LEFT JOIN ads.campaigns c ON c.campaign_id=d.campaign_id
LEFT JOIN clicks k ON k.delivery_id=d.delivery_id AND k.campaign_id=d.campaign_id
LEFT JOIN reach r ON r.source=d.source AND r.medium=d.medium AND r.campaign=d.campaign AND r.campaign_id=d.campaign_id
GROUP BY d.source,d.medium,d.campaign,d.campaign_id,c.name
ORDER BY view_sessions DESC,viewed_deliveries DESC,d.campaign,advertiser_name
LIMIT 101
