ALTER TABLE tb_portal_runner_app_groups
    ADD COLUMN IF NOT EXISTS itens_por_linha SMALLINT NOT NULL DEFAULT 3;

UPDATE tb_portal_runner_app_groups
SET itens_por_linha = 3
WHERE itens_por_linha NOT IN (3, 4, 5) OR itens_por_linha IS NULL;

ALTER TABLE tb_portal_runner_app_groups
    DROP CONSTRAINT IF EXISTS tb_portal_runner_app_groups_itens_por_linha_check;

ALTER TABLE tb_portal_runner_app_groups
    ADD CONSTRAINT tb_portal_runner_app_groups_itens_por_linha_check
    CHECK (itens_por_linha IN (3, 4, 5));
