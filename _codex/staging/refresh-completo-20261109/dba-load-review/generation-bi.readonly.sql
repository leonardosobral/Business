WITH groups AS MATERIALIZED(
 SELECT f.id_geracao AS stored,f.idade_range,r.id_resultado IS NOT NULL AS raw_present,
 CASE WHEN r.data_nascimento<=f.data_evento AND 2026-extract(year FROM r.data_nascimento)::integer BETWEEN 0 AND 120 THEN extract(year FROM r.data_nascimento)::integer END AS plausible_birth_year,count(*) AS n
 FROM public.tbbi_fat_perfil_br_2026 f LEFT JOIN public.tb_resultados r USING(id_resultado) GROUP BY 1,2,3,4),
classified AS MATERIALIZED(SELECT n,stored,raw_present,
 public.get_id_geracao(idade_range,2026) AS two_args,
 public.get_id_geracao(idade_range,2026,CASE WHEN plausible_birth_year IS NOT NULL THEN make_date(plausible_birth_year,1,1) END,DATE '2026-12-31') AS four_args FROM groups)
SELECT jsonb_build_object('capturado_em',transaction_timestamp(),'read_only',current_setting('transaction_read_only'),
 'summary',(SELECT jsonb_build_object('n',sum(n),'groups',count(*),'without_raw',sum(n) FILTER(WHERE NOT raw_present),'stored_different_two_args',sum(n) FILTER(WHERE stored IS DISTINCT FROM two_args),'stored_different_four_args',sum(n) FILTER(WHERE stored IS DISTINCT FROM four_args),'stored_four_args_would_revert_with_two',sum(n) FILTER(WHERE raw_present AND stored=four_args AND two_args IS DISTINCT FROM four_args),'different_two_vs_four',sum(n) FILTER(WHERE two_args IS DISTINCT FROM four_args)) FROM classified),
 'matrix',(SELECT jsonb_agg(to_jsonb(x) ORDER BY stored,two_args,four_args,raw_present) FROM(SELECT stored,two_args,four_args,raw_present,sum(n) AS n FROM classified GROUP BY 1,2,3,4)x))::text AS payload