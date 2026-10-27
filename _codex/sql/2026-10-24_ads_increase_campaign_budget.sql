  -- Business: increase an approved EVENT campaign total budget without pausing/review.
  -- Only ads schema objects are modified. Customer limits/balances are not changed.
  BEGIN;
  SET LOCAL lock_timeout = '5s';
  SET LOCAL statement_timeout = '30s';
  DO $guard$
  BEGIN
   IF md5(pg_get_functiondef('ads.invalidate_campaign_review_on_edit()'::regprocedure)) <> '79c0c2e285b378a6dd4247d4ec32a377' THEN
    RAISE EXCEPTION 'Budget increase migration: review trigger baseline drift (or migration already applied)';
   END IF;
   IF to_regprocedure('ads.paid_banner_actor_allowed(bigint,integer)') IS NULL THEN
    RAISE EXCEPTION 'Budget increase migration: existing actor/delegation guard required';
   END IF;
  END $guard$;
  CREATE OR REPLACE FUNCTION ads.invalidate_campaign_review_on_edit()
   RETURNS trigger
   LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path TO 'pg_catalog'
  AS $function$
  DECLARE
      target_id uuid;
      campaign ads.campaigns%ROWTYPE;
      review ads.campaign_review_requests%ROWTYPE;
      actor_id integer;
      old_material jsonb;
      new_material jsonb;
      previous_transition_setting text;
      reason text := 'Campanha alterada; novo envio para analise obrigatorio';
  BEGIN
      IF TG_TABLE_NAME = 'campaigns' THEN
          -- Only a pure total-budget increase preserves an existing approval.
          -- Compare every other column: no session flag can exempt creative edits.
          IF OLD.billing_model='CPC' AND OLD.status IN ('ACTIVE','PAUSED')
             AND NEW.budget_total > OLD.budget_total
             AND (to_jsonb(OLD) - ARRAY['budget_total','updated_at','updated_by','version'])
                 IS NOT DISTINCT FROM
                 (to_jsonb(NEW) - ARRAY['budget_total','updated_at','updated_by','version'])
             AND (SELECT r.status FROM ads.campaign_review_requests r
                   WHERE r.campaign_id=OLD.campaign_id AND r.account_id=OLD.account_id
                   ORDER BY r.campaign_review_request_id DESC LIMIT 1)='APPROVED'
          THEN RETURN NULL; END IF;
          -- Operational pause/resume and accounting timestamps are not creative edits.
          old_material := jsonb_build_array(OLD.account_id, OLD.name, OLD.billing_model,
              OLD.currency, OLD.cpc_bid, OLD.budget_total, OLD.budget_daily,
              OLD.frequency_cap_count, OLD.frequency_cap_window_minutes,
              OLD.target_device_class, OLD.target_country_code, OLD.target_region_code,
              OLD.starts_at, OLD.ends_at, CASE WHEN OLD.metadata->>'ad_type'='BANNER' THEN OLD.metadata - ARRAY['last_status_reason','requires_new_review'] END);
          new_material := jsonb_build_array(NEW.account_id, NEW.name, NEW.billing_model,
              NEW.currency, NEW.cpc_bid, NEW.budget_total, NEW.budget_daily,
              NEW.frequency_cap_count, NEW.frequency_cap_window_minutes,
              NEW.target_device_class, NEW.target_country_code, NEW.target_region_code,
              NEW.starts_at, NEW.ends_at, CASE WHEN NEW.metadata->>'ad_type'='BANNER' THEN NEW.metadata - ARRAY['last_status_reason','requires_new_review'] END);
          IF old_material IS NOT DISTINCT FROM new_material THEN RETURN NULL; END IF;
      ELSIF TG_OP = 'UPDATE' THEN
          old_material := to_jsonb(OLD) - ARRAY['updated_at','updated_by','created_at','created_by'];
          new_material := to_jsonb(NEW) - ARRAY['updated_at','updated_by','created_at','created_by'];
          IF old_material IS NOT DISTINCT FROM new_material THEN RETURN NULL; END IF;
      END IF;

      target_id := CASE WHEN TG_OP = 'DELETE' THEN OLD.campaign_id ELSE NEW.campaign_id END;
      SELECT stored.* INTO campaign FROM ads.campaigns stored
       WHERE stored.campaign_id = target_id FOR UPDATE;
      IF NOT FOUND OR campaign.billing_model <> 'CPC' THEN RETURN NULL; END IF;
      IF campaign.status = 'ACTIVE' THEN
          RAISE EXCEPTION 'Campanha ativa exige reabertura para edicao e nova revisao';
      END IF;
      actor_id := coalesce(
          CASE WHEN TG_OP <> 'DELETE' THEN (to_jsonb(NEW)->>'updated_by')::integer END,
          campaign.updated_by, campaign.created_by
      );
      -- Both editing APIs accept PAUSED. Once its approval is invalidated,
      -- the campaign must become a submit-capable draft in this same transaction.
      IF campaign.status = 'PAUSED' THEN
          previous_transition_setting := current_setting('ads.allow_campaign_status_transition',true);
          PERFORM set_config('ads.allow_campaign_status_transition','on',true);
          UPDATE ads.campaigns SET status='DRAFT', updated_by=actor_id,
              version=version+1, metadata=metadata || jsonb_build_object(
                  'last_status_reason',reason,'requires_new_review',true)
           WHERE campaign_id=target_id;
          INSERT INTO ads.campaign_status_history
              (campaign_id,account_id,from_status,to_status,reason,changed_by)
          VALUES (target_id,campaign.account_id,'PAUSED','DRAFT',reason,actor_id);
          PERFORM set_config('ads.allow_campaign_status_transition',coalesce(previous_transition_setting,'off'),true);
      END IF;
      FOR review IN SELECT stored.* FROM ads.campaign_review_requests stored
          WHERE stored.campaign_id = target_id
            AND stored.status IN ('WAITING_PREREQUISITES','PENDING_REVIEW','CHANGES_REQUESTED','APPROVED')
          ORDER BY stored.campaign_review_request_id FOR UPDATE
      LOOP
          UPDATE ads.campaign_review_requests SET status = 'CANCELED',
              reviewed_by = coalesce(actor_id, review.requested_by),
              reviewed_at = clock_timestamp(), updated_at = clock_timestamp(),
              review_reason = reason
           WHERE campaign_review_request_id = review.campaign_review_request_id;
          INSERT INTO ads.campaign_review_history
              (campaign_review_request_id, from_status, to_status, actor_id, reason)
          VALUES (review.campaign_review_request_id, review.status, 'CANCELED',
              coalesce(actor_id, review.requested_by), reason);
      END LOOP;
      RETURN NULL;
  END;
  $function$;

  CREATE TABLE ads.campaign_budget_history (
   campaign_budget_history_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
   campaign_id uuid NOT NULL,
   account_id bigint NOT NULL,
   previous_budget numeric(14,2) NOT NULL,
   new_budget numeric(14,2) NOT NULL CHECK(new_budget > previous_budget),
   changed_by integer NOT NULL,
   changed_at timestamptz NOT NULL DEFAULT clock_timestamp(),
   FOREIGN KEY(campaign_id,account_id) REFERENCES ads.campaigns(campaign_id,account_id)
  );
  ALTER TABLE ads.campaign_budget_history OWNER TO ads_owner;
  REVOKE ALL ON ads.campaign_budget_history FROM PUBLIC;

  CREATE FUNCTION ads.increase_campaign_budget(
   p_campaign_id uuid,p_account_id bigint,p_actor_id integer,
   p_expected_budget numeric,p_new_budget numeric
  ) RETURNS numeric
  LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog
  AS $function$
  DECLARE campaign ads.campaigns%ROWTYPE; review_status text;
  BEGIN
   IF p_expected_budget IS NULL OR p_new_budget IS NULL
      OR p_new_budget::text IN ('NaN','Infinity','-Infinity')
      OR p_new_budget <= 0 OR p_new_budget > 999999999999.99
      OR round(p_new_budget,2) <> p_new_budget THEN
    RAISE EXCEPTION 'ADS_BUDGET_INVALID';
   END IF;
   IF NOT coalesce(ads.paid_banner_actor_allowed(p_account_id,p_actor_id),false) THEN
    RAISE EXCEPTION 'ADS_BUDGET_FORBIDDEN';
   END IF;
   SELECT c.* INTO campaign FROM ads.campaigns c
    WHERE c.campaign_id=p_campaign_id AND c.account_id=p_account_id FOR UPDATE;
   IF NOT FOUND OR campaign.billing_model<>'CPC'
      OR NOT EXISTS(SELECT 1 FROM ads.advertisements a WHERE a.campaign_id=campaign.campaign_id
                    AND a.account_id=campaign.account_id AND a.ad_type='EVENT') THEN
    RAISE EXCEPTION 'ADS_BUDGET_NOT_FOUND';
   END IF;
   IF campaign.status NOT IN ('ACTIVE','PAUSED') THEN RAISE EXCEPTION 'ADS_BUDGET_NOT_APPROVED'; END IF;
   SELECT r.status INTO review_status FROM ads.campaign_review_requests r
    WHERE r.campaign_id=campaign.campaign_id AND r.account_id=campaign.account_id
    ORDER BY r.campaign_review_request_id DESC LIMIT 1 FOR UPDATE;
   IF review_status IS DISTINCT FROM 'APPROVED' THEN RAISE EXCEPTION 'ADS_BUDGET_NOT_APPROVED'; END IF;
   IF campaign.budget_total IS DISTINCT FROM p_expected_budget THEN RAISE EXCEPTION 'ADS_BUDGET_STALE'; END IF;
   IF p_new_budget <= campaign.budget_total THEN RAISE EXCEPTION 'ADS_BUDGET_INCREASE_ONLY'; END IF;
   UPDATE ads.campaigns SET budget_total=p_new_budget,updated_by=p_actor_id,
    updated_at=clock_timestamp(),version=version+1 WHERE campaign_id=p_campaign_id;
   INSERT INTO ads.campaign_budget_history(campaign_id,account_id,previous_budget,new_budget,changed_by)
    VALUES(p_campaign_id,p_account_id,campaign.budget_total,p_new_budget,p_actor_id);
   RETURN p_new_budget;
  END;
  $function$;
  ALTER FUNCTION ads.increase_campaign_budget(uuid,bigint,integer,numeric,numeric) OWNER TO ads_owner;
  REVOKE ALL ON FUNCTION ads.increase_campaign_budget(uuid,bigint,integer,numeric,numeric) FROM PUBLIC;
  GRANT EXECUTE ON FUNCTION ads.increase_campaign_budget(uuid,bigint,integer,numeric,numeric) TO ads_business;
  INSERT INTO ads.schema_migrations(migration_key,description)
   VALUES('2026-10-24_ads_increase_campaign_budget','Increase only total budget while preserving approved campaign status and review');
  COMMIT;
