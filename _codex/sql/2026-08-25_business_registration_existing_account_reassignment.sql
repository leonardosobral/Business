-- Ao aprovar uma solicitacao criada com workspace provisorio, permite ao
-- administrador escolher uma conta ativa existente sem perder evento,
-- voucher ou publicidade preparados durante a analise.

BEGIN;

CREATE OR REPLACE FUNCTION ads.reassign_pending_account_data(
    p_source_account_id bigint,
    p_target_account_id bigint,
    p_registration_id bigint,
    p_actor_id integer
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
    actor public.tb_usuarios%ROWTYPE;
    source_account public.tb_contas%ROWTYPE;
    target_account public.tb_contas%ROWTYPE;
    campaign_count integer := 0;
    review_count integer := 0;
    voucher_count integer := 0;
BEGIN
    IF p_source_account_id IS NULL OR p_source_account_id <= 0
       OR p_target_account_id IS NULL OR p_target_account_id <= 0
       OR p_source_account_id = p_target_account_id
       OR p_registration_id IS NULL OR p_registration_id <= 0
       OR p_actor_id IS NULL OR p_actor_id <= 0 THEN
        RAISE EXCEPTION 'Contexto invalido para transferir a conta provisoria';
    END IF;

    SELECT user_record.*
      INTO actor
      FROM public.tb_usuarios user_record
     WHERE user_record.id = p_actor_id;

    IF NOT FOUND OR actor.is_admin IS NOT TRUE THEN
        RAISE EXCEPTION 'Somente administrador RunnerHub pode transferir uma conta provisoria';
    END IF;

    SELECT account_info.*
      INTO source_account
      FROM public.tb_contas account_info
     WHERE account_info.id_conta = p_source_account_id;

    SELECT account_info.*
      INTO target_account
      FROM public.tb_contas account_info
     WHERE account_info.id_conta = p_target_account_id;

    IF source_account.id_conta IS NULL
       OR source_account.status::text <> 'PENDENTE' THEN
        RAISE EXCEPTION 'A conta de origem precisa ser provisoria e pendente';
    END IF;

    IF target_account.id_conta IS NULL
       OR target_account.status::text <> 'ATIVA' THEN
        RAISE EXCEPTION 'A conta de destino precisa estar ativa';
    END IF;

    IF EXISTS (
        SELECT 1 FROM ads.payment_intents payment
         WHERE payment.account_id = p_source_account_id
    ) OR EXISTS (
        SELECT 1 FROM ads.credit_ledger ledger
         WHERE ledger.account_id = p_source_account_id
    ) OR EXISTS (
        SELECT 1 FROM ads.account_financial_holds financial_hold
         WHERE financial_hold.account_id = p_source_account_id
    ) THEN
        RAISE EXCEPTION 'A conta provisoria possui movimentacao financeira e exige revisao manual';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM ads.account_balances balance
         WHERE balance.account_id = p_source_account_id
           AND coalesce(balance.available_balance, 0) <> 0
    ) THEN
        RAISE EXCEPTION 'A conta provisoria possui saldo aplicado e exige revisao manual';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM ads.deliveries delivery
         WHERE delivery.account_id = p_source_account_id
    ) OR EXISTS (
        SELECT 1
          FROM ads.daily_metrics metric
         WHERE metric.account_id = p_source_account_id
    ) OR EXISTS (
        SELECT 1
          FROM ads.campaigns campaign
         WHERE campaign.account_id = p_source_account_id
           AND campaign.status <> 'DRAFT'
    ) THEN
        RAISE EXCEPTION 'A conta provisoria possui publicidade efetivada e exige revisao manual';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM ads.voucher_reservations reservation
          JOIN ads.tb_ad_vouchers voucher
            ON voucher.id_ad_voucher = reservation.id_ad_voucher
         WHERE (reservation.id_conta = p_source_account_id
             OR reservation.id_solicitacao_cadastro = p_registration_id)
           AND (
               reservation.status <> 'RESERVED'
               OR voucher.status <> 1
               OR voucher.id_usuario_resgate IS NOT NULL
               OR voucher.data_resgate IS NOT NULL
           )
    ) OR EXISTS (
        SELECT 1
          FROM ads.tb_ad_vouchers voucher
         WHERE voucher.id_conta = p_source_account_id
           AND (
               voucher.status <> 1
               OR voucher.id_usuario_resgate IS NOT NULL
               OR voucher.data_resgate IS NOT NULL
           )
    ) THEN
        RAISE EXCEPTION 'A conta provisoria possui voucher efetivado e exige revisao manual';
    END IF;

    SELECT count(*)::integer
      INTO campaign_count
      FROM ads.campaigns campaign
     WHERE campaign.account_id = p_source_account_id;

    SELECT count(*)::integer
      INTO review_count
      FROM ads.campaign_review_requests review
     WHERE review.account_id = p_source_account_id;

    SELECT count(*)::integer
      INTO voucher_count
      FROM ads.voucher_reservations reservation
     WHERE reservation.id_conta = p_source_account_id
        OR reservation.id_solicitacao_cadastro = p_registration_id;

    UPDATE ads.tb_ad_vouchers voucher
       SET id_conta = p_target_account_id,
           data_atualizacao = clock_timestamp() AT TIME ZONE 'America/Sao_Paulo'
     WHERE voucher.id_conta = p_source_account_id
       AND voucher.status = 1
       AND voucher.id_usuario_resgate IS NULL
       AND voucher.data_resgate IS NULL;

    UPDATE ads.voucher_reservations reservation
       SET id_conta = p_target_account_id,
           updated_at = clock_timestamp(),
           transition_reason = 'Conta provisoria associada a conta existente'
     WHERE (reservation.id_conta = p_source_account_id
         OR reservation.id_solicitacao_cadastro = p_registration_id)
       AND reservation.status = 'RESERVED';

    DELETE FROM ads.account_balances balance
     WHERE balance.account_id = p_source_account_id
       AND balance.available_balance = 0;

    UPDATE ads.campaign_review_requests review
       SET account_id = p_target_account_id,
           updated_at = clock_timestamp(),
           review_reason = concat_ws(
               ' | ',
               nullif(review.review_reason, ''),
               'Conta provisoria associada a conta existente'
           )
     WHERE review.account_id = p_source_account_id;

    -- As FKs compostas da Ads V1 usam ON UPDATE CASCADE. Alterar a campanha
    -- transfere anuncios, criativos, placements, budget e historico juntos.
    UPDATE ads.campaigns campaign
       SET account_id = p_target_account_id,
           updated_by = p_actor_id,
           updated_at = clock_timestamp(),
           metadata = campaign.metadata || pg_catalog.jsonb_build_object(
               'reassigned_from_account_id', p_source_account_id,
               'reassigned_registration_id', p_registration_id
           )
     WHERE campaign.account_id = p_source_account_id;

    RETURN pg_catalog.jsonb_build_object(
        'campaigns', campaign_count,
        'campaign_reviews', review_count,
        'voucher_reservations', voucher_count
    );
END;
$function$;

ALTER FUNCTION ads.reassign_pending_account_data(
    bigint, bigint, bigint, integer
) OWNER TO ads_owner;
REVOKE ALL ON FUNCTION ads.reassign_pending_account_data(
    bigint, bigint, bigint, integer
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION ads.reassign_pending_account_data(
    bigint, bigint, bigint, integer
) TO runner_dba;

CREATE OR REPLACE FUNCTION public.reassign_business_pending_registration(
    p_registration_id bigint,
    p_target_account_id bigint,
    p_actor_id integer
)
RETURNS TABLE (
    source_account_id bigint,
    target_account_id bigint,
    subject_user_id bigint,
    moved_counts jsonb
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
    actor public.tb_usuarios%ROWTYPE;
    registration public.tb_conta_cadastro_solicitacoes%ROWTYPE;
    source_account public.tb_contas%ROWTYPE;
    target_account public.tb_contas%ROWTYPE;
    registration_count integer := 0;
    membership_count integer := 0;
    event_request_count integer := 0;
    event_link_count integer := 0;
    ads_counts jsonb := '{}'::jsonb;
    all_counts jsonb := '{}'::jsonb;
BEGIN
    IF p_registration_id IS NULL OR p_registration_id <= 0
       OR p_target_account_id IS NULL OR p_target_account_id <= 0
       OR p_actor_id IS NULL OR p_actor_id <= 0 THEN
        RAISE EXCEPTION 'Contexto invalido para associar a conta existente';
    END IF;

    SELECT user_record.*
      INTO actor
      FROM public.tb_usuarios user_record
     WHERE user_record.id = p_actor_id;

    IF NOT FOUND OR actor.is_admin IS NOT TRUE THEN
        RAISE EXCEPTION 'Somente administrador RunnerHub pode associar a conta existente';
    END IF;

    SELECT request.*
      INTO registration
      FROM public.tb_conta_cadastro_solicitacoes request
     WHERE request.id_solicitacao = p_registration_id
     FOR UPDATE;

    IF NOT FOUND OR registration.status::text <> 'PENDENTE'
       OR registration.id_conta IS NULL THEN
        RAISE EXCEPTION 'Solicitacao pendente com conta provisoria nao encontrada';
    END IF;

    IF registration.id_conta = p_target_account_id THEN
        RAISE EXCEPTION 'Selecione uma conta ativa diferente da conta provisoria';
    END IF;

    SELECT account_info.*
      INTO source_account
      FROM public.tb_contas account_info
     WHERE account_info.id_conta = registration.id_conta
     FOR UPDATE;

    SELECT account_info.*
      INTO target_account
      FROM public.tb_contas account_info
     WHERE account_info.id_conta = p_target_account_id
     FOR UPDATE;

    IF source_account.id_conta IS NULL
       OR source_account.status::text <> 'PENDENTE' THEN
        RAISE EXCEPTION 'A conta de origem precisa ser provisoria e pendente';
    END IF;

    IF target_account.id_conta IS NULL
       OR target_account.status::text <> 'ATIVA' THEN
        RAISE EXCEPTION 'A conta escolhida precisa estar ativa';
    END IF;

    SELECT count(*)::integer
      INTO registration_count
      FROM public.tb_conta_cadastro_solicitacoes request
     WHERE request.id_conta = source_account.id_conta;

    IF registration_count <> 1 THEN
        RAISE EXCEPTION 'A conta provisoria possui outras solicitacoes e exige revisao manual';
    END IF;

    SELECT count(*)::integer
      INTO membership_count
      FROM public.tb_conta_usuarios membership
     WHERE membership.id_conta = source_account.id_conta;

    IF membership_count <> 1 OR NOT EXISTS (
        SELECT 1
          FROM public.tb_conta_usuarios membership
         WHERE membership.id_conta = source_account.id_conta
           AND membership.id_usuario = registration.id_usuario
           AND membership.papel::text = 'OWNER'
           AND membership.status::text = 'ATIVO'
    ) THEN
        RAISE EXCEPTION 'A conta provisoria possui usuarios inesperados e exige revisao manual';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.tb_percursos route
         WHERE route.id_conta_responsavel = source_account.id_conta
    ) THEN
        RAISE EXCEPTION 'A conta provisoria possui percursos proprios e exige revisao manual';
    END IF;

    ads_counts := ads.reassign_pending_account_data(
        source_account.id_conta,
        target_account.id_conta,
        registration.id_solicitacao,
        p_actor_id
    );

    INSERT INTO public.tb_conta_eventos (
        id_conta,
        id_evento,
        status,
        usuario_cadastro,
        data_criacao,
        data_atualizacao
    )
    SELECT target_account.id_conta,
           event_link.id_evento,
           event_link.status,
           event_link.usuario_cadastro,
           event_link.data_criacao,
           clock_timestamp()
      FROM public.tb_conta_eventos event_link
     WHERE event_link.id_conta = source_account.id_conta
    ON CONFLICT (id_conta, id_evento) DO NOTHING;
    GET DIAGNOSTICS event_link_count = ROW_COUNT;

    DELETE FROM public.tb_conta_eventos event_link
     WHERE event_link.id_conta = source_account.id_conta;

    UPDATE public.tb_conta_evento_solicitacoes event_request
       SET id_conta = p_target_account_id
     WHERE event_request.id_conta = source_account.id_conta;
    GET DIAGNOSTICS event_request_count = ROW_COUNT;

    UPDATE public.tb_conta_cadastro_solicitacoes request
       SET id_conta = p_target_account_id
     WHERE request.id_solicitacao = registration.id_solicitacao;

    DELETE FROM public.tb_conta_usuarios membership
     WHERE membership.id_conta = source_account.id_conta;

    DELETE FROM public.tb_contas account_info
     WHERE account_info.id_conta = source_account.id_conta;

    all_counts := ads_counts || pg_catalog.jsonb_build_object(
        'event_requests', event_request_count,
        'event_links', event_link_count,
        'memberships', membership_count,
        'accounts', 1
    );

    RETURN QUERY
    SELECT source_account.id_conta,
           target_account.id_conta,
           registration.id_usuario,
           all_counts;
END;
$function$;

ALTER FUNCTION public.reassign_business_pending_registration(
    bigint, bigint, integer
) OWNER TO runner_dba;
REVOKE ALL ON FUNCTION public.reassign_business_pending_registration(
    bigint, bigint, integer
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.reassign_business_pending_registration(
    bigint, bigint, integer
) TO runner;

INSERT INTO ads.schema_migrations (migration_key, description)
VALUES (
    '2026-08-25_business_registration_existing_account_reassignment',
    'Aprovacao pode transferir workspace provisorio para conta ativa escolhida'
)
ON CONFLICT (migration_key) DO UPDATE
SET description = EXCLUDED.description,
    applied_at = clock_timestamp();

COMMIT;
