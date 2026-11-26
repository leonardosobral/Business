-- Cidades com UF — candidato revisado
SELECT coalesce(upper(btrim(evt.estado)),'N/A') AS uf,
 coalesce(upper(btrim(evt.cidade)),'N/A') AS cidade,count(*) AS total,
 round(count(*)*100.0/nullif(sum(count(*)) OVER(),0),2) AS percentual
FROM public.vw_resultados res JOIN public.tb_evento_corridas evt ON evt.id_evento=res.id_evento
WHERE evt.pais='BR' AND evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
GROUP BY upper(btrim(evt.estado)),upper(btrim(evt.cidade)) ORDER BY total DESC LIMIT 50;