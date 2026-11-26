from pathlib import Path
import importlib.util,json,sys

ROOT=Path('/Users/Shared/Projects/RunnerHub/Business')
W=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('launch_readonly',ROOT/'_codex/staging/lancamento-lista-observacoes-20261104/inspect.py')
h=importlib.util.module_from_spec(spec);spec.loader.exec_module(h)
sql="""SELECT jsonb_build_object(
 'products',(SELECT jsonb_agg(jsonb_build_object('code',p.codigo,'status',p.status,'publication',p.publicacao_id,'run',w.run_id,'published_at',w.publicado_em,'meta',jsonb_build_object('corte',w.payload#>'{meta,corte}','coletado_em',w.payload#>'{meta,coletado_em}','escopo_trimestres',w.payload#>'{meta,escopo_trimestres}','versao',w.payload#>'{meta,versao}'),'series_count',jsonb_array_length(w.payload->'series'))) FROM estudo.produtos p LEFT JOIN estudo.web_publicacoes w ON w.id=p.publicacao_id),
 'cells',(SELECT jsonb_agg(jsonb_build_object('id',c.id,'section',c.notebook_id,'version',c.version,'source_key',c.source_key,'updated_at',c.updated_at,'hash',md5(c.content),'last_run',(SELECT jsonb_build_object('id',r.id,'cell_version',r.cell_version,'status',r.status,'frozen',r.frozen,'started_at',r.started_at) FROM estudo.notebook_runs r WHERE r.cell_id=c.id ORDER BY r.id DESC LIMIT 1),'last_frozen',(SELECT jsonb_build_object('id',r.id,'cell_version',r.cell_version,'started_at',r.started_at) FROM estudo.notebook_runs r WHERE r.cell_id=c.id AND r.frozen ORDER BY r.id DESC LIMIT 1))) FROM estudo.notebook_cells c JOIN estudo.notebooks n ON n.notebook_id=c.notebook_id WHERE n.caderno_id=6 AND NOT c.archived),
 'checklist',(SELECT jsonb_agg(to_jsonb(d)) FROM (SELECT DISTINCT ON(detalhes->>'step') detalhes->>'step' AS step,id AS version,detalhes->>'responsible' AS responsible,detalhes->>'notes' AS notes FROM estudo.auditoria_comercial WHERE entidade='launch_checklist' AND acao='LAUNCH_STEP_DETAILS' AND detalhes->>'release'='2026-q3-20261113' ORDER BY detalhes->>'step',id DESC)d)
 )::text AS payload"""
if __name__=='__main__':
 result=h.remote("print(json.dumps(bridge(ROOT,raw_query(payload['sql'])+'report=deserializeJSON(q.payload[1]);')))",{'sql':sql})
 (W/'current-state.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
 print(json.dumps({'products':result['products'],'cells':len(result['cells']),'checklist_revisions':{s['step']:s['version'] for s in result['checklist']}},ensure_ascii=False))
 check_sql="""WITH publication AS (
 SELECT w.payload FROM estudo.produtos p JOIN estudo.web_publicacoes w ON w.id=p.publicacao_id WHERE p.codigo='previa-2026-q3'
 ), chosen AS (
 SELECT s FROM publication p CROSS JOIN LATERAL jsonb_array_elements(p.payload->'series') s
 WHERE s->>'id' !~ '^(inscricoes_|cna_|maratonas_revisao_|performance_42k_)' AND s->>'id' NOT IN ('maratonas_cadastro','variacoes_a_z')
 ), comparisons AS (
 SELECT c FROM publication p CROSS JOIN LATERAL jsonb_array_elements(p.payload->'comparacoes') c
 WHERE EXISTS(SELECT 1 FROM chosen WHERE s->>'id'=c->>'serie') AND (c->>'serie'<>'maratonas_destaques' OR c->>'categoria' IN ('Top 10 soma','Mulheres'))
 ) SELECT jsonb_build_object(
 'selected_series',(SELECT count(*) FROM chosen),
 'comparisons',(SELECT count(*) FROM comparisons),
 'null_numeric_values',(SELECT count(*) FROM comparisons WHERE c#>'{atual,valor}'='null'::jsonb OR c->'atual'='null'::jsonb),
 'campaign',(SELECT jsonb_build_object('status',c.status,'discount',c.beneficio_percentual,'vouchers',(SELECT count(*) FROM estudo.vouchers WHERE campanha_id=c.id),'ready',(SELECT count(*) FROM estudo.vouchers WHERE campanha_id=c.id AND status='READY'),'redeemed',(SELECT count(*) FROM estudo.vouchers WHERE campanha_id=c.id AND status='REDEEMED'),'last_redemption_day',(SELECT max((expira_em AT TIME ZONE 'America/Sao_Paulo')::date-1) FROM estudo.vouchers WHERE campanha_id=c.id)) FROM estudo.campanhas c WHERE c.codigo='abraceo-primeiro-acesso'),
 'public_view_definition',pg_get_viewdef('estudo.lancamento_publico'::regclass,true)
 )::text AS payload"""
 checks=h.remote("print(json.dumps(bridge(ROOT,raw_query(payload['sql'])+'report=deserializeJSON(q.payload[1]);')))",{'sql':check_sql})
 (W/'source-checks.json').write_text(json.dumps(checks,ensure_ascii=False,indent=2))
 print(json.dumps({k:v for k,v in checks.items() if k!='public_view_definition'},ensure_ascii=False))
