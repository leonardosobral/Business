-- Casos de fronteira independentes, usando a matriz retornada no congelamento 60.
-- Cada tempo positivo deve entrar exatamente em uma faixa; zero/nulo não entra.
WITH fonte AS (
 SELECT r FROM estudo.notebook_runs n CROSS JOIN LATERAL jsonb_array_elements(n.result->'rows') r
 WHERE n.id=60 AND n.frozen AND n.status='ok' AND NOT n.truncated AND r->>'segmento'='geral'
), casos AS (
 SELECT column1 AS indicador,column2 AS distancia,column3::numeric AS segundos,column4 AS esperado FROM (VALUES ('cna','5k',899.999,'Mestre'),('cna','5k',900,'Preta'),('cna','5k',1799.999,'Laranja'),('cna','5k',1800,'Branca'),('cna','10k',2099.999,'Mestre'),('cna','10k',2100,'Preta'),('cna','10k',3600,'Branca'),('cna','21k',4800,'Preta'),('cna','21k',7200,'Branca'),('cna','42k',8999.999,'Mestre'),('cna','42k',9000,'Preta'),('cna','42k',14400,'Branca'),('performance','5k',1200,'<20min'),('performance','5k',1200.001,'20–25min'),('performance','10k',2400,'<40min'),('performance','10k',2400.001,'40–50min'),('performance','21k',5400,'<1:30'),('performance','21k',5400.001,'1:30–2:00'),('performance','42k',14400,'<4:00'),('performance','42k',14400.001,'4:00–4:30'),('cna','5k',0,NULL),('cna','10k',NULL,NULL),('performance','21k',0,NULL),('performance','42k',NULL,NULL)) t
), conferidos AS (
 SELECT c.indicador,c.distancia,c.segundos,c.esperado,count(r) AS matches,max(r->>'faixa') AS obtido
 FROM casos c LEFT JOIN fonte f ON f.r->>'indicador'=c.indicador AND f.r->>'distancia'=c.distancia
 AND c.segundos>0 AND c.segundos<@numrange((f.r->>'minimo')::numeric,(f.r->>'maximo')::numeric,f.r->>'fronteiras')
 GROUP BY c.indicador,c.distancia,c.segundos,c.esperado
)
SELECT *,matches=CASE WHEN esperado IS NULL THEN 0 ELSE 1 END AND obtido IS NOT DISTINCT FROM esperado AS confere FROM conferidos ORDER BY indicador,distancia,segundos
