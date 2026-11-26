-- Vertical maratonas: totais autorais; participações, não pessoas únicas.
WITH base AS MATERIALIZED (
 SELECT e.id_evento,e.tipo_corrida,extract(month FROM e.data_final)::int AS mes,r.percurso,r.sexo
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e USING(id_evento)
 WHERE e.pais='BR' AND e.data_final>=DATE '2025-01-01' AND e.data_final<DATE '2026-01-01'
 AND r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE
), grupos AS (
 SELECT *,CASE WHEN percurso IS NULL OR percurso<=0 THEN 'Sem distância válida'
 WHEN percurso=5 THEN '5 km' WHEN percurso=10 THEN '10 km'
 WHEN percurso BETWEEN 21 AND 21.2 THEN '21–21,2 km'
 WHEN percurso BETWEEN 42 AND 42.2 THEN '42–42,2 km'
 ELSE 'Outras distâncias' END AS faixa FROM base
)
SELECT 2025 AS ano,current_timestamp AS coletado_em,mes,tipo_corrida,faixa,count(*) AS participacoes,
 count(DISTINCT id_evento) AS eventos,count(*) FILTER(WHERE sexo='F') AS feminino
FROM grupos GROUP BY mes,tipo_corrida,faixa ORDER BY mes,tipo_corrida,faixa