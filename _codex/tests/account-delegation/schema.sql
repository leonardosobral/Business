-- Missing/incomplete migrations, weakened constraints, privilege leaks, or data loss fail these tests.
DO $test$
DECLARE t text;
BEGIN
 FOREACH t IN ARRAY ARRAY['tb_conta_gestoras','tb_conta_gestao_vinculos','tb_conta_gestao_permissoes','tb_conta_gestao_equipe','tb_conta_gestao_equipe_permissoes','tb_conta_gestao_convites','tb_conta_gestao_auditoria'] LOOP
  IF to_regclass('public.'||t) IS NULL THEN RAISE EXCEPTION 'missing delegation schema: %',t; END IF;
 END LOOP;
 IF EXISTS(SELECT 1 FROM pg_enum WHERE enumlabel='AGENCIA' AND enumtypid='papel_usuario_conta'::regtype) THEN RAISE EXCEPTION 'role leak'; END IF;
 IF (SELECT count(*) FROM tb_conta_usuarios)<>6 OR (SELECT count(*) FROM tb_conta_usuarios WHERE id_conta=102)<>1 THEN RAISE EXCEPTION 'direct memberships changed'; END IF;
 IF (SELECT count(*) FROM tb_conta_cadastro_solicitacoes WHERE id_solicitacao=4001 AND origem_gestora_id IS NULL AND gestao_vinculo_id IS NULL)<>1 THEN RAISE EXCEPTION 'legacy request changed'; END IF;
 IF EXISTS(SELECT 1 FROM tb_conta_gestoras WHERE habilitada) THEN RAISE EXCEPTION 'migration enabled manager'; END IF;
 IF (SELECT count(*) FROM tb_business_permissoes WHERE codigo IN('ads.campaigns.view','ads.campaigns.manage','ads.payments.view','ads.credits.purchase','events.view','events.manage','events.links.request'))<>7 THEN RAISE EXCEPTION 'missing capability catalog'; END IF;
END $test$;
CREATE FUNCTION pg_temp.reject(statement text, expected_state text) RETURNS void LANGUAGE plpgsql AS $fn$
BEGIN
 BEGIN EXECUTE statement;
 EXCEPTION WHEN OTHERS THEN
  IF SQLSTATE=expected_state THEN RETURN; END IF;
  RAISE EXCEPTION 'wrong rejection %, expected %: %',SQLSTATE,expected_state,SQLERRM;
 END;
 RAISE EXCEPTION 'unsafe success: %',statement;
END $fn$;
BEGIN;
INSERT INTO tb_conta_gestoras(id_conta,classificacao,habilitada,id_usuario_autor) VALUES(101,'AGENCIA',true,901),(103,'TICKETEIRA',true,901);
INSERT INTO tb_conta_gestao_vinculos(id_vinculo,id_conta_gestora,id_conta_cliente,origem,status,id_usuario_solicitante,capacidades_propostas)
VALUES(2001,101,102,'CONVITE_CLIENTE','ATIVO',904,'["ads.campaigns.view","events.view"]');
SELECT pg_temp.reject($q$INSERT INTO tb_conta_gestao_vinculos(id_conta_gestora,id_conta_cliente,origem,status,id_usuario_solicitante) VALUES(101,101,'CONVITE_CLIENTE','ATIVO',904)$q$,'23514');
SELECT pg_temp.reject($q$INSERT INTO tb_conta_gestao_vinculos(id_conta_gestora,id_conta_cliente,origem,status,id_usuario_solicitante) VALUES(101,102,'CONVITE_CLIENTE','ATIVO',904)$q$,'23505');
SELECT pg_temp.reject($q$UPDATE tb_conta_gestao_vinculos SET status='UNKNOWN' WHERE id_vinculo=2001$q$,'23514');
SELECT pg_temp.reject($q$UPDATE tb_conta_gestao_vinculos SET capacidades_propostas='["crm.manage"]' WHERE id_vinculo=2001$q$,'23514');
SELECT pg_temp.reject($q$UPDATE tb_conta_gestao_vinculos SET capacidades_propostas='{"events.view":true}' WHERE id_vinculo=2001$q$,'23514');
SELECT pg_temp.reject($q$UPDATE tb_conta_gestao_vinculos SET capacidades_propostas='["events.view","events.view"]' WHERE id_vinculo=2001$q$,'23514');
SELECT pg_temp.reject($q$UPDATE tb_conta_gestao_vinculos SET version=0 WHERE id_vinculo=2001$q$,'23514');
SELECT pg_temp.reject($q$INSERT INTO tb_conta_gestao_permissoes VALUES(2001,999999)$q$,'23503');
INSERT INTO tb_business_permissoes(codigo,descricao) VALUES('crm.export','Synthetic forbidden capability');
SELECT pg_temp.reject($q$INSERT INTO tb_conta_gestao_permissoes SELECT 2001,id_permissao FROM tb_business_permissoes WHERE codigo='crm.export'$q$,'23514');
INSERT INTO tb_conta_gestao_permissoes SELECT 2001,id_permissao FROM tb_business_permissoes WHERE codigo='events.view';
INSERT INTO tb_conta_gestao_equipe(id_equipe,id_vinculo,id_conta_usuario,status) VALUES(3001,2001,1002,'ATIVO');
SELECT pg_temp.reject($q$INSERT INTO tb_conta_gestao_equipe(id_vinculo,id_conta_usuario,status) VALUES(2001,1003,'ATIVO')$q$,'23514');
INSERT INTO tb_conta_gestao_equipe_permissoes SELECT 3001,2001,id_permissao FROM tb_business_permissoes WHERE codigo='events.view';
SELECT pg_temp.reject($q$INSERT INTO tb_conta_gestao_equipe_permissoes SELECT 3001,2001,id_permissao FROM tb_business_permissoes WHERE codigo='ads.campaigns.view'$q$,'23503');
DELETE FROM tb_conta_gestao_permissoes WHERE id_vinculo=2001;
DO $test$ BEGIN IF EXISTS(SELECT 1 FROM tb_conta_gestao_equipe_permissoes) THEN RAISE EXCEPTION 'removed relationship grant survives in team'; END IF; END $test$;
INSERT INTO tb_conta_gestao_convites(id_convite,tipo,id_conta,id_vinculo,email_destinatario,token_hash,id_usuario_autor)
VALUES(5001,'TITULAR',102,2001,'client@example.test',repeat('a',64),902);
SELECT pg_temp.reject($q$INSERT INTO tb_conta_gestao_convites(tipo,id_conta,email_destinatario,token_hash,id_usuario_autor) VALUES('TITULAR',102,'other@example.test',repeat('b',64),902)$q$,'23505');
SELECT pg_temp.reject($q$UPDATE tb_conta_gestao_convites SET status='UNKNOWN' WHERE id_convite=5001$q$,'23514');
SELECT pg_temp.reject($q$UPDATE tb_conta_gestao_convites SET token_hash='raw-token' WHERE id_convite=5001$q$,'23514');
SELECT pg_temp.reject($q$UPDATE tb_conta_gestao_convites SET email_destinatario=' Client@Example.test ' WHERE id_convite=5001$q$,'23514');
UPDATE tb_conta_gestao_convites SET status='CANCELADO' WHERE id_convite=5001;
INSERT INTO tb_conta_gestao_convites(tipo,id_conta,email_destinatario,token_hash,id_usuario_autor) VALUES('TITULAR',102,'client@example.test',repeat('b',64),902);
DO $test$ BEGIN
 IF (SELECT expires_at-created_at FROM tb_conta_gestao_convites WHERE id_convite=5001)<>interval '7 days' THEN RAISE EXCEPTION 'invitation expiry'; END IF;
 IF (SELECT version FROM tb_conta_gestoras WHERE id_conta=101)<>1 OR (SELECT version FROM tb_conta_gestao_equipe WHERE id_equipe=3001)<>1 THEN RAISE EXCEPTION 'version defaults'; END IF;
END $test$;
INSERT INTO tb_conta_gestao_auditoria(id_usuario_ator,id_conta_gestora,id_conta_cliente,id_vinculo,acao,recurso_tipo,recurso_id,resultado)
 VALUES(903,101,102,2001,'synthetic.grant','ASSIGNMENT','3001','SUCCESS');
DELETE FROM tb_conta_usuarios WHERE id_conta_usuario=1002;
DO $test$ BEGIN
 IF EXISTS(SELECT 1 FROM tb_conta_gestao_equipe WHERE id_equipe=3001) THEN RAISE EXCEPTION 'deleted membership assignment survives'; END IF;
 IF NOT EXISTS(SELECT 1 FROM tb_conta_gestao_auditoria WHERE recurso_tipo='ASSIGNMENT' AND recurso_id='3001') THEN RAISE EXCEPTION 'membership removal lost historical audit'; END IF;
END $test$;
ROLLBACK;
SELECT 'PASS schema SQL invariants and preserved direct data';
