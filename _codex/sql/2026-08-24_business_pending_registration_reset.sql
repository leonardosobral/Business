-- Reset seguro de uma solicitacao Business de teste ainda pendente.
-- Preserva public.tb_usuarios e recusa contas com qualquer evidencia financeira
-- ou de entrega de publicidade.

BEGIN;

CREATE TABLE IF NOT EXISTS public.tb_business_pending_reset_audits (
    id_reset_audit bigserial PRIMARY KEY,
    id_solicitacao bigint NOT NULL,
    id_conta bigint NOT NULL,
    id_usuario_solicitante bigint,
    email_solicitante varchar(255) NOT NULL,
    nome_conta varchar(160) NOT NULL,
    id_usuario_admin bigint
        REFERENCES public.tb_usuarios(id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    motivo text NOT NULL,
    contagens jsonb NOT NULL DEFAULT '{}'::jsonb,
    dados_solicitacao jsonb NOT NULL DEFAULT '{}'::jsonb,
    data_eliminacao timestamp with time zone NOT NULL DEFAULT clock_timestamp()
);

ALTER TABLE public.tb_business_pending_reset_audits OWNER TO runner_dba;

CREATE INDEX IF NOT EXISTS idx_business_pending_reset_audits_subject
    ON public.tb_business_pending_reset_audits
    (id_usuario_solicitante, data_eliminacao DESC);

CREATE INDEX IF NOT EXISTS idx_business_pending_reset_audits_admin
    ON public.tb_business_pending_reset_audits
    (id_usuario_admin, data_eliminacao DESC);

REVOKE ALL ON TABLE public.tb_business_pending_reset_audits FROM PUBLIC;
REVOKE ALL ON SEQUENCE public.tb_business_pending_reset_audits_id_reset_audit_seq
    FROM PUBLIC;
GRANT SELECT ON TABLE public.tb_business_pending_reset_audits TO runner;

-- A tabela legada de vouchers pertence a runner_dba. O helper ADS precisa
-- apenas remover vouchers ACCOUNT intactos da conta provisoria eliminada.
GRANT DELETE ON TABLE ads.tb_ad_vouchers TO ads_owner;

CREATE OR REPLACE FUNCTION ads.purge_pending_account_data(
    p_account_id bigint,
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
    account_record public.tb_contas%ROWTYPE;
    campaign_count integer := 0;
    advertisement_count integer := 0;
    creative_count integer := 0;
    review_count integer := 0;
    voucher_count integer := 0;
    deleted_count integer := 0;
BEGIN
    SELECT user_record.*
      INTO actor
      FROM public.tb_usuarios user_record
     WHERE user_record.id = p_actor_id;

    IF NOT FOUND OR actor.is_admin IS NOT TRUE THEN
        RAISE EXCEPTION 'Somente administrador RunnerHub pode eliminar dados de teste';
    END IF;

    SELECT account_info.*
      INTO account_record
      FROM public.tb_contas account_info
     WHERE account_info.id_conta = p_account_id;

    IF NOT FOUND OR account_record.status::text <> 'PENDENTE' THEN
        RAISE EXCEPTION 'A limpeza ADS exige uma conta provisória pendente';
    END IF;

    IF EXISTS (
        SELECT 1 FROM ads.payment_intents payment
         WHERE payment.account_id = p_account_id
    ) OR EXISTS (
        SELECT 1 FROM ads.credit_ledger ledger
         WHERE ledger.account_id = p_account_id
    ) OR EXISTS (
        SELECT 1 FROM ads.account_financial_holds financial_hold
         WHERE financial_hold.account_id = p_account_id
    ) THEN
        RAISE EXCEPTION 'A conta possui pagamento, crédito ou bloqueio financeiro e exige revisão manual';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM ads.account_balances balance
         WHERE balance.account_id = p_account_id
           AND coalesce(balance.available_balance, 0) <> 0
    ) THEN
        RAISE EXCEPTION 'A conta possui saldo de publicidade e exige revisão manual';
    END IF;

    -- ads.events nasce de ads.deliveries. Impedir qualquer delivery preserva
    -- tanto os eventos de entrega quanto seus payloads e evidencias.
    IF EXISTS (
        SELECT 1
          FROM ads.deliveries delivery
          JOIN ads.campaigns campaign
            ON campaign.campaign_id = delivery.campaign_id
         WHERE campaign.account_id = p_account_id
    ) OR EXISTS (
        SELECT 1
          FROM ads.daily_metrics metric
         WHERE metric.account_id = p_account_id
    ) THEN
        RAISE EXCEPTION 'A conta possui entregas ou métricas e exige revisão manual';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM ads.campaigns campaign
         WHERE campaign.account_id = p_account_id
           AND campaign.status NOT IN ('DRAFT', 'ENDED')
    ) THEN
        RAISE EXCEPTION 'A conta possui campanha ativa ou pausada e exige revisão manual';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM ads.voucher_reservations reservation
          JOIN ads.tb_ad_vouchers voucher
            ON voucher.id_ad_voucher = reservation.id_ad_voucher
         WHERE (reservation.id_conta = p_account_id
             OR reservation.id_solicitacao_cadastro = p_registration_id)
           AND (
               reservation.status <> 'RESERVED'
               OR voucher.status <> 1
               OR voucher.id_usuario_resgate IS NOT NULL
               OR voucher.data_resgate IS NOT NULL
           )
    ) THEN
        RAISE EXCEPTION 'A conta possui voucher aplicado ou resgatado e exige revisão manual';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM ads.tb_ad_vouchers voucher
         WHERE voucher.id_conta = p_account_id
           AND voucher.voucher_scope = 'ACCOUNT'
           AND (
               voucher.status <> 1
               OR voucher.id_usuario_resgate IS NOT NULL
               OR voucher.data_resgate IS NOT NULL
           )
    ) THEN
        RAISE EXCEPTION 'A conta possui voucher restrito já utilizado e exige revisão manual';
    END IF;

    SELECT count(*)::integer
      INTO campaign_count
      FROM ads.campaigns campaign
     WHERE campaign.account_id = p_account_id;

    SELECT count(*)::integer
      INTO advertisement_count
      FROM ads.advertisements advertisement
     WHERE advertisement.account_id = p_account_id;

    SELECT count(*)::integer
      INTO creative_count
      FROM ads.creatives creative
     WHERE creative.account_id = p_account_id;

    SELECT count(*)::integer
      INTO review_count
      FROM ads.campaign_review_requests review
     WHERE review.account_id = p_account_id;

    SELECT count(*)::integer
      INTO voucher_count
      FROM ads.voucher_reservations reservation
     WHERE reservation.id_conta = p_account_id
        OR reservation.id_solicitacao_cadastro = p_registration_id;

    DELETE FROM ads.campaign_review_history history
     WHERE history.campaign_review_request_id IN (
         SELECT review.campaign_review_request_id
           FROM ads.campaign_review_requests review
          WHERE review.account_id = p_account_id
     );

    DELETE FROM ads.campaign_review_requests review
     WHERE review.account_id = p_account_id;

    DELETE FROM ads.daily_metrics metric
     WHERE metric.account_id = p_account_id;

    DELETE FROM ads.campaign_status_history history
     WHERE history.account_id = p_account_id;

    DELETE FROM ads.campaign_budget_state budget
     WHERE budget.account_id = p_account_id;

    DELETE FROM ads.campaign_placements placement
     WHERE placement.account_id = p_account_id;

    DELETE FROM ads.creatives creative
     WHERE creative.account_id = p_account_id;

    DELETE FROM ads.advertisements advertisement
     WHERE advertisement.account_id = p_account_id;

    DELETE FROM ads.campaigns campaign
     WHERE campaign.account_id = p_account_id;

    DELETE FROM ads.account_balances balance
     WHERE balance.account_id = p_account_id;

    UPDATE ads.tb_ad_vouchers voucher
       SET id_conta = reservation.original_account_id,
           data_atualizacao = clock_timestamp() AT TIME ZONE 'America/Sao_Paulo'
      FROM ads.voucher_reservations reservation
     WHERE voucher.id_ad_voucher = reservation.id_ad_voucher
       AND (reservation.id_conta = p_account_id
         OR reservation.id_solicitacao_cadastro = p_registration_id)
       AND voucher.voucher_scope = 'PROMOTIONAL'
       AND voucher.status = 1
       AND voucher.id_usuario_resgate IS NULL
       AND voucher.data_resgate IS NULL;

    UPDATE public.tb_conta_cadastro_solicitacoes registration
       SET id_ad_voucher = NULL,
           voucher_codigo = NULL
     WHERE registration.id_solicitacao = p_registration_id;

    DELETE FROM ads.voucher_reservations reservation
     WHERE reservation.id_conta = p_account_id
        OR reservation.id_solicitacao_cadastro = p_registration_id;

    DELETE FROM ads.tb_ad_vouchers voucher
     WHERE voucher.id_conta = p_account_id
       AND voucher.voucher_scope = 'ACCOUNT'
       AND voucher.status = 1
       AND voucher.id_usuario_resgate IS NULL
       AND voucher.data_resgate IS NULL;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    voucher_count := voucher_count + deleted_count;

    RETURN pg_catalog.jsonb_build_object(
        'campaigns', campaign_count,
        'advertisements', advertisement_count,
        'creatives', creative_count,
        'campaign_reviews', review_count,
        'vouchers', voucher_count
    );
END;
$function$;

ALTER FUNCTION ads.purge_pending_account_data(bigint, bigint, integer)
    OWNER TO ads_owner;
REVOKE ALL ON FUNCTION ads.purge_pending_account_data(bigint, bigint, integer)
    FROM PUBLIC;
GRANT EXECUTE ON FUNCTION ads.purge_pending_account_data(bigint, bigint, integer)
    TO runner_dba;

CREATE OR REPLACE FUNCTION public.reset_business_pending_registration(
    p_registration_id bigint,
    p_actor_id integer,
    p_expected_email text,
    p_reason text
)
RETURNS TABLE (
    reset_audit_id bigint,
    account_id bigint,
    subject_user_id bigint,
    deleted_counts jsonb
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
    actor public.tb_usuarios%ROWTYPE;
    registration public.tb_conta_cadastro_solicitacoes%ROWTYPE;
    account_record public.tb_contas%ROWTYPE;
    account_membership_count integer := 0;
    account_registration_count integer := 0;
    event_request_count integer := 0;
    event_link_count integer := 0;
    membership_count integer := 0;
    ads_counts jsonb := '{}'::jsonb;
    all_counts jsonb := '{}'::jsonb;
    stored_audit_id bigint;
BEGIN
    IF p_registration_id IS NULL OR p_registration_id <= 0
       OR p_actor_id IS NULL OR p_actor_id <= 0 THEN
        RAISE EXCEPTION 'Contexto inválido para eliminar dados de teste';
    END IF;

    IF p_reason IS NULL OR length(btrim(p_reason)) < 5 THEN
        RAISE EXCEPTION 'Informe um motivo com pelo menos 5 caracteres';
    END IF;

    SELECT user_record.*
      INTO actor
      FROM public.tb_usuarios user_record
     WHERE user_record.id = p_actor_id;

    IF NOT FOUND OR actor.is_admin IS NOT TRUE THEN
        RAISE EXCEPTION 'Somente administrador RunnerHub pode eliminar dados de teste';
    END IF;

    SELECT request.*
      INTO registration
      FROM public.tb_conta_cadastro_solicitacoes request
     WHERE request.id_solicitacao = p_registration_id
     FOR UPDATE;

    IF NOT FOUND OR registration.status::text <> 'PENDENTE' THEN
        RAISE EXCEPTION 'Somente solicitação pendente pode ser eliminada';
    END IF;

    IF registration.id_conta IS NULL THEN
        RAISE EXCEPTION 'A solicitação não possui conta provisória';
    END IF;

    IF p_expected_email IS NULL
       OR lower(btrim(p_expected_email)) IS DISTINCT FROM
          lower(btrim(registration.email_responsavel)) THEN
        RAISE EXCEPTION 'O e-mail de confirmação não corresponde ao solicitante';
    END IF;

    SELECT account_info.*
      INTO account_record
      FROM public.tb_contas account_info
     WHERE account_info.id_conta = registration.id_conta
     FOR UPDATE;

    IF NOT FOUND OR account_record.status::text <> 'PENDENTE' THEN
        RAISE EXCEPTION 'Somente conta provisória pendente pode ser eliminada';
    END IF;

    SELECT count(*)::integer
      INTO account_registration_count
      FROM public.tb_conta_cadastro_solicitacoes request
     WHERE request.id_conta = account_record.id_conta;

    IF account_registration_count <> 1 THEN
        RAISE EXCEPTION 'A conta possui outras solicitações e exige revisão manual';
    END IF;

    SELECT count(*)::integer
      INTO account_membership_count
      FROM public.tb_conta_usuarios membership
     WHERE membership.id_conta = account_record.id_conta;

    IF account_membership_count <> 1 OR NOT EXISTS (
        SELECT 1
          FROM public.tb_conta_usuarios membership
         WHERE membership.id_conta = account_record.id_conta
           AND membership.id_usuario = registration.id_usuario
           AND membership.papel::text = 'OWNER'
    ) THEN
        RAISE EXCEPTION 'A conta possui outros usuários ou vínculo inesperado e exige revisão manual';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.tb_percursos route
         WHERE route.id_conta_responsavel = account_record.id_conta
    ) THEN
        RAISE EXCEPTION 'A conta possui percursos próprios e exige revisão manual';
    END IF;

    ads_counts := ads.purge_pending_account_data(
        account_record.id_conta,
        registration.id_solicitacao,
        p_actor_id
    );

    DELETE FROM public.tb_conta_evento_solicitacoes event_request
     WHERE event_request.id_conta = account_record.id_conta;
    GET DIAGNOSTICS event_request_count = ROW_COUNT;

    DELETE FROM public.tb_conta_eventos event_link
     WHERE event_link.id_conta = account_record.id_conta;
    GET DIAGNOSTICS event_link_count = ROW_COUNT;

    DELETE FROM public.tb_conta_cadastro_solicitacoes request
     WHERE request.id_solicitacao = registration.id_solicitacao;

    DELETE FROM public.tb_conta_usuarios membership
     WHERE membership.id_conta = account_record.id_conta;
    GET DIAGNOSTICS membership_count = ROW_COUNT;

    DELETE FROM public.tb_contas account_info
     WHERE account_info.id_conta = account_record.id_conta;

    all_counts := ads_counts || pg_catalog.jsonb_build_object(
        'event_requests', event_request_count,
        'event_links', event_link_count,
        'registrations', 1,
        'memberships', membership_count,
        'accounts', 1
    );

    INSERT INTO public.tb_business_pending_reset_audits (
        id_solicitacao,
        id_conta,
        id_usuario_solicitante,
        email_solicitante,
        nome_conta,
        id_usuario_admin,
        motivo,
        contagens,
        dados_solicitacao
    )
    VALUES (
        registration.id_solicitacao,
        account_record.id_conta,
        registration.id_usuario,
        lower(btrim(registration.email_responsavel)),
        account_record.nome_conta,
        p_actor_id,
        btrim(p_reason),
        all_counts,
        pg_catalog.jsonb_build_object(
            'nome_empresa', registration.nome_empresa,
            'documento', registration.documento,
            'nome_responsavel', registration.nome_responsavel,
            'tipo_prestador', registration.tipo_prestador
        )
    )
    RETURNING id_reset_audit INTO stored_audit_id;

    RETURN QUERY
    SELECT stored_audit_id,
           account_record.id_conta,
           registration.id_usuario,
           all_counts;
END;
$function$;

ALTER FUNCTION public.reset_business_pending_registration(
    bigint, integer, text, text
) OWNER TO runner_dba;
REVOKE ALL ON FUNCTION public.reset_business_pending_registration(
    bigint, integer, text, text
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.reset_business_pending_registration(
    bigint, integer, text, text
) TO runner;

COMMIT;
