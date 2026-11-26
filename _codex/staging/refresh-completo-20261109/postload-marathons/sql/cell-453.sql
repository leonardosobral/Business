-- Renovação candidata09/11; curadoria/capturas externas preservadas; entradas=[{"cell": 425, "revision": 1, "run": 292, "started_at": "2026-11-09 15:52:45.816865-03"}, {"cell": 426, "revision": 1, "run": 303, "started_at": "2026-11-09 18:19:51.924112-03"}, {"cell": 427, "revision": 3, "run": 339, "started_at": "2026-11-09 18:31:12.809605-03"}, {"cell": 428, "revision": 2, "run": 324, "started_at": "2026-11-09 18:24:38.447301-03"}, {"cell": 429, "revision": 3, "run": 340, "started_at": "2026-11-09 18:31:14.538989-03"}, {"cell": 436, "revision": 1, "run": 294, "started_at": "2026-11-09 15:52:52.633375-03"}, {"cell": 437, "revision": 1, "run": 305, "started_at": "2026-11-09 18:19:56.237708-03"}, {"cell": 452, "revision": 2, "run": 308, "started_at": "2026-11-09 18:20:00.171625-03"}, {"cell": 251, "revision": 42, "run": 351, "started_at": "2026-11-09 18:38:30.179861-03"}]
-- Encarte Brasil Gigante: derivação dos congelamentos existentes, sem recontar o estudo principal.
-- Seção nova; referências2025 precedem o anúncio do circuito em07/04/2026.
-- João Pessoa é agregador14/evento32450:335 no inventário243, versus332 no balanço oficial.
-- Paraná estreia em2026; Aracaju fora do corte. Comparação descritiva, sem atribuição causal.
WITH fonte AS MATERIALIZED (
 SELECT id,cell_id,cell_version,sql_sha256,frozen_at,result,
 CASE WHEN jsonb_typeof(result->'rows'->0->'payload')='string' THEN (result->'rows'->0->>'payload')::jsonb ELSE result->'rows'->0->'payload' END AS payload
 FROM estudo.notebook_runs WHERE id IN(210,292,303,339,324,340,294,305,308,351)
 AND status='ok' AND frozen AND NOT truncated
), seed AS (SELECT ordinality AS ord,value AS j FROM jsonb_array_elements('[{"id": "sao-paulo", "label": "São Paulo", "aggregator": 17, "event2025": 22582, "event2026": 29291, "official_date_2026": "2026-04-12", "registered_date_2026": "2026-04-12", "comparable": true, "pending": false, "new": false, "quality_notes": []}, {"id": "parana", "label": "Paraná", "aggregator": 1000, "event2025": null, "event2026": 37310, "official_date_2026": "2026-05-03", "registered_date_2026": "2026-04-28", "comparable": false, "pending": false, "new": true, "quality_notes": ["Estreia em 2026: não existe base de 2025 para calcular variação.", "Data oficial dos 42 km: 03/05; cadastro/fonte congelada registra 28/04. Ambos pertencem ao segundo trimestre."]}, {"id": "porto-alegre", "label": "Porto Alegre", "aggregator": 26, "event2025": 24998, "event2026": 34236, "official_date_2026": "2026-05-31", "registered_date_2026": "2026-05-31", "comparable": true, "pending": false, "new": false, "quality_notes": []}, {"id": "campo-grande", "label": "Campo Grande", "aggregator": 9, "event2025": 27747, "event2026": 39393, "official_date_2026": "2026-07-05", "registered_date_2026": "2026-07-05", "comparable": true, "pending": false, "new": false, "quality_notes": []}, {"id": "joao-pessoa", "label": "João Pessoa Internacional", "aggregator": 14, "event2025": 27532, "event2026": 32450, "official_date_2026": "2026-08-02", "registered_date_2026": "2026-08-02", "comparable": true, "pending": false, "new": false, "quality_notes": ["Agregador 14: Internacional de agosto; não confundir com o agregador 12, realizado em abril.", "Inventário congelado 243 contém 335 concluintes; balanço oficial informa 332. Divergência de três a conciliar.", "Não consta da seleção geral 245; entra somente neste encarte, pelos mesmos filtros convencionais do inventário."]}, {"id": "floripa", "label": "Floripa", "aggregator": 28, "event2025": 22792, "event2026": 34529, "official_date_2026": "2026-08-30", "registered_date_2026": "2026-08-30", "comparable": true, "pending": false, "new": false, "quality_notes": ["2025: 5.137 concluintes convencionais no congelamento 294; 5.152 incluindo modalidades excluídas no inventário 292.", "2026 substitui integralmente o BI (3.609) pelos 3.592 classificados Geral/Elite da captura oficial 210.", "A variação de volume é descritiva; não comprova efeito do circuito nem captura completa equivalente entre anos."]}, {"id": "salvador", "label": "Salvador", "aggregator": 15, "event2025": 24016, "event2026": 36245, "official_date_2026": "2026-09-27", "registered_date_2026": "2026-09-27", "comparable": true, "pending": false, "new": false, "quality_notes": []}, {"id": "aracaju", "label": "Aracaju", "aggregator": 77, "event2025": 25481, "event2026": 39399, "official_date_2026": "2026-11-01", "registered_date_2026": "2026-11-01", "comparable": false, "pending": true, "new": false, "quality_notes": ["Etapas de 2025 e 2026 no quarto trimestre: fora dos consolidados janeiro–setembro.", "Cadastro 2026 identificado pelo agregador 77; não realizado até o corte."]}]'::jsonb) WITH ORDINALITY),
raw_details AS (
 SELECT f.id AS source_run,f.cell_id AS source_cell,v.value AS j
 FROM fonte f CROSS JOIN LATERAL jsonb_array_elements(f.payload->'provas') v WHERE f.id IN(294,305)
), metrics AS (
 SELECT (j->>'id_evento')::int AS event_id,
 jsonb_build_object('total',(j->>'total')::int,'female',(j->>'feminino')::int,'male',(j->>'masculino')::int,
 'sub3',(j->>'sub3')::int,'sub4',(j->>'sub4')::int,'median_seconds',(j->>'mediana')::numeric,
 'source_run',source_run,'source_cell',source_cell,'date_registered',j->>'data') AS m
 FROM raw_details WHERE (j->>'id_evento')::int<>34529
 UNION ALL
 SELECT 34529,jsonb_build_object('total',(j->>'concluintes')::int,'female',(j->>'feminino')::int,
 'male',(j->>'masculino')::int,'sub3',(j->>'sub3')::int,'sub4',(j->>'sub4')::int,
 'median_seconds',(j->>'mediano_segundos')::numeric,'source_run',210,'source_cell',402,'date_registered','2026-08-30')
 FROM (SELECT payload->'classificados_geral_elite' AS j FROM fonte WHERE id=210) f
 UNION ALL
 SELECT 32450,jsonb_build_object('total',(j->>'participacoes')::int,'female',(j->>'feminino')::int,
 'male',(j->>'masculino')::int,'sub3',(j->>'sub3')::int,'sub4',(j->>'sub4')::int,
 'median_seconds',(j->>'mediana_segundos')::numeric,'source_run',303,'source_cell',426,'date_registered',j->>'data_final')
 FROM (SELECT v.value AS j FROM fonte f CROSS JOIN LATERAL jsonb_array_elements(f.result->'rows') v
 WHERE f.id=303 AND (v.value->>'id_evento')::int=32450) f
), stages AS (
 SELECT s.ord,s.j||jsonb_build_object('metrics2025',a.m,'metrics2026',b.m,
 'delta',CASE WHEN (s.j->>'comparable')::boolean THEN jsonb_build_object(
 'absolute',(b.m->>'total')::int-(a.m->>'total')::int,
 'percent',100*((b.m->>'total')::numeric/(a.m->>'total')::numeric-1)) ELSE NULL END) AS j
 FROM seed s LEFT JOIN metrics a ON a.event_id=(s.j->>'event2025')::int
 LEFT JOIN metrics b ON b.event_id=(s.j->>'event2026')::int
), paired AS (
 SELECT j->>'id' AS id,(j->'metrics2025'->>'total')::int AS n2025,(j->'metrics2026'->>'total')::int AS n2026
 FROM stages WHERE (j->>'comparable')::boolean
), summary_groups AS (
 SELECT 'cohort' AS kind,p.* FROM paired p
 UNION ALL SELECT 'without_floripa',p.* FROM paired p WHERE id<>'floripa'
 UNION ALL SELECT 'without_joao_pessoa',p.* FROM paired p WHERE id<>'joao-pessoa'
), summaries AS (
 SELECT kind,jsonb_build_object('pairs',count(*),'base_total',sum(n2025),'total',sum(n2026),'absolute',sum(n2026)-sum(n2025),
 'percent',100*(sum(n2026)::numeric/sum(n2025)-1),'growing',count(*) FILTER(WHERE n2026>n2025),
 'declining',count(*) FILTER(WHERE n2026<n2025)) AS j FROM summary_groups GROUP BY kind
), other_pairs AS (
 SELECT v.value AS j FROM fonte f CROSS JOIN LATERAL jsonb_array_elements(f.payload->'pares') v
 WHERE f.id=340 AND (v.value->>'agregador')::int NOT IN(17,1000,26,9,14,28,15,77)
), other_groups AS (
 SELECT 'all' AS kind,j FROM other_pairs UNION ALL SELECT 'without_nb',j FROM other_pairs WHERE (j->>'agregador')::int<>39
), benchmarks AS (
 SELECT kind,jsonb_build_object('pairs',count(*),'base_total',sum((j->>'n2025')::int),'total',sum((j->>'n2026')::int),
 'absolute',sum((j->>'n2026')::int)-sum((j->>'n2025')::int),
 'percent',100*(sum((j->>'n2026')::numeric)/sum((j->>'n2025')::numeric)-1),'source_run',340,
 'events',jsonb_agg(jsonb_build_object('aggregator',(j->>'agregador')::int,'event2025',(j->>'id2025')::int,
 'event2026',(j->>'id2026')::int,'label',j->>'nome_evento','base_total',(j->>'n2025')::int,'total',(j->>'n2026')::int)
 ORDER BY CAST(j->>'n2026' AS int) DESC)) AS j FROM other_groups GROUP BY kind
), adoption AS (SELECT payload AS j FROM fonte WHERE id=308)
SELECT jsonb_build_object(
 'meta','{"title": "Encarte · Circuito Brasil Gigante", "year": 2026, "cutoff": "2026-09-30", "baseline_year": 2025, "announcement_date": "2026-04-07", "ceremony_date": "2026-04-11", "source_runs": [210, 292, 303, 339, 324, 340, 294, 305, 308, 351], "source_cells": [402, 425, 426, 427, 428, 429, 436, 437, 452, 251], "source_section": 66, "book": 6, "unit": "conclusões de maratona, não pessoas únicas", "status": "reviewed", "notes": ["2025 é a referência anterior ao lançamento do circuito, não uma edição do Brasil Gigante.", "Comparações somam conclusões nos pares antes de calcular a variação, não média dos percentuais.", "Benchmark é descritivo; não é grupo de controle causal.", "Os seis pares dependem de cobertura equivalente; a diferença oficial de João Pessoa permanece aberta."], "notebook_section": 67, "methodology_cell": 451, "adoption_run": 308, "adoption_cell": 452, "external_sources": [{"title": "Lançamento e calendário", "url": "https://circuitobrasilgigante.com.br/noticias/circuito-de-oito-maratonas-brasil-gigante-e-lancado-para-democratizar-as-provas-de-42-km-no-pais-2/?lang=pt-br"}, {"title": "Balanço João Pessoa", "url": "https://circuitobrasilgigante.com.br/noticias/joao-pessoa-marca-a-quinta-etapa-do-brasil-gigante-que-reune-corredores-em-jornada-pelas-oito-maratonas/"}, {"title": "Regulamento Paraná", "url": "https://www.maratonainternacionalpr.com.br/_files/ugd/4113c7_bb907a07911d44439d2933c673860efe.pdf"}, {"title": "Regras e retroatividade", "url": "https://circuitobrasilgigante.com.br/sobre/"}], "principal_context_run": 351, "principal_context_publication": 42}'::jsonb||jsonb_build_object('source_versions',(SELECT jsonb_agg(jsonb_build_object('run',id,'cell',cell_id,'version',cell_version,'sql_sha256',sql_sha256,'frozen_at',frozen_at) ORDER BY id) FROM fonte)),
 'stages',(SELECT jsonb_agg(j ORDER BY ord) FROM stages),
 'cohort',(SELECT j FROM summaries WHERE kind='cohort'),
 'subtotal',(SELECT jsonb_build_object('stages2026',count(*) FILTER(WHERE j->'metrics2026'<>'null'::jsonb AND NOT (j->>'pending')::boolean),
 'total2026',sum((j->'metrics2026'->>'total')::int) FILTER(WHERE NOT (j->>'pending')::boolean),
 'female2026',sum((j->'metrics2026'->>'female')::int) FILTER(WHERE NOT (j->>'pending')::boolean),
 'sub4_2026',sum((j->'metrics2026'->>'sub4')::int) FILTER(WHERE NOT (j->>'pending')::boolean),
 'total2025_comparable',sum((j->'metrics2025'->>'total')::int) FILTER(WHERE (j->>'comparable')::boolean),
 'new2026',sum((j->'metrics2026'->>'total')::int) FILTER(WHERE (j->>'new')::boolean),
 'pending',count(*) FILTER(WHERE (j->>'pending')::boolean)) FROM stages),
 'benchmark',(SELECT jsonb_object_agg(kind,j) FROM benchmarks),
 'sensitivity',(SELECT jsonb_object_agg(kind,j) FROM summaries WHERE kind<>'cohort'),
 'adoption',(SELECT jsonb_build_object('registered',(j->>'inscritos')::int,'with_result',(j->>'com_resultado')::int,
 'two_or_more',(j->>'com_duas_ou_mais')::int,'registered_before_or_same_day_one',(j->>'inscritos_antes_ou_dia_de_uma_etapa')::int,
 'registered_before_or_same_day_two',(j->>'inscritos_antes_ou_dia_de_duas_etapas')::int,'queried_at',j->>'consultado_em',
 'registration_cutoff','2026-09-30','result_cutoff','2026-09-30','status','I','source_run',308,'source_cell',452,
 'distribution',(SELECT jsonb_agg(jsonb_build_object('stages',(v.value->>'etapas')::int,'accounts',(v.value->>'contas')::int)
 ORDER BY CAST(v.value->>'etapas' AS int)) FROM jsonb_array_elements(j->'distribuicao') v),
 'notes','["Contas cadastradas no circuito até 30/09; resultados de provas até 30/09 associados na consulta atual.", "Status I é o cadastro existente; não significa conclusão de etapa.", "Associações podem ser retroativas; zero resultados associados não significa que a pessoa não correu.", "Recorrência deduplica conta e evento. Indicador operacional não comprova conversão causada pelo circuito.", "Floripa operacional usa o BI com 3.609; volume editorial usa a captura oficial com 3.592. Não combinar os dois denominadores."]'::jsonb) FROM adoption)
) AS payload

