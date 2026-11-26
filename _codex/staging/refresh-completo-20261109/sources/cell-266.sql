-- Conciliação da regra legada de grupos com a transcrição congelada da p13.
-- Ambas as fontes são imutáveis: execuções 48 (cálculo) e 34 (PDF).
WITH nomes AS (SELECT column1 AS id,column2 AS nome FROM (VALUES (24999,'Maratona do Rio'),(24998,'Maratona de Porto Alegre'),(26867,'SP City Marathon'),(22792,'Maratona de Floripa'),(22582,'Maratona de São Paulo'),(27104,'Maratona de Curitiba'),(28253,'Maratona Monumental de Brasília'),(22590,'New Balance 42k Porto Alegre'),(25481,'Maratona de Aracaju'),(24016,'Maratona de Salvador')) t),
calculo AS (SELECT r FROM estudo.notebook_runs n CROSS JOIN LATERAL jsonb_array_elements(n.result->'rows') r WHERE n.id=48 AND n.frozen AND n.status='ok' AND NOT n.truncated),
referencia AS (SELECT s->>'id' AS serie,v->>'rotulo' AS categoria,v->>'valor' AS tempo FROM estudo.notebook_runs n CROSS JOIN LATERAL jsonb_array_elements(n.result->'rows'->0->'referencias') s CROSS JOIN LATERAL jsonb_array_elements(s->'valores') v WHERE n.id=34 AND n.frozen)
SELECT r->>'id_evento' AS id_evento,nomes.nome AS prova,r->>'grupo' AS grupo,
ref.tempo AS publicado,r->>'tempo_medio' AS recalculado,
extract(epoch FROM (r->>'tempo_medio')::time)-extract(epoch FROM ref.tempo::time) AS diferenca_segundos,
(r->>'incluidos')::bigint AS resultados_incluidos,(r->>'posicoes_distintas')::bigint AS posicoes_distintas,
(r->>'inscritos')::bigint AS inscritos,(r->>'classificacao_ausente_ou_invalida')::bigint AS classificacao_ausente_ou_invalida
FROM calculo JOIN nomes ON nomes.id=(r->>'id_evento')::integer JOIN referencia ref ON ref.serie='maratonas_'||(r->>'grupo') AND ref.categoria=nomes.nome ORDER BY nomes.nome,r->>'grupo'
