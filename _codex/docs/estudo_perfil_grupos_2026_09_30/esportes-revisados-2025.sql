-- P15: atividades de 2025. Mesmo recorte de data/tipo da célula 223, com diagnóstico de delete.
-- total_bruto reproduz a regra antiga; total exclui indicação de exclusão enviada pelo Strava.
-- Denominador inclui todos os tipos preenchidos, inclusive Run; são atividades, não usuários.
WITH a AS (
 SELECT type,count(*) AS total_bruto,
 count(*) FILTER(WHERE strava_raw->>'aspect_type'='delete') AS excluidos_delete,
 count(*) FILTER(WHERE (strava_raw->>'aspect_type') IS DISTINCT FROM 'delete') AS total
 FROM public.tb_strava_activities
 WHERE activity_date>=DATE '2025-01-01' AND activity_date<DATE '2026-01-01'
 GROUP BY type
)
SELECT 2025 AS ano,a.*,sum(total_bruto) OVER() AS registros,
sum(total_bruto) FILTER(WHERE type IS NULL) OVER() AS tipo_nulo,
sum(total_bruto) FILTER(WHERE type IS NOT NULL) OVER() AS denominador_bruto,
sum(total) FILTER(WHERE type IS NOT NULL) OVER() AS denominador
FROM a ORDER BY total DESC,type
