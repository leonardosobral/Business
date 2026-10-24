from pathlib import Path
import json,shlex,subprocess
S=Path(__file__).resolve().parent
remote=r'''
import json,subprocess,xml.etree.ElementTree as ET
path='/sitemaps/events-upcoming-1.xml'
cp=subprocess.run(['curl','-sS','--fail-with-body','--max-time','45','--resolve','roadrunners.run:443:127.0.0.1','https://roadrunners.run'+path],capture_output=True,text=True,timeout=50)
assert cp.returncode==0,cp.stderr[-500:]
root=ET.fromstring(cp.stdout);urls=[e.text for e in root.findall('.//{http://www.sitemaps.org/schemas/sitemap/0.9}loc')]
original=[u for u in urls if '/2026-corrida-das-cores-da-amazonia/' in u]
alias=[u for u in urls if '/2027-corrida-das-cores-da-amazonia/' in u]
assert len(original)==3 and not alias,dict(original=original,alias=alias)
print(json.dumps(dict(sitemap=path,valid_xml=True,original_languages=len(original),redirect_urls=len(alias),urls=len(urls))))
'''
ssh=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run']
cp=subprocess.run(ssh+['python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=65);assert cp.returncode==0,cp.stderr[-2000:]
r=json.loads(cp.stdout);(S/'amazonia-sitemap-verified.json').write_text(json.dumps(r,indent=2));print(json.dumps(r))
