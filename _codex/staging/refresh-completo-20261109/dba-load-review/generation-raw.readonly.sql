WITH groups AS MATERIALIZED(
 SELECT r.idade_range,CASE WHEN r.data_nascimento<=e.data_final AND 2026-extract(year FROM r.data_nascimento)::integer BETWEEN 0 AND 120 THEN extract(year FROM r.data_nascimento)::integer END AS plausible_birth_year,count(*) AS n
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e USING(id_evento)
 WHERE e.pais='BR' AND e.data_final>=DATE '2026-01-01' AND e.data_final<DATE '2026-10-01' AND r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE GROUP BY 1,2),
classified AS MATERIALIZED(SELECT n,plausible_birth_year IS NOT NULL AS plausible_birth,
 public.get_id_geracao(idade_range,2026) AS two_args,
 public.get_id_geracao(idade_range,2026,CASE WHEN plausible_birth_year IS NOT NULL THEN make_date(plausible_birth_year,1,1) END,DATE '2026-12-31') AS four_args FROM groups)
SELECT jsonb_build_object('capturado_em',transaction_timestamp(),'read_only',current_setting('transaction_read_only'),
 'summary',(SELECT jsonb_build_object('n',sum(n),'groups',count(*),'with_plausible_birth',sum(n) FILTER(WHERE plausible_birth),'different_two_vs_four',sum(n) FILTER(WHERE two_args IS DISTINCT FROM four_args)) FROM classified),
 'matrix',(SELECT jsonb_agg(to_jsonb(x) ORDER BY two_args,four_args) FROM(SELECT two_args,four_args,sum(n) AS n FROM classified GROUP BY 1,2)x))::text AS payload