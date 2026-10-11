from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import json,re,subprocess

stage=Path(__file__).resolve().parent
checks=[
 ('estado_ba','/estado/ba/',200,'Cidade: Todas as cidades'),
 ('feira','/estado/ba/?cidade=feira-de-santana',200,'Cidade: Feira de Santana'),
 ('salvador_maratonas','/estado/ba/?cidade=salvador&filtro=maratonas',200,'Cidade: Salvador'),
 ('feira_pagina2','/api/eventos_por_estado.cfm?tag=BA&cidade=feira-de-santana&page=1',200,'totalEventos = 73'),
 ('estado_invalido','/api/eventos_por_estado.cfm?tag=XX',404,'Estado não encontrado'),
 ('js','/assets/js/openresults-estado-cidades.js',200,'OpenResultsEstadoCities'),
 ('css','/assets/css/openresults-estado-cidades.css',200,'.estado-city-picker'),
 ('home','/',200,'Open Results')]

def verify(item):
 name,path,want,needle=item
 cp=subprocess.run(['curl','-sS','--max-time','25','-A','Mozilla/5.0','-w','\n%{http_code}','https://openresults.run'+path],capture_output=True,text=True,timeout=30)
 assert cp.returncode==0,(name,cp.stderr)
 body,status=cp.stdout.rsplit('\n',1)
 assert int(status)==want,(name,status)
 assert needle in body,(name,'missing marker')
 count=len(re.findall(r'href="/evento/',body))
 if name=='salvador_maratonas':assert count==7,count
 if name=='feira_pagina2':assert count==23,count
 return {'name':name,'url':'https://openresults.run'+path,'status':int(status),'event_cards':count}

with ThreadPoolExecutor(max_workers=3) as pool:results=list(pool.map(verify,checks))
(stage/'public-verify.json').write_text(json.dumps({'checks':results},ensure_ascii=False,indent=2))
print(json.dumps(results,ensure_ascii=False))
