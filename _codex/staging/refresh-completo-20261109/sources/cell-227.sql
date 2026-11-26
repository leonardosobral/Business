-- População bruta e qualidade dos campos em 2025
SELECT count(*) AS linhas_brutas,
 count(*) FILTER(WHERE r.status_final=0 AND r.homologado IS TRUE) AS linhas_vw_resultados,
 count(*) FILTER(WHERE r.concluinte IS TRUE) AS sinalizadas_concluintes,
 count(*) FILTER(WHERE r.idade_range IS NULL) AS idade_ausente,
 count(*) FILTER(WHERE r.tempo_total IS NULL) AS tempo_nulo,
 count(*) FILTER(WHERE r.tempo_total=TIME '00:00:00') AS tempo_zero,
 count(*) FILTER(WHERE r.sexo IS NULL OR btrim(r.sexo)='') AS sexo_ausente
FROM public.tb_resultados r JOIN public.tb_evento_corridas e ON e.id_evento=r.id_evento
WHERE e.pais='BR' AND e.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31';