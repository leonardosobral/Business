from pathlib import Path
import importlib.util,json,sys

W=Path(__file__).resolve().parent
s=importlib.util.spec_from_file_location('inspect_paired',W/'inspect.py');h=importlib.util.module_from_spec(s);s.loader.exec_module(h)
s=importlib.util.spec_from_file_location('reader_builder',h.ROOT.parent/'RoadRunners/_codex/staging/imprensa-estudos-20261019/reader-builder.py');b=importlib.util.module_from_spec(s);s.loader.exec_module(b)
sql=b.extract_projection((h.ROOT/'estudos/includes/StudyAccess.cfc').read_text()).replace(':code',"'previa-2026-q3'")
(W/(sys.argv[1]+'-projection.sql')).write_text(sql)
sql="WITH document AS MATERIALIZED ("+sql+") SELECT substring(payload_json FROM offset_char FOR 16000) AS piece FROM document CROSS JOIN LATERAL generate_series(1,char_length(payload_json),16000) offset_char ORDER BY offset_char"
body="print(json.dumps(bridge(ROOT,raw_query(payload['sql'])+'report={pieces=[]};for(i=1;i<=q.recordCount;i++)arrayAppend(report.pieces,q.piece[i]);')))"
r=h.h.h.remote(body,{'sql':sql});raw=''.join(r['PIECES'] if 'PIECES'in r else r['pieces']);data=json.loads(raw)
(W/(sys.argv[1]+'-payload.json')).write_text(raw)
print(json.dumps({'bytes':len(raw.encode()),'series':len(data['series']),'comparisons':len(data['comparacoes']),'paired':data.get('meta',{}).get('comparativo_pareado')},ensure_ascii=False))
