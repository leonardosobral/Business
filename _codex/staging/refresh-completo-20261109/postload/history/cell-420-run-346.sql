-- Candidato de narrativa Jan–Set; congelar não altera a view nem a publicação liberada.
-- Mosaico comparativo público,13/10/2026. CorteJan–Set nos dois anos.
-- Preserva todos os valores2026 do congelamento233/publicação41.
-- Referências2025: sexo/distâncias/calendário228;gerações164(v2);interior237(fonte nova421).
-- Porte: contagens anuais222 filtradas pelo calendário congelado229 até30/09;
-- recalcula ranking/ceil(10%*n) antes de calcular concentração. Nenhum valor anual comparado aQ3.
-- Coorte231:608pares, variação de soma de concluintes, não média por prova. Captura pode variar.
-- Coletas distintas por tema; não transforma mudanças de cobertura em crescimento real do mercado.
-- JSON público só percentuais arredondados e notas; sem volumes/IDs privados.
-- Revisão editorial: destaque para provas cadastradas, no lugar de fevereiro.
-- Provas BR pela data final Jan-Set; inclui cadastros inativos/cancelados.
-- Mede o calendário conhecido, não certifica realização nem crescimento de mercado.
-- Mulheres: exibir percentuais de cada ano; não converter diferença absoluta em %.
-- Publicação profissional 41, congelamento 233, comparações Jan–Set.
-- Releia a fonte vigente antes de editar. Novo congelamento não muda a liberação pública automaticamente.
-- Projeção pública: somente seis percentuais e três comparações arredondadas.
-- Fonte: publicação Q3 fixada no produto, derivada das queries do notebook.
-- Crescimento de resultados registrados não estima crescimento do mercado.
WITH indicadores(ord,serie,categoria,textos) AS (VALUES
(1,'sexo_2026','F','{"id": "femininas", "label": "Elas seguem maioria.", "descricao": "As mulheres representam a maior parte das participações registradas no período.", "universo": "Base: todas as participações elegíveis. Uma pessoa pode concluir mais de uma prova."}'::jsonb),
(2,'geracoes_2026_geral','Millennials','{"id": "millennials", "label": "Uma geração em destaque.", "descricao": "Os Millennials concentram quase metade das participações observadas.", "universo": "Nascimento entre 1981 e 1996 ou aproximação pela faixa etária. Desconhecidos permanecem no denominador."}'::jsonb),
(3,'distancias_faixas','Até 5 km','{"id": "distancias_curtas", "label": "As curtas têm mais presença.", "descricao": "Participações em percursos cadastrados inferiores a 6 km.", "universo": "Base: corridas de rua com distância positiva informada; percentual de participações, não de provas."}'::jsonb),
(4,'capital_interior_Brasil','Interior','{"id": "interior", "label": "O interior também é protagonista.", "descricao": "Quase metade das participações de rua está em provas fora das capitais.", "universo": "Localização da prova, não residência do atleta. Localidades não classificadas permanecem no denominador."}'::jsonb),
(5,'trimestres','3','{"id": "terceiro_trimestre", "label": "Julho a setembro puxam o recorte.", "descricao": "O terceiro trimestre concentra a maior parcela das participações dos nove meses.", "universo": "Base: todas as participações elegíveis de janeiro a setembro de 2026. Não representa o ano completo."}'::jsonb),
(6,'porte_concentracao','10% maiores provas','{"id": "concentracao_porte", "label": "As maiores concentram o volume.", "descricao": "Quase metade das participações observadas está nas 10% maiores provas da base de porte.", "universo": "Provas de rua elegíveis ao ranking, com alguma conclusão. O porte observado depende da completude da captura."}'::jsonb)
), fonte AS (
 SELECT result->'rows'->0->'payload' AS payload FROM estudo.notebook_runs
 WHERE id=345 AND cell_id=251 AND cell_version=41 AND frozen AND status='ok' AND NOT truncated
), geral25 AS (
 SELECT result->'rows'->0->'payload' AS p FROM estudo.notebook_runs WHERE id=317 AND cell_id=347 AND cell_version=1 AND frozen AND status='ok' AND NOT truncated
), geracao25 AS (
 SELECT v FROM estudo.notebook_runs,jsonb_array_elements(result->'rows')v WHERE id=318 AND cell_id=354 AND cell_version=1 AND frozen AND status='ok' AND NOT truncated
 AND v->>'bloco'='geracao' AND v->>'sexo'='geral' AND v->>'categoria'='Millennials'
), geo25 AS (
 SELECT v FROM estudo.notebook_runs,jsonb_array_elements(result->'rows')v WHERE id=320 AND cell_id=421 AND cell_version=1 AND frozen AND status='ok' AND NOT truncated
 AND v->>'regiao'='Brasil' AND v->>'tipo'='Interior'
), calendario25 AS (
 SELECT v FROM estudo.notebook_runs,jsonb_array_elements(result->'rows'->0->'payload'->'eventos')v
 WHERE id=321 AND cell_id=383 AND cell_version=1 AND frozen AND status='ok' AND NOT truncated AND (v->>'na_janela')::boolean
), porte25 AS (
 SELECT (prova.value->>'id_evento')::bigint AS id_evento,(prova.value->>'participacoes')::bigint AS participacoes
 FROM estudo.notebook_runs,jsonb_array_elements(result->'rows'->0->'payload'->'edicoes'->'2025'->'provas') AS prova
 WHERE id=313 AND cell_id=368 AND cell_version=2 AND frozen AND status='ok' AND NOT truncated
 AND EXISTS(SELECT 1 FROM calendario25 c WHERE c.v->>'id_evento'=prova.value->>'id_evento')
), ranking25 AS (
 SELECT *,row_number() OVER(ORDER BY participacoes DESC,id_evento) AS posicao,count(*) OVER() AS n FROM porte25
), anteriores AS (
 SELECT 'femininas' AS id,((SELECT payload FROM fonte)#>>'{comparativo,mulheres,percentual_2025}')::numeric AS valor,'Mesmos nove meses; participações, não pessoas únicas.'::text AS nota
 UNION ALL SELECT 'millennials',(v->>'percentual')::numeric,'Mesma regra de geração; a cobertura das idades também muda entre anos.' FROM geracao25
 UNION ALL SELECT 'distancias_curtas',(v->>'percentual')::numeric,'Rua com distância positiva; percursos inferiores a 6 km.' FROM geral25,jsonb_array_elements(p->'recortes')v WHERE v->>'indicador'='distancia_faixas' AND v->>'categoria'='Até 5 km'
 UNION ALL SELECT 'interior',(v->>'percentual')::numeric,'Mesma regra de localização; não classificados continuam no denominador. Coletas próprias por tema; referência2025 2026-11-09; referência2026 2026-11-09.' FROM geo25
 UNION ALL SELECT 'terceiro_trimestre',(v->>'percentual')::numeric,'Peso de julho–setembro no total de janeiro–setembro de cada ano.' FROM geral25,jsonb_array_elements(p->'recortes')v WHERE v->>'indicador'='trimestre' AND v->>'categoria'='3'
 UNION ALL SELECT 'concentracao_porte',sum(participacoes) FILTER(WHERE posicao<=ceil(n*0.1))*100.0/nullif(sum(participacoes),0),'Top 10% recalculado em Jan–Set de cada ano; não são necessariamente as mesmas provas.' FROM ranking25
), pareadas AS (
 SELECT result->'rows'->0->'payload'->'coorte_pareada' AS p FROM estudo.notebook_runs WHERE id=329 AND cell_id=387 AND cell_version=3 AND frozen AND status='ok' AND NOT truncated
), itens AS (
 SELECT i.ord, i.textos || jsonb_build_object('valor',round((c->'atual'->>'valor')::numeric,1),'comparativo',jsonb_build_object('anterior',round(a.valor,1),'nota',a.nota)) AS item
 FROM fonte, indicadores i JOIN anteriores a ON a.id=i.textos->>'id', jsonb_array_elements(fonte.payload->'comparacoes') c
 WHERE c->>'serie'=i.serie AND c->>'categoria'=i.categoria
)
SELECT jsonb_build_object('ok',true,'release',jsonb_build_object(
 'title','O Brasil que Corre Provas 2026 · Janeiro a setembro',
 'periodo_inicio','2026-01-01','periodo_fim','2026-09-30',
 'coleta',left((SELECT payload->'meta'->>'coletado_em' FROM fonte),10),
 'indicadores',jsonb_agg(item ORDER BY ord),
 'historias',jsonb_build_object(
  'pareadas',jsonb_build_object('variacao_percentual',(SELECT round((p->>'variacao_pct')::numeric,1) FROM pareadas)),
  'mulheres',jsonb_build_object('anterior',round(((SELECT payload FROM fonte)#>>'{comparativo,mulheres,percentual_2025}')::numeric,1),'atual',round(((SELECT payload FROM fonte)#>>'{comparativo,mulheres,percentual_2026}')::numeric,1),'diferenca_pp',round(((SELECT payload FROM fonte)#>>'{comparativo,mulheres,diferenca_pp}')::numeric,1)),
  'resultados',jsonb_build_object('variacao_percentual',round(((SELECT payload FROM fonte)#>>'{comparativo,meses_completos,variacao_percentual}')::numeric,1)),
  'provas',jsonb_build_object('variacao_percentual',round(((SELECT payload FROM fonte)#>>'{comparativo,provas,meses_completos,variacao_cadastradas}')::numeric,1))
 ))) AS payload
FROM itens HAVING count(*)=6;
