from pathlib import Path
from html import unescape
import json,urllib.request
S=Path(__file__).resolve().parent
cases=[('/en/event/2027-corrida-adc-zf-clube/','The ADC ZF Clube race is scheduled for January 24, 2027'),('/es/evento/2027-corrida-adc-zf-clube/','La carrera ADC ZF Clube está programada para el 24 de enero de 2027'),('/en/event/2026-corrida-e-caminhada-outubro-rosa-chupinguaia/','The Outubro Rosa Run and Walk in Chupinguaia is scheduled for October 31, 2026'),('/es/evento/2026-corrida-e-caminhada-outubro-rosa-chupinguaia/','La Carrera y Caminata Outubro Rosa de Chupinguaia está programada para el 31 de octubre de 2026')]
for path,text in cases:
 with urllib.request.urlopen(urllib.request.Request('https://roadrunners.run'+path,headers={'User-Agent':'RunnerHub-SEO-Validation/1.0'}),timeout=35) as r:
  assert r.status==200 and text in unescape(r.read().decode()),path
(S/'translations-verified.json').write_text(json.dumps({'checks':len(cases),'passed':True})+'\n');print('4 public translations verified')
