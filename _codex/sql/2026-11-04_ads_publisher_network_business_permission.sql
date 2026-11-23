-- Complemento para instalações que aplicaram a primeira versão do inventário.
-- Somente EXECUTE em duas funções do schema ads; sem grants em tabelas,
-- associação a roles, alteração de saldo ou mudança nas regras de autorização.
-- Ambas as funções continuam exigindo administrador global e recusam delegação.
BEGIN;
SET LOCAL lock_timeout='5s';
SET LOCAL statement_timeout='15s';
GRANT EXECUTE ON FUNCTION
 ads.save_publisher_site(uuid,integer,bigint,text,text,text[],text),
 ads.save_publisher_spot(uuid,integer,bigint,uuid,text,text,text,text,integer,integer,text)
TO ads_business;
INSERT INTO ads.schema_migrations(migration_key,description)
VALUES('2026-11-04_ads_publisher_network_business_permission',
 'Execucao do cadastro de sites e spots pelo Business, com validacao de administrador nas funcoes')
ON CONFLICT(migration_key) DO NOTHING;
COMMIT;
