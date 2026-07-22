BEGIN;

CREATE TABLE IF NOT EXISTS public.tb_evento_percursos_gpx (
    id_evento_percurso_gpx bigserial PRIMARY KEY,
    id_evento integer NOT NULL REFERENCES public.tb_evento_corridas(id_evento) ON DELETE CASCADE,
    id_percurso bigint NOT NULL REFERENCES public.tb_percursos(id_percurso) ON DELETE CASCADE,
    id_usuario_criador bigint NOT NULL,
    criado_em timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT tb_evento_percursos_gpx_evento_percurso_uq UNIQUE (id_evento, id_percurso)
);

CREATE INDEX IF NOT EXISTS tb_evento_percursos_gpx_percurso_idx
    ON public.tb_evento_percursos_gpx (id_percurso, id_evento);

CREATE INDEX IF NOT EXISTS tb_evento_percursos_gpx_evento_idx
    ON public.tb_evento_percursos_gpx (id_evento, id_percurso);

CREATE INDEX IF NOT EXISTS tb_conta_eventos_evento_conta_status_idx
    ON public.tb_conta_eventos (id_evento, id_conta, status);

GRANT SELECT, INSERT, DELETE ON public.tb_evento_percursos_gpx TO runner;
GRANT USAGE, SELECT ON SEQUENCE public.tb_evento_percursos_gpx_id_evento_percurso_gpx_seq TO runner;

COMMIT;
