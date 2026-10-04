"""Existing shared logs: aggregate bot declarations without assigning them to a site."""
from pathlib import Path
import json,shlex,subprocess
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business');STAGE=Path(__file__).resolve().parent
module=(ROOT/'_codex/scripts/seo_live_evidence.py').read_text().split("if __name__ == '__main__':")[0]
remote=module+r'''
import sys
payload=json.load(sys.stdin)
paths=[Path('/var/log/apache2/access.log'),Path('/var/log/apache2/access.log.1')]+[Path('/var/log/apache2/access.log.'+str(n)+'.gz') for n in range(2,9)]
paths=[p for p in paths if p.is_file()]
since=datetime.datetime.fromisoformat(payload['since'])
report=summarize_logs(paths,payload['ranges'],since)
report['measured_at']=datetime.datetime.now(datetime.timezone.utc).isoformat();report['since']=payload['since']
report['vhosts']={}
for name in ['roadrunners.run','openresults.run']:
 text=Path('/etc/apache2/sites-enabled/'+name+'-le-ssl.conf').read_text()
 report['vhosts'][name]={'shared_combined_log':bool(re.search(r'CustomLog\s+\$\{APACHE_LOG_DIR\}/access[.]log\s+combined',text)), 'remote_ip_header':bool(re.search(r'RemoteIPHeader\s+CF-Connecting-IP',text)), 'trusted_proxy_directives':len(re.findall(r'^\s*RemoteIPTrustedProxy\s+',text,re.M))}
report['vhost_log_bytes']=Path('/var/log/apache2/other_vhosts_access.log').stat().st_size
print(json.dumps(report))
'''
ranges=json.loads((STAGE/'ranges.json').read_text())
payload={'ranges':ranges['ranges'],'since':'2026-09-26T22:00:00+00:00'}
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=180)
if cp.returncode:raise RuntimeError(cp.stderr[-2000:])
result=json.loads(cp.stdout);(STAGE/'logs.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result))
