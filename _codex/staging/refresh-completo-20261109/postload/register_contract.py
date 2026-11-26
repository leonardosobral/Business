"""Add contract18 from the reviewed aggregate payload; never alter contract17."""
from pathlib import Path
import base64
import hashlib
import importlib.util
import json

W=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('contract_registration_reader',W.parent/'inspect.py')
reader=importlib.util.module_from_spec(spec);spec.loader.exec_module(reader)

def combine(a,b):
    out={'types':sorted(set(a['types'])|set(b['types']))}
    if 'object' in out['types']:
        aa=a.get('keys',{});bb=b.get('keys',{})
        out['keys']={k:combine(aa[k],bb[k]) if k in aa and k in bb else aa.get(k,bb.get(k)) for k in sorted(set(aa)|set(bb))}
        if 'object' in a['types'] and 'object' in b['types']:
            out['required']=sorted(set(a.get('required',[]))&set(b.get('required',[])))
        else:out['required']=a.get('required',b.get('required',[]))
    if 'array' in out['types']:
        out['items']=combine(a['items'],b['items']) if 'items' in a and 'items' in b else a.get('items',b.get('items',{'types':['null']}))
    return out

def shape(v):
    if v is None:return {'types':['null']}
    if isinstance(v,bool):return {'types':['boolean']}
    if isinstance(v,(float,int)):return {'types':['number']}
    if isinstance(v,str):
        assert len(v)<=10000
        return {'types':['string']}
    if isinstance(v,list):
        assert len(v)<=2000
        result=None
        for x in v:result=shape(x) if result is None else combine(result,shape(x))
        return {'types':['array'],'items':result or {'types':['null']}}
    if isinstance(v,dict):
        assert not set(v)&{'email','cpf','data_nascimento','id_usuario','id_atleta_strava'},'Personal-data key in aggregate package'
        return {'types':['object'],'keys':{k:shape(x) for k,x in sorted(v.items())},'required':sorted(v)}
    raise TypeError(type(v))

if __name__=='__main__':
    payload=json.loads((W/'runs/251.json').read_text())['data']['result']['rows'][0]['payload']
    assert payload['meta']['contrato_versao']==17
    payload['meta']['contrato_versao']=18
    schema=shape(payload)
    (W/'contract18-schema.json').write_text(json.dumps(schema,ensure_ascii=False,indent=2))
    cfg={'schema':schema,'run':345,'cell_version':41}
    encoded=base64.b64encode(json.dumps(cfg,ensure_ascii=False).encode()).decode()
    cf='cfg=deserializeJSON(toString(binaryDecode("'+encoded+'","base64")));transaction {'
    cf+='before=queryExecute("SELECT encode(sha256(convert_to(payload::text,\'UTF8\')),\'hex\') AS hash FROM estudo.web_base_versoes WHERE ano=2026 AND versao=17",{},{datasource="runner_dba",timeout=10});'
    cf+='queryExecute("SELECT pg_advisory_xact_lock(9282026,618)",{},{datasource="runner_dba",timeout=10});'
    cf+='existing=queryExecute("SELECT versao FROM estudo.web_base_versoes WHERE ano=2026 AND versao=18",{},{datasource="runner_dba",timeout=10});if(existing.recordCount)throw(message="Contrato18 já existe; reler antes de registrar.");'
    cf+='q=queryExecute("INSERT INTO estudo.web_base_versoes(ano,versao,payload,contrato) SELECT 2026,18,jsonb_set(result->\'rows\'->0->\'payload\',\'{meta,contrato_versao}\',\'18\'::jsonb),CAST(:schema AS jsonb) FROM estudo.notebook_runs WHERE id=:run AND cell_id=251 AND cell_version=:revision AND frozen AND status=\'ok\' AND NOT truncated AND row_count=1 RETURNING versao",{schema={value=serializeJSON(cfg.schema),cfsqltype="cf_sql_longvarchar"},run={value=cfg.run,cfsqltype="cf_sql_bigint"},revision={value=cfg.cell_version,cfsqltype="cf_sql_integer"}},{datasource="runner_dba",timeout=10});if(q.recordCount!=1)throw(message="Fonte do contrato ausente.");'
    cf+='check=queryExecute("SELECT estudo.web_json_valido(payload,contrato) AS valid,encode(sha256(convert_to(payload::text,\'UTF8\')),\'hex\') AS hash FROM estudo.web_base_versoes WHERE ano=2026 AND versao=18",{},{datasource="runner_dba",timeout=30});if(!check.valid[1])throw(message="Contrato gerado não valida o pacote revisado.");'
    cf+='old=queryExecute("SELECT encode(sha256(convert_to(payload::text,\'UTF8\')),\'hex\') AS hash FROM estudo.web_base_versoes WHERE ano=2026 AND versao=17",{},{datasource="runner_dba",timeout=10});if(old.hash[1]!=before.hash[1])throw(message="Contrato anterior alterado.");'
    cf+='report={"registered":18,"previous_contract_preserved":true,"valid":true,"payload_hash":check.hash[1],"baseline17_hash":before.hash[1]};}'
    result=reader.h.h.remote("print(json.dumps(bridge(ROOT,payload['cf'])))",{'cf':cf})
    (W/'contract18-receipt.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
    print(json.dumps(result,ensure_ascii=False))
