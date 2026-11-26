CREATE OR REPLACE FUNCTION ads.serve_delivery(p_served_event_id uuid, p_campaign_id uuid, p_advertisement_id uuid, p_creative_id uuid, p_placement_id uuid, p_token_hash text, p_expires_at timestamp with time zone, p_served_at timestamp with time zone DEFAULT clock_timestamp(), p_token_version smallint DEFAULT 1, p_user_id integer DEFAULT NULL::integer, p_anonymous_id_hash text DEFAULT NULL::text, p_ip_hash text DEFAULT NULL::text, p_device_class text DEFAULT NULL::text, p_country_code character DEFAULT NULL::bpchar, p_region_code text DEFAULT NULL::text, p_route_key text DEFAULT NULL::text, p_request_context jsonb DEFAULT '{}'::jsonb, p_retention_until timestamp with time zone DEFAULT NULL::timestamp with time zone)
 RETURNS TABLE(delivery_id uuid, destination_url text, billing_model text, price_snapshot numeric, currency character, result_status text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
    paid_banner_candidate record;
    paid_banner_price numeric;
    existing_event ads.events%ROWTYPE;
    selected_delivery ads.deliveries%ROWTYPE;
    new_delivery_id uuid;
    campaign ads.campaigns%ROWTYPE;
    advertisement ads.advertisements%ROWTYPE;
    creative ads.creatives%ROWTYPE;
    selected_placement ads.placements%ROWTYPE;
    eligible_entities record;
    account_is_active boolean;
    budget_available boolean;
    balance_available boolean;
    effective_retention timestamp with time zone;
    frequency_identity text;
    frequency_window_start timestamp with time zone;
    recent_delivery_count integer;
BEGIN
    PERFORM pg_advisory_xact_lock(
        hashtextextended(p_served_event_id::text, 91001)
    );

    SELECT event.*
      INTO existing_event
      FROM ads.events event
     WHERE event.event_id = p_served_event_id;

    IF FOUND THEN
        IF existing_event.event_type <> 'SERVED' THEN
            RAISE EXCEPTION
                'event_id ja utilizado por outro tipo de evento';
        END IF;

        RETURN QUERY
        SELECT delivery.delivery_id,
               delivery.destination_url,
               delivery.billing_model,
               delivery.price_snapshot,
               delivery.currency,
               'already_recorded'::text
          FROM ads.deliveries delivery
         WHERE delivery.delivery_id = existing_event.delivery_id;
        RETURN;
    END IF;

    SELECT current_campaign,
           current_advertisement,
           current_creative,
           current_placement
      INTO eligible_entities
      FROM ads.campaigns current_campaign
      JOIN ads.advertisements current_advertisement
        ON current_advertisement.advertisement_id = p_advertisement_id
       AND current_advertisement.campaign_id = current_campaign.campaign_id
       AND current_advertisement.account_id = current_campaign.account_id
       AND current_advertisement.billing_model = current_campaign.billing_model
      JOIN ads.creatives current_creative
        ON current_creative.creative_id = p_creative_id
       AND current_creative.advertisement_id =
           current_advertisement.advertisement_id
       AND current_creative.campaign_id = current_campaign.campaign_id
       AND current_creative.account_id = current_campaign.account_id
       AND current_creative.billing_model = current_campaign.billing_model
       AND current_creative.ad_type = current_advertisement.ad_type
      JOIN ads.campaign_placements campaign_placement
        ON campaign_placement.campaign_id = current_campaign.campaign_id
       AND campaign_placement.account_id = current_campaign.account_id
       AND campaign_placement.billing_model = current_campaign.billing_model
       AND campaign_placement.placement_id = p_placement_id
       AND campaign_placement.status = 'ACTIVE'
      JOIN ads.placements current_placement
        ON current_placement.placement_id = campaign_placement.placement_id
       AND current_placement.status = 'ACTIVE'
      LEFT JOIN public.tb_evento_corridas core_event
        ON core_event.id_evento = current_advertisement.core_event_id
     WHERE current_campaign.campaign_id = p_campaign_id
       AND current_campaign.status = 'ACTIVE'
       AND current_advertisement.status = 'ACTIVE'
       AND current_creative.status = 'ACTIVE'
       AND (
           current_advertisement.ad_type <> 'EVENT'
           OR core_event.ativo
       )
       AND current_campaign.starts_at <= p_served_at
       AND current_campaign.ends_at >= p_served_at
       AND (
           current_placement.device_class = 'ALL'
           OR current_placement.device_class = p_device_class
       )
       AND (
           current_campaign.target_device_class = 'ALL'
           OR current_campaign.target_device_class = p_device_class
       )
       AND (
           current_campaign.target_country_code IS NULL
           OR current_campaign.target_country_code = p_country_code
       )
       AND (
           current_campaign.target_region_code IS NULL
           OR current_campaign.target_region_code = p_region_code
       )
     FOR SHARE OF
         current_campaign,
         current_advertisement,
         current_creative,
         campaign_placement,
         current_placement;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Campanha/anuncio/criativo/placement nao elegivel para entrega';
    END IF;

    -- Cada item selecionado acima e um registro composto. PostgreSQL nao
    -- distribui com seguranca quatro composites diretamente entre quatro
    -- variaveis %ROWTYPE; materializamos primeiro em record e depois atribuímos
    -- cada campo ao tipo de tabela correspondente.
    campaign := eligible_entities.current_campaign;
    advertisement := eligible_entities.current_advertisement;
    creative := eligible_entities.current_creative;
    selected_placement := eligible_entities.current_placement;
    IF campaign.billing_model='CPC' AND advertisement.ad_type='BANNER' THEN
        SELECT * INTO paid_banner_candidate FROM ads.select_paid_banner_candidate(selected_placement.placement_key,p_served_at,p_device_class,p_country_code,p_region_code,p_request_context->>'banner_page');
        IF NOT FOUND OR paid_banner_candidate.campaign_id<>campaign.campaign_id OR paid_banner_candidate.advertisement_id<>advertisement.advertisement_id OR paid_banner_candidate.creative_id<>creative.creative_id THEN
            RAISE EXCEPTION 'Banner pago nao elegivel no escopo/leilao ou revisao atual';
        END IF;
        paid_banner_price:=paid_banner_candidate.price_candidate;
        p_request_context:=coalesce(p_request_context,'{}'::jsonb)||jsonb_build_object('paid_banner_auction',jsonb_build_object('price',paid_banner_price,'max_bid',campaign.cpc_bid,'region',p_region_code,'page',p_request_context->>'banner_page','version',1));
    END IF;
    -- banner_scope_v1: revalidate the locked campaign immediately before delivery.
    IF campaign.billing_model='HOUSE' AND advertisement.ad_type='BANNER'
       AND NOT ads.banner_scope_matches(campaign.metadata,p_region_code,p_request_context->>'banner_page') THEN
        RAISE EXCEPTION 'Banner fora do escopo de pagina ou UF';
    END IF;


    SELECT (account.status::text = 'ATIVA')
      INTO account_is_active
      FROM public.tb_contas account
     WHERE account.id_conta = campaign.account_id;

    IF NOT coalesce(account_is_active, false) THEN
        RAISE EXCEPTION 'Conta da campanha nao esta ativa';
    END IF;

    IF campaign.frequency_cap_count IS NOT NULL THEN
        frequency_identity := CASE
            WHEN p_user_id IS NOT NULL THEN 'user:' || p_user_id::text
            WHEN nullif(trim(p_anonymous_id_hash), '') IS NOT NULL
                THEN 'anonymous:' || trim(p_anonymous_id_hash)
            ELSE NULL
        END;

        IF frequency_identity IS NULL THEN
            RAISE EXCEPTION
                'Campanha com frequency cap exige user_id ou anonymous_id_hash';
        END IF;

        -- Serializa entregas da mesma campanha/audiencia para que duas
        -- requisicoes concorrentes nao ultrapassem o limite.
        PERFORM pg_advisory_xact_lock(
            hashtextextended(
                campaign.campaign_id::text || ':' || frequency_identity,
                91004
            )
        );

        frequency_window_start := p_served_at - make_interval(
            mins => campaign.frequency_cap_window_minutes
        );

        SELECT count(*)::integer
          INTO recent_delivery_count
          FROM ads.deliveries previous_delivery
          JOIN ads.delivery_payloads previous_payload
            ON previous_payload.delivery_id = previous_delivery.delivery_id
         WHERE previous_delivery.campaign_id = campaign.campaign_id
           AND previous_delivery.served_at >= frequency_window_start
           AND previous_delivery.served_at <= p_served_at
           AND (
               (
                   p_user_id IS NOT NULL
                   AND previous_payload.user_id = p_user_id
               )
               OR
               (
                   p_user_id IS NULL
                   AND previous_payload.anonymous_id_hash =
                       trim(p_anonymous_id_hash)
               )
           );

        IF recent_delivery_count >= campaign.frequency_cap_count THEN
            RAISE EXCEPTION 'Frequency cap da campanha atingido';
        END IF;
    END IF;

    IF campaign.billing_model = 'CPC' THEN
        SELECT EXISTS (
            SELECT 1
              FROM ads.account_balances balance
             WHERE balance.account_id = campaign.account_id
               AND balance.currency = campaign.currency
               AND balance.available_balance >= campaign.cpc_bid
        )
          INTO balance_available;

        SELECT EXISTS (
            SELECT 1
              FROM ads.campaign_budget_state state
             WHERE state.campaign_id = campaign.campaign_id
               AND state.account_id = campaign.account_id
               AND state.currency = campaign.currency
               AND state.spent_total + campaign.cpc_bid
                   <= campaign.budget_total
               AND (
                   campaign.budget_daily IS NULL
                   OR state.spent_date < ads.business_date(p_served_at)
                   OR state.spent_today + campaign.cpc_bid
                      <= campaign.budget_daily
               )
        )
          INTO budget_available;

        IF NOT balance_available OR NOT budget_available THEN
            RAISE EXCEPTION 'Saldo ou orcamento indisponivel para entrega CPC';
        END IF;
    END IF;

    IF p_expires_at <= p_served_at THEN
        RAISE EXCEPTION 'Expiracao da entrega deve ser posterior ao served_at';
    END IF;

    IF length(trim(p_token_hash)) < 32 THEN
        RAISE EXCEPTION 'token_hash invalido';
    END IF;

    effective_retention := coalesce(
        p_retention_until,
        p_served_at + interval '30 days'
    );

    IF effective_retention <= p_served_at THEN
        RAISE EXCEPTION 'Retencao do payload deve ser futura';
    END IF;

    IF campaign.frequency_cap_window_minutes IS NOT NULL
       AND effective_retention < p_served_at + make_interval(
           mins => campaign.frequency_cap_window_minutes
       ) THEN
        RAISE EXCEPTION
            'Retencao do payload deve cobrir a janela de frequency cap';
    END IF;

    new_delivery_id := gen_random_uuid();

    INSERT INTO ads.deliveries (
        delivery_id,
        campaign_id,
        account_id,
        advertisement_id,
        creative_id,
        placement_id,
        billing_model,
        ad_type,
        currency,
        price_snapshot,
        destination_url,
        served_at,
        expires_at,
        token_version,
        token_hash
    )
    VALUES (
        new_delivery_id,
        campaign.campaign_id,
        campaign.account_id,
        advertisement.advertisement_id,
        creative.creative_id,
        p_placement_id,
        campaign.billing_model,
        advertisement.ad_type,
        campaign.currency,
        coalesce(paid_banner_price, campaign.cpc_bid, 0),
        advertisement.destination_url,
        p_served_at,
        p_expires_at,
        p_token_version,
        trim(p_token_hash)
    )
    RETURNING * INTO selected_delivery;

    INSERT INTO ads.delivery_payloads (
        delivery_id,
        user_id,
        anonymous_id_hash,
        ip_hash,
        device_class,
        country_code,
        region_code,
        route_key,
        request_context,
        retention_until
    )
    VALUES (
        selected_delivery.delivery_id,
        p_user_id,
        p_anonymous_id_hash,
        p_ip_hash,
        p_device_class,
        p_country_code,
        p_region_code,
        p_route_key,
        coalesce(p_request_context, '{}'::jsonb),
        effective_retention
    );

    INSERT INTO ads.events (
        event_id,
        delivery_id,
        account_id,
        campaign_id,
        advertisement_id,
        creative_id,
        placement_id,
        billing_model,
        ad_type,
        currency,
        price_snapshot,
        event_type,
        source,
        occurred_at,
        valid,
        billable
    )
    VALUES (
        p_served_event_id,
        selected_delivery.delivery_id,
        selected_delivery.account_id,
        selected_delivery.campaign_id,
        selected_delivery.advertisement_id,
        selected_delivery.creative_id,
        selected_delivery.placement_id,
        selected_delivery.billing_model,
        selected_delivery.ad_type,
        selected_delivery.currency,
        selected_delivery.price_snapshot,
        'SERVED',
        'SERVER',
        p_served_at,
        true,
        false
    );

    PERFORM ads.apply_metric_delta(
        selected_delivery,
        ads.business_date(p_served_at),
        p_served => 1
    );

    RETURN QUERY
    SELECT selected_delivery.delivery_id,
           selected_delivery.destination_url,
           selected_delivery.billing_model,
           selected_delivery.price_snapshot,
           selected_delivery.currency,
           'served'::text;
END;
$function$
