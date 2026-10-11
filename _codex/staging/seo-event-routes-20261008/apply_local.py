from config import *
import hashlib,json,os
assert json.loads((S/'public-passed.json').read_text())['passed']
for n in TEMPLATES:assert (R/n).read_bytes()==(S/'local-before'/n).read_bytes(),'Local changed: '+n
for n in TEMPLATES:
 if (R/n).read_bytes()==(S/'candidate/rr'/n).read_bytes():continue
 tmp=(R/n).with_name(Path(n).name+'.seo-new')
 with tmp.open('xb') as out:out.write((S/'candidate/rr'/n).read_bytes())
 os.chmod(tmp,(R/n).stat().st_mode & 0o777);os.replace(tmp,R/n)
print(json.dumps({'synced_title_template':True,'existing_local_card_preserved':True}))
