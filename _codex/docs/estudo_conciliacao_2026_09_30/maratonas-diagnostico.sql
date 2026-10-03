-- Diagnóstico agregado: não seleciona nomes, identificadores ou tempos individuais de atletas.
WITH base AS (
 SELECT r.*,e.nome_evento
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e USING(id_evento)
 WHERE r.id_evento IN(24999,24998,26867,22792,22582,27104,28253,22590,25481,24016)
 AND r.percurso BETWEEN 42 AND 42.99
), flags AS (
 SELECT *,status_final=0 AND homologado IS TRUE AND pcd IS FALSE AND percurso<=42.2 AS criterio_contagem,
 status_final=0 AND homologado IS TRUE AND concluinte IS TRUE
 AND modalidade NOT ILIKE '%CADEIRANTE%' AND modalidade NOT ILIKE '%PCD%'
 AND modalidade NOT ILIKE '%DI%' AND modalidade NOT ILIKE '%DMAI%'
 AND modalidade NOT ILIKE '%DMS%' AND modalidade NOT ILIKE '%HAND%'
 AND modalidade NOT ILIKE '%BIKE%' AND modalidade NOT ILIKE '%ACD%' AS criterio_tempos
 FROM base
), resumo AS (
 SELECT id_evento,nome_evento,
 count(*) FILTER(WHERE criterio_contagem) AS contagem,
 count(*) FILTER(WHERE criterio_contagem AND concluinte IS NOT TRUE) AS sem_conclusao,
 count(*) FILTER(WHERE criterio_contagem AND (tempo_total IS NULL OR tempo_total=TIME '00:00:00')) AS sem_tempo_positivo,
 min(tempo_total) FILTER(WHERE criterio_contagem)::text AS minimo_contagem,
 count(*) FILTER(WHERE criterio_tempos) AS tempos_legado,
 min(tempo_total) FILTER(WHERE criterio_tempos)::text AS minimo_tempos,
 count(*) FILTER(WHERE criterio_contagem AND NOT coalesce(criterio_tempos,false)) AS excluidos_pelo_texto_ou_conclusao,
 count(*) FILTER(WHERE criterio_contagem AND tempo_total<TIME '02:00:00') AS abaixo_2h,
 count(*) FILTER(WHERE criterio_contagem AND classificacao_total<=0) AS classificacao_zero_negativa
 FROM flags GROUP BY id_evento,nome_evento
), modalidades AS (
 SELECT id_evento,nome_evento,modalidade,pcd,count(*) AS total,min(tempo_total)::text AS minimo,max(tempo_total)::text AS maximo
 FROM flags WHERE criterio_contagem AND NOT coalesce(criterio_tempos,false)
 GROUP BY id_evento,nome_evento,modalidade,pcd
)
SELECT jsonb_build_object('resumo',(SELECT jsonb_agg(to_jsonb(r) ORDER BY id_evento) FROM resumo r),
 'modalidades_excluidas',(SELECT jsonb_agg(to_jsonb(m) ORDER BY id_evento,total DESC) FROM modalidades m)) AS payload
