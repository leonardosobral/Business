-- Stable synthetic IDs; never copied from production. Baseline counts: accounts=4, memberships=6, requests=1.
INSERT INTO tb_usuarios(id,name,email) VALUES
 (901,'Internal Reviewer','reviewer@example.test'),(902,'Manager Owner','owner@example.test'),
 (903,'Manager Operator','operator@example.test'),(904,'Client Owner','client@example.test'),
 (905,'Manager Viewer','viewer@example.test'),(906,'Manager Medic','medic@example.test');
INSERT INTO tb_contas(id_conta,nome_conta,status) VALUES
 (101,'Manager One','ATIVA'),(102,'Client One','ATIVA'),(103,'Manager Two','ATIVA'),(104,'Pending Client','PENDENTE');
INSERT INTO tb_conta_usuarios(id_conta_usuario,id_conta,id_usuario,papel,status) VALUES
 (1001,101,902,'OWNER','ATIVO'),(1002,101,903,'OPERADOR','ATIVO'),
 (1003,102,904,'OWNER','ATIVO'),(1004,103,902,'ADMIN','ATIVO'),
 (1005,101,905,'VISUALIZADOR','ATIVO'),(1006,101,906,'MEDICO','ATIVO');
INSERT INTO tb_conta_cadastro_solicitacoes(id_solicitacao,id_conta,id_usuario,status) VALUES(4001,104,904,'PENDENTE');
-- SELECT count(*) FROM tb_conta_usuarios WHERE id_conta=102; -- 1, preserved by migration.
-- SELECT count(*) FROM tb_conta_cadastro_solicitacoes WHERE id_solicitacao=4001; -- 1.

-- DELEGATION_FIXTURES
-- Applied only after migration preservation tests.
INSERT INTO tb_conta_gestoras(id_conta,classificacao,habilitada,id_usuario_autor) VALUES(101,'AGENCIA',true,901),(103,'TICKETEIRA',true,901);
INSERT INTO tb_conta_gestao_vinculos(id_vinculo,id_conta_gestora,id_conta_cliente,origem,status,id_usuario_solicitante,capacidades_propostas) VALUES
 (2001,101,102,'CONVITE_CLIENTE','ATIVO',904,'["ads.campaigns.view","ads.campaigns.manage","ads.payments.view","ads.credits.purchase","events.view","events.manage","events.links.request"]'),
 (2002,103,102,'CONVITE_CLIENTE','ATIVO',904,'["events.view"]'),
 (2003,101,104,'CRIACAO_GESTORA','AGUARDANDO_CONTA',902,'["events.view"]');
INSERT INTO tb_conta_gestao_permissoes SELECT 2001,id_permissao FROM tb_business_permissoes;
INSERT INTO tb_conta_gestao_permissoes SELECT 2002,id_permissao FROM tb_business_permissoes WHERE codigo='events.view';
INSERT INTO tb_conta_gestao_equipe(id_equipe,id_vinculo,id_conta_usuario,status) VALUES
 (3001,2001,1001,'ATIVO'),(3002,2001,1002,'ATIVO'),(3003,2001,1005,'ATIVO'),(3004,2002,1004,'ATIVO');
INSERT INTO tb_conta_gestao_equipe_permissoes SELECT 3001,2001,id_permissao FROM tb_conta_gestao_permissoes WHERE id_vinculo=2001;
INSERT INTO tb_conta_gestao_equipe_permissoes SELECT 3002,2001,id_permissao FROM tb_business_permissoes WHERE codigo IN('events.view','events.manage');
INSERT INTO tb_conta_gestao_equipe_permissoes SELECT 3003,2001,id_permissao FROM tb_business_permissoes WHERE codigo IN('ads.campaigns.view','events.view');
INSERT INTO tb_conta_gestao_equipe_permissoes SELECT 3004,2002,id_permissao FROM tb_business_permissoes WHERE codigo='events.view';
SELECT setval(pg_get_serial_sequence('tb_conta_gestao_vinculos','id_vinculo'),2100);
SELECT setval(pg_get_serial_sequence('tb_conta_gestao_equipe','id_equipe'),3100);
UPDATE tb_conta_cadastro_solicitacoes SET origem_gestora_id=101,gestao_vinculo_id=2003 WHERE id_solicitacao=4001;
-- SELECT count(*) FROM tb_conta_gestao_vinculos; -- 3
-- SELECT count(*) FROM tb_conta_gestao_equipe; -- 4
-- SELECT count(*) FROM tb_conta_usuarios WHERE id_conta=102; -- still 1
