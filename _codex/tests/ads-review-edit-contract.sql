-- Runs the actual function against isolated fixtures; no production datasource.
DO $test$
DECLARE
 cid uuid := '11111111-1111-4111-8111-111111111111';
 old_review text;
 initial_status text;
 actor integer;
 result record;
 rejected boolean;
BEGIN
 FOREACH old_review IN ARRAY ARRAY['PENDING_REVIEW','WAITING_PREREQUISITES','APPROVED'] LOOP
  initial_status := CASE WHEN old_review='APPROVED' THEN 'ACTIVE' ELSE 'DRAFT' END;
  FOREACH actor IN ARRAY ARRAY[1,2] LOOP
   DELETE FROM ads.campaign_review_history;
   DELETE FROM ads.campaign_status_history;
   DELETE FROM ads.campaign_review_requests;
   DELETE FROM ads.campaigns;
   INSERT INTO ads.campaigns(campaign_id,account_id,billing_model,status) VALUES(cid,10,'CPC',initial_status);
   INSERT INTO ads.campaign_review_requests(campaign_id,account_id,status) VALUES(cid,10,old_review);
   SELECT * INTO result FROM ads.prepare_campaign_for_edit(cid,10,actor);
   IF result.campaign_status <> 'DRAFT' OR result.review_status <> 'CANCELED'
     OR (SELECT status FROM ads.campaigns WHERE campaign_id=cid) <> 'DRAFT'
     OR EXISTS(SELECT FROM ads.campaign_review_requests WHERE status <> 'CANCELED') THEN
    RAISE EXCEPTION 'Editing must withdraw review and stay off air: %',old_review;
   END IF;
   IF NOT EXISTS(SELECT FROM ads.campaign_review_history WHERE from_status=old_review AND to_status='CANCELED' AND actor_id=actor) THEN
    RAISE EXCEPTION 'Missing review audit';
   END IF;
   IF EXISTS(SELECT FROM ads.campaign_status_history WHERE from_status=to_status) THEN
    RAISE EXCEPTION 'Draft editing must not record a fake delivery transition';
   END IF;
  END LOOP;
 END LOOP;
 UPDATE ads.campaigns SET status='DRAFT';
 UPDATE ads.campaign_review_requests SET status='PENDING_REVIEW';
 FOREACH actor IN ARRAY ARRAY[3,4,999] LOOP
  rejected := false;
  BEGIN PERFORM ads.prepare_campaign_for_edit(cid,10,actor); EXCEPTION WHEN OTHERS THEN rejected := true; END;
  IF NOT rejected THEN RAISE EXCEPTION 'Unauthorized actor accepted: %',actor; END IF;
 END LOOP;
 rejected := false;
 BEGIN PERFORM ads.prepare_campaign_for_edit(cid,99,1); EXCEPTION WHEN OTHERS THEN rejected := true; END;
 IF NOT rejected THEN RAISE EXCEPTION 'Cross-account edit accepted'; END IF;
 UPDATE ads.campaigns SET status='ENDED';
 rejected := false;
 BEGIN PERFORM ads.prepare_campaign_for_edit(cid,10,1); EXCEPTION WHEN OTHERS THEN rejected := true; END;
 IF NOT rejected THEN RAISE EXCEPTION 'Ended campaign reopened'; END IF;
 IF (SELECT status FROM ads.campaign_review_requests WHERE campaign_id=cid) <> 'PENDING_REVIEW' THEN RAISE EXCEPTION 'Denied edit changed review'; END IF;
 IF NOT has_function_privilege('ads_business','ads.prepare_campaign_for_edit(uuid,bigint,integer)','EXECUTE')
    OR has_function_privilege('ads_reader','ads.prepare_campaign_for_edit(uuid,bigint,integer)','EXECUTE') THEN
  RAISE EXCEPTION 'Unexpected execution grants';
 END IF;
 RAISE NOTICE 'ADS REVIEW EDIT CONTRACT: PASSED';
END;
$test$;
