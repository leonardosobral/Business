-- P12/P13: recálculo com população única para contagens, gêneros e tempos.
-- Janela anual; seleção histórica fixa das dez provas para permitir conciliação.
-- PCD=false também exige ausência das palavras de modalidade excluídas nos SQLs recebidos.
-- Não altera cadastros. A consulta é uma candidata metodológica, não o snapshot do PDF.
WITH parametros AS (
 SELECT DATE '2025-01-01' AS inicio,DATE '2026-01-01' AS fim_exclusivo
), base AS (
 SELECT e.id_evento,e.nome_evento,r.sexo,r.tempo_total
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e USING(id_evento)
 CROSS JOIN parametros p
 WHERE e.id_evento IN(24999,24998,26867,22792,22582,27104,28253,22590,25481,24016)
 AND e.data_final>=p.inicio AND e.data_final<p.fim_exclusivo
 AND e.pais='BR' AND e.tipo_corrida='rua' AND (e.ranking IS NULL OR e.ranking<>'false')
 AND r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE
 AND r.percurso BETWEEN 42 AND 42.2 AND r.pcd IS FALSE AND r.tempo_total>TIME '00:00:00'
 AND r.modalidade NOT ILIKE '%CADEIRANTE%' AND r.modalidade NOT ILIKE '%PCD%'
 AND r.modalidade NOT ILIKE '%DI%' AND r.modalidade NOT ILIKE '%DMAI%'
 AND r.modalidade NOT ILIKE '%DMS%' AND r.modalidade NOT ILIKE '%HAND%'
 AND r.modalidade NOT ILIKE '%BIKE%' AND r.modalidade NOT ILIKE '%ACD%'
), totais AS (
 SELECT id_evento,nome_evento,count(*) AS concluintes,
 count(*) FILTER(WHERE sexo='F') AS feminino,count(*) FILTER(WHERE sexo='M') AS masculino,
 count(*) FILTER(WHERE sexo IS NULL OR sexo NOT IN('F','M')) AS outros_sexos,
 min(tempo_total)::text AS tempo_menor,
 to_char(round(avg(extract(epoch FROM tempo_total)))::double precision*INTERVAL '1 second','HH24:MI:SS') AS tempo_medio,
 to_char(round((percentile_cont(.5) WITHIN GROUP(ORDER BY extract(epoch FROM tempo_total)))::numeric)::double precision*INTERVAL '1 second','HH24:MI:SS') AS tempo_mediano,
 count(*) FILTER(WHERE tempo_total<TIME '04:00:00') AS sub4,
 count(*) FILTER(WHERE tempo_total<TIME '03:00:00') AS sub3,
 count(*) FILTER(WHERE tempo_total<TIME '02:30:00') AS sub2h30
 FROM base GROUP BY id_evento,nome_evento
)
SELECT *,feminino*100.0/nullif(concluintes,0) AS feminino_pct,
 masculino*100.0/nullif(concluintes,0) AS masculino_pct,
 sub4*100.0/nullif(concluintes,0) AS sub4_pct,
 sub3*100.0/nullif(concluintes,0) AS sub3_pct,
 sub2h30*100.0/nullif(concluintes,0) AS sub2h30_pct
FROM totais ORDER BY concluintes DESC,id_evento
