-- 2026: janeiro a setembro. Auditoria das novas fontes do DBA.
-- Mulheres / todas as participações, incluindo sexo não definido no denominador.
WITH fontes AS (
 SELECT 'tbbi_fat_perfil_br_2026'::text AS fonte,count(*) AS participacoes,
 count(DISTINCT id_resultado) AS resultados_distintos,
 count(DISTINCT id_evento) AS provas_com_participacoes,
 min(data_evento) AS primeira_data,max(data_evento) AS ultima_data,
 count(*) FILTER(WHERE data_evento<DATE '2026-01-01' OR data_evento>=DATE '2026-10-01') AS fora_jan_set,
 count(*) FILTER(WHERE idade_range IS NULL) AS sem_range,
 count(*) FILTER(WHERE sexo='F') AS participacoes_femininas,
 count(*) FILTER(WHERE sexo='M') AS participacoes_masculinas
 FROM public.tbbi_fat_perfil_br_2026
 UNION ALL
 SELECT 'vwbi_fat_perfil_br_2026',count(*),count(DISTINCT id_resultado),count(DISTINCT id_evento),
 min(data_evento),max(data_evento),
 count(*) FILTER(WHERE data_evento<DATE '2026-01-01' OR data_evento>=DATE '2026-10-01'),
 count(*) FILTER(WHERE idade_range IS NULL),
 count(*) FILTER(WHERE sexo='F'),count(*) FILTER(WHERE sexo='M')
 FROM public.vwbi_fat_perfil_br_2026
)
SELECT *,round(participacoes_femininas*100.0/nullif(participacoes,0),4) AS percentual_feminino,
 current_timestamp AS coletado_em FROM fontes ORDER BY fonte;
