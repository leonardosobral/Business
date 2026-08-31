-- Preparacao de voucher e campanha enquanto conta/evento Business aguardam aprovacao.
-- A migration e aditiva: campanhas continuam DRAFT e o delivery continua lendo ACTIVE.

BEGIN;

CREATE TABLE IF NOT EXISTS ads.voucher_reservations (
    voucher_reservation_id bigserial PRIMARY KEY,
    id_ad_voucher integer NOT NULL
        REFERENCES ads.tb_ad_vouchers(id_ad_voucher)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    id_conta bigint NOT NULL
        REFERENCES public.tb_contas(id_conta)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    original_account_id bigint
        REFERENCES public.tb_contas(id_conta)
        ON UPDATE CASCADE ON DELETE SET NULL,
    id_solicitacao_cadastro bigint NOT NULL
        REFERENCES public.tb_conta_cadastro_solicitacoes(id_solicitacao)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    reserved_by integer NOT NULL
        REFERENCES public.tb_usuarios(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    status text NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT clock_timestamp(),
    updated_at timestamp with time zone NOT NULL DEFAULT clock_timestamp(),
    applied_at timestamp with time zone,
    released_at timestamp with time zone,
    expires_at timestamp with time zone,
    transition_reason text,
    CONSTRAINT ck_ads_voucher_reservations_status
        CHECK (status IN ('RESERVED', 'APPLIED', 'RELEASED', 'EXPIRED'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_ads_voucher_reservations_open_voucher
    ON ads.voucher_reservations (id_ad_voucher)
    WHERE status = 'RESERVED';

CREATE UNIQUE INDEX IF NOT EXISTS uq_ads_voucher_reservations_open_registration
    ON ads.voucher_reservations (id_solicitacao_cadastro)
    WHERE status = 'RESERVED';

CREATE INDEX IF NOT EXISTS idx_ads_voucher_reservations_account_status
    ON ads.voucher_reservations (id_conta, status, updated_at DESC);

CREATE TABLE IF NOT EXISTS ads.campaign_review_requests (
    campaign_review_request_id bigserial PRIMARY KEY,
    campaign_id uuid NOT NULL
        REFERENCES ads.campaigns(campaign_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    account_id bigint NOT NULL
        REFERENCES public.tb_contas(id_conta)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    core_event_id integer NOT NULL
        REFERENCES public.tb_evento_corridas(id_evento)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    status text NOT NULL,
    requested_by integer NOT NULL
        REFERENCES public.tb_usuarios(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    reviewed_by integer
        REFERENCES public.tb_usuarios(id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    submitted_at timestamp with time zone NOT NULL DEFAULT clock_timestamp(),
    reviewed_at timestamp with time zone,
    updated_at timestamp with time zone NOT NULL DEFAULT clock_timestamp(),
    review_reason text,
    approval_idempotency_key text,
    CONSTRAINT ck_ads_campaign_review_requests_status
        CHECK (
            status IN (
                'WAITING_PREREQUISITES',
                'PENDING_REVIEW',
                'CHANGES_REQUESTED',
                'APPROVED',
                'CANCELED'
            )
        ),
    CONSTRAINT uq_ads_campaign_review_request_identity
        UNIQUE (campaign_review_request_id, campaign_id, account_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_ads_campaign_review_requests_open
    ON ads.campaign_review_requests (campaign_id)
    WHERE status IN (
        'WAITING_PREREQUISITES',
        'PENDING_REVIEW',
        'CHANGES_REQUESTED'
    );

CREATE UNIQUE INDEX IF NOT EXISTS uq_ads_campaign_review_approval_key
    ON ads.campaign_review_requests (approval_idempotency_key)
    WHERE approval_idempotency_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_ads_campaign_review_queue
    ON ads.campaign_review_requests (status, submitted_at, campaign_review_request_id);

CREATE INDEX IF NOT EXISTS idx_ads_campaign_review_account_event
    ON ads.campaign_review_requests (account_id, core_event_id, status);

CREATE TABLE IF NOT EXISTS ads.campaign_review_history (
    campaign_review_history_id bigserial PRIMARY KEY,
    campaign_review_request_id bigint NOT NULL
        REFERENCES ads.campaign_review_requests(campaign_review_request_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    from_status text,
    to_status text NOT NULL,
    actor_id integer NOT NULL
        REFERENCES public.tb_usuarios(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    reason text,
    changed_at timestamp with time zone NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX IF NOT EXISTS idx_ads_campaign_review_history_request
    ON ads.campaign_review_history (
        campaign_review_request_id,
        campaign_review_history_id
    );

CREATE OR REPLACE FUNCTION ads.guard_reserved_voucher_redemption()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
BEGIN
    IF NEW.status = 2
       AND OLD.status <> 2
       AND EXISTS (
           SELECT 1
             FROM ads.voucher_reservations reservation
            WHERE reservation.id_ad_voucher = OLD.id_ad_voucher
              AND reservation.status = 'RESERVED'
       ) THEN
        RAISE EXCEPTION
            'Voucher reservado para conta em analise; aguarde a decisao do cadastro';
    END IF;

    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_ads_guard_reserved_voucher_redemption
    ON ads.tb_ad_vouchers;

CREATE TRIGGER trg_ads_guard_reserved_voucher_redemption
BEFORE UPDATE OF status ON ads.tb_ad_vouchers
FOR EACH ROW
EXECUTE FUNCTION ads.guard_reserved_voucher_redemption();

CREATE OR REPLACE FUNCTION ads.reserve_voucher(
    p_account_id bigint,
    p_registration_id bigint,
    p_code text,
    p_actor_id integer
)
RETURNS TABLE (
    voucher_reservation_id bigint,
    voucher_id integer,
    account_id bigint,
    registration_id bigint,
    amount numeric,
    reservation_status text,
    expires_at timestamp with time zone,
    result_status text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
#variable_conflict use_column
DECLARE
    registration public.tb_conta_cadastro_solicitacoes%ROWTYPE;
    voucher ads.tb_ad_vouchers%ROWTYPE;
    existing ads.voucher_reservations%ROWTYPE;
    stored ads.voucher_reservations%ROWTYPE;
    normalized_code text := upper(pg_catalog.btrim(p_code));
    credit_amount numeric(14, 2);
BEGIN
    IF p_account_id IS NULL OR p_account_id <= 0
       OR p_registration_id IS NULL OR p_registration_id <= 0
       OR p_actor_id IS NULL OR p_actor_id <= 0 THEN
        RAISE EXCEPTION 'Contexto invalido para reservar voucher';
    END IF;

    IF nullif(normalized_code, '') IS NULL
       OR length(normalized_code) > 160
       OR normalized_code !~ '^[A-Z0-9-]+$' THEN
        RAISE EXCEPTION 'Codigo de voucher invalido';
    END IF;

    SELECT request.*
      INTO registration
      FROM public.tb_conta_cadastro_solicitacoes request
     WHERE request.id_solicitacao = p_registration_id
     FOR UPDATE;

    IF NOT FOUND
       OR registration.id_conta IS DISTINCT FROM p_account_id
       OR registration.id_usuario IS DISTINCT FROM p_actor_id
       OR registration.status::text <> 'PENDENTE' THEN
        RAISE EXCEPTION 'Solicitacao pendente nao pertence ao usuario e conta informados';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM public.tb_contas account
          JOIN public.tb_conta_usuarios membership
            ON membership.id_conta = account.id_conta
           AND membership.id_usuario = p_actor_id
           AND membership.papel::text = 'OWNER'
           AND membership.status::text = 'ATIVO'
         WHERE account.id_conta = p_account_id
           AND account.status::text = 'PENDENTE'
    ) THEN
        RAISE EXCEPTION 'Apenas o OWNER da conta provisoria pode reservar voucher';
    END IF;

    SELECT reservation.*
      INTO existing
      FROM ads.voucher_reservations reservation
     WHERE reservation.id_solicitacao_cadastro = p_registration_id
       AND reservation.status = 'RESERVED'
     FOR UPDATE;

    IF FOUND THEN
        SELECT legacy.*
          INTO voucher
          FROM ads.tb_ad_vouchers legacy
         WHERE legacy.id_ad_voucher = existing.id_ad_voucher;

        IF pg_catalog.lower(pg_catalog.btrim(voucher.codigo)) <>
           pg_catalog.lower(normalized_code) THEN
            RAISE EXCEPTION 'Esta solicitacao ja possui outro voucher reservado';
        END IF;

        RETURN QUERY
        SELECT existing.voucher_reservation_id,
               existing.id_ad_voucher,
               existing.id_conta,
               existing.id_solicitacao_cadastro,
               coalesce(voucher.credito_disponivel, voucher.credito, 0)::numeric,
               existing.status,
               existing.expires_at,
               'already_reserved'::text;
        RETURN;
    END IF;

    SELECT legacy.*
      INTO voucher
      FROM ads.tb_ad_vouchers legacy
     WHERE pg_catalog.lower(pg_catalog.btrim(legacy.codigo)) =
           pg_catalog.lower(normalized_code)
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Voucher nao encontrado';
    END IF;

    IF voucher.status <> 1
       OR voucher.id_usuario_resgate IS NOT NULL
       OR voucher.data_resgate IS NOT NULL THEN
        RAISE EXCEPTION 'Voucher nao esta disponivel';
    END IF;

    IF voucher.data_expiracao IS NOT NULL
       AND voucher.data_expiracao < ads.business_date(clock_timestamp()) THEN
        RAISE EXCEPTION 'Voucher expirado';
    END IF;

    credit_amount := coalesce(
        voucher.credito_disponivel,
        voucher.credito,
        0
    )::numeric(14, 2);

    IF credit_amount <= 0 OR round(credit_amount, 2) <> credit_amount THEN
        RAISE EXCEPTION 'Credito do voucher e invalido';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM ads.voucher_reservations reservation
         WHERE reservation.id_ad_voucher = voucher.id_ad_voucher
           AND reservation.status = 'RESERVED'
    ) THEN
        RAISE EXCEPTION 'Voucher ja reservado por outra solicitacao';
    END IF;

    INSERT INTO ads.voucher_reservations (
        id_ad_voucher,
        id_conta,
        original_account_id,
        id_solicitacao_cadastro,
        reserved_by,
        status,
        expires_at,
        transition_reason
    )
    VALUES (
        voucher.id_ad_voucher,
        p_account_id,
        voucher.id_conta,
        p_registration_id,
        p_actor_id,
        'RESERVED',
        CASE
            WHEN voucher.data_expiracao IS NULL THEN NULL
            ELSE (voucher.data_expiracao + 1)::timestamp
                 AT TIME ZONE 'America/Sao_Paulo'
        END,
        'Voucher reservado durante a analise da conta'
    )
    RETURNING * INTO stored;

    UPDATE ads.tb_ad_vouchers target
       SET id_conta = p_account_id,
           data_atualizacao =
               clock_timestamp() AT TIME ZONE 'America/Sao_Paulo'
     WHERE target.id_ad_voucher = voucher.id_ad_voucher;

    UPDATE public.tb_conta_cadastro_solicitacoes request
       SET id_ad_voucher = voucher.id_ad_voucher,
           voucher_codigo = voucher.codigo
     WHERE request.id_solicitacao = p_registration_id;

    RETURN QUERY
    SELECT stored.voucher_reservation_id,
           stored.id_ad_voucher,
           stored.id_conta,
           stored.id_solicitacao_cadastro,
           credit_amount::numeric,
           stored.status,
           stored.expires_at,
           'reserved'::text;
END;
$function$;

CREATE OR REPLACE FUNCTION ads.apply_voucher_reservation(
    p_registration_id bigint,
    p_actor_id integer
)
RETURNS TABLE (
    voucher_reservation_id bigint,
    voucher_id integer,
    account_id bigint,
    ledger_entry_id uuid,
    amount numeric,
    balance_after numeric,
    reservation_status text,
    result_status text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
#variable_conflict use_column
DECLARE
    registration public.tb_conta_cadastro_solicitacoes%ROWTYPE;
    reservation ads.voucher_reservations%ROWTYPE;
    voucher ads.tb_ad_vouchers%ROWTYPE;
    redemption record;
BEGIN
    IF p_registration_id IS NULL OR p_registration_id <= 0
       OR p_actor_id IS NULL OR p_actor_id <= 0 THEN
        RAISE EXCEPTION 'Contexto invalido para aplicar voucher';
    END IF;

    SELECT request.*
      INTO registration
      FROM public.tb_conta_cadastro_solicitacoes request
     WHERE request.id_solicitacao = p_registration_id
     FOR UPDATE;

    IF NOT FOUND OR registration.id_conta IS NULL THEN
        RAISE EXCEPTION 'Solicitacao de cadastro nao encontrada';
    END IF;

    SELECT stored.*
      INTO reservation
      FROM ads.voucher_reservations stored
     WHERE stored.id_solicitacao_cadastro = p_registration_id
       AND stored.status IN ('RESERVED', 'APPLIED', 'EXPIRED')
     ORDER BY stored.voucher_reservation_id DESC
     LIMIT 1
     FOR UPDATE;

    IF NOT FOUND THEN
        RETURN;
    END IF;

    SELECT legacy.*
      INTO voucher
      FROM ads.tb_ad_vouchers legacy
     WHERE legacy.id_ad_voucher = reservation.id_ad_voucher
     FOR UPDATE;

    IF reservation.id_conta IS DISTINCT FROM registration.id_conta THEN
        RAISE EXCEPTION 'Reserva nao pertence a conta criada na solicitacao';
    END IF;

    IF reservation.status = 'APPLIED' THEN
        SELECT ledger.ledger_entry_id,
               ledger.amount,
               ledger.balance_after
          INTO redemption
          FROM ads.credit_ledger ledger
         WHERE ledger.idempotency_key =
               'legacy:voucher-redemption:v1:' || reservation.id_ad_voucher;

        RETURN QUERY
        SELECT reservation.voucher_reservation_id,
               reservation.id_ad_voucher,
               reservation.id_conta,
               redemption.ledger_entry_id,
               redemption.amount,
               redemption.balance_after,
               reservation.status,
               'already_applied'::text;
        RETURN;
    END IF;

    IF reservation.status = 'EXPIRED'
       OR (
           voucher.data_expiracao IS NOT NULL
           AND voucher.data_expiracao < ads.business_date(clock_timestamp())
       ) THEN
        UPDATE ads.voucher_reservations target
           SET status = 'EXPIRED',
               released_at = coalesce(target.released_at, clock_timestamp()),
               updated_at = clock_timestamp(),
               transition_reason = 'Voucher expirou antes da aprovacao da conta'
         WHERE target.voucher_reservation_id =
               reservation.voucher_reservation_id;

        RETURN QUERY
        SELECT reservation.voucher_reservation_id,
               reservation.id_ad_voucher,
               reservation.id_conta,
               NULL::uuid,
               NULL::numeric,
               NULL::numeric,
               'EXPIRED'::text,
               'expired'::text;
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM public.tb_contas account
         WHERE account.id_conta = reservation.id_conta
           AND account.status::text = 'ATIVA'
    ) THEN
        RAISE EXCEPTION 'Conta precisa estar ativa para aplicar o voucher';
    END IF;

    -- A alteracao antecede o resgate somente dentro desta transacao.
    -- Qualquer falha em redeem_voucher desfaz APPLIED automaticamente.
    UPDATE ads.voucher_reservations target
       SET status = 'APPLIED',
           applied_at = coalesce(target.applied_at, clock_timestamp()),
           updated_at = clock_timestamp(),
           transition_reason = 'Credito aplicado apos aprovacao da conta'
     WHERE target.voucher_reservation_id =
           reservation.voucher_reservation_id;

    SELECT redeemed.*
      INTO redemption
      FROM ads.redeem_voucher(
          reservation.id_conta,
          voucher.codigo::text,
          p_actor_id
      ) redeemed;

    RETURN QUERY
    SELECT reservation.voucher_reservation_id,
           reservation.id_ad_voucher,
           reservation.id_conta,
           redemption.ledger_entry_id,
           redemption.amount,
           redemption.balance_after,
           'APPLIED'::text,
           redemption.result_status::text;
END;
$function$;

CREATE OR REPLACE FUNCTION ads.release_voucher_reservation(
    p_registration_id bigint,
    p_actor_id integer,
    p_reason text
)
RETURNS TABLE (
    voucher_reservation_id bigint,
    voucher_id integer,
    reservation_status text,
    result_status text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
#variable_conflict use_column
DECLARE
    reservation ads.voucher_reservations%ROWTYPE;
    target_status text;
BEGIN
    IF p_registration_id IS NULL OR p_registration_id <= 0
       OR p_actor_id IS NULL OR p_actor_id <= 0
       OR nullif(pg_catalog.btrim(p_reason), '') IS NULL THEN
        RAISE EXCEPTION 'Contexto e motivo sao obrigatorios para liberar reserva';
    END IF;

    SELECT stored.*
      INTO reservation
      FROM ads.voucher_reservations stored
     WHERE stored.id_solicitacao_cadastro = p_registration_id
     ORDER BY stored.voucher_reservation_id DESC
     LIMIT 1
     FOR UPDATE;

    IF NOT FOUND THEN
        RETURN;
    END IF;

    IF reservation.status <> 'RESERVED' THEN
        RETURN QUERY
        SELECT reservation.voucher_reservation_id,
               reservation.id_ad_voucher,
               reservation.status,
               'already_closed'::text;
        RETURN;
    END IF;

    target_status := CASE
        WHEN reservation.expires_at IS NOT NULL
         AND reservation.expires_at <= clock_timestamp()
        THEN 'EXPIRED'
        ELSE 'RELEASED'
    END;

    UPDATE ads.voucher_reservations target
       SET status = target_status,
           released_at = clock_timestamp(),
           updated_at = clock_timestamp(),
           transition_reason = pg_catalog.btrim(p_reason)
     WHERE target.voucher_reservation_id =
           reservation.voucher_reservation_id;

    UPDATE ads.tb_ad_vouchers voucher
       SET id_conta = reservation.original_account_id,
           data_atualizacao =
               clock_timestamp() AT TIME ZONE 'America/Sao_Paulo'
     WHERE voucher.id_ad_voucher = reservation.id_ad_voucher
       AND voucher.status = 1;

    RETURN QUERY
    SELECT reservation.voucher_reservation_id,
           reservation.id_ad_voucher,
           target_status,
           'released'::text;
END;
$function$;

CREATE OR REPLACE FUNCTION ads.save_pending_event_campaign(
    p_campaign_id uuid,
    p_account_id bigint,
    p_registration_id bigint,
    p_core_event_id integer,
    p_placement_key text,
    p_name text,
    p_destination_url text,
    p_cpc_bid numeric,
    p_budget_total numeric,
    p_budget_daily numeric,
    p_starts_at timestamp with time zone,
    p_ends_at timestamp with time zone,
    p_target_device_class text DEFAULT 'ALL',
    p_target_country_code character(2) DEFAULT 'BR',
    p_target_region_code text DEFAULT NULL,
    p_changed_by integer DEFAULT NULL
)
RETURNS TABLE (
    campaign_id uuid,
    advertisement_id uuid,
    creative_id uuid,
    placement_id uuid,
    campaign_status text,
    result_status text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
#variable_conflict use_column
DECLARE
    target ads.campaigns%ROWTYPE;
    target_advertisement ads.advertisements%ROWTYPE;
    target_creative ads.creatives%ROWTYPE;
    selected_placement ads.placements%ROWTYPE;
    v_campaign_id uuid;
    v_advertisement_id uuid;
    v_creative_id uuid;
    v_result_status text;
    normalized_name text := nullif(pg_catalog.btrim(p_name), '');
    normalized_destination text :=
        nullif(pg_catalog.btrim(p_destination_url), '');
    normalized_device text := upper(coalesce(
        nullif(pg_catalog.btrim(p_target_device_class), ''),
        'ALL'
    ));
    normalized_country character(2) :=
        upper(nullif(pg_catalog.btrim(p_target_country_code), ''));
    normalized_region text :=
        upper(nullif(pg_catalog.btrim(p_target_region_code), ''));
BEGIN
    IF p_changed_by IS NULL OR p_changed_by <= 0 THEN
        RAISE EXCEPTION 'Usuario da alteracao e obrigatorio';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM public.tb_conta_cadastro_solicitacoes registration
          JOIN public.tb_contas account
            ON account.id_conta = registration.id_conta
           AND account.status::text = 'PENDENTE'
          JOIN public.tb_conta_usuarios membership
            ON membership.id_conta = registration.id_conta
           AND membership.id_usuario = registration.id_usuario
           AND membership.status::text = 'ATIVO'
           AND membership.papel::text = 'OWNER'
         WHERE registration.id_solicitacao = p_registration_id
           AND registration.id_conta = p_account_id
           AND registration.id_usuario = p_changed_by
           AND registration.status::text = 'PENDENTE'
    ) THEN
        RAISE EXCEPTION 'Conta provisoria nao pertence ao OWNER autenticado';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM public.tb_conta_eventos link
          JOIN public.tb_conta_evento_solicitacoes request
            ON request.id_conta = link.id_conta
           AND request.id_evento = link.id_evento
           AND request.id_usuario_solicitante = p_changed_by
           AND request.status = 'PENDENTE'
          JOIN public.tb_evento_corridas event
            ON event.id_evento = link.id_evento
           AND event.ativo
         WHERE link.id_conta = p_account_id
           AND link.id_evento = p_core_event_id
           AND link.status::text = 'PENDENTE'
    ) THEN
        RAISE EXCEPTION 'Evento pendente nao pertence ao OWNER e conta informados';
    END IF;

    IF normalized_name IS NULL THEN
        RAISE EXCEPTION 'Nome da campanha e obrigatorio';
    END IF;

    IF normalized_destination IS NULL
       OR normalized_destination !~ '^https://[^[:space:]]+$' THEN
        RAISE EXCEPTION 'Destino HTTPS valido e obrigatorio';
    END IF;

    IF p_cpc_bid IS NULL OR p_cpc_bid <= 0
       OR round(p_cpc_bid, 2) <> p_cpc_bid THEN
        RAISE EXCEPTION 'CPC deve ser positivo e ter no maximo duas casas';
    END IF;

    IF p_budget_total IS NULL OR p_budget_total <= 0
       OR round(p_budget_total, 2) <> p_budget_total THEN
        RAISE EXCEPTION 'Orcamento total invalido';
    END IF;

    IF p_budget_daily IS NOT NULL
       AND (
           p_budget_daily <= 0
           OR p_budget_daily > p_budget_total
           OR round(p_budget_daily, 2) <> p_budget_daily
       ) THEN
        RAISE EXCEPTION 'Orcamento diario invalido';
    END IF;

    IF p_starts_at IS NULL OR p_ends_at IS NULL
       OR p_ends_at <= p_starts_at THEN
        RAISE EXCEPTION 'Janela da campanha e obrigatoria e deve ser valida';
    END IF;

    IF normalized_device NOT IN ('ALL', 'DESKTOP', 'MOBILE') THEN
        RAISE EXCEPTION 'Dispositivo alvo invalido';
    END IF;

    SELECT placement.*
      INTO selected_placement
      FROM ads.placements placement
     WHERE placement.placement_key = nullif(pg_catalog.btrim(p_placement_key), '')
       AND placement.status = 'ACTIVE'
       AND placement.format_key = 'NATIVE_EVENT'
     FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Placement ativo de evento nao encontrado';
    END IF;

    IF p_campaign_id IS NULL THEN
        v_campaign_id := gen_random_uuid();
        v_advertisement_id := gen_random_uuid();
        v_creative_id := gen_random_uuid();
        v_result_status := 'created';

        INSERT INTO ads.campaigns (
            campaign_id, account_id, name, billing_model, status, currency,
            cpc_bid, budget_total, budget_daily, target_device_class,
            target_country_code, target_region_code, starts_at, ends_at,
            created_by, updated_by, metadata
        )
        VALUES (
            v_campaign_id, p_account_id, normalized_name, 'CPC', 'DRAFT', 'BRL',
            p_cpc_bid, p_budget_total, p_budget_daily, normalized_device,
            normalized_country, normalized_region, p_starts_at, p_ends_at,
            p_changed_by, p_changed_by,
            pg_catalog.jsonb_build_object(
                'managed_by', 'ads_business',
                'prepared_while_pending', true,
                'registration_id', p_registration_id
            )
        );

        INSERT INTO ads.advertisements (
            advertisement_id, campaign_id, account_id, billing_model,
            ad_type, name, status, core_event_id, destination_url,
            created_by, updated_by, metadata
        )
        VALUES (
            v_advertisement_id, v_campaign_id, p_account_id, 'CPC',
            'EVENT', normalized_name, 'ACTIVE', p_core_event_id,
            normalized_destination, p_changed_by, p_changed_by,
            '{"managed_by":"ads_business","prepared_while_pending":true}'::jsonb
        );

        INSERT INTO ads.creatives (
            creative_id, advertisement_id, campaign_id, account_id,
            billing_model, ad_type, creative_type, status, title,
            created_by, updated_by, payload
        )
        VALUES (
            v_creative_id, v_advertisement_id, v_campaign_id, p_account_id,
            'CPC', 'EVENT', 'NATIVE_EVENT', 'ACTIVE', normalized_name,
            p_changed_by, p_changed_by,
            '{"managed_by":"ads_business","prepared_while_pending":true}'::jsonb
        );

        INSERT INTO ads.campaign_placements (
            campaign_id, account_id, billing_model, placement_id,
            status, metadata
        )
        VALUES (
            v_campaign_id, p_account_id, 'CPC',
            selected_placement.placement_id, 'ACTIVE',
            '{"managed_by":"ads_business","prepared_while_pending":true}'::jsonb
        );
    ELSE
        SELECT stored.*
          INTO target
          FROM ads.campaigns stored
         WHERE stored.campaign_id = p_campaign_id
         FOR UPDATE;

        IF NOT FOUND
           OR target.account_id <> p_account_id
           OR target.billing_model <> 'CPC'
           OR target.status <> 'DRAFT'
           OR target.created_by IS DISTINCT FROM p_changed_by
           OR (target.metadata ->> 'registration_id')::bigint
              IS DISTINCT FROM p_registration_id THEN
            RAISE EXCEPTION 'Campanha pendente nao pertence ao contexto autorizado';
        END IF;

        SELECT advertisement.*
          INTO target_advertisement
          FROM ads.advertisements advertisement
         WHERE advertisement.campaign_id = target.campaign_id
           AND advertisement.account_id = target.account_id
           AND advertisement.billing_model = 'CPC'
           AND advertisement.ad_type = 'EVENT'
         FOR UPDATE;

        SELECT creative.*
          INTO target_creative
          FROM ads.creatives creative
         WHERE creative.advertisement_id =
               target_advertisement.advertisement_id
         FOR UPDATE;

        IF target_advertisement.advertisement_id IS NULL
           OR target_creative.creative_id IS NULL THEN
            RAISE EXCEPTION 'Campanha pendente possui estrutura incompleta';
        END IF;

        v_campaign_id := target.campaign_id;
        v_advertisement_id := target_advertisement.advertisement_id;
        v_creative_id := target_creative.creative_id;
        v_result_status := 'updated';

        UPDATE ads.campaigns campaign
           SET name = normalized_name,
               cpc_bid = p_cpc_bid,
               budget_total = p_budget_total,
               budget_daily = p_budget_daily,
               target_device_class = normalized_device,
               target_country_code = normalized_country,
               target_region_code = normalized_region,
               starts_at = p_starts_at,
               ends_at = p_ends_at,
               updated_by = p_changed_by,
               updated_at = clock_timestamp(),
               version = campaign.version + 1
         WHERE campaign.campaign_id = v_campaign_id;

        UPDATE ads.advertisements advertisement
           SET name = normalized_name,
               status = 'ACTIVE',
               core_event_id = p_core_event_id,
               destination_url = normalized_destination,
               updated_by = p_changed_by,
               updated_at = clock_timestamp()
         WHERE advertisement.advertisement_id = v_advertisement_id;

        UPDATE ads.creatives creative
           SET status = 'ACTIVE',
               title = normalized_name,
               updated_by = p_changed_by,
               updated_at = clock_timestamp()
         WHERE creative.creative_id = v_creative_id;

        UPDATE ads.campaign_placements link
           SET status = 'INACTIVE',
               updated_at = clock_timestamp()
         WHERE link.campaign_id = v_campaign_id
           AND link.placement_id <> selected_placement.placement_id;

        INSERT INTO ads.campaign_placements (
            campaign_id, account_id, billing_model, placement_id,
            status, metadata
        )
        VALUES (
            v_campaign_id, p_account_id, 'CPC',
            selected_placement.placement_id, 'ACTIVE',
            '{"managed_by":"ads_business","prepared_while_pending":true}'::jsonb
        )
        ON CONFLICT (campaign_id, placement_id)
        DO UPDATE SET status = 'ACTIVE',
                      updated_at = clock_timestamp();
    END IF;

    RETURN QUERY
    SELECT v_campaign_id,
           v_advertisement_id,
           v_creative_id,
           selected_placement.placement_id,
           'DRAFT'::text,
           v_result_status;
END;
$function$;

CREATE OR REPLACE FUNCTION ads.submit_campaign_review(
    p_campaign_id uuid,
    p_account_id bigint,
    p_actor_id integer,
    p_core_event_id integer
)
RETURNS TABLE (
    campaign_review_request_id bigint,
    campaign_id uuid,
    review_status text,
    result_status text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
#variable_conflict use_column
DECLARE
    campaign ads.campaigns%ROWTYPE;
    stored ads.campaign_review_requests%ROWTYPE;
    previous_status text;
    account_active boolean;
    event_active boolean;
    pending_owner boolean;
    active_operator boolean;
    target_status text;
BEGIN
    SELECT current_campaign.*
      INTO campaign
      FROM ads.campaigns current_campaign
     WHERE current_campaign.campaign_id = p_campaign_id
       AND current_campaign.account_id = p_account_id
     FOR UPDATE;

    IF NOT FOUND OR campaign.status <> 'DRAFT' THEN
        RAISE EXCEPTION 'Somente campanha DRAFT da conta pode ser enviada';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM ads.advertisements advertisement
         WHERE advertisement.campaign_id = campaign.campaign_id
           AND advertisement.account_id = campaign.account_id
           AND advertisement.ad_type = 'EVENT'
           AND advertisement.core_event_id = p_core_event_id
    ) THEN
        RAISE EXCEPTION 'Evento nao pertence a campanha';
    END IF;

    SELECT account.status::text = 'ATIVA'
      INTO account_active
      FROM public.tb_contas account
     WHERE account.id_conta = p_account_id;

    SELECT EXISTS (
        SELECT 1
          FROM public.tb_conta_eventos link
         WHERE link.id_conta = p_account_id
           AND link.id_evento = p_core_event_id
           AND link.status::text = 'ATIVO'
    ) INTO event_active;

    SELECT EXISTS (
        SELECT 1
          FROM public.tb_conta_cadastro_solicitacoes registration
          JOIN public.tb_contas account
            ON account.id_conta = registration.id_conta
           AND account.status::text = 'PENDENTE'
          JOIN public.tb_conta_usuarios membership
            ON membership.id_conta = registration.id_conta
           AND membership.id_usuario = p_actor_id
           AND membership.status::text = 'ATIVO'
           AND membership.papel::text = 'OWNER'
          JOIN public.tb_conta_evento_solicitacoes event_request
            ON event_request.id_conta = registration.id_conta
           AND event_request.id_evento = p_core_event_id
           AND event_request.id_usuario_solicitante = p_actor_id
           AND event_request.status = 'PENDENTE'
         WHERE registration.id_conta = p_account_id
           AND registration.id_usuario = p_actor_id
           AND registration.status::text = 'PENDENTE'
    ) INTO pending_owner;

    SELECT EXISTS (
        SELECT 1
          FROM public.tb_conta_usuarios membership
         WHERE membership.id_conta = p_account_id
           AND membership.id_usuario = p_actor_id
           AND membership.status::text = 'ATIVO'
           AND membership.papel::text IN ('OWNER', 'ADMIN', 'OPERADOR')
    ) INTO active_operator;

    IF NOT (
        (coalesce(account_active, false) AND active_operator)
        OR pending_owner
    ) THEN
        RAISE EXCEPTION 'Usuario nao pode enviar campanha desta conta';
    END IF;

    target_status := CASE
        WHEN coalesce(account_active, false) AND coalesce(event_active, false)
        THEN 'PENDING_REVIEW'
        ELSE 'WAITING_PREREQUISITES'
    END;

    SELECT review.*
      INTO stored
      FROM ads.campaign_review_requests review
     WHERE review.campaign_id = p_campaign_id
       AND review.status IN (
           'WAITING_PREREQUISITES',
           'PENDING_REVIEW',
           'CHANGES_REQUESTED'
       )
     FOR UPDATE;

    IF FOUND THEN
        previous_status := stored.status;
        UPDATE ads.campaign_review_requests review
           SET status = target_status,
               core_event_id = p_core_event_id,
               requested_by = p_actor_id,
               submitted_at = clock_timestamp(),
               reviewed_by = NULL,
               reviewed_at = NULL,
               review_reason = NULL,
               updated_at = clock_timestamp()
         WHERE review.campaign_review_request_id =
               stored.campaign_review_request_id
        RETURNING * INTO stored;
    ELSE
        previous_status := NULL;
        INSERT INTO ads.campaign_review_requests (
            campaign_id,
            account_id,
            core_event_id,
            status,
            requested_by
        )
        VALUES (
            p_campaign_id,
            p_account_id,
            p_core_event_id,
            target_status,
            p_actor_id
        )
        RETURNING * INTO stored;
    END IF;

    IF previous_status IS DISTINCT FROM stored.status THEN
        INSERT INTO ads.campaign_review_history (
            campaign_review_request_id,
            from_status,
            to_status,
            actor_id,
            reason
        )
        VALUES (
            stored.campaign_review_request_id,
            previous_status,
            stored.status,
            p_actor_id,
            'Campanha enviada para analise'
        );
    END IF;

    RETURN QUERY
    SELECT stored.campaign_review_request_id,
           stored.campaign_id,
           stored.status,
           CASE
               WHEN previous_status IS NULL THEN 'created'
               ELSE 'updated'
           END;
END;
$function$;

CREATE OR REPLACE FUNCTION ads.refresh_campaign_review_prerequisites(
    p_account_id bigint,
    p_core_event_id integer,
    p_actor_id integer
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
    review ads.campaign_review_requests%ROWTYPE;
    actor_is_admin boolean;
    account_status text;
    event_status text;
    target_status text;
    target_reason text;
    changed_count integer := 0;
BEGIN
    IF p_account_id IS NULL OR p_account_id <= 0
       OR p_actor_id IS NULL OR p_actor_id <= 0 THEN
        RAISE EXCEPTION 'Conta e ator sao obrigatorios para reavaliar campanhas';
    END IF;

    SELECT actor.is_admin
      INTO actor_is_admin
      FROM public.tb_usuarios actor
     WHERE actor.id = p_actor_id;

    IF NOT FOUND OR actor_is_admin IS NOT TRUE THEN
        RAISE EXCEPTION 'Somente administrador RunnerHub pode reavaliar campanhas';
    END IF;

    SELECT account.status::text
      INTO account_status
      FROM public.tb_contas account
     WHERE account.id_conta = p_account_id;

    FOR review IN
        SELECT stored.*
          FROM ads.campaign_review_requests stored
         WHERE stored.account_id = p_account_id
           AND (
               p_core_event_id IS NULL
               OR stored.core_event_id = p_core_event_id
           )
           AND stored.status IN (
               'WAITING_PREREQUISITES',
               'PENDING_REVIEW'
           )
         FOR UPDATE
    LOOP
        SELECT link.status::text
          INTO event_status
          FROM public.tb_conta_eventos link
         WHERE link.id_conta = review.account_id
           AND link.id_evento = review.core_event_id;

        IF event_status = 'INATIVO' THEN
            target_status := 'CHANGES_REQUESTED';
            target_reason := 'Evento nao aprovado; escolha outro evento.';
        ELSIF account_status = 'ATIVA' AND event_status = 'ATIVO' THEN
            target_status := 'PENDING_REVIEW';
            target_reason := 'Conta e evento aprovados; anuncio liberado para analise.';
        ELSE
            target_status := 'WAITING_PREREQUISITES';
            target_reason := 'Aguardando aprovacao da conta e/ou do evento.';
        END IF;

        IF review.status IS DISTINCT FROM target_status THEN
            UPDATE ads.campaign_review_requests target
               SET status = target_status,
                   review_reason = CASE
                       WHEN target_status = 'CHANGES_REQUESTED'
                       THEN target_reason
                       ELSE NULL
                   END,
                   updated_at = clock_timestamp()
             WHERE target.campaign_review_request_id =
                   review.campaign_review_request_id;

            INSERT INTO ads.campaign_review_history (
                campaign_review_request_id,
                from_status,
                to_status,
                actor_id,
                reason
            )
            VALUES (
                review.campaign_review_request_id,
                review.status,
                target_status,
                p_actor_id,
                target_reason
            );

            changed_count := changed_count + 1;
        END IF;
    END LOOP;

    RETURN changed_count;
END;
$function$;

CREATE OR REPLACE FUNCTION ads.cancel_open_campaign_reviews(
    p_account_id bigint,
    p_actor_id integer,
    p_reason text
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
    review ads.campaign_review_requests%ROWTYPE;
    changed_count integer := 0;
BEGIN
    IF p_account_id IS NULL OR p_account_id <= 0
       OR p_actor_id IS NULL OR p_actor_id <= 0
       OR nullif(pg_catalog.btrim(p_reason), '') IS NULL THEN
        RAISE EXCEPTION 'Conta, ator e motivo sao obrigatorios';
    END IF;

    FOR review IN
        SELECT stored.*
          FROM ads.campaign_review_requests stored
         WHERE stored.account_id = p_account_id
           AND stored.status IN (
               'WAITING_PREREQUISITES',
               'PENDING_REVIEW',
               'CHANGES_REQUESTED'
           )
         FOR UPDATE
    LOOP
        UPDATE ads.campaign_review_requests target
           SET status = 'CANCELED',
               reviewed_by = p_actor_id,
               reviewed_at = clock_timestamp(),
               updated_at = clock_timestamp(),
               review_reason = pg_catalog.btrim(p_reason)
         WHERE target.campaign_review_request_id =
               review.campaign_review_request_id;

        INSERT INTO ads.campaign_review_history (
            campaign_review_request_id,
            from_status,
            to_status,
            actor_id,
            reason
        )
        VALUES (
            review.campaign_review_request_id,
            review.status,
            'CANCELED',
            p_actor_id,
            pg_catalog.btrim(p_reason)
        );

        changed_count := changed_count + 1;
    END LOOP;

    RETURN changed_count;
END;
$function$;

CREATE OR REPLACE FUNCTION ads.review_campaign(
    p_campaign_id uuid,
    p_action text,
    p_actor_id integer,
    p_reason text,
    p_idempotency_key text
)
RETURNS TABLE (
    campaign_review_request_id bigint,
    campaign_id uuid,
    review_status text,
    campaign_status text,
    result_status text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
#variable_conflict use_column
DECLARE
    review ads.campaign_review_requests%ROWTYPE;
    campaign ads.campaigns%ROWTYPE;
    normalized_action text := upper(pg_catalog.btrim(p_action));
    normalized_reason text := nullif(pg_catalog.btrim(p_reason), '');
    account_active boolean;
    event_active boolean;
    placement_ready boolean;
    has_balance boolean;
    new_review_status text;
BEGIN
    IF p_actor_id IS NULL OR p_actor_id <= 0
       OR NOT EXISTS (
           SELECT 1
             FROM public.tb_usuarios actor
            WHERE actor.id = p_actor_id
              AND (coalesce(actor.is_admin, false) OR coalesce(actor.is_dev, false))
       ) THEN
        RAISE EXCEPTION 'Somente administrador RunnerHub revisa publicidade';
    END IF;

    IF normalized_action NOT IN ('APPROVE', 'REQUEST_CHANGES', 'CANCEL') THEN
        RAISE EXCEPTION 'Acao de revisao invalida';
    END IF;

    IF normalized_action IN ('REQUEST_CHANGES', 'CANCEL')
       AND (
           normalized_reason IS NULL
           OR length(normalized_reason) < 5
           OR length(normalized_reason) > 1000
       ) THEN
        RAISE EXCEPTION 'Motivo deve possuir entre 5 e 1000 caracteres';
    END IF;

    SELECT stored.*
      INTO review
      FROM ads.campaign_review_requests stored
     WHERE stored.campaign_id = p_campaign_id
       AND stored.status IN (
           'WAITING_PREREQUISITES',
           'PENDING_REVIEW',
           'CHANGES_REQUESTED',
           'APPROVED'
       )
     ORDER BY stored.campaign_review_request_id DESC
     LIMIT 1
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Solicitacao de revisao nao encontrada';
    END IF;

    SELECT stored.*
      INTO campaign
      FROM ads.campaigns stored
     WHERE stored.campaign_id = review.campaign_id
       AND stored.account_id = review.account_id
     FOR UPDATE;

    IF normalized_action = 'APPROVE'
       AND review.status = 'APPROVED'
       AND campaign.status = 'ACTIVE' THEN
        RETURN QUERY
        SELECT review.campaign_review_request_id,
               review.campaign_id,
               review.status,
               campaign.status,
               'already_approved'::text;
        RETURN;
    END IF;

    IF normalized_action = 'APPROVE' THEN
        IF review.status <> 'PENDING_REVIEW' THEN
            RAISE EXCEPTION 'Campanha ainda nao esta elegivel para aprovacao';
        END IF;

        SELECT account.status::text = 'ATIVA'
          INTO account_active
          FROM public.tb_contas account
         WHERE account.id_conta = review.account_id;

        SELECT EXISTS (
            SELECT 1
              FROM public.tb_conta_eventos link
              JOIN public.tb_evento_corridas event
                ON event.id_evento = link.id_evento
               AND event.ativo
             WHERE link.id_conta = review.account_id
               AND link.id_evento = review.core_event_id
               AND link.status::text = 'ATIVO'
        ) INTO event_active;

        SELECT EXISTS (
            SELECT 1
              FROM ads.campaign_placements link
              JOIN ads.placements placement
                ON placement.placement_id = link.placement_id
               AND placement.status = 'ACTIVE'
             WHERE link.campaign_id = campaign.campaign_id
               AND link.account_id = campaign.account_id
               AND link.status = 'ACTIVE'
        ) INTO placement_ready;

        SELECT EXISTS (
            SELECT 1
              FROM ads.account_balances balance
             WHERE balance.account_id = campaign.account_id
               AND balance.currency = campaign.currency
               AND balance.available_balance >= campaign.cpc_bid
        ) INTO has_balance;

        IF NOT coalesce(account_active, false)
           OR NOT coalesce(event_active, false)
           OR NOT coalesce(placement_ready, false)
           OR NOT coalesce(has_balance, false)
           OR campaign.status <> 'DRAFT'
           OR campaign.starts_at IS NULL
           OR campaign.ends_at IS NULL
           OR campaign.ends_at <= campaign.starts_at
           OR campaign.ends_at <= clock_timestamp()
           OR campaign.cpc_bid IS NULL
           OR campaign.budget_total IS NULL THEN
            RAISE EXCEPTION 'Campanha nao atende aos pre-requisitos de ativacao';
        END IF;

        IF nullif(pg_catalog.btrim(p_idempotency_key), '') IS NULL THEN
            RAISE EXCEPTION 'Chave idempotente de aprovacao e obrigatoria';
        END IF;

        UPDATE ads.campaign_review_requests target
           SET status = 'APPROVED',
               reviewed_by = p_actor_id,
               reviewed_at = clock_timestamp(),
               updated_at = clock_timestamp(),
               review_reason = normalized_reason,
               approval_idempotency_key =
                   pg_catalog.btrim(p_idempotency_key)
         WHERE target.campaign_review_request_id =
               review.campaign_review_request_id;

        PERFORM ads.activate_campaign(
            campaign.campaign_id,
            p_actor_id,
            coalesce(normalized_reason, 'Aprovacao RunnerHub')
        );

        new_review_status := 'APPROVED';
    ELSIF normalized_action = 'REQUEST_CHANGES' THEN
        IF review.status NOT IN (
            'WAITING_PREREQUISITES',
            'PENDING_REVIEW',
            'CHANGES_REQUESTED'
        ) THEN
            RAISE EXCEPTION 'Revisao encerrada nao aceita ajustes';
        END IF;

        UPDATE ads.campaign_review_requests target
           SET status = 'CHANGES_REQUESTED',
               reviewed_by = p_actor_id,
               reviewed_at = clock_timestamp(),
               updated_at = clock_timestamp(),
               review_reason = normalized_reason
         WHERE target.campaign_review_request_id =
               review.campaign_review_request_id;

        new_review_status := 'CHANGES_REQUESTED';
    ELSE
        IF review.status = 'APPROVED' THEN
            RAISE EXCEPTION 'Campanha aprovada deve ser pausada ou encerrada pelo fluxo canonico';
        END IF;

        UPDATE ads.campaign_review_requests target
           SET status = 'CANCELED',
               reviewed_by = p_actor_id,
               reviewed_at = clock_timestamp(),
               updated_at = clock_timestamp(),
               review_reason = normalized_reason
         WHERE target.campaign_review_request_id =
               review.campaign_review_request_id;

        new_review_status := 'CANCELED';
    END IF;

    IF review.status IS DISTINCT FROM new_review_status THEN
        INSERT INTO ads.campaign_review_history (
            campaign_review_request_id,
            from_status,
            to_status,
            actor_id,
            reason
        )
        VALUES (
            review.campaign_review_request_id,
            review.status,
            new_review_status,
            p_actor_id,
            normalized_reason
        );
    END IF;

    SELECT stored.*
      INTO campaign
      FROM ads.campaigns stored
     WHERE stored.campaign_id = review.campaign_id;

    RETURN QUERY
    SELECT review.campaign_review_request_id,
           review.campaign_id,
           new_review_status,
           campaign.status,
           'updated'::text;
END;
$function$;

ALTER TABLE ads.voucher_reservations OWNER TO ads_owner;
ALTER TABLE ads.campaign_review_requests OWNER TO ads_owner;
ALTER TABLE ads.campaign_review_history OWNER TO ads_owner;
ALTER SEQUENCE ads.voucher_reservations_voucher_reservation_id_seq
    OWNER TO ads_owner;
ALTER SEQUENCE ads.campaign_review_requests_campaign_review_request_id_seq
    OWNER TO ads_owner;
ALTER SEQUENCE ads.campaign_review_history_campaign_review_history_id_seq
    OWNER TO ads_owner;

ALTER FUNCTION ads.guard_reserved_voucher_redemption() OWNER TO ads_owner;
ALTER FUNCTION ads.reserve_voucher(bigint, bigint, text, integer)
    OWNER TO ads_owner;
ALTER FUNCTION ads.apply_voucher_reservation(bigint, integer)
    OWNER TO ads_owner;
ALTER FUNCTION ads.release_voucher_reservation(bigint, integer, text)
    OWNER TO ads_owner;
ALTER FUNCTION ads.save_pending_event_campaign(
    uuid, bigint, bigint, integer, text, text, text, numeric, numeric,
    numeric, timestamp with time zone, timestamp with time zone, text,
    character, text, integer
) OWNER TO ads_owner;
ALTER FUNCTION ads.submit_campaign_review(uuid, bigint, integer, integer)
    OWNER TO ads_owner;
ALTER FUNCTION ads.refresh_campaign_review_prerequisites(
    bigint, integer, integer
) OWNER TO ads_owner;
ALTER FUNCTION ads.cancel_open_campaign_reviews(bigint, integer, text)
    OWNER TO ads_owner;
ALTER FUNCTION ads.review_campaign(uuid, text, integer, text, text)
    OWNER TO ads_owner;

-- Dependencias public usadas pelas APIs SECURITY DEFINER deste fluxo.
GRANT SELECT ON TABLE public.tb_contas TO ads_owner;
GRANT SELECT ON TABLE public.tb_conta_usuarios TO ads_owner;
GRANT SELECT ON TABLE public.tb_conta_eventos TO ads_owner;
GRANT SELECT ON TABLE public.tb_conta_evento_solicitacoes TO ads_owner;
GRANT SELECT ON TABLE public.tb_evento_corridas TO ads_owner;
GRANT SELECT ON TABLE public.tb_usuarios TO ads_owner;
GRANT SELECT, UPDATE ON TABLE public.tb_conta_cadastro_solicitacoes TO ads_owner;

REVOKE ALL ON TABLE
    ads.voucher_reservations,
    ads.campaign_review_requests,
    ads.campaign_review_history
FROM PUBLIC, runner, runner_dba, ads_reader, ads_delivery, ads_admin,
    ads_finance, ads_business;

GRANT SELECT ON ads.voucher_reservations TO ads_business, ads_admin;
GRANT SELECT ON ads.campaign_review_requests TO ads_business, ads_admin;
GRANT SELECT ON ads.campaign_review_history TO ads_business, ads_admin;

REVOKE ALL ON SEQUENCE
    ads.voucher_reservations_voucher_reservation_id_seq,
    ads.campaign_review_requests_campaign_review_request_id_seq,
    ads.campaign_review_history_campaign_review_history_id_seq
FROM PUBLIC, runner, runner_dba, ads_reader, ads_delivery, ads_admin,
    ads_finance, ads_business;

GRANT SELECT, USAGE ON SEQUENCE
    ads.voucher_reservations_voucher_reservation_id_seq,
    ads.campaign_review_requests_campaign_review_request_id_seq,
    ads.campaign_review_history_campaign_review_history_id_seq
TO ads_business, ads_admin;

REVOKE ALL ON FUNCTION
    ads.guard_reserved_voucher_redemption(),
    ads.reserve_voucher(bigint, bigint, text, integer),
    ads.apply_voucher_reservation(bigint, integer),
    ads.release_voucher_reservation(bigint, integer, text),
    ads.save_pending_event_campaign(
        uuid, bigint, bigint, integer, text, text, text, numeric, numeric,
        numeric, timestamp with time zone, timestamp with time zone, text,
        character, text, integer
    ),
    ads.submit_campaign_review(uuid, bigint, integer, integer),
    ads.refresh_campaign_review_prerequisites(bigint, integer, integer),
    ads.cancel_open_campaign_reviews(bigint, integer, text),
    ads.review_campaign(uuid, text, integer, text, text)
FROM PUBLIC, runner, runner_dba, ads_reader, ads_delivery, ads_admin,
    ads_finance, ads_business;

GRANT EXECUTE ON FUNCTION
    ads.reserve_voucher(bigint, bigint, text, integer),
    ads.apply_voucher_reservation(bigint, integer),
    ads.release_voucher_reservation(bigint, integer, text),
    ads.save_pending_event_campaign(
        uuid, bigint, bigint, integer, text, text, text, numeric, numeric,
        numeric, timestamp with time zone, timestamp with time zone, text,
        character, text, integer
    ),
    ads.submit_campaign_review(uuid, bigint, integer, integer)
TO ads_business;

GRANT EXECUTE ON FUNCTION
    ads.refresh_campaign_review_prerequisites(bigint, integer, integer)
TO ads_business;

GRANT EXECUTE ON FUNCTION
    ads.apply_voucher_reservation(bigint, integer),
    ads.release_voucher_reservation(bigint, integer, text),
    ads.refresh_campaign_review_prerequisites(bigint, integer, integer),
    ads.cancel_open_campaign_reviews(bigint, integer, text),
    ads.review_campaign(uuid, text, integer, text, text)
TO ads_admin;

INSERT INTO ads.schema_migrations (migration_key, description)
VALUES (
    '2026-08-24_ads_pending_onboarding',
    'Reserva de voucher e revisao de campanhas durante onboarding Business'
)
ON CONFLICT (migration_key) DO NOTHING;

COMMIT;
