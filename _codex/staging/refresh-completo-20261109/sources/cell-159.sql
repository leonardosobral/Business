-- Eventos cadastrados e eventos com resultados
WITH eventos AS (
 SELECT id_evento,extract(year FROM data_final)::integer AS ano
 FROM public.tb_evento_corridas
 WHERE pais='BR' AND tipo_corrida IN ('rua','trail')
 AND data_final>=DATE '2024-01-01' AND data_final<DATE '2026-01-01'
), presenca AS (
 SELECT r.id_evento,count(*) AS linhas,
 count(*) FILTER (WHERE r.status_final=0 AND r.homologado IS TRUE) AS linhas_view
 FROM public.tb_resultados r JOIN eventos e ON e.id_evento=r.id_evento GROUP BY r.id_evento
)
SELECT e.ano,count(*) AS eventos_cadastrados,
 count(*) FILTER(WHERE p.linhas>0) AS eventos_com_resultados_brutos,
 count(*) FILTER(WHERE p.linhas_view>0) AS eventos_com_resultados_view,
 round(count(*) FILTER(WHERE p.linhas>0)*100.0/nullif(count(*),0),2) AS cobertura_bruta_pct
FROM eventos e LEFT JOIN presenca p ON p.id_evento=e.id_evento GROUP BY e.ano ORDER BY e.ano;