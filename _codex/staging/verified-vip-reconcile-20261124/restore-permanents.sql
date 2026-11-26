-- Emergency reversal of this batch's entitlement conversion only.
-- Financial evidence/events remain intact. Do not execute routinely.
BEGIN;
SET LOCAL lock_timeout='5s';
SET LOCAL statement_timeout='30s';
SELECT pg_advisory_xact_lock(hashtext('rr_verified:foundation'));
DO $guard$
BEGIN
 IF current_database()<>'runnerhub' OR current_user<>'runner_dba' THEN RAISE EXCEPTION 'Wrong database/role'; END IF;
 IF (SELECT count(*) FROM rr_verified.legacy_reclassifications WHERE profile_id IN (2732,9438,11469,12322,13813,15572,15644,16236,16431,17465,17698,17888,17923,18537,18542,18744,18803,18856,18938,18996,19144,19279,19288,19432,21688,28882,53025,53134,53618,53754,53789,53794,53798,53812,53816,53820,53823,53839,53848,53850,53854,53857) AND reason='Origem Todo Santo Dia VIP/upgrade; conciliação de 42 pagamentos e aplicação do prazo autorizadas pelo proprietário em 24/11/2026' AND approved_at>now()-interval '48 hours')<>42
 OR (SELECT count(*) FROM crm_interno.audit WHERE action='verified.vip_reconciled' AND details->>'batch'='verified-vip-20261124')<>42
 THEN RAISE EXCEPTION 'Batch changed or rollback window expired'; END IF;
END $guard$;
SELECT pg_advisory_xact_lock(742912,id_pagina) FROM public.tb_paginas WHERE id_pagina IN (2732,9438,11469,12322,13813,15572,15644,16236,16431,17465,17698,17888,17923,18537,18542,18744,18803,18856,18938,18996,19144,19279,19288,19432,21688,28882,53025,53134,53618,53754,53789,53794,53798,53812,53816,53820,53823,53839,53848,53850,53854,53857) ORDER BY id_pagina;
UPDATE public.tb_paginas SET verificado=true WHERE id_pagina IN (2732,9438,11469,12322,13813,15572,15644,16236,16431,17465,17698,17888,17923,18537,18542,18744,18803,18856,18938,18996,19144,19279,19288,19432,21688,28882,53025,53134,53618,53754,53789,53794,53798,53812,53816,53820,53823,53839,53848,53850,53854,53857);
DELETE FROM rr_verified.legacy_reclassifications WHERE profile_id IN (2732,9438,11469,12322,13813,15572,15644,16236,16431,17465,17698,17888,17923,18537,18542,18744,18803,18856,18938,18996,19144,19279,19288,19432,21688,28882,53025,53134,53618,53754,53789,53794,53798,53812,53816,53820,53823,53839,53848,53850,53854,53857);
INSERT INTO crm_interno.audit(actor_id,action,entity_id,revision,details)
 VALUES(139,'verified.vip_conversion_reversed','verified-vip-20261124',0,'{"scope":"restore_permanents_only","financial_history_preserved":true}');
COMMIT;
