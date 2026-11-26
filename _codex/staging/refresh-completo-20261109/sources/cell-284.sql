-- P15: tipos mapeados exatamente; não confunde Hike com TrailRun nem soma os 11 tipos para obter o denominador.
-- Recálculo exclui apenas aspect_type=delete; referência PDF e SELECT legado permanecem consultáveis.
WITH mapa AS(SELECT column1 AS tipo,column2 AS categoria FROM(VALUES ('WeightTraining','Fortalecimento'),('Walk','Caminhada'),('Workout','Treino livre'),('Ride','Pedal'),('Swim','Natação'),('Yoga','Yoga'),('VirtualRide','Rolo'),('Hike','Trilha'),('Elliptical','Elíptico'),('Crossfit','Crossfit'),('StairStepper','Stepper')) t),
f25 AS(SELECT r FROM estudo.notebook_runs n CROSS JOIN LATERAL jsonb_array_elements(n.result->'rows') r WHERE n.id=69 AND n.frozen AND n.status='ok' AND NOT n.truncated),
f26 AS(SELECT r FROM estudo.notebook_runs n CROSS JOIN LATERAL jsonb_array_elements(n.result->'rows') r WHERE n.id=65 AND n.frozen AND n.status='ok' AND NOT n.truncated),
base26 AS(SELECT sum((r->>'com_indicacao_delete')::bigint) AS excluidos,max((r->>'denominador')::bigint) AS bruto FROM f26),
fonte AS(
 SELECT 2025 AS ano,r->>'type' AS tipo,(r->>'total')::bigint AS total,(r->>'denominador')::bigint AS denominador,
 (r->>'total_bruto')::bigint AS total_bruto,(r->>'excluidos_delete')::bigint AS excluidos_delete,
 (r->>'denominador_bruto')::bigint AS denominador_bruto,(r->>'tipo_nulo')::bigint AS tipo_nulo,69 AS execucao_fonte
 FROM f25 WHERE r->>'type' IS NOT NULL
 UNION ALL
 SELECT 2026,r->>'type',(r->>'total')::bigint-(r->>'com_indicacao_delete')::bigint,bruto-excluidos,
 (r->>'total')::bigint,(r->>'com_indicacao_delete')::bigint,bruto,(r->>'tipo_nulo')::bigint,65 FROM f26 CROSS JOIN base26
), pdf AS(SELECT v->>'rotulo' AS categoria,(v->>'valor')::numeric AS percentual FROM estudo.notebook_runs n CROSS JOIN LATERAL jsonb_array_elements(n.result->'rows'->0->'payload'->'series') s CROSS JOIN LATERAL jsonb_array_elements(s->'valores') v WHERE n.id=63 AND n.frozen AND s->>'id'='outros_esportes')
SELECT f.*,m.categoria,f.total*100.0/f.denominador AS percentual,
f.total_bruto*100.0/f.denominador_bruto AS percentual_legado,
CASE WHEN ano=2025 THEN pdf.percentual ELSE NULL END AS percentual_pdf
FROM fonte f JOIN mapa m USING(tipo) JOIN pdf ON pdf.categoria=m.categoria ORDER BY ano,m.categoria
