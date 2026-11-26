-- Seleção inicial de provas identificadas na referência CR 2026, com resultados elegíveis.
-- Ainda não é censo nem lista final de percursos aferidos. Jan-Set, por data_final da base.
-- Uma edição por prova: Goiânia 37874 (não 43068), Torres 43073 (não 34240), Feira 43077 (não 37693).
-- Mesma data/cidade/nome e fonte de cronometragem; não somar importações alternativas.
-- Paraná 37310: data do cadastro diverge da referência; ambos dentro do recorte, conferir antes de análise mensal.
-- FILA 36974 retida para auditoria de 23 tempos sub2h; Piracicaba tem vínculo/data divergente; demais lacunas ficam no inventário.
-- Floripa usa a captura oficial congelada 210, igual ao estudo geral; substitui o BI integralmente (3594 -> 3592), sem soma.
WITH fonte AS (SELECT j.value AS v FROM estudo.notebook_runs r CROSS JOIN LATERAL jsonb_array_elements(r.result->'rows') j WHERE r.id=243),
floripa AS (SELECT result->'rows'->0->'payload'->'classificados_geral_elite' AS f FROM estudo.notebook_runs WHERE id=210)
SELECT (v->>'id_evento')::int AS id_evento,v->>'nome_evento' AS nome_evento,v->>'data_final' AS data_final,
(v->>'id_agrega_evento')::int AS id_agrega_evento,
CASE WHEN (v->>'id_evento')::int=34529 THEN (f->>'concluintes')::int ELSE (v->>'participacoes')::int END AS participacoes,
CASE WHEN (v->>'id_evento')::int=34529 THEN (f->>'feminino')::int ELSE (v->>'feminino')::int END AS feminino,
CASE WHEN (v->>'id_evento')::int=34529 THEN (f->>'sub3')::int ELSE (v->>'sub3')::int END AS sub3,
CASE WHEN (v->>'id_evento')::int=34529 THEN (f->>'sub4')::int ELSE (v->>'sub4')::int END AS sub4
FROM fonte CROSS JOIN floripa WHERE (v->>'id_evento')::int IN(43066,34236,33486,34235,29291,34529,38863,37310,34841,39421,35868,33490,36245,37815,43078,40448,34840,36973,39393,36250,36249,37874,31176,39461,37868,38234,37322,40597,31179,34131,36246,33976,43073,37307,37006,43077,33713,36665,43074) ORDER BY participacoes DESC,id_evento