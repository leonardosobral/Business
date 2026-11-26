-- Categoria Atleta de elite e classificação de Guilherme Neto, autorizadas em 24/11/2026.
-- Executar inteiro em runnerhub como runner_dba. Reexecução não duplica o histórico.
-- Não altera selos, validade, pedidos, pagamentos ou classificações de outras pessoas.
BEGIN;
SET LOCAL lock_timeout='5s';
SET LOCAL statement_timeout='30s';
SELECT pg_advisory_xact_lock(72623,28882);
DO $guard$
BEGIN
 IF current_database()<>'runnerhub' OR current_user<>'runner_dba' THEN RAISE EXCEPTION 'Execute em runnerhub como runner_dba'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.tb_paginas WHERE id_pagina=28882 AND tag='gneto25')
 OR NOT EXISTS(SELECT 1 FROM public.tb_paginas_usuarios WHERE id_pagina=28882 AND id_usuario=49983)
 OR NOT EXISTS(SELECT 1 FROM public.tb_usuarios WHERE id=139 AND is_admin)
 OR NOT EXISTS(SELECT 1 FROM rr_verified.profile_status(28882) WHERE permanent)
 THEN RAISE EXCEPTION 'Perfil, administrador ou concessão mudaram; conferir antes de executar'; END IF;
 IF md5(pg_get_functiondef('rr_verified.classify_permanent_badge(integer,text,text,integer,bigint)'::regprocedure)) NOT IN ('c456cdd6294429ecacd9fd5ec81bb108','d1aef25e4186256b7530915bf769ee18')
 THEN RAISE EXCEPTION 'Função foi modificada; revisar antes de substituir'; END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conrelid='rr_verified.admin_classifications'::regclass
 AND conname='admin_classifications_category_check' AND pg_get_constraintdef(oid) IN (
 'CHECK ((category = ANY (ARRAY[''influencer''::text, ''imprensa''::text, ''parceiro''::text, ''equipe''::text, ''cortesia''::text, ''outro''::text, ''nao_informado''::text])))','CHECK ((category = ANY (ARRAY[''elite''::text, ''influencer''::text, ''imprensa''::text, ''parceiro''::text, ''equipe''::text, ''cortesia''::text, ''outro''::text, ''nao_informado''::text])))')) THEN RAISE EXCEPTION 'Restrição de categorias mudou; revisar antes de substituir'; END IF;
END $guard$;
ALTER TABLE rr_verified.admin_classifications DROP CONSTRAINT admin_classifications_category_check;
ALTER TABLE rr_verified.admin_classifications ADD CONSTRAINT admin_classifications_category_check
 CHECK(category IN ('elite','influencer','imprensa','parceiro','equipe','cortesia','outro','nao_informado'));
CREATE OR REPLACE FUNCTION rr_verified.classify_permanent_badge(p_profile_id integer, p_category text, p_reason text, p_actor_id integer, p_expected_revision bigint)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'rr_verified', 'public'
AS $function$
DECLARE current_revision bigint; new_revision bigint;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.tb_usuarios WHERE id=p_actor_id AND is_admin IS TRUE) THEN
        RAISE EXCEPTION 'Somente administradores podem classificar selos.' USING ERRCODE='42501';
    END IF;
    IF p_category IS NULL OR p_category NOT IN ('elite','influencer','imprensa','parceiro','equipe','cortesia','outro','nao_informado')
       OR p_reason IS NULL OR length(btrim(p_reason)) NOT BETWEEN 5 AND 2000
       OR p_expected_revision IS NULL OR p_expected_revision < 0 THEN
        RAISE EXCEPTION 'Categoria, motivo ou versão inválidos.' USING ERRCODE='22023';
    END IF;
    PERFORM pg_advisory_xact_lock(72623,p_profile_id);
    IF NOT EXISTS (SELECT 1 FROM rr_verified.profile_status(p_profile_id) WHERE permanent) THEN
        RAISE EXCEPTION 'A classificação manual exige uma concessão permanente existente.' USING ERRCODE='22023';
    END IF;
    SELECT coalesce(max(revision),0) INTO current_revision
        FROM rr_verified.admin_classifications WHERE profile_id=p_profile_id;
    IF current_revision <> p_expected_revision THEN
        RAISE EXCEPTION 'Classificação alterada em outra sessão. Reabra o perfil antes de salvar.' USING ERRCODE='40001';
    END IF;
    INSERT INTO rr_verified.admin_classifications(profile_id,category,reason,actor_id)
        VALUES(p_profile_id,p_category,btrim(p_reason),p_actor_id) RETURNING revision INTO new_revision;
    RETURN new_revision;
END;
$function$;
REVOKE ALL ON FUNCTION rr_verified.classify_permanent_badge(integer,text,text,integer,bigint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION rr_verified.classify_permanent_badge(integer,text,text,integer,bigint) TO runner;
DO $classify$
DECLARE current_revision bigint; current_category text; current_reason text;
BEGIN
 SELECT revision,category,reason INTO current_revision,current_category,current_reason
 FROM rr_verified.admin_classifications WHERE profile_id=28882 ORDER BY revision DESC LIMIT 1;
 IF current_category='elite' AND current_reason='Atleta de elite — classificação autorizada por Leonardo Sobral em 24/11/2026. Resultado vinculado ao usuário 49983: BSB City Half Marathon, 06/11/2022, 21 km, categoria ELITEM, 4º colocado (resultado 1831949). Ficha CBAt 24936: https://cbat.org.br/atletas/24936/guilherme-neto-de-sousa-ferreira.' THEN RETURN; END IF;
 IF coalesce(current_revision,0)<>0 THEN RAISE EXCEPTION 'Guilherme recebeu outra classificação; nenhuma anotação foi sobrescrita'; END IF;
 PERFORM rr_verified.classify_permanent_badge(28882,'elite','Atleta de elite — classificação autorizada por Leonardo Sobral em 24/11/2026. Resultado vinculado ao usuário 49983: BSB City Half Marathon, 06/11/2022, 21 km, categoria ELITEM, 4º colocado (resultado 1831949). Ficha CBAt 24936: https://cbat.org.br/atletas/24936/guilherme-neto-de-sousa-ferreira.',139,0);
END $classify$;
SELECT jsonb_build_object('elite_category_ready',true,'profile_id',28882,'category',
 (SELECT category FROM rr_verified.admin_classifications WHERE profile_id=28882 ORDER BY revision DESC LIMIT 1),
 'permanent_preserved',(SELECT permanent FROM rr_verified.profile_status(28882)),
 'payments_changed',false) AS receipt;
COMMIT;
