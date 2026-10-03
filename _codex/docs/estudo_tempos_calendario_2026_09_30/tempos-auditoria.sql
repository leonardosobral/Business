-- Diagnóstico antes de revisar P08/P14. Não altera cadastros nem descarta automaticamente modalidades.
-- As distâncias e filtros CNA vêm da célula 219 revisão 1; performance, das células 189/191.
-- Universo 2025 anual e 2026 até 26/09. 2026 tem filtro adicional de concluinte.
WITH base AS (
 SELECT extract(year FROM e.data_final)::integer AS ano,r.sexo,r.percurso,r.tempo_total,r.concluinte,r.pcd,r.modalidade,e.tipo_corrida,e.ranking
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e USING(id_evento)
 WHERE e.pais='BR' AND e.data_final>=DATE '2025-01-01' AND e.data_final<DATE '2026-09-27'
 AND r.status_final=0 AND r.homologado IS TRUE
 AND (r.percurso IN(5,10) OR r.percurso>=21 AND r.percurso<22 OR r.percurso>=42 AND r.percurso<43)
), candidatos AS (
 SELECT 'performance' AS indicador,*,CASE WHEN percurso=5 THEN '5k' WHEN percurso=10 THEN '10k' WHEN percurso<22 THEN '21k' ELSE '42k' END AS distancia
 FROM base WHERE tipo_corrida='rua'
 UNION ALL
 SELECT 'cna',*,CASE WHEN percurso=5 THEN '5k' WHEN percurso=10 THEN '10k' WHEN percurso<22 THEN '21k' ELSE '42k' END
 FROM base WHERE pcd IS FALSE AND (ranking IS NULL OR ranking<>'false')
 AND (percurso IN(5,10) OR percurso BETWEEN 21 AND 21.1 OR percurso BETWEEN 42 AND 42.2)
)
SELECT ano,indicador,distancia,count(*) AS legado,
 count(*) FILTER(WHERE tempo_total IS NULL) AS tempo_nulo,
 count(*) FILTER(WHERE tempo_total=TIME '00:00:00') AS tempo_zero,
 count(*) FILTER(WHERE concluinte IS NOT TRUE) AS sem_conclusao,
 count(*) FILTER(WHERE tempo_total>TIME '00:00:00' AND concluinte IS TRUE) AS concluinte_tempo_positivo,
 count(*) FILTER(WHERE tipo_corrida='rua') AS rua,
 count(*) FILTER(WHERE tipo_corrida IS NULL OR tipo_corrida<>'rua') AS outros_tipos,
 count(*) FILTER(WHERE pcd IS FALSE AND modalidade ~* 'CADEIRANTE|PCD|DMAI|DMS|HAND|BIKE|ACD') AS modalidade_pcd_com_flag_falsa,
 count(*) FILTER(WHERE pcd IS FALSE AND modalidade ~* 'CADEIRANTE|PCD|DMAI|DMS|HAND|BIKE|ACD' AND tempo_total>TIME '00:00:00' AND concluinte IS TRUE) AS modalidade_pcd_entre_elegiveis,
 count(*) FILTER(WHERE (CASE distancia WHEN '5k' THEN tempo_total<TIME '00:12:00' WHEN '10k' THEN tempo_total<TIME '00:26:00' WHEN '21k' THEN tempo_total<TIME '00:50:00' ELSE tempo_total<TIME '02:00:00' END) AND tempo_total>TIME '00:00:00' AND concluinte IS TRUE) AS abaixo_marca_auditoria
FROM candidatos GROUP BY ano,indicador,distancia ORDER BY ano,indicador,distancia
