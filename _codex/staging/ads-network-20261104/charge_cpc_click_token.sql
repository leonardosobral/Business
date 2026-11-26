CREATE OR REPLACE FUNCTION ads.charge_cpc_click_token(p_event_id uuid, p_delivery_id uuid, p_token text, p_occurred_at timestamp with time zone, p_user_id integer DEFAULT NULL::integer, p_ip_hash text DEFAULT NULL::text, p_device_class text DEFAULT NULL::text, p_referer_host text DEFAULT NULL::text, p_metadata jsonb DEFAULT '{}'::jsonb)
 RETURNS TABLE(event_id uuid, delivery_id uuid, billable boolean, ledger_entry_id uuid, balance_after numeric, rejection_reason text, result_status text, destination_url text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
#variable_conflict use_column
DECLARE
    normalized_token text := nullif(trim(p_token), '');
    selected_delivery ads.deliveries%ROWTYPE;
    charged_click record;
BEGIN
    IF p_event_id IS NULL OR p_delivery_id IS NULL THEN
        RAISE EXCEPTION 'Evento e entrega CPC sao obrigatorios';
    END IF;

    IF normalized_token IS NULL
       OR length(normalized_token) < 32
       OR length(normalized_token) > 256 THEN
        RAISE EXCEPTION 'Token CPC invalido';
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

    SELECT charged.*
      INTO charged_click
      FROM ads.charge_cpc_click(
          p_event_id,
          p_delivery_id,
          p_occurred_at,
          p_user_id,
          p_ip_hash,
          p_device_class,
          p_referer_host,
          coalesce(p_metadata, '{}'::jsonb),
          clock_timestamp() + interval '30 days'
      ) charged;

    RETURN QUERY
    SELECT charged_click.event_id,
           charged_click.delivery_id,
           charged_click.billable,
           charged_click.ledger_entry_id,
           charged_click.balance_after,
           charged_click.rejection_reason,
           charged_click.result_status,
           selected_delivery.destination_url;
END;
$function$
