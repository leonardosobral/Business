from inspect import remote,W
import json
body=r'''
checks=[('/estudos/primeiro-acesso/','GET',200),('/estudos/primeiro-acesso/api.cfm','GET',403),('/estudos/primeiro-acesso/api.cfm','POST',401),('/estudos/api.cfm','GET',403),('/estudos/api.cfm','POST',401),('/estudos/primeiro-acesso/primeiro-acesso.js','GET',200)]
result=[]
for path,method,want in checks:
 p=subprocess.run(['curl','-sS','--max-time','20','--resolve','business.roadrunners.run:443:127.0.0.1','-X',method,'-w','\n%{http_code}','https://business.roadrunners.run'+path],capture_output=True,text=True,timeout=25)
 assert p.returncode==0;data,status=p.stdout.rsplit('\n',1);assert int(status)==want,(path,status)
 if path=='/estudos/primeiro-acesso/':assert '50% na compra antecipada do anual.'in data
 result.append({'path':path,'method':method,'status':int(status)})
print(json.dumps(result))
'''
r=remote(body,{});(W/'http-qa.json').write_text(json.dumps(r,indent=2));print(r)
