BEGIN;

CREATE TABLE IF NOT EXISTS public.tb_trello_quadros (
    id_trello_quadro bigserial PRIMARY KEY,
    trello_board_id varchar(32) NOT NULL UNIQUE,
    departamento varchar(100) NOT NULL,
    nome_remoto varchar(255),
    url varchar(500),
    ativo boolean NOT NULL DEFAULT true,
    ordem integer NOT NULL DEFAULT 100,
    id_usuario_criacao integer REFERENCES public.tb_usuarios(id) ON UPDATE CASCADE ON DELETE SET NULL,
    id_usuario_alteracao integer REFERENCES public.tb_usuarios(id) ON UPDATE CASCADE ON DELETE SET NULL,
    data_criacao timestamp NOT NULL DEFAULT now(),
    data_atualizacao timestamp NOT NULL DEFAULT now(),
    CONSTRAINT tb_trello_quadros_board_id_ck CHECK (trello_board_id ~ '^[0-9a-fA-F]{24}$'),
    CONSTRAINT tb_trello_quadros_departamento_ck CHECK (length(btrim(departamento)) BETWEEN 2 AND 100)
);

CREATE UNIQUE INDEX IF NOT EXISTS tb_trello_quadros_departamento_ativo_uq
    ON public.tb_trello_quadros (lower(btrim(departamento)))
    WHERE ativo = true;

CREATE INDEX IF NOT EXISTS tb_trello_quadros_ordem_idx
    ON public.tb_trello_quadros (ativo, ordem, lower(departamento));

CREATE TABLE IF NOT EXISTS public.tb_trello_auditoria (
    id_trello_auditoria bigserial PRIMARY KEY,
    id_usuario integer REFERENCES public.tb_usuarios(id) ON UPDATE CASCADE ON DELETE SET NULL,
    id_trello_quadro bigint REFERENCES public.tb_trello_quadros(id_trello_quadro) ON UPDATE CASCADE ON DELETE SET NULL,
    trello_board_id varchar(32),
    trello_card_id varchar(32),
    acao varchar(64) NOT NULL,
    sucesso boolean NOT NULL DEFAULT false,
    http_status integer,
    detalhes jsonb NOT NULL DEFAULT '{}'::jsonb,
    mensagem_erro varchar(1000),
    endereco_ip varchar(64),
    user_agent varchar(512),
    data_criacao timestamp NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS tb_trello_auditoria_quadro_idx
    ON public.tb_trello_auditoria (id_trello_quadro, data_criacao DESC);

CREATE INDEX IF NOT EXISTS tb_trello_auditoria_usuario_idx
    ON public.tb_trello_auditoria (id_usuario, data_criacao DESC);

COMMIT;
