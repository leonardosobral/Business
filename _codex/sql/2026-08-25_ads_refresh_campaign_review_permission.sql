-- Corrige a integracao entre as aprovacoes Business e a reavaliacao ADS.
-- O datasource da aplicacao usa ads_business; a funcao continua protegida
-- pela identidade do administrador RunnerHub recebida como ator.

BEGIN;

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

ALTER FUNCTION ads.refresh_campaign_review_prerequisites(
    bigint, integer, integer
) OWNER TO ads_owner;

REVOKE ALL ON FUNCTION ads.refresh_campaign_review_prerequisites(
    bigint, integer, integer
) FROM PUBLIC, runner, runner_dba, ads_reader, ads_delivery, ads_admin,
    ads_finance, ads_business;

GRANT EXECUTE ON FUNCTION ads.refresh_campaign_review_prerequisites(
    bigint, integer, integer
) TO ads_admin;

GRANT EXECUTE ON FUNCTION ads.refresh_campaign_review_prerequisites(
    bigint, integer, integer
) TO ads_business;

INSERT INTO ads.schema_migrations (migration_key, description)
VALUES (
    '2026-08-25_ads_refresh_campaign_review_permission',
    'Permite a integracao Business protegida por ator administrador'
)
ON CONFLICT (migration_key) DO NOTHING;

COMMIT;
