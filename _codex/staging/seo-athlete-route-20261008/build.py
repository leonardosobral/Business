from pathlib import Path
import hashlib,json
S=Path(__file__).resolve().parent
rules={
 '.htaccess':[
  'RewriteRule ^en/athlete/([^/]+)/?$ /atleta/index.cfm?i18n_lang=en&i18n_route=athlete&tag=$1 [NC,L,QSA]',
  'RewriteRule ^es/atleta/([^/]+)/?$ /atleta/index.cfm?i18n_lang=es&i18n_route=athlete&tag=$1 [NC,L,QSA]'],
 'atleta/.htaccess':['RewriteRule ^(.*) index.cfm?tag=$1 [NC,L,QSA]']}
for n,lines in rules.items():
 s=(S/'baseline'/n).read_text()
 for line in lines:
  assert s.count(line)==1,n
  s=s.replace(line,line.replace('[NC,L,QSA]','[B,NC,L,QSA]'))
 (S/'candidate'/n).write_text(s)
(S/'candidate-hashes.json').write_text(json.dumps({n:hashlib.sha256((S/'candidate'/n).read_bytes()).hexdigest() for n in rules},indent=2))
print(json.dumps({'files':len(rules),'rules':3,'change':'escape rewrite backreferences'}))
