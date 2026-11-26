"""Register a validated immutable candidate WITHOUT changing any active pointer.

Safer alternative to the rejected premature publish operation: this does not
call publicar_web and does not update web_destinos, produtos or any view. The
candidate is deliberately unreferenced until one later coordinated transaction.
"""
from pathlib import Path
import importlib.util
import json

W=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('private_candidate_reader',W.parent/'inspect.py')
reader=importlib.util.module_from_spec(spec);spec.loader.exec_module(reader)
cf=r'''
transaction {
 stateSql="SELECT jsonb_build_object('destinations',(SELECT jsonb_agg(to_jsonb(d) ORDER BY ano) FROM estudo.web_destinos d),'products',(SELECT jsonb_agg(jsonb_build_object('id',id,'publication',publicacao_id,'status',status) ORDER BY id) FROM estudo.produtos),'public_view',pg_get_viewdef('estudo.lancamento_publico'::regclass,true))::text AS state";
 before=queryExecute(stateSql,{},{datasource="runner_dba",timeout=10});
 locks=queryExecute("SELECT pg_advisory_xact_lock(9282026,6351)",{},{datasource="runner_dba",timeout=10});
 guard=queryExecute("SELECT d.publicacao_id=41 AND d.versao=22 AND p.publicacao_id=41 AS preserved FROM estudo.web_destinos d CROSS JOIN estudo.produtos p WHERE d.ano=2026 AND p.codigo='previa-2026-q3'",{},{datasource="runner_dba",timeout=10});
 if(guard.recordCount!=1 || !guard.preserved[1])throw(message="Active version changed; reread before registering a private candidate.");
 existing=queryExecute("SELECT id FROM estudo.web_publicacoes WHERE ano=2026 AND run_id=351",{},{datasource="runner_dba",timeout=10});
 if(existing.recordCount)throw(message="Candidate already registered; inspect rather than duplicate.");
 candidate=queryExecute("INSERT INTO estudo.web_publicacoes(ano,run_id,payload,nota,publicado_por) SELECT 2026,351,estudo.web_payload_conferido(2026,351),:note,139 RETURNING id,encode(sha256(convert_to(payload::text,'UTF8')),'hex') AS payload_hash",{note={value="CANDIDATO PRIVADO VALIDADO: renovação Jan–Set09/11, contrato18. Sem destinos/produto/view apontados; liberação depende do corte coordenado com os leitores e materiais.",cfsqltype="cf_sql_varchar"}},{datasource="runner_dba",timeout=30});
 after=queryExecute(stateSql,{},{datasource="runner_dba",timeout=10});
 if(compare(before.state[1],after.state[1])!=0)throw(message="An active pointer changed; rollback candidate registration.");
 refs=queryExecute("SELECT (SELECT count(*) FROM estudo.web_destinos WHERE publicacao_id=:id)+(SELECT count(*) FROM estudo.produtos WHERE publicacao_id=:id) AS n",{id={value=candidate.id[1],cfsqltype="cf_sql_bigint"}},{datasource="runner_dba",timeout=10});
 if(refs.n[1]!=0)throw(message="Candidate must remain unreferenced.");
 report={"candidate_id":toString(candidate.id[1]),"run_id":351,"payload_sha256":candidate.payload_hash[1],"active_references":0,"destinations_products_view_unchanged":true,"published":false,"active_state":deserializeJSON(after.state[1])};
}
'''
result=reader.h.h.remote("print(json.dumps(bridge(ROOT,payload['cf'])))",{'cf':cf})
(W/'private-candidate-receipt.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
print(json.dumps({k:v for k,v in result.items() if k!='active_state'},ensure_ascii=False))
