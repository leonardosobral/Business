from pathlib import Path
import csv,hashlib,json
W=Path(__file__).resolve().parent;B=W.parents[3];D=json.loads((W/'data.json').read_text());dest=W/'runtime/business/estudos/lancamento/arquivos'
checks={}
for year in ('2025','2026'):
 name=f'maratonas-selecao-{year}.csv';rows=list(csv.DictReader((dest/name).open(encoding='utf-8-sig')))
 actual={int(r['id_evento']):r for r in rows};expected={r['id_evento']:r for r in D['years'][year]['selection']};assert actual.keys()==expected.keys()
 for i,r in expected.items():
  for field in actual[i]:assert actual[i][field]==(''if r.get(field)is None else str(r.get(field))), (name,i,field)
 checks[name]=len(rows)
rows=list(csv.DictReader((dest/'maratonas-pares-2025-2026.csv').open(encoding='utf-8-sig')));assert len(rows)==len(D['pairs']['pares']);assert sum(int(r['n2025'])for r in rows)==D['pairs']['coorte']['n2025'];assert sum(int(r['n2026'])for r in rows)==D['pairs']['coorte']['n2026'];checks['pairs']=len(rows)
rows=list(csv.DictReader((dest/'maratonas-indicadores-completos.csv').open(encoding='utf-8-sig'),delimiter=';'));assert len(rows)==sum(len(s['values'])for Y in D['years'].values()for s in Y['series']);checks['indicators']=len(rows)
rows=list(csv.DictReader((dest/'maratonas-auditoria-idades.csv').open(encoding='utf-8-sig'),delimiter=';'));assert len(rows)==sum(len(a['provas'])for a in D['age_audit'].values())
for year,A in D['age_audit'].items():
 actual=[r for r in rows if r['ano']==year];assert sum(int(r['total'])for r in actual)==A['totals']['total'];assert {int(r['congelamento'])for r in actual}=={A['run_id']}
checks['age_audit']=len(rows)
assert not list((W/'runtime').rglob('*.pdf'))
for name in ('maratonas.cfm','maratonas-detalhado.js'):
 original=W/'baseline'/name;current=B/'estudos/lancamento'/name;assert original.read_bytes()==current.read_bytes(),'Runtime modified outside candidate'
report={'csv_roundtrip_counts_and_nulls':True,'files':checks,'no_pdfs_generated':True,'canonical_runtime_unchanged':True}
(W/'csv-validation.json').write_text(json.dumps(report,indent=2));print(json.dumps(report))
