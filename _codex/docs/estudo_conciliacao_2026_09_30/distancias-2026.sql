-- Completa a leitura inversa sem nova coleta nem mistura de datas.
-- A execução 33 guarda o pacote 2026 v3; usa contagens, nunca percentuais arredondados.
-- Universo: BR, status 0, homologado e concluinte; rua com percurso positivo.
-- As quatro faixas particionam todas as distâncias elegíveis de cada gênero.
WITH origem AS (
 SELECT result->'rows'->0->'payload' AS payload
 FROM estudo.notebook_runs WHERE id=33 AND frozen AND status='ok' AND NOT truncated
), contagens AS (
 SELECT substring(c->>'serie' FROM length('sexo_dentro_distancia_')+1) AS distancia,
 c->>'categoria' AS sexo,(c->'atual'->>'contagem')::bigint AS total
 FROM origem CROSS JOIN LATERAL jsonb_array_elements(payload->'comparacoes') c
 WHERE c->>'serie' IN('sexo_dentro_distancia_Até 5 km','sexo_dentro_distancia_6 a 10 km','sexo_dentro_distancia_11 a 29 km','sexo_dentro_distancia_+30 km')
 AND c->>'categoria' IN('F','M')
), percentuais AS (
 SELECT *,sum(total) OVER(PARTITION BY sexo) AS denominador FROM contagens
)
SELECT 'distancia_dentro_sexo_'||sexo AS serie,distancia AS categoria,total,denominador,
 total*100.0/nullif(denominador,0) AS percentual,33 AS execucao_origem
FROM percentuais ORDER BY sexo,distancia
