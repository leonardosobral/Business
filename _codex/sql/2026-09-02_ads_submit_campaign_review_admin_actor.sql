-- Permite que um admin/dev RunnerHub envie para analise uma campanha da
-- conta ativa que esta personificando. O ator real continua registrado
-- em requested_by e no historico da revisao.

BEGIN;

DO $block$
BEGIN
    IF to_regprocedure('ads.submit_campaign_review(uuid,bigint,integer,integer)') IS NULL THEN
        RAISE EXCEPTION 'Funcao ads.submit_campaign_review nao encontrada';
    END IF;
END;
$block$;

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
    actor_is_admin boolean;
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

    SELECT EXISTS (
        SELECT 1
          FROM public.tb_usuarios actor
         WHERE actor.id = p_actor_id
           AND (
               coalesce(actor.is_admin, false)
               OR coalesce(actor.is_dev, false)
           )
    ) INTO actor_is_admin;

    IF NOT (
        (
            coalesce(account_active, false)
            AND (active_operator OR actor_is_admin)
        )
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

ALTER FUNCTION ads.submit_campaign_review(uuid, bigint, integer, integer)
    OWNER TO ads_owner;

REVOKE ALL ON FUNCTION
    ads.submit_campaign_review(uuid, bigint, integer, integer)
FROM PUBLIC, runner, runner_dba, ads_reader, ads_delivery, ads_admin,
    ads_finance, ads_business;

GRANT EXECUTE ON FUNCTION
    ads.submit_campaign_review(uuid, bigint, integer, integer)
TO ads_business;

INSERT INTO ads.schema_migrations (migration_key, description)
VALUES (
    '2026-09-02_ads_submit_campaign_review_admin_actor',
    'Permite que admin real envie campanha da conta ativa personificada para analise'
)
ON CONFLICT (migration_key) DO NOTHING;

COMMIT;
