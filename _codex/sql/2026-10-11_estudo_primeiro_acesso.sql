-- ABRACEO: leitura pessoal por declaração, sem alterar titularidade ou acesso operacional.
CREATE TABLE estudo.primeiro_acesso_empresas (
    id_conta bigint PRIMARY KEY REFERENCES public.tb_conta_perfis_publicos(id_conta),
    ativo boolean NOT NULL DEFAULT true,
    criado_em timestamptz NOT NULL DEFAULT clock_timestamp()
);
INSERT INTO estudo.primeiro_acesso_empresas(id_conta)
SELECT id_conta FROM public.tb_conta_perfis_publicos WHERE origem='ABRACEO';

CREATE TABLE estudo.primeiro_acesso_convites (
    voucher_id bigint PRIMARY KEY REFERENCES estudo.vouchers(id),
    id_conta bigint NOT NULL REFERENCES estudo.primeiro_acesso_empresas(id_conta)
);
CREATE TABLE estudo.primeiro_acesso_representantes (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_conta bigint NOT NULL REFERENCES estudo.primeiro_acesso_empresas(id_conta),
    usuario_id bigint NOT NULL REFERENCES public.tb_usuarios(id),
    acesso_id bigint NOT NULL REFERENCES estudo.acessos(id),
    metodo varchar(10) NOT NULL CHECK(metodo IN ('CNPJ','VOUCHER')),
    nome varchar(200) NOT NULL,
    email varchar(254) NOT NULL,
    funcao varchar(80) NOT NULL,
    observacoes varchar(1000) NOT NULL DEFAULT '',
    declaracao_versao varchar(40) NOT NULL DEFAULT 'abraceo-20261011-v1',
    criado_em timestamptz NOT NULL DEFAULT clock_timestamp(),
    UNIQUE(id_conta,usuario_id)
);
COMMENT ON TABLE estudo.primeiro_acesso_representantes IS
    'Autodeclaração para leitura pessoal da prévia. Não verifica representação legal nem concede papel na conta empresarial.';
INSERT INTO estudo.campanhas(codigo,titulo,produto_id,status,beneficio_percentual)
SELECT 'abraceo-primeiro-acesso','ABRACEO · Primeiro acesso à prévia',id,'ACTIVE',0
FROM estudo.produtos WHERE codigo='previa-2026-q3';
ALTER TABLE estudo.primeiro_acesso_empresas OWNER TO runner_dba;
ALTER TABLE estudo.primeiro_acesso_convites OWNER TO runner_dba;
ALTER TABLE estudo.primeiro_acesso_representantes OWNER TO runner_dba;
REVOKE ALL ON estudo.primeiro_acesso_empresas,estudo.primeiro_acesso_convites,
    estudo.primeiro_acesso_representantes FROM PUBLIC;
