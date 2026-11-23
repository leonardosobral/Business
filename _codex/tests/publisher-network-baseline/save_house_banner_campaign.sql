CREATE OR REPLACE FUNCTION ads.save_house_banner_campaign(p_campaign_id uuid, p_account_id bigint, p_placement_key text, p_name text, p_desktop_image_url text, p_desktop_width integer, p_desktop_height integer, p_mobile_image_url text, p_mobile_width integer, p_mobile_height integer, p_alt_text text, p_destination_url text, p_open_in_new_tab boolean, p_starts_at timestamp with time zone, p_ends_at timestamp with time zone, p_weight integer DEFAULT 1, p_priority integer DEFAULT 1, p_changed_by integer DEFAULT NULL::integer, p_legacy_banner_id bigint DEFAULT NULL::bigint)
 RETURNS TABLE(campaign_id uuid, advertisement_id uuid, creative_id uuid, placement_id uuid, campaign_status text, result_status text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
#variable_conflict use_column
DECLARE
    target ads.campaigns%ROWTYPE;
    target_advertisement ads.advertisements%ROWTYPE;
    target_creative ads.creatives%ROWTYPE;
    selected_placement ads.placements%ROWTYPE;
    mapped_campaign_id uuid;
    effective_campaign_id uuid := p_campaign_id;
    v_campaign_id uuid;
    v_advertisement_id uuid;
    v_creative_id uuid;
    v_result_status text;
    v_advertisement_count integer;
    v_creative_count integer;
    normalized_name text := nullif(trim(p_name), '');
    normalized_desktop_url text := nullif(trim(p_desktop_image_url), '');
    normalized_mobile_url text := nullif(trim(p_mobile_image_url), '');
    normalized_alt text := nullif(trim(p_alt_text), '');
    normalized_destination text := nullif(trim(p_destination_url), '');
    creative_payload jsonb;
    map_metadata jsonb;
BEGIN
    -- banner_scope_v1: institutional owner and canonical global admin actor.
    IF p_account_id IS DISTINCT FROM 1::bigint OR NOT EXISTS (
        SELECT 1 FROM public.tb_usuarios actor WHERE actor.id=p_changed_by
          AND (coalesce(actor.is_admin,false) OR coalesce(actor.is_dev,false))
    ) THEN RAISE EXCEPTION 'Somente administrador RunnerHub salva HOUSE da conta institucional'; END IF;

    IF p_legacy_banner_id IS NOT NULL AND p_legacy_banner_id <= 0 THEN
        RAISE EXCEPTION 'ID legado de banner deve ser positivo';
    END IF;

    IF p_legacy_banner_id IS NOT NULL THEN
        SELECT legacy.canonical_id
          INTO mapped_campaign_id
          FROM ads.legacy_id_map legacy
         WHERE legacy.legacy_schema = 'ads'
           AND legacy.legacy_table = 'tb_portal_banners'
           AND legacy.legacy_id = p_legacy_banner_id::text
           AND legacy.canonical_entity_type = 'CAMPAIGN';

        IF effective_campaign_id IS NULL THEN
            effective_campaign_id := mapped_campaign_id;
        ELSIF mapped_campaign_id IS NOT NULL
              AND mapped_campaign_id <> effective_campaign_id THEN
            RAISE EXCEPTION 'ID legado ja aponta para outra campanha';
        END IF;
    END IF;

    IF p_account_id IS NULL OR NOT EXISTS (
        SELECT 1
          FROM public.tb_contas account
         WHERE account.id_conta = p_account_id
           AND account.status::text = 'ATIVA'
    ) THEN
        RAISE EXCEPTION 'Conta da campanha nao encontrada ou nao ativa';
    END IF;

    IF normalized_name IS NULL THEN
        RAISE EXCEPTION 'Nome do banner e obrigatorio';
    END IF;

    IF normalized_desktop_url IS NULL
       OR normalized_desktop_url !~ '^https://[^[:space:]]+$'
       OR normalized_mobile_url IS NULL
       OR normalized_mobile_url !~ '^https://[^[:space:]]+$' THEN
        RAISE EXCEPTION 'Imagens desktop e mobile HTTPS sao obrigatorias';
    END IF;

    IF p_desktop_width IS NULL OR p_desktop_width <= 0
       OR p_desktop_height IS NULL OR p_desktop_height <= 0
       OR p_mobile_width IS NULL OR p_mobile_width <= 0
       OR p_mobile_height IS NULL OR p_mobile_height <= 0 THEN
        RAISE EXCEPTION 'Dimensoes desktop e mobile positivas sao obrigatorias';
    END IF;

    IF normalized_alt IS NULL THEN
        RAISE EXCEPTION 'Texto alternativo do banner e obrigatorio';
    END IF;

    IF normalized_destination IS NULL
       OR normalized_destination !~ '^https://[^[:space:]]+$' THEN
        RAISE EXCEPTION 'Destino HTTPS valido e obrigatorio';
    END IF;

    IF p_starts_at IS NULL OR p_ends_at IS NULL
       OR p_ends_at <= p_starts_at THEN
        RAISE EXCEPTION 'Janela do banner e obrigatoria e deve ser valida';
    END IF;

    IF p_weight IS NULL OR p_weight <= 0
       OR p_priority IS NULL OR p_priority <= 0 THEN
        RAISE EXCEPTION 'Peso e prioridade devem ser positivos';
    END IF;

    SELECT placement.*
      INTO selected_placement
      FROM ads.placements placement
     WHERE placement.placement_key = nullif(trim(p_placement_key), '')
       AND placement.placement_key = 'rr-sidebar-banner-300x250'
       AND placement.status = 'ACTIVE'
       AND placement.format_key = 'IMAGE'
     FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Placement ativo de imagem nao encontrado';
    END IF;

    creative_payload := jsonb_build_object(
        'managed_by', 'ads_business',
        'product', 'HOUSE',
        'responsive', true,
        'desktop_image_url', normalized_desktop_url,
        'desktop_width', p_desktop_width,
        'desktop_height', p_desktop_height,
        'mobile_image_url', normalized_mobile_url,
        'mobile_width', p_mobile_width,
        'mobile_height', p_mobile_height,
        'open_in_new_tab', coalesce(p_open_in_new_tab, false)
    );

    IF p_legacy_banner_id IS NOT NULL THEN
        creative_payload := creative_payload || jsonb_build_object(
            'legacy_banner_id', p_legacy_banner_id
        );
    END IF;

    IF effective_campaign_id IS NULL THEN
        v_campaign_id := gen_random_uuid();
        v_advertisement_id := gen_random_uuid();
        v_creative_id := gen_random_uuid();
        v_result_status := 'created';

        INSERT INTO ads.campaigns (
            campaign_id,
            account_id,
            name,
            billing_model,
            status,
            currency,
            target_device_class,
            target_country_code,
            starts_at,
            ends_at,
            created_by,
            updated_by,
            metadata
        )
        VALUES (
            v_campaign_id,
            p_account_id,
            normalized_name,
            'HOUSE',
            'DRAFT',
            'BRL',
            'ALL',
            'BR',
            p_starts_at,
            p_ends_at,
            p_changed_by,
            p_changed_by,
            jsonb_strip_nulls(jsonb_build_object(
                'managed_by', 'ads_business',
                'product', 'HOUSE',
                'ad_type', 'BANNER',
                'legacy_banner_id', p_legacy_banner_id
            ))
        );

        INSERT INTO ads.advertisements (
            advertisement_id,
            campaign_id,
            account_id,
            billing_model,
            ad_type,
            name,
            status,
            core_event_id,
            destination_url,
            created_by,
            updated_by,
            metadata
        )
        VALUES (
            v_advertisement_id,
            v_campaign_id,
            p_account_id,
            'HOUSE',
            'BANNER',
            normalized_name,
            'ACTIVE',
            NULL,
            normalized_destination,
            p_changed_by,
            p_changed_by,
            jsonb_strip_nulls(jsonb_build_object(
                'managed_by', 'ads_business',
                'product', 'HOUSE',
                'legacy_banner_id', p_legacy_banner_id
            ))
        );

        INSERT INTO ads.creatives (
            creative_id,
            advertisement_id,
            campaign_id,
            account_id,
            billing_model,
            ad_type,
            creative_type,
            status,
            title,
            image_url,
            alt_text,
            width,
            height,
            payload,
            created_by,
            updated_by
        )
        VALUES (
            v_creative_id,
            v_advertisement_id,
            v_campaign_id,
            p_account_id,
            'HOUSE',
            'BANNER',
            'IMAGE',
            'ACTIVE',
            normalized_name,
            normalized_desktop_url,
            normalized_alt,
            p_desktop_width,
            p_desktop_height,
            creative_payload,
            p_changed_by,
            p_changed_by
        );

        INSERT INTO ads.campaign_placements (
            campaign_id,
            account_id,
            billing_model,
            placement_id,
            status,
            priority,
            weight,
            metadata
        )
        VALUES (
            v_campaign_id,
            p_account_id,
            'HOUSE',
            selected_placement.placement_id,
            'ACTIVE',
            p_priority,
            p_weight,
            jsonb_strip_nulls(jsonb_build_object(
                'managed_by', 'ads_business',
                'product', 'HOUSE',
                'legacy_banner_id', p_legacy_banner_id
            ))
        );
    ELSE
        SELECT stored.*
          INTO target
          FROM ads.campaigns stored
         WHERE stored.campaign_id = effective_campaign_id
         FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Campanha de banner nao encontrada';
        END IF;

        IF target.account_id <> p_account_id
           OR target.billing_model <> 'HOUSE' THEN
            RAISE EXCEPTION 'Conta ou produto da campanha nao corresponde';
        END IF;

        IF target.status NOT IN ('DRAFT', 'PAUSED') THEN
            RAISE EXCEPTION 'Pause o banner antes de editar';
        END IF;

        SELECT count(*)
          INTO v_advertisement_count
          FROM ads.advertisements advertisement
         WHERE advertisement.campaign_id = target.campaign_id
           AND advertisement.account_id = target.account_id
           AND advertisement.billing_model = 'HOUSE'
           AND advertisement.ad_type = 'BANNER'
           AND advertisement.status <> 'ARCHIVED';

        IF v_advertisement_count <> 1 THEN
            RAISE EXCEPTION 'Campanha deve possuir exatamente um anuncio BANNER';
        END IF;

        SELECT advertisement.*
          INTO target_advertisement
          FROM ads.advertisements advertisement
         WHERE advertisement.campaign_id = target.campaign_id
           AND advertisement.account_id = target.account_id
           AND advertisement.billing_model = 'HOUSE'
           AND advertisement.ad_type = 'BANNER'
           AND advertisement.status <> 'ARCHIVED'
         FOR UPDATE;

        SELECT count(*)
          INTO v_creative_count
          FROM ads.creatives creative
         WHERE creative.advertisement_id =
               target_advertisement.advertisement_id
           AND creative.status <> 'ARCHIVED';

        IF v_creative_count <> 1 THEN
            RAISE EXCEPTION 'Banner deve possuir exatamente um criativo ativo';
        END IF;

        SELECT creative.*
          INTO target_creative
          FROM ads.creatives creative
         WHERE creative.advertisement_id =
               target_advertisement.advertisement_id
           AND creative.status <> 'ARCHIVED'
         FOR UPDATE;

        v_campaign_id := target.campaign_id;
        v_advertisement_id := target_advertisement.advertisement_id;
        v_creative_id := target_creative.creative_id;
        v_result_status := 'updated';

        UPDATE ads.campaigns campaign
           SET name = normalized_name,
               starts_at = p_starts_at,
               ends_at = p_ends_at,
               updated_by = p_changed_by,
               updated_at = clock_timestamp(),
               version = campaign.version + 1,
               metadata = campaign.metadata || jsonb_strip_nulls(
                   jsonb_build_object(
                       'managed_by', 'ads_business',
                       'legacy_banner_id', p_legacy_banner_id
                   )
               )
         WHERE campaign.campaign_id = v_campaign_id;

        UPDATE ads.advertisements advertisement
           SET name = normalized_name,
               status = 'ACTIVE',
               destination_url = normalized_destination,
               updated_by = p_changed_by,
               updated_at = clock_timestamp()
         WHERE advertisement.advertisement_id = v_advertisement_id;

        UPDATE ads.creatives creative
           SET status = 'ACTIVE',
               title = normalized_name,
               image_url = normalized_desktop_url,
               alt_text = normalized_alt,
               width = p_desktop_width,
               height = p_desktop_height,
               payload = creative_payload,
               updated_by = p_changed_by,
               updated_at = clock_timestamp()
         WHERE creative.creative_id = v_creative_id;

        UPDATE ads.campaign_placements link
           SET status = 'INACTIVE',
               updated_at = clock_timestamp()
         WHERE link.campaign_id = v_campaign_id
           AND link.placement_id <> selected_placement.placement_id;

        INSERT INTO ads.campaign_placements (
            campaign_id,
            account_id,
            billing_model,
            placement_id,
            status,
            priority,
            weight,
            updated_at,
            metadata
        )
        VALUES (
            v_campaign_id,
            p_account_id,
            'HOUSE',
            selected_placement.placement_id,
            'ACTIVE',
            p_priority,
            p_weight,
            clock_timestamp(),
            jsonb_strip_nulls(jsonb_build_object(
                'managed_by', 'ads_business',
                'product', 'HOUSE',
                'legacy_banner_id', p_legacy_banner_id
            ))
        )
        ON CONFLICT (campaign_id, placement_id)
        DO UPDATE SET status = 'ACTIVE',
                      priority = EXCLUDED.priority,
                      weight = EXCLUDED.weight,
                      updated_at = EXCLUDED.updated_at,
                      metadata = campaign_placements.metadata
                                 || EXCLUDED.metadata;
    END IF;

    IF p_legacy_banner_id IS NOT NULL THEN
        IF EXISTS (
            SELECT 1
              FROM ads.legacy_id_map legacy
             WHERE legacy.legacy_schema = 'ads'
               AND legacy.legacy_table = 'tb_portal_banners'
               AND legacy.legacy_id = p_legacy_banner_id::text
               AND (
                   (legacy.canonical_entity_type = 'CAMPAIGN'
                    AND legacy.canonical_id <> v_campaign_id)
                   OR
                   (legacy.canonical_entity_type = 'ADVERTISEMENT'
                    AND legacy.canonical_id <> v_advertisement_id)
                   OR
                   (legacy.canonical_entity_type = 'CREATIVE'
                    AND legacy.canonical_id <> v_creative_id)
               )
        ) THEN
            RAISE EXCEPTION 'Mapa legado aponta para outra entidade canonica';
        END IF;

        map_metadata := jsonb_build_object(
            'managed_by', 'ads_business',
            'migration', '2026-08-20_ads_v1_house_banner',
            'owner_account_id', p_account_id
        );

        INSERT INTO ads.legacy_id_map (
            legacy_schema,
            legacy_table,
            legacy_id,
            canonical_entity_type,
            canonical_id,
            metadata
        )
        VALUES
            (
                'ads', 'tb_portal_banners', p_legacy_banner_id::text,
                'CAMPAIGN', v_campaign_id, map_metadata
            ),
            (
                'ads', 'tb_portal_banners', p_legacy_banner_id::text,
                'ADVERTISEMENT', v_advertisement_id, map_metadata
            ),
            (
                'ads', 'tb_portal_banners', p_legacy_banner_id::text,
                'CREATIVE', v_creative_id, map_metadata
            )
        ON CONFLICT (
            legacy_schema,
            legacy_table,
            legacy_id,
            canonical_entity_type
        )
        DO UPDATE SET metadata = legacy_id_map.metadata || EXCLUDED.metadata;
    END IF;

    RETURN QUERY
    SELECT v_campaign_id,
           v_advertisement_id,
           v_creative_id,
           selected_placement.placement_id,
           stored.status,
           v_result_status
      FROM ads.campaigns stored
     WHERE stored.campaign_id = v_campaign_id;
END;
$function$
