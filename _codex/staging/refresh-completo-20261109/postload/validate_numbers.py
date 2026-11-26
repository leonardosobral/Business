"""Independent conservation checks over frozen source and assembled packages."""
from pathlib import Path
from decimal import Decimal
import json

W=Path(__file__).resolve().parent
def receipt(cell):return json.loads((W/'runs'/f'{cell}.json').read_text(),parse_float=Decimal)
def rows(cell):return receipt(cell)['data']['result']['rows']
def payload(cell):return rows(cell)[0]['payload']
def approx(a,b,tolerance=Decimal('0.00000001')):assert abs(Decimal(str(a))-Decimal(str(b)))<tolerance,(a,b)

g=payload(343);b=payload(347);months=payload(350)['mensais'];study=payload(251)
pair=payload(387);public=payload(420)['release'];audit=payload(413)
checks={}
assert g['resultados']==study['totais_atuais']['resultados']==audit['fato']['ids']==4574981
assert audit['fato']['ids']==audit['view_estudo']['ids']==audit['resultados_estudo']['ids']
assert audit['validacao']=={'sem_resultado':0,'divergencias':0}
checks['loaded_source_and_adapters_conserve_ids']=True
sex=[r for r in g['recortes'] if r['indicador']=='sexo']
assert sum(r['total'] for r in sex)==g['resultados']
for year,source in ((2025,b),(2026,g)):
    assert sum(r['concluintes_estudo'] for r in months if r['ano']==year)==source['resultados']
checks['gender_and_months_conserve_total']=True
pairs=json.loads((W/'pairs-full.json').read_text(),parse_float=Decimal)['pares']
assert len(pairs)==pair['coorte_pareada']['pares']==615
assert len({p['id_2025'] for p in pairs})==len({p['id_2026'] for p in pairs})==615
for year in (2025,2026):assert sum(p[f'concluintes_{year}'] for p in pairs)==pair['coorte_pareada'][f'concluintes_{year}']
rate=(Decimal(pair['coorte_pareada']['concluintes_2026'])/pair['coorte_pareada']['concluintes_2025']-1)*100
approx(rate,pair['coorte_pareada']['variacao_pct'],Decimal('1e-23'))
assert sum(p['metodo']=='vinculo_cadastrado' for p in pairs)==614
checks['paired_ids_counts_and_unrounded_rate']=True
calendar={year:sum(r['provas_cadastradas'] for r in months if r['ano']==year) for year in (2025,2026)}
assert calendar=={2025:5898,2026:8179}
approx((Decimal(calendar[2026])/calendar[2025]-1)*100,study['comparativo']['provas']['meses_completos']['variacao_cadastradas'])
assert Decimal(public['historias']['pareadas']['variacao_percentual'])==rate.quantize(Decimal('.1'))
assert Decimal(public['historias']['provas']['variacao_percentual'])==Decimal('38.7')
checks['public_compares_match_full_precision_sources']=True
f=next(s for s in sex if s['categoria']=='F')
short=next(s for s in g['recortes'] if s['indicador']=='distancia_faixas' and s['categoria']=='Até 5 km')
mill=next(r for r in rows(357) if r['bloco']=='geracao' and r['sexo']=='geral' and r['categoria']=='Millennials')
values={v['id']:Decimal(v['valor']) for v in public['indicadores']}
for name,r in [('femininas',f),('distancias_curtas',short),('millennials',mill)]:
    assert values[name]==Decimal(r['percentual']).quantize(Decimal('.1'))
third=sum(r['concluintes_estudo'] for r in months if r['ano']==2026 and r['mes']>=7)
assert values['terceiro_trimestre']==(Decimal(third)*100/g['resultados']).quantize(Decimal('.1'))
checks['public_gender_generation_distance_quarter']=True
assert study['meta']['contrato_versao']==18 and len(study['series'])==137
assert len({s['id'] for s in study['series']})==137
keys=[(c['serie'],c['categoria']) for c in study['comparacoes']]
assert len(set(keys))==len(keys)==846
assert study['meta']['bi_fonte_versionada']['relacao']=='estudo.fat_perfil_br_2026_20261109'
assert study['meta']['maratonas']['floripa']['execucao']==210
annual=payload(418)
assert annual['meta']['contrato_versao']==18
checks['contract_provenance_and_official_capture']=True
report={'checks':checks,'passed':len(checks),'total_2026':g['resultados'],'total_2025_q3':b['resultados'],
        'paired':pair['coorte_pareada'],'calendar':calendar,'public_indicators':values,'publication_pending':True}
(W/'numeric-validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2,default=str))
print(json.dumps({'checks_passed':len(checks),'paired_count':615,'paired_rate':str(rate),'calendar':calendar,'total':g['resultados']},ensure_ascii=False))
