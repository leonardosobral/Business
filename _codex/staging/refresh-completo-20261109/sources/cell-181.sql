-- Presença de 5 km nos eventos com resultados
SELECT count(DISTINCT evt.id_evento) AS eventos_com_resultados_rua,
 count(DISTINCT evt.id_evento) FILTER(WHERE res.percurso=5) AS eventos_com_5km,
 round(count(DISTINCT evt.id_evento) FILTER(WHERE res.percurso=5)*100.0/nullif(count(DISTINCT evt.id_evento),0),2) AS percentual
FROM public.vw_resultados res JOIN public.tb_evento_corridas evt ON evt.id_evento=res.id_evento
WHERE evt.pais='BR' AND evt.tipo_corrida='rua'
AND evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31';