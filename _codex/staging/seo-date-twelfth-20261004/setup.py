from pathlib import Path
import json
p=Path(__file__).resolve().parent;old=p.parent/'seo-date-eleventh-20261004'
ids=[43140,43541,45366,43854,43166,41908];sids=','.join(map(str,ids));oids=','.join(map(str,json.loads((old/'selected-ids.json').read_text())))
(p/'selected-ids.json').write_text(json.dumps(ids))
(p/'baseline.py').write_text((old/'baseline.py').read_text().replace(oids,sids))
(p/'inventory-before.json').write_bytes((old/'date-divergences-after.json').read_bytes())
(p/'correct_data.py').write_text((old/'correct_data.py').read_text().replace(oids,sids).replace('<>30','<>12').replace('seo-date-eleventh-20261004','seo-date-twelfth-20261004'))
(p/'verify_public.py').write_text((old/'verify_public.py').read_text())
(p/'read_after.py').write_text((old/'read_after.py').read_text())
(p/'dependencies.json').write_text((old/'dependencies.json').read_text())
(p/'replacements.json').write_text('{}')
