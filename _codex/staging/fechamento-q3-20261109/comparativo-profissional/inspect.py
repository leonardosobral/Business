from pathlib import Path
import importlib.util,json,base64,hashlib

ROOT=Path(__file__).resolve().parents[4]
W=Path(__file__).resolve().parent
s=importlib.util.spec_from_file_location('inspection',W.parent/'inspect_current.py')
h=importlib.util.module_from_spec(s);s.loader.exec_module(h)

def query(sql):
    return h.h.remote("print(json.dumps(bridge(ROOT,raw_query(payload['sql'])+'report=deserializeJSON(q.payload[1]);')))",{'sql':sql})

if __name__=='__main__':
    files=['estudos/leitor/parcial.js','estudos/leitor/estudo.js','estudos/leitor/estudo.css','estudos/includes/StudyAccess.cfc']
    result=h.h.remote("result={}\nfor name in payload['files']:\n data=(ROOT/name).read_bytes();result[name]={'sha256':digest(data),'content':base64.b64encode(data).decode()}\nprint(json.dumps(result))",{'files':files})
    report={}
    for name,v in result.items():
        data=base64.b64decode(v['content']);p=W/'baseline'/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
        local=(ROOT/name).read_bytes();p=W/'local-before'/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(local)
        report[name]={'production_sha256':v['sha256'],'local_sha256':hashlib.sha256(local).hexdigest(),'matches':data==local}
    (W/'baseline.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
    sql="""SELECT jsonb_build_object(
      'publication_meta',(SELECT w.payload->'meta' FROM estudo.produtos p JOIN estudo.web_publicacoes w ON w.id=p.publicacao_id WHERE p.codigo='previa-2026-q3'),
      'comparison_keys',(SELECT jsonb_agg(k) FROM estudo.produtos p JOIN estudo.web_publicacoes w ON w.id=p.publicacao_id CROSS JOIN LATERAL jsonb_object_keys(w.payload->'comparativo') k WHERE p.codigo='previa-2026-q3'),
      'run_columns',(SELECT jsonb_agg(column_name) FROM information_schema.columns WHERE table_schema='estudo' AND table_name='notebook_runs'),
      'public_definition',pg_get_viewdef('estudo.lancamento_publico'::regclass,true),
      'public_columns',(SELECT jsonb_agg(column_name) FROM information_schema.columns WHERE table_schema='estudo' AND table_name='lancamento_publico'))::text AS payload"""
    r=query(sql);(W/'metadata.json').write_text(json.dumps(r,ensure_ascii=False,indent=2));print(json.dumps(r,ensure_ascii=False))
