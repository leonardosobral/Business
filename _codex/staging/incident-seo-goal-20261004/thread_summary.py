"""Read-only JVM/connector aggregates; never emit raw threads, URLs or queries."""
from pathlib import Path
import json,shlex,subprocess
code=r'''from pathlib import Path
import subprocess,json,re,collections,datetime,shutil
result={'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat()}
pids=[]
for folder in Path('/proc').iterdir():
 if folder.name.isdigit():
  try:
   name=(folder/'comm').read_text().strip()
   args=(folder/'cmdline').read_bytes().replace(b'\0',b' ').decode(errors='replace')
  except (OSError,PermissionError):continue
  if name=='java' and '/opt/ColdFusion/cfusion' in args:pids.append(int(folder.name))
result['coldfusion_pids']=pids
assert len(pids)==1,'Expected one ColdFusion JVM'
pid=pids[0];java=Path('/proc/'+str(pid)+'/exe').resolve()
jcmd=java.parent/'jcmd';jstack=java.parent/'jstack'
if not jcmd.exists():
 candidates=list(Path('/usr/lib/jvm').glob('*/bin/jcmd'))
 if shutil.which('jcmd'):candidates.insert(0,Path(shutil.which('jcmd')))
 if candidates:jcmd=candidates[0]
if not jcmd.exists() and not jstack.exists():
 print(json.dumps({'checked_at':result['checked_at'],'coldfusion_pids':pids,'thread_diagnostic':'unavailable: no installed JVM thread diagnostic command'}));raise SystemExit(0)
command=[str(jcmd),str(pid),'Thread.print'] if jcmd.exists() else [str(jstack),str(pid)]
cp=subprocess.run(command,capture_output=True,text=True,timeout=25)
assert cp.returncode==0,'JVM thread read failed'
blocks=re.split(r'(?m)^(?=")',cp.stdout)
states=collections.Counter();ajpstates=collections.Counter();tops=collections.Counter();slow=collections.Counter();active=0
for block in blocks:
 if not block.startswith('"'):continue
 st=re.search(r'java.lang.Thread.State:\s*([^\n]+)',block)
 state=st.group(1).split('(')[0].strip() if st else 'unavailable'
 states[state]+=1
 if not re.match(r'"(?:ajp|http|catalina-exec)',block,re.I):continue
 ajpstates[state]+=1
 methods=re.findall(r'^\s+at\s+([\w.$]+)\(',block,re.M)
 if methods:tops[methods[0]]+=1
 # Class/method names only: no thread names, source paths, arguments or SQL.
 if any(x.startswith(('coldfusion.tagext.sql.','org.postgresql.','coldfusion.sql.')) for x in methods):
  active+=1
  interesting=next((x for x in methods if x.startswith(('org.postgresql.','coldfusion.tagext.sql.','coldfusion.sql.'))),'unknown')
  slow[interesting]+=1
result.update(thread_states=dict(states),request_thread_states=dict(ajpstates),request_top_methods=dict(tops),request_threads_with_sql_stack=active,sql_stack_methods=dict(slow))
settings=[]
for root in [Path('/etc/apache2'),Path('/opt/ColdFusion/config/wsconfig')]:
 if not root.exists():continue
 for f in root.rglob('*'):
  if not f.is_file() or f.stat().st_size>1000000:continue
  try:text=f.read_text()
  except (OSError,UnicodeError):continue
  for line in text.splitlines():
   line=line.strip()
   if line.startswith('#'):continue
   if re.match(r'^(ServerLimit|MaxRequestWorkers|KeepAliveTimeout|Timeout|ProxyTimeout|ThreadsPerChild|StartServers|MinSpareThreads|MaxSpareThreads)\s+\d+',line):settings.append(line)
   elif re.match(r'^worker\.\w+\.(connection_pool_size|connection_pool_timeout|socket_timeout|reply_timeout|max_reuse_connections)=\d+',line):settings.append(re.sub(r'worker\.\w+\.', 'worker.<name>.',line))
result['numeric_connector_settings']=sorted(set(settings))
print(json.dumps(result))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=8','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(code)],capture_output=True,text=True,timeout=60)
if cp.returncode:raise RuntimeError(cp.stderr[-1500:])
r=json.loads(cp.stdout);Path(__file__).with_suffix('.json').write_text(json.dumps(r,indent=2))
print(json.dumps(r))
