"""Register the missing-BI-IDs audit in the authoritative notebook."""
from pathlib import Path
import base64
import importlib.util
import json

W = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('audit_reader', W / 'inspect.py')
reader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reader)
target = W / 'freshness-audit-receipt.json'
assert not target.exists(), 'Inspect existing audit receipt before any retry'
cfg = dict(section=63, actor=json.loads((W/'preflight.json').read_text())['actor'],
           content=(W/'candidate-sql/freshness-audit.sql').read_text())
encoded = base64.b64encode(json.dumps(cfg,ensure_ascii=False).encode()).decode()
cf = 'cfg=deserializeJSON(toString(binaryDecode("'+encoded+'","base64")));'
cf += 'existing=queryExecute("SELECT id,version FROM estudo.notebook_cells WHERE notebook_id=:section AND content=:content AND NOT archived",{section={value=cfg.section,cfsqltype="cf_sql_bigint"},content={value=cfg.content,cfsqltype="cf_sql_longvarchar"}},{datasource="runner_dba",timeout=10});'
cf += 'if(existing.recordCount)throw(message="Auditoria já existe; recuperar célula e execuções antes de repetir.");'
cf += 'svc=new estudo.includes.StudyNotebook().init();saved=svc.createCell(cfg.section,"code","sql",cfg.content,cfg.actor);'
cf += 'run=svc.execute(saved.id,saved.version,saved.content,cfg.actor);'
cf += 'if(run.status=="ok" && !run.truncated)run=svc.freeze(run.id,"Auditoria da renovação BI — 09/11/2026","Diferenças por id_resultado entre elegibilidade operacional Jan–Set e fato BI2026. Não é nova publicação ou estimativa. Confirmar a carga do DBA antes de renovar os consumidores.",cfg.actor);'
cf += 'structDelete(saved,"content");structDelete(run,"result_json");report={"saved":saved,"run":run};'
report = reader.h.h.remote("print(json.dumps(bridge(ROOT,payload['cf'])))", {'cf':cf})
target.write_text(json.dumps(report,ensure_ascii=False,indent=2))
r = report['run']
assert r['status']=='ok' and r['frozen'], 'Audit failed; receipt preserved'
report['data'] = reader.query("SELECT jsonb_build_object('result',result,'id',id,'cell_id',cell_id,'cell_version',cell_version,'started_at',started_at,'frozen',frozen,'status',status)::text AS payload FROM estudo.notebook_runs WHERE id="+str(int(r['id'])))
target.write_text(json.dumps(report,ensure_ascii=False,indent=2))
row = report['data']['result']['rows'][0]
assert row['operacional_linhas']==row['operacional_ids']
assert row['bi_linhas']==row['bi_ids']
assert row['operacional_ids']==row['ids_comuns']+row['novos_no_operacional']
assert row['bi_ids']==row['ids_comuns']+row['bi_fora_elegibilidade_atual']
print(json.dumps({'cell':r['cell_id'],'run':r['id'],'data':row},ensure_ascii=False))
