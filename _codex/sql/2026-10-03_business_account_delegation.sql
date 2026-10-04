-- Additive account delegation foundation. Does not enable accounts, alter legacy roles, or grant privileges.
BEGIN;
SET LOCAL lock_timeout='5s';
SET LOCAL statement_timeout='60s';
DO $preflight$
DECLARE object_name text;
BEGIN
 FOREACH object_name IN ARRAY ARRAY['tb_contas','tb_conta_usuarios','tb_usuarios','tb_business_permissoes','tb_conta_cadastro_solicitacoes'] LOOP
  IF to_regclass('public.'||object_name) IS NULL THEN RAISE EXCEPTION 'Delegation prerequisite missing: %',object_name; END IF;
 END LOOP;
 IF NOT has_schema_privilege(current_user,'public','CREATE') THEN RAISE EXCEPTION 'Delegation migration requires CREATE on public; no privileges were changed'; END IF;
END $preflight$;
INSERT INTO public.tb_business_permissoes(codigo,descricao,ativo) VALUES
 ('ads.campaigns.view','Consulta operacional de campanhas da conta',true),
 ('ads.campaigns.manage','Operação de campanhas sujeita à revisão existente',true),
 ('ads.payments.view','Histórico financeiro da própria conta',true),
 ('ads.credits.purchase','Compra de créditos para a própria conta',true),
 ('events.view','Consulta dos eventos vinculados à conta',true),
 ('events.manage','Edição operacional dos eventos vinculados à conta',true),
 ('events.links.request','Solicitação sujeita à análise existente',true)
ON CONFLICT(codigo) DO NOTHING;
CREATE TABLE IF NOT EXISTS public.tb_business_delegacao_schema(
 version bigint PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);
-- JSON only records the proposal. Effective grants use normalized, catalog-referencing tables below.
CREATE OR REPLACE FUNCTION public.business_delegation_capabilities_valid(proposal jsonb)
RETURNS boolean LANGUAGE plpgsql STABLE SET search_path=pg_catalog,public AS $function$
DECLARE item jsonb; codes text[] := ARRAY[]::text[]; code text;
BEGIN
 IF proposal IS NULL OR jsonb_typeof(proposal)<>'array' THEN RETURN false; END IF;
 FOR item IN SELECT value FROM jsonb_array_elements(proposal) LOOP
  IF jsonb_typeof(item)<>'string' THEN RETURN false; END IF;
  code=item#>>'{}';
  IF code=ANY(codes) OR code NOT IN('ads.campaigns.view','ads.campaigns.manage','ads.payments.view','ads.credits.purchase','events.view','events.manage','events.links.request')
   OR NOT EXISTS(SELECT 1 FROM public.tb_business_permissoes WHERE codigo=code) THEN RETURN false; END IF;
  codes=array_append(codes,code);
 END LOOP;
 RETURN true;
END $function$;
CREATE TABLE IF NOT EXISTS public.tb_conta_gestoras(
 id_conta bigint PRIMARY KEY REFERENCES public.tb_contas(id_conta),
 classificacao text NOT NULL CHECK(classificacao IN('AGENCIA','TICKETEIRA','OUTROS')),
 habilitada boolean NOT NULL DEFAULT false,
 id_usuario_autor integer NOT NULL REFERENCES public.tb_usuarios(id),
 version bigint NOT NULL DEFAULT 1 CHECK(version>0),
 created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
 updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS public.tb_conta_gestao_vinculos(
 id_vinculo bigserial PRIMARY KEY,
 id_conta_gestora bigint NOT NULL REFERENCES public.tb_conta_gestoras(id_conta),
 id_conta_cliente bigint NOT NULL REFERENCES public.tb_contas(id_conta),
 origem text NOT NULL CHECK(origem IN('CRIACAO_GESTORA','CONVITE_CLIENTE','SOLICITACAO_GESTORA')),
 status text NOT NULL CHECK(status IN('AGUARDANDO_CONTA','PENDENTE_CLIENTE','PENDENTE_GESTORA','ATIVO','SUSPENSO','RECUSADO','REVOGADO')),
 id_usuario_solicitante integer NOT NULL REFERENCES public.tb_usuarios(id),
 id_usuario_aprovador_cliente integer REFERENCES public.tb_usuarios(id),
 id_usuario_aprovador_gestora integer REFERENCES public.tb_usuarios(id),
 id_usuario_revisor integer REFERENCES public.tb_usuarios(id),
 capacidades_propostas jsonb NOT NULL DEFAULT '[]'::jsonb CHECK(public.business_delegation_capabilities_valid(capacidades_propostas)),
 version bigint NOT NULL DEFAULT 1 CHECK(version>0),
 created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
 updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
 decided_at timestamptz,
 CHECK(id_conta_gestora<>id_conta_cliente),
 UNIQUE(id_conta_gestora,id_conta_cliente)
);
CREATE TABLE IF NOT EXISTS public.tb_conta_gestao_permissoes(
 id_vinculo bigint NOT NULL REFERENCES public.tb_conta_gestao_vinculos(id_vinculo),
 id_permissao bigint NOT NULL REFERENCES public.tb_business_permissoes(id_permissao),
 PRIMARY KEY(id_vinculo,id_permissao)
);
CREATE OR REPLACE FUNCTION public.business_delegation_grant_catalog()
RETURNS trigger LANGUAGE plpgsql SET search_path=pg_catalog,public AS $function$
DECLARE code text;
BEGIN
 SELECT codigo INTO code FROM public.tb_business_permissoes WHERE id_permissao=NEW.id_permissao;
 IF FOUND AND code NOT IN('ads.campaigns.view','ads.campaigns.manage','ads.payments.view','ads.credits.purchase','events.view','events.manage','events.links.request') THEN
  RAISE EXCEPTION 'Capability is outside the delegation catalog' USING ERRCODE='23514';
 END IF;
 RETURN NEW;
END $function$;
DROP TRIGGER IF EXISTS business_delegation_grant_catalog ON public.tb_conta_gestao_permissoes;
CREATE TRIGGER business_delegation_grant_catalog BEFORE INSERT OR UPDATE OF id_permissao
 ON public.tb_conta_gestao_permissoes FOR EACH ROW EXECUTE FUNCTION public.business_delegation_grant_catalog();
CREATE TABLE IF NOT EXISTS public.tb_conta_gestao_equipe(
 id_equipe bigserial PRIMARY KEY,
 id_vinculo bigint NOT NULL REFERENCES public.tb_conta_gestao_vinculos(id_vinculo),
 id_conta_usuario bigint NOT NULL REFERENCES public.tb_conta_usuarios(id_conta_usuario) ON DELETE CASCADE,
 status text NOT NULL DEFAULT 'ATIVO' CHECK(status IN('ATIVO','REMOVIDO')),
 version bigint NOT NULL DEFAULT 1 CHECK(version>0),
 created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
 updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
 UNIQUE(id_vinculo,id_conta_usuario),
 UNIQUE(id_equipe,id_vinculo)
);
-- Reapply must refuse an incompatible prior installation; never rewrite deployed FKs silently.
DO $membership_fk$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_constraint c
   WHERE c.contype='f' AND c.convalidated AND c.confdeltype='c'
     AND c.conrelid='public.tb_conta_gestao_equipe'::regclass
     AND c.confrelid='public.tb_conta_usuarios'::regclass
     AND c.conkey=ARRAY[(SELECT attnum FROM pg_attribute WHERE attrelid=c.conrelid AND attname='id_conta_usuario')]::smallint[]
     AND c.confkey=ARRAY[(SELECT attnum FROM pg_attribute WHERE attrelid=c.confrelid AND attname='id_conta_usuario')]::smallint[])
 THEN RAISE EXCEPTION 'Incompatible delegation membership foreign key; installation requires reviewed repair'; END IF;
END $membership_fk$;
CREATE TABLE IF NOT EXISTS public.tb_conta_gestao_equipe_permissoes(
 id_equipe bigint NOT NULL,
 id_vinculo bigint NOT NULL,
 id_permissao bigint NOT NULL,
 PRIMARY KEY(id_equipe,id_permissao),
 FOREIGN KEY(id_equipe,id_vinculo) REFERENCES public.tb_conta_gestao_equipe(id_equipe,id_vinculo) ON DELETE CASCADE,
 FOREIGN KEY(id_vinculo,id_permissao) REFERENCES public.tb_conta_gestao_permissoes(id_vinculo,id_permissao) ON DELETE CASCADE
);
CREATE OR REPLACE FUNCTION public.business_delegation_team_scope()
RETURNS trigger LANGUAGE plpgsql SET search_path=pg_catalog,public AS $function$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.tb_conta_usuarios member
  JOIN public.tb_conta_gestao_vinculos relation ON relation.id_vinculo=NEW.id_vinculo AND relation.id_conta_gestora=member.id_conta
  WHERE member.id_conta_usuario=NEW.id_conta_usuario) THEN
  RAISE EXCEPTION 'Assignment member belongs to a different manager' USING ERRCODE='23514';
 END IF;
 RETURN NEW;
END $function$;
DROP TRIGGER IF EXISTS business_delegation_team_scope ON public.tb_conta_gestao_equipe;
CREATE TRIGGER business_delegation_team_scope BEFORE INSERT OR UPDATE OF id_vinculo,id_conta_usuario
 ON public.tb_conta_gestao_equipe FOR EACH ROW EXECUTE FUNCTION public.business_delegation_team_scope();
CREATE TABLE IF NOT EXISTS public.tb_conta_gestao_convites(
 id_convite bigserial PRIMARY KEY,
 tipo text NOT NULL CHECK(tipo IN('RELACAO','AMPLIACAO','TITULAR')),
 id_conta bigint NOT NULL REFERENCES public.tb_contas(id_conta),
 id_vinculo bigint REFERENCES public.tb_conta_gestao_vinculos(id_vinculo),
 email_destinatario text NOT NULL CHECK(email_destinatario=lower(btrim(email_destinatario)) AND email_destinatario ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'),
 capacidades_propostas jsonb NOT NULL DEFAULT '[]'::jsonb CHECK(public.business_delegation_capabilities_valid(capacidades_propostas)),
 token_hash varchar(64) NOT NULL UNIQUE CHECK(token_hash ~ '^[a-f0-9]{64}$'),
 status text NOT NULL DEFAULT 'PENDENTE' CHECK(status IN('PENDENTE','ACEITO','RECUSADO','CANCELADO','EXPIRADO')),
 id_usuario_autor integer NOT NULL REFERENCES public.tb_usuarios(id),
 id_usuario_aceite integer REFERENCES public.tb_usuarios(id),
 version bigint NOT NULL DEFAULT 1 CHECK(version>0),
 created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
 expires_at timestamptz NOT NULL DEFAULT(CURRENT_TIMESTAMP+interval '7 days'),
 updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
 accepted_at timestamptz,
 CHECK(expires_at>created_at AND expires_at<=created_at+interval '7 days'),
 CHECK(tipo='TITULAR' OR id_vinculo IS NOT NULL)
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_business_delegation_owner_pending ON public.tb_conta_gestao_convites(id_conta,tipo) WHERE tipo='TITULAR' AND status='PENDENTE';
CREATE TABLE IF NOT EXISTS public.tb_conta_gestao_auditoria(
 id_auditoria bigserial PRIMARY KEY,
 id_usuario_ator integer NOT NULL REFERENCES public.tb_usuarios(id),
 id_conta_gestora bigint REFERENCES public.tb_conta_gestoras(id_conta),
 id_conta_cliente bigint REFERENCES public.tb_contas(id_conta),
 id_vinculo bigint REFERENCES public.tb_conta_gestao_vinculos(id_vinculo),
 acao text NOT NULL,
 recurso_tipo text NOT NULL CHECK(recurso_tipo IN('RELATIONSHIP','ASSIGNMENT','INVITATION','ACCOUNT','CAMPAIGN','PAYMENT_INTENT','EVENT','EVENT_REQUEST')),
 recurso_id text,
 resultado text NOT NULL CHECK(resultado IN('SUCCESS','DENIED','CONFLICT','ERROR')),
 alteracoes jsonb NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(alteracoes)='object'),
 created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE public.tb_conta_cadastro_solicitacoes ADD COLUMN IF NOT EXISTS origem_gestora_id bigint REFERENCES public.tb_conta_gestoras(id_conta);
ALTER TABLE public.tb_conta_cadastro_solicitacoes ADD COLUMN IF NOT EXISTS gestao_vinculo_id bigint REFERENCES public.tb_conta_gestao_vinculos(id_vinculo);
CREATE INDEX IF NOT EXISTS ix_business_delegation_client ON public.tb_conta_gestao_vinculos(id_conta_cliente,status,id_vinculo);
CREATE INDEX IF NOT EXISTS ix_business_delegation_manager_pending ON public.tb_conta_gestao_vinculos(id_conta_gestora,status,id_vinculo);
CREATE INDEX IF NOT EXISTS ix_business_delegation_member ON public.tb_conta_gestao_equipe(id_conta_usuario,status,id_vinculo);
CREATE INDEX IF NOT EXISTS ix_business_delegation_invitee ON public.tb_conta_gestao_convites(email_destinatario,status,expires_at,id_convite);
CREATE INDEX IF NOT EXISTS ix_business_delegation_invite_relation ON public.tb_conta_gestao_convites(id_vinculo,status,id_convite);
CREATE INDEX IF NOT EXISTS ix_business_delegation_audit_relation ON public.tb_conta_gestao_auditoria(id_vinculo,created_at DESC,id_auditoria DESC);
CREATE INDEX IF NOT EXISTS ix_business_delegation_registration ON public.tb_conta_cadastro_solicitacoes(origem_gestora_id,status,id_solicitacao) WHERE origem_gestora_id IS NOT NULL;
INSERT INTO public.tb_business_delegacao_schema(version) VALUES(1) ON CONFLICT DO NOTHING;
COMMIT;
