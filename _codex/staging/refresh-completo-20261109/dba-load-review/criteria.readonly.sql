WITH dates AS MATERIALIZED(SELECT data_referencia,count(*) AS matches FROM public.tbbi_dim_data GROUP BY data_referencia),
events AS MATERIALIZED(SELECT e.id_evento,e.data_inicial,e.data_final,e.tipo_corrida,
 coalesce(di.matches,0) AS initial_matches,coalesce(df.matches,0) AS final_matches
 FROM public.tb_evento_corridas e LEFT JOIN dates di ON di.data_referencia=e.data_inicial LEFT JOIN dates df ON df.data_referencia=e.data_final
 WHERE e.pais='BR' AND e.data_final>=DATE '2026-01-01' AND e.data_final<DATE '2026-10-01'),
groups AS MATERIALIZED(SELECT e.id_evento,e.data_inicial,e.data_final,e.tipo_corrida,e.initial_matches,e.final_matches,
 r.homologado IS TRUE AS approved,r.modalidade='KIDS' AS kids,r.modalidade IS NULL AS null_modality,r.tempo_total IS NULL AS null_time,
 coalesce(r.modalidade<>'KIDS' AND e.tipo_corrida IN('rua','trail') AND r.tempo_total IS NOT NULL,false) AS script_predicates,
 count(*) AS n FROM events e JOIN public.tb_resultados r USING(id_evento)
 WHERE r.status_final=0 AND r.concluinte IS TRUE
 GROUP BY e.id_evento,e.data_inicial,e.data_final,e.tipo_corrida,e.initial_matches,e.final_matches,r.homologado IS TRUE,r.modalidade='KIDS',r.modalidade IS NULL,r.tempo_total IS NULL,
 coalesce(r.modalidade<>'KIDS' AND e.tipo_corrida IN('rua','trail') AND r.tempo_total IS NOT NULL,false)),
summary AS(SELECT sum(n) FILTER(WHERE approved) AS approved,
 sum(n) FILTER(WHERE approved AND kids IS TRUE) AS approved_kids,
 sum(n) FILTER(WHERE approved AND null_modality) AS approved_null_modality,
 sum(n) FILTER(WHERE approved AND null_time) AS approved_null_time,
 sum(n) FILTER(WHERE approved AND NOT coalesce(tipo_corrida IN('rua','trail'),false)) AS approved_other_kind,
 sum(n) FILTER(WHERE approved AND initial_matches=0) AS approved_missing_initial_date,
 sum(n) FILTER(WHERE approved AND final_matches=0) AS approved_missing_final_date,
 sum(n) FILTER(WHERE approved AND initial_matches>1) AS approved_duplicate_initial_date,
 sum(n*(initial_matches-1)) FILTER(WHERE approved AND initial_matches>1) AS approved_date_join_extra_rows,
 sum(n) FILTER(WHERE approved AND data_inicial IS DISTINCT FROM data_final) AS approved_initial_final_differ,
 sum(n) FILTER(WHERE approved AND date_trunc('month',data_inicial) IS DISTINCT FROM date_trunc('month',data_final)) AS approved_initial_final_month_differ,
 sum(n) FILTER(WHERE approved AND extract(year FROM data_inicial) IS DISTINCT FROM extract(year FROM data_final)) AS approved_initial_final_year_differ,
 sum(n) FILTER(WHERE approved AND script_predicates AND initial_matches>0) AS approved_retained_by_original_script_unique,
 sum(n) FILTER(WHERE approved AND(NOT script_predicates OR initial_matches=0)) AS approved_excluded_by_original_script,
 sum(n) FILTER(WHERE NOT approved AND script_predicates AND initial_matches>0) AS non_homologated_added_by_original_script_unique,
 sum(n*initial_matches) FILTER(WHERE script_predicates) AS original_script_rows,
 count(DISTINCT id_evento) FILTER(WHERE approved) AS approved_events,
 count(DISTINCT id_evento) FILTER(WHERE script_predicates AND initial_matches>0) AS script_events
 FROM groups)
 SELECT jsonb_build_object('capturado_em',transaction_timestamp(),'read_only',current_setting('transaction_read_only'),'timeout',current_setting('statement_timeout'),
 'summary',(SELECT to_jsonb(s) FROM summary s),
 'months',(SELECT jsonb_agg(to_jsonb(x) ORDER BY mes) FROM(SELECT extract(month FROM data_final)::int AS mes,sum(n) FILTER(WHERE approved) AS approved,sum(n) FILTER(WHERE approved AND(NOT script_predicates OR initial_matches=0)) AS excluded,sum(n) FILTER(WHERE NOT approved AND script_predicates AND initial_matches>0) AS non_homologated_added,sum(n*initial_matches) FILTER(WHERE script_predicates) AS script_rows FROM groups GROUP BY 1)x),
 'approved_flag_groups',(SELECT jsonb_agg(to_jsonb(x)) FROM(SELECT kids,null_modality,null_time,coalesce(tipo_corrida IN('rua','trail'),false) AS allowed_kind,sum(n) AS n FROM groups WHERE approved GROUP BY 1,2,3,4)x),
 'kinds',(SELECT jsonb_agg(to_jsonb(x)) FROM(SELECT tipo_corrida,sum(n) FILTER(WHERE approved) AS approved,sum(n) FILTER(WHERE NOT approved AND script_predicates AND initial_matches>0) AS non_homologated_added FROM groups GROUP BY 1)x)
 )::text AS payload