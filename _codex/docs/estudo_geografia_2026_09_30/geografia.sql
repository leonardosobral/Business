-- Geografia revisada: preserva uma participação por resultado; nunca cruza só pelo nome.
-- 2025: rua/BR, status=0 e homologado (universo da query DBA, sem filtro de idade/concluinte).
-- 2026: mesmo recorte de rua, com concluinte; corte até 26/09. Nova coleta independente da prévia.
-- cod_cidade positivo precisa concordar com a cidade/UF. Sem código: chave única validada.
-- Normalização restrita a acentos latinos, caixa e espaços; não inventa aliases de cidades.
WITH eventos AS (
 SELECT id_evento,extract(year FROM data_final)::integer AS ano,cod_cidade,
 upper(btrim(estado)) AS uf,
 translate(upper(regexp_replace(btrim(cidade),'\s+',' ','g')),'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ','AAAAAEEEEIIIIOOOOOUUUUC') AS nome
 FROM public.tb_evento_corridas
 WHERE pais='BR' AND upper(tipo_corrida)='RUA'
 AND data_final>=DATE '2025-01-01' AND data_final<DATE '2026-09-27'
), contagens AS (
 SELECT e.id_evento,count(*) AS n FROM eventos e JOIN public.tb_resultados r USING(id_evento)
 WHERE r.status_final=0 AND r.homologado IS TRUE AND (e.ano=2025 OR r.concluinte IS TRUE)
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
SELECT 'geografia' AS bloco,to_jsonb(r) AS dados FROM resultado r
UNION ALL SELECT 'qualidade',to_jsonb(q) FROM qualidade q
UNION ALL SELECT 'pendencias',jsonb_build_object('ano',ano,'evento',id_evento,'cidade',nome,'uf',uf,'codigo',cod_cidade,'participacoes',n,'motivo',qualidade) FROM base WHERE tipo='Não classificada'
UNION ALL SELECT 'integridade',jsonb_build_object('ano',e.ano,'eventos',count(*),'participacoes',sum(c.n)) FROM contagens c JOIN eventos e USING(id_evento) GROUP BY e.ano
