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
 SELECT x.placement_id INTO p FROM ads.placements x WHERE x.placement_key=p_values->>'placement_key' AND x.placement_key='rr-sidebar-banner-300x250' AND x.status='ACTIVE' AND x.format_key='IMAGE' FOR SHARE;
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
