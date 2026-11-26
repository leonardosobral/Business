-- Vertical de maratonas: todas as séries revisadas do estudo principal.
-- Snapshot das publicações 37/41; valores atuais em comparacoes.atual, nunca transcrição do PDF.
-- Não altera queries do DBA, destinos web ou publicações existentes.
WITH p AS (SELECT CASE id WHEN 205 THEN 37 ELSE 41 END AS id,result->'rows'->0->'payload' AS payload FROM estudo.notebook_runs WHERE id IN(205,233))
SELECT p.id AS publicacao, (p.payload->'meta'->>'ano')::int AS ano,
jsonb_build_object('meta',p.payload->'meta',
'series',(SELECT jsonb_agg(s) FROM jsonb_array_elements(p.payload->'series') s WHERE s->>'id' LIKE 'maratonas_%' OR s->>'id' LIKE 'performance_42k_%' OR s->>'id' LIKE 'cna_42k%'),
'comparacoes',(SELECT jsonb_agg(c) FROM jsonb_array_elements(p.payload->'comparacoes') c WHERE c->>'serie' LIKE 'maratonas_%' OR c->>'serie' LIKE 'performance_42k_%' OR c->>'serie' LIKE 'cna_42k%')) AS payload
FROM p WHERE p.id IN (37,41) ORDER BY p.id
