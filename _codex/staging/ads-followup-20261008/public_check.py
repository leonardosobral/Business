from pathlib import Path
import urllib.request,re,json,hashlib
p=Path(__file__).parent
html=urllib.request.urlopen('https://roadrunners.run/',timeout=30).read().decode()
script=re.search(r'src=["\']([^"\']*assets/js/rr-audience.js[^"\']*)',html)
assert script,'public tracker missing'
u=script.group(1);u='https://roadrunners.run'+u if u.startswith('/') else u
js=urllib.request.urlopen(u,timeout=30).read()
assert hashlib.sha256(js).digest()==hashlib.sha256((p/'candidate/RoadRunners/assets/js/rr-audience.js').read_bytes()).digest()
assert 'G-7MYGVTEDZV' in html
assert re.search(r'"environment"\s*:\s*"prod"',html)
assert re.search(r'"isInternal"\s*:\s*false',html)
result={'public_tracker_hash_matches':True,'production_context':True,'anonymous_not_internal':True,'google_measurement_id_matches':True,'script':u}
(p/'public-checks.json').write_text(json.dumps(result));print(json.dumps(result))
