SET LOCAL lock_timeout='3s';
DO $r$ BEGIN IF NOT EXISTS (SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p04-faixas' AND version=1 AND encode(sha256(convert_to(content,'UTF8')),'hex')='c31f0942aa75f7335f2ee6bbb379c79b9b6c455632e12e492929f89c3da3dab9' FOR UPDATE) THEN RAISE EXCEPTION 'Célula alterada: pdf-2025-p04-faixas'; END IF; UPDATE estudo.notebook_cells SET content='-- Idades: mesmas faixas e populações; agregar intervalos antes do cruzamento.
WITH intervalos AS (
 SELECT r.idade_range,coalesce(r.sexo,''N/A'') AS sexo,
 count(r.id_resultado) AS editor,
 count(r.id_resultado) FILTER(WHERE r.status_final=0 AND r.homologado IS TRUE) AS datagrip
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e ON e.id_evento=r.id_evento
 WHERE e.pais=''BR'' AND e.data_final BETWEEN DATE ''2025-01-01'' AND DATE ''2025-12-31''
 GROUP BY r.idade_range,r.sexo
), popula AS (
 SELECT ''Editor / geral'' AS versao,idade_range,sum(editor) AS n FROM intervalos GROUP BY idade_range
 UNION ALL SELECT ''DataGrip / geral'',idade_range,sum(datagrip) FROM intervalos GROUP BY idade_range
 UNION ALL SELECT ''Editor / ''||sexo,idade_range,editor FROM intervalos WHERE sexo IN (''F'',''M'')
 UNION ALL SELECT ''DataGrip / ''||sexo,idade_range,datagrip FROM intervalos WHERE sexo IN (''F'',''M'')
), versoes AS (
 SELECT ''Editor / geral'' AS versao UNION ALL SELECT ''DataGrip / geral''
 UNION ALL SELECT ''Editor / F'' UNION ALL SELECT ''Editor / M''
 UNION ALL SELECT ''DataGrip / F'' UNION ALL SELECT ''DataGrip / M''
), faixas AS (
SELECT 1 AS ordem, ''13–19'' AS faixa, int4range(13,20,''[)'') AS r
UNION ALL
SELECT 2 AS ordem, ''20–24'' AS faixa, int4range(20,25,''[)'') AS r
UNION ALL
SELECT 3 AS ordem, ''25–29'' AS faixa, int4range(25,30,''[)'') AS r
UNION ALL
SELECT 4 AS ordem, ''30–34'' AS faixa, int4range(30,35,''[)'') AS r
UNION ALL
SELECT 5 AS ordem, ''35–39'' AS faixa, int4range(35,40,''[)'') AS r
UNION ALL
SELECT 6 AS ordem, ''40–44'' AS faixa, int4range(40,45,''[)'') AS r
UNION ALL
SELECT 7 AS ordem, ''45–49'' AS faixa, int4range(45,50,''[)'') AS r
UNION ALL
SELECT 8 AS ordem, ''50–54'' AS faixa, int4range(50,55,''[)'') AS r
UNION ALL
SELECT 9 AS ordem, ''55–59'' AS faixa, int4range(55,60,''[)'') AS r
UNION ALL
SELECT 10 AS ordem, ''60–64'' AS faixa, int4range(60,65,''[)'') AS r
UNION ALL
SELECT 11 AS ordem, ''65–69'' AS faixa, int4range(65,70,''[)'') AS r
UNION ALL
SELECT 12 AS ordem, ''70+'' AS faixa, int4range(70,NULL,''[)'') AS r
), agregados AS (
 SELECT v.versao,f.ordem,f.faixa,coalesce(sum(p.n),0) AS total
 FROM versoes v CROSS JOIN faixas f
 LEFT JOIN popula p ON p.versao=v.versao AND p.idade_range && f.r
 GROUP BY v.versao,f.ordem,f.faixa
)
SELECT versao,faixa,total,round(total*100.0/nullif(sum(total) OVER(PARTITION BY versao),0),2) AS porcentagem
FROM agregados ORDER BY versao,ordem;',origem=CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 4, "fontes": ["editor:03_faixa_etaria.sql.txt:4", "datagrip:INFOGRAFICO.sql.txt:9"], "regra": "Derivação explícita do bloco do editor: executa geral/F/M em tb_resultados e vw_resultados, mantendo 13–19, sobreposição e duas casas para comparar. As repetições por fonte/sexo são intencionais.", "data_registro": "2026-09-28", "otimizacao": "Após timeout da revisão 1: agrega as contagens por intervalo/sexo antes do join &&. Mantém as seis populações, o primeiro grupo 13–19 e o denominador por associações; não é correção metodológica."}' AS jsonb),updated_by=NULL WHERE source_key='pdf-2025-p04-faixas'; END $r$;
DO $r$ BEGIN IF NOT EXISTS (SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p04-faixas-nota' AND version=1 AND encode(sha256(convert_to(content,'UTF8')),'hex')='d7e9745cd831ae0275769042bed5c0923e85699e3d19f9bd76bd928696b1bb85' FOR UPDATE) THEN RAISE EXCEPTION 'Célula alterada: pdf-2025-p04-faixas-nota'; END IF; UPDATE estudo.notebook_cells SET content='### Idades — duas fontes, geral e por sexo

Derivação explícita do bloco do editor: executa geral/F/M em tb_resultados e vw_resultados, mantendo 13–19, sobreposição e duas casas para comparar. As repetições por fonte/sexo são intencionais.

**Linhas de origem:** `editor:03_faixa_etaria.sql.txt:4`, `datagrip:INFOGRAFICO.sql.txt:9`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.

**Otimização da execução:** a revisão 1 atingiu 45s. A revisão seguinte agrega por intervalo/sexo antes do cruzamento. Preserva as populações, as sobreposições e os percentuais; reduz a repetição de varreduras.',origem=CAST('{"tipo": "conciliacao_por_pagina", "pagina_pdf": 4, "referencia_pdf": "https://roadrunners.run/brasilquecorreprovas/BrasilQueCorreProvas2025_v3.10.3.pdf", "data_registro": "2026-09-28"}' AS jsonb),updated_by=NULL WHERE source_key='pdf-2025-p04-faixas-nota'; END $r$;
DO $r$ BEGIN IF NOT EXISTS (SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p05-historico' AND version=1 AND encode(sha256(convert_to(content,'UTF8')),'hex')='2a20b33645aa8d7d6c4af85b55b85882894ecef7924d4885d8993fdedfa48e7e' FOR UPDATE) THEN RAISE EXCEPTION 'Célula alterada: pdf-2025-p05-historico'; END IF; UPDATE estudo.notebook_cells SET content='-- Gerações históricas: mesmos ranges e sexos, com pré-agregação.
WITH intervalos AS (
 SELECT extract(year FROM e.data_final)::integer AS ano,r.idade_range,count(*) AS n
 FROM public.vw_resultados r JOIN public.tb_evento_corridas e ON e.id_evento=r.id_evento
 WHERE e.pais=''BR'' AND e.data_final>=DATE ''2023-01-01'' AND e.data_final<DATE ''2026-01-01''
 AND (extract(year FROM e.data_final)=2023 OR extract(year FROM e.data_final)=2024 AND r.sexo=''M''
 OR extract(year FROM e.data_final)=2025 AND r.sexo=''F'')
 GROUP BY extract(year FROM e.data_final),r.idade_range
), faixas AS (
SELECT 2025 AS ano, f.* FROM (
  SELECT 1 AS ordem, ''Alfa'' AS faixa, int4range(0, 15, ''[)'') AS r UNION ALL
  SELECT 2, ''Z'', int4range(16, 28, ''[)'') UNION ALL
  SELECT 3, ''Y'', int4range(29, 44, ''[)'') UNION ALL
  SELECT 4, ''X'', int4range(45, 60, ''[)'') UNION ALL
  SELECT 12, ''60+'',   int4range(60, NULL, ''[)'')
) f
UNION ALL
SELECT 2024 AS ano, f.* FROM (
  SELECT 1 AS ordem, ''Alfa'' AS faixa, int4range(0, 15, ''[)'') AS r UNION ALL
  SELECT 2, ''Z'', int4range(16, 28, ''[)'') UNION ALL
  SELECT 3, ''Y'', int4range(29, 44, ''[)'') UNION ALL
  SELECT 4, ''X'', int4range(45, 60, ''[)'') UNION ALL
  SELECT 12, ''Boomers'',   int4range(60, NULL, ''[)'')
) f
UNION ALL
SELECT 2023 AS ano, f.* FROM (
  SELECT 1 AS ordem, ''Alfa'' AS faixa, int4range(0, 14, ''[)'') AS r UNION ALL
  SELECT 2, ''Z'', int4range(15, 28, ''[)'') UNION ALL
  SELECT 3, ''Y'', int4range(29, 44, ''[)'') UNION ALL
  SELECT 4, ''X'', int4range(45, 60, ''[)'') UNION ALL
  SELECT 12, ''Boomers'',   int4range(60, NULL, ''[)'')
) f
), agregados AS (
 SELECT f.ano,f.ordem,f.faixa,coalesce(sum(i.n),0) AS total
 FROM faixas f LEFT JOIN intervalos i ON i.ano=f.ano AND i.idade_range && f.r
 GROUP BY f.ano,f.ordem,f.faixa
)
SELECT CASE ano WHEN 2025 THEN ''DataGrip 2025 / F'' WHEN 2024 THEN ''DataGrip 2024 / M'' ELSE ''DataGrip 2023 / geral'' END AS versao,
 faixa,total,round(total*100.0/nullif(sum(total) OVER(PARTITION BY ano),0),1) AS porcentagem
FROM agregados ORDER BY ano,ordem;',origem=CAST('{"tipo": "consulta_conciliacao", "pagina_pdf": 5, "fontes": ["datagrip:INFOGRAFICO.sql.txt:10", "datagrip:INFOGRAFICO.sql.txt:11", "datagrip:INFOGRAFICO.sql.txt:12"], "regra": "Preserva os filtros salvos F/2025, M/2024 e geral/2023; não interpretar essa saída como evolução anual de uma população comum.", "data_registro": "2026-09-28", "otimizacao": "Pré-agrega por ano/intervalo antes de cruzar as faixas literais; preserva filtros de sexo e limites dos três blocos de origem."}' AS jsonb),updated_by=NULL WHERE source_key='pdf-2025-p05-historico'; END $r$;