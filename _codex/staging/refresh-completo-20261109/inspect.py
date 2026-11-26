from pathlib import Path
import importlib.util,json,base64

ROOT=Path('/Users/Shared/Projects/RunnerHub/Business')
W=Path(__file__).resolve().parent
s=importlib.util.spec_from_file_location('bridge_reader',ROOT/'_codex/staging/fechamento-q3-20261109/inspect_current.py')
h=importlib.util.module_from_spec(s);s.loader.exec_module(h)
def query(sql):
 wrapped="WITH document AS MATERIALIZED ("+sql+") SELECT substring(payload FROM pos FOR 16000) AS payload FROM document CROSS JOIN LATERAL generate_series(1,char_length(payload),16000) AS pieces(pos) ORDER BY pos"
 body="qtext=[];for(j=1;j<=q.recordCount;j++)arrayAppend(qtext,q.payload[j]);report=deserializeJSON(arrayToList(qtext,''));"
 return h.h.remote("print(json.dumps(bridge(ROOT,raw_query(payload['sql'])+payload['body'])))",{'sql':wrapped,'body':body})
if __name__=='__main__':
 sql="""SELECT jsonb_build_object(
 'cells',(SELECT jsonb_agg(jsonb_build_object('id',c.id,'section',c.notebook_id,'section_title',n.notebook_title,'version',c.version,'type',c.cell_type,'lang',c.lang,'content',c.content,'source_key',c.source_key,'updated_at',c.updated_at,'hash',md5(c.content),'last_frozen',(SELECT jsonb_build_object('id',r.id,'cell_version',r.cell_version,'started_at',r.started_at) FROM estudo.notebook_runs r WHERE r.cell_id=c.id AND r.frozen ORDER BY r.id DESC LIMIT 1)) ORDER BY c.id) FROM estudo.notebook_cells c JOIN estudo.notebooks n ON n.notebook_id=c.notebook_id WHERE n.caderno_id=6 AND NOT c.archived),
 'products',(SELECT jsonb_agg(jsonb_build_object('id',p.id,'code',p.codigo,'publication',p.publicacao_id,'run',w.run_id,'status',p.status)) FROM estudo.produtos p LEFT JOIN estudo.web_publicacoes w ON w.id=p.publicacao_id),
 'destinations',(SELECT jsonb_agg(to_jsonb(d)) FROM estudo.web_destinos d),
 'public_definition',pg_get_viewdef('estudo.lancamento_publico'::regclass,true)
 )::text AS payload"""
 r=query(sql);(W/'notebook-before.json').write_text(json.dumps(r,ensure_ascii=False,indent=2))
 for c in r['cells']:
  p=W/'sources'/('cell-'+str(c['id'])+('.sql' if c['lang']=='sql' else '.md'));p.parent.mkdir(exist_ok=True);p.write_text(c['content'])
 summary=[{k:c[k] for k in ['id','section','section_title','version','type','lang','last_frozen']} for c in r['cells'] if c['lang']=='sql']
 (W/'source-inventory.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2))
 print(json.dumps({'active_cells':len(r['cells']),'sql_cells':len(summary),'products':r['products'],'destinations':r['destinations']},ensure_ascii=False))
