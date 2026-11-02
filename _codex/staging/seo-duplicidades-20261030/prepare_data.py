from pathlib import Path
import json,hashlib
S=Path(__file__).resolve().parent;b=json.loads((S/'before.json').read_text())
patch={'48501':{'ativo':False,'tag_301':'2027-corrida-adc-zf-clube'},'48554':{'ativo':False,'tag_301':'2026-corrida-e-caminhada-outubro-rosa-chupinguaia'}}
texts={49606:[
'A Corrida ADC ZF Clube está programada para 24 de janeiro de 2027, na Sede Campestre ADC ZF Clube, em Sorocaba (SP), com corridas de 4 km e 8 km e caminhada. A organização informa que a retirada de kits ainda será anunciada. Consulte a página oficial para horários, condições de inscrição e atualizações.',
'The ADC ZF Clube race is scheduled for January 24, 2027, at Sede Campestre ADC ZF Clube in Sorocaba, São Paulo, with 4 km and 8 km races and a walk. The organizer says race kit collection details will be announced. Check the official event page for times, registration conditions and updates.',
'La carrera ADC ZF Clube está programada para el 24 de enero de 2027, en la Sede Campestre ADC ZF Clube, en Sorocaba (SP), con carreras de 4 km y 8 km y caminata. La organización indica que la entrega de kits se anunciará. Consulte la página oficial para horarios, condiciones de inscripción y actualizaciones.'],48918:[
'A Corrida e Caminhada Outubro Rosa de Chupinguaia está programada para 31 de outubro de 2026, com largada às 6h em frente ao Sicredi, em Chupinguaia (RO), e percurso de 5 km, conforme a página oficial do Corre Chupinguaia na Sympla. Consulte a fonte para condições de participação e atualizações.',
'The Outubro Rosa Run and Walk in Chupinguaia is scheduled for October 31, 2026, starting at 6 a.m. in front of Sicredi in Chupinguaia, Rondônia, with a 5 km course, according to the official Corre Chupinguaia page on Sympla. Check the source for participation conditions and updates.',
'La Carrera y Caminata Outubro Rosa de Chupinguaia está programada para el 31 de octubre de 2026, con salida a las 6h frente a Sicredi, en Chupinguaia (RO), y recorrido de 5 km, según la página oficial de Corre Chupinguaia en Sympla. Consulte la fuente para condiciones de participación y actualizaciones.']}
for eid,ds in texts.items():
 meta={lang:{'source_hash':hashlib.md5(ds[0].encode()).hexdigest(),'description_hash':hashlib.md5(ds[i].encode()).hexdigest()} for i,lang in [(1,'en'),(2,'es')]}
 patch[str(eid)]={'descricao':ds[0],'descricao_en':ds[1],'descricao_es':ds[2],'descricao_traducoes_meta':meta}
for k,v in b['dependencies'].items():
 if any(x in k for x in ['resultados','calendario','conta','inscri','advertis','campaign','crm','foco_vinculos']):assert v['source_adc']==v['source_outubro']==0,(k,v)
(S/'decisions.json').write_text(json.dumps({'eventChanges':patch,'sources':[{'eventId':49606,'url':'https://www.ticketsports.com.br/e/CORRIDA+ADC+ZF+CLUBE-88536','file':'../seo-reaudit-20261030/official-adc.txt','confirmed':['24/01/2027','Sorocaba','4 km','8 km','kit a informar']},{'eventId':48918,'url':'https://www.sympla.com.br/evento/corrida-e-caminhada-outubro-rosa/3594186','file':'../seo-reaudit-20261030/official-outubro.txt','confirmed':['31/10/2026','06h','Sicredi','Chupinguaia','5 km']}],'eventDatesChanged':False,'coursesChanged':False,'duplicatePairs':[[48501,49606],[48554,48918]]},ensure_ascii=False,indent=2))
print(json.dumps({'duplicatePairs':2,'descriptions':2,'translatedDescriptions':4,'sourceCriticalDependencies':0,'datesChanged':False,'coursesChanged':False}))
