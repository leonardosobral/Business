from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import json,sys
stage=Path(__file__).resolve().parent
sys.path.insert(0,str(stage.parent/'seo-semrush-fixes-20261004'))
from check_public import fetch
issues=json.loads((stage.parent/'seo-semrush-fixes-20261004/issues.json').read_text())
urls=[x['source_url'] for x in issues['24']['data']['data'] if any(t in x['source_url'] for t in ['/busca/','/search/','/busqueda/'])]
urls+=['https://roadrunners.run/busca/','https://roadrunners.run/en/search/','https://roadrunners.run/es/busqueda/','https://roadrunners.run/busca/?busca=maratona','https://roadrunners.run/busca/?utm_source=seo-check']
with ThreadPoolExecutor(max_workers=3) as pool:r=list(pool.map(fetch,urls))
(stage/(sys.argv[1]+'.json')).write_text(json.dumps(r,ensure_ascii=False,indent=2))
for x in r: print(json.dumps(x,ensure_ascii=False))
