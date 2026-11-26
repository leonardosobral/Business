-- P09/P10: percentuais derivados de contagens já congeladas, sem consultar resultados novamente.
-- 2024/2025: execução 21 (vw_resultados BR, ano pela data final); UF 22 / DataGrip.
-- 2026: execução 74; não altera corte, resultados, crescimento ou coortes.
-- Dentro de cada gênero usa total nacional do gênero; dentro da região inclui outros/não informados.
WITH bruto AS(SELECT r->>'versao' AS versao,r->>'regiao' AS regiao,(r->>'total')::bigint AS n FROM estudo.notebook_runs a CROSS JOIN LATERAL jsonb_array_elements(a.result->'rows') r WHERE a.id=21 AND a.frozen AND a.status='ok' AND NOT a.truncated),
nomes AS(SELECT column1 AS codigo,column2 AS nome FROM(VALUES('SE','Sudeste'),('NE','Nordeste'),('S','Sul'),('CO','Centro-Oeste'),('N','Norte'),('N/A','Não informada')) t),
b AS(SELECT b.*,coalesce(n.nome,'Não informada') AS nome,sum(b.n) OVER(PARTITION BY versao) AS denominador FROM bruto b LEFT JOIN nomes n ON n.codigo=b.regiao),
p AS(SELECT result->'rows'->0->'payload' AS payload FROM estudo.notebook_runs WHERE id=74 AND frozen AND status='ok' AND NOT truncated),
c AS(SELECT x->>'serie' AS serie,x->>'categoria' AS categoria,(x->'atual'->>'contagem')::bigint AS n FROM p CROSS JOIN LATERAL jsonb_array_elements(payload->'comparacoes') x),
f AS(SELECT r->>'estado' AS uf,(r->>'total')::bigint AS n FROM estudo.notebook_runs a CROSS JOIN LATERAL jsonb_array_elements(a.result->'rows') r WHERE a.id=22 AND a.frozen AND a.status='ok' AND NOT a.truncated AND r->>'versao'='DataGrip'),
g AS(SELECT 2025 AS ano,'regioes_'||left(versao,4) AS serie,nome AS categoria,n,denominador,21 AS fonte FROM b WHERE versao IN('2024 / geral','2025 / geral')
 UNION ALL SELECT 2025,'regioes_'||CASE WHEN versao='2025 / F' THEN 'feminino' ELSE 'masculino' END||'_rotulos_visiveis',nome,n,denominador,21 FROM b WHERE versao IN('2025 / F','2025 / M')
 UNION ALL SELECT 2025,'sexo_por_regiao_'||s.nome,right(s.versao,1),s.n,g.n,21 FROM b s JOIN b g ON g.regiao=s.regiao AND g.versao='2025 / geral' WHERE s.versao IN('2025 / F','2025 / M')
 UNION ALL SELECT 2025,'sexo_por_regiao_'||g.nome,'X',g.n-f.n-m.n,g.n,21 FROM b g JOIN b f ON f.regiao=g.regiao AND f.versao='2025 / F' JOIN b m ON m.regiao=g.regiao AND m.versao='2025 / M' WHERE g.versao='2025 / geral'
 UNION ALL SELECT 2025,'ufs',uf,n,(SELECT sum(n) FROM f),22 FROM f
 UNION ALL SELECT 2025,'ufs_top_grafico',CASE WHEN uf IN('SP','RJ','PR','MG','SC','BA','DF','CE','RS') THEN uf ELSE 'Outros' END,sum(n),(SELECT sum(n) FROM f),22 FROM f GROUP BY 3
 UNION ALL SELECT 2026,'regioes_'||CASE WHEN s.categoria='F' THEN 'feminino' ELSE 'masculino' END||'_rotulos_visiveis',replace(r.serie,'sexo_por_regiao_',''),r.n,s.n,74 FROM c r JOIN c s ON s.serie='sexo_2026' AND s.categoria=r.categoria WHERE r.serie LIKE 'sexo_por_regiao_%' AND r.categoria IN('F','M')
 UNION ALL SELECT 2026,'regioes_'||CASE WHEN s.categoria='F' THEN 'feminino' ELSE 'masculino' END||'_rotulos_visiveis','Não informada',s.n-(SELECT sum(r.n) FROM c r WHERE r.serie LIKE 'sexo_por_regiao_%' AND r.categoria=s.categoria),s.n,74 FROM c s WHERE s.serie='sexo_2026' AND s.categoria IN('F','M')
)
SELECT *,n*100.0/nullif(denominador,0) AS percentual FROM g ORDER BY ano,serie,categoria
