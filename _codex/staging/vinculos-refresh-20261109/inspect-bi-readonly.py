from pathlib import Path
import importlib.util,json
p=Path(__file__).parents[1]/'fechamento-q3-20261109/comparativo-profissional/inspect.py'
s=importlib.util.spec_from_file_location('q',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
sql="""SELECT jsonb_build_object(
 'function_refs',(SELECT jsonb_agg(jsonb_build_object('schema',n.nspname,'name',p.proname,'definition',pg_get_functiondef(p.oid))) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE p.prokind IN('f','p') AND n.nspname NOT IN('pg_catalog','information_schema') AND (p.prosrc ILIKE '%tbbi_fat_perfil%' OR p.prosrc ILIKE '%tbbi_dim_organizacao_2026%')),
 'cells',(SELECT jsonb_agg(jsonb_build_object('id',c.id,'notebook',c.notebook_id,'version',c.version,'source_key',c.source_key,'origem',c.origem,'content',c.content)) FROM estudo.notebook_cells c WHERE c.content ILIKE '%tbbi_fat_perfil_br_2026%' OR c.content ILIKE '%tbbi_dim_organizacao_2026%'),
 'backup_relations',(SELECT jsonb_agg(jsonb_build_object('schema',n.nspname,'name',c.relname,'kind',c.relkind,'owner',pg_get_userbyid(c.relowner),'estimate',c.reltuples,'size',pg_total_relation_size(c.oid))) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname NOT IN('pg_catalog','information_schema') AND (c.relname ILIKE '%perfil%2026%' OR c.relname ILIKE '%bi%2026%' OR c.relname ILIKE '%backup%')),
 'constraints',(SELECT jsonb_agg(jsonb_build_object('table',conrelid::regclass::text,'name',conname,'definition',pg_get_constraintdef(oid))) FROM pg_constraint WHERE conrelid='public.tbbi_fat_perfil_br_2026'::regclass OR confrelid='public.tbbi_fat_perfil_br_2026'::regclass),
 'triggers',(SELECT jsonb_agg(jsonb_build_object('name',tgname,'definition',pg_get_triggerdef(oid))) FROM pg_trigger WHERE tgrelid='public.tbbi_fat_perfil_br_2026'::regclass AND NOT tgisinternal),
 'indexes',(SELECT jsonb_agg(jsonb_build_object('name',indexname,'definition',indexdef)) FROM pg_indexes WHERE schemaname='public' AND tablename='tbbi_fat_perfil_br_2026'),
 'adapter_defs',(SELECT jsonb_agg(jsonb_build_object('name',c.oid::regclass::text,'definition',pg_get_viewdef(c.oid,true))) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='estudo' AND c.relkind='v' AND c.relname IN('vwbi_perfil_br_2026','vw_resultados_2026','vw_resultados_comparativo_2025_2026')),
 'get_id_defs',(SELECT jsonb_agg(jsonb_build_object('name',p.proname,'args',pg_get_function_identity_arguments(p.oid),'definition',pg_get_functiondef(p.oid))) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname IN('get_id_geracao','get_id_categoria_cbat','get_id_faixa','get_id_localidade','get_id_organizador','get_id_cronometragem'))
 )::text AS payload"""
r=m.query(sql)
out=Path(__file__).parent/'bi-load-sources-readonly.json';out.write_text(json.dumps(r,ensure_ascii=False,indent=2))
print(json.dumps({k:([{'name':x.get('name'),'id':x.get('id'),'version':x.get('version'),'source_key':x.get('source_key')} for x in v] if isinstance(v,list) else v) for k,v in r.items()},ensure_ascii=False,indent=2))
for c in r.get('cells') or []:
 (Path(__file__).parent/f"bi-source-cell-{c['id']}.sql").write_text(c['content'])
