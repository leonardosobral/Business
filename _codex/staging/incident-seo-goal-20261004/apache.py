import subprocess,json,shlex
from pathlib import Path
code=r'''from pathlib import Path
import subprocess,json,re,collections
for label,cmd in [('listeners',['ss','-lnt']),('apache_modules',['apache2ctl','-M']),('apache_runtime',['apache2ctl','-t','-D','DUMP_RUN_CFG'])]:
 p=subprocess.run(cmd,capture_output=True,text=True,timeout=10);out=p.stdout+p.stderr
 if label=='apache_modules':out='\n'.join(l for l in out.splitlines() if any(x in l.lower() for x in ['mpm','jk','proxy','status']))
 print(json.dumps({'check':label,'output':out}),flush=True)
p=subprocess.run(['ss','-Hant'],capture_output=True,text=True,timeout=10)
c=collections.Counter()
for l in p.stdout.splitlines():
 a=l.split()
 if len(a)>4:c[(a[0],a[3].rsplit(':',1)[-1],a[4].rsplit(':',1)[-1])]+=1
print(json.dumps({'socket_state_port_counts':[[*k,v] for k,v in c.most_common(20)]}),flush=True)
for name in ['/var/log/apache2/error.log','/var/log/apache2/mod_jk.log']:
 f=Path(name)
 if not f.exists():continue
 with f.open('rb') as h:h.seek(max(0,f.stat().st_size-180000));data=h.read().decode(errors='replace')
 codes=collections.Counter(re.findall(r'AH\d+: [^\n]*',data))
 safe=[]
 for line in data.splitlines():
  if any(w in line.lower() for w in ['maxrequestworkers','scoreboard','serverlimit','too many open files','no space left','all tomcat instances','failed to obtain','connection pool','connecting to tomcat failed']):safe.append(re.sub(r'\[client[^\]]*\]','[client redacted]',line)[:450])
 print(json.dumps({'log':name,'size':f.stat().st_size,'mtime':f.stat().st_mtime,'codes':collections.Counter(re.findall(r'AH\d+',data)),'selected':safe[-12:]}),flush=True)
for f in Path('/etc/apache2/mods-enabled').glob('mpm*.conf'):
 print(json.dumps({'config':str(f),'settings':[l.strip() for l in f.read_text().splitlines() if re.match(r'\s*(ServerLimit|ThreadLimit|ThreadsPerChild|MaxRequestWorkers|MaxConnectionsPerChild|StartServers|MinSpareThreads|MaxSpareThreads)',l)]}),flush=True)
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=8','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(code)],text=True,capture_output=True,timeout=60)
print(p.stdout);print(p.stderr);Path(__file__).with_suffix('.jsonl').write_text(p.stdout)
