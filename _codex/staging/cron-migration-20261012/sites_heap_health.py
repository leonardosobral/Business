from datetime import datetime, timezone
import json, subprocess

out = {'measured_at_utc': datetime.now(timezone.utc).isoformat(), 'sites': []}
for host in ['roadrunners.run', 'runnerhub.run', 'conteudo.roadrunners.run', 'business.roadrunners.run']:
    for direct in [True, False]:
        cmd = ['curl', '-sS', '--max-time', '15', '--connect-timeout', '5', '-o', '/dev/null', '-w', '%{http_code} %{time_total}']
        if direct:
            cmd += ['--resolve', host + ':443:172.233.2.76']
        cmd += ['https://' + host + '/']
        result = subprocess.run(cmd, capture_output=True, text=True)
        out['sites'].append({'host': host, 'origin_direct': direct, 'result': result.stdout, 'rc': result.returncode})
result = subprocess.run(['curl', '-sS', '--max-time', '5', 'http://127.0.0.1/server-status?auto'], capture_output=True, text=True)
out['apache'] = [line for line in result.stdout.splitlines() if line.startswith(('BusyWorkers:', 'IdleWorkers:', 'ConnsTotal:'))]
print(json.dumps(out, indent=2))
