from pathlib import Path
import json,re,hashlib
s=Path(__file__).resolve().parent;old=s.parent/'seo-date-ninth-20261004'
b=json.loads((s/'baseline-data.json').read_text());ids=','.join(map(str,json.loads((s/'selected-ids.json').read_text())))
facts={
37769:('2026-11-22',[5,10],'22 NOV; Circuito das Estações 2026 - Verão - Palmas; Palmas, TO; 5K, 10K','visible DOM in official Running Land event page'),
37784:('2026-11-07',[5,10],'7 NOV; Night Run - Etapa 1 - Fortaleza 2026; Fortaleza, CE; 5K, 10K','visible DOM in official Running Land event page'),
44234:('2026-11-08',[5,10],'8 NOV; Girl Power - Brasília 2026; Brasilia, DF; 5K, 10K','visible DOM in official Running Land event page'),
43093:('2026-10-17',[5],'ITAMARACÁ NIGHT RUN; Itamaracá - PE; 17/10/2026; 5 KM - CORRIDA; 5 KM - CAMINHADA; description repeats 17/10/2026 (SÁBADO)','visible DOM of TimeCrono, header and description agree'),
47496:('2026-10-31',[3],'Corrida nossa senhora aparecida trindad; 31 out - 2026 • 08:00 > 31 out - 2026 • 12:00; Trindade - GO; description: percurso 3km','visible Sympla event header and description'),
47013:('2026-10-25',[3,5],'CORRE POTIRETAMA SOLIDÁRIO; Potiretama - CE; 25/10/2026; 5KM; 3KM','visible Brazil Timing event header and categories; old URL identifies the same current event'),
46944:('2026-11-08',[5],'4ª EDIÇÃO IVIA EM AÇÃO; Campina Grande - PB; 08/11/2026; 5KM','visible SM Crono event header and categories'),
45435:('2026-11-08',[3],'ACIG EM MOVIMENTO – CAMINHADA PELA SAÚDE 3 KM; Garopaba - SC; 08/11/2026; 3KM','visible MaisSport header and categories; DOCX not used as date proof'),
46485:('2026-11-08',[6],'SEVEN RUNNING; Data: 08.NOV.2026; SANTA CRUZ DO CAPIBARIBE - PE; Categorias: 6km','visible Real Timing inscription source, no hotsite required'),
44160:('2026-11-29',[4],'DIA – 29/11/2026; PARQUE MADUREIRA; CORRIDA 4KM E CAMINHADA 4KM','official event metadata matches name/date/Parque Madureira; linked PDF first page visually reviewed'),
47442:('2026-11-29',[3,5],'FLUIR RUN; Data do evento: 29/11/2026 (Domingo); Cabo Frio; Corrida: 5km; Caminhada: 3km','official event metadata matches name/date/Cabo Frio; linked PDF first page visually reviewed')}
assert set(facts)==set(e['id_evento'] for e in b['events'])
changes={'events':{'37769':{'data_inicial':'2026-11-22','data_final':'2026-11-22'}},'routes':{}}
reviews=[]
for e in b['events']:
    eid=e['id_evento'];date,distances,excerpt,method=facts[eid]
    routes=[r for r in b['routes'] if r['id_evento']==eid]
    assert routes
    assert e['data_inicial']==e['data_final'],eid
    if eid!=37769:assert e['data_inicial']==date,eid
    else:assert e['data_inicial']=='2026-11-21' and not e['descricao'] and not e['descricao_en'] and not e['descricao_es']
    for r in routes:
        assert r['percurso_evento'] in distances and r['unidade_de_medida']=='km',(eid,r['id_evento_percurso'])
        assert r['data_percurso']!=date
        changes['routes'][str(r['id_evento_percurso'])]={'data_percurso':date,'percurso_bloqueado':True}
    proof={'id':eid,'date':date,'distances_km':distances,'source':e['url_hotsite'] or e['url_inscricao'],'regulation':e['url_regulamento'],'method':method,'excerpt':excerpt,'checked_date':'2026-10-04','fields':list(changes['events'].get(str(eid),{}))+['data_percurso','percurso_bloqueado'],'route_ids':[r['id_evento_percurso'] for r in routes]}
    if eid in [44160,47442]:proof['regulation_sha256']=hashlib.sha256((old/f'regulation-{eid}.pdf').read_bytes()).hexdigest()
    reviews.append(proof)
assert len(changes['routes'])==16
(s/'changes.json').write_text(json.dumps(changes,indent=2,ensure_ascii=False))
(s/'source-review.json').write_text(json.dumps({'selected':reviews,'excluded':[{'id':41938,'reason':'Official source now offers only 6 km; existing 5/10 km rows cannot be matched to this program without reconciliation.'},{'id':43239,'reason':'Regulation calls 21/11/2026 Sunday although that date is Saturday; keep unresolved until current source confirms.'},{'id':42042,'reason':'Regulation mentions 20–21 November; date allocation per program, especially Open Trail, still requires proof.'},{'id':45303,'reason':'Regulation header Caraguatatuba conflicts with body Taubaté; no unqualified identity/date correction.'}]},indent=2,ensure_ascii=False))
(s/'replacements.json').write_text('{}')
deps=json.loads((old/'dependencies.json').read_text())
tables=list(deps['dependencies'])
dep_sql='jsonb_build_object('+','.join("'"+t+"',(SELECT jsonb_build_object('count',count(*),'hash',md5(string_agg(md5(to_jsonb(d)::text),'' ORDER BY md5(to_jsonb(d)::text)))) FROM "+t+" d WHERE id_evento IN ("+','.join("'"+str(e['id_evento'])+"'" for e in b['events'])+"))" for t in tables)+')'
t=(old/'baseline.py').read_text();t=t[t.index('remote='):]
# Reuse the existing bridge transport, but read only the dependency aggregate.
template=(s/'baseline.py').read_text();prefix=template[:template.index('sql=')]
transport=template[template.index('remote='):template.index("r=json.loads(cp.stdout)")]
(s/'read_dependencies.py').write_text(prefix+'sql='+repr('SELECT '+dep_sql+'::text payload')+'\n'+transport+"r=json.loads(cp.stdout);(p/'dependencies.json').write_text(json.dumps({'dependencies':r},indent=2));print(json.dumps({'dependent_tables':len(r)}))\n")
code=(old/'correct_data.py').read_text().replace('39558,41364,42544,42847,44114,44134,44550,44804,45121,45208,45377,45484,46297,47432,48133',ids).replace('<>31','<>16').replace('seo-date-ninth-20261004','seo-date-tenth-20261004')
code=code.replace(" assert not patch['events'], 'This batch changes route dates only'",'')
needle=' for eid,fields in ev.items():out.append('
assert code.count(needle)==1
code=code.replace(needle," # Temporarily protect all corrected route IDs before event date triggers, also for inverse.\n for rid in rt:out.append(f'UPDATE tb_evento_corridas_percursos SET percurso_bloqueado=true WHERE id_evento_percurso={rid};')\n"+needle,1)
(s/'correct_data.py').write_text(code)
code=(s/'verify_public.py').read_text()
code=code.replace("  checks['metadata_expected']=m==expected","""  if str(c['id']) in changes['events']:
   patch=changes['events'][str(c['id'])];before=next(e for e in events if e['id_evento']==c['id'])
   def expected_dates(node):
    if isinstance(node,list):return [expected_dates(v) for v in node]
    if isinstance(node,dict):
     node={k:expected_dates(v) for k,v in node.items()}
     if node.get('@type') in ['Event','SportsEvent']:
      for key,field in [('startDate','data_inicial'),('endDate','data_final')]:
       if field in patch and key in node:
        assert node[key].startswith(before[field]),(key,node[key],before[field])
        node[key]=patch[field]+node[key][len(before[field]):]
     return node
    return node
   expected=expected_dates(expected)
  checks['metadata_expected']=m==expected""")
(s/'verify_public.py').write_text(code)
print(json.dumps({'events':11,'route_dates':16,'event_date_fields':2,'ids_preserved':16,'manual_protection':16}))
