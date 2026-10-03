-- P12/P13 2026: auditoria agregada antes de qualquer filtro novo ou ranking.
-- Universo do ranking anterior: BR/rua, encerradas até 26/09, 42–42,2 km,
-- status 0/homologado/concluinte e tempo positivo; preserva PCD e texto para revisar.
-- Tempo abaixo de 2h só sinaliza revisão; não descarta automaticamente.
WITH base AS (
 SELECT e.id_evento,e.nome_evento,e.data_final,r.modalidade,r.pcd,r.tempo_total,r.tempo_bruto
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e USING(id_evento)
 WHERE e.pais='BR' AND e.tipo_corrida='rua' AND (e.ranking IS NULL OR e.ranking<>'false')
 AND e.data_final>=DATE '2026-01-01' AND e.data_final<DATE '2026-09-27'
 AND r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE
 AND r.percurso BETWEEN 42 AND 42.2 AND r.tempo_total>TIME '00:00:00'
), eventos AS (
 SELECT id_evento,count(*) FILTER(WHERE pcd IS FALSE) AS elegiveis_anteriores FROM base GROUP BY id_evento
), top AS (
 SELECT *,row_number() OVER(ORDER BY elegiveis_anteriores DESC,id_evento) AS ordem FROM eventos
)
SELECT b.id_evento,b.nome_evento,b.data_final,b.modalidade,b.pcd,count(*) AS quantidade,
 min(tempo_total)::text AS minimo,max(tempo_total)::text AS maximo,
 count(*) FILTER(WHERE tempo_total<TIME '02:00:00') AS sub2,
 min(tempo_bruto)::text AS minimo_bruto,
 count(*) FILTER(WHERE tempo_total<TIME '02:00:00' AND tempo_bruto>=TIME '02:00:00') AS sub2_liquido_com_bruto_maior,
 count(*) FILTER(WHERE tempo_bruto>TIME '00:00:00' AND tempo_total>tempo_bruto) AS liquido_maior_bruto,
 count(*) FILTER(WHERE tempo_bruto IS NULL OR tempo_bruto=TIME '00:00:00') AS bruto_ausente_zero
 FROM base b JOIN top t ON t.id_evento=b.id_evento AND t.ordem<=10
 GROUP BY b.id_evento,b.nome_evento,b.data_final,b.modalidade,b.pcd
 ORDER BY b.id_evento,b.pcd,b.modalidade
