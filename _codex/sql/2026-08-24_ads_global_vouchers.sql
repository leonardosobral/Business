-- Vouchers globais de publicidade.
-- ACCOUNT: restrito a uma conta desde a criacao.
-- PROMOTIONAL: nasce sem conta e e vinculado atomicamente no primeiro uso.

BEGIN;

ALTER TABLE ads.tb_ad_vouchers
    ADD COLUMN IF NOT EXISTS voucher_scope text;

UPDATE ads.tb_ad_vouchers
   SET voucher_scope = CASE
       WHEN id_conta IS NULL THEN 'PROMOTIONAL'
       ELSE 'ACCOUNT'
   END
 WHERE voucher_scope IS NULL;

ALTER TABLE ads.tb_ad_vouchers
    ALTER COLUMN voucher_scope SET DEFAULT 'ACCOUNT',
    ALTER COLUMN voucher_scope SET NOT NULL;

ALTER TABLE ads.tb_ad_vouchers
    DROP CONSTRAINT IF EXISTS ck_tb_ad_vouchers_scope;

ALTER TABLE ads.tb_ad_vouchers
    ADD CONSTRAINT ck_tb_ad_vouchers_scope
    CHECK (
        voucher_scope IN ('PROMOTIONAL', 'ACCOUNT')
        AND (voucher_scope <> 'ACCOUNT' OR id_conta IS NOT NULL)
    );

CREATE INDEX IF NOT EXISTS idx_tb_ad_vouchers_scope_status
    ON ads.tb_ad_vouchers (voucher_scope, status, data_expiracao);

CREATE OR REPLACE FUNCTION ads.create_voucher(
    p_scope_type text,
    p_account_id bigint,
    p_code text,
    p_amount numeric,
    p_expires_on date,
    p_redemption_role text,
    p_note text,
    p_created_by integer
)
RETURNS TABLE (
    voucher_id integer,
    code text,
    amount numeric,
    status integer,
    result_status text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
    created ads.tb_ad_vouchers%ROWTYPE;
    normalized_scope text := upper(pg_catalog.btrim(p_scope_type));
    normalized_code text := upper(pg_catalog.btrim(p_code));
    normalized_role text := upper(pg_catalog.btrim(p_redemption_role));
    normalized_note text := nullif(pg_catalog.btrim(p_note), '');
    credit_amount numeric(14, 2) := p_amount::numeric(14, 2);
    local_now timestamp :=
        clock_timestamp() AT TIME ZONE 'America/Sao_Paulo';
BEGIN
    IF p_created_by IS NULL OR p_created_by <= 0 OR NOT EXISTS (
        SELECT 1
          FROM public.tb_usuarios user_info
         WHERE user_info.id = p_created_by
           AND coalesce(user_info.is_admin, false)
    ) THEN
        RAISE EXCEPTION 'Somente administrador interno pode criar voucher';
    END IF;

    IF normalized_scope NOT IN ('PROMOTIONAL', 'ACCOUNT') THEN
        RAISE EXCEPTION 'Tipo de voucher invalido';
    END IF;

    IF normalized_scope = 'PROMOTIONAL' AND p_account_id IS NOT NULL THEN
        RAISE EXCEPTION 'Voucher promocional deve nascer sem conta';
    END IF;

    IF normalized_scope = 'ACCOUNT' AND (
        p_account_id IS NULL
        OR p_account_id <= 0
        OR NOT EXISTS (
            SELECT 1
              FROM public.tb_contas account_info
             WHERE account_info.id_conta = p_account_id
        )
    ) THEN
        RAISE EXCEPTION 'Conta invalida para o voucher restrito';
    END IF;

    IF nullif(normalized_code, '') IS NULL
       OR length(normalized_code) > 80
       OR normalized_code !~ '^[A-Z0-9-]+$' THEN
        RAISE EXCEPTION 'Codigo de voucher invalido';
    END IF;

    IF credit_amount IS NULL
       OR credit_amount <= 0
       OR round(credit_amount, 2) <> credit_amount THEN
        RAISE EXCEPTION 'Credito do voucher e invalido';
    END IF;

    IF normalized_role IS NULL OR normalized_role NOT IN (
        'OWNER', 'ADMIN', 'OPERADOR', 'VISUALIZADOR'
    ) THEN
        RAISE EXCEPTION 'Papel de resgate do voucher e invalido';
    END IF;

    IF p_expires_on IS NOT NULL
       AND p_expires_on < local_now::date THEN
        RAISE EXCEPTION 'Data de expiracao do voucher e invalida';
    END IF;

    IF normalized_note IS NOT NULL AND length(normalized_note) > 2000 THEN
        RAISE EXCEPTION 'Observacao do voucher excede o limite';
    END IF;

    INSERT INTO ads.tb_ad_vouchers (
        codigo,
        id_conta,
        credito,
        credito_disponivel,
        status,
        data_criacao,
        data_expiracao,
        papel_resgate,
        observacao,
        data_atualizacao,
        voucher_scope
    )
    VALUES (
        normalized_code,
        CASE WHEN normalized_scope = 'ACCOUNT' THEN p_account_id ELSE NULL END,
        credit_amount,
        credit_amount,
        1,
        local_now::date,
        p_expires_on,
        normalized_role::public.papel_usuario_conta,
        normalized_note,
        local_now,
        normalized_scope
    )
    RETURNING * INTO created;

    RETURN QUERY
    SELECT created.id_ad_voucher,
           created.codigo::text,
           created.credito::numeric,
           created.status::integer,
           'created'::text;
END;
$function$;

-- Mantem compatibilidade: a assinatura anterior sempre cria voucher de conta.
CREATE OR REPLACE FUNCTION ads.create_voucher(
    p_account_id bigint,
    p_code text,
    p_amount numeric,
    p_expires_on date,
    p_redemption_role text,
    p_note text,
    p_created_by integer
)
RETURNS TABLE (
    voucher_id integer,
    code text,
    amount numeric,
    status integer,
    result_status text
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
    SELECT *
      FROM ads.create_voucher(
          'ACCOUNT'::text,
          p_account_id,
          p_code,
          p_amount,
          p_expires_on,
          p_redemption_role,
          p_note,
          p_created_by
      );
$function$;

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

    IF voucher.voucher_scope = 'ACCOUNT' AND voucher.id_conta IS DISTINCT FROM p_account_id THEN
        RAISE EXCEPTION 'Voucher restrito a outra conta';
    END IF;

    IF voucher.voucher_scope = 'PROMOTIONAL'
       AND voucher.id_conta IS NOT NULL
       AND voucher.id_conta IS DISTINCT FROM p_account_id THEN
        RAISE EXCEPTION 'Voucher promocional ja pertence a outra conta';
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

    IF voucher.voucher_scope = 'PROMOTIONAL' AND voucher.id_conta IS NULL THEN
        UPDATE ads.tb_ad_vouchers target
           SET id_conta = p_account_id,
               data_atualizacao =
                   clock_timestamp() AT TIME ZONE 'America/Sao_Paulo'
         WHERE target.id_ad_voucher = voucher.id_ad_voucher;
    END IF;

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

CREATE OR REPLACE FUNCTION ads.redeem_voucher(
    p_account_id bigint,
    p_code text,
    p_created_by integer
)
RETURNS TABLE (
    voucher_id integer,
    ledger_entry_id uuid,
    amount numeric,
    balance_after numeric,
    result_status text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
    voucher ads.tb_ad_vouchers%ROWTYPE;
    existing ads.credit_ledger%ROWTYPE;
    credited record;
    credit_amount numeric(14, 2);
    normalized_code text := upper(pg_catalog.btrim(p_code));
    voucher_ledger_key text;
    local_now timestamp :=
        clock_timestamp() AT TIME ZONE 'America/Sao_Paulo';
BEGIN
    IF p_account_id IS NULL OR p_account_id <= 0 THEN
        RAISE EXCEPTION 'Conta invalida para o voucher';
    END IF;

    IF nullif(normalized_code, '') IS NULL
       OR length(normalized_code) > 160
       OR normalized_code !~ '^[A-Z0-9-]+$' THEN
        RAISE EXCEPTION 'Codigo de voucher invalido';
    END IF;

    IF p_created_by IS NULL OR p_created_by <= 0 THEN
        RAISE EXCEPTION 'Usuario do resgate e obrigatorio';
    END IF;

    SELECT stored.*
      INTO voucher
      FROM ads.tb_ad_vouchers stored
     WHERE pg_catalog.lower(pg_catalog.btrim(stored.codigo)) =
           pg_catalog.lower(normalized_code)
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Voucher nao encontrado';
    END IF;

    IF voucher.voucher_scope = 'ACCOUNT' AND voucher.id_conta IS DISTINCT FROM p_account_id THEN
        RAISE EXCEPTION 'Voucher nao encontrado para esta conta';
    END IF;

    IF voucher.voucher_scope = 'PROMOTIONAL'
       AND voucher.id_conta IS NOT NULL
       AND voucher.id_conta IS DISTINCT FROM p_account_id THEN
        RAISE EXCEPTION 'Voucher promocional ja pertence a outra conta';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM ads.voucher_reservations reservation
         WHERE reservation.id_ad_voucher = voucher.id_ad_voucher
           AND reservation.status = 'RESERVED'
           AND reservation.id_conta IS DISTINCT FROM p_account_id
    ) THEN
        RAISE EXCEPTION 'Voucher reservado por outra conta';
    END IF;

    IF voucher.voucher_scope = 'PROMOTIONAL' AND voucher.id_conta IS NULL THEN
        UPDATE ads.tb_ad_vouchers target
           SET id_conta = p_account_id,
               data_atualizacao = local_now
         WHERE target.id_ad_voucher = voucher.id_ad_voucher;
        voucher.id_conta := p_account_id;
    END IF;

    credit_amount := coalesce(
        voucher.credito_disponivel,
        voucher.credito,
        0
    )::numeric(14, 2);
    voucher_ledger_key :=
        'legacy:voucher-redemption:v1:' || voucher.id_ad_voucher;

    IF voucher.status = 2 THEN
        SELECT ledger.*
          INTO existing
          FROM ads.credit_ledger ledger
         WHERE ledger.idempotency_key = voucher_ledger_key;

        IF NOT FOUND THEN
            RAISE EXCEPTION
                'Voucher legado resgatado sem credito canonico; use recuperacao explicita';
        END IF;

        IF existing.account_id <> p_account_id
           OR existing.source_type <> 'VOUCHER'
           OR existing.entry_type <> 'CREDIT'
           OR existing.amount <> credit_amount THEN
            RAISE EXCEPTION
                'Credito canonico do voucher diverge do registro legado';
        END IF;

        RETURN QUERY
        SELECT voucher.id_ad_voucher,
               existing.ledger_entry_id,
               existing.amount,
               existing.balance_after,
               'already_recorded'::text;
        RETURN;
    END IF;

    IF voucher.status <> 1 THEN
        RAISE EXCEPTION 'Voucher nao esta disponivel para resgate';
    END IF;

    IF voucher.data_expiracao IS NOT NULL
       AND voucher.data_expiracao < ads.business_date(clock_timestamp()) THEN
        RAISE EXCEPTION 'Voucher expirado';
    END IF;

    IF credit_amount <= 0 OR round(credit_amount, 2) <> credit_amount THEN
        RAISE EXCEPTION 'Credito do voucher e invalido';
    END IF;

    SELECT result.*
      INTO credited
      FROM ads.credit_account(
          p_account_id,
          credit_amount,
          voucher_ledger_key,
          'VOUCHER',
          p_created_by,
          pg_catalog.jsonb_build_object(
              'module', 'business_ads',
              'voucher_id', voucher.id_ad_voucher,
              'voucher_code', normalized_code,
              'voucher_scope', voucher.voucher_scope,
              'redemption_mode', 'canonical'
          )
      ) result;

    UPDATE ads.tb_ad_vouchers target
       SET status = 2,
           id_usuario_resgate = p_created_by,
           data_resgate = coalesce(target.data_resgate, local_now),
           credito_disponivel = credit_amount,
           data_atualizacao = local_now
     WHERE target.id_ad_voucher = voucher.id_ad_voucher
       AND target.status = 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Voucher mudou de estado durante o resgate';
    END IF;

    RETURN QUERY
    SELECT voucher.id_ad_voucher,
           credited.ledger_entry_id,
           credit_amount::numeric,
           credited.balance_after,
           credited.result_status;
END;
$function$;

ALTER FUNCTION ads.create_voucher(
    text, bigint, text, numeric, date, text, text, integer
) OWNER TO ads_owner;
ALTER FUNCTION ads.create_voucher(
    bigint, text, numeric, date, text, text, integer
) OWNER TO ads_owner;
ALTER FUNCTION ads.reserve_voucher(bigint, bigint, text, integer)
    OWNER TO ads_owner;
ALTER FUNCTION ads.redeem_voucher(bigint, text, integer)
    OWNER TO ads_owner;

GRANT SELECT, UPDATE ON TABLE public.tb_conta_cadastro_solicitacoes TO ads_owner;
GRANT SELECT ON TABLE public.tb_conta_usuarios TO ads_owner;

REVOKE ALL ON FUNCTION ads.create_voucher(
    text, bigint, text, numeric, date, text, text, integer
) FROM PUBLIC, runner, runner_dba, ads_reader, ads_delivery, ads_admin,
    ads_finance, ads_business;
REVOKE ALL ON FUNCTION ads.create_voucher(
    bigint, text, numeric, date, text, text, integer
) FROM PUBLIC, runner, runner_dba, ads_reader, ads_delivery, ads_admin,
    ads_finance, ads_business;
REVOKE ALL ON FUNCTION ads.reserve_voucher(bigint, bigint, text, integer)
FROM PUBLIC, runner, runner_dba, ads_reader, ads_delivery, ads_admin,
    ads_finance, ads_business;
REVOKE ALL ON FUNCTION ads.redeem_voucher(bigint, text, integer)
FROM PUBLIC, runner, runner_dba, ads_reader, ads_delivery, ads_admin,
    ads_finance, ads_business;

GRANT EXECUTE ON FUNCTION ads.create_voucher(
    text, bigint, text, numeric, date, text, text, integer
) TO ads_business;
GRANT EXECUTE ON FUNCTION ads.create_voucher(
    bigint, text, numeric, date, text, text, integer
) TO ads_business;
GRANT EXECUTE ON FUNCTION ads.reserve_voucher(bigint, bigint, text, integer)
TO ads_business;
GRANT EXECUTE ON FUNCTION ads.redeem_voucher(bigint, text, integer)
TO ads_business;

COMMENT ON COLUMN ads.tb_ad_vouchers.voucher_scope IS
    'ACCOUNT restringe o codigo a uma conta; PROMOTIONAL vincula no primeiro uso.';
COMMENT ON FUNCTION ads.create_voucher(
    text, bigint, text, numeric, date, text, text, integer
) IS
    'Cria voucher promocional global ou voucher restrito a uma conta.';

COMMIT;
