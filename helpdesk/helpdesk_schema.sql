CREATE TABLE IF NOT EXISTS public.tb_helpdesk_setores (
    id_setor serial PRIMARY KEY,
    nome_setor varchar(120) NOT NULL,
    descricao_setor text,
    id_usuario_responsavel integer REFERENCES public.tb_usuarios(id) ON DELETE SET NULL,
    ativo boolean NOT NULL DEFAULT true,
    created_at timestamp without time zone NOT NULL DEFAULT now(),
    updated_at timestamp without time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.tb_helpdesk_chamados (
    id_chamado serial PRIMARY KEY,
    protocolo varchar(40) NOT NULL UNIQUE,
    id_usuario integer NOT NULL REFERENCES public.tb_usuarios(id) ON DELETE CASCADE,
    id_setor integer NOT NULL REFERENCES public.tb_helpdesk_setores(id_setor) ON DELETE RESTRICT,
    assunto varchar(180) NOT NULL,
    status varchar(40) NOT NULL DEFAULT 'aberto',
    created_at timestamp without time zone NOT NULL DEFAULT now(),
    updated_at timestamp without time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.tb_helpdesk_mensagens (
    id_mensagem serial PRIMARY KEY,
    id_chamado integer NOT NULL REFERENCES public.tb_helpdesk_chamados(id_chamado) ON DELETE CASCADE,
    id_usuario integer NOT NULL REFERENCES public.tb_usuarios(id) ON DELETE RESTRICT,
    mensagem text NOT NULL,
    interno boolean NOT NULL DEFAULT false,
    created_at timestamp without time zone NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_helpdesk_chamados_usuario
    ON public.tb_helpdesk_chamados (id_usuario, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_helpdesk_chamados_setor
    ON public.tb_helpdesk_chamados (id_setor, status);

CREATE INDEX IF NOT EXISTS idx_helpdesk_mensagens_chamado
    ON public.tb_helpdesk_mensagens (id_chamado, created_at ASC);
