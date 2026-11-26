"""Compile candidate SELECT and inspect aggregate sample only; no DDL/DML."""
from pathlib import Path
import base64
import hashlib
import importlib.util
import json

W=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('load_validation_reader',W.parent/'inspect.py')
reader=importlib.util.module_from_spec(spec);spec.loader.exec_module(reader)
source=(W/'source-select.sql').read_text().strip().rstrip(';')
token='AND r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE'
assert source.count(token)==1
sample=source.replace(token,token+' AND r.id_evento=34529 ORDER BY r.id_resultado LIMIT 1000')
sample_sql="""SELECT jsonb_build_object('rows',count(*),'unique_ids',count(DISTINCT id_resultado),
 'homologated',count(*) FILTER(WHERE resultado_homologado IS TRUE),
 'outside_window',count(*) FILTER(WHERE data_evento<DATE '2026-01-01' OR data_evento>=DATE '2026-10-01'),
 'null_required_id',count(*) FILTER(WHERE id_resultado IS NULL OR id_evento IS NULL),
 'generations',(SELECT jsonb_agg(to_jsonb(g) ORDER BY id_geracao) FROM(SELECT id_geracao,count(*) AS n FROM sample GROUP BY id_geracao)g)
 )::text AS payload FROM sample"""
cfg=dict(compile='SELECT * FROM ('+source+')candidate LIMIT 0',
         sample='WITH sample AS MATERIALIZED ('+sample+') '+sample_sql)
encoded=base64.b64encode(json.dumps(cfg).encode()).decode()
cf='cfg=deserializeJSON(toString(binaryDecode("'+encoded+'","base64")));'
cf+='transaction isolation="repeatable_read" {'
cf+=reader.h.h.h.raw_query('SET TRANSACTION READ ONLY')
cf+=reader.h.h.h.raw_query("SET LOCAL statement_timeout='45s'")
cf+='q=queryExecute(cfg.compile,{},{datasource="runner_dba",timeout=50});metadata=getMetaData(q);report={"compiled":true,"columns":[],"returned_rows":q.recordCount};for(c in metadata)arrayAppend(report.columns,{"name":c.name,"type":c.typeName});'
cf+='q=queryExecute(cfg.sample,{},{datasource="runner_dba",timeout=50});report["sample"]=deserializeJSON(q.payload[1]);}'
result=reader.h.h.remote("print(json.dumps(bridge(ROOT,payload['cf'])))",{'cf':cf})
result['source_select_sha256']=hashlib.sha256(source.encode()).hexdigest()
result['read_only']=True
(W/'validation-readonly.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
expected=[c['name'] for c in json.loads((W.parent/'dba-load-review/current-metadata.json').read_text())['columns'] if c['table']=='tbbi_fat_perfil_br_2026']
assert result['compiled'] and result['returned_rows']==0
assert [c['name'] for c in result['columns']]==expected
assert result['sample']['rows']==result['sample']['unique_ids']==result['sample']['homologated']==1000
assert result['sample']['outside_window']==result['sample']['null_required_id']==0
print(json.dumps({'compiled_columns':len(expected),'sample_rows':result['sample']['rows'],'unique':True,'window_and_eligibility':True,'ddl_dml_executed':False},ensure_ascii=False))
