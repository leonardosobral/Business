-- Catches direct-only rejection, actor substitution, selected-path fallback and stale grants.
BEGIN;
DO $quiet$ BEGIN PERFORM set_config('business.delegation_context','{"enabled":true,"accessMode":"DELEGATED","actorId":"902","accountId":"102","managerAccountId":"101","relationshipId":"2001","versions":{"managerVersion":"1","relationshipVersion":"1","assignmentVersion":"1","membershipId":"1001"}}',true); END $quiet$;
CREATE TEMP TABLE delegated_banner AS SELECT * FROM ads.save_paid_banner_campaign(NULL,102,902,
 jsonb_build_object('name','Delegated actual actor','placement_key','rr-sidebar-banner-300x250','image_url_desktop','https://example.test/d.png','width_desktop',300,'height_desktop',250,'image_url_mobile','https://example.test/m.png','width_mobile',300,'height_mobile',250,'alt_text','Fixture brand','destination_url','https://example.test/brand','open_new_tab',false,'starts_at',now()-interval '1 hour','ends_at',now()+interval '1 day','cpc_bid',1,'budget_total',10,'budget_daily',5,'target_device','ALL','banner_scope_v1',jsonb_build_object('regions_mode','ALL','regions','[]'::jsonb,'pages_mode','ALL','pages','[]'::jsonb)),false);
DO $test$ DECLARE c uuid; BEGIN
 SELECT campaign_id INTO c FROM delegated_banner;
 IF NOT EXISTS(SELECT 1 FROM ads.campaigns WHERE campaign_id=c AND created_by=902 AND updated_by=902 AND account_id=102) THEN RAISE EXCEPTION 'Actual actor was replaced'; END IF;
 PERFORM ads.submit_paid_banner_review(c,102,902);
 BEGIN PERFORM ads.review_paid_banner_campaign(c,'APPROVE',902,'self','delegated-self',NULL); RAISE EXCEPTION 'Unauthorized self approval';
 EXCEPTION WHEN OTHERS THEN IF SQLERRM='Unauthorized self approval' OR SQLERRM NOT ILIKE '%administr%' THEN RAISE; END IF; END;
END $test$;
ROLLBACK;
SELECT 'PASS ads-db canonical save/submit preserves actual actor; self review denied';

BEGIN;
DO $test$
DECLARE good jsonb := '{"enabled":true,"accessMode":"DELEGATED","actorId":"902","accountId":"102","managerAccountId":"101","relationshipId":"2001","versions":{"managerVersion":"1","relationshipVersion":"1","assignmentVersion":"1","membershipId":"1001"}}'; bad text; k text;
BEGIN
 IF public.business_gestao_ads_allowed(102,902) THEN RAISE EXCEPTION 'Absent context authorized'; END IF;
 PERFORM set_config('business.delegation_context',good::text,true);
 IF NOT public.business_gestao_ads_allowed(102,902) THEN RAISE EXCEPTION 'Valid context denied'; END IF;
 IF public.business_gestao_ads_allowed(101,902) OR public.business_gestao_ads_allowed(102,904) THEN RAISE EXCEPTION 'Actor/account binding bypass'; END IF;
 FOREACH bad IN ARRAY ARRAY['{','null','[]','{}','false',(good-'enabled')::text,jsonb_set(good,'{enabled}','false')::text,jsonb_set(good,'{enabled}','"true"')::text,jsonb_set(good,'{relationshipId}','"2002"')::text,jsonb_set(good,'{relationshipId}','"2003"')::text,jsonb_set(good,'{managerAccountId}','"103"')::text,jsonb_set(good,'{accountId}','"9999999999999999999"')::text] LOOP
  PERFORM set_config('business.delegation_context',bad,true);
  IF public.business_gestao_ads_allowed(102,902) THEN RAISE EXCEPTION 'Invalid context authorized: %',bad; END IF;
 END LOOP;
 FOREACH k IN ARRAY ARRAY['managerVersion','relationshipVersion','assignmentVersion','membershipId'] LOOP
  PERFORM set_config('business.delegation_context',jsonb_set(good,ARRAY['versions',k],'"2"')::text,true);
  IF public.business_gestao_ads_allowed(102,902) THEN RAISE EXCEPTION 'Stale version authorized: %',k; END IF;
  PERFORM set_config('business.delegation_context',(good #- ARRAY['versions',k])::text,true);
  IF public.business_gestao_ads_allowed(102,902) THEN RAISE EXCEPTION 'Incomplete stamp authorized: %',k; END IF;
 END LOOP;
 PERFORM set_config('business.delegation_context',good::text,true);
 UPDATE public.tb_conta_gestoras SET habilitada=false WHERE id_conta=101;
 IF public.business_gestao_ads_allowed(102,902) THEN RAISE EXCEPTION 'Disabled manager authorized'; END IF;
 UPDATE public.tb_conta_gestoras SET habilitada=true WHERE id_conta=101;
 UPDATE public.tb_conta_gestao_vinculos SET status='SUSPENSO' WHERE id_vinculo=2001;
 IF public.business_gestao_ads_allowed(102,902) THEN RAISE EXCEPTION 'Suspended relationship authorized'; END IF;
 UPDATE public.tb_conta_gestao_vinculos SET status='ATIVO' WHERE id_vinculo=2001;
 UPDATE public.tb_conta_gestao_equipe SET status='REMOVIDO' WHERE id_equipe=3001;
 IF public.business_gestao_ads_allowed(102,902) THEN RAISE EXCEPTION 'Removed assignment authorized'; END IF;
 UPDATE public.tb_conta_gestao_equipe SET status='ATIVO' WHERE id_equipe=3001;
 UPDATE public.tb_conta_usuarios SET papel='VISUALIZADOR' WHERE id_conta_usuario=1001;
 IF public.business_gestao_ads_allowed(102,902) THEN RAISE EXCEPTION 'Viewer authorized manage'; END IF;
 UPDATE public.tb_conta_usuarios SET papel='OWNER',status='REMOVIDO' WHERE id_conta_usuario=1001;
 IF public.business_gestao_ads_allowed(102,902) THEN RAISE EXCEPTION 'Removed membership authorized'; END IF;
 UPDATE public.tb_conta_usuarios SET status='ATIVO' WHERE id_conta_usuario=1001;
 UPDATE public.tb_contas SET status='PENDENTE' WHERE id_conta IN(101,102);
 IF public.business_gestao_ads_allowed(102,902) THEN RAISE EXCEPTION 'Inactive account authorized'; END IF;
 UPDATE public.tb_contas SET status='ATIVA' WHERE id_conta IN(101,102);
 UPDATE public.tb_business_permissoes SET ativo=false WHERE codigo='ads.campaigns.manage';
 IF public.business_gestao_ads_allowed(102,902) THEN RAISE EXCEPTION 'Disabled catalogue grant authorized'; END IF;
 UPDATE public.tb_business_permissoes SET ativo=true WHERE codigo='ads.campaigns.manage';
 DELETE FROM public.tb_conta_gestao_equipe_permissoes WHERE id_equipe=3001 AND id_permissao=(SELECT id_permissao FROM public.tb_business_permissoes WHERE codigo='ads.campaigns.manage');
 IF public.business_gestao_ads_allowed(102,902) THEN RAISE EXCEPTION 'Missing member grant authorized'; END IF;
 INSERT INTO public.tb_conta_gestao_equipe_permissoes SELECT 3001,2001,id_permissao FROM public.tb_business_permissoes WHERE codigo='ads.campaigns.manage';
 DELETE FROM public.tb_conta_gestao_permissoes WHERE id_vinculo=2001 AND id_permissao=(SELECT id_permissao FROM public.tb_business_permissoes WHERE codigo='ads.campaigns.manage');
 IF public.business_gestao_ads_allowed(102,902) THEN RAISE EXCEPTION 'Missing client grant authorized'; END IF;
END $test$;
ROLLBACK;
BEGIN;
CREATE TABLE public.tb_usuarios_gestao(id_usuario integer PRIMARY KEY,ativo boolean,excluido boolean);
INSERT INTO public.tb_usuarios_gestao VALUES(902,false,false);
DO $quiet$ BEGIN PERFORM set_config('business.delegation_context','{"enabled":true,"accessMode":"DELEGATED","actorId":"902","accountId":"102","managerAccountId":"101","relationshipId":"2001","versions":{"managerVersion":"1","relationshipVersion":"1","assignmentVersion":"1","membershipId":"1001"}}',true); END $quiet$;
DO $test$ BEGIN IF public.business_gestao_ads_allowed(102,902) THEN RAISE EXCEPTION 'Inactive actor authorized'; END IF; END $test$;
ROLLBACK;
-- A selected invalid delegated context must never inherit direct/internal powers.
BEGIN;
UPDATE public.tb_usuarios SET is_admin=true,is_dev=true WHERE id=904;
DO $quiet$ BEGIN PERFORM set_config('business.delegation_context','{',true); END $quiet$;
DO $test$ BEGIN IF ads.paid_banner_actor_allowed(102,904) THEN RAISE EXCEPTION 'Malformed context fell back to direct/internal role'; END IF; END $test$;
DO $quiet$ BEGIN PERFORM set_config('business.delegation_context','{"enabled":true,"accessMode":"DELEGATED","actorId":"904","accountId":"102","managerAccountId":"101","relationshipId":"2001","versions":{"managerVersion":"1","relationshipVersion":"1","assignmentVersion":"1","membershipId":"1001"}}',true); END $quiet$;
DO $test$ BEGIN IF ads.paid_banner_actor_allowed(102,904) THEN RAISE EXCEPTION 'Invalid selection fell back to direct/internal role'; END IF; END $test$;
DO $quiet$ BEGIN PERFORM set_config('business.delegation_context','',true); END $quiet$;
DO $test$ BEGIN IF NOT ads.paid_banner_actor_allowed(102,904) THEN RAISE EXCEPTION 'Direct/internal baseline broken'; END IF; END $test$;
ROLLBACK;
SELECT 'PASS ads-db invalid/missing context, binding, versions, DB states, capability intersection, no direct/internal fallback';
