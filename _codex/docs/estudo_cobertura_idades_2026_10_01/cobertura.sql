-- P02/P03 — cobertura de coleta dentro do cadastro atual, sem estimativa nacional.
-- BR, data final e todas as modalidades; rua/trail é recorte separado, não soma adicional.
-- Cadastrados incluem inativos; coletado exige qualquer linha, sem certificar completude.
WITH calendario AS (
 SELECT id_evento,data_final,tipo_corrida,ativo FROM public.tb_evento_corridas
 WHERE pais='BR' AND data_final>=DATE '2025-01-01' AND data_final<DATE '2026-09-27'
), por_evento AS (
 SELECT r.id_evento,count(*) AS brutos,
 count(*) FILTER(WHERE r.status_final=0 AND r.homologado IS TRUE) AS view,
 count(*) FILTER(WHERE r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE) AS concluintes,
 count(*) FILTER(WHERE r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS FALSE) AS conclusao_falsa,
 count(*) FILTER(WHERE r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS NULL) AS conclusao_desconhecida
 FROM public.tb_resultados r JOIN calendario c USING(id_evento) GROUP BY r.id_evento
), periodos AS(SELECT column1 AS escopo,column2 AS ano,column3 AS inicio,column4 AS fim FROM(VALUES
 ('2025 · ano completo',2025,DATE '2025-01-01',DATE '2026-01-01'),
 ('2025 · até 26/09',2025,DATE '2025-01-01',DATE '2025-09-27'),
 ('2026 · até 26/09',2026,DATE '2026-01-01',DATE '2026-09-27'))t),
universos AS(SELECT 'Todas as modalidades' AS universo UNION ALL SELECT 'Rua/trail'),
cobertura AS(
 SELECT s.escopo,s.ano,u.universo,s.inicio::text,s.fim::text AS fim_exclusivo,count(*) AS cadastradas,
 count(*) FILTER(WHERE NOT c.ativo) AS inativas,
 count(*) FILTER(WHERE p.brutos>0) AS coletadas,
 count(*) FILTER(WHERE p.view>0) AS com_view,
 count(*) FILTER(WHERE p.concluintes>0) AS com_concluintes,
 coalesce(sum(p.brutos),0)::bigint AS resultados_brutos,
 coalesce(sum(p.view),0)::bigint AS resultados_view,
 coalesce(sum(p.concluintes),0)::bigint AS concluintes,
 coalesce(sum(p.conclusao_falsa),0)::bigint AS conclusao_falsa,
 coalesce(sum(p.conclusao_desconhecida),0)::bigint AS conclusao_desconhecida,
 count(*) FILTER(WHERE p.brutos>0)*100.0/nullif(count(*),0) AS coleta_pct,
 count(*) FILTER(WHERE p.view>0)*100.0/nullif(count(*),0) AS view_pct
 FROM calendario c JOIN periodos s ON c.data_final>=s.inicio AND c.data_final<s.fim
 CROSS JOIN universos u LEFT JOIN por_evento p USING(id_evento)
 WHERE u.universo='Todas as modalidades' OR c.tipo_corrida IN('rua','trail')
 GROUP BY s.escopo,s.ano,u.universo,s.inicio,s.fim
)
SELECT jsonb_build_object('coletado_em',current_timestamp,'cobertura',(SELECT jsonb_agg(to_jsonb(c) ORDER BY escopo,universo) FROM cobertura c)) AS payload;
