from pathlib import Path
import json,hashlib
P=Path(__file__).resolve().parent;old=P.parent/'seo-abavse-reschedule-20261004';r=json.loads((old/'service-passed.json').read_text());name='services/EventRedirectService.cfc';want=hashlib.sha256((P/'candidate'/name).read_bytes()).hexdigest();assert r['hashes'][name]==want
(P/'service-passed.json').write_text(json.dumps({'hashes':{name:want},'watch':json.loads((P/'watch.json').read_text()),'checks':r['CHECKS']},indent=2))
