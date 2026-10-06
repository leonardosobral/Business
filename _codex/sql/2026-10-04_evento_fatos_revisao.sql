-- Private human reviews; no backfill or automatic public approval.
CREATE TABLE public.tb_evento_fatos_revisao (
    id_revisao bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_evento integer NOT NULL,
    grupo text NOT NULL CHECK (grupo IN ('datas','local','situacao')),
    fatos jsonb NOT NULL CHECK (jsonb_typeof(fatos)='object' AND fatos <> '{}'::jsonb),
    fonte_url text NOT NULL CHECK (length(fonte_url) BETWEEN 8 AND 2048 AND fonte_url ~* '^https?://'),
    registrado_em timestamptz NOT NULL DEFAULT clock_timestamp(),
    revogado_em timestamptz CHECK (revogado_em IS NULL OR revogado_em >= registrado_em),
    requisicao uuid NOT NULL UNIQUE
);
CREATE INDEX tb_evento_fatos_revisao_evento_idx ON public.tb_evento_fatos_revisao (id_evento, id_revisao DESC);
COMMENT ON TABLE public.tb_evento_fatos_revisao IS 'Conferencias internas por grupo, com fonte e snapshot. Retirada preserva evidencia; nao publica fatos, nao comprova fonte atual e nao inclui operador/IP.';
REVOKE ALL ON TABLE public.tb_evento_fatos_revisao FROM PUBLIC;
REVOKE ALL ON SEQUENCE public.tb_evento_fatos_revisao_id_revisao_seq FROM PUBLIC;
