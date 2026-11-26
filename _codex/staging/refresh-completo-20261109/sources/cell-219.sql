-- CNA — quatro distâncias
WITH q0 AS (
-- FAIXAS COLAB CORRIDA NO AR 5KM
SELECT
  faixa_tempo,
  total,
  ROUND(
    total * 100.0 / NULLIF(SUM(total) OVER (), 0),
    2
  ) AS porcentagem
FROM (
  SELECT
    CASE
        WHEN tempo_total < TIME '00:15:00' THEN 'Mestre < 15 min'
        WHEN tempo_total < TIME '00:17:00' THEN 'Faixa Preta < 17 min'
        WHEN tempo_total < TIME '00:20:00' THEN 'Faixa Marrom < 20 min'
        WHEN tempo_total < TIME '00:22:00' THEN 'Faixa Vermelha < 22 min'
        WHEN tempo_total < TIME '00:25:00' THEN 'Faixa Azul < 25 min'
        WHEN tempo_total < TIME '00:27:00' THEN 'Faixa Amarela < 27 min'
        WHEN tempo_total < TIME '00:30:00' THEN 'Faixa Laranja < 30 min'
        ELSE 'Faixa Branca > 30 min'
    END AS faixa_tempo,
    COUNT(*) AS total
  FROM vw_resultados res
  JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
  WHERE res.percurso = 5
    AND res.pcd = false
    AND evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
    and evt.pais = 'BR'
    --and res.sexo = 'M'
    --AND idade_range is not null
    --AND idade_range && int4range(50, 59, '[)')
    and (evt.ranking is null OR evt.ranking <> 'false')
  GROUP BY faixa_tempo
) s
ORDER BY
  CASE faixa_tempo
    WHEN 'Mestre < 15 min' THEN 8
    WHEN 'Faixa Preta < 17 min' THEN 7
    WHEN 'Faixa Marrom < 20 min' THEN 6
    WHEN 'Faixa Vermelha < 22 min' THEN 5
    WHEN 'Faixa Azul < 25 min' THEN 4
    WHEN 'Faixa Amarela < 27 min' THEN 3
    WHEN 'Faixa Laranja < 30 min' THEN 2
    ELSE 1
  END
),
q1 AS (
-- FAIXAS COLAB CORRIDA NO AR 10KM
SELECT
  faixa_tempo,
  total,
  ROUND(
    total * 100.0 / NULLIF(SUM(total) OVER (), 0),
    2
  ) AS porcentagem
FROM (
  SELECT
    CASE
        WHEN tempo_total < TIME '00:35:00' THEN 'Mestre < 35 min'
        WHEN tempo_total < TIME '00:40:00' THEN 'Faixa Preta < 40 min'
        WHEN tempo_total < TIME '00:42:00' THEN 'Faixa Marrom < 42 min'
        WHEN tempo_total < TIME '00:45:00' THEN 'Faixa Vermelha < 45 min'
        WHEN tempo_total < TIME '00:50:00' THEN 'Faixa Azul < 50 min'
        WHEN tempo_total < TIME '00:55:00' THEN 'Faixa Amarela < 55 min'
        WHEN tempo_total < TIME '01:00:00' THEN 'Faixa Laranja < 60 min'
        ELSE 'Faixa Branca > 60 min'
    END AS faixa_tempo,
    COUNT(*) AS total
  FROM vw_resultados res
    JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
    where res.percurso = 10 and res.pcd = false
    AND evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
    and evt.pais = 'BR'
    --and res.sexo = 'M'
    and (evt.ranking is null OR evt.ranking <> 'false')
  GROUP BY faixa_tempo
) s
ORDER BY
  CASE faixa_tempo
    WHEN 'Mestre < 35 min' THEN 8
    WHEN 'Faixa Preta < 40 min' THEN 7
    WHEN 'Faixa Marrom < 42 min' THEN 6
    WHEN 'Faixa Vermelha < 45 min' THEN 5
    WHEN 'Faixa Azul < 50 min' THEN 4
    WHEN 'Faixa Amarela < 55 min' THEN 3
    WHEN 'Faixa Laranja < 60 min' THEN 2
    ELSE 1
  END
),
q2 AS (
-- FAIXAS COLAB CORRIDA NO AR 21KM
SELECT
  faixa_tempo,
  total,
  ROUND(
    total * 100.0 / NULLIF(SUM(total) OVER (), 0),
    2
  ) AS porcentagem
FROM (
  SELECT
    CASE
        WHEN tempo_total < TIME '01:20:00' THEN 'Mestre < 1:20'
        WHEN tempo_total < TIME '01:25:00' THEN 'Faixa Preta < 1:25'
        WHEN tempo_total < TIME '01:30:00' THEN 'Faixa Marrom < 1:30'
        WHEN tempo_total < TIME '01:40:00' THEN 'Faixa Vermelha < 1:40'
        WHEN tempo_total < TIME '01:45:00' THEN 'Faixa Azul < 1:45'
        WHEN tempo_total < TIME '01:50:00' THEN 'Faixa Amarela < 1:50'
        WHEN tempo_total < TIME '02:00:00' THEN 'Faixa Laranja < 2h'
        ELSE 'Faixa Branca > 2h'
    END AS faixa_tempo,
    COUNT(*) AS total
  FROM vw_resultados res
    JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
    where res.percurso between 21 and 21.1 and res.pcd = false
    AND evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
    and evt.pais = 'BR'
    --and res.sexo = 'M'
    and (evt.ranking is null OR evt.ranking <> 'false')
  GROUP BY faixa_tempo
) s
ORDER BY
  CASE faixa_tempo
    WHEN 'Mestre < 1:20' THEN 8
    WHEN 'Faixa Preta < 1:25' THEN 7
    WHEN 'Faixa Marrom < 1:30' THEN 6
    WHEN 'Faixa Vermelha < 1:40' THEN 5
    WHEN 'Faixa Azul < 1:45' THEN 4
    WHEN 'Faixa Amarela < 1:50' THEN 3
    WHEN 'Faixa Laranja < 2h' THEN 2
    ELSE 1
  END
),
q3 AS (
-- FAIXAS COLAB CORRIDA NO AR 42KM
SELECT
  faixa_tempo,
  total,
  ROUND(
    total * 100.0 / NULLIF(SUM(total) OVER (), 0),
    2
  ) AS porcentagem
FROM (
  SELECT
    CASE
        WHEN tempo_total < TIME '02:30:00' THEN 'Mestre < 2:30'
        WHEN tempo_total < TIME '02:45:00' THEN 'Faixa Preta < 2:45'
        WHEN tempo_total < TIME '03:00:00' THEN 'Faixa Marrom < 3h'
        WHEN tempo_total < TIME '03:15:00' THEN 'Faixa Vermelha < 3:15'
        WHEN tempo_total < TIME '03:30:00' THEN 'Faixa Azul < 3:30'
        WHEN tempo_total < TIME '03:45:00' THEN 'Faixa Amarela < 3:45'
        WHEN tempo_total < TIME '04:00:00' THEN 'Faixa Laranja < 4h'
        ELSE 'Faixa Branca > 4h'
    END AS faixa_tempo,
    COUNT(*) AS total
  FROM vw_resultados res
    JOIN tb_evento_corridas evt
    ON evt.id_evento = res.id_evento
    where res.percurso between 42 and 42.2 and res.pcd = false
    AND evt.data_final BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
    and evt.pais = 'BR'
    --and res.sexo = 'M'
    and (evt.ranking is null OR evt.ranking <> 'false')
  GROUP BY faixa_tempo
) s
ORDER BY
  CASE faixa_tempo
    WHEN 'Mestre < 2:30' THEN 8
    WHEN 'Faixa Preta < 2:45' THEN 7
    WHEN 'Faixa Marrom < 3h' THEN 6
    WHEN 'Faixa Vermelha < 3:15' THEN 5
    WHEN 'Faixa Azul < 3:30' THEN 4
    WHEN 'Faixa Amarela < 3:45' THEN 3
    WHEN 'Faixa Laranja < 4h' THEN 2
    ELSE 1
  END
)
SELECT '5k' AS versao, faixa_tempo,total,porcentagem FROM q0
UNION ALL
SELECT '10k' AS versao, faixa_tempo,total,porcentagem FROM q1
UNION ALL
SELECT '21k' AS versao, faixa_tempo,total,porcentagem FROM q2
UNION ALL
SELECT '42k' AS versao, faixa_tempo,total,porcentagem FROM q3;