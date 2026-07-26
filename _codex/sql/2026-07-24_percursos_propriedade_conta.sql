BEGIN;

ALTER TABLE public.tb_percursos
    ADD COLUMN IF NOT EXISTS id_conta_responsavel bigint;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'public.tb_percursos'::regclass
          AND contype = 'f'
          AND pg_get_constraintdef(oid) LIKE 'FOREIGN KEY (id_conta_responsavel)%'
    ) THEN
        ALTER TABLE public.tb_percursos
            ADD CONSTRAINT fk_tb_percursos_conta_responsavel
            FOREIGN KEY (id_conta_responsavel)
            REFERENCES public.tb_contas(id_conta)
            ON UPDATE CASCADE
            ON DELETE RESTRICT;
    END IF;
END
$$;

-- Percursos antigos são atribuídos automaticamente somente quando todos os
-- eventos vinculados apontam para uma única conta ativa.
WITH contas_por_percurso AS (
    SELECT vinculo.id_percurso,
           min(conta_evento.id_conta) AS id_conta,
           count(DISTINCT conta_evento.id_conta) AS total_contas
    FROM public.tb_evento_percursos_gpx vinculo
    INNER JOIN public.tb_conta_eventos conta_evento
        ON conta_evento.id_evento = vinculo.id_evento
       AND conta_evento.status = 'ATIVO'::status_conta_evento
    INNER JOIN public.tb_contas conta
        ON conta.id_conta = conta_evento.id_conta
       AND conta.status = 'ATIVA'::status_conta
    GROUP BY vinculo.id_percurso
)
UPDATE public.tb_percursos percurso
SET id_conta_responsavel = candidato.id_conta,
    atualizado_em = now()
FROM contas_por_percurso candidato
WHERE percurso.id_percurso = candidato.id_percurso
  AND percurso.id_conta_responsavel IS NULL
  AND candidato.total_contas = 1;

CREATE INDEX IF NOT EXISTS tb_percursos_conta_idx
    ON public.tb_percursos (id_conta_responsavel, atualizado_em DESC);

-- Mantém os casos antigos ambíguos disponíveis para atribuição manual, mas
-- impede que novos registros ou atualizações permaneçam sem conta.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'tb_percursos_conta_proprietaria_nn'
          AND conrelid = 'public.tb_percursos'::regclass
    ) THEN
        ALTER TABLE public.tb_percursos
            ADD CONSTRAINT tb_percursos_conta_proprietaria_nn
            CHECK (id_conta_responsavel IS NOT NULL)
            NOT VALID;
    END IF;
END
$$;

COMMENT ON COLUMN public.tb_percursos.id_conta_responsavel IS
    'Conta proprietária do percurso. id_usuario_criador registra somente a autoria original.';

GRANT SELECT, INSERT, UPDATE ON public.tb_percursos TO runner;

COMMIT;

-- Estes registros precisam de atribuição manual pelo ADMIN antes de serem editados.
SELECT id_percurso, nome, id_usuario_criador, criado_em
FROM public.tb_percursos
WHERE id_conta_responsavel IS NULL
ORDER BY criado_em, id_percurso;
