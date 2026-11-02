from pathlib import Path
import subprocess,hashlib,json,shlex
S=Path(__file__).resolve().parent
name='includes/aviso_resultados_pnc.cfm';target=Path('/Users/Shared/Projects/RunnerHub/OpenResults')/name
assert not target.exists(),'Preserve concurrent local dependency'
code="from pathlib import Path;import json,hashlib;p=Path('/var/www/openresults.run/includes/aviso_resultados_pnc.cfm');print(json.dumps({'text':p.read_text(),'sha':hashlib.sha256(p.read_bytes()).hexdigest()}))"
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(code)],capture_output=True,text=True,timeout=30)
assert cp.returncode==0,cp.stderr[-1000:]
data=json.loads(cp.stdout);assert hashlib.sha256(data['text'].encode()).hexdigest()==data['sha']
with target.open('x') as f:f.write(data['text'])
(S/'dependency-pnc.json').write_text(json.dumps({'path':name,'sha':data['sha'],'published':False,'source':'existing production dependency','localCopyOnly':True},indent=2)+'\n')
print('Existing production PNC dependency copied locally; no runtime publication.')
