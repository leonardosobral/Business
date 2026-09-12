-- Reabre campanhas aprovadas ou em analise para edicao.
-- Cancela a revisao anterior atomicamente. Salvar nao reenvia automaticamente.
-- Altera somente a funcao e o registro de migration no schema ads; public e somente leitura.

BEGIN;

CREATE OR REPLACE FUNCTION ads.prepare_campaign_for_edit(
    p_campaign_id uuid,
    p_account_id bigint,
    p_actor_id integer
)
RETURNS TABLE (
    campaign_id uuid,
    campaign_status text,
    review_status text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
#variable_conflict use_column
DECLARE
    campaign ads.campaigns%ROWTYPE;
    review ads.campaign_review_requests%ROWTYPE;
    active_operator boolean;
    actor_is_admin boolean;
    previous_campaign_status text;
    transition_reason text := 'Edicao solicitada pelo Business; nova aprovacao obrigatoria';
BEGIN
    SELECT stored.*
      INTO campaign
      FROM ads.campaigns stored
     WHERE stored.campaign_id = p_campaign_id
       AND stored.account_id = p_account_id
       AND stored.billing_model = 'CPC'
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Campanha nao encontrada nesta conta';
    END IF;

    IF campaign.status NOT IN ('DRAFT', 'ACTIVE', 'PAUSED') THEN
        RAISE EXCEPTION 'Somente campanha em rascunho, ativa ou pausada pode iniciar nova edicao';
    END IF;

    SELECT stored.*
      INTO review
      FROM ads.campaign_review_requests stored
     WHERE stored.campaign_id = campaign.campaign_id
       AND stored.account_id = campaign.account_id
     ORDER BY stored.campaign_review_request_id DESC
     LIMIT 1
     FOR UPDATE;

    IF NOT FOUND OR NOT coalesce(
        (campaign.status IN ('ACTIVE', 'PAUSED') AND review.status = 'APPROVED')
        OR (campaign.status = 'DRAFT' AND review.status IN ('PENDING_REVIEW', 'WAITING_PREREQUISITES')),
        false
    ) THEN
        RAISE EXCEPTION 'Somente campanha aprovada ou em analise pode ser reaberta para edicao';
    END IF;

    SELECT EXISTS (
        SELECT 1
          FROM public.tb_conta_usuarios membership
         WHERE membership.id_conta = campaign.account_id
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

    IF NOT (active_operator OR actor_is_admin) THEN
        RAISE EXCEPTION 'Usuario nao pode editar campanha desta conta';
    END IF;

    previous_campaign_status := campaign.status;
    PERFORM set_config('ads.allow_campaign_status_transition', 'on', true);

    UPDATE ads.campaigns target
       SET status = 'DRAFT',
           updated_by = p_actor_id,
           version = target.version + 1,
           metadata = target.metadata || jsonb_build_object(
               'last_status_reason', transition_reason,
               'requires_new_review', true
           )
     WHERE target.campaign_id = campaign.campaign_id;

    IF previous_campaign_status <> 'DRAFT' THEN
        INSERT INTO ads.campaign_status_history (
            campaign_id,
            account_id,
            from_status,
            to_status,
            reason,
            changed_by,
            metadata
        )
        VALUES (
            campaign.campaign_id,
            campaign.account_id,
            previous_campaign_status,
            'DRAFT',
            transition_reason,
            p_actor_id,
            '{"managed_by":"ads_business","requires_new_review":true}'::jsonb
        );
    END IF;

    PERFORM set_config('ads.allow_campaign_status_transition', 'off', true);

    UPDATE ads.campaign_review_requests target
       SET status = 'CANCELED',
           reviewed_by = p_actor_id,
           reviewed_at = clock_timestamp(),
           updated_at = clock_timestamp(),
           review_reason = transition_reason
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
        transition_reason
    );

    RETURN QUERY
    SELECT campaign.campaign_id,
           'DRAFT'::text,
           'CANCELED'::text;
END;
$function$;

ALTER FUNCTION ads.prepare_campaign_for_edit(uuid, bigint, integer)
    OWNER TO ads_owner;

REVOKE ALL ON FUNCTION
    ads.prepare_campaign_for_edit(uuid, bigint, integer)
FROM PUBLIC, runner, runner_dba, ads_reader, ads_delivery, ads_admin,
    ads_finance, ads_business;

GRANT EXECUTE ON FUNCTION
    ads.prepare_campaign_for_edit(uuid, bigint, integer)
TO ads_business;

INSERT INTO ads.schema_migrations (migration_key, description)
VALUES (
    '2026-09-11_ads_prepare_pending_campaign_edit',
    'Retira campanha em analise ou aprovada para edicao, com nova revisao explicita'
)
ON CONFLICT (migration_key) DO NOTHING;

COMMIT;
