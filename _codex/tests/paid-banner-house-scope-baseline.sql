-- HOUSE/BANNER scope only. Incremental over the September 2 EVENT auction.
-- No campaign data changes, no public-schema writes, no finance/CPC changes.
-- Keep these protective contracts installed when rolling back application code.
BEGIN;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='5min';

CREATE OR REPLACE FUNCTION ads.normalize_banner_scope(p_scope jsonb)
RETURNS jsonb LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE SET search_path=pg_catalog
AS $function$
DECLARE
  mode text; items jsonb; dimension text; normalized text[]; result jsonb:='{}';
BEGIN
  IF jsonb_typeof(p_scope) IS DISTINCT FROM 'object' THEN RETURN NULL; END IF;
  IF (SELECT count(*) FROM jsonb_object_keys(p_scope))<>4 THEN RETURN NULL; END IF;
  FOREACH dimension IN ARRAY ARRAY['regions','pages'] LOOP
    mode:=p_scope->>(dimension||'_mode'); items:=p_scope->dimension;
    IF mode IS NULL OR mode NOT IN ('ALL','SELECTED')
      OR jsonb_typeof(items) IS DISTINCT FROM 'array' THEN RETURN NULL; END IF;
    IF EXISTS(SELECT 1 FROM jsonb_array_elements(items) x WHERE jsonb_typeof(x)<>'string') THEN RETURN NULL; END IF;
    SELECT coalesce(array_agg(DISTINCT value ORDER BY value),ARRAY[]::text[]) INTO normalized
    FROM (SELECT CASE WHEN dimension='regions' THEN upper(btrim(x)) ELSE lower(btrim(x)) END value
      FROM jsonb_array_elements_text(items) x) values_normalized;
    IF (mode='ALL' AND cardinality(normalized)<>0)
      OR (mode='SELECTED' AND cardinality(normalized)=0) THEN RETURN NULL; END IF;
    IF dimension='regions' AND NOT normalized <@ ARRAY['AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'] THEN RETURN NULL; END IF;
    IF dimension='pages' AND NOT normalized <@ ARRAY['home','search','state','event','athlete'] THEN RETURN NULL; END IF;
    result:=result||jsonb_build_object(dimension||'_mode',mode,dimension,to_jsonb(normalized));
  END LOOP;
  RETURN result;
END;
$function$;

CREATE OR REPLACE FUNCTION ads.banner_scope_matches(p_metadata jsonb,p_region text,p_page text)
RETURNS boolean LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE SECURITY DEFINER SET search_path=pg_catalog
AS $function$
DECLARE scope jsonb;
BEGIN
  IF p_metadata IS NULL THEN RETURN true; END IF;
  IF jsonb_typeof(p_metadata)<>'object' THEN RETURN false; END IF;
  IF NOT p_metadata ? 'banner_scope_v1' THEN RETURN true; END IF;
  scope:=ads.normalize_banner_scope(p_metadata->'banner_scope_v1');
  IF scope IS NULL THEN RETURN false; END IF;
  RETURN coalesce((scope->>'regions_mode'='ALL' OR scope->'regions' ? upper(btrim(p_region)))
    AND (scope->>'pages_mode'='ALL' OR scope->'pages' ? lower(btrim(p_page))),false);
END;
$function$;

-- Guard known complete bodies, not loose text snippets. Strip only this migration's
-- exact additions before comparing, so reapplication is safe and drift aborts.
-- pg_get_functiondef retains ownership, signature, defaults and existing ACLs.
DO $contracts$
DECLARE
  save_oid regprocedure:=to_regprocedure('ads.save_house_banner_campaign(uuid,bigint,text,text,text,integer,integer,text,integer,integer,text,text,boolean,timestamptz,timestamptz,integer,integer,integer,bigint)');
  select_oid regprocedure:=to_regprocedure('ads.select_delivery_candidate_v2(text,timestamptz,text,character,text,integer,text,text[],uuid[])');
  serve_oid regprocedure:=to_regprocedure('ads.serve_delivery(uuid,uuid,uuid,uuid,uuid,text,timestamptz,timestamptz,smallint,integer,text,text,text,character,text,text,jsonb,timestamptz)');
  source text; baseline text; definition text; new_definition text;
  save_guard text:=$guard$    -- banner_scope_v1: institutional owner and canonical global admin actor.
    IF p_account_id IS DISTINCT FROM 1::bigint OR NOT EXISTS (
        SELECT 1 FROM public.tb_usuarios actor WHERE actor.id=p_changed_by
          AND (coalesce(actor.is_admin,false) OR coalesce(actor.is_dev,false))
    ) THEN RAISE EXCEPTION 'Somente administrador RunnerHub salva HOUSE da conta institucional'; END IF;

$guard$;
  select_metadata text:=E'           campaign.metadata AS banner_scope_metadata,\n';
  select_guard text:=E'\n                     AND ads.banner_scope_matches(candidate.banner_scope_metadata, candidate.region_code, NULL::text)';
  serve_guard text:=$guard$
    -- banner_scope_v1: revalidate the locked campaign immediately before delivery.
    IF campaign.billing_model='HOUSE' AND advertisement.ad_type='BANNER'
       AND NOT ads.banner_scope_matches(campaign.metadata,p_region_code,p_request_context->>'banner_page') THEN
        RAISE EXCEPTION 'Banner fora do escopo de pagina ou UF';
    END IF;
$guard$;
BEGIN
  IF current_user='runner' OR NOT (SELECT rolsuper FROM pg_roles WHERE rolname=current_user) THEN
    RAISE EXCEPTION 'Migration exige executor DBA separado de runner';
  END IF;
  IF save_oid IS NULL OR select_oid IS NULL OR serve_oid IS NULL
     OR NOT EXISTS(SELECT 1 FROM ads.schema_migrations WHERE migration_key='2026-09-02_ads_event_auction_ranking') THEN
    RAISE EXCEPTION 'Baseline HOUSE e leilao EVENT de 2026-09-02 obrigatorio';
  END IF;
  IF EXISTS(SELECT 1 FROM pg_proc WHERE oid IN(save_oid,select_oid,serve_oid)
      AND (proowner<>'ads_owner'::regrole OR NOT prosecdef
        OR NOT coalesce(proconfig @> ARRAY['search_path=pg_catalog'],false))) THEN
    RAISE EXCEPTION 'Owner ou configuracao SECURITY DEFINER do contrato divergente';
  END IF;
  SELECT prosrc INTO source FROM pg_proc WHERE oid=save_oid;
  baseline:=replace(source,save_guard,'');
  IF md5(baseline)<>'70a058f54d9578b0d23531ad1576c443' THEN RAISE EXCEPTION 'Baseline save_house_banner_campaign divergente'; END IF;
  definition:=replace(pg_get_functiondef(save_oid),source,replace(baseline,E'BEGIN\n',E'BEGIN\n'||save_guard));
  EXECUTE definition;

  SELECT prosrc INTO source FROM pg_proc WHERE oid=select_oid;
  baseline:=replace(replace(source,select_metadata,''),select_guard,'');
  IF md5(baseline)<>'dd39e4b47d95cf64fcef6034a48b6f64' THEN RAISE EXCEPTION 'Baseline select_delivery_candidate_v2 divergente'; END IF;
  new_definition:=replace(baseline,'           campaign.frequency_cap_count,',select_metadata||'           campaign.frequency_cap_count,');
  new_definition:=replace(new_definition,'AND advertisement.billing_model = ''HOUSE''','AND advertisement.billing_model = ''HOUSE'''||select_guard);
  definition:=replace(pg_get_functiondef(select_oid),source,new_definition);
  EXECUTE definition;

  -- The dedicated six-argument selector inherits the exact current ranking and
  -- eligibility SQL, replacing only context inputs absent from the banner API.
  definition:='CREATE OR REPLACE FUNCTION ads.select_house_banner_candidate('
    ||'p_placement_key text,p_requested_at timestamptz DEFAULT clock_timestamp(),'
    ||'p_device_class text DEFAULT ''ALL'',p_country_code character(2) DEFAULT ''BR'','
    ||'p_region_code text DEFAULT NULL,p_banner_page text DEFAULT NULL)'
    ||substring(definition FROM position(E'\n RETURNS TABLE' IN definition));
  definition:=replace(definition,'candidate.region_code, NULL::text)','candidate.region_code, p_banner_page)');
  definition:=replace(definition,'p_user_id','NULL::integer');
  definition:=replace(definition,'p_anonymous_id_hash','NULL::text');
  definition:=replace(definition,'p_allowed_ad_types','ARRAY[''BANNER'']::text[]');
  definition:=replace(definition,'p_excluded_campaign_ids','ARRAY[]::uuid[]');
  EXECUTE definition;

  SELECT prosrc INTO source FROM pg_proc WHERE oid=serve_oid;
  baseline:=replace(source,serve_guard,'');
  IF md5(baseline)<>'ff5432fde3cacf729a7a79673c8dbe9e' THEN RAISE EXCEPTION 'Baseline serve_delivery divergente'; END IF;
  definition:=replace(pg_get_functiondef(serve_oid),source,replace(baseline,
    '    selected_placement := eligible_entities.current_placement;',
    '    selected_placement := eligible_entities.current_placement;'||serve_guard));
  EXECUTE definition;
END;
$contracts$;

CREATE OR REPLACE FUNCTION ads.save_house_banner_campaign_v2(
    p_campaign_id uuid,p_account_id bigint,p_placement_key text,p_name text,
    p_desktop_image_url text,p_desktop_width integer,p_desktop_height integer,
    p_mobile_image_url text,p_mobile_width integer,p_mobile_height integer,
    p_alt_text text,p_destination_url text,p_open_in_new_tab boolean,
    p_starts_at timestamptz,p_ends_at timestamptz,p_weight integer DEFAULT 1,
    p_priority integer DEFAULT 1,p_changed_by integer DEFAULT NULL,
    p_legacy_banner_id bigint DEFAULT NULL,p_scope jsonb DEFAULT NULL
)
RETURNS TABLE(campaign_id uuid,advertisement_id uuid,creative_id uuid,placement_id uuid,campaign_status text,result_status text)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog
AS $function$
DECLARE scope jsonb; saved record;
BEGIN
    scope:=ads.normalize_banner_scope(p_scope);
    IF scope IS NULL THEN RAISE EXCEPTION 'Escopo de banner invalido; selecao especifica exige paginas ou UFs validas'; END IF;
    SELECT result.* INTO saved FROM ads.save_house_banner_campaign(
      p_campaign_id,p_account_id,p_placement_key,p_name,p_desktop_image_url,p_desktop_width,p_desktop_height,
      p_mobile_image_url,p_mobile_width,p_mobile_height,p_alt_text,p_destination_url,p_open_in_new_tab,
      p_starts_at,p_ends_at,p_weight,p_priority,p_changed_by,p_legacy_banner_id) result;
    -- The canonical save holds the campaign lock until this transaction ends.
    UPDATE ads.campaigns c SET metadata=c.metadata||jsonb_build_object('banner_scope_v1',scope)
      WHERE c.campaign_id=saved.campaign_id;
    RETURN QUERY SELECT saved.campaign_id,saved.advertisement_id,saved.creative_id,
      saved.placement_id,saved.campaign_status,saved.result_status;
END;
$function$;

ALTER FUNCTION ads.normalize_banner_scope(jsonb) OWNER TO ads_owner;
ALTER FUNCTION ads.banner_scope_matches(jsonb,text,text) OWNER TO ads_owner;
ALTER FUNCTION ads.select_house_banner_candidate(text,timestamptz,text,character,text,text) OWNER TO ads_owner;
ALTER FUNCTION ads.save_house_banner_campaign_v2(uuid,bigint,text,text,text,integer,integer,text,integer,integer,text,text,boolean,timestamptz,timestamptz,integer,integer,integer,bigint,jsonb) OWNER TO ads_owner;
REVOKE ALL ON FUNCTION ads.normalize_banner_scope(jsonb),ads.banner_scope_matches(jsonb,text,text),
  ads.select_house_banner_candidate(text,timestamptz,text,character,text,text),
  ads.save_house_banner_campaign_v2(uuid,bigint,text,text,text,integer,integer,text,integer,integer,text,text,boolean,timestamptz,timestamptz,integer,integer,integer,bigint,jsonb)
  FROM PUBLIC,runner,runner_dba,ads_reader,ads_delivery,ads_admin,ads_finance,ads_business;
GRANT EXECUTE ON FUNCTION ads.select_house_banner_candidate(text,timestamptz,text,character,text,text) TO ads_delivery;
GRANT EXECUTE ON FUNCTION ads.save_house_banner_campaign_v2(uuid,bigint,text,text,text,integer,integer,text,integer,integer,text,text,boolean,timestamptz,timestamptz,integer,integer,integer,bigint,jsonb) TO ads_business;
INSERT INTO ads.schema_migrations(migration_key,description)
 VALUES('2026-09-15_ads_house_banner_scope','HOUSE/BANNER scope validated on atomic save, candidate selection and locked delivery')
 ON CONFLICT(migration_key) DO NOTHING;
COMMIT;
