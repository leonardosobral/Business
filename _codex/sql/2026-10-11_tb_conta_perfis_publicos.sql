-- Complemento de pesquisa para pré-cadastro. Não concede acesso nem substitui titular.
CREATE TABLE IF NOT EXISTS public.tb_conta_perfis_publicos (
    id_conta bigint PRIMARY KEY REFERENCES public.tb_contas(id_conta),
    origem varchar(80) NOT NULL,
    id_origem varchar(160) NOT NULL,
    logo_path varchar(300),
    dados jsonb NOT NULL CHECK (jsonb_typeof(dados) = 'object'),
    data_pesquisa date NOT NULL,
    data_criacao timestamptz NOT NULL DEFAULT now(),
    UNIQUE (origem, id_origem)
);
ALTER TABLE public.tb_conta_perfis_publicos OWNER TO runner_dba;
GRANT SELECT ON public.tb_conta_perfis_publicos TO runner;
