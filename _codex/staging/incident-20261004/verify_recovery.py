import subprocess,json,concurrent.futures,sys
from pathlib import Path
from datetime import datetime,timezone
stage=Path(__file__).resolve().parent
urls=['https://business.roadrunners.run/portal/seo/','https://business.roadrunners.run/assets/css/business-ui.css','https://roadrunners.run/','https://openresults.run/']
def fetch(url):
 p=subprocess.run(['curl','-sS','--connect-timeout','6','--max-time','20','-o','/dev/null','-w','%{http_code} %{time_starttransfer} %{time_total}',url],capture_output=True,text=True,timeout=24)
 return {'url':url,'result':p.stdout,'error':p.stderr.strip(),'exit':p.returncode}
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as ex:results=list(ex.map(fetch,urls))
(stage/('public-'+sys.argv[1]+'.json')).write_text(json.dumps({'at':datetime.now(timezone.utc).isoformat(),'results':results},indent=2))
for r in results:print(json.dumps(r))
