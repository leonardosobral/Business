"""Final bounded metadata check; only SELECTs and local evidence writes."""
from pathlib import Path
import hashlib,json,sys
W=Path(__file__).resolve().parent;sys.path.insert(0,str(W));import derive
r=derive.runs();cells={**{k:v for k,v in r.items()if k in derive.CELLS},251:r[251]}
ids=','.join(str(v['id'])for v in cells.values());cids=','.join(map(str,cells))
x=derive.op.query("SELECT jsonb_build_object('cells',(SELECT jsonb_agg(jsonb_build_object('id',id,'version',version,'hash',encode(sha256(convert_to(content,'UTF8')),'hex'),'content',content)) FROM estudo.notebook_cells WHERE id IN("+cids+")),'runs',(SELECT jsonb_agg(jsonb_build_object('id',id,'cell_id',cell_id,'cell_version',cell_version,'sql_sha256',sql_sha256,'frozen',frozen,'status',status,'truncated',truncated)) FROM estudo.notebook_runs WHERE id IN("+ids+")),'products',(SELECT jsonb_agg(jsonb_build_object('code',codigo,'publication',publicacao_id)) FROM estudo.produtos),'publication_snapshot',(SELECT jsonb_build_object('id',id,'run',run_id,'contract',payload->'meta'->'contrato_versao') FROM estudo.web_publicacoes WHERE id=42),'snapshot_active_destinations',(SELECT count(*) FROM estudo.web_destinos WHERE publicacao_id=42),'snapshot_active_products',(SELECT count(*) FROM estudo.produtos WHERE publicacao_id=42))::text AS payload")
cc={v['id']:v for v in x['cells']};rr={v['id']:v for v in x['runs']}
for c,v in cells.items():
 actual=rr[v['id']];assert actual['status']=='ok'and actual['frozen']and not actual['truncated'],c
 assert actual['cell_id']==c and actual['cell_version']==v['cell_version'],c
 assert cc[c]['version']==v['cell_version'],f'Current cell{c} differs from selected run'
 assert hashlib.sha256(cc[c]['content'].strip().encode()).hexdigest()==actual['sql_sha256'],f'Current SQL{c} differs from frozen SQL'
assert x['publication_snapshot']=={'id':42,'run':351,'contract':18},'Private snapshot mismatches final main source'
for value in x['cells']:value.pop('content',None)
x['verified']=True;x['published_by_vertical_task']=False
(W/'notebook-verification.json').write_text(json.dumps(x,ensure_ascii=False,indent=2));print(json.dumps({'verified_cells':len(cells),'all_frozen_complete_current':True,'published_by_task':False}))
