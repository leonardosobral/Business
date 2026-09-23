BEGIN;

CREATE TABLE IF NOT EXISTS public.tb_evento_saude_acesso_solicitacoes
(
    id_solicitacao         bigserial PRIMARY KEY,
    id_evento              integer NOT NULL
        REFERENCES public.tb_evento_corridas (id_evento) ON DELETE CASCADE,
    id_conta               bigint NOT NULL
        REFERENCES public.tb_contas (id_conta) ON DELETE CASCADE,
    id_usuario_solicitante bigint NOT NULL
        REFERENCES public.tb_usuarios (id) ON DELETE CASCADE,
    papel_solicitado       public.papel_usuario_conta NOT NULL
        DEFAULT 'MEDICO'::public.papel_usuario_conta,
    status                 varchar(16) NOT NULL DEFAULT 'PENDENTE',
    mensagem               text,
    id_usuario_revisor     bigint
        REFERENCES public.tb_usuarios (id) ON DELETE SET NULL,
    observacao_revisor     text,
    data_criacao           timestamp with time zone NOT NULL DEFAULT now(),
    data_atualizacao       timestamp with time zone NOT NULL DEFAULT now(),
    data_revisao           timestamp with time zone,
    CONSTRAINT ck_evento_saude_acesso_papel_medico
        CHECK (papel_solicitado = 'MEDICO'::public.papel_usuario_conta),
    CONSTRAINT ck_evento_saude_acesso_status
        CHECK (status IN ('PENDENTE', 'APROVADA', 'RECUSADA', 'CANCELADA'))
);

ALTER TABLE public.tb_evento_saude_acesso_solicitacoes OWNER TO runner_dba;

CREATE UNIQUE INDEX IF NOT EXISTS uq_evento_saude_acesso_pendente
    ON public.tb_evento_saude_acesso_solicitacoes
       (id_evento, id_conta, id_usuario_solicitante)
    WHERE status = 'PENDENTE';

CREATE INDEX IF NOT EXISTS idx_evento_saude_acesso_conta_status
    ON public.tb_evento_saude_acesso_solicitacoes
       (id_conta, status, data_criacao);

CREATE INDEX IF NOT EXISTS idx_evento_saude_acesso_usuario
    ON public.tb_evento_saude_acesso_solicitacoes
       (id_usuario_solicitante, data_criacao DESC);

GRANT SELECT, USAGE ON SEQUENCE public.tb_evento_saude_acesso_solicitacoes_id_solicitacao_seq TO runner;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE
    ON public.tb_evento_saude_acesso_solicitacoes TO runner;

COMMIT;
