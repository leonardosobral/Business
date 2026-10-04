<cfscript>
dsn=application.delegationTest.datasource;
function db(required string sql,struct params={}){return queryExecute(sql,params,{datasource=application.delegationTest.datasource});}
 db("CREATE TYPE tipo_titular_conta AS ENUM('PF','PJ')");
 db("CREATE TYPE status_conta AS ENUM('PENDENTE','ATIVA','SUSPENSA','CANCELADA')");
 db("CREATE TYPE status_conta_cadastro_solicitacao AS ENUM('PENDENTE','APROVADA','RECUSADA')");
 db("CREATE TYPE status_usuario_conta AS ENUM('ATIVO','INATIVO','CONVIDADO','BLOQUEADO')");
 db("CREATE SEQUENCE receiver_fixture_ids START 5000");
 db("ALTER TABLE tb_contas ALTER COLUMN id_conta SET DEFAULT nextval('receiver_fixture_ids'), ADD COLUMN tipo_titular tipo_titular_conta, ADD COLUMN documento varchar(20) UNIQUE, ADD COLUMN nome_titular varchar(200), ADD COLUMN email_principal varchar(255), ADD COLUMN telefone_principal varchar(30), ADD COLUMN data_atualizacao timestamptz DEFAULT now()");
 db("ALTER TABLE tb_conta_usuarios ALTER COLUMN id_conta_usuario SET DEFAULT nextval('receiver_fixture_ids'), ADD COLUMN usuario_convite bigint, ADD COLUMN data_convite timestamptz, ADD COLUMN data_aceite timestamptz, ADD COLUMN data_atualizacao timestamptz DEFAULT now()");
 db("ALTER TABLE tb_conta_cadastro_solicitacoes ALTER COLUMN id_solicitacao SET DEFAULT nextval('receiver_fixture_ids'), ADD COLUMN nome_empresa varchar(160), ADD COLUMN tipo_titular tipo_titular_conta, ADD COLUMN documento varchar(20), ADD COLUMN nome_responsavel varchar(200), ADD COLUMN email_responsavel varchar(255), ADD COLUMN telefone_responsavel varchar(30), ADD COLUMN site varchar(256), ADD COLUMN cidade varchar(128), ADD COLUMN estado varchar(2), ADD COLUMN tipo_prestador varchar(80), ADD COLUMN mensagem text, ADD COLUMN id_usuario_revisor bigint, ADD COLUMN data_revisao timestamptz");
db("CREATE TABLE ads.tb_ad_vouchers(id_conta bigint,credito numeric)");
db("ALTER TABLE tb_usuarios ADD CONSTRAINT receiver_email_unique UNIQUE(email), ADD COLUMN imagem_usuario text, ADD COLUMN password text, ADD COLUMN verification_key text, ADD COLUMN is_email_verified boolean DEFAULT false, ADD COLUMN optin_usuario boolean DEFAULT false, ADD COLUMN data_alteracao timestamptz DEFAULT now()");
db("ALTER TABLE tb_usuarios ALTER COLUMN id SET DEFAULT nextval('receiver_fixture_ids')");
db("ALTER TABLE tb_contas ALTER COLUMN status TYPE status_conta USING CAST(status AS status_conta)");
db("ALTER TABLE tb_conta_usuarios ALTER COLUMN status TYPE status_usuario_conta USING CAST(status AS status_usuario_conta)");
db("ALTER TABLE tb_conta_cadastro_solicitacoes ALTER COLUMN status TYPE status_conta_cadastro_solicitacao USING CAST(status AS status_conta_cadastro_solicitacao)");
db("CREATE TABLE tb_log(log_item text,log_item_id text,log_user text,site text)");

db("ALTER TABLE tb_contas ADD COLUMN data_criacao timestamptz DEFAULT now()");
db("ALTER TABLE tb_conta_cadastro_solicitacoes ADD COLUMN data_criacao timestamptz DEFAULT now()");
db("ALTER TABLE tb_usuarios ADD COLUMN strava_id text,ADD COLUMN aka text,ADD COLUMN fonte_lead text,ADD COLUMN strava_profile text,ADD COLUMN partner_info text");
db("CREATE TYPE status_conta_evento AS ENUM('ATIVO','INATIVO')");
db("ALTER TABLE tb_conta_eventos ALTER COLUMN status TYPE status_conta_evento USING CAST(status AS status_conta_evento)");
db("CREATE TABLE tb_paginas_usuarios(id_pagina integer,id_usuario integer)");
db("CREATE TABLE tb_paginas(id_pagina integer,nome text,path_imagem text,tag text,tag_prefix text,verificado boolean,cidade text,uf text,instagram text,youtube text,tiktok text,website text,loja text,whatsapp text,whatsapp_publico boolean,descricao text)");
db("CREATE TABLE tb_notifica(id_notifica integer,id_usuario integer,data_publicacao timestamptz,data_expiracao timestamptz,data_leitura timestamptz,id_notifica_template integer,link text,icone text,conteudo_notifica text)");
db("CREATE TABLE tb_notifica_template(id_notifica_template integer,link text,icone text,conteudo_template text)");
db("CREATE TABLE tb_permissoes(id_permissao integer,id_usuario integer,tag text,tipo text)");
db("CREATE TABLE tb_temas(id_tema integer)");
db("CREATE TABLE tb_bi(bi_tag text,id_tema integer,ordem integer,bi_nome text)");
db("CREATE TABLE tb_agregadores(agregador_tag text,id_tema integer,ordem integer,agregador_nome text)");
db("CREATE TABLE tb_agrega_eventos(tag text,id_tema integer,ordem integer,tipo_agregacao text,nome_evento_agregado text)");
db("INSERT INTO tb_usuarios(id,name,email) VALUES(907,'New Owner','new@example.test'),(908,'Pending Owner','pending@example.test')");
db("INSERT INTO tb_conta_usuarios(id_conta_usuario,id_conta,id_usuario,papel,status) VALUES(1008,102,902,'VISUALIZADOR','ATIVO')");
db("UPDATE tb_usuarios SET is_admin=true WHERE id=901");
// Canonical production functions own accesses to the new synthetic columns/tables.
db("GRANT SELECT ON ALL TABLES IN SCHEMA public TO ads_owner; GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA public TO runnerhub; GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO runnerhub");
</cfscript>
