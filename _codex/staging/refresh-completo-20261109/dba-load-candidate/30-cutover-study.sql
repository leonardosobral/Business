-- EXECUTAR O ARQUIVO INTEIRO EM NOVA CONEXÃO/CONSOLE DATAGRIP, SEM TRANSAÇÃO PENDENTE.
-- Uma aba nova pode compartilhar conexão; confirme uma conexão nova e limpa.
-- O guard não detecta uma transação REPEATABLE READ anterior; não confirmar DML de outra tarefa.
-- CANDIDATO SEPARADO. Só após revisão e controle da carga10.
-- Troca exclusivamente os dois adaptadores do estudo; produto/publicações ficam fixados.
BEGIN ISOLATION LEVEL REPEATABLE READ;
SET LOCAL search_path=pg_catalog,public;
SET LOCAL standard_conforming_strings=on;
SET LOCAL lock_timeout='2s';
SET LOCAL statement_timeout='15min';
DO $guard$
BEGIN
 IF current_setting('transaction_isolation') IS DISTINCT FROM 'repeatable read' THEN RAISE EXCEPTION 'A sessão não está em REPEATABLE READ; encerre a transação anterior'; END IF;
 IF NOT pg_try_advisory_xact_lock(9282026,1109) THEN RAISE EXCEPTION 'Carga/cutover em curso'; END IF;
 IF EXISTS(SELECT 1 FROM (VALUES ('public.get_id_categoria_cbat(int4range)','aa6fe20f75af7d049cc0cb1bb49fbfc5'),('public.get_id_dim_faixa(numeric,time without time zone)','547a306bfba2b1bd9fe072b76869608d'),('public.get_id_geracao(int4range,integer)','4ceab31871e33e5eb841c16d6e37cd82'),('public.get_id_geracao(int4range,integer,date,date)','221972b658c5e11554e75a9b361da415')) f(signature,expected) WHERE to_regprocedure(signature) IS NULL OR md5(pg_get_functiondef(to_regprocedure(signature))) IS DISTINCT FROM expected) THEN RAISE EXCEPTION 'Função mudou ou assinatura ausente; releia antes da carga'; END IF;
 IF EXISTS(SELECT 1 FROM (VALUES ('estudo.vwbi_perfil_br_2026','19b2d5dfdaec0ff8eaeea4bdf5c57cdb'),('estudo.vw_resultados_2026','51d27f43da989bb1f50bdc414f54192e'),('public.vwbi_fat_perfil_br_2026','fddd821daa89826c4284eb5a81b954d0'),('estudo.vw_resultados_comparativo_2025_2026','5d6c7b6d81cbbe774e0963e6e8ab65fb')) v(name,expected) WHERE to_regclass(name) IS NULL OR md5(pg_get_viewdef(to_regclass(name),true)) IS DISTINCT FROM expected) THEN RAISE EXCEPTION 'View vigente mudou; releia antes de prosseguir'; END IF;
 IF EXISTS (
 SELECT 1 FROM (VALUES ('estudo.vwbi_perfil_br_2026','estudo.vwbi_perfil_br_2026_20261109'),('estudo.vw_resultados_2026','estudo.vw_resultados_2026_20261109')) p(old_name,new_name)
 CROSS JOIN LATERAL (SELECT jsonb_agg(jsonb_build_array(attnum,attname,atttypid,atttypmod,attcollation) ORDER BY attnum) AS signature FROM pg_attribute WHERE attrelid=to_regclass(p.old_name) AND attnum>0 AND NOT attisdropped) old
 CROSS JOIN LATERAL (SELECT jsonb_agg(jsonb_build_array(attnum,attname,atttypid,atttypmod,attcollation) ORDER BY attnum) AS signature FROM pg_attribute WHERE attrelid=to_regclass(p.new_name) AND attnum>0 AND NOT attisdropped) new
 WHERE old.signature IS DISTINCT FROM new.signature
) THEN RAISE EXCEPTION 'Contrato de colunas/tipos/ordem da view mudou'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.fat_perfil_br_2026_20261109_audit WHERE status='ready_for_review') THEN RAISE EXCEPTION 'Carga não está validada'; END IF;
 IF (SELECT count(*) FROM estudo.fat_perfil_br_2026_20261109)<>(SELECT (quality->>'fact')::bigint FROM estudo.fat_perfil_br_2026_20261109_audit) THEN RAISE EXCEPTION 'Fato candidata mudou após validação'; END IF;
END;
$guard$;
CREATE OR REPLACE VIEW estudo.vwbi_perfil_br_2026 AS SELECT * FROM estudo.vwbi_perfil_br_2026_20261109;
CREATE OR REPLACE VIEW estudo.vw_resultados_2026 AS SELECT * FROM estudo.vw_resultados_2026_20261109;
DO $verify$
BEGIN
 IF (SELECT count(*) FROM estudo.vw_resultados_2026)<>(SELECT count(*) FROM estudo.fat_perfil_br_2026_20261109) THEN RAISE EXCEPTION 'Conservação após cutover falhou'; END IF;
 IF md5(pg_get_viewdef('public.vwbi_fat_perfil_br_2026'::regclass,true))<>'fddd821daa89826c4284eb5a81b954d0' THEN RAISE EXCEPTION 'View pública mudou'; END IF;
END;
$verify$;
UPDATE estudo.fat_perfil_br_2026_20261109_audit SET status='activated',activated_at=clock_timestamp(),activated_views=jsonb_build_object('estudo.vwbi_perfil_br_2026',md5(pg_get_viewdef('estudo.vwbi_perfil_br_2026'::regclass,true)),'estudo.vw_resultados_2026',md5(pg_get_viewdef('estudo.vw_resultados_2026'::regclass,true)));
SELECT to_jsonb(a) AS cutover_receipt FROM estudo.fat_perfil_br_2026_20261109_audit a;
COMMIT;
