from pathlib import Path
import json,re,unicodedata
S=Path(__file__).resolve().parent; inv=json.loads((S/'inventory.json').read_text());checks=json.loads((S/'official-checks.json').read_text());events={e['id_evento']:e for e in inv['events']}
def norm(s):return ''.join(c for c in unicodedata.normalize('NFD',s.lower()) if unicodedata.category(c)!='Mn')
checks={r['id']:r for r in checks if any('level=1' in x and 'heading' in x for x in r.get('summary',[]))}
add=[]
for eid,r in checks.items():
 e=events[eid];s='\n'.join(r['summary']);h=next(x for x in r['summary'] if 'level=1' in x and 'heading' in x)
 if 'runningland.com.br/' not in r['url'] or 'circuito' not in norm(h) or 'estacoes' not in norm(h):continue
 assert norm(e['cidade']) in norm(h),(eid,h)
 date=e['data_inicial'];day=int(date[8:10]);month={'11':'Nov','12':'Dez'}[date[5:7]]
 assert any(re.search(r'strong: "?'+str(day)+r'"?$',x) for x in r['summary']),(eid,s)
 assert any('generic: '+month in x for x in r['summary']) and '2026' in h,(eid,s)
 assert not any(m['agregador_tag']=='estacoes' for m in e['memberships'])
 add.append({'id_evento':eid,'agregador_tag':'estacoes','source':r['url']})
assert len(add)==21,len(add)
r=next(r for r in json.loads((S/'official-checks.json').read_text()) if r.get('status')=='confirmed-correct-source');assert r['id']==48557 and 'ribeirao-preto-ii-2026' in r['url'];add.append({'id_evento':48557,'agregador_tag':'live-run-xp','source':r['url']})
out={'addMemberships':sorted(add,key=lambda x:x['id_evento']),'eventChanges':{'45366':{'ativo':False,'tag_301':events[37570]['tag']},'48557':{'url_hotsite':r['url'],'url_inscricao':'https://www.appliveexperience.com.br/evento/live-run-ribeirao-preto-ii-2026','categorias':'5km,10km,15km,kids'}},'pending':[{'id_evento':37765,'reason':'Imperatriz: ficha oficial O2 sem detalhes e cidade ausente do seletor atual do circuito; não inferir cancelamento.'}],'excluded':[e['id_evento'] for e in inv['events'] if not any(x in (e['url_hotsite'] or e['url_inscricao'] or '') for x in ['runningland.com.br','o2corre.com.br','liverun.com.br'])]}
(S/'decisions.json').write_text(json.dumps(out,ensure_ascii=False,indent=2));print(json.dumps({'newLinks':len(add),'estacoes':21,'live':1,'eventCorrections':2,'pending':out['pending'],'excluded':out['excluded']},ensure_ascii=False))
ids=sorted(set(x['id_evento'] for x in add)|{45366,37570});idsSQL=','.join(map(str,ids));rel=json.loads((S/'relations.json').read_text())['foreignKeys'];rel=[r for r in rel if r['table'] not in ['tb_agregadores_eventos','tb_evento_corridas_percursos']]
def lit(x):return "'"+x.replace("'","''")+"'"
fields=[]
for r in rel:
 t,c=r['table'],r['column'];fields.extend([lit(t+'.'+c),f"(SELECT jsonb_build_object('count',count(*),'hash',md5(coalesce(string_agg(md5(to_jsonb(z)::text),'' ORDER BY md5(to_jsonb(z)::text)),'')),'duplicate_count',count(*) FILTER(WHERE {c}=45366)) FROM {t} z WHERE {c} IN ({idsSQL}))"])
dep='jsonb_build_object('+','.join(fields)+')';(S/'dependency-expression.sql').write_text(dep)
snapshot=f"SELECT jsonb_build_object('events',(SELECT jsonb_agg(to_jsonb(e) ORDER BY id_evento) FROM tb_evento_corridas e WHERE id_evento IN ({idsSQL})),'routes',(SELECT coalesce(jsonb_agg(to_jsonb(p) ORDER BY id_evento_percurso),'[]') FROM tb_evento_corridas_percursos p WHERE id_evento IN ({idsSQL})),'memberships',(SELECT coalesce(jsonb_agg(to_jsonb(g) ORDER BY id_evento,agregador_tag),'[]') FROM tb_agregadores_eventos g WHERE id_evento IN ({idsSQL})),'dependencies',{dep})::text payload"
(S/'before.sql').write_text(snapshot)
