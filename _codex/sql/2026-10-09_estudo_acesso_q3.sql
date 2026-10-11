-- Apply as one transaction through the reviewed operator bridge, not the notebook.
-- Additive first installation. Refuse reruns/partial installs; never overwrite live data.
SET LOCAL lock_timeout = '3s';
SET LOCAL statement_timeout = '45s';
SELECT pg_advisory_xact_lock(hashtextextended('estudo-acesso-q3-v1',0));
DO $$
DECLARE p estudo.web_publicacoes;
BEGIN
  IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
      WHERE n.nspname='estudo' AND c.relname IN
      ('produtos','campanhas','solicitacoes','vouchers','acessos','interesses','beneficios','auditoria_comercial')) THEN
    RAISE EXCEPTION 'Commercial study objects already exist; inspect the installed migration before proceeding';
  END IF;
  IF (SELECT publicacao_id FROM estudo.web_destinos WHERE ano=2026) IS DISTINCT FROM 41::bigint THEN
    RAISE EXCEPTION 'The 2026 publication changed after review; inspect and select the Q3 publication again';
  END IF;
  SELECT * INTO p FROM estudo.web_publicacoes WHERE id=41 AND ano=2026;
  IF p.id IS NULL OR p.run_id<>233
      OR p.payload->'meta'->>'periodo_inicio' IS DISTINCT FROM '2026-01-01'
      OR p.payload->'meta'->>'periodo_fim_exclusivo' IS DISTINCT FROM '2026-10-01'
      OR p.payload->'meta'->>'corte' IS DISTINCT FROM '2026-09-30' THEN
    RAISE EXCEPTION 'Publication 41 is not the reviewed frozen Jan-Sep 2026 package';
  END IF;
END $$;

CREATE TABLE estudo.produtos (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  codigo text NOT NULL UNIQUE CHECK(codigo ~ '^[a-z0-9-]{3,60}$'),
  titulo text NOT NULL CHECK(length(titulo) BETWEEN 1 AND 200),
  tipo text NOT NULL CHECK(tipo IN ('PREVIA','ANUAL')),
  ano integer NOT NULL CHECK(ano BETWEEN 2026 AND 2100),
  periodo_inicio date NOT NULL,
  periodo_fim date NOT NULL CHECK(periodo_fim>=periodo_inicio),
  status text NOT NULL DEFAULT 'DRAFT' CHECK(status IN ('DRAFT','ACTIVE','ARCHIVED')),
  publicacao_id bigint REFERENCES estudo.web_publicacoes(id),
  criado_em timestamptz NOT NULL DEFAULT clock_timestamp(),
  CHECK(status<>'ACTIVE' OR publicacao_id IS NOT NULL)
);
COMMENT ON COLUMN estudo.produtos.publicacao_id IS 'Explicit approved publication; never resolve the paid/private product by year alone.';

CREATE TABLE estudo.campanhas (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  codigo text NOT NULL UNIQUE CHECK(codigo ~ '^[a-z0-9-]{3,60}$'),
  titulo text NOT NULL,
  produto_id bigint NOT NULL REFERENCES estudo.produtos(id),
  status text NOT NULL DEFAULT 'DRAFT' CHECK(status IN ('DRAFT','ACTIVE','PAUSED','CLOSED')),
  beneficio_percentual smallint NOT NULL DEFAULT 0 CHECK(beneficio_percentual IN (0,50)),
  beneficio_produto_id bigint REFERENCES estudo.produtos(id),
  inicio_em timestamptz,
  fim_em timestamptz,
  version integer NOT NULL DEFAULT 1 CHECK(version>0),
  atualizado_por bigint REFERENCES public.tb_usuarios(id),
  atualizado_em timestamptz NOT NULL DEFAULT clock_timestamp(),
  CHECK((beneficio_percentual=0 AND beneficio_produto_id IS NULL)
     OR (beneficio_percentual=50 AND beneficio_produto_id IS NOT NULL)),
  CHECK(fim_em IS NULL OR inicio_em IS NULL OR fim_em>inicio_em)
);

CREATE TABLE estudo.solicitacoes (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  usuario_id bigint NOT NULL REFERENCES public.tb_usuarios(id),
  produto_id bigint NOT NULL REFERENCES estudo.produtos(id),
  kind text NOT NULL CHECK(kind IN ('PROFISSIONAL','EDITORIAL')),
  empresa text NOT NULL DEFAULT '' CHECK(length(empresa)<=160),
  perfil text NOT NULL DEFAULT '' CHECK(length(perfil)<=80),
  mensagem text NOT NULL DEFAULT '' CHECK(length(mensagem)<=2000),
  status text NOT NULL DEFAULT 'PENDING' CHECK(status IN ('PENDING','INVITED','DECLINED')),
  criado_em timestamptz NOT NULL DEFAULT clock_timestamp(),
  decidido_em timestamptz,
  decidido_por bigint REFERENCES public.tb_usuarios(id),
  nota text NOT NULL DEFAULT '' CHECK(length(nota)<=1000),
  UNIQUE(usuario_id,produto_id)
);

CREATE TABLE estudo.vouchers (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  campanha_id bigint NOT NULL REFERENCES estudo.campanhas(id),
  solicitacao_id bigint UNIQUE REFERENCES estudo.solicitacoes(id),
  codigo_hash char(64) NOT NULL UNIQUE CHECK(codigo_hash ~ '^[a-f0-9]{64}$'),
  email_destinatario text NOT NULL CHECK(email_destinatario=lower(btrim(email_destinatario)) AND length(email_destinatario) BETWEEN 3 AND 254),
  status text NOT NULL DEFAULT 'READY' CHECK(status IN ('READY','REDEEMED','REVOKED')),
  expira_em timestamptz NOT NULL,
  criado_por bigint NOT NULL REFERENCES public.tb_usuarios(id),
  criado_em timestamptz NOT NULL DEFAULT clock_timestamp(),
  resgatado_por bigint REFERENCES public.tb_usuarios(id),
  resgatado_em timestamptz,
  revogado_por bigint REFERENCES public.tb_usuarios(id),
  revogado_em timestamptz,
  nota text NOT NULL DEFAULT '' CHECK(length(nota)<=1000),
  CHECK((resgatado_por IS NULL)=(resgatado_em IS NULL)),
  CHECK(status<>'REDEEMED' OR resgatado_por IS NOT NULL),
  CHECK(status<>'READY' OR resgatado_por IS NULL)
);
CREATE UNIQUE INDEX estudo_voucher_destinatario_ativo
  ON estudo.vouchers(campanha_id,email_destinatario) WHERE status IN ('READY','REDEEMED');
COMMENT ON COLUMN estudo.vouchers.codigo_hash IS 'SHA-256 of the uppercase BQ26- code; plaintext is returned once on creation and is never persisted.';

CREATE TABLE estudo.acessos (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  usuario_id bigint NOT NULL REFERENCES public.tb_usuarios(id),
  produto_id bigint NOT NULL REFERENCES estudo.produtos(id),
  voucher_id bigint NOT NULL UNIQUE REFERENCES estudo.vouchers(id),
  status text NOT NULL DEFAULT 'ACTIVE' CHECK(status IN ('ACTIVE','REVOKED')),
  concedido_em timestamptz NOT NULL DEFAULT clock_timestamp(),
  revogado_em timestamptz,
  revogado_por bigint REFERENCES public.tb_usuarios(id),
  motivo text NOT NULL DEFAULT '' CHECK(length(motivo)<=1000)
);
CREATE INDEX estudo_acesso_usuario_produto ON estudo.acessos(usuario_id,produto_id,status);

CREATE TABLE estudo.interesses (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  usuario_id bigint NOT NULL REFERENCES public.tb_usuarios(id),
  kind text NOT NULL CHECK(kind IN ('ANUAL','EDITORIAL')),
  status text NOT NULL DEFAULT 'ACTIVE' CHECK(status IN ('ACTIVE','WITHDRAWN')),
  consentimento_versao text NOT NULL DEFAULT 'q3-2026-v1',
  criado_em timestamptz NOT NULL DEFAULT clock_timestamp(),
  atualizado_em timestamptz NOT NULL DEFAULT clock_timestamp(),
  UNIQUE(usuario_id,kind)
);

CREATE TABLE estudo.beneficios (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  usuario_id bigint NOT NULL REFERENCES public.tb_usuarios(id),
  produto_id bigint NOT NULL REFERENCES estudo.produtos(id),
  acesso_id bigint NOT NULL UNIQUE REFERENCES estudo.acessos(id),
  percentual smallint NOT NULL CHECK(percentual=50),
  status text NOT NULL DEFAULT 'ELIGIBLE' CHECK(status IN ('ELIGIBLE','REVOKED')),
  criado_em timestamptz NOT NULL DEFAULT clock_timestamp(),
  revogado_em timestamptz,
  revogado_por bigint REFERENCES public.tb_usuarios(id)
);
CREATE INDEX estudo_beneficio_usuario ON estudo.beneficios(usuario_id,produto_id,status);
COMMENT ON TABLE estudo.beneficios IS 'Eligibility only. No checkout, monetary balance, payment or consumption exists in the Q3 phase. Independent origins do not stack discounts.';

CREATE TABLE estudo.auditoria_comercial (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  ator_id bigint NOT NULL REFERENCES public.tb_usuarios(id),
  acao text NOT NULL CHECK(length(acao) BETWEEN 1 AND 80),
  entidade text NOT NULL CHECK(length(entidade) BETWEEN 1 AND 40),
  entidade_id bigint NOT NULL,
  detalhes jsonb NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(detalhes)='object'),
  criado_em timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE INDEX estudo_auditoria_entidade ON estudo.auditoria_comercial(entidade,entidade_id,id);
CREATE TRIGGER estudo_auditoria_imutavel BEFORE UPDATE OR DELETE ON estudo.auditoria_comercial
  FOR EACH ROW EXECUTE FUNCTION estudo.notebook_immutable();
CREATE TRIGGER estudo_auditoria_no_truncate BEFORE TRUNCATE ON estudo.auditoria_comercial
  FOR EACH STATEMENT EXECUTE FUNCTION estudo.notebook_immutable();

INSERT INTO estudo.produtos(codigo,titulo,tipo,ano,periodo_inicio,periodo_fim,status,publicacao_id)
VALUES ('previa-2026-q3','Prévia profissional 2026 · Janeiro a setembro','PREVIA',2026,'2026-01-01','2026-09-30','ACTIVE',41),
       ('anual-2026','Estudo profissional 2026 · Edição anual','ANUAL',2026,'2026-01-01','2026-12-31','DRAFT',NULL);
INSERT INTO estudo.campanhas(codigo,titulo,produto_id,status,beneficio_percentual,beneficio_produto_id)
SELECT x.codigo,x.titulo,p.id,'DRAFT',x.percentual,CASE WHEN x.percentual=50 THEN a.id ELSE NULL END
FROM (VALUES ('piloto','Piloto com organizadores',50),('abraceo','ABRACEO · Parceria em negociação',50),('editorial','Convites editoriais',50)) x(codigo,titulo,percentual)
CROSS JOIN estudo.produtos p CROSS JOIN estudo.produtos a
WHERE p.codigo='previa-2026-q3' AND a.codigo='anual-2026';

REVOKE ALL ON estudo.produtos,estudo.campanhas,estudo.solicitacoes,estudo.vouchers,
  estudo.acessos,estudo.interesses,estudo.beneficios,estudo.auditoria_comercial FROM PUBLIC;
-- Do not grant the public portal's runner role access to these private tables.
-- Business StudyAccess uses runner_dba, the reviewed existing owner datasource.
-- Public projection and its narrowly scoped grant are a separate reviewed migration.
