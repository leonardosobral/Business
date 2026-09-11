-- PostgreSQL 16. Executar integralmente pelo operador no DataGrip, na base runnerhub,
-- depois da migração de retenção. Parar no primeiro erro e executar ROLLBACK.
-- Cria somente a identidade dedicada; não agenda nem executa a exclusão.
-- Configurar a senha privadamente no DataGrip/gestor de usuários, fora do Git e do chat.
-- PASSWORD NULL impede autenticação por senha até essa configuração; outros métodos
-- de autenticação dependem das regras existentes do servidor.
BEGIN;

DO $guard$
BEGIN
 IF current_database() <> 'runnerhub' THEN
  RAISE EXCEPTION 'Execute este arquivo somente na base runnerhub';
 END IF;

 IF NOT EXISTS (
  SELECT 1 FROM pg_catalog.pg_roles
  WHERE rolname = 'audience_maintenance_executor'
    AND NOT (rolcanlogin OR rolsuper OR rolcreatedb OR rolcreaterole OR rolreplication OR rolbypassrls)
 ) OR EXISTS (
  SELECT 1 FROM pg_catalog.pg_auth_members m
  JOIN pg_catalog.pg_roles r ON r.oid = m.member
  WHERE r.rolname = 'audience_maintenance_executor'
 ) THEN
  RAISE EXCEPTION 'Executor ausente ou fora do contrato NOLOGIN sem privilégios globais/memberships; revisão DBA necessária';
 END IF;

 IF to_regclass('audience.events') IS NULL
    OR to_regprocedure('audience.purge_expired_events(integer)') IS NULL THEN
  RAISE EXCEPTION 'A migração de retenção deve estar instalada antes deste arquivo';
 END IF;

 IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'rr_audience_retention_job') THEN
  RAISE EXCEPTION 'rr_audience_retention_job já existe; revisar a identidade existente sem sobrescrevê-la';
 END IF;
END $guard$;

CREATE ROLE rr_audience_retention_job
 LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT NOREPLICATION NOBYPASSRLS
 CONNECTION LIMIT 2 PASSWORD NULL;
GRANT CONNECT ON DATABASE runnerhub TO rr_audience_retention_job;
GRANT audience_maintenance_executor TO rr_audience_retention_job;

COMMIT;

-- Verificação somente de metadados. Esperado: true, false, true, true, false.
-- Se algum valor divergir, interromper o provisionamento operacional e revisar com o DBA.
SELECT r.rolname,
       r.rolcanlogin AS job_can_login,
       r.rolsuper AS job_is_superuser,
       pg_has_role(r.oid, 'audience_maintenance_executor', 'MEMBER') AS executor_member,
       has_function_privilege(r.oid, 'audience.purge_expired_events(integer)', 'EXECUTE') AS can_execute_retention,
       has_table_privilege(r.oid, 'audience.events', 'DELETE') AS can_delete_events_directly
FROM pg_catalog.pg_roles r
WHERE r.rolname = 'rr_audience_retention_job';
