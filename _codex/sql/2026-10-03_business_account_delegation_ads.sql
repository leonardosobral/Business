-- Install only after read-only preflight/backup and the delegation schema.
-- The immutable baseline below was recovered with pg_get_functiondef/owner/ACL.
-- No historical Ads migration, ownership change, GRANT or role change occurs here.
BEGIN;
DO $preflight$
DECLARE f oid := pg_catalog.to_regprocedure('ads.paid_banner_actor_allowed(bigint,integer)'); t text;
BEGIN
 IF f IS NULL OR pg_catalog.pg_get_functiondef(f) IS DISTINCT FROM $baseline$CREATE OR REPLACE FUNCTION ads.paid_banner_actor_allowed(p_account_id bigint, p_actor_id integer)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
SELECT EXISTS(SELECT 1 FROM public.tb_usuarios u WHERE u.id=p_actor_id AND (coalesce(u.is_admin,false) OR coalesce(u.is_dev,false))) OR EXISTS(SELECT 1 FROM public.tb_conta_usuarios m WHERE m.id_conta=p_account_id AND m.id_usuario=p_actor_id AND m.status::text='ATIVO' AND m.papel::text IN('OWNER','ADMIN','OPERADOR'));
$function$
$baseline$
 OR (SELECT pg_catalog.pg_get_userbyid(proowner) FROM pg_catalog.pg_proc WHERE oid=f) IS DISTINCT FROM 'ads_owner'
 OR (SELECT proacl::text FROM pg_catalog.pg_proc WHERE oid=f) IS DISTINCT FROM '{ads_owner=X/ads_owner}'
 THEN RAISE EXCEPTION 'Ads delegation baseline drift: definition, owner or ACL differs'; END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_roles WHERE rolname=current_user AND rolsuper)
    AND NOT pg_catalog.pg_has_role(current_user,'ads_owner','USAGE') THEN RAISE EXCEPTION 'Ads delegation replacement privilege required'; END IF;
 IF NOT pg_catalog.has_schema_privilege(current_user,'public','CREATE') THEN RAISE EXCEPTION 'Ads delegation public CREATE privilege required'; END IF;
 IF pg_catalog.to_regprocedure('public.business_gestao_ads_allowed(bigint,integer)') IS NOT NULL THEN RAISE EXCEPTION 'Ads delegation helper already exists; verify installed migration instead of overwriting'; END IF;
 FOREACH t IN ARRAY ARRAY['tb_usuarios','tb_contas','tb_conta_usuarios','tb_conta_gestoras','tb_conta_gestao_vinculos','tb_conta_gestao_equipe','tb_business_permissoes','tb_conta_gestao_permissoes','tb_conta_gestao_equipe_permissoes'] LOOP
  IF NOT pg_catalog.has_table_privilege('ads_owner','public.'||t,'SELECT') THEN RAISE EXCEPTION 'Ads delegation SELECT privilege missing for ads_owner on %',t; END IF;
 END LOOP;
 IF pg_catalog.to_regclass('public.tb_usuarios_gestao') IS NOT NULL AND NOT pg_catalog.has_table_privilege('ads_owner','public.tb_usuarios_gestao','SELECT') THEN RAISE EXCEPTION 'Ads delegation actor status SELECT privilege missing'; END IF;
END $preflight$;

CREATE FUNCTION public.business_gestao_ads_allowed(p_account_id bigint,p_actor_id integer)
RETURNS boolean LANGUAGE plpgsql STABLE SECURITY INVOKER SET search_path=pg_catalog
AS $function$
DECLARE ctx jsonb; k text; allowed boolean;
BEGIN
 -- This setting conveys a selection, never a grant. All authority is re-read below.
 BEGIN ctx := nullif(pg_catalog.current_setting('business.delegation_context',true),'')::jsonb;
 EXCEPTION WHEN invalid_text_representation THEN RETURN false; END;
 IF ctx IS NULL OR pg_catalog.jsonb_typeof(ctx)<>'object' OR ctx->'enabled' IS DISTINCT FROM 'true'::jsonb
    OR ctx->>'accessMode' IS DISTINCT FROM 'DELEGATED' OR pg_catalog.jsonb_typeof(ctx->'versions') IS DISTINCT FROM 'object' THEN RETURN false; END IF;
 FOREACH k IN ARRAY ARRAY['actorId','accountId','managerAccountId','relationshipId'] LOOP
  IF coalesce(ctx->>k,'') !~ '^[1-9][0-9]{0,18}$' THEN RETURN false; END IF;
 END LOOP;
 FOREACH k IN ARRAY ARRAY['managerVersion','relationshipVersion','assignmentVersion','membershipId'] LOOP
  IF coalesce(ctx->'versions'->>k,'') !~ '^[1-9][0-9]{0,18}$' THEN RETURN false; END IF;
 END LOOP;
 BEGIN
  IF (ctx->>'actorId')::bigint IS DISTINCT FROM p_actor_id::bigint OR (ctx->>'accountId')::bigint IS DISTINCT FROM p_account_id THEN RETURN false; END IF;
  SELECT EXISTS(
   SELECT 1 FROM public.tb_usuarios u
   JOIN public.tb_conta_usuarios m ON m.id_usuario=u.id
   JOIN public.tb_contas manager_account ON manager_account.id_conta=m.id_conta AND manager_account.status::text='ATIVA'
   JOIN public.tb_conta_gestoras manager ON manager.id_conta=m.id_conta AND manager.habilitada
   JOIN public.tb_conta_gestao_vinculos v ON v.id_conta_gestora=manager.id_conta
   JOIN public.tb_contas client ON client.id_conta=v.id_conta_cliente AND client.status::text='ATIVA'
   JOIN public.tb_conta_gestao_equipe e ON e.id_vinculo=v.id_vinculo AND e.id_conta_usuario=m.id_conta_usuario
   JOIN public.tb_conta_gestao_permissoes grant_client ON grant_client.id_vinculo=v.id_vinculo
   JOIN public.tb_conta_gestao_equipe_permissoes grant_member ON grant_member.id_vinculo=v.id_vinculo AND grant_member.id_equipe=e.id_equipe AND grant_member.id_permissao=grant_client.id_permissao
   JOIN public.tb_business_permissoes p ON p.id_permissao=grant_client.id_permissao AND p.ativo AND p.codigo='ads.campaigns.manage'
   WHERE u.id=p_actor_id AND client.id_conta=p_account_id
    AND manager.id_conta=(ctx->>'managerAccountId')::bigint AND v.id_vinculo=(ctx->>'relationshipId')::bigint
    AND m.id_conta_usuario=(ctx->'versions'->>'membershipId')::bigint
    AND manager.version=(ctx->'versions'->>'managerVersion')::bigint AND v.version=(ctx->'versions'->>'relationshipVersion')::bigint AND e.version=(ctx->'versions'->>'assignmentVersion')::bigint
    AND m.status::text='ATIVO' AND m.papel::text IN('OWNER','ADMIN','OPERADOR') AND v.status='ATIVO' AND e.status='ATIVO'
  ) INTO allowed;
 EXCEPTION WHEN numeric_value_out_of_range OR invalid_text_representation THEN RETURN false; END;
 IF NOT allowed THEN RETURN false; END IF;
 -- Older installations have no optional actor-status table; match the service boundary.
 IF pg_catalog.to_regclass('public.tb_usuarios_gestao') IS NOT NULL THEN
  EXECUTE 'SELECT NOT EXISTS(SELECT 1 FROM public.tb_usuarios_gestao WHERE id_usuario=$1 AND (NOT coalesce(ativo,true) OR coalesce(excluido,false)))' INTO allowed USING p_actor_id;
 END IF;
 RETURN allowed;
END;
$function$;

CREATE OR REPLACE FUNCTION ads.paid_banner_actor_allowed(p_account_id bigint,p_actor_id integer)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog
AS $function$
SELECT CASE WHEN nullif(pg_catalog.current_setting('business.delegation_context',true),'') IS NOT NULL
 THEN public.business_gestao_ads_allowed(p_account_id,p_actor_id)
 ELSE EXISTS(SELECT 1 FROM public.tb_usuarios u WHERE u.id=p_actor_id AND (coalesce(u.is_admin,false) OR coalesce(u.is_dev,false))) OR EXISTS(SELECT 1 FROM public.tb_conta_usuarios m WHERE m.id_conta=p_account_id AND m.id_usuario=p_actor_id AND m.status::text='ATIVO' AND m.papel::text IN('OWNER','ADMIN','OPERADOR')) END;
$function$;
DO $verify$
BEGIN
 IF NOT pg_catalog.has_function_privilege('ads_owner','public.business_gestao_ads_allowed(bigint,integer)','EXECUTE') THEN RAISE EXCEPTION 'Ads delegation helper EXECUTE privilege missing'; END IF;
 IF (SELECT pg_catalog.pg_get_userbyid(proowner) FROM pg_catalog.pg_proc WHERE oid='ads.paid_banner_actor_allowed(bigint,integer)'::regprocedure) IS DISTINCT FROM 'ads_owner'
 OR (SELECT proacl::text FROM pg_catalog.pg_proc WHERE oid='ads.paid_banner_actor_allowed(bigint,integer)'::regprocedure) IS DISTINCT FROM '{ads_owner=X/ads_owner}' THEN RAISE EXCEPTION 'Ads delegation owner/ACL preservation failed'; END IF;
END $verify$;
COMMIT;
