#!/usr/bin/env python3
"""Verify only SELECT guard predicates extracted from the proposed cutover artifact.

The BEGIN/DO/UPDATE/CREATE/COMMIT proposal is never submitted or executed.
"""
import importlib.util
import json
from pathlib import Path
import re
import uuid

HERE=Path(__file__).resolve().parent
RR=HERE.parents[3].parent/'RoadRunners'


def main():
    proposal=(HERE/'CORTE_FINAL_PUB42_RUN352.sql').read_text()
    guard=re.search(r"IF NOT EXISTS\(\s*(SELECT 1 FROM estudo.web_publicacoes p\s+JOIN estudo.notebook_runs paired.*?)\s*\) THEN RAISE EXCEPTION 'Comparative rates or public release contract changed'",proposal,re.S)[1]
    if re.search(r'\b(UPDATE|INSERT|DELETE|CREATE|ALTER|DROP|COMMIT)\b',guard,re.I):raise ValueError('Guard extraction must contain SELECT only')
    sql="""SELECT jsonb_build_object(
 'rates_and_public_contract',EXISTS("""+guard+"""),
 'destination2026',EXISTS(SELECT 1 FROM estudo.web_destinos WHERE ano=2026 AND cell_id=251 AND publicacao_id=41 AND versao=22),
 'destination2025',EXISTS(SELECT 1 FROM estudo.web_destinos WHERE ano=2025 AND cell_id=249 AND publicacao_id=37 AND versao=19),
 'candidate_contract18',EXISTS(SELECT 1 FROM estudo.web_publicacoes WHERE id=42 AND run_id=351 AND payload->'meta'->>'contrato_versao'='18'),
 'candidate_active_references',(SELECT count(*) FROM estudo.web_destinos WHERE publicacao_id=42)+(SELECT count(*) FROM estudo.produtos WHERE publicacao_id=42),
 'old_public_view',encode(sha256(convert_to(pg_get_viewdef('estudo.lancamento_publico'::regclass,true),'UTF8')),'hex')='ee05be7bd4b56685eb01cd0e9c7fcc3a4a0f54fc8a80604e59b52717157252e4'
)::text AS payload"""
    (HERE/'delivery-qa/atomic-preflight.readonly.sql').write_text(sql)
    s=importlib.util.spec_from_file_location('atomic_guard_reader',RR/'_codex/scripts/deploy_estudo_q3.py');m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
    prefix='consumer-atomic-read-'+uuid.uuid4().hex+'-'
    m.HELPERS=m.HELPERS.replace("prefix='error-triage-op-'","prefix='"+prefix+"'")
    body="""result=bridge(ROOT,'transaction {'+raw_query('SET TRANSACTION READ ONLY')+raw_query(payload['sql'])+'report=deserializeJSON(q.payload[1]);}')
result['temporary_directories_left']=[str(p) for p in (ROOT/'_codex').glob(payload['prefix']+'*')]
print(json.dumps(result))"""
    result=m.remote(body,{'sql':sql,'prefix':prefix})
    if result['candidate_active_references']!=0 or result['temporary_directories_left'] or not all(result[k] is True for k in ['rates_and_public_contract','destination2026','destination2025','candidate_contract18','old_public_view']):
        raise RuntimeError('Atomic SELECT preflight failed: '+json.dumps(result))
    result.update({'proposal_executed':False,'read_only_transaction':True})
    (HERE/'delivery-qa/atomic-preflight.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2))


if __name__=='__main__':main()
