BEGIN;

CREATE TABLE IF NOT EXISTS public.tb_percursos (
    id_percurso bigserial PRIMARY KEY,
    codigo_publico uuid NOT NULL UNIQUE,
    nome varchar(180) NOT NULL,
    cidade varchar(128),
    estado varchar(2),
    pais varchar(2) NOT NULL DEFAULT 'BR',
    distancia_nominal_m integer NOT NULL,
    tipo_percurso varchar(30) NOT NULL DEFAULT 'rua',
    descricao text,
    visibilidade varchar(20) NOT NULL DEFAULT 'privado',
    status varchar(20) NOT NULL DEFAULT 'rascunho',
    id_usuario_criador bigint NOT NULL,
    id_conta_responsavel bigint,
    criado_em timestamp without time zone NOT NULL DEFAULT now(),
    atualizado_em timestamp without time zone NOT NULL DEFAULT now(),
    CONSTRAINT tb_percursos_distancia_chk CHECK (distancia_nominal_m > 0),
    CONSTRAINT tb_percursos_tipo_chk CHECK (tipo_percurso IN ('rua', 'trail', 'misto')),
    CONSTRAINT tb_percursos_visibilidade_chk CHECK (visibilidade IN ('privado', 'compartilhado', 'publico')),
    CONSTRAINT tb_percursos_status_chk CHECK (status IN ('rascunho', 'publicado', 'arquivado'))
);

CREATE INDEX IF NOT EXISTS tb_percursos_busca_idx
    ON public.tb_percursos (status, estado, cidade, distancia_nominal_m);
CREATE INDEX IF NOT EXISTS tb_percursos_conta_idx
    ON public.tb_percursos (id_conta_responsavel, atualizado_em DESC);
CREATE INDEX IF NOT EXISTS tb_percursos_criador_idx
    ON public.tb_percursos (id_usuario_criador, atualizado_em DESC);

CREATE TABLE IF NOT EXISTS public.tb_percurso_arquivos (
    id_percurso_arquivo bigserial PRIMARY KEY,
    id_percurso bigint NOT NULL REFERENCES public.tb_percursos(id_percurso) ON DELETE RESTRICT,
    versao integer NOT NULL,
    storage_key varchar(512) NOT NULL,
    geojson_storage_key varchar(512) NOT NULL,
    nome_original varchar(255) NOT NULL,
    mime_type varchar(100),
    tamanho_bytes bigint NOT NULL,
    sha256 char(64) NOT NULL,
    quantidade_pontos integer NOT NULL,
    distancia_gpx_m numeric(14,2) NOT NULL,
    elevacao_min_m numeric(10,2),
    elevacao_max_m numeric(10,2),
    ganho_elevacao_m numeric(12,2),
    bbox_min_lat numeric(10,7) NOT NULL,
    bbox_min_lng numeric(10,7) NOT NULL,
    bbox_max_lat numeric(10,7) NOT NULL,
    bbox_max_lng numeric(10,7) NOT NULL,
    ativo boolean NOT NULL DEFAULT true,
    id_usuario_criador bigint NOT NULL,
    criado_em timestamp without time zone NOT NULL DEFAULT now(),
    CONSTRAINT tb_percurso_arquivos_versao_uq UNIQUE (id_percurso, versao),
    CONSTRAINT tb_percurso_arquivos_pontos_chk CHECK (quantidade_pontos >= 2),
    CONSTRAINT tb_percurso_arquivos_tamanho_chk CHECK (tamanho_bytes > 0)
);

CREATE INDEX IF NOT EXISTS tb_percurso_arquivos_percurso_idx
    ON public.tb_percurso_arquivos (id_percurso, versao DESC);
CREATE INDEX IF NOT EXISTS tb_percurso_arquivos_hash_idx
    ON public.tb_percurso_arquivos (sha256);

CREATE TABLE IF NOT EXISTS public.tb_percurso_historico (
    id_historico bigserial PRIMARY KEY,
    id_percurso bigint NOT NULL REFERENCES public.tb_percursos(id_percurso) ON DELETE RESTRICT,
    id_percurso_arquivo bigint REFERENCES public.tb_percurso_arquivos(id_percurso_arquivo) ON DELETE SET NULL,
    id_usuario bigint NOT NULL,
    acao varchar(50) NOT NULL,
    dados jsonb NOT NULL DEFAULT '{}'::jsonb,
    endereco_ip varchar(64),
    criado_em timestamp without time zone NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS tb_percurso_historico_percurso_idx
    ON public.tb_percurso_historico (id_percurso, criado_em DESC);

GRANT SELECT, INSERT, UPDATE ON public.tb_percursos TO runner;
GRANT SELECT, INSERT, UPDATE ON public.tb_percurso_arquivos TO runner;
GRANT SELECT, INSERT ON public.tb_percurso_historico TO runner;
GRANT USAGE, SELECT ON SEQUENCE public.tb_percursos_id_percurso_seq TO runner;
GRANT USAGE, SELECT ON SEQUENCE public.tb_percurso_arquivos_id_percurso_arquivo_seq TO runner;
GRANT USAGE, SELECT ON SEQUENCE public.tb_percurso_historico_id_historico_seq TO runner;

COMMIT;
