from pathlib import Path
import hashlib
root=Path('/Users/Shared/Projects/RunnerHub/Business'); stage=root/'_codex/staging/ads-network-20261104'
names=['paid_banner_content_valid','select_paid_banner_candidate','save_paid_banner_campaign']
parts=[]
for n in names:
 s=(stage/(n+'.sql')).read_text(); old=s
 alias='x' if n=='save_paid_banner_campaign' else 'p'
 needle=f"{alias}.placement_key='rr-sidebar-banner-300x250'"
 assert s.count(needle)==1
 s=s.replace(needle,f"ads.banner_placement_available({alias}.placement_id)")
 if n=='save_paid_banner_campaign':
  needle='  UPDATE ads.campaigns x SET name=v_name'
  assert s.count(needle)==1
  s=s.replace(needle,"""  UPDATE ads.campaign_placements x SET status='INACTIVE' WHERE x.campaign_id=c.campaign_id AND x.placement_id<>p AND x.status='ACTIVE';
  INSERT INTO ads.campaign_placements(campaign_id,account_id,billing_model,placement_id,status,priority,weight)
    VALUES(c.campaign_id,p_account_id,'CPC',p,'ACTIVE',1,1)
    ON CONFLICT(campaign_id,placement_id) DO UPDATE SET status='ACTIVE';
"""+needle)
 # Reject stale baselines; definitions include security/search path, preserve original ACL/owner with OR REPLACE.
 parts.append("DO $guard$ BEGIN IF NOT EXISTS(SELECT 1 FROM ads.schema_migrations WHERE migration_key='2026-11-04_ads_publisher_network') AND NOT EXISTS(SELECT 1 FROM pg_proc WHERE pronamespace='ads'::regnamespace AND proname='"+n+"' AND md5(pg_get_functiondef(oid))='"+hashlib.md5(old.encode()).hexdigest()+"') THEN RAISE EXCEPTION 'Baseline divergiu: "+n+"'; END IF; END $guard$;\n"+s+';\n')
(stage/'patches.sql').write_text('\n'.join(parts))
