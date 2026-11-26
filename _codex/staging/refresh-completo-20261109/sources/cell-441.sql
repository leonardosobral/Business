-- Maratonas: faixas de dez anos, conforme decisão editorial de 19/10/2026.
-- Até 29 reúne o grupo inicial, incluindo categorias 18–24 e 20–29; depois30–39,40–49,50–59,60–69,70+.
-- Idade individual em31/12 tem prioridade; categorias devem caber inteiras. Sem repartir ou imputar.
-- Preserva gerações, filtros, população e critérios de conclusão dos congelamentos250/251.
-- Perfil e auditoria por prova vêm da mesma execução. Nenhuma query anterior é substituída.
WITH base AS (
 SELECT r.id_evento,coalesce(r.nome_categoria,'') AS categoria_origem, r.idade_range AS idade_range_operacional,coalesce(r.sexo,'N/A') AS sexo,r.idade_range,
 2025-extract(year FROM r.data_nascimento)::integer AS idade_31dez,
 coalesce(r.data_nascimento<=e.data_final AND 2025-extract(year FROM r.data_nascimento)::integer BETWEEN 0 AND 120,false) AS nascimento_plausivel,
 CASE WHEN e.tipo_corrida='rua' AND r.percurso>0 THEN
 CASE WHEN r.percurso<6 THEN 'Até 5 km' WHEN r.percurso<11 THEN '6 a 10 km'
 WHEN r.percurso<30 THEN '11 a 29 km' ELSE '+30 km' END END AS distancia
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e USING(id_evento)
 WHERE e.pais='BR' AND e.data_final>=DATE '2025-01-01' AND e.data_final<DATE '2026-01-01'
 AND r.status_final=0 AND r.homologado IS TRUE AND r.id_evento IN(22582,22586,22590,22591,22592,22792,23713,24012,24015,24016,24998,24999,25481,25680,25698,25720,25726,25727,25733,26506,26768,26867,26983,27088,27099,27104,27532,27635,27637,27747,27771,28253,28327,28572,28609,28610,28611,28617,29387,30471,31973) AND r.percurso BETWEEN 42 AND 42.2 AND r.concluinte IS TRUE AND r.tempo_total>TIME '00:00:00' AND r.pcd IS FALSE AND NOT(coalesce(r.modalidade,'') ~* '(CADEIR|DEFICI|ANDANTE|HAND|BIKE|GUIA|REVEZ|DUPLA|QUARTETO|OCTETO|TRAIL|(^|[^A-Z0-9])(PCD|ACD|DI|DV|DA|DMAI|DMS|CAD)([^A-Z0-9]|$))') 
), agrupados AS (
 SELECT id_evento,categoria_origem,idade_range_operacional,sexo,idade_range,idade_31dez,nascimento_plausivel,distancia,count(*) AS n FROM base
 GROUP BY id_evento,categoria_origem,idade_range_operacional,sexo,idade_range,idade_31dez,nascimento_plausivel,distancia
), normalizados AS (
 SELECT *,CASE WHEN nascimento_plausivel THEN int4range(idade_31dez,idade_31dez+1,'[)')
 WHEN idade_range IS NOT NULL AND idade_range<>'empty'::int4range
 AND lower(idade_range)>=0 AND lower(idade_range)<=120 AND (upper(idade_range) IS NULL OR upper(idade_range)<=121) THEN idade_range END AS faixa,
 CASE WHEN nascimento_plausivel THEN 'Nascimento plausível'
 WHEN idade_range IS NULL THEN 'Sem idade informada'
 WHEN idade_range<>'empty'::int4range AND lower(idade_range)>=0
 AND lower(idade_range)<=120 AND (upper(idade_range) IS NULL OR upper(idade_range)<=121) THEN 'Faixa da categoria'
 ELSE 'Dado inválido' END AS origem
 FROM agrupados
), faixas_idade AS (
 SELECT column1 AS ordem,column2 AS categoria,column3 AS faixa FROM (VALUES
 (0,'Até 29',int4range(0,30,'[)')),
 (1,'30–39',int4range(30,40,'[)')),
 (2,'40–49',int4range(40,50,'[)')),
 (3,'50–59',int4range(50,60,'[)')),
 (4,'60–69',int4range(60,70,'[)')),
 (5,'70+',int4range(70,NULL,'[)'))) t
), faixas_geracao AS (
 SELECT column1 AS ordem,column2 AS categoria,column3 AS faixa FROM (VALUES
 (0,'Menos de 14',int4range(0,14,'[)')),
 (1,'Alfa',int4range(14,2025-2010+1,'[)')),
 (2,'Geração Z',int4range(2025-2010+1,2025-1997+1,'[)')),
 (3,'Millennials',int4range(2025-1997+1,2025-1981+1,'[)')),
 (4,'Geração X',int4range(2025-1981+1,2025-1965+1,'[)')),
 (5,'Boomers',int4range(2025-1965+1,2025-1946+1,'[)')),
 (6,'Anteriores a 1946',int4range(2025-1946+1,NULL,'[)'))) t
), classificados AS (
 SELECT n.*,
 coalesce((SELECT f.categoria FROM faixas_idade f WHERE n.faixa<@f.faixa),
 CASE WHEN origem='Sem idade informada' THEN 'Sem idade informada' ELSE 'Idade indeterminada' END) AS idade,
 coalesce((SELECT f.categoria FROM faixas_geracao f WHERE n.faixa<@f.faixa),
 CASE WHEN lower(n.faixa)>=14 AND upper(n.faixa) IS NOT NULL AND (SELECT count(*) FROM faixas_geracao f WHERE n.faixa && f.faixa)<=2 THEN (SELECT f.categoria FROM faixas_geracao f WHERE f.faixa @> floor((lower(n.faixa)+upper(n.faixa)-1)/2.0)::integer) END,
 CASE WHEN origem='Sem idade informada' THEN 'Sem idade informada' ELSE 'Geração indeterminada' END) AS geracao
 FROM normalizados n
),
sexos AS (SELECT 'geral' AS sexo UNION ALL SELECT 'F' UNION ALL SELECT 'M'),
idades AS (SELECT ordem,categoria FROM faixas_idade UNION ALL SELECT 13,'Idade indeterminada' UNION ALL SELECT 14,'Sem idade informada'),
geracoes AS (SELECT ordem,categoria FROM faixas_geracao UNION ALL SELECT 7,'Geração indeterminada' UNION ALL SELECT 8,'Sem idade informada'),
origens AS (SELECT 1 AS ordem,'Nascimento plausível' AS categoria UNION ALL SELECT 2,'Faixa da categoria' UNION ALL SELECT 3,'Sem idade informada' UNION ALL SELECT 4,'Dado inválido'),
distancias AS (SELECT 1 AS ordem,'Até 5 km' AS categoria UNION ALL SELECT 2,'6 a 10 km' UNION ALL SELECT 3,'11 a 29 km' UNION ALL SELECT 4,'+30 km'),
totais AS (SELECT s.sexo,sum(c.n) AS total FROM sexos s JOIN classificados c ON s.sexo='geral' OR s.sexo=c.sexo GROUP BY s.sexo),
idade_por_sexo AS (SELECT s.sexo,f.ordem,f.categoria,coalesce(sum(c.n),0) AS total FROM sexos s CROSS JOIN idades f LEFT JOIN classificados c ON c.idade=f.categoria AND (s.sexo='geral' OR s.sexo=c.sexo) GROUP BY s.sexo,f.ordem,f.categoria),
geracao_por_sexo AS (SELECT s.sexo,f.ordem,f.categoria,coalesce(sum(c.n),0) AS total FROM sexos s CROSS JOIN geracoes f LEFT JOIN classificados c ON c.geracao=f.categoria AND (s.sexo='geral' OR s.sexo=c.sexo) GROUP BY s.sexo,f.ordem,f.categoria),
origem_por_sexo AS (SELECT s.sexo,f.ordem,f.categoria,coalesce(sum(c.n),0) AS total FROM sexos s CROSS JOIN origens f LEFT JOIN classificados c ON c.origem=f.categoria AND (s.sexo='geral' OR s.sexo=c.sexo) GROUP BY s.sexo,f.ordem,f.categoria),
criterios AS (SELECT 'Nascimento individual' AS categoria UNION ALL SELECT 'Faixa contida numa geração' UNION ALL SELECT 'Faixa atribuída por proximidade' UNION ALL SELECT 'Indeterminada ou ausente'),
com_criterio AS (SELECT c.*,CASE WHEN nascimento_plausivel THEN 'Nascimento individual' WHEN EXISTS(SELECT 1 FROM faixas_geracao f WHERE c.faixa<@f.faixa) THEN 'Faixa contida numa geração' WHEN geracao NOT IN('Sem idade informada','Geração indeterminada','Menos de 14') THEN 'Faixa atribuída por proximidade' ELSE 'Indeterminada ou ausente' END AS criterio FROM classificados c),
criterio_por_sexo AS (SELECT s.sexo,f.categoria,coalesce(sum(c.n),0) AS total FROM sexos s CROSS JOIN criterios f LEFT JOIN com_criterio c ON c.criterio=f.categoria AND(s.sexo='geral' OR s.sexo=c.sexo) GROUP BY s.sexo,f.categoria),
cruzamento AS (SELECT g.ordem AS ordem_geracao,g.categoria AS geracao,d.ordem AS ordem_distancia,d.categoria AS distancia,coalesce(sum(c.n),0) AS total FROM geracoes g CROSS JOIN distancias d LEFT JOIN classificados c ON c.geracao=g.categoria AND c.distancia=d.categoria GROUP BY g.ordem,g.categoria,d.ordem,d.categoria),
medidas AS (
 SELECT 'idade' AS bloco,i.sexo,i.ordem,i.categoria,NULL::text AS distancia,i.total,t.total AS denominador FROM idade_por_sexo i JOIN totais t USING(sexo)
 UNION ALL SELECT 'geracao',g.sexo,g.ordem,g.categoria,NULL,g.total,t.total FROM geracao_por_sexo g JOIN totais t USING(sexo)
 UNION ALL SELECT 'criterio',g.sexo,0,g.categoria,NULL,g.total,t.total FROM criterio_por_sexo g JOIN totais t USING(sexo)
 UNION ALL SELECT 'origem',g.sexo,g.ordem,g.categoria,NULL,g.total,t.total FROM origem_por_sexo g JOIN totais t USING(sexo)
 UNION ALL SELECT 'geracao_na_distancia','geral',ordem_geracao,geracao,distancia,total,sum(total) OVER(PARTITION BY distancia) FROM cruzamento
 UNION ALL SELECT 'distancia_na_geracao','geral',ordem_distancia,geracao,distancia,total,sum(total) OVER(PARTITION BY geracao) FROM cruzamento
),
provas AS (
 SELECT id_evento,sum(n) AS total,
 coalesce(sum(n) FILTER(WHERE nascimento_plausivel),0) AS nascimento,
 coalesce(sum(n) FILTER(WHERE origem='Faixa da categoria'),0) AS pela_faixa,
 coalesce(sum(n) FILTER(WHERE origem='Sem idade informada'),0) AS sem_informacao,
 coalesce(sum(n) FILTER(WHERE origem='Dado inválido'),0) AS dado_invalido,
 coalesce(sum(n) FILTER(WHERE idade='Idade indeterminada'),0) AS fora_faixa_padrao,
 coalesce(sum(n) FILTER(WHERE geracao='Geração indeterminada'),0) AS geracao_indeterminada,
 coalesce(sum(n) FILTER(WHERE idade='Idade indeterminada' AND geracao NOT IN('Geração indeterminada','Sem idade informada')),0) AS faixa_ampla_geracao_util,
 coalesce(sum(n) FILTER(WHERE idade_range IS DISTINCT FROM idade_range_operacional),0) AS range_bi_diverge_operacional,
 coalesce(sum(n) FILTER(WHERE NOT nascimento_plausivel AND idade_range IS NULL AND idade_range_operacional IS NOT NULL AND NOT isempty(idade_range_operacional)),0) AS range_so_no_operacional
 FROM classificados GROUP BY id_evento
), exemplos AS (
 SELECT id_evento,CASE WHEN origem='Sem idade informada' THEN 'Sem informação' WHEN origem='Dado inválido' THEN 'Inválido' ELSE 'Fora da faixa padrão' END AS motivo,
 categoria_origem,idade_range::text AS faixa_importada,idade_range_operacional::text AS faixa_operacional,idade,geracao,sum(n) AS total
 FROM classificados WHERE idade IN('Sem idade informada','Idade indeterminada')
 GROUP BY id_evento,2,categoria_origem,idade_range,idade_range_operacional,idade,geracao
), exemplos_rank AS (
 SELECT *,row_number() OVER(PARTITION BY id_evento,motivo ORDER BY total DESC,categoria_origem,faixa_importada) AS ordem FROM exemplos
), dados AS (
 SELECT p.*,e.nome_evento,e.data_final::text AS data,e.cidade,e.estado,e.url_resultado,e.url_hotsite,
 round(100.0*p.sem_informacao/nullif(p.total,0),2) AS sem_informacao_pct,
 round(100.0*p.fora_faixa_padrao/nullif(p.total,0),2) AS fora_faixa_padrao_pct
 FROM provas p JOIN public.tb_evento_corridas e USING(id_evento)
)
SELECT 2025 AS ano,current_timestamp AS coletado_em,jsonb_build_object(
 'provas',(SELECT jsonb_agg(to_jsonb(d) ORDER BY sem_informacao DESC,fora_faixa_padrao DESC,id_evento) FROM dados d),
 'exemplos',(SELECT jsonb_agg(to_jsonb(x) ORDER BY id_evento,motivo,ordem) FROM exemplos_rank x WHERE ordem<=6),
 'profile',(SELECT jsonb_agg(to_jsonb(p) ORDER BY bloco,sexo,categoria,ordem) FROM (
 SELECT 2025 AS ano,*,total*100.0/nullif(denominador,0) AS percentual FROM medidas) p)
) AS payload
