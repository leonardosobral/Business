CREATE OR REPLACE FUNCTION ads.banner_scope_matches(p_metadata jsonb, p_region text, p_page text)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
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
$function$
