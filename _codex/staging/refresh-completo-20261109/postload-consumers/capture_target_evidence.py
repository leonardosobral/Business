#!/usr/bin/env python3
"""Read frozen target evidence and recheck real production hashes; never executes cutover."""
import importlib.util
import json
from pathlib import Path
import uuid

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
RR=ROOT.parent/'RoadRunners'


def load(name,path):
    s=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m


SQL="""SELECT jsonb_build_object(
 'captured_at',clock_timestamp(),
 'publication',(SELECT jsonb_build_object('id',p.id,'run',p.run_id,'year',p.ano,'cell',r.cell_id,
   'contract_version',(p.payload->'meta'->>'contrato_versao')::integer,
   'payload_sha256',encode(sha256(convert_to(p.payload::text,'UTF8')),'hex'),
   'paired_run',(SELECT (f->>'execucao')::bigint FROM jsonb_array_elements(p.payload->'meta'->'notebook_fontes') f WHERE f->>'celula'='387'),
   'paired_revision',(SELECT (f->>'revisao')::integer FROM jsonb_array_elements(p.payload->'meta'->'notebook_fontes') f WHERE f->>'celula'='387'))
   FROM estudo.web_publicacoes p JOIN estudo.notebook_runs r ON r.id=p.run_id WHERE p.id=42 AND p.run_id=351),
 'validated_payload_sha256',encode(sha256(convert_to(estudo.web_payload_conferido(2026,351)::text,'UTF8')),'hex'),
 'active_references',(SELECT count(*) FROM estudo.web_destinos WHERE publicacao_id=42)+(SELECT count(*) FROM estudo.produtos WHERE publicacao_id=42),
 'runs',(SELECT jsonb_agg(jsonb_build_object('id',id,'cell',cell_id,'revision',cell_version,'frozen',frozen,'status',status,
   'truncated',truncated,'row_count',row_count,'payload_sha256',encode(sha256(convert_to((result->'rows'->0->'payload')::text,'UTF8')),'hex')) ORDER BY id)
   FROM estudo.notebook_runs WHERE id IN(329,351,352,353)),
 'annual_latest_run',(SELECT r.id FROM estudo.notebook_runs r JOIN estudo.notebook_cells c ON c.id=r.cell_id
   WHERE c.source_key='bqc-2026-anual-output' AND NOT c.archived AND r.frozen AND r.status='ok' AND NOT r.truncated
   AND r.row_count=1 AND r.result->'columns'='["payload"]'::jsonb AND jsonb_array_length(r.result->'rows')=1
   ORDER BY r.frozen_at DESC,r.id DESC LIMIT 1),
 'destinations',(SELECT jsonb_agg(to_jsonb(d) ORDER BY ano) FROM estudo.web_destinos d),
 'current_product',(SELECT jsonb_build_object('id',id,'publication',publicacao_id,'status',status) FROM estudo.produtos WHERE codigo='previa-2026-q3'),
 'previous_contract_version',(SELECT (payload->'meta'->>'contrato_versao')::integer FROM estudo.web_publicacoes WHERE id=41),
 'view_definition',pg_get_viewdef('estudo.lancamento_publico'::regclass,true),
 'public_payload',(SELECT result->'rows'->0->'payload' FROM estudo.notebook_runs WHERE id=352)
)::text AS payload"""

REMOTE=r'''
result=bridge(ROOT,raw_query(payload['sql'])+'report=deserializeJSON(q.payload[1]);')
roots={'business':ROOT,'portal':Path('/var/www/roadrunners.com.br')}
result['production_hashes']={}
for key in payload['files']:
 site,relative=key.split('/',1);result['production_hashes'][key]=digest((roots[site]/relative).read_bytes())
result['temporary_directories_left']=[str(p) for p in (ROOT/'_codex').glob(payload['prefix']+'*')]
if result['temporary_directories_left']:raise RuntimeError('Owned bridge cleanup incomplete')
print(json.dumps(result))
'''


def main():
    remote=load('target_read_operator',RR/'_codex/scripts/deploy_estudo_q3.py')
    helper=load('target_consumer_helper',HERE.parent/'consumer-cutover/consumer_cutover.py')
    baseline=json.loads((HERE/'baseline.json').read_text())
    prefix='consumer-target-read-'+uuid.uuid4().hex+'-'
    remote.HELPERS=remote.HELPERS.replace("prefix='error-triage-op-'","prefix='"+prefix+"'")
    result=remote.remote(REMOTE,{'sql':SQL,'files':helper.REQUIRED_FILES,'prefix':prefix})
    for key,record in baseline['files'].items():
        if result['production_hashes'][key]!=record['production_sha256'] or helper.sha(helper.path_for(key,ROOT,RR).read_bytes())!=record['local_sha256']:
            raise RuntimeError('Production/local drift before candidate generation: '+key)
    receipt=json.loads((HERE.parent/'postload/private-candidate-receipt.json').read_text())
    if result['publication']['payload_sha256']!=receipt['payload_sha256'] or result['validated_payload_sha256']!=receipt['payload_sha256']:
        raise RuntimeError('Private candidate/validator hash mismatch')
    if result['active_references']!=0 or result['current_product']['publication']!=41:
        raise RuntimeError('Active pointers moved unexpectedly')
    if result['view_definition']!=baseline['database']['view_definition']:raise RuntimeError('Public view changed')
    db=baseline['database'];dest={x['ano']:x for x in result['destinations']}
    if dest[2026]!={'ano':2026,'cell_id':251,'publicacao_id':41,'versao':22}:raise RuntimeError('2026 destination changed')
    if dest[2025]!={'ano':2025,'cell_id':249,'publicacao_id':37,'versao':19}:raise RuntimeError('2025 destination changed')
    db.update({'destination2026':dest[2026],'destination2025':dest[2025],'contract_version':result['previous_contract_version']})
    baseline['database_refreshed_at']=result['captured_at']
    ids={'publication_id':42,'publication_run':351,'public_run':352,'public_revision':7,
         'paired_run':329,'paired_revision':3,'annual_run':353,'annual_revision':3}
    evidence={k:result[k] for k in ['publication','runs','annual_latest_run']}
    helper.validate_inputs(baseline,ids,evidence,ROOT,RR)
    (HERE/'baseline.json').write_text(json.dumps(baseline,ensure_ascii=False,indent=2)+'\n')
    (HERE/'target-evidence.json').write_text(json.dumps(evidence,ensure_ascii=False,indent=2)+'\n')
    (HERE/'target-snapshot.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    (HERE/'ids-real.json').write_text(json.dumps(ids,indent=2)+'\n')
    print(json.dumps({'validated':True,'ids':ids,'contract_transition':[db['contract_version'],result['publication']['contract_version']],
                      'active_references':0,'unchanged_production_files':len(result['production_hashes']),
                      'private_hash':result['publication']['payload_sha256'],'temporary_directories_left':result['temporary_directories_left']},indent=2))


if __name__=='__main__':main()
