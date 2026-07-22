BEGIN;

ALTER TABLE public.tb_evento_percursos_gpx
    ADD COLUMN IF NOT EXISTS id_evento_percurso integer;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_evento_percursos_gpx_modalidade'
          AND conrelid = 'public.tb_evento_percursos_gpx'::regclass
    ) THEN
        ALTER TABLE public.tb_evento_percursos_gpx
            ADD CONSTRAINT fk_evento_percursos_gpx_modalidade
            FOREIGN KEY (id_evento_percurso)
            REFERENCES public.tb_evento_corridas_percursos(id_evento_percurso)
            ON UPDATE CASCADE
            ON DELETE CASCADE;
    END IF;
END
$$;

-- Vinculos manuais antigos continuam unicos por evento/percurso. Vinculos
-- migrados passam a ser unicos pela modalidade original do evento.
ALTER TABLE public.tb_evento_percursos_gpx
    DROP CONSTRAINT IF EXISTS tb_evento_percursos_gpx_evento_percurso_uq;

CREATE UNIQUE INDEX IF NOT EXISTS tb_evento_percursos_gpx_manual_uq
    ON public.tb_evento_percursos_gpx (id_evento, id_percurso)
    WHERE id_evento_percurso IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS tb_evento_percursos_gpx_modalidade_uq
    ON public.tb_evento_percursos_gpx (id_evento_percurso)
    WHERE id_evento_percurso IS NOT NULL;

CREATE INDEX IF NOT EXISTS tb_evento_percursos_gpx_modalidade_idx
    ON public.tb_evento_percursos_gpx (id_evento_percurso, id_percurso);

CREATE TABLE IF NOT EXISTS public.tb_percurso_migracoes_strava (
    id_migracao bigserial PRIMARY KEY,
    id_evento_percurso integer NOT NULL
        REFERENCES public.tb_evento_corridas_percursos(id_evento_percurso)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    id_evento integer NOT NULL
        REFERENCES public.tb_evento_corridas(id_evento)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    strava_route_id varchar(128) NOT NULL,
    strava_url varchar(512) NOT NULL,
    status varchar(24) NOT NULL DEFAULT 'pendente',
    id_percurso bigint
        REFERENCES public.tb_percursos(id_percurso)
        ON DELETE SET NULL,
    id_percurso_arquivo bigint
        REFERENCES public.tb_percurso_arquivos(id_percurso_arquivo)
        ON DELETE SET NULL,
    sha256 char(64),
    distancia_gpx_m numeric(14,2),
    tentativas integer NOT NULL DEFAULT 0,
    ultimo_http_status integer,
    mensagem text,
    dados jsonb NOT NULL DEFAULT '{}'::jsonb,
    id_usuario_ultima_acao bigint,
    data_criacao timestamp with time zone NOT NULL DEFAULT now(),
    data_atualizacao timestamp with time zone NOT NULL DEFAULT now(),
    data_ultima_tentativa timestamp with time zone,
    data_conclusao timestamp with time zone,
    CONSTRAINT tb_percurso_migracoes_strava_modalidade_uq UNIQUE (id_evento_percurso),
    CONSTRAINT tb_percurso_migracoes_strava_status_chk CHECK (
        status IN ('pendente', 'processando', 'validado', 'migrado', 'reutilizado', 'revisao', 'erro', 'ignorado')
    ),
    CONSTRAINT tb_percurso_migracoes_strava_tentativas_chk CHECK (tentativas >= 0)
);

CREATE INDEX IF NOT EXISTS tb_percurso_migracoes_strava_status_idx
    ON public.tb_percurso_migracoes_strava (status, data_atualizacao, id_evento_percurso);

CREATE INDEX IF NOT EXISTS tb_percurso_migracoes_strava_rota_idx
    ON public.tb_percurso_migracoes_strava (strava_route_id);

CREATE INDEX IF NOT EXISTS tb_percurso_migracoes_strava_percurso_idx
    ON public.tb_percurso_migracoes_strava (id_percurso, id_evento_percurso);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.tb_percurso_migracoes_strava TO runner;
GRANT SELECT, INSERT, UPDATE ON public.tb_evento_percursos_gpx TO runner;
GRANT USAGE, SELECT ON SEQUENCE public.tb_percurso_migracoes_strava_id_migracao_seq TO runner;

COMMIT;
