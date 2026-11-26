CREATE OR REPLACE FUNCTION ads.paid_banner_actor_allowed(p_account_id bigint, p_actor_id integer)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
SELECT CASE WHEN nullif(pg_catalog.current_setting('business.delegation_context',true),'') IS NOT NULL
 THEN public.business_gestao_ads_allowed(p_account_id,p_actor_id)
 ELSE EXISTS(SELECT 1 FROM public.tb_usuarios u WHERE u.id=p_actor_id AND (coalesce(u.is_admin,false) OR coalesce(u.is_dev,false))) OR EXISTS(SELECT 1 FROM public.tb_conta_usuarios m WHERE m.id_conta=p_account_id AND m.id_usuario=p_actor_id AND m.status::text='ATIVO' AND m.papel::text IN('OWNER','ADMIN','OPERADOR')) END;
$function$
