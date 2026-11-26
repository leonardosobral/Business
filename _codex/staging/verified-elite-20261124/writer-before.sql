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
    IF p_category IS NULL OR p_category NOT IN ('influencer','imprensa','parceiro','equipe','cortesia','outro','nao_informado')
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
$function$
