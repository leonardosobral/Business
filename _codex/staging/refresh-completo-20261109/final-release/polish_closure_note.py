from pathlib import Path
import base64,hashlib,importlib.util,json
W=Path(__file__).resolve().parent;S=W.parent
spec=importlib.util.spec_from_file_location('reader',S/'inspect.py');r=importlib.util.module_from_spec(spec);spec.loader.exec_module(r)
old=json.loads((W/'closure-note-proposed.json').read_text());before=r.query("SELECT jsonb_build_object('version',version,'hash',md5(content),'content',content)::text AS payload FROM estudo.notebook_cells WHERE id=419 AND NOT archived")
assert before['content']==old['content'] and before['version']==5
marker='## Renovação concluída e publicada — 09/11/2026'
new=before['content'].split(marker)[0].rstrip()+'\n'+(W/'closure-appendix.md').read_text()
cfg={'actor':old['actor'],'version':before['version'],'hash':before['hash'],'content':new};enc=base64.b64encode(json.dumps(cfg,ensure_ascii=False).encode()).decode()
cf='cfg=deserializeJSON(toString(binaryDecode("'+enc+'","base64")));transaction{q=queryExecute("SELECT version,md5(content) AS hash FROM estudo.notebook_cells WHERE id=419 AND NOT archived",{},{datasource="runner_dba",timeout=10});if(q.version[1]!=cfg.version||q.hash[1]!=cfg.hash)throw(message="Nota alterada; reler.");svc=new estudo.includes.StudyNotebook().init();saved=svc.saveCell(419,cfg.version,"markdown","markdown",cfg.content,cfg.actor);structDelete(saved,"content");report={note=saved};}'
result=r.h.h.remote("print(json.dumps(bridge(ROOT,payload['cf'])))",{'cf':cf});assert result['note']['version']==6
(W/'closure-note-editorial-receipt.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
after=r.query("SELECT jsonb_build_object('version',version,'hash',md5(content),'content',content)::text AS payload FROM estudo.notebook_cells WHERE id=419 AND NOT archived");assert after['content']==new and after['version']==6
(W/'closure-note-final.json').write_text(json.dumps(after,ensure_ascii=False,indent=2));print(json.dumps({'note_revision':6,'content_verified':True}))
