CREATE OR REPLACE FUNCTION ads.record_cpc_viewable(p_event_id uuid, p_delivery_id uuid, p_token text, p_occurred_at timestamp with time zone, p_view_ms integer, p_view_ratio numeric, p_device_class text DEFAULT NULL::text, p_referer_host text DEFAULT NULL::text, p_metadata jsonb DEFAULT '{}'::jsonb)
 RETURNS TABLE(event_id uuid, delivery_id uuid, event_valid boolean, result_status text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
#variable_conflict use_column
DECLARE
    normalized_token text := nullif(trim(p_token), '');
    selected_delivery ads.deliveries%ROWTYPE;
    recorded_event record;
BEGIN
    IF p_event_id IS NULL OR p_delivery_id IS NULL THEN
        RAISE EXCEPTION 'Evento e entrega CPC sao obrigatorios';
    END IF;

    IF normalized_token IS NULL
       OR length(normalized_token) < 32
       OR length(normalized_token) > 256 THEN
        RAISE EXCEPTION 'Token CPC invalido';
    END IF;

    IF p_view_ms IS NULL OR p_view_ms < 1000
       OR p_view_ratio IS NULL OR p_view_ratio < 0.5
       OR p_view_ratio > 1 THEN
        RAISE EXCEPTION 'Viewable CPC invalido';
    END IF;

    -- deliveries e imutavel por trigger. O lock antecipado da linha inverteria
    -- a ordem global da funcao canonica: advisory do event_id -> delivery.
    SELECT stored.*
      INTO selected_delivery
      FROM ads.deliveries stored
     WHERE stored.delivery_id = p_delivery_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Entrega CPC nao encontrada';
    END IF;

    IF selected_delivery.billing_model <> 'CPC'
       OR selected_delivery.ad_type NOT IN ('EVENT','BANNER')
       OR selected_delivery.price_snapshot <= 0 THEN
        RAISE EXCEPTION 'Entrega nao pertence ao produto EVENT/CPC';
    END IF;

    IF p_occurred_at IS NULL
       OR selected_delivery.expires_at < clock_timestamp()
       OR p_occurred_at > selected_delivery.expires_at THEN
        RAISE EXCEPTION 'Entrega CPC expirada';
    END IF;

    IF p_occurred_at < selected_delivery.served_at - interval '5 minutes'
       OR p_occurred_at > clock_timestamp() + interval '5 minutes' THEN
        RAISE EXCEPTION 'Horario do evento CPC invalido';
    END IF;

    IF selected_delivery.token_hash <>
       encode(sha256(convert_to(normalized_token, 'UTF8')), 'hex') THEN
        RAISE EXCEPTION 'Token CPC invalido';
    END IF;

    SELECT recorded.*
      INTO recorded_event
      FROM ads.record_event(
          p_event_id,
          p_delivery_id,
          'VIEWABLE_IMPRESSION',
          p_occurred_at,
          NULL,
          p_view_ms,
          p_view_ratio,
          NULL,
          NULL,
          p_device_class,
          p_referer_host,
          coalesce(p_metadata, '{}'::jsonb),
          clock_timestamp() + interval '30 days'
      ) recorded;

    RETURN QUERY
    SELECT recorded_event.event_id,
           recorded_event.delivery_id,
           recorded_event.valid,
           recorded_event.result_status;
END;
$function$
