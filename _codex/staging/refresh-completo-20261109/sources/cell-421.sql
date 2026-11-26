-- Comparativo público: referência 2025 de janeiro a setembro, mesma regra de conclusão do card 2026.
-- Derivada da célula378 relida em13/10/2026, sem alterar a fonte do DBA.
-- Coleta própria de2025;2026 preserva publicação41/run233, geografia221 de06/10.
-- Critérios: BR/rua,status0,homologado,concluinte;localização da prova.
-- Validação cidade+UF+código, dimensões ambíguas e ausentes no denominador.
WITH eventos AS (
 SELECT id_evento,extract(year FROM data_final)::integer AS ano,cod_cidade,
 upper(btrim(estado)) AS uf,
 translate(upper(regexp_replace(btrim(cidade),'\s+',' ','g')),'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ','AAAAAEEEEIIIIOOOOOUUUUC') AS nome
 FROM public.tb_evento_corridas
 WHERE pais='BR' AND upper(tipo_corrida)='RUA'
 AND data_final>=DATE '2025-01-01' AND data_final<DATE '2025-10-01'
), contagens AS (
 SELECT e.id_evento,count(*) AS n FROM eventos e JOIN public.tb_resultados r USING(id_evento)
 WHERE r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE
 GROUP BY e.id_evento
), cidades AS (
 SELECT c.cod_cidade,c.id_localidade,upper(btrim(c.uf)) AS uf,
 translate(upper(regexp_replace(btrim(c.nome_cidade),'\s+',' ','g')),'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ','AAAAAEEEEIIIIOOOOOUUUUC') AS nome
 FROM public.tb_cidades c
), chaves AS (
 SELECT nome,uf,count(*) AS candidatos,min(cod_cidade) AS codigo FROM cidades GROUP BY nome,uf
), locais AS (
 SELECT id_localidade,count(*) AS candidatos,max(upper(btrim(estado))) AS uf,
 max(translate(upper(regexp_replace(btrim(nome_cidade),'\s+',' ','g')),'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ','AAAAAEEEEIIIIOOOOOUUUUC')) AS nome,
 bool_and(capital) AS capital,count(capital) AS tem_capital
 FROM public.tbbi_dim_localidade GROUP BY id_localidade
), ufs AS (
 SELECT upper(btrim(uf)) AS uf,CASE WHEN count(DISTINCT regiao)=1 THEN max(regiao) END AS regiao
 FROM public.tb_uf GROUP BY upper(btrim(uf))
), mapa AS (
 SELECT e.*,r.n,u.regiao,l.capital,
 CASE WHEN coalesce(k.candidatos,0)=0 THEN 'Cidade/UF sem correspondência'
 WHEN k.candidatos<>1 THEN 'Cidade/UF ambígua'
 WHEN e.cod_cidade>0 AND e.cod_cidade<>k.codigo THEN 'Código diverge da cidade/UF'
 WHEN coalesce(l.candidatos,0)<>1 OR l.tem_capital<>1 OR l.uf IS NULL OR l.nome IS NULL THEN 'Dimensão ausente ou ambígua'
 WHEN l.uf<>e.uf OR l.nome<>e.nome THEN 'Dimensão diverge da cidade/UF'
 WHEN u.regiao IS NULL THEN 'UF sem região'
 WHEN e.cod_cidade>0 THEN 'Código e cidade/UF validados'
 ELSE 'Cidade/UF única; evento sem código' END AS qualidade
 FROM eventos e JOIN contagens r USING(id_evento)
 LEFT JOIN chaves k ON k.nome=e.nome AND k.uf=e.uf
 LEFT JOIN cidades c ON k.candidatos=1 AND c.cod_cidade=k.codigo
 LEFT JOIN locais l ON l.id_localidade=c.id_localidade
 LEFT JOIN ufs u ON u.uf=e.uf
), base AS (
 SELECT *,CASE WHEN qualidade IN('Código e cidade/UF validados','Cidade/UF única; evento sem código')
 THEN CASE WHEN capital THEN 'Capital' ELSE 'Interior' END ELSE 'Não classificada' END AS tipo
 FROM mapa
), geo AS (
 SELECT ano,coalesce(regiao,'Não classificada') AS regiao,tipo,sum(n) AS total FROM base GROUP BY ano,regiao,tipo
 UNION ALL SELECT ano,'Brasil',tipo,sum(n) FROM base GROUP BY ano,tipo
), qualidade AS (
 SELECT ano,qualidade,count(*) AS eventos,sum(n) AS participacoes FROM base GROUP BY ano,qualidade
), resultado AS (
 SELECT *,sum(total) OVER(PARTITION BY ano,regiao) AS denominador,
 total*100.0/nullif(sum(total) OVER(PARTITION BY ano,regiao),0) AS percentual
 FROM geo
)
SELECT current_timestamp AS coletado_em,ano,regiao,tipo,total,denominador,percentual FROM resultado WHERE regiao='Brasil' ORDER BY tipo