import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
export async function loadCanonicalAdsFixture(sql,root){
 const rr=resolve(root,'../RoadRunners/_codex/sql');
 const read=name=>readFileSync(resolve(rr,name),'utf8');
 const business=name=>readFileSync(resolve(root,'_codex/sql',name),'utf8');
 function func(source,name){const start=source.indexOf(`CREATE OR REPLACE FUNCTION ads.${name}(`);const end=source.indexOf('$function$;',start);assert(start>=0&&end>start,`Missing canonical ${name}`);return source.slice(start,end+11);}
  await sql(read('2026-07-26_ads_v1_canonical_foundation.sql'));
  await sql(read('2026-08-18_ads_v1_admin_api.sql'));
  await sql(read('2026-08-18_ads_v1_shadow_selection.sql'));
  await sql(read('2026-08-18_ads_v1_house_delivery.sql'));
  await sql(read('2026-08-19_ads_v1_cpc_delivery.sql'));
  await sql(func(read('2026-08-20_ads_v1_all_spots_foundation.sql'),'select_delivery_candidate_v2'));
  await sql(func(read('2026-08-20_ads_v1_all_spots_foundation.sql'),'replace_campaign_placements'));
  await sql(`ALTER FUNCTION ads.select_delivery_candidate_v2(text,timestamptz,text,character,text,integer,text,text[],uuid[]) OWNER TO ads_owner`);
  // All-spots migration also migrates legacy data. This fixture creates only its required placement.
  await sql(`INSERT INTO ads.schema_migrations(migration_key,description) VALUES('2026-08-20_ads_v1_all_spots_foundation','synthetic inventory');
    INSERT INTO ads.placements(placement_key,channel,surface,format_key,device_class,status) VALUES('rr-sidebar-banner-300x250','ROADRUNNERS','SIDEBAR','IMAGE','ALL','ACTIVE');
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO ads_owner,runner;`);
  await sql(read('2026-08-21_ads_phase2_payments.sql'));
  await sql(read('2026-09-02_ads_event_auction_ranking.sql'));
  await sql(func(read('2026-08-20_ads_v1_house_banner.sql'),'save_house_banner_campaign'));
  const onboarding=business('2026-08-24_ads_pending_onboarding.sql');
  await sql(onboarding.slice(onboarding.indexOf('CREATE TABLE IF NOT EXISTS ads.campaign_review_requests'),onboarding.indexOf('CREATE OR REPLACE FUNCTION ads.guard_reserved_voucher_redemption')));
  for(const name of ['submit_campaign_review','review_campaign','cancel_open_campaign_reviews'])await sql(func(onboarding,name));
  await sql(business('2026-08-25_ads_refresh_campaign_review_permission.sql'));
  await sql(business('2026-09-11_ads_prepare_pending_campaign_edit.sql'));
  await sql(read('2026-09-04_ads_review_activation_invariants.sql'));
  await sql(`DO $b$ DECLARE f regprocedure; BEGIN FOR f IN SELECT oid::regprocedure FROM pg_proc WHERE pronamespace='ads'::regnamespace LOOP EXECUTE format('ALTER FUNCTION %s OWNER TO ads_owner',f);END LOOP; END $b$;
    ALTER TABLE ads.campaign_review_requests OWNER TO ads_owner; ALTER TABLE ads.campaign_review_history OWNER TO ads_owner;
    GRANT SELECT ON ads.campaign_review_requests,ads.campaign_review_history TO ads_reader;
    REVOKE ALL ON FUNCTION ads.cancel_open_campaign_reviews(bigint,integer,text),ads.replace_campaign_placements(uuid,text[],integer,text) FROM PUBLIC;
    GRANT EXECUTE ON FUNCTION ads.cancel_open_campaign_reviews(bigint,integer,text) TO ads_admin;
    GRANT EXECUTE ON FUNCTION ads.replace_campaign_placements(uuid,text[],integer,text) TO ads_business;
    REVOKE ALL ON FUNCTION ads.save_house_banner_campaign(uuid,bigint,text,text,text,integer,integer,text,integer,integer,text,text,boolean,timestamptz,timestamptz,integer,integer,integer,bigint) FROM PUBLIC;
    GRANT EXECUTE ON FUNCTION ads.save_house_banner_campaign(uuid,bigint,text,text,text,integer,integer,text,integer,integer,text,text,boolean,timestamptz,timestamptz,integer,integer,integer,bigint) TO ads_business;
`);
  await sql(`REVOKE ALL ON FUNCTION ads.submit_campaign_review(uuid,bigint,integer,integer) FROM PUBLIC; GRANT EXECUTE ON FUNCTION ads.submit_campaign_review(uuid,bigint,integer,integer) TO ads_business`);
  // Immutable reviewed HOUSE baseline: the live workspace migration was replaced by an operator query.
  // Recovered byte-for-byte from the September 15 final-review added-file diff; no runtime source edits.
  await sql(readFileSync(resolve(root,'_codex/tests/paid-banner-house-scope-baseline.sql'),'utf8'));
}
