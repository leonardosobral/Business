#!/usr/bin/env python3
"""Execute only the two virtual-source SELECT projections in a read-only transaction.

No REQUEST identity, product mutation, destination/view cutover or endpoint write.
Raw JSON travels as base64 so PostgreSQL precision survives CF/Python transport.
"""
import base64
import importlib.util
import json
from pathlib import Path
import uuid

HERE=Path(__file__).resolve().parent
RR=HERE.parents[3].parent/'RoadRunners'


def main():
    p=RR/'_codex/scripts/deploy_estudo_q3.py'
    s=importlib.util.spec_from_file_location('delivery_read_operator',p);remote=importlib.util.module_from_spec(s);s.loader.exec_module(remote)
    prefix='consumer-delivery-read-'+uuid.uuid4().hex+'-'
    remote.HELPERS=remote.HELPERS.replace("prefix='error-triage-op-'","prefix='"+prefix+"'")
    queries={str(pub):(HERE/'delivery-qa'/f'compatible-publication-{pub}.sql').read_text() for pub in [41,42]}
    body=r'''
parts=["report={deliveries_base64={}};transaction {",raw_query('SET TRANSACTION READ ONLY')]
for pub,sql in payload['queries'].items():
 wrapped="WITH document AS MATERIALIZED ("+sql+") SELECT substring(payload FROM pos FOR 16000) AS payload FROM document CROSS JOIN LATERAL generate_series(1,char_length(payload),16000) AS pieces(pos) ORDER BY pos"
 parts.append(raw_query(wrapped))
 parts.append("pieces=[];for(j=1;j<=q.recordCount;j++)arrayAppend(pieces,q.payload[j]);report.deliveries_base64['"+pub+"']=toBase64(arrayToList(pieces,''),'UTF-8');")
parts.append('}')
result=bridge(ROOT,''.join(parts))
result['temporary_directories_left']=[str(p) for p in (ROOT/'_codex').glob(payload['prefix']+'*')]
if result['temporary_directories_left']:raise RuntimeError('Owned read bridge cleanup incomplete')
print(json.dumps(result))
'''
    result={key.lower():value for key,value in remote.remote(body,{'queries':queries,'prefix':prefix}).items()}
    report={}
    for pub,encoded in result['deliveries_base64'].items():
        raw=base64.b64decode(encoded);doc=json.loads(raw)
        meta=doc['meta']['comparativo_pareado']
        expected=(231,239) if pub=='41' else (329,352)
        if meta['status']!='disponivel' or (meta['execucao'],meta['narrativa']['execucao'])!=expected:
            raise RuntimeError('Publication/narrative pairing mismatch: '+pub)
        (HERE/'delivery-qa'/f'compatible-publication-{pub}.json').write_bytes(raw)
        report[pub]={'source':meta['execucao'],'narrative':meta['narrativa']['execucao'],
                     'pairs':meta['coorte']['pares'],'bytes':len(raw),'status':meta['status']}
    report.update({'database_read_only':True,'request_identity_created':False,
                   'temporary_directories_left':result['temporary_directories_left']})
    (HERE/'delivery-qa/capture-report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(report,ensure_ascii=False,indent=2))


if __name__=='__main__':main()
