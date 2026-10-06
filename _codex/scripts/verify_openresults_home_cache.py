from pathlib import Path
import subprocess,shlex,json
root=Path(__file__).resolve().parents[2]
remote=r'''
import subprocess,json,re
checks=[]
for host,path,origin in [('openresults.run','/',True),('openresults.run','/',False),('openresults.run','/',False),('openresults.run','/?rua=false&trail=true',False),('openresults.run','/estado/rj/',False),('openresults.run','/busca/?termo=maratona',False),('roadrunners.run','/',False)]:
 cmd=['curl','-sS','--max-time','25','-w','\nPROFILE %{http_code} %{time_starttransfer} %{time_total}','https://'+host+path]
 if origin:cmd[1:1]=['--resolve',host+':443:127.0.0.1']
 p=subprocess.run(cmd,capture_output=True,text=True,timeout=27)
 body,_,stats=p.stdout.rpartition('\nPROFILE ');fields=stats.split();title=re.search(r'<title>(.*?)</title>',body,re.S|re.I)
 r={'host':host,'path':path,'origin':origin,'status':fields[0] if fields else '', 'firstByte':fields[1] if len(fields)>1 else '', 'seconds':fields[2] if len(fields)>2 else '', 'title':title.group(1).strip() if title else '', 'bytes':len(body),'curl_error':p.stderr}
 if host=='openresults.run' and path=='/':r['has_city_data']='homeCity' in body or 'home-city' in body;r['has_result_counter']='resultados oficiais' in body
 checks.append(r)
status=subprocess.run(['curl','-sS','--max-time','5','http://127.0.0.1/server-status?auto'],capture_output=True,text=True).stdout
print(json.dumps({'checks':checks,'apache':[s for s in status.splitlines() if s.startswith(('BusyWorkers:','IdleWorkers:','Load1:'))]}));assert all(c['status']=='200' and not c['curl_error'] for c in checks)
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=190)
print(p.stdout);print(p.stderr[-1600:]);(root/'_codex/staging/openresults-home-cache-20261004/verification.json').write_text(p.stdout);raise SystemExit(p.returncode)
