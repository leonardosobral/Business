-- Permite que o datasource da aplicacao invoque a decisao administrativa.
-- A funcao SECURITY DEFINER continua validando p_actor_id como admin/dev RunnerHub.

BEGIN;

DO $block$
BEGIN
    IF to_regprocedure('ads.review_campaign(uuid,text,integer,text,text)') IS NULL THEN
        RAISE EXCEPTION 'Funcao ads.review_campaign nao encontrada';
    END IF;
END;
$block$;

GRANT EXECUTE ON FUNCTION ads.review_campaign(
    uuid,
    text,
    integer,
    text,
    text
) TO ads_business;

INSERT INTO ads.schema_migrations (migration_key, description)
VALUES (
    '2026-09-02_ads_review_campaign_business_permission',
    'Permite ao datasource Business executar revisao protegida por ator administrador'
)
ON CONFLICT (migration_key) DO NOTHING;

COMMIT;
