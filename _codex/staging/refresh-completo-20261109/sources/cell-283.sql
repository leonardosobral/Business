-- P13: referência PDF, regra legada e regra revisada; cada origem é uma execução congelada.
WITH nomes AS (SELECT column1 AS id,column2 AS nome FROM (VALUES (24999,'Maratona do Rio'),(24998,'Maratona de Porto Alegre'),(26867,'SP City Marathon'),(22792,'Maratona de Floripa'),(22582,'Maratona de São Paulo'),(27104,'Maratona de Curitiba'),(28253,'Maratona Monumental de Brasília'),(22590,'New Balance 42k Porto Alegre'),(25481,'Maratona de Aracaju'),(24016,'Maratona de Salvador')) t),
novo AS (SELECT r FROM estudo.notebook_runs n CROSS JOIN LATERAL jsonb_array_elements(n.result->'rows') r WHERE n.id=67 AND n.frozen AND n.status='ok' AND NOT n.truncated),
legado AS (SELECT r FROM estudo.notebook_runs n CROSS JOIN LATERAL jsonb_array_elements(n.result->'rows') r WHERE n.id=48 AND n.frozen AND n.status='ok' AND NOT n.truncated),
referencia AS (SELECT s->>'id' AS serie,v->>'rotulo' AS categoria,v->>'valor' AS tempo FROM estudo.notebook_runs n CROSS JOIN LATERAL jsonb_array_elements(n.result->'rows'->0->'referencias') s CROSS JOIN LATERAL jsonb_array_elements(s->'valores') v WHERE n.id=34 AND n.frozen)
SELECT nomes.nome AS categoria,n.r->>'grupo' AS grupo,(n.r->>'id_evento')::integer AS id_evento,
ref.tempo AS publicado,l.r->>'tempo_medio' AS legado,n.r->>'tempo_medio' AS revisado,
extract(epoch FROM(n.r->>'tempo_medio')::time)-extract(epoch FROM ref.tempo::time) AS diferenca_pdf_segundos,
(n.r->>'denominador')::bigint AS denominador,(n.r->>'incluidos')::integer AS incluidos,
(l.r->>'incluidos')::integer AS incluidos_legado,(n.r->>'selecionados')::integer AS selecionados,
n.r->>'tempo_limite' AS tempo_limite,(n.r->>'empatados_no_limite')::integer AS empatados_no_limite
FROM novo n JOIN nomes ON nomes.id=(n.r->>'id_evento')::integer
JOIN legado l ON l.r->>'id_evento'=n.r->>'id_evento' AND l.r->>'grupo'=n.r->>'grupo'
JOIN referencia ref ON ref.serie='maratonas_'||(n.r->>'grupo') AND ref.categoria=nomes.nome ORDER BY nomes.nome,n.r->>'grupo'
