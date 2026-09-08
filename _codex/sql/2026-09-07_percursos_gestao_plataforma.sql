BEGIN;

-- Diferencia a gestão global explícita dos percursos legados sem proprietário.
ALTER TABLE public.tb_percursos
    ADD COLUMN IF NOT EXISTS gestao_plataforma boolean NOT NULL DEFAULT false;

ALTER TABLE public.tb_percursos
    ALTER COLUMN id_conta_responsavel DROP NOT NULL,
    DROP CONSTRAINT IF EXISTS tb_percursos_conta_proprietaria_nn;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'public.tb_percursos'::regclass
          AND conname = 'tb_percursos_proprietario_chk'
    ) THEN
        ALTER TABLE public.tb_percursos
            ADD CONSTRAINT tb_percursos_proprietario_chk CHECK (
                (gestao_plataforma AND id_conta_responsavel IS NULL)
                OR (NOT gestao_plataforma AND id_conta_responsavel IS NOT NULL)
            ) NOT VALID;
    END IF;
END
$$;

-- NOT VALID preserva os legados pendentes; novos registros e atualizações
-- precisam de conta proprietária ou de gestão explícita da plataforma.
-- Não altera contas, eventos, vínculos, autores nem a propriedade dos legados.
COMMENT ON COLUMN public.tb_percursos.gestao_plataforma IS
    'Gestão explícita da plataforma, atribuída somente por admin global. Não torna o percurso público.';
COMMENT ON COLUMN public.tb_percursos.id_conta_responsavel IS
    'Conta proprietária; nula na gestão da plataforma ou em legados pendentes. Autoria permanece em id_usuario_criador.';

COMMIT;
