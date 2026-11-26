from pathlib import Path
import importlib.util,json,sys,hashlib,re
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business');W=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('readonly_compare',ROOT/'_codex/staging/vinculos-refresh-20261109/compare-bi-readonly.py');helper=importlib.util.module_from_spec(spec);spec.loader.exec_module(helper)
QUERIES={}
QUERIES['metadata']="""SELECT jsonb_build_object(
 'capturado_em',transaction_timestamp(),'read_only',current_setting('transaction_read_only'),
 'columns',(SELECT jsonb_agg(jsonb_build_object('name',column_name,'type',data_type,'nullable',is_nullable,'default',column_default) ORDER BY ordinal_position) FROM information_schema.columns WHERE table_schema='public' AND table_name='tbbi_fat_perfil_br_2026'),
 'functions',(SELECT jsonb_agg(jsonb_build_object('name',p.proname,'args',pg_get_function_identity_arguments(p.oid),'definition',pg_get_functiondef(p.oid))) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname IN('get_id_geracao','get_id_categoria_cbat','get_id_dim_faixa')),
 'views',(SELECT jsonb_agg(jsonb_build_object('name',c.oid::regclass::text,'definition',pg_get_viewdef(c.oid,true))) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE c.relkind='v' AND (c.oid='public.vwbi_fat_perfil_br_2026'::regclass OR (n.nspname='estudo' AND c.relname IN('vwbi_perfil_br_2026','vw_resultados_2026','vw_resultados_comparativo_2025_2026')))),
 'direct_dependents',(SELECT jsonb_agg(DISTINCT c.oid::regclass::text) FROM pg_depend d JOIN pg_rewrite r ON r.oid=d.objid JOIN pg_class c ON c.oid=r.ev_class WHERE d.refobjid IN('public.tbbi_fat_perfil_br_2026'::regclass,'public.vwbi_fat_perfil_br_2026'::regclass) AND c.oid<>d.refobjid),
 'table_acl',(SELECT relacl FROM pg_class WHERE oid='public.tbbi_fat_perfil_br_2026'::regclass),
 'view_acl',(SELECT relacl FROM pg_class WHERE oid='public.vwbi_fat_perfil_br_2026'::regclass),
 'date_dimension',(SELECT jsonb_build_object('rows',sum(n),'dates',count(*),'first',min(data_referencia),'last',max(data_referencia),'duplicate_dates',count(*) FILTER(WHERE n>1),'duplicate_surplus',sum(n-1)) FROM(SELECT data_referencia,count(*) AS n FROM public.tbbi_dim_data GROUP BY data_referencia)x)
 )::text AS payload"""
QUERIES['criteria']="""WITH dates AS MATERIALIZED(SELECT data_referencia,count(*) AS matches FROM public.tbbi_dim_data GROUP BY data_referencia),
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
 )::text AS payload"""
QUERIES['generation-raw']="""WITH groups AS MATERIALIZED(
 SELECT r.idade_range,CASE WHEN r.data_nascimento<=e.data_final AND 2026-extract(year FROM r.data_nascimento)::integer BETWEEN 0 AND 120 THEN extract(year FROM r.data_nascimento)::integer END AS plausible_birth_year,count(*) AS n
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e USING(id_evento)
 WHERE e.pais='BR' AND e.data_final>=DATE '2026-01-01' AND e.data_final<DATE '2026-10-01' AND r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE GROUP BY 1,2),
classified AS MATERIALIZED(SELECT n,plausible_birth_year IS NOT NULL AS plausible_birth,
 public.get_id_geracao(idade_range,2026) AS two_args,
 public.get_id_geracao(idade_range,2026,CASE WHEN plausible_birth_year IS NOT NULL THEN make_date(plausible_birth_year,1,1) END,DATE '2026-12-31') AS four_args FROM groups)
SELECT jsonb_build_object('capturado_em',transaction_timestamp(),'read_only',current_setting('transaction_read_only'),
 'summary',(SELECT jsonb_build_object('n',sum(n),'groups',count(*),'with_plausible_birth',sum(n) FILTER(WHERE plausible_birth),'different_two_vs_four',sum(n) FILTER(WHERE two_args IS DISTINCT FROM four_args)) FROM classified),
 'matrix',(SELECT jsonb_agg(to_jsonb(x) ORDER BY two_args,four_args) FROM(SELECT two_args,four_args,sum(n) AS n FROM classified GROUP BY 1,2)x))::text AS payload"""
QUERIES['generation-bi']="""WITH groups AS MATERIALIZED(
 SELECT f.id_geracao AS stored,f.idade_range,r.id_resultado IS NOT NULL AS raw_present,
 CASE WHEN r.data_nascimento<=f.data_evento AND 2026-extract(year FROM r.data_nascimento)::integer BETWEEN 0 AND 120 THEN extract(year FROM r.data_nascimento)::integer END AS plausible_birth_year,count(*) AS n
 FROM public.tbbi_fat_perfil_br_2026 f LEFT JOIN public.tb_resultados r USING(id_resultado) GROUP BY 1,2,3,4),
classified AS MATERIALIZED(SELECT n,stored,raw_present,
 public.get_id_geracao(idade_range,2026) AS two_args,
 public.get_id_geracao(idade_range,2026,CASE WHEN plausible_birth_year IS NOT NULL THEN make_date(plausible_birth_year,1,1) END,DATE '2026-12-31') AS four_args FROM groups)
SELECT jsonb_build_object('capturado_em',transaction_timestamp(),'read_only',current_setting('transaction_read_only'),
 'summary',(SELECT jsonb_build_object('n',sum(n),'groups',count(*),'without_raw',sum(n) FILTER(WHERE NOT raw_present),'stored_different_two_args',sum(n) FILTER(WHERE stored IS DISTINCT FROM two_args),'stored_different_four_args',sum(n) FILTER(WHERE stored IS DISTINCT FROM four_args),'stored_four_args_would_revert_with_two',sum(n) FILTER(WHERE raw_present AND stored=four_args AND two_args IS DISTINCT FROM four_args),'different_two_vs_four',sum(n) FILTER(WHERE two_args IS DISTINCT FROM four_args)) FROM classified),
 'matrix',(SELECT jsonb_agg(to_jsonb(x) ORDER BY stored,two_args,four_args,raw_present) FROM(SELECT stored,two_args,four_args,raw_present,sum(n) AS n FROM classified GROUP BY 1,2,3,4)x))::text AS payload"""
if __name__=='__main__':
 task=sys.argv[1];sql=QUERIES[task]
 (W/(task+'.readonly.sql')).write_text(sql)
 r=helper.query(sql);(W/(task+'.json')).write_text(json.dumps(r,ensure_ascii=False,indent=2));print(json.dumps(r,ensure_ascii=False,indent=2))
