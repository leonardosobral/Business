-- Permite eliminar campanhas de teste ja finalizadas, desde que continuem
-- sem qualquer entrega, metrica, pagamento, credito ou saldo consumido.
-- Mantem a revisao manual obrigatoria para campanhas ativas ou pausadas.

BEGIN;

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

COMMIT;
