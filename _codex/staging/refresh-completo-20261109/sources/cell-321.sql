WITH base AS MATERIALIZED (
 SELECT e.id_evento,e.nome_evento,e.data_final,r.sexo,r.tempo_total
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e USING(id_evento)
 WHERE r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE
   AND r.tempo_total>TIME '00:00:00' AND r.percurso BETWEEN 42 AND 42.2
   AND r.pcd IS FALSE AND e.tipo_corrida='rua' AND e.pais='BR'
   AND (e.ranking IS NULL OR e.ranking<>'false')
   AND e.data_final>=DATE '2026-01-01' AND e.data_final<DATE '2026-09-27'
), por_evento AS (
 SELECT id_evento,nome_evento,data_final,count(*) AS concluintes,
   count(*) FILTER(WHERE sexo='F') AS feminino,count(*) FILTER(WHERE sexo='M') AS masculino,
   count(*) FILTER(WHERE tempo_total IS NULL OR tempo_total=TIME '00:00:00') AS tempo_ausente_ou_zero,
   count(*) FILTER(WHERE tempo_total<TIME '04:00:00') AS sub4,
   count(*) FILTER(WHERE tempo_total<TIME '03:00:00') AS sub3,
   count(*) FILTER(WHERE tempo_total<TIME '02:30:00') AS sub2h30,
   min(tempo_total)::text AS tempo_minimo,
   to_char(make_interval(secs=>avg(extract(epoch FROM tempo_total))::double precision),'HH24:MI:SS') AS tempo_medio,
   to_char(make_interval(secs=>percentile_cont(0.5) WITHIN GROUP(ORDER BY extract(epoch FROM tempo_total))),'HH24:MI:SS') AS tempo_mediano
 FROM base GROUP BY id_evento,nome_evento,data_final
), ranking AS (
 SELECT *,row_number() OVER(ORDER BY concluintes DESC,id_evento) AS posicao
 FROM por_evento
)
SELECT jsonb_build_object(
 'coletado_em',transaction_timestamp(),'read_only',current_setting('transaction_read_only'),
 'populacao','Parcial 2026: status=0/homologado/concluinte e tempo positivo, BR/rua, 42–42.2km, pcd=false, ranking diferente de false ou nulo; dez maiores até o corte, não as dez da edição 2025.',
 'eventos',(SELECT count(*) FROM por_evento),'concluintes',(SELECT count(*) FROM base),
 'mulheres',(SELECT count(*) FROM base WHERE sexo='F'),
 'top10_soma',(SELECT sum(concluintes) FROM ranking WHERE posicao<=10),
 'top10',(SELECT jsonb_agg(to_jsonb(r) ORDER BY posicao) FROM ranking r WHERE posicao<=10)
) AS payload