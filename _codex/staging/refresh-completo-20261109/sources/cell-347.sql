WITH parametros AS (
 SELECT DATE '2025-01-01' AS inicio, DATE '2025-10-01' AS fim_exclusivo
), base AS MATERIALIZED (
 SELECT r.sexo,r.percurso,r.idade_range,e.tipo_corrida,e.estado,e.cidade,e.data_final
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e USING(id_evento)
 CROSS JOIN parametros p
 WHERE r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE
   AND e.pais='BR' AND e.data_final>=p.inicio AND e.data_final<p.fim_exclusivo
), dimensoes AS (
 SELECT 'sexo'::text AS indicador,'geral'::text AS segmento,
   coalesce(nullif(btrim(sexo),''),'Não informado') AS categoria,count(*) AS total
 FROM base GROUP BY 3
 UNION ALL
 SELECT 'uf','geral',coalesce(nullif(upper(btrim(estado)),''),'Não informado'),count(*) FROM base GROUP BY 3
 UNION ALL
 SELECT 'cidade','geral',coalesce(nullif(btrim(cidade),''),'Não informada')||' · '||coalesce(nullif(upper(btrim(estado)),''),'UF não informada'),count(*) FROM base GROUP BY 3
 UNION ALL
 SELECT 'mes','geral',extract(month FROM data_final)::int::text,count(*) FROM base GROUP BY 3
 UNION ALL
 SELECT 'trimestre','geral',extract(quarter FROM data_final)::int::text,count(*) FROM base GROUP BY 3
 UNION ALL
 SELECT 'distancia_floor','geral',floor(percurso)::text,count(*) FROM base WHERE tipo_corrida='rua' AND percurso>0 GROUP BY 3
), idade AS MATERIALIZED (
 SELECT sexo,idade_range,count(*) AS n FROM base GROUP BY sexo,idade_range
), faixas(categoria,r) AS (VALUES
 ('Menos de 14',int4range(0,14,'[)')),('14–19',int4range(14,20,'[)')),
 ('20–24',int4range(20,25,'[)')),('25–29',int4range(25,30,'[)')),
 ('30–34',int4range(30,35,'[)')),('35–39',int4range(35,40,'[)')),
 ('40–44',int4range(40,45,'[)')),('45–49',int4range(45,50,'[)')),
 ('50–54',int4range(50,55,'[)')),('55–59',int4range(55,60,'[)')),
 ('60–64',int4range(60,65,'[)')),('65–69',int4range(65,70,'[)')),
 ('70+',int4range(70,NULL,'[)'))
), idades AS (
 SELECT i.sexo,CASE WHEN i.idade_range IS NULL THEN 'Sem faixa informada'
   WHEN isempty(i.idade_range) THEN 'Idade indeterminada'
   ELSE coalesce(f.categoria,'Idade indeterminada') END AS categoria,i.n
 FROM idade i LEFT JOIN faixas f ON NOT isempty(i.idade_range) AND i.idade_range <@ f.r
), distancias AS MATERIALIZED (
 SELECT sexo,CASE WHEN percurso<6 THEN 'Até 5 km' WHEN percurso<11 THEN '6 a 10 km'
   WHEN percurso<30 THEN '11 a 29 km' ELSE '+30 km' END AS categoria,count(*) AS n
 FROM base WHERE tipo_corrida='rua' AND percurso>0 GROUP BY sexo,2
), uf_regiao AS (
 SELECT uf,CASE WHEN count(DISTINCT regiao)=1 THEN max(regiao) END AS regiao
 FROM public.tb_uf GROUP BY uf
), geografia AS (
 SELECT coalesce(nullif(upper(btrim(estado)),''),'Não informado') AS uf,sexo,count(*) AS n
 FROM base GROUP BY 1,sexo
), regioes AS (
 SELECT coalesce(u.regiao,'Não informada') AS regiao,g.sexo,g.n
 FROM geografia g LEFT JOIN uf_regiao u ON u.uf=g.uf
), contagens AS (
 SELECT * FROM dimensoes
 UNION ALL SELECT 'idade','geral',categoria,sum(n) FROM idades GROUP BY categoria
 UNION ALL SELECT 'idade',sexo,categoria,sum(n) FROM idades WHERE sexo IN('F','M') GROUP BY sexo,categoria
 UNION ALL SELECT 'distancia_faixas','geral',categoria,sum(n) FROM distancias GROUP BY categoria
 UNION ALL SELECT 'sexo_dentro_distancia',categoria,coalesce(nullif(btrim(sexo),''),'Não informado'),sum(n) FROM distancias GROUP BY categoria,sexo
 UNION ALL SELECT 'regiao','geral',regiao,sum(n) FROM regioes GROUP BY regiao
 UNION ALL SELECT 'sexo_por_regiao',regiao,coalesce(nullif(btrim(sexo),''),'Não informado'),sum(n) FROM regioes GROUP BY regiao,sexo
), percentuais AS (
 SELECT *,sum(total) OVER(PARTITION BY indicador,segmento) AS denominador,
   total*100.0/nullif(sum(total) OVER(PARTITION BY indicador,segmento),0) AS percentual
 FROM contagens
)
SELECT jsonb_build_object(
 'coletado_em',transaction_timestamp(),'read_only',current_setting('transaction_read_only'),
 'parametros',(SELECT to_jsonb(p) FROM parametros p),
 'populacao','BR por data_final; status_final=0, homologado=true e concluinte=true. Inclui todas as idades e modalidades; distâncias usam rua/percurso positivo. Sem filtro de idade 14+, pois os intervalos amplos não permitem esse corte com precisão.',
 'resultados',(SELECT count(*) FROM base),
 'ultima_data_evento',(SELECT max(data_final) FROM base),
 'recortes',(SELECT jsonb_agg(to_jsonb(p) ORDER BY indicador,segmento,categoria) FROM percentuais p)
) AS payload