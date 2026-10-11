from pathlib import Path
import json,hashlib
p=Path(__file__).resolve().parent;old=p.parent/'seo-date-eleventh-20261004';b=json.loads((p/'baseline-data.json').read_text());e=next(e for e in b['events'] if e['id_evento']==39399)
texts={
'descricao':'A edição de 2026 da Maratona de Aracaju reúne provas em 31 de outubro e 1º de novembro, em Aracaju, Sergipe. A programação de 31 de outubro inclui 10 km e 21 km. Em 1º de novembro, estão previstas as provas de 5 km e maratona de 42,195 km.\n\nO local informado pela organização é a Praça de Eventos da Orla, na Avenida Santos Dumont. Consulte a página oficial e o regulamento para horários, retirada de kits e condições de participação.',
'descricao_en':'The 2026 edition of the Aracaju Marathon has races on October 31 and November 1 in Aracaju, Sergipe, Brazil. The October 31 program includes the 10 km and 21 km races. The 5 km race and the 42.195 km marathon are scheduled for November 1.\n\nThe organizer lists Praça de Eventos da Orla on Avenida Santos Dumont as the venue. Check the official event page and regulations for start times, race kit collection and participation requirements.',
'descricao_es':'La edición de 2026 de la Maratón de Aracaju tiene pruebas el 31 de octubre y el 1 de noviembre en Aracaju, Sergipe, Brasil. El programa del 31 de octubre incluye las carreras de 10 km y 21 km. Para el 1 de noviembre están previstas la carrera de 5 km y la maratón de 42,195 km.\n\nLa organización indica la Praça de Eventos da Orla, en la Avenida Santos Dumont, como lugar del evento. Consulta la página oficial y el reglamento para conocer los horarios, la recogida de kits y las condiciones de participación.'}
meta=dict(e['descricao_traducoes_meta'] or {})
for lang in ['en','es']:meta[lang]={'source_hash':hashlib.md5(texts['descricao'].encode()).hexdigest(),'description_hash':hashlib.md5(texts['descricao_'+lang].encode()).hexdigest()}
patch=texts|{'descricao_traducoes_meta':meta};(p/'changes.json').write_text(json.dumps({'events':{'39399':patch},'routes':{}},ensure_ascii=False,indent=2))
ids='37483,33486,39399';oids=','.join(map(str,json.loads((old/'selected-ids.json').read_text())))
(p/'correct_data.py').write_text((old/'correct_data.py').read_text().replace(oids,ids).replace('<>30','<>8').replace('seo-date-eleventh-20261004','seo-keyword-locales-20261004'))
(p/'dependencies.json').write_text((old/'dependencies.json').read_text());(p/'replacements.json').write_text('{}')
s=(old/'verify_public.py').read_text();needle="  checks['metadata_expected']=m==expected";assert s.count(needle)==1
s=s.replace(needle,needle+'''\n  if str(c['id']) in changes['events'] and 'descricao' in changes['events'][str(c['id'])]:
   patch=changes['events'][str(c['id'])];key='descricao' if c['lang']=='pt-br' else 'descricao_'+c['lang']
   visible=html.unescape(re.sub(r'<[^>]*>',' ',h));normalize=lambda t:re.sub(r'\\s+',' ',t).strip()
   for n,paragraph in enumerate(patch[key].split('\\n\\n')):checks['localized_paragraph_'+str(n)]=normalize(paragraph) in normalize(visible)
   checks['no_old_empty_heading']='DISTÂNCIAS:' not in visible and 'DISTANCIAS:' not in visible
''')
(p/'verify_public.py').write_text(s)
(p/'source-review.json').write_text(json.dumps({'checked_date':'2026-10-04','aracaju':{'source':e['url_hotsite'],'regulation':e['url_regulamento'],'source_program':{'2026-10-31':[10,21],'2026-11-01':[5,42.195]},'venue':'Praça de Eventos da Orla, Avenida Santos Dumont','method':'current visible official TicketSports DOM and current PDF previously reviewed','regulation_sha256':hashlib.sha256((p.parent/'seo-upcoming-second-20261004/39399-current.pdf').read_bytes()).hexdigest(),'not_changed':['start times with conflicting sources','availability state','dates','course IDs or distances','original source description','registration links'],'text_policy':'own factual summary and manual EN/ES translation; no paid provider call'},'other_opportunities':{'37483':'EN/ES translations already tracked against exact PT hash; current primary source confirms date,city,5/10 and Kids','33486':'EN/ES translations present; historical2026 edition preserved when official old URL redirects to new2027 edition'}},ensure_ascii=False,indent=2))
print(json.dumps({'changed_events':1,'description_fields':3,'metadata_fields':1,'routes_preserved':8,'paid_ai_calls':0}))
