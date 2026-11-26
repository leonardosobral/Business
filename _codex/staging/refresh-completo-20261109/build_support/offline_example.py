#!/usr/bin/env python3
"""Generate illustrative SQL using ONLY the October frozen fixtures.

These are historical examples, never a new collection or release candidate.
No database or network is contacted; full SQL numeric evaluation is not claimed.
"""
from pathlib import Path
import hashlib,json,sys
sys.path.insert(0,str(Path(__file__).resolve().parent))
from test_builder import b,fixtures,canonical_updates,TRIMESTRES,BI


def main():
    out=Path(__file__).resolve().parent/'old-fixture-example';out.mkdir(exist_ok=True)
    runs,baseline=fixtures()
    statements={str(c):b.build_derived(c,runs) for c in (380,377)}
    statements['387'],pairs=b.build_pairs(runs)
    statements['414']=b.build_themes(runs,baseline)
    statements['251']=b.build_final(runs)
    statements['420']=b.build_public(runs)
    statements['418']=b.build_annual(runs)
    for cell,sql in statements.items():(out/f'example-cell-{cell}.sql').write_text(sql+'\n')
    expected=json.loads((BI/'edicoes-q3.json').read_text())
    equation_match=canonical_updates(statements['414'])==canonical_updates((TRIMESTRES/'output-2026.sql').read_text())
    pair_match=pairs['pares']==expected['pares'] and pairs['coorte_pareada']==expected['coorte_pareada']
    assert equation_match and pair_match
    report={
        'historical_fixture_only':True,'network_used':False,'database_queries_executed':0,
        'claim':'Identical 105 SQL projection SELECT expressions, ignoring source labels; every 608 pair and exact cohort metric reproduced by Python.',
        'not_claimed':'Generated SQL has not been parsed or numerically evaluated by PostgreSQL; 2026 BI freshness is not verified.',
        'baseline_series':len(baseline['series']),'contract':baseline['meta']['contrato_versao'],
        'projection_equations_equal':equation_match,'matched_pairs_equal':pair_match,
        'cohort':pairs['coorte_pareada'],'matcher_sha256':pairs['matcher_sha256'],
        'preserved_evidence':list(b.PRESERVED_EVIDENCE),
        'files':{str(p.name):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(out.glob('*.sql'))},
    }
    (out/'verification.json').write_text(b.dumps(report,indent=2))
    print(b.dumps(report,indent=2))

if __name__=='__main__':main()
