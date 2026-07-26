-- Garante que os importadores de notícias sempre enviem novos conteúdos
-- para a fila de curadoria, mesmo que o padrão da API seja alterado.
--
-- O gerenciador valida request_body como JSON para jobs application/json.
-- Este script preserva as demais propriedades já configuradas no payload.

BEGIN;

UPDATE public.tb_cron_jobs
SET request_body = (
        COALESCE(NULLIF(btrim(request_body), ''), '{}')::jsonb
        || jsonb_build_object('import_status', 'review')
    )::text,
    data_atualizacao = now()
WHERE endpoint_url IN (
    'https://conteudo.roadrunners.run/api/admin/importers/contrarelogio.cfm',
    'https://conteudo.roadrunners.run/api/admin/importers/corridanoar.cfm',
    'https://conteudo.roadrunners.run/api/admin/importers/cbat.cfm',
    'https://conteudo.roadrunners.run/api/admin/importers/cbat-corrida-de-rua.cfm'
);

COMMIT;
