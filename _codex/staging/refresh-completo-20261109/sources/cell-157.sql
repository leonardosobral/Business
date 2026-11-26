-- Total de linhas — editor versus DataGrip
WITH q0 AS (
-- TOTAL DE CONCLUINTES

select count(res.id_resultado) from tb_resultados res
inner join tb_evento_corridas evt ON evt.id_evento = res.id_evento
where evt.data_final between '2025-01-01' and '2025-12-31' and evt.pais = 'BR'
),
q1 AS (
-- TOTAL DE CONCLUINTES

select count(res.id_resultado) from vw_resultados res
inner join tb_evento_corridas evt ON evt.id_evento = res.id_evento
where evt.data_final between '2025-01-01' and '2025-12-31' and evt.pais = 'BR'
)
SELECT 'Editor' AS versao, count AS total FROM q0
UNION ALL
SELECT 'DataGrip' AS versao, count AS total FROM q1;