from pathlib import Path
import subprocess,json,hashlib,re
S=Path(__file__).resolve().parent
checks={}
for name,url in [('pace','https://roadrunners.run/calculadora-de-pace/'),('source','https://roadrunners.run/assets/js/runnerhub-pace.js?v=20261025measure'),('min','https://roadrunners.run/assets/js/runnerhub-pace.min.js?v=20261025measure'),('direct_baseline','https://business.roadrunners.run/portal/conteudo/seo_growth_baseline.cfm'),('anonymous_panel','https://business.roadrunners.run/portal/seo/?aba=ga4&site=roadrunners')]:
 cp=subprocess.run(['curl','-sS','-A','Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36','--max-time','40','-w','\n%{http_code}',url],capture_output=True,timeout=45);body,status=cp.stdout.rsplit(b'\n',1);status=int(status);checks[name]={'status':status}
 if name in ('source','min'):
  f=S/'candidate/RoadRunners/assets/js'/('runnerhub-pace.'+('js' if name=='source' else 'min.js'));assert body==f.read_bytes();checks[name]['hash_matches']=True
 elif name=='pace':
  assert b'20261025measure' in body and b'data-pace-form' in body and b'Error Occurred' not in body
  m=re.search(rb'window.RoadRunnersAudienceConfig=(\{.*?\});</script>',body)
  assert m,'No anonymous measurement context';c=json.loads(m[1])['context'];checks[name]['context']={k:c[k] for k in ['environment','isInternal']};assert c['environment']=='prod' and c['isInternal'] is False
 else:assert b'316 cliques' not in body
 assert status in ((302,403) if name=='anonymous_panel' else ((403,) if name=='direct_baseline' else (200,))),(name,status)
(S/'public-verified.json').write_text(json.dumps(checks,indent=2));print(json.dumps(checks,indent=2))
