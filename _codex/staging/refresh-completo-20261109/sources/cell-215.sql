-- Maratonas — faixas sub4/sub3/sub2h30
WITH base AS (
 SELECT e.id_evento,e.nome_evento,r.sexo,r.tempo_total
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e USING(id_evento)
 WHERE r.status_final=0 AND r.homologado IS TRUE AND r.percurso BETWEEN 42 AND 42.2
   AND r.pcd IS FALSE AND e.tipo_corrida='rua' AND e.pais='BR'
   AND (e.ranking IS NULL OR e.ranking<>'false')
   AND e.data_final>=DATE '2025-01-01' AND e.data_final<DATE '2026-01-01'
), por_evento AS (
 SELECT id_evento,nome_evento,count(*) AS concluintes,
   count(*) FILTER(WHERE sexo='F') AS feminino,count(*) FILTER(WHERE sexo='M') AS masculino,
   count(*) FILTER(WHERE tempo_total IS NULL OR tempo_total=TIME '00:00:00') AS tempo_ausente_ou_zero,
   count(*) FILTER(WHERE tempo_total<TIME '04:00:00') AS sub4,
   count(*) FILTER(WHERE tempo_total<TIME '03:00:00') AS sub3,
   count(*) FILTER(WHERE tempo_total<TIME '02:30:00') AS sub2h30,
   min(tempo_total)::text AS tempo_minimo,
   to_char((avg(extract(epoch FROM tempo_total))::double precision * INTERVAL '1 second'),'HH24:MI:SS') AS tempo_medio,
   to_char((percentile_cont(0.5) WITHIN GROUP(ORDER BY extract(epoch FROM tempo_total)) * INTERVAL '1 second'),'HH24:MI:SS') AS tempo_mediano
 FROM base GROUP BY id_evento,nome_evento
), ranking AS (
 SELECT *,row_number() OVER(ORDER BY concluintes DESC,id_evento) AS posicao
 FROM por_evento
)
SELECT posicao,id_evento,nome_evento,concluintes,sub4,round(sub4*100.0/nullif(concluintes,0),2) AS sub4_pct,
sub3,round(sub3*100.0/nullif(concluintes,0),2) AS sub3_pct,
sub2h30,round(sub2h30*100.0/nullif(concluintes,0),2) AS sub2h30_pct,tempo_ausente_ou_zero
FROM ranking WHERE id_evento IN(24999,24998,26867,22792,22582,27104,28253,22590,25481,24016) ORDER BY posicao;