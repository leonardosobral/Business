-- Calendário — editor versus DataGrip
WITH base AS (
 SELECT extract(month FROM e.data_final)::integer AS mes,extract(quarter FROM e.data_final)::integer AS trimestre,
 count(*) AS editor,count(*) FILTER(WHERE r.status_final=0 AND r.homologado IS TRUE) AS datagrip
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e ON e.id_evento=r.id_evento
 WHERE e.pais='BR' AND e.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
 GROUP BY extract(month FROM e.data_final),extract(quarter FROM e.data_final)
), recortes AS (
 SELECT 'Mês' AS periodo,mes AS ordem,'Editor' AS versao,editor AS total FROM base
 UNION ALL SELECT 'Mês',mes,'DataGrip',datagrip FROM base
 UNION ALL SELECT 'Trimestre',trimestre,'Editor',sum(editor) FROM base GROUP BY trimestre
 UNION ALL SELECT 'Trimestre',trimestre,'DataGrip',sum(datagrip) FROM base GROUP BY trimestre
)
SELECT periodo,ordem,versao,total,round(total*100.0/nullif(sum(total) OVER(PARTITION BY periodo,versao),0),2) AS percentual
FROM recortes ORDER BY periodo,ordem,versao;