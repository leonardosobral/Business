from pathlib import Path
import hashlib,json,sys
S=Path(__file__).resolve().parent;B=S.parents[2];R=B.parent/'RoadRunners';group=sys.argv[1];assert group in ['rr','business']
root=R if group=='rr' else B
names=['includes/estrutura/header_tema.cfm'] if group=='rr' else ['portal/includes/seo_queue_data.cfm','portal/conteudo/seo_semrush.cfm']
assert json.loads((S/'public-passed.json').read_text())['passed']
assert json.loads((S/(group+'-verify.json')).read_text())['verified_hashes']==len(names)
if group=='business':assert json.loads((S/'published-render-passed.json').read_text())['scenarios']==19
for n in names:
 old=(root/n).read_bytes();baseline=(S/'baseline'/group/n).read_bytes();new=(S/'candidate'/group/n).read_bytes()
 assert old==baseline or old==new,n+' local drift'
for n in names:(root/n).write_bytes((S/'candidate'/group/n).read_bytes())
print(json.dumps({'local_files_updated':len(names),'group':group}))
