-- P10: cidade/UF canônicas; agrega por evento antes de validar códigos, evitando multiplicar resultados.
-- 2025: BR anual, status=0 e homologado (mesma população da consulta 201/23, sem concluir/idade).
-- 2026: BR até 26/09, status=0, homologado e concluinte; coleta própria, não muda prévia mensal.
-- Código positivo deve concordar com chave cidade/UF única. Só normaliza acentos, caixa e espaços.
-- Cidades inválidas continuam no denominador nacional; não são apresentadas como cidades válidas.
WITH eventos AS(SELECT id_evento,extract(year FROM data_final)::integer AS ano,cod_cidade,upper(btrim(estado)) AS uf,translate(upper(regexp_replace(btrim(cidade),'\s+',' ','g')),'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ','AAAAAEEEEIIIIOOOOOUUUUC') AS nome FROM public.tb_evento_corridas WHERE pais='BR' AND data_final>=DATE '2025-01-01' AND data_final<DATE '2026-09-27'),
contagens AS(SELECT e.id_evento,count(*) AS n FROM eventos e JOIN public.tb_resultados r USING(id_evento) WHERE r.status_final=0 AND r.homologado IS TRUE AND(e.ano=2025 OR r.concluinte IS TRUE) GROUP BY e.id_evento),
cidades AS(SELECT cod_cidade,min(nome_cidade) AS rotulo,max(upper(btrim(uf))) AS uf,max(translate(upper(regexp_replace(btrim(nome_cidade),'\s+',' ','g')),'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ','AAAAAEEEEIIIIOOOOOUUUUC')) AS nome,count(*) AS linhas FROM public.tb_cidades GROUP BY cod_cidade),
chaves AS(SELECT nome,uf,count(*) AS candidatos,min(cod_cidade) AS codigo FROM cidades GROUP BY nome,uf),
mapa AS(SELECT e.*,r.n,c.rotulo,k.codigo,CASE WHEN coalesce(k.candidatos,0)=0 THEN 'Cidade/UF sem correspondência' WHEN k.candidatos<>1 OR c.linhas<>1 THEN 'Cidade/UF ambígua' WHEN e.cod_cidade>0 AND e.cod_cidade<>k.codigo THEN 'Código diverge da cidade/UF' ELSE 'Cidade/UF validada' END AS qualidade FROM eventos e JOIN contagens r USING(id_evento) LEFT JOIN chaves k ON k.nome=e.nome AND k.uf=e.uf LEFT JOIN cidades c ON k.candidatos=1 AND c.cod_cidade=k.codigo),
bases AS(SELECT ano,sum(n) AS denominador,count(*) AS eventos FROM mapa GROUP BY ano),
agregado AS(SELECT ano,codigo,nome,uf,rotulo,sum(n) AS total,count(*) AS eventos FROM mapa WHERE qualidade='Cidade/UF validada' GROUP BY ano,codigo,nome,uf,rotulo),
ranqueado AS(SELECT a.*,b.denominador,row_number() OVER(PARTITION BY a.ano ORDER BY total DESC,nome,uf) AS ordem FROM agregado a JOIN bases b USING(ano)),
fixas AS(SELECT column1 AS nome,column2 AS uf FROM(VALUES('SAO PAULO','SP'),('RIO DE JANEIRO','RJ'),('BELO HORIZONTE','MG'),('BRASILIA','DF'),('CURITIBA','PR'),('SALVADOR','BA'),('FORTALEZA','CE'),('PORTO ALEGRE','RS'),('BELEM','PA'),('RECIFE','PE'),('FLORIANOPOLIS','SC'),('GOIANIA','GO'),('JOAO PESSOA','PB'),('SANTOS','SP')) t),
qualidade AS(SELECT ano,qualidade,sum(n) AS total,count(*) AS eventos FROM mapa GROUP BY ano,qualidade)
SELECT 'cidades' AS bloco,to_jsonb(r)||jsonb_build_object('percentual',r.total*100.0/nullif(r.denominador,0)) AS dados FROM ranqueado r WHERE ordem<=14 OR(ano=2025 AND EXISTS(SELECT 1 FROM fixas f WHERE f.nome=r.nome AND f.uf=r.uf))
UNION ALL SELECT 'qualidade',to_jsonb(q) FROM qualidade q
UNION ALL SELECT 'integridade',to_jsonb(b)||jsonb_build_object('validas',(SELECT sum(a.total) FROM agregado a WHERE a.ano=b.ano),'cidades_validas',(SELECT count(*) FROM agregado a WHERE a.ano=b.ano),'resultados_antes_do_mapa',(SELECT sum(r.n) FROM contagens r JOIN eventos e USING(id_evento) WHERE e.ano=b.ano)) FROM bases b
