CREATE ROLE runner;
CREATE SCHEMA rr_verified;
CREATE TABLE public.tb_usuarios(id integer PRIMARY KEY,is_admin boolean);
CREATE TABLE public.tb_paginas(id_pagina integer PRIMARY KEY,verificado boolean);
INSERT INTO tb_usuarios VALUES(1,true),(2,false);
INSERT INTO tb_paginas VALUES(10,true),(20,false);
CREATE FUNCTION rr_verified.profile_status(integer) RETURNS TABLE(permanent boolean)
LANGUAGE sql AS 'SELECT verificado FROM public.tb_paginas WHERE id_pagina=$1';
\ir ../../sql/2026-11-23_verified_classifications.sql
DO $$
DECLARE rev bigint; n integer;
BEGIN
 rev:=rr_verified.classify_permanent_badge(10,'imprensa','Veículo e referência conhecidos',1,0);
 ASSERT rev>0;
 ASSERT (SELECT verificado FROM tb_paginas WHERE id_pagina=10);
 BEGIN
  PERFORM rr_verified.classify_permanent_badge(10,'influencer','Autor sem permissão',2,rev);
  RAISE EXCEPTION 'Non-admin accepted';
 EXCEPTION WHEN insufficient_privilege THEN NULL; END;
 BEGIN
  PERFORM rr_verified.classify_permanent_badge(20,'influencer','Não possui concessão permanente',1,0);
  RAISE EXCEPTION 'Annual profile accepted';
 EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
 BEGIN
  PERFORM rr_verified.classify_permanent_badge(10,'vip','Pagamento não é categoria manual',1,rev);
  RAISE EXCEPTION 'Invalid category accepted';
 EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
 BEGIN
  PERFORM rr_verified.classify_permanent_badge(10,'imprensa','abc',1,rev);
  RAISE EXCEPTION 'Short reason accepted';
 EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
 BEGIN
  PERFORM rr_verified.classify_permanent_badge(10,'outro','Revisão desatualizada',1,0);
  RAISE EXCEPTION 'Stale revision accepted';
 EXCEPTION WHEN serialization_failure THEN NULL; END;
 rev:=rr_verified.classify_permanent_badge(10,'influencer','Correção com referência adicional',1,rev);
 ASSERT (SELECT count(*)=2 FROM rr_verified.admin_classifications);
 ASSERT (SELECT category='imprensa' FROM rr_verified.admin_classifications ORDER BY revision LIMIT 1);
 ASSERT (SELECT category='influencer' FROM rr_verified.admin_classifications ORDER BY revision DESC LIMIT 1);
 ASSERT (SELECT count(*)=1 FROM tb_paginas WHERE verificado);
 ASSERT NOT has_table_privilege('runner','rr_verified.admin_classifications','UPDATE');
 ASSERT NOT has_table_privilege('runner','rr_verified.admin_classifications','DELETE');
 ASSERT NOT has_function_privilege('public','rr_verified.classify_permanent_badge(integer,text,text,integer,bigint)','EXECUTE');
END $$;
\ir ../../sql/2026-11-23_verified_classifications.sql
SELECT 'VERIFIED_CLASSIFICATIONS_PASSED' AS result;
