-- Sites/slots administrados pelo Business; delivery em ads.roadrunners.run.
-- Somente schema ads. Sem migração de campanhas ou alteração de saldos.
BEGIN;
SET LOCAL lock_timeout='5s';
SET LOCAL statement_timeout='60s';
SELECT pg_advisory_xact_lock(hashtext('ads.publisher_network.v1'));
CREATE TABLE IF NOT EXISTS ads.publisher_sites (
 site_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 site_key text NOT NULL UNIQUE CHECK(site_key ~ '^[a-z][a-z0-9-]{1,49}$'),
 name text NOT NULL CHECK(length(btrim(name)) BETWEEN 2 AND 120),
 origins text[] NOT NULL CHECK(cardinality(origins) BETWEEN 1 AND 10),
 status text NOT NULL CHECK(status IN('ACTIVE','INACTIVE')),
 version bigint NOT NULL DEFAULT 1,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 updated_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE TABLE IF NOT EXISTS ads.publisher_spots (
 spot_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 site_id uuid NOT NULL REFERENCES ads.publisher_sites(site_id),
 spot_key text NOT NULL CHECK(spot_key ~ '^[a-z][a-z0-9-]{1,49}$'),
 placement_id uuid NOT NULL UNIQUE REFERENCES ads.placements(placement_id),
 name text NOT NULL CHECK(length(btrim(name)) BETWEEN 2 AND 120),
 page_key text NOT NULL DEFAULT '' CHECK(page_key IN('','home','search','state','event','athlete')),
 region_code text NOT NULL DEFAULT '' CHECK(region_code='' OR region_code=ANY(ARRAY['AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'])),
 width integer NOT NULL CHECK(width BETWEEN 50 AND 2400),
 height integer NOT NULL CHECK(height BETWEEN 50 AND 2400),
 status text NOT NULL CHECK(status IN('ACTIVE','INACTIVE')),
 version bigint NOT NULL DEFAULT 1,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 UNIQUE(site_id,spot_key)
);
CREATE TABLE IF NOT EXISTS ads.publisher_inventory_history (
 history_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 entity_id uuid NOT NULL, entity_type text NOT NULL CHECK(entity_type IN('SITE','SPOT')),
 actor_id integer NOT NULL, before_value jsonb, after_value jsonb NOT NULL,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);
ALTER TABLE ads.publisher_sites OWNER TO ads_owner;
ALTER TABLE ads.publisher_spots OWNER TO ads_owner;
ALTER TABLE ads.publisher_inventory_history OWNER TO ads_owner;
REVOKE ALL ON ads.publisher_sites,ads.publisher_spots,ads.publisher_inventory_history FROM PUBLIC;
GRANT SELECT ON ads.publisher_sites,ads.publisher_spots TO ads_reader;

CREATE OR REPLACE FUNCTION ads.publisher_origin_valid(p_origin text) RETURNS boolean
LANGUAGE sql IMMUTABLE SET search_path=pg_catalog AS $f$
 SELECT coalesce(length(p_origin)<=255 AND p_origin=lower(p_origin)
 AND p_origin ~ '^https://([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$',false)
$f$;

CREATE OR REPLACE FUNCTION ads.save_publisher_site(p_id uuid,p_actor integer,p_version bigint,p_key text,p_name text,p_origins text[],p_status text)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $f$
DECLARE old ads.publisher_sites%ROWTYPE; saved ads.publisher_sites%ROWTYPE;
BEGIN
 IF nullif(current_setting('business.delegation_context',true),'') IS NOT NULL OR NOT EXISTS(SELECT 1 FROM public.tb_usuarios WHERE id=p_actor AND is_admin IS TRUE) THEN RAISE EXCEPTION 'Somente administrador global'; END IF;
 IF p_origins IS NULL OR cardinality(p_origins) NOT BETWEEN 1 AND 10 OR EXISTS(SELECT 1 FROM unnest(p_origins) o WHERE NOT ads.publisher_origin_valid(o)) THEN RAISE EXCEPTION 'Informe dominios HTTPS, sem caminho, porta ou barra final'; END IF;
 IF p_id IS NULL THEN
  INSERT INTO ads.publisher_sites(site_key,name,origins,status) VALUES(p_key,btrim(p_name),p_origins,p_status) RETURNING * INTO saved;
 ELSE
  SELECT * INTO old FROM ads.publisher_sites WHERE site_id=p_id FOR UPDATE;
  IF NOT FOUND OR old.version IS DISTINCT FROM p_version OR old.site_key IS DISTINCT FROM p_key THEN RAISE EXCEPTION 'Site alterado; recarregue antes de salvar'; END IF;
  UPDATE ads.publisher_sites SET name=btrim(p_name),origins=p_origins,status=p_status,version=version+1,updated_at=clock_timestamp() WHERE site_id=p_id RETURNING * INTO saved;
 END IF;
 INSERT INTO ads.publisher_inventory_history(entity_id,entity_type,actor_id,before_value,after_value) VALUES(saved.site_id,'SITE',p_actor,to_jsonb(old),to_jsonb(saved));
 RETURN saved.site_id;
END $f$;

CREATE OR REPLACE FUNCTION ads.save_publisher_spot(p_id uuid,p_actor integer,p_version bigint,p_site uuid,p_key text,p_name text,p_page text,p_region text,p_width integer,p_height integer,p_status text)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $f$
DECLARE old ads.publisher_spots%ROWTYPE; saved ads.publisher_spots%ROWTYPE; placement uuid;
BEGIN
 IF nullif(current_setting('business.delegation_context',true),'') IS NOT NULL OR NOT EXISTS(SELECT 1 FROM public.tb_usuarios WHERE id=p_actor AND is_admin IS TRUE) THEN RAISE EXCEPTION 'Somente administrador global'; END IF;
 PERFORM 1 FROM ads.publisher_sites WHERE site_id=p_site FOR SHARE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Site nao encontrado'; END IF;
 IF p_id IS NULL THEN
  INSERT INTO ads.placements(placement_key,channel,surface,format_key,status,description)
   VALUES('network-'||replace(gen_random_uuid()::text,'-',''),'PUBLISHER_NETWORK','BANNER','IMAGE','ACTIVE',btrim(p_name)) RETURNING placement_id INTO placement;
  INSERT INTO ads.publisher_spots(site_id,spot_key,placement_id,name,page_key,region_code,width,height,status)
   VALUES(p_site,p_key,placement,btrim(p_name),p_page,p_region,p_width,p_height,p_status) RETURNING * INTO saved;
 ELSE
  SELECT * INTO old FROM ads.publisher_spots WHERE spot_id=p_id FOR UPDATE;
  IF NOT FOUND OR old.version IS DISTINCT FROM p_version OR old.spot_key IS DISTINCT FROM p_key OR old.site_id IS DISTINCT FROM p_site THEN RAISE EXCEPTION 'Spot alterado; recarregue antes de salvar'; END IF;
  UPDATE ads.publisher_spots SET name=btrim(p_name),page_key=p_page,region_code=p_region,width=p_width,height=p_height,status=p_status,version=version+1,updated_at=clock_timestamp() WHERE spot_id=p_id RETURNING * INTO saved;
 END IF;
 INSERT INTO ads.publisher_inventory_history(entity_id,entity_type,actor_id,before_value,after_value) VALUES(saved.spot_id,'SPOT',p_actor,to_jsonb(old),to_jsonb(saved));
 RETURN saved.spot_id;
END $f$;

CREATE OR REPLACE FUNCTION ads.banner_placement_available(p_id uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $f$
 SELECT EXISTS(SELECT 1 FROM ads.placements p WHERE p.placement_id=p_id AND p.status='ACTIVE' AND p.format_key='IMAGE'
 AND (p.placement_key='rr-sidebar-banner-300x250' OR EXISTS(SELECT 1 FROM ads.publisher_spots sp JOIN ads.publisher_sites si USING(site_id)
 WHERE sp.placement_id=p_id AND sp.status='ACTIVE' AND si.status='ACTIVE')))
$f$;
DO $guard$ BEGIN IF NOT EXISTS(SELECT 1 FROM ads.schema_migrations WHERE migration_key='2026-11-04_ads_publisher_network') AND NOT EXISTS(SELECT 1 FROM pg_proc WHERE pronamespace='ads'::regnamespace AND proname='paid_banner_content_valid' AND md5(pg_get_functiondef(oid))='e27df94165060883a817951609d45197') THEN RAISE EXCEPTION 'Baseline divergiu: paid_banner_content_valid'; END IF; END $guard$;
CREATE OR REPLACE FUNCTION ads.paid_banner_content_valid(p_campaign_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
SELECT EXISTS(SELECT 1 FROM ads.campaigns c
 JOIN ads.advertisements a ON a.campaign_id=c.campaign_id AND a.account_id=c.account_id AND a.billing_model='CPC' AND a.ad_type='BANNER' AND a.core_event_id IS NULL AND a.status='ACTIVE'
 JOIN ads.creatives r ON r.advertisement_id=a.advertisement_id AND r.status='ACTIVE' AND r.creative_type='IMAGE'
 JOIN ads.campaign_placements cp ON cp.campaign_id=c.campaign_id AND cp.status='ACTIVE'
 JOIN ads.placements p ON p.placement_id=cp.placement_id AND (p.placement_key='rr-sidebar-banner-300x250' OR EXISTS(SELECT 1 FROM ads.publisher_spots sp WHERE sp.placement_id=p.placement_id)) AND p.status='ACTIVE' AND p.format_key='IMAGE'
 WHERE c.campaign_id=p_campaign_id AND c.billing_model='CPC' AND c.cpc_bid>=0.51 AND c.budget_total>=c.cpc_bid AND (c.budget_daily IS NULL OR c.budget_daily>=c.cpc_bid)
 AND c.starts_at IS NOT NULL AND c.ends_at>c.starts_at AND ads.normalize_banner_scope(c.metadata->'banner_scope_v1') IS NOT NULL
 AND ads.paid_banner_public_https(a.destination_url) AND ads.paid_banner_public_https(r.image_url) AND ads.paid_banner_public_https(r.payload->>'mobile_image_url')
 AND length(btrim(r.alt_text)) BETWEEN 1 AND 500 AND r.width BETWEEN 1 AND 8192 AND r.height BETWEEN 1 AND 8192
 AND (r.payload->>'mobile_width')::integer BETWEEN 1 AND 8192 AND (r.payload->>'mobile_height')::integer BETWEEN 1 AND 8192 AND jsonb_typeof(r.payload->'open_in_new_tab')='boolean'
 AND (SELECT count(*) FROM ads.advertisements x WHERE x.campaign_id=c.campaign_id AND x.status<>'ARCHIVED')=1
 AND (SELECT count(*) FROM ads.creatives x WHERE x.campaign_id=c.campaign_id AND x.status<>'ARCHIVED')=1
 AND (SELECT count(*) FROM ads.campaign_placements x WHERE x.campaign_id=c.campaign_id AND x.status='ACTIVE')=1);
$function$
;

DO $guard$ BEGIN IF NOT EXISTS(SELECT 1 FROM ads.schema_migrations WHERE migration_key='2026-11-04_ads_publisher_network') AND NOT EXISTS(SELECT 1 FROM pg_proc WHERE pronamespace='ads'::regnamespace AND proname='select_paid_banner_candidate' AND md5(pg_get_functiondef(oid))='bf1448b8610250ed4025fd718177024d') THEN RAISE EXCEPTION 'Baseline divergiu: select_paid_banner_candidate'; END IF; END $guard$;
CREATE OR REPLACE FUNCTION ads.select_paid_banner_candidate(p_placement_key text, p_requested_at timestamp with time zone DEFAULT clock_timestamp(), p_device_class text DEFAULT 'ALL'::text, p_country_code character DEFAULT 'BR'::bpchar, p_region_code text DEFAULT NULL::text, p_banner_page text DEFAULT NULL::text)
 RETURNS TABLE(campaign_id uuid, account_id bigint, advertisement_id uuid, creative_id uuid, placement_id uuid, placement_key text, ad_type text, core_event_id integer, destination_url text, billing_model text, price_candidate numeric, currency character, creative_type text, title text, body text, image_url text, alt_text text, width integer, height integer, creative_payload jsonb, priority integer, weight integer)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
WITH eligible AS (
 SELECT c.*,a.advertisement_id,a.destination_url,r.creative_id,r.creative_type,r.title,r.body,r.image_url,r.alt_text,r.width,r.height,r.payload,p.placement_id,p.placement_key,cp.priority,cp.weight,
 CASE WHEN c.metadata->'banner_scope_v1'->>'regions_mode'='SELECTED' THEN 2.0 ELSE 1.2 END AS relevance
 FROM ads.campaigns c JOIN public.tb_contas ac ON ac.id_conta=c.account_id AND ac.status::text='ATIVA'
 JOIN ads.campaign_placements cp ON cp.campaign_id=c.campaign_id AND cp.status='ACTIVE'
 JOIN ads.placements p ON p.placement_id=cp.placement_id AND p.status='ACTIVE' AND p.placement_key=p_placement_key AND ads.banner_placement_available(p.placement_id)
 JOIN ads.advertisements a ON a.campaign_id=c.campaign_id AND a.status='ACTIVE' AND a.ad_type='BANNER'
 JOIN ads.creatives r ON r.advertisement_id=a.advertisement_id AND r.status='ACTIVE'
 JOIN ads.account_balances b ON b.account_id=c.account_id AND b.currency=c.currency AND b.available_balance>=c.cpc_bid
 JOIN ads.campaign_budget_state bs ON bs.campaign_id=c.campaign_id AND bs.spent_total+c.cpc_bid<=c.budget_total
 WHERE c.billing_model='CPC' AND c.status='ACTIVE' AND c.starts_at<=p_requested_at AND c.ends_at>=p_requested_at
 AND p_device_class IN('ALL','DESKTOP','MOBILE') AND (p.device_class='ALL' OR p.device_class=p_device_class)
 AND (c.target_device_class='ALL' OR c.target_device_class=p_device_class) AND (c.target_country_code IS NULL OR c.target_country_code=p_country_code)
 AND (c.target_region_code IS NULL OR c.target_region_code=upper(btrim(p_region_code))) AND c.frequency_cap_count IS NULL
 AND (c.budget_daily IS NULL OR bs.spent_date<ads.business_date(p_requested_at) OR bs.spent_today+c.cpc_bid<=c.budget_daily)
 AND NOT EXISTS(SELECT 1 FROM ads.account_financial_holds h WHERE h.account_id=c.account_id AND h.status='OPEN')
 AND ads.banner_scope_matches(c.metadata,p_region_code,p_banner_page) AND ads.paid_banner_approved(c.campaign_id)
), ranked AS (
 SELECT e.*,lead(e.cpc_bid*e.relevance) OVER(ORDER BY e.cpc_bid*e.relevance DESC,e.campaign_id) AS next_score FROM eligible e
)
SELECT c.campaign_id,c.account_id,c.advertisement_id,c.creative_id,c.placement_id,c.placement_key,'BANNER'::text,NULL::integer,c.destination_url,'CPC'::text,
 ads.event_auction_price(c.cpc_bid,c.relevance,c.next_score,0.51),c.currency,c.creative_type,c.title,c.body,c.image_url,c.alt_text,c.width,c.height,c.payload,c.priority,c.weight
FROM ranked c ORDER BY c.cpc_bid*c.relevance DESC,c.campaign_id LIMIT 1;
$function$
;

DO $guard$ BEGIN IF NOT EXISTS(SELECT 1 FROM ads.schema_migrations WHERE migration_key='2026-11-04_ads_publisher_network') AND NOT EXISTS(SELECT 1 FROM pg_proc WHERE pronamespace='ads'::regnamespace AND proname='save_paid_banner_campaign' AND md5(pg_get_functiondef(oid))='d5335a4157f123bad2d4d795f3fb6ebd') THEN RAISE EXCEPTION 'Baseline divergiu: save_paid_banner_campaign'; END IF; END $guard$;
CREATE OR REPLACE FUNCTION ads.save_paid_banner_campaign(p_campaign_id uuid, p_account_id bigint, p_actor_id integer, p_values jsonb, p_submit boolean DEFAULT false)
 RETURNS TABLE(campaign_id uuid, advertisement_id uuid, creative_id uuid, placement_id uuid, campaign_status text, review_status text, campaign_review_request_id bigint)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE c ads.campaigns%ROWTYPE; a uuid; r uuid; p uuid; scope jsonb; creative_payload jsonb; submitted record;
 v_name text:=btrim(p_values->>'name'); bid numeric; total numeric; daily numeric; starts timestamptz; ends timestamptz;
BEGIN
 IF NOT ads.paid_banner_actor_allowed(p_account_id,p_actor_id) THEN RAISE EXCEPTION 'Ator nao autorizado nesta conta'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.tb_contas x WHERE x.id_conta=p_account_id AND x.status::text IN('ATIVA','PENDENTE')) THEN RAISE EXCEPTION 'Conta indisponivel'; END IF;
 IF jsonb_typeof(p_values) IS DISTINCT FROM 'object' OR EXISTS(SELECT 1 FROM jsonb_object_keys(p_values) k WHERE k<>ALL(ARRAY['name','placement_key','image_url_desktop','width_desktop','height_desktop','image_url_mobile','width_mobile','height_mobile','alt_text','destination_url','open_new_tab','starts_at','ends_at','cpc_bid','budget_total','budget_daily','target_device','banner_scope_v1','expected_version'])) THEN RAISE EXCEPTION 'Campos de banner invalidos'; END IF;
 IF p_values ? 'expected_version' AND (jsonb_typeof(p_values->'expected_version') IS DISTINCT FROM 'number' OR (p_values->>'expected_version') !~ '^[1-9][0-9]{0,9}$') THEN RAISE EXCEPTION 'Versao esperada deve ser inteiro positivo'; END IF;
 scope:=ads.normalize_banner_scope(p_values->'banner_scope_v1');
 bid:=(p_values->>'cpc_bid')::numeric;total:=(p_values->>'budget_total')::numeric;daily:=(p_values->>'budget_daily')::numeric;
 starts:=(p_values->>'starts_at')::timestamptz; ends:=(p_values->>'ends_at')::timestamptz;
 IF scope IS NULL OR v_name IS NULL OR length(v_name) NOT BETWEEN 1 AND 200
  OR p_values->>'target_device' IS NULL OR p_values->>'target_device' NOT IN('ALL','DESKTOP','MOBILE') OR jsonb_typeof(p_values->'open_new_tab') IS DISTINCT FROM 'boolean'
  OR NOT ads.paid_banner_public_https(p_values->>'destination_url') OR NOT ads.paid_banner_public_https(p_values->>'image_url_desktop') OR NOT ads.paid_banner_public_https(p_values->>'image_url_mobile')
  OR coalesce(length(btrim(p_values->>'alt_text')),0) NOT BETWEEN 1 AND 500
  OR coalesce((p_values->>'width_desktop')::integer,0) NOT BETWEEN 1 AND 8192 OR coalesce((p_values->>'height_desktop')::integer,0) NOT BETWEEN 1 AND 8192 OR coalesce((p_values->>'width_mobile')::integer,0) NOT BETWEEN 1 AND 8192 OR coalesce((p_values->>'height_mobile')::integer,0) NOT BETWEEN 1 AND 8192
  OR starts IS NULL OR ends IS NULL OR ends<=starts OR NOT isfinite(starts) OR NOT isfinite(ends)
  OR bid IS NULL OR bid<0.51 OR bid>999999999999.99 OR bid<>round(bid,2)
  OR total IS NULL OR total<bid OR total>999999999999.99 OR total<>round(total,2)
  OR (daily IS NOT NULL AND (daily<bid OR daily>total OR daily>999999999999.99 OR daily<>round(daily,2)))
 THEN RAISE EXCEPTION 'Conteudo, escopo, lance ou orcamento do banner invalido'; END IF;
 SELECT x.placement_id INTO p FROM ads.placements x WHERE x.placement_key=p_values->>'placement_key' AND ads.banner_placement_available(x.placement_id) AND x.status='ACTIVE' AND x.format_key='IMAGE' FOR SHARE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Placement de banner invalido'; END IF;
 creative_payload:=jsonb_build_object('managed_by','ads_business','product','CPC','responsive',true,'desktop_image_url',p_values->>'image_url_desktop','desktop_width',(p_values->>'width_desktop')::integer,'desktop_height',(p_values->>'height_desktop')::integer,'mobile_image_url',p_values->>'image_url_mobile','mobile_width',(p_values->>'width_mobile')::integer,'mobile_height',(p_values->>'height_mobile')::integer,'open_in_new_tab',(p_values->>'open_new_tab')::boolean);
 IF p_campaign_id IS NULL THEN
  INSERT INTO ads.campaigns(account_id,name,billing_model,cpc_bid,budget_total,budget_daily,target_device_class,target_country_code,starts_at,ends_at,created_by,updated_by,metadata) VALUES(p_account_id,v_name,'CPC',bid,total,daily,p_values->>'target_device','BR',starts,ends,p_actor_id,p_actor_id,jsonb_build_object('ad_type','BANNER','managed_by','ads_business','banner_scope_v1',scope,'banner_revision',1)) RETURNING * INTO c;
  INSERT INTO ads.advertisements(campaign_id,account_id,billing_model,ad_type,name,status,destination_url,created_by,updated_by) VALUES(c.campaign_id,p_account_id,'CPC','BANNER',v_name,'ACTIVE',p_values->>'destination_url',p_actor_id,p_actor_id) RETURNING ads.advertisements.advertisement_id INTO a;
  INSERT INTO ads.creatives(advertisement_id,campaign_id,account_id,billing_model,ad_type,creative_type,status,title,image_url,alt_text,width,height,payload,created_by,updated_by) VALUES(a,c.campaign_id,p_account_id,'CPC','BANNER','IMAGE','ACTIVE',v_name,p_values->>'image_url_desktop',p_values->>'alt_text',(p_values->>'width_desktop')::integer,(p_values->>'height_desktop')::integer,creative_payload,p_actor_id,p_actor_id) RETURNING ads.creatives.creative_id INTO r;
  INSERT INTO ads.campaign_placements(campaign_id,account_id,billing_model,placement_id,status,priority,weight) VALUES(c.campaign_id,p_account_id,'CPC',p,'ACTIVE',1,1);
 ELSE
  SELECT * INTO c FROM ads.campaigns x WHERE x.campaign_id=p_campaign_id AND x.account_id=p_account_id AND x.billing_model='CPC' FOR UPDATE;
  IF NOT FOUND OR NOT ads.paid_banner_content_valid(c.campaign_id) THEN RAISE EXCEPTION 'Banner nao encontrado nesta conta'; END IF;
  IF (p_values->>'expected_version')::bigint IS DISTINCT FROM c.version::bigint THEN RAISE EXCEPTION 'Conflito de versao; recarregue o banner antes de editar'; END IF;
  IF c.status NOT IN('DRAFT','ACTIVE','PAUSED') THEN RAISE EXCEPTION 'Banner encerrado nao pode ser editado'; END IF;
  IF EXISTS(SELECT 1 FROM ads.campaign_review_requests x WHERE x.campaign_id=c.campaign_id AND x.status IN('PENDING_REVIEW','WAITING_PREREQUISITES','APPROVED')) THEN PERFORM ads.prepare_campaign_for_edit(c.campaign_id,p_account_id,p_actor_id);
  ELSIF c.status='ACTIVE' THEN RAISE EXCEPTION 'Banner ativo sem aprovacao'; END IF;
  SELECT x.advertisement_id INTO a FROM ads.advertisements x WHERE x.campaign_id=c.campaign_id AND x.status<>'ARCHIVED';
  SELECT x.creative_id INTO r FROM ads.creatives x WHERE x.campaign_id=c.campaign_id AND x.status<>'ARCHIVED';
  UPDATE ads.campaign_placements x SET status='INACTIVE' WHERE x.campaign_id=c.campaign_id AND x.placement_id<>p AND x.status='ACTIVE';
  INSERT INTO ads.campaign_placements(campaign_id,account_id,billing_model,placement_id,status,priority,weight)
    VALUES(c.campaign_id,p_account_id,'CPC',p,'ACTIVE',1,1)
    ON CONFLICT ON CONSTRAINT campaign_placements_pkey DO UPDATE SET status='ACTIVE';
  UPDATE ads.campaigns x SET name=v_name,cpc_bid=bid,budget_total=total,budget_daily=daily,target_device_class=p_values->>'target_device',starts_at=starts,ends_at=ends,updated_by=p_actor_id,version=x.version+1,metadata=x.metadata||jsonb_build_object('banner_scope_v1',scope,'banner_revision',coalesce((x.metadata->>'banner_revision')::integer,0)+1) WHERE x.campaign_id=c.campaign_id;
  UPDATE ads.advertisements x SET name=v_name,destination_url=p_values->>'destination_url',updated_by=p_actor_id WHERE x.advertisement_id=a;
  UPDATE ads.creatives x SET title=v_name,image_url=p_values->>'image_url_desktop',alt_text=p_values->>'alt_text',width=(p_values->>'width_desktop')::integer,height=(p_values->>'height_desktop')::integer,payload=creative_payload,updated_by=p_actor_id WHERE x.creative_id=r;
 END IF;
 IF coalesce(p_submit,false) THEN
  SELECT * INTO submitted FROM ads.submit_paid_banner_review(c.campaign_id,p_account_id,p_actor_id);
  RETURN QUERY SELECT c.campaign_id,a,r,p,submitted.campaign_status,submitted.review_status,submitted.campaign_review_request_id;
 ELSE RETURN QUERY SELECT c.campaign_id,a,r,p,x.status,'NONE'::text,NULL::bigint FROM ads.campaigns x WHERE x.campaign_id=c.campaign_id;
 END IF;
END;
$function$
;

DO $guard$ BEGIN IF NOT EXISTS(SELECT 1 FROM ads.schema_migrations WHERE migration_key='2026-11-04_ads_publisher_network') AND NOT EXISTS(SELECT 1 FROM pg_proc WHERE pronamespace='ads'::regnamespace AND proname='save_house_banner_campaign' AND md5(pg_get_functiondef(oid))='1e87d19a83419d0bed5b632bffeed3af') THEN RAISE EXCEPTION 'Baseline divergiu: save_house_banner_campaign'; END IF; END $guard$;
CREATE OR REPLACE FUNCTION ads.save_house_banner_campaign(p_campaign_id uuid, p_account_id bigint, p_placement_key text, p_name text, p_desktop_image_url text, p_desktop_width integer, p_desktop_height integer, p_mobile_image_url text, p_mobile_width integer, p_mobile_height integer, p_alt_text text, p_destination_url text, p_open_in_new_tab boolean, p_starts_at timestamp with time zone, p_ends_at timestamp with time zone, p_weight integer DEFAULT 1, p_priority integer DEFAULT 1, p_changed_by integer DEFAULT NULL::integer, p_legacy_banner_id bigint DEFAULT NULL::bigint)
 RETURNS TABLE(campaign_id uuid, advertisement_id uuid, creative_id uuid, placement_id uuid, campaign_status text, result_status text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
#variable_conflict use_column
DECLARE
    target ads.campaigns%ROWTYPE;
    target_advertisement ads.advertisements%ROWTYPE;
    target_creative ads.creatives%ROWTYPE;
    selected_placement ads.placements%ROWTYPE;
    mapped_campaign_id uuid;
    effective_campaign_id uuid := p_campaign_id;
    v_campaign_id uuid;
    v_advertisement_id uuid;
    v_creative_id uuid;
    v_result_status text;
    v_advertisement_count integer;
    v_creative_count integer;
    normalized_name text := nullif(trim(p_name), '');
    normalized_desktop_url text := nullif(trim(p_desktop_image_url), '');
    normalized_mobile_url text := nullif(trim(p_mobile_image_url), '');
    normalized_alt text := nullif(trim(p_alt_text), '');
    normalized_destination text := nullif(trim(p_destination_url), '');
    creative_payload jsonb;
    map_metadata jsonb;
BEGIN
    -- banner_scope_v1: institutional owner and canonical global admin actor.
    IF p_account_id IS DISTINCT FROM 1::bigint OR NOT EXISTS (
        SELECT 1 FROM public.tb_usuarios actor WHERE actor.id=p_changed_by
          AND (coalesce(actor.is_admin,false) OR coalesce(actor.is_dev,false))
    ) THEN RAISE EXCEPTION 'Somente administrador RunnerHub salva HOUSE da conta institucional'; END IF;

    IF p_legacy_banner_id IS NOT NULL AND p_legacy_banner_id <= 0 THEN
        RAISE EXCEPTION 'ID legado de banner deve ser positivo';
    END IF;

    IF p_legacy_banner_id IS NOT NULL THEN
        SELECT legacy.canonical_id
          INTO mapped_campaign_id
          FROM ads.legacy_id_map legacy
         WHERE legacy.legacy_schema = 'ads'
           AND legacy.legacy_table = 'tb_portal_banners'
           AND legacy.legacy_id = p_legacy_banner_id::text
           AND legacy.canonical_entity_type = 'CAMPAIGN';

        IF effective_campaign_id IS NULL THEN
            effective_campaign_id := mapped_campaign_id;
        ELSIF mapped_campaign_id IS NOT NULL
              AND mapped_campaign_id <> effective_campaign_id THEN
            RAISE EXCEPTION 'ID legado ja aponta para outra campanha';
        END IF;
    END IF;

    IF p_account_id IS NULL OR NOT EXISTS (
        SELECT 1
          FROM public.tb_contas account
         WHERE account.id_conta = p_account_id
           AND account.status::text = 'ATIVA'
    ) THEN
        RAISE EXCEPTION 'Conta da campanha nao encontrada ou nao ativa';
    END IF;

    IF normalized_name IS NULL THEN
        RAISE EXCEPTION 'Nome do banner e obrigatorio';
    END IF;

    IF normalized_desktop_url IS NULL
       OR normalized_desktop_url !~ '^https://[^[:space:]]+$'
       OR normalized_mobile_url IS NULL
       OR normalized_mobile_url !~ '^https://[^[:space:]]+$' THEN
        RAISE EXCEPTION 'Imagens desktop e mobile HTTPS sao obrigatorias';
    END IF;

    IF p_desktop_width IS NULL OR p_desktop_width <= 0
       OR p_desktop_height IS NULL OR p_desktop_height <= 0
       OR p_mobile_width IS NULL OR p_mobile_width <= 0
       OR p_mobile_height IS NULL OR p_mobile_height <= 0 THEN
        RAISE EXCEPTION 'Dimensoes desktop e mobile positivas sao obrigatorias';
    END IF;

    IF normalized_alt IS NULL THEN
        RAISE EXCEPTION 'Texto alternativo do banner e obrigatorio';
    END IF;

    IF normalized_destination IS NULL
       OR normalized_destination !~ '^https://[^[:space:]]+$' THEN
        RAISE EXCEPTION 'Destino HTTPS valido e obrigatorio';
    END IF;

    IF p_starts_at IS NULL OR p_ends_at IS NULL
       OR p_ends_at <= p_starts_at THEN
        RAISE EXCEPTION 'Janela do banner e obrigatoria e deve ser valida';
    END IF;

    IF p_weight IS NULL OR p_weight <= 0
       OR p_priority IS NULL OR p_priority <= 0 THEN
        RAISE EXCEPTION 'Peso e prioridade devem ser positivos';
    END IF;

    SELECT placement.*
      INTO selected_placement
      FROM ads.placements placement
     WHERE placement.placement_key = nullif(trim(p_placement_key), '')
       AND ads.banner_placement_available(placement.placement_id)
       AND placement.status = 'ACTIVE'
       AND placement.format_key = 'IMAGE'
     FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Placement ativo de imagem nao encontrado';
    END IF;

    creative_payload := jsonb_build_object(
        'managed_by', 'ads_business',
        'product', 'HOUSE',
        'responsive', true,
        'desktop_image_url', normalized_desktop_url,
        'desktop_width', p_desktop_width,
        'desktop_height', p_desktop_height,
        'mobile_image_url', normalized_mobile_url,
        'mobile_width', p_mobile_width,
        'mobile_height', p_mobile_height,
        'open_in_new_tab', coalesce(p_open_in_new_tab, false)
    );

    IF p_legacy_banner_id IS NOT NULL THEN
        creative_payload := creative_payload || jsonb_build_object(
            'legacy_banner_id', p_legacy_banner_id
        );
    END IF;

    IF effective_campaign_id IS NULL THEN
        v_campaign_id := gen_random_uuid();
        v_advertisement_id := gen_random_uuid();
        v_creative_id := gen_random_uuid();
        v_result_status := 'created';

        INSERT INTO ads.campaigns (
            campaign_id,
            account_id,
            name,
            billing_model,
            status,
            currency,
            target_device_class,
            target_country_code,
            starts_at,
            ends_at,
            created_by,
            updated_by,
            metadata
        )
        VALUES (
            v_campaign_id,
            p_account_id,
            normalized_name,
            'HOUSE',
            'DRAFT',
            'BRL',
            'ALL',
            'BR',
            p_starts_at,
            p_ends_at,
            p_changed_by,
            p_changed_by,
            jsonb_strip_nulls(jsonb_build_object(
                'managed_by', 'ads_business',
                'product', 'HOUSE',
                'ad_type', 'BANNER',
                'legacy_banner_id', p_legacy_banner_id
            ))
        );

        INSERT INTO ads.advertisements (
            advertisement_id,
            campaign_id,
            account_id,
            billing_model,
            ad_type,
            name,
            status,
            core_event_id,
            destination_url,
            created_by,
            updated_by,
            metadata
        )
        VALUES (
            v_advertisement_id,
            v_campaign_id,
            p_account_id,
            'HOUSE',
            'BANNER',
            normalized_name,
            'ACTIVE',
            NULL,
            normalized_destination,
            p_changed_by,
            p_changed_by,
            jsonb_strip_nulls(jsonb_build_object(
                'managed_by', 'ads_business',
                'product', 'HOUSE',
                'legacy_banner_id', p_legacy_banner_id
            ))
        );

        INSERT INTO ads.creatives (
            creative_id,
            advertisement_id,
            campaign_id,
            account_id,
            billing_model,
            ad_type,
            creative_type,
            status,
            title,
            image_url,
            alt_text,
            width,
            height,
            payload,
            created_by,
            updated_by
        )
        VALUES (
            v_creative_id,
            v_advertisement_id,
            v_campaign_id,
            p_account_id,
            'HOUSE',
            'BANNER',
            'IMAGE',
            'ACTIVE',
            normalized_name,
            normalized_desktop_url,
            normalized_alt,
            p_desktop_width,
            p_desktop_height,
            creative_payload,
            p_changed_by,
            p_changed_by
        );

        INSERT INTO ads.campaign_placements (
            campaign_id,
            account_id,
            billing_model,
            placement_id,
            status,
            priority,
            weight,
            metadata
        )
        VALUES (
            v_campaign_id,
            p_account_id,
            'HOUSE',
            selected_placement.placement_id,
            'ACTIVE',
            p_priority,
            p_weight,
            jsonb_strip_nulls(jsonb_build_object(
                'managed_by', 'ads_business',
                'product', 'HOUSE',
                'legacy_banner_id', p_legacy_banner_id
            ))
        );
    ELSE
        SELECT stored.*
          INTO target
          FROM ads.campaigns stored
         WHERE stored.campaign_id = effective_campaign_id
         FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Campanha de banner nao encontrada';
        END IF;

        IF target.account_id <> p_account_id
           OR target.billing_model <> 'HOUSE' THEN
            RAISE EXCEPTION 'Conta ou produto da campanha nao corresponde';
        END IF;

        IF target.status NOT IN ('DRAFT', 'PAUSED') THEN
            RAISE EXCEPTION 'Pause o banner antes de editar';
        END IF;

        SELECT count(*)
          INTO v_advertisement_count
          FROM ads.advertisements advertisement
         WHERE advertisement.campaign_id = target.campaign_id
           AND advertisement.account_id = target.account_id
           AND advertisement.billing_model = 'HOUSE'
           AND advertisement.ad_type = 'BANNER'
           AND advertisement.status <> 'ARCHIVED';

        IF v_advertisement_count <> 1 THEN
            RAISE EXCEPTION 'Campanha deve possuir exatamente um anuncio BANNER';
        END IF;

        SELECT advertisement.*
          INTO target_advertisement
          FROM ads.advertisements advertisement
         WHERE advertisement.campaign_id = target.campaign_id
           AND advertisement.account_id = target.account_id
           AND advertisement.billing_model = 'HOUSE'
           AND advertisement.ad_type = 'BANNER'
           AND advertisement.status <> 'ARCHIVED'
         FOR UPDATE;

        SELECT count(*)
          INTO v_creative_count
          FROM ads.creatives creative
         WHERE creative.advertisement_id =
               target_advertisement.advertisement_id
           AND creative.status <> 'ARCHIVED';

        IF v_creative_count <> 1 THEN
            RAISE EXCEPTION 'Banner deve possuir exatamente um criativo ativo';
        END IF;

        SELECT creative.*
          INTO target_creative
          FROM ads.creatives creative
         WHERE creative.advertisement_id =
               target_advertisement.advertisement_id
           AND creative.status <> 'ARCHIVED'
         FOR UPDATE;

        v_campaign_id := target.campaign_id;
        v_advertisement_id := target_advertisement.advertisement_id;
        v_creative_id := target_creative.creative_id;
        v_result_status := 'updated';

        UPDATE ads.campaigns campaign
           SET name = normalized_name,
               starts_at = p_starts_at,
               ends_at = p_ends_at,
               updated_by = p_changed_by,
               updated_at = clock_timestamp(),
               version = campaign.version + 1,
               metadata = campaign.metadata || jsonb_strip_nulls(
                   jsonb_build_object(
                       'managed_by', 'ads_business',
                       'legacy_banner_id', p_legacy_banner_id
                   )
               )
         WHERE campaign.campaign_id = v_campaign_id;

        UPDATE ads.advertisements advertisement
           SET name = normalized_name,
               status = 'ACTIVE',
               destination_url = normalized_destination,
               updated_by = p_changed_by,
               updated_at = clock_timestamp()
         WHERE advertisement.advertisement_id = v_advertisement_id;

        UPDATE ads.creatives creative
           SET status = 'ACTIVE',
               title = normalized_name,
               image_url = normalized_desktop_url,
               alt_text = normalized_alt,
               width = p_desktop_width,
               height = p_desktop_height,
               payload = creative_payload,
               updated_by = p_changed_by,
               updated_at = clock_timestamp()
         WHERE creative.creative_id = v_creative_id;

        UPDATE ads.campaign_placements link
           SET status = 'INACTIVE',
               updated_at = clock_timestamp()
         WHERE link.campaign_id = v_campaign_id
           AND link.placement_id <> selected_placement.placement_id;

        INSERT INTO ads.campaign_placements (
            campaign_id,
            account_id,
            billing_model,
            placement_id,
            status,
            priority,
            weight,
            updated_at,
            metadata
        )
        VALUES (
            v_campaign_id,
            p_account_id,
            'HOUSE',
            selected_placement.placement_id,
            'ACTIVE',
            p_priority,
            p_weight,
            clock_timestamp(),
            jsonb_strip_nulls(jsonb_build_object(
                'managed_by', 'ads_business',
                'product', 'HOUSE',
                'legacy_banner_id', p_legacy_banner_id
            ))
        )
        ON CONFLICT (campaign_id, placement_id)
        DO UPDATE SET status = 'ACTIVE',
                      priority = EXCLUDED.priority,
                      weight = EXCLUDED.weight,
                      updated_at = EXCLUDED.updated_at,
                      metadata = campaign_placements.metadata
                                 || EXCLUDED.metadata;
    END IF;

    IF p_legacy_banner_id IS NOT NULL THEN
        IF EXISTS (
            SELECT 1
              FROM ads.legacy_id_map legacy
             WHERE legacy.legacy_schema = 'ads'
               AND legacy.legacy_table = 'tb_portal_banners'
               AND legacy.legacy_id = p_legacy_banner_id::text
               AND (
                   (legacy.canonical_entity_type = 'CAMPAIGN'
                    AND legacy.canonical_id <> v_campaign_id)
                   OR
                   (legacy.canonical_entity_type = 'ADVERTISEMENT'
                    AND legacy.canonical_id <> v_advertisement_id)
                   OR
                   (legacy.canonical_entity_type = 'CREATIVE'
                    AND legacy.canonical_id <> v_creative_id)
               )
        ) THEN
            RAISE EXCEPTION 'Mapa legado aponta para outra entidade canonica';
        END IF;

        map_metadata := jsonb_build_object(
            'managed_by', 'ads_business',
            'migration', '2026-08-20_ads_v1_house_banner',
            'owner_account_id', p_account_id
        );

        INSERT INTO ads.legacy_id_map (
            legacy_schema,
            legacy_table,
            legacy_id,
            canonical_entity_type,
            canonical_id,
            metadata
        )
        VALUES
            (
                'ads', 'tb_portal_banners', p_legacy_banner_id::text,
                'CAMPAIGN', v_campaign_id, map_metadata
            ),
            (
                'ads', 'tb_portal_banners', p_legacy_banner_id::text,
                'ADVERTISEMENT', v_advertisement_id, map_metadata
            ),
            (
                'ads', 'tb_portal_banners', p_legacy_banner_id::text,
                'CREATIVE', v_creative_id, map_metadata
            )
        ON CONFLICT (
            legacy_schema,
            legacy_table,
            legacy_id,
            canonical_entity_type
        )
        DO UPDATE SET metadata = legacy_id_map.metadata || EXCLUDED.metadata;
    END IF;

    RETURN QUERY
    SELECT v_campaign_id,
           v_advertisement_id,
           v_creative_id,
           selected_placement.placement_id,
           stored.status,
           v_result_status
      FROM ads.campaigns stored
     WHERE stored.campaign_id = v_campaign_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION ads.publisher_deliver(p_site text,p_spot text,p_origin text,p_device text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $f$
DECLARE slot record; candidate record; served record; token text; view_id uuid:=gen_random_uuid(); click_id uuid:=gen_random_uuid(); context jsonb; instant timestamptz:=clock_timestamp();
BEGIN
 IF NOT ads.publisher_origin_valid(p_origin) OR p_device IS NULL OR p_device NOT IN('DESKTOP','MOBILE') THEN RAISE EXCEPTION 'Contexto invalido'; END IF;
 SELECT sp.*,si.site_key,si.origins,p.placement_key INTO slot FROM ads.publisher_spots sp JOIN ads.publisher_sites si USING(site_id) JOIN ads.placements p USING(placement_id)
 WHERE si.site_key=p_site AND sp.spot_key=p_spot AND si.status='ACTIVE' AND sp.status='ACTIVE' AND p.status='ACTIVE' AND p_origin=ANY(si.origins) FOR SHARE OF si,sp,p;
 IF NOT FOUND THEN RAISE EXCEPTION 'Origem ou spot nao autorizado'; END IF;
 SELECT * INTO candidate FROM ads.select_paid_banner_candidate(slot.placement_key,instant,p_device,'BR',nullif(slot.region_code,''),nullif(slot.page_key,''));
 IF NOT FOUND THEN
  SELECT * INTO candidate FROM ads.select_house_banner_candidate(slot.placement_key,instant,p_device,'BR',nullif(slot.region_code,''),nullif(slot.page_key,''));
 END IF;
 IF NOT FOUND THEN RETURN jsonb_build_object('status','empty'); END IF;
 token:=replace(gen_random_uuid()::text||gen_random_uuid()::text,'-','');
 context:=jsonb_build_object('source','publisher_network_v1','publisher_site',slot.site_id,'publisher_spot',slot.spot_id,'publisher_origin',p_origin,'banner_page',slot.page_key,'view_event',view_id,'click_event',click_id);
 SELECT * INTO served FROM ads.serve_delivery(gen_random_uuid(),candidate.campaign_id,candidate.advertisement_id,candidate.creative_id,candidate.placement_id,
 encode(sha256(convert_to(token,'UTF8')),'hex'),instant+interval '30 minutes',instant,1::smallint,NULL,NULL,NULL,p_device,'BR',nullif(slot.region_code,''),'other',context,instant+interval '30 days');
 IF served.result_status NOT IN('served','already_recorded') THEN RETURN jsonb_build_object('status','empty'); END IF;
 RETURN jsonb_build_object('status','served','delivery',served.delivery_id,'token',token,'destination',served.destination_url,
 'desktop',candidate.creative_payload->>'desktop_image_url','mobile',candidate.creative_payload->>'mobile_image_url',
 'alt',candidate.alt_text,'newTab',coalesce((candidate.creative_payload->>'open_in_new_tab')::boolean,true),'width',slot.width,'height',slot.height);
END $f$;

CREATE OR REPLACE FUNCTION ads.publisher_track(p_delivery uuid,p_token text,p_origin text,p_event text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $f$
DECLARE d ads.deliveries%ROWTYPE; payload ads.delivery_payloads%ROWTYPE; result record; event_id uuid; context jsonb;
BEGIN
 SELECT * INTO payload FROM ads.delivery_payloads WHERE delivery_id=p_delivery;
 SELECT * INTO d FROM ads.deliveries WHERE delivery_id=p_delivery;
 IF NOT FOUND OR p_token IS NULL OR length(p_token) NOT BETWEEN 32 AND 256 OR d.token_hash<>encode(sha256(convert_to(p_token,'UTF8')),'hex')
 OR d.expires_at<clock_timestamp() OR payload.request_context->>'source' IS DISTINCT FROM 'publisher_network_v1'
 OR payload.request_context->>'publisher_origin' IS DISTINCT FROM p_origin OR p_event IS NULL OR p_event NOT IN('VIEWABLE_IMPRESSION','CLICK')
 THEN RAISE EXCEPTION 'Entrega invalida'; END IF;
 IF NOT EXISTS(SELECT 1 FROM ads.publisher_sites si JOIN ads.publisher_spots sp USING(site_id)
 WHERE si.site_id=(payload.request_context->>'publisher_site')::uuid AND sp.spot_id=(payload.request_context->>'publisher_spot')::uuid
 AND si.status='ACTIVE' AND sp.status='ACTIVE' AND p_origin=ANY(si.origins)) THEN RAISE EXCEPTION 'Origem inativa'; END IF;
 context:=jsonb_build_object('source','publisher_network_v1','publisher_site',payload.request_context->>'publisher_site','publisher_spot',payload.request_context->>'publisher_spot');
 IF p_event='VIEWABLE_IMPRESSION' THEN
  IF clock_timestamp()<d.served_at+interval '1 second' THEN RAISE EXCEPTION 'Impressao antecipada'; END IF;
  event_id:=(payload.request_context->>'view_event')::uuid;
  IF d.billing_model='CPC' THEN
   SELECT * INTO result FROM ads.record_cpc_viewable(event_id,d.delivery_id,p_token,clock_timestamp(),1000,0.5,payload.device_class,substring(p_origin from 9),context);
  ELSE
   SELECT * INTO result FROM ads.record_house_event(event_id,d.delivery_id,p_token,p_event,clock_timestamp(),1000,0.5,payload.device_class,substring(p_origin from 9),context);
  END IF;
  RETURN jsonb_build_object('status',result.result_status);
 END IF;
 -- No synthetic impressions. Without the visibility receipt, navigate without charging/counting.
 IF NOT EXISTS(SELECT 1 FROM ads.events WHERE delivery_id=d.delivery_id AND event_type='VIEWABLE_IMPRESSION' AND valid) THEN
  RETURN jsonb_build_object('status','not_viewable','destination',d.destination_url);
 END IF;
 event_id:=(payload.request_context->>'click_event')::uuid;
 IF d.billing_model='CPC' THEN
  SELECT * INTO result FROM ads.charge_cpc_click_token(event_id,d.delivery_id,p_token,clock_timestamp(),NULL,NULL,payload.device_class,substring(p_origin from 9),context);
 ELSE
  SELECT * INTO result FROM ads.record_house_event(event_id,d.delivery_id,p_token,'CLICK',clock_timestamp(),NULL,NULL,payload.device_class,substring(p_origin from 9),context);
 END IF;
 RETURN jsonb_build_object('status',result.result_status,'destination',d.destination_url);
END $f$;

DO $permissions$
DECLARE f regprocedure;
BEGIN
 FOR f IN SELECT oid::regprocedure FROM pg_proc WHERE pronamespace='ads'::regnamespace AND proname IN('publisher_origin_valid','save_publisher_site','save_publisher_spot','banner_placement_available','publisher_deliver','publisher_track') LOOP
  EXECUTE format('ALTER FUNCTION %s OWNER TO ads_owner',f);
  EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC',f);
 END LOOP;
END $permissions$;
GRANT EXECUTE ON FUNCTION ads.save_publisher_site(uuid,integer,bigint,text,text,text[],text),ads.save_publisher_spot(uuid,integer,bigint,uuid,text,text,text,text,integer,integer,text) TO ads_admin, ads_business;
GRANT EXECUTE ON FUNCTION ads.publisher_origin_valid(text),ads.banner_placement_available(uuid) TO ads_reader;
GRANT EXECUTE ON FUNCTION ads.publisher_deliver(text,text,text,text),ads.publisher_track(uuid,text,text,text) TO ads_delivery;
INSERT INTO ads.schema_migrations(migration_key,description) VALUES('2026-11-04_ads_publisher_network','Sites, spots e integracao publica em ads.roadrunners.run') ON CONFLICT(migration_key) DO NOTHING;
COMMIT;
