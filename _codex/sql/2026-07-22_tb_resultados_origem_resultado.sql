BEGIN;

ALTER TABLE public.tb_resultados
    ADD COLUMN IF NOT EXISTS origem_resultado varchar(30) DEFAULT 'oficial' NOT NULL;

ALTER TABLE public.tb_resultados
    ALTER COLUMN origem_resultado SET DEFAULT 'oficial';

UPDATE public.tb_resultados
SET origem_resultado = 'oficial'
WHERE origem_resultado IS NULL OR btrim(origem_resultado) = '';

ALTER TABLE public.tb_resultados
    ALTER COLUMN origem_resultado SET NOT NULL;

COMMENT ON COLUMN public.tb_resultados.origem_resultado IS
    'Origem do registro. oficial para resultados importados/publicaveis; validacao_documental para participacoes reconhecidas manualmente.';

-- Identifica com seguranca eventuais resultados ja criados pelo fluxo documental,
-- usando o id_resultado persistido na propria solicitacao aprovada.
WITH resultados_documentais AS (
    SELECT DISTINCT (item ->> 'id_resultado')::integer AS id_resultado
    FROM public.desafios des
    CROSS JOIN LATERAL jsonb_array_elements(
        CASE
            WHEN jsonb_typeof(des.body -> 'validacoes_documentais') = 'array'
                THEN des.body -> 'validacoes_documentais'
            ELSE '[]'::jsonb
        END
    ) AS item
    WHERE des.produto = 'circuitobrasilgigante'
      AND coalesce(item ->> 'id_resultado', '') ~ '^[0-9]+$'
)
UPDATE public.tb_resultados res
SET origem_resultado = 'validacao_documental'
FROM resultados_documentais doc
WHERE res.id_resultado = doc.id_resultado;

COMMIT;
