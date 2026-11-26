-- Contexto do vertical de maratonas: reutiliza congelamentos existentes, sem substituir consultas.
-- Participações, nunca pessoas únicas. 2025 anual; 2026 janeiro-setembro.
-- Runs 240/241: BR, rua, data_final, status_final=0, homologado=true, concluinte=true.
-- 5/10 km exatos; 21–21,2 e 42–42,2; demais distâncias válidas em Outras.
-- Esta base ampla NÃO aplica os filtros convencionais de modalidade/ranking/tempo da seleção41/39.
-- Registro de Nova York: resultados oficiais consultados em 19/10/2026, 59.219;
-- a divulgação anterior preservada no run138 registrava59.226. Causa da diferença não apurada.
WITH raw AS (
 SELECT CASE WHEN r.id=240 THEN 2025 ELSE 2026 END AS ano,j.value AS row
 FROM estudo.notebook_runs r CROSS JOIN LATERAL jsonb_array_elements(r.result->'rows') j
 WHERE r.id IN(240,241) AND r.frozen IS TRUE AND r.status='ok'
), grouped AS (
 SELECT ano,row->>'faixa' AS label,sum((row->>'participacoes')::bigint) AS total,
 sum((row->>'feminino')::bigint) AS female
 FROM raw WHERE row->>'tipo_corrida'='rua' AND row->>'faixa'<>'Sem distância válida'
 GROUP BY ano,row->>'faixa'
), totals AS (
 SELECT ano,sum(total) AS total,sum(total) FILTER(WHERE label='42–42,2 km') AS marathon FROM grouped GROUP BY ano
), pub AS (
 SELECT r.id,(r.result->'rows'->0->>'payload')::jsonb AS payload,CASE WHEN r.id=205 THEN 2025 ELSE 2026 END AS ano
 FROM estudo.notebook_runs r WHERE r.id IN(205,233) AND r.frozen IS TRUE AND r.status='ok'
), principal AS (
 SELECT p.ano,s.value->>'id' AS id,jsonb_build_object('id',s.value->>'id','unit',s.value->>'unidade','note',s.value->>'ressalva',
 'values',(SELECT jsonb_agg(jsonb_build_object('label',c.value->>'categoria','value',(c.value->'atual'->>'valor')::numeric,
 'count',(c.value->'atual'->>'contagem')::numeric,'denominator',(c.value->'atual'->>'denominador')::numeric,
 'source',c.value->'atual'->>'fonte','note',c.value->'atual'->>'nota') ORDER BY c.value->>'categoria')
 FROM jsonb_array_elements(p.payload->'comparacoes') c WHERE c.value->>'serie'=s.value->>'id')) AS item
 FROM pub p CROSS JOIN LATERAL jsonb_array_elements(p.payload->'series') s
 WHERE s.value->>'id' LIKE '%distancia%' OR s.value->>'id' LIKE 'cna_%'
), registered AS (
 SELECT p.ano,
 max((c.value->'atual'->>'valor')::numeric) FILTER(WHERE c.value->>'categoria'='Maratonas cadastradas') AS events,
 max((c.value->'atual'->>'denominador')::numeric) FILTER(WHERE c.value->>'categoria'='Maratonas cadastradas') AS denominator,
 max((c.value->'atual'->>'valor')::numeric) FILTER(WHERE c.value->>'categoria'='Cadastradas com resultados de 42 km') AS with_results
 FROM pub p CROSS JOIN LATERAL jsonb_array_elements(p.payload->'comparacoes') c
 WHERE c.value->>'serie'='maratonas_cadastro' GROUP BY p.ano
), years AS (
 SELECT t.ano,jsonb_build_object('total',t.total,'marathon',t.marathon,'share',100.0*t.marathon/t.total,
 'source_run',CASE WHEN t.ano=2025 THEN 240 ELSE 241 END,
 'distances',(SELECT jsonb_agg(jsonb_build_object('label',g.label,'total',g.total,'female',g.female,'share',100.0*g.total/t.total,'female_share',100.0*g.female/g.total) ORDER BY g.total DESC) FROM grouped g WHERE g.ano=t.ano),
 'registered',jsonb_build_object('events',r.events,'denominator',r.denominator,'share',100.0*r.events/r.denominator,'with_results',r.with_results),
 'principal_series',(SELECT jsonb_agg(item ORDER BY id) FROM principal p WHERE p.ano=t.ano)) AS item
 FROM totals t JOIN registered r USING(ano)
), brazil AS (
 SELECT sum((c.value->'atual'->>'valor')::numeric) AS total FROM pub p
 CROSS JOIN LATERAL jsonb_array_elements(p.payload->'comparacoes') c
 WHERE p.ano=2025 AND c.value->>'serie'='maratonas_concluintes'
)
SELECT jsonb_build_object('years',(SELECT jsonb_object_agg(ano,item) FROM years),
 'nyc',jsonb_build_object('year',2025,'finishers',59219,'previous_announced',59226,
 'url','https://results.nyrr.org/event/M2025/overview','captured','2026-10-19','brazil_top10',(SELECT total FROM brazil)),
 'publication_ids',jsonb_build_array(37,41),'captured_at',current_timestamp)::text AS payload
