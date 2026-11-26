-- CANDIDATO READ ONLY: um único SELECT JSON agregado, sem PII.
WITH fonte AS MATERIALIZED (
SELECT r.id_resultado,r.id_evento,r.percurso,r.sexo,r.tempo_total,
 r.idade_range,r.data_nascimento,r.id_usuario,r.pcd,
 r.homologado AS resultado_homologado,r.concluinte,r.status_final,r.modalidade,
 e.data_final,e.data_inicial,e.estado,e.cidade,e.organizador,
 e.homologado AS evento_homologado,e.tipo_corrida
FROM public.tb_resultados r
JOIN public.tb_evento_corridas e ON e.id_evento=r.id_evento
WHERE e.pais='BR'
 AND e.data_final>=DATE '2026-01-01' AND e.data_final<DATE '2026-10-01'
 AND r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE
), nulls AS (
 SELECT count(*) AS eligible,count(DISTINCT id_resultado) AS unique_results,
 count(*) FILTER(WHERE id_resultado IS NULL) AS null_id,
 count(*) FILTER(WHERE sexo IS NULL) AS null_sex,
 count(*) FILTER(WHERE length(sexo)>1) AS sex_over_varchar1,
 count(*) FILTER(WHERE percurso IS NULL) AS null_distance,
 count(*) FILTER(WHERE pcd IS NULL) AS null_pcd,
 count(*) FILTER(WHERE evento_homologado IS NULL) AS null_event_homologated,
 count(*) FILTER(WHERE evento_homologado IS FALSE) AS false_event_homologated,
 count(*) FILTER(WHERE tempo_total IS NULL) AS null_time,
 count(*) FILTER(WHERE tempo_total=TIME '00:00:00') AS zero_time,
 count(*) FILTER(WHERE modalidade='KIDS') AS kids,
 count(*) FILTER(WHERE modalidade IS NULL) AS null_modality,
 count(*) FILTER(WHERE tipo_corrida NOT IN ('rua','trail') OR tipo_corrida IS NULL) AS other_event_types,
 count(*) FILTER(WHERE data_inicial IS NULL) AS null_start_date
 FROM fonte
), date_keys AS (
 SELECT data_referencia,count(*) AS matches FROM public.tbbi_dim_data GROUP BY data_referencia
), dimensions AS (
SELECT 'tbbi_dim_data' AS dimension,count(*) AS duplicate_keys FROM (SELECT id_data FROM public.tbbi_dim_data WHERE id_data IS NOT NULL GROUP BY id_data HAVING count(*)>1)d UNION ALL SELECT 'tbbi_dim_localidade' AS dimension,count(*) AS duplicate_keys FROM (SELECT id_localidade FROM public.tbbi_dim_localidade WHERE id_localidade IS NOT NULL GROUP BY id_localidade HAVING count(*)>1)d UNION ALL SELECT 'tbbi_dim_geracoes' AS dimension,count(*) AS duplicate_keys FROM (SELECT id_geracao FROM public.tbbi_dim_geracoes WHERE id_geracao IS NOT NULL GROUP BY id_geracao HAVING count(*)>1)d UNION ALL SELECT 'tbbi_dim_faixas' AS dimension,count(*) AS duplicate_keys FROM (SELECT id_faixa FROM public.tbbi_dim_faixas WHERE id_faixa IS NOT NULL GROUP BY id_faixa HAVING count(*)>1)d UNION ALL SELECT 'tbbi_dim_cbat_categorias' AS dimension,count(*) AS duplicate_keys FROM (SELECT id_cbat_categoria FROM public.tbbi_dim_cbat_categorias WHERE id_cbat_categoria IS NOT NULL GROUP BY id_cbat_categoria HAVING count(*)>1)d UNION ALL SELECT 'tbbi_dim_organizacao_2026' AS dimension,count(*) AS duplicate_keys FROM (SELECT id_organizacao FROM public.tbbi_dim_organizacao_2026 WHERE id_organizacao IS NOT NULL GROUP BY id_organizacao HAVING count(*)>1)d UNION ALL SELECT 'tbbi_dim_cronometragem' AS dimension,count(*) AS duplicate_keys FROM (SELECT id_cronometragem FROM public.tbbi_dim_cronometragem WHERE id_cronometragem IS NOT NULL GROUP BY id_cronometragem HAVING count(*)>1)d
), months AS (
 SELECT date_trunc('month',data_final)::date AS month,count(*) AS eligible FROM fonte GROUP BY 1
), generations AS (
 SELECT public.get_id_geracao(idade_range,extract(year FROM data_final)::integer,data_nascimento,data_final) AS generation_id,count(*) AS eligible FROM fonte GROUP BY 1
), signatures AS (
 SELECT signature,expected,to_regprocedure(signature) AS oid FROM (VALUES ('public.get_id_categoria_cbat(int4range)','aa6fe20f75af7d049cc0cb1bb49fbfc5'),('public.get_id_dim_faixa(numeric,time without time zone)','547a306bfba2b1bd9fe072b76869608d'),('public.get_id_geracao(int4range,integer)','4ceab31871e33e5eb841c16d6e37cd82'),('public.get_id_geracao(int4range,integer,date,date)','221972b658c5e11554e75a9b361da415')
 ) f(signature,expected)
)
SELECT jsonb_build_object(
 'transaction_read_only',current_setting('transaction_read_only'),'actor',current_user,
 'range','[2026-01-01,2026-10-01)','source_script_sha256','d9907382d2de1c9d396d4edb0d23c907c89aa0e74bca62cfa6783c99b34c6a08',
 'nulls_and_universe',(SELECT to_jsonb(n) FROM nulls n),
 'months',(SELECT jsonb_agg(to_jsonb(m) ORDER BY month) FROM months m),
 'generation',(SELECT jsonb_agg(to_jsonb(g) ORDER BY generation_id) FROM generations g),
 'duplicate_dimension_ids',(SELECT jsonb_agg(to_jsonb(d) ORDER BY dimension) FROM dimensions d),
 'missing_start_date_dimension',(SELECT count(*) FROM fonte f LEFT JOIN date_keys d ON d.data_referencia=f.data_inicial WHERE coalesce(d.matches,0)=0),
 'ambiguous_start_date_dimension',(SELECT count(*) FROM fonte f JOIN date_keys d ON d.data_referencia=f.data_inicial WHERE d.matches>1),
 'functions',(SELECT jsonb_agg(jsonb_build_object('signature',signature,'expected_md5',expected,'actual_md5',CASE WHEN oid IS NOT NULL THEN md5(pg_get_functiondef(oid)) END,'matches',CASE WHEN oid IS NOT NULL THEN md5(pg_get_functiondef(oid))=expected ELSE false END)) FROM signatures),
 'current_view_columns',(SELECT jsonb_agg(jsonb_build_object('relation',a.attrelid::regclass::text,'position',a.attnum,'name',a.attname,'type',format_type(a.atttypid,a.atttypmod)) ORDER BY a.attrelid,a.attnum) FROM pg_attribute a WHERE a.attrelid IN('estudo.vwbi_perfil_br_2026'::regclass,'estudo.vw_resultados_2026'::regclass) AND a.attnum>0 AND NOT a.attisdropped),
 'can_create_in_estudo',has_schema_privilege(current_user,'estudo','CREATE'),
 'target_exists',to_regclass('estudo.fat_perfil_br_2026_20261109') IS NOT NULL
) AS payload;
