\ir classifications.sql
INSERT INTO tb_paginas VALUES(11,true);
DO $$
DECLARE previous_revision bigint; previous_count integer;
BEGIN
 SELECT max(revision) INTO previous_revision FROM rr_verified.admin_classifications WHERE profile_id=10;
 SELECT count(*) INTO previous_count FROM rr_verified.admin_classifications;
 BEGIN
  PERFORM rr_verified.classify_permanent_badge(10,'imprensa','Imprensa',1,previous_revision);
  PERFORM rr_verified.classify_permanent_badge(11,'imprensa','Imprensa',1,99);
  RAISE EXCEPTION 'Expected conflict';
 EXCEPTION WHEN serialization_failure THEN NULL;
 END;
 ASSERT (SELECT count(*)=previous_count FROM rr_verified.admin_classifications),'Partial batch survived conflict';
 ASSERT (SELECT max(revision)=previous_revision FROM rr_verified.admin_classifications WHERE profile_id=10),'Earlier item changed';
 PERFORM rr_verified.classify_permanent_badge(10,'imprensa','Imprensa — GE',1,previous_revision);
 PERFORM rr_verified.classify_permanent_badge(11,'imprensa','Imprensa — GE',1,0);
 ASSERT (SELECT count(*)=previous_count+2 FROM rr_verified.admin_classifications),'Successful batch missing';
 ASSERT (SELECT count(*)=2 FROM tb_paginas WHERE verificado),'Entitlements changed';
END $$;
SELECT 'VERIFIED_QUICK_BATCH_PASSED' AS result;
