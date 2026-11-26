\ir classifications.sql
ALTER TABLE public.tb_paginas ADD COLUMN tag text;
INSERT INTO public.tb_paginas VALUES (28882,true,'gneto25');
INSERT INTO public.tb_usuarios VALUES (139,true),(49983,false);
CREATE TABLE public.tb_paginas_usuarios(id_pagina integer,id_usuario integer);
INSERT INTO public.tb_paginas_usuarios VALUES(28882,49983);
\ir ../../sql/2026-11-24_verified_elite.sql
\ir ../../sql/2026-11-24_verified_elite.sql
DO $$
DECLARE rev bigint;
BEGIN
 ASSERT (SELECT count(*)=1 FROM rr_verified.admin_classifications WHERE profile_id=28882);
 ASSERT (SELECT category='elite' AND actor_id=139 FROM rr_verified.admin_classifications WHERE profile_id=28882);
 ASSERT (SELECT count(*)=2 FROM rr_verified.admin_classifications WHERE profile_id=10);
 ASSERT (SELECT verificado FROM tb_paginas WHERE id_pagina=28882);
 ASSERT (SELECT count(*)=2 FROM tb_paginas WHERE verificado);
 ASSERT NOT has_table_privilege('runner','rr_verified.admin_classifications','UPDATE');
 ASSERT NOT has_table_privilege('runner','rr_verified.admin_classifications','DELETE');
 ASSERT NOT has_function_privilege('public','rr_verified.classify_permanent_badge(integer,text,text,integer,bigint)','EXECUTE');
 BEGIN
  PERFORM rr_verified.classify_permanent_badge(28882,'elite','Alteração sem permissão',2,0);
  RAISE EXCEPTION 'Non-admin elite write accepted';
 EXCEPTION WHEN insufficient_privilege THEN NULL; END;
 BEGIN
  PERFORM rr_verified.classify_permanent_badge(20,'elite','Sem selo permanente',139,0);
  RAISE EXCEPTION 'Annual profile classified as permanent';
 EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
 BEGIN
  PERFORM rr_verified.classify_permanent_badge(28882,'elite','Revisão antiga',139,0);
  RAISE EXCEPTION 'Stale revision accepted';
 EXCEPTION WHEN serialization_failure THEN NULL; END;
END $$;
SELECT 'VERIFIED_ELITE_PASSED';
