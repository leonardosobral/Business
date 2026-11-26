-- Uma referência por prova: menor preço capturado em opção explicitamente geral/adulta.
-- Classificação conservadora: ausência de restrição NÃO prova categoria geral.
WITH eventos AS MATERIALIZED (
 SELECT id_evento,nome_evento,precos FROM public.tb_evento_corridas
 WHERE ativo IS TRUE AND pais='BR' AND tipo_corrida='rua'
 AND (ranking IS NULL OR ranking<>'false')
 AND data_final>=DATE '2026-01-01' AND data_final<DATE '2027-01-01'
), raw AS (
 SELECT e.id_evento,t.value AS opcao,
 CASE WHEN jsonb_typeof(t.value->'valor')='number' THEN (t.value->>'valor')::numeric END AS preco,
 translate(lower(concat_ws(' ',t.value->>'nome',t.value->>'categoria',t.value->>'grupo',t.value->>'restricao',t.value->>'idade',t.value->>'modalidade',t.value->>'kit',t.value->>'lote',t.value->>'periodo')),'áàâãäéèêëíìîïóòôõöúùûüç','aaaaaeeeeiiiiooooouuuuc') AS texto,
 translate(lower(concat_ws(' ',t.value->>'nome',t.value->>'categoria',t.value->>'grupo',t.value->>'restricao')),'áàâãäéèêëíìîïóòôõöúùûüç','aaaaaeeeeiiiiooooouuuuc') AS publico_texto,
 translate(lower(coalesce(t.value->>'restricao','')),'áàâãäéèêëíìîïóòôõöúùûüç','aaaaaeeeeiiiiooooouuuuc') AS restricao,
 translate(lower(concat_ws(' ',t.value->>'kit',t.value->>'grupo',t.value->>'nome')),'áàâãäéèêëíìîïóòôõöúùûüç','aaaaaeeeeiiiiooooouuuuc') AS kit_texto,
 btrim(regexp_replace(lower(coalesce(t.value->>'lote','')),'[ºª°]','','g')) AS lote_texto,
 lower(concat_ws(' ',t.value->>'nome',t.value->>'grupo',t.value->>'categoria',t.value->>'periodo',t.value->>'lote')) AS lote_contexto
 FROM eventos e CROSS JOIN LATERAL jsonb_array_elements(CASE WHEN jsonb_typeof(e.precos)='array' THEN e.precos ELSE '[]'::jsonb END)t
), marcas_lote AS (
 SELECT *,regexp_replace(texto,'(^|[^0-9])([0-9]{1,3})\s*(/|–|-|a(os|te)?)\s*([0-9]{1,3})(\s*anos)?',' ','g') AS texto_sem_faixas,
 (lote_texto ~ '^(1|1\s*lote|lote\s*1|primeiro lote)$' OR lote_contexto ~ '(^|[^0-9])(1[ºª°o]?\s*lote|lote\s*1([^0-9]|$)|primeiro lote)') AS lote1,
 (lote_texto ~ '^(2|2\s*lote|lote\s*2|segundo lote)$' OR lote_contexto ~ '(^|[^0-9])(2[ºª°o]?\s*lote|lote\s*2([^0-9]|$)|segundo lote)') AS lote2,
 (lote_texto ~ '^(3|3\s*lote|lote\s*3|terceiro lote)$' OR lote_contexto ~ '(^|[^0-9])(3[ºª°o]?\s*lote|lote\s*3([^0-9]|$)|terceiro lote)') AS lote3
 FROM raw
), classificadas AS (
 SELECT *,CASE
 WHEN preco IS NULL OR preco<=0.01 THEN 'Preço ausente, inválido ou até R$ 0,01'
 WHEN upper(coalesce(opcao->>'moeda','BRL')) NOT IN ('BRL','R$') THEN 'Outra moeda'
 WHEN lower(coalesce(opcao->>'disponivel','')) IN ('false','0','não','nao') OR texto ~ '(esgotad|encerrad|indisponivel)' THEN 'Indisponibilidade explícita'
 WHEN texto_sem_faixas ~ '(^|[^0-9])(6[0-9]|[7-9][0-9])\s*(\+|anos|e acima)' OR texto ~ '(^|[^0-9])(6[0-9]|[7-9][0-9])\s*a(os|te)?\s*([6-9][0-9]|1[01][0-9])([^0-9]|$)' THEN 'Desconto ou público restrito'
 WHEN texto ~ '(^|[^0-9])(6[0-9]|[7-9][0-9])\s*[/–-]\s*([6-9][0-9]|1[01][0-9])([^0-9]|$)' THEN 'Desconto ou público restrito'
 WHEN texto ~ '(pcd|pne|deficien|idos|senior|sênior|terceira idade|meia|descont|cupom|convenio|sindicat|associad|morador|colaborador|servidor|militar|estudant|universitari|aluno|professor|funcionari|residente|convidad|beneficiari|aposentad|filiad|federa|50\s*%|gratuit|isento|acima de 60)' THEN 'Desconto ou público restrito'
 WHEN texto ~ '(^|[^0-9])(0?[0-9]|1[0-7])\s*(/|–|-|a(os|te)?)\s*(0?[0-9]|1[0-7])([^0-9]|$)' THEN 'Kids ou menores explícitos'
 WHEN texto ~ '(kids|infantil|mirim|juvenil|crianca|menor de|ate 17|até 17)' THEN 'Kids ou menores explícitos'
 WHEN texto ~ '(alimento|litro de leite|cesta basica|doacao obrigatoria)' THEN 'Contrapartida não monetária'
 WHEN texto ~ '(caminhada|trail|ciclismo|bike)' THEN 'Modalidade mista ou fora de corrida de rua'
 WHEN btrim(restricao)<>'' AND btrim(restricao) !~ '^(sem restric(ao|oes)|nenhuma|publico geral|geral|adulto[s]?)$' THEN 'Restrição não interpretada'
 WHEN replace(publico_texto,'kit geral','') !~ '(^|[^a-z])(geral|adulto|adultos)([^a-z]|$)' THEN 'Categoria geral não identificada'
 ELSE 'Geral explícita analisável' END AS classe,
 CASE
 WHEN kit_texto ~ '(basico|simples|economico)' AND kit_texto ~ '(completo|premium|vip)' THEN 'Composição ambígua'
 WHEN kit_texto ~ 'sem camis(a|eta)' AND kit_texto ~ 'com camis(a|eta)' THEN 'Composição ambígua'
 WHEN kit_texto ~ 'sem camis(a|eta)' THEN 'Sem camiseta explícita'
 WHEN kit_texto ~ 'com camis(a|eta)' THEN 'Com camiseta explícita'
 WHEN kit_texto ~ '(so chip|só chip|somente chip|apenas chip)' THEN 'Só chip explícito'
 WHEN kit_texto ~ '(completo|premium|vip)' THEN 'Completo / premium (rótulo)'
 WHEN kit_texto ~ '(basico|simples|economico|participacao)' THEN 'Básico / simples (rótulo)'
 WHEN btrim(coalesce(opcao->>'kit',''))<>'' THEN 'Outro kit identificado'
 ELSE 'Kit não identificado' END AS kit,
 CASE
 WHEN (lote1::integer+lote2::integer+lote3::integer)>1 THEN 'Lote ambíguo'
 WHEN lote1 THEN '1º lote'
 WHEN lote2 THEN '2º lote'
 WHEN lote3 THEN '3º lote'
 WHEN lote_contexto ~ '(lote (único|unico)|(único|unico) lote)' THEN 'Lote único'
 WHEN lote_contexto ~ '(lote promocional|promocional lote)' THEN 'Lote promocional'
 WHEN lote_texto='' AND lote_contexto !~ 'lote' THEN 'Lote não informado' ELSE 'Outro lote identificado' END AS lote
 FROM marcas_lote
), gerais AS MATERIALIZED (SELECT * FROM classificadas WHERE classe='Geral explícita analisável'),
por_prova AS (SELECT id_evento,min(preco) AS preco FROM gerais GROUP BY id_evento),
ordenadas AS (SELECT *,row_number() OVER(ORDER BY preco,id_evento) AS posicao,count(*) OVER() AS n FROM por_prova),
resumo AS (
 SELECT (SELECT count(*) FROM eventos) AS calendario,count(*) AS analisadas,
 (SELECT count(DISTINCT id_evento) FROM raw) AS com_opcoes,
 (SELECT count(*) FROM eventos e WHERE NOT EXISTS(SELECT 1 FROM raw r WHERE r.id_evento=e.id_evento)) AS sem_opcoes,
 (SELECT count(DISTINCT id_evento) FROM raw WHERE id_evento NOT IN(SELECT id_evento FROM por_prova)) AS sem_geral_identificado,
 avg(preco)::text AS media,(SELECT avg(preco)::text FROM ordenadas WHERE posicao IN ((n+1)/2,(n+2)/2)) AS mediana,
 (count(*)*100.0/nullif((SELECT count(*) FROM eventos),0))::text AS cobertura
 FROM por_prova
), cortes AS (
 SELECT 'kits' AS eixo,kit AS rotulo,id_evento,min(preco) AS preco FROM gerais GROUP BY kit,id_evento
 UNION ALL SELECT 'lotes',lote,id_evento,min(preco) FROM gerais GROUP BY lote,id_evento
), ord_cortes AS (
 SELECT *,row_number() OVER(PARTITION BY eixo,rotulo ORDER BY preco,id_evento) AS posicao,count(*) OVER(PARTITION BY eixo,rotulo) AS n FROM cortes
), resumo_cortes AS (
 SELECT eixo,rotulo,count(*) AS contagem,avg(preco)::text AS media,
 avg(preco) FILTER(WHERE posicao IN ((n+1)/2,(n+2)/2))::text AS mediana FROM ord_cortes GROUP BY eixo,rotulo
), cobertura AS (
 SELECT 'Categoria geral identificada' AS rotulo,analisadas AS contagem,cobertura AS percentual FROM resumo
 UNION ALL SELECT 'Com opções, sem geral analisável',sem_geral_identificado,(sem_geral_identificado*100.0/nullif(calendario,0))::text FROM resumo
 UNION ALL SELECT 'Sem opções capturadas',sem_opcoes,(sem_opcoes*100.0/nullif(calendario,0))::text FROM resumo
), limites AS (SELECT column1 AS ordem,column2 AS rotulo,column3 AS inferior,column4 AS superior FROM (VALUES
 (1,'Até R$ 50',0.01::numeric,50::numeric),(2,'Acima de R$ 50 até R$ 100',50,100),(3,'Acima de R$ 100 até R$ 150',100,150),(4,'Acima de R$ 150 até R$ 200',150,200),(5,'Acima de R$ 200',200,NULL))t),
faixas AS (
 SELECT ordem,rotulo,count(id_evento) AS contagem,(count(id_evento)*100.0/nullif((SELECT analisadas FROM resumo),0))::text AS percentual
 FROM limites LEFT JOIN por_prova ON preco>inferior AND (superior IS NULL OR preco<=superior) GROUP BY ordem,rotulo
)
SELECT jsonb_build_object('ano',2026,'inicio','2026-01-01','fim','2026-12-31','coletado_em',current_timestamp,
 'regra','Menor preço acima de R$ 0,01 por id_evento em opção com rótulo geral/adulto explícito. Descontos, PCD, idosos (inclusive faixas 60+), kids, públicos restritos, contrapartidas não monetárias explícitas, modalidades mistas, restrições desconhecidas e indisponibilidade explícita excluídos; moeda BRL/R$, ausente assumida BRL. Identificação textual conservadora, sujeita a revisão; ausência de palavra de desconto não prova generalidade. Ofertas capturadas, sem confirmar disponibilidade atual. Média/mediana não ponderadas por vendas. Taxas não somadas. Distâncias, kits e lotes ainda variam na referência geral. Cortes de kit e lote calculam menor preço por prova dentro de cada rótulo, podem se sobrepor e não garantem composição equivalente. Ausência de kit/lote não é imputada. Não estima ticket de vendas nem mercado nacional.',
 'resumo',(SELECT to_jsonb(resumo) FROM resumo),'cobertura',(SELECT jsonb_agg(to_jsonb(cobertura) ORDER BY rotulo) FROM cobertura),
 'faixas',(SELECT jsonb_agg(to_jsonb(faixas) ORDER BY ordem) FROM faixas),
 'kits',(SELECT coalesce(jsonb_agg(to_jsonb(resumo_cortes)-'eixo' ORDER BY rotulo),'[]'::jsonb) FROM resumo_cortes WHERE eixo='kits'),
 'lotes',(SELECT coalesce(jsonb_agg(to_jsonb(resumo_cortes)-'eixo' ORDER BY rotulo),'[]'::jsonb) FROM resumo_cortes WHERE eixo='lotes'),
 'opcoes',(SELECT coalesce(jsonb_agg(jsonb_build_object('rotulo',classe,'contagem',n) ORDER BY classe),'[]'::jsonb) FROM (SELECT classe,count(*) AS n FROM classificadas GROUP BY classe)t),
 'provas',(SELECT coalesce(jsonb_agg(jsonb_build_object('id_evento',id_evento,'preco',preco::text) ORDER BY id_evento),'[]'::jsonb) FROM por_prova),
 'opcoes_gerais',(SELECT coalesce(jsonb_agg(jsonb_build_object('id_evento',id_evento,'valor',preco::text,'kit',kit,'lote',lote,'rotulos',opcao-'taxas') ORDER BY id_evento,preco),'[]'::jsonb) FROM gerais),
 'pendentes_amostra_limitada_100',(SELECT coalesce(jsonb_agg(to_jsonb(t)),'[]'::jsonb) FROM (SELECT id_evento,classe,opcao FROM classificadas WHERE classe<>'Geral explícita analisável' ORDER BY id_evento,preco LIMIT 100)t)) AS payload;
