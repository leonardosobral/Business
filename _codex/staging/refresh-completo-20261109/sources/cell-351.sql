-- BI 2026: fato e estrutura da view do DBA; adapter estudo conserva IDs sem localidade.
-- Nascimento/modalidade/ranking complementados por id_resultado; nenhuma junção por nome.
WITH base AS MATERIALIZED (
 SELECT r.sexo,r.percurso,extract(epoch FROM r.tempo_total) AS segundos,r.pcd,
        e.tipo_corrida,e.ranking
 FROM estudo.vw_resultados_2026 r JOIN public.tb_evento_corridas e USING(id_evento)
 WHERE r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE
   AND r.tempo_total>TIME '00:00:00' AND e.pais='BR'
   AND e.data_final>=DATE '2026-01-01' AND e.data_final<DATE '2026-10-01'
   AND (r.percurso IN(5,10) OR r.percurso>=21 AND r.percurso<22 OR r.percurso>=42 AND r.percurso<43)
), desempenho AS (
 SELECT sexo,
   CASE WHEN percurso=5 THEN '5k' WHEN percurso=10 THEN '10k' WHEN percurso<22 THEN '21k' ELSE '42k' END AS distancia,
   CASE WHEN percurso=5 THEN CASE WHEN segundos<=1200 THEN 1 WHEN segundos<=1500 THEN 2 WHEN segundos<=1800 THEN 3 ELSE 4 END
        WHEN percurso=10 THEN CASE WHEN segundos<=2400 THEN 1 WHEN segundos<=3000 THEN 2 WHEN segundos<=3600 THEN 3 ELSE 4 END
        WHEN percurso<22 THEN CASE WHEN segundos<=5400 THEN 1 WHEN segundos<=7200 THEN 2 WHEN segundos<=9000 THEN 3 ELSE 4 END
        ELSE CASE WHEN segundos<=10800 THEN 1 WHEN segundos<=12600 THEN 2 WHEN segundos<=14400 THEN 3 WHEN segundos<=16200 THEN 4 ELSE 5 END
   END AS faixa_ordem
 FROM base WHERE tipo_corrida='rua'
), cna AS (
 SELECT sexo,
   CASE WHEN percurso=5 THEN '5k' WHEN percurso=10 THEN '10k' WHEN percurso<22 THEN '21k' ELSE '42k' END AS distancia,
   CASE WHEN percurso=5 THEN CASE WHEN segundos<900 THEN 8 WHEN segundos<1020 THEN 7 WHEN segundos<1200 THEN 6 WHEN segundos<1320 THEN 5 WHEN segundos<1500 THEN 4 WHEN segundos<1620 THEN 3 WHEN segundos<1800 THEN 2 ELSE 1 END
        WHEN percurso=10 THEN CASE WHEN segundos<2100 THEN 8 WHEN segundos<2400 THEN 7 WHEN segundos<2520 THEN 6 WHEN segundos<2700 THEN 5 WHEN segundos<3000 THEN 4 WHEN segundos<3300 THEN 3 WHEN segundos<3600 THEN 2 ELSE 1 END
        WHEN percurso<22 THEN CASE WHEN segundos<4800 THEN 8 WHEN segundos<5100 THEN 7 WHEN segundos<5400 THEN 6 WHEN segundos<6000 THEN 5 WHEN segundos<6300 THEN 4 WHEN segundos<6600 THEN 3 WHEN segundos<7200 THEN 2 ELSE 1 END
        ELSE CASE WHEN segundos<9000 THEN 8 WHEN segundos<9900 THEN 7 WHEN segundos<10800 THEN 6 WHEN segundos<11700 THEN 5 WHEN segundos<12600 THEN 4 WHEN segundos<13500 THEN 3 WHEN segundos<14400 THEN 2 ELSE 1 END
   END AS faixa_ordem
 FROM base WHERE pcd IS FALSE AND (ranking IS NULL OR ranking<>'false')
   AND (percurso IN(5,10) OR percurso BETWEEN 21 AND 21.1 OR percurso BETWEEN 42 AND 42.2)
), todos AS (
 SELECT 'performance' AS indicador,* FROM desempenho
 UNION ALL SELECT 'cna',* FROM cna
), contagens AS (
 SELECT indicador,distancia,faixa_ordem,
   CASE WHEN grouping(sexo)=1 THEN 'geral' ELSE coalesce(sexo,'N/A') END AS segmento,
   count(*) AS total
 FROM todos GROUP BY GROUPING SETS((indicador,distancia,faixa_ordem,sexo),(indicador,distancia,faixa_ordem))
), percentuais AS (
 SELECT *,sum(total) OVER(PARTITION BY indicador,distancia,segmento) AS denominador,
 round(total*100.0/nullif(sum(total) OVER(PARTITION BY indicador,distancia,segmento),0),4) AS percentual
 FROM contagens
)
SELECT jsonb_build_object(
 'coletado_em',transaction_timestamp(),'read_only',current_setting('transaction_read_only'),
 'status','parcial_2026_concluintes_com_tempo_positivo',
 'cna_faixas',jsonb_build_array('Branca','Laranja','Amarela','Azul','Vermelha','Marrom','Preta','Mestre'),
 'recortes',(SELECT jsonb_agg(to_jsonb(p) ORDER BY indicador,distancia,segmento,faixa_ordem) FROM percentuais p)
) AS payload