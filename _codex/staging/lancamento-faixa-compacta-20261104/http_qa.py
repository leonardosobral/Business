from inspect import remote,W
import json
body=r'''
items=[('/estudos/lancamento/','GET',401),('/estudos/lancamento/checklist.cfm','GET',405),('/estudos/lancamento/checklist.cfm','POST',401),('/estudos/lancamento/checklist.js','GET',200),('/estudos/lancamento/lancamento.css','GET',200)]
results=[]
for path,method,status in items:
 p=subprocess.run(['curl','-sS','--max-time','20','--resolve','business.roadrunners.run:443:127.0.0.1','-X',method,'-w','\n%{http_code}','https://business.roadrunners.run'+path],capture_output=True,timeout=25)
 assert p.returncode==0,path
 data,raw=p.stdout.rsplit(b'\n',1);actual=int(raw)
 assert actual==status,(path,actual,status)
 results.append({'path':path,'method':method,'status':actual})
print(json.dumps({'anonymous_and_method_guards':results}))
'''
r=remote(body,{});(W/'http-qa.json').write_text(json.dumps(r,indent=2));print(r)
