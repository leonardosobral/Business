-- Auditoria agregada das dez maratonas do congelamento 2026 v3.
-- Consulta da base atual em 30/09, sem modificar o pacote congelado de 27/09.
-- Duas horas é um limiar de revisão; não exclui resultados automaticamente.
WITH base AS (
 SELECT r.id_evento,e.nome_evento,r.modalidade,r.pcd,r.tempo_total
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e USING(id_evento)
 WHERE r.id_evento IN(43066,34236,33486,34235,29291,34529,38863,37310,34841,39421)
 AND r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE
 AND r.pcd IS FALSE AND r.percurso BETWEEN 42 AND 42.2 AND r.tempo_total>TIME '00:00:00'
), grupos AS (
 SELECT id_evento,nome_evento,modalidade,count(*) AS registros,
 min(tempo_total)::text AS minimo,max(tempo_total)::text AS maximo
 FROM base WHERE tempo_total<TIME '02:00:00' GROUP BY id_evento,nome_evento,modalidade
)
SELECT * FROM grupos ORDER BY id_evento,modalidade