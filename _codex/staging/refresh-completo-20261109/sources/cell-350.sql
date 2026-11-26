-- Cadastro e coleta mantêm fonte operacional; elegíveis 2026 usam BI conservada.
WITH eventos AS MATERIALIZED (
 SELECT id_evento,extract(year FROM data_final)::int AS ano,
  extract(month FROM data_final)::int AS mes
 FROM public.tb_evento_corridas
 WHERE pais='BR' AND (
  (data_final>=DATE '2025-01-01' AND data_final<DATE '2025-10-01') OR
  (data_final>=DATE '2026-01-01' AND data_final<DATE '2026-10-01'))
), resultados AS MATERIALIZED (
 SELECT r.id_evento,count(*) AS registros_coletados,
  count(*) FILTER(WHERE r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE) AS concluintes_estudo
 FROM public.tb_resultados r JOIN eventos e USING(id_evento)
 GROUP BY r.id_evento
), bi AS MATERIALIZED (
 SELECT id_evento,count(*) AS n FROM estudo.vw_resultados_2026
 WHERE status_final=0 AND homologado IS TRUE AND concluinte IS TRUE GROUP BY id_evento
), mensais AS (
 SELECT e.ano,e.mes,count(*) AS provas_cadastradas,
  count(*) FILTER(WHERE r.registros_coletados>0) AS provas_com_resultado_coletado,
  count(*) FILTER(WHERE CASE WHEN e.ano=2026 THEN coalesce(bi.n,0) ELSE coalesce(r.concluintes_estudo,0) END>0) AS provas_com_concluintes_elegiveis,
  sum(CASE WHEN e.ano=2026 THEN coalesce(bi.n,0) ELSE coalesce(r.concluintes_estudo,0) END) AS concluintes_estudo
 FROM eventos e LEFT JOIN resultados r USING(id_evento) LEFT JOIN bi USING(id_evento)
 GROUP BY e.ano,e.mes
)
SELECT jsonb_build_object(
 'coletado_em',transaction_timestamp(),'read_only',current_setting('transaction_read_only'),
 'parametros',jsonb_build_object('2025',jsonb_build_object('inicio','2025-01-01','fim_exclusivo','2025-10-01'),
                               '2026',jsonb_build_object('inicio','2026-01-01','fim_exclusivo','2026-10-01')),
 'definicoes',jsonb_build_object(
  'provas_cadastradas','Eventos no Brasil pela data final, inclusive cadastros inativos ou cancelados; não é contagem pela data de inclusão nem garantia de realização.',
  'provas_com_resultado_coletado','Eventos do calendário com ao menos uma linha em tb_resultados, independentemente de status, homologação ou conclusão. Não certifica captura completa.',
  'provas_com_concluintes_elegiveis','Eventos com ao menos um resultado status_final=0, homologado=true e concluinte=true.',
  'concluintes_estudo','Participações elegíveis; todas as idades e modalidades, não atletas únicos.'),
 'mensais',(SELECT jsonb_agg(to_jsonb(m) ORDER BY ano,mes) FROM mensais m)
) AS payload