BEGIN;

ALTER TABLE public.tb_evento_saude_config
    ADD COLUMN IF NOT EXISTS id_diretor_medico integer;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'tb_evento_saude_config_diretor_fk'
          AND conrelid = 'public.tb_evento_saude_config'::regclass
    ) THEN
        ALTER TABLE public.tb_evento_saude_config
            ADD CONSTRAINT tb_evento_saude_config_diretor_fk
            FOREIGN KEY (id_diretor_medico)
            REFERENCES public.tb_usuarios (id)
            ON UPDATE CASCADE ON DELETE SET NULL;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS tb_evento_saude_config_diretor_idx
    ON public.tb_evento_saude_config (id_diretor_medico);

WITH diretor_candidatos AS (
    SELECT cfg.id_evento,
           min(usr.id) AS id_usuario,
           count(DISTINCT usr.id) AS total
    FROM public.tb_evento_saude_config cfg
    INNER JOIN public.tb_conta_eventos ce
        ON ce.id_evento = cfg.id_evento
       AND ce.status = 'ATIVO'::public.status_conta_evento
    INNER JOIN public.tb_conta_usuarios cu
        ON cu.id_conta = ce.id_conta
       AND cu.papel = 'MEDICO'::public.papel_usuario_conta
       AND cu.status = 'ATIVO'::public.status_usuario_conta
    INNER JOIN public.tb_usuarios usr
        ON usr.id = cu.id_usuario
       AND lower(trim(usr.name)) = lower(trim(cfg.diretor_medico))
    WHERE cfg.id_diretor_medico IS NULL
      AND nullif(trim(cfg.diretor_medico), '') IS NOT NULL
    GROUP BY cfg.id_evento
)
UPDATE public.tb_evento_saude_config cfg
SET id_diretor_medico = diretor_candidatos.id_usuario
FROM diretor_candidatos
WHERE cfg.id_evento = diretor_candidatos.id_evento
  AND diretor_candidatos.total = 1;

COMMIT;
