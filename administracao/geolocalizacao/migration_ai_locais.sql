-- Business: locais independentes da prova e da retirada de kit.
-- Executar na conexão administrativa já utilizada para o schema deste módulo.
-- Aditiva: não remove dados, não altera grants nem configurações do datasource.
BEGIN;
SET LOCAL ROLE runner_dba;
ALTER TABLE public.tb_evento_corridas
    ADD COLUMN IF NOT EXISTS localizacoes jsonb NOT NULL DEFAULT '{}'::jsonb;
COMMENT ON COLUMN public.tb_evento_corridas.localizacoes IS
    'Locais confirmados da prova e do kit, separados por finalidade, com cidade/UF, endereço, nome, coordenadas e proveniência. Aproximações permanecem nas propostas privadas.';
COMMIT;
