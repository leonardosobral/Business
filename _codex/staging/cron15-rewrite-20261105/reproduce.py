import pathlib,re,json,hmac,hashlib,datetime,urllib.request,urllib.error
root=pathlib.Path('/var/www/business.roadrunners.run')
secret=''
for line in (root/'config/business.local.cfm').read_text().splitlines():
 m=re.match(r'\s*"?business_internal"?\s*[:=]\s*"(.*)"\s*,?\s*$',line)
 if m:secret=m.group(1).replace('""','"')
if not secret:raise SystemExit('No configured Business secret found; nothing executed')
body=b'{"limit":3,"dryRun":false}'
from zoneinfo import ZoneInfo
ts=datetime.datetime.now(ZoneInfo('America/Sao_Paulo')).strftime('%Y-%m-%d %H:%M:%S')
sig=hmac.new(secret.encode(),ts.encode()+b'.'+body,hashlib.sha256).hexdigest()
import subprocess
run=subprocess.run(['curl','-sS','--max-time','180','--resolve','business.roadrunners.run:443:127.0.0.1','--user-agent','RoadRunners-Business-Cron/1.0','--header','Content-Type: application/json','--header','X-RR-Handoff-Timestamp: '+ts,'--header','X-RR-Handoff-Signature: '+sig,'--data-binary',body.decode(),'--write-out','\n%{http_code}','https://business.roadrunners.run/api/event-description-rewrite.cfm'],capture_output=True,timeout=185)
raw,_,code=run.stdout.decode('utf-8-sig').rpartition('\n')
print(json.dumps({'http':code,'response':json.loads(raw) if raw.lstrip().startswith('{') else raw[:2000]},ensure_ascii=False))
