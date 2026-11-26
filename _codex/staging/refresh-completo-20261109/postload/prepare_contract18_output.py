"""Prepare one more output revision with contract18; preserve the prior candidate."""
from pathlib import Path
import hashlib
import importlib.util
import json
import shutil

W=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('revision_reader',W.parent/'inspect.py')
reader=importlib.util.module_from_spec(spec);spec.loader.exec_module(reader)
snapshot=json.loads((W/'notebook-before.json').read_text())
history=W/'history';history.mkdir(exist_ok=True)
for cell in (251,420,418):
    receipt=json.loads((W/'runs'/f'{cell}.json').read_text())
    live=reader.query("SELECT jsonb_build_object('id',id,'version',version,'hash',md5(content),'content',content)::text AS payload FROM estudo.notebook_cells WHERE id="+str(cell)+" AND NOT archived")
    sql_path=W/'sql'/f'cell-{cell}.sql'
    assert live['version']==receipt['run']['cell_version']
    assert live['hash']==hashlib.md5(sql_path.read_bytes()).hexdigest(),'Concurrent source edit'
    target=next(c for c in snapshot['cells'] if c['id']==cell)
    target.update({k:live[k] for k in ('version','hash','content')})
    shutil.move(W/'runs'/f'{cell}.json',history/f"cell-{cell}-run-{receipt['run']['id']}.json")
    shutil.move(sql_path,history/f"cell-{cell}-run-{receipt['run']['id']}.sql")
    if cell==251:
        old=live['content'].strip().rstrip(';')
        sql_path.write_text('-- Mesmas métricas; contrato18 registra categorias e proveniência novas.\nWITH updated_contract AS (\n'+old+"\n) SELECT jsonb_set(payload,'{meta,contrato_versao}','18'::jsonb) AS payload FROM updated_contract\n")
(W/'notebook-before.json').write_text(json.dumps(snapshot,ensure_ascii=False,indent=2))
print('Prepared contract18 output; previous345/346/347 preserved in history')
