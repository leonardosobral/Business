import json,re,unicodedata
from pathlib import Path
from urllib.parse import urlparse
p=Path(__file__).resolve().parent
d=json.loads((p/'prepared.json').read_text());b=json.loads((p/'business_inventory.json').read_text());roles=json.loads((p/'business_roles.json').read_text())['papeis'];aliases=json.loads((p/'aliases-v3.json').read_text())
def norm(v):return re.sub(r'[^a-z0-9]+',' ',unicodedata.normalize('NFKD',v or '').encode('ascii','ignore').decode().lower()).strip()
def match(k,v):
    if k=='rg' and v.strip().upper()=='RG+':return True
    v=norm(v)
    if k=='run-eventos':return v in ('run eventos','run eventos esportivos e culturais')
    if k=='run-sports' and 'life run' in v:return False
    return any(re.search(r'\b'+re.escape(t)+r'\b',v) for t in aliases[k])
aliases['metodo-grupo-chokito']+=['chokito','runners club']
aliases['rg']+=['rede geral']
aliases['wine-run-brasil']+=['wine run']
domains={}
shared={'instagram.com','facebook.com','gmail.com','hotmail.com','outlook.com','yahoo.com.br','yahoo.com','msn.com','live.com','terra.com.br','uol.com.br','bol.com.br','msha.ke','proeesp.com.br'}
extra={'3lr-eventos':['3lr.esp.br'],'grupo-stc-eventos-ltda':['grupostc.net'],'mountain-do':['mountaindo.com.br'],'voa-esportes':['voaesportes.com'],'x3m-entretenimento-ltda':['x3mbrasil.com']}
for m in d['filiados']:
    ds=[]
    for s in [m.get('site_revisado'),m.get('site_abraceo')]:
        if s:
            host=(urlparse(s).hostname or '').lower().removeprefix('www.')
            if host and host not in shared:ds.append(host)
    domains[m['id_filiado']]=sorted(set(ds+extra.get(m['id_filiado'],[])))
matched={k:[r for r in roles if match(k,r['valor'])] for k in aliases}
(p/'role_matches-v3.json').write_text(json.dumps(matched,ensure_ascii=False,indent=2))
(p/'aliases-v3.json').write_text(json.dumps(aliases,ensure_ascii=False,indent=2))
(p/'domains-v3.json').write_text(json.dumps(domains,ensure_ascii=False,indent=2))
q=lambda s:"'"+s.replace("'","''")+"'"
names=','.join(q(s) for s in sorted(set(r['valor'] for rows in matched.values() for r in rows)))
patterns=','.join(q('%'+s+'%') for s in sorted(set(v for vals in domains.values() for v in vals)))
fids='2,7,8,21,22,23,25,27,59,60,347,351,353'
sql=f'''SELECT e.id_evento,e.nome_evento,e.cidade,e.estado,e.tag,e.data_inicial::text,e.data_final::text,e.ativo,e.status_evento,e.organizador,e.cronometragem,e.realizacao,e.id_fornecedor,e.url_inscricao,e.url_hotsite,e.url_regulamento,
coalesce((SELECT jsonb_agg(jsonb_build_object('id_conta',ce.id_conta,'status',ce.status,'id_conta_evento',ce.id_conta_evento)) FROM public.tb_conta_eventos ce WHERE ce.id_evento=e.id_evento),'[]')::text AS contas,
coalesce((SELECT jsonb_agg(jsonb_build_object('id_fornecedor',ef.id_fornecedor,'id_fornecedor_tipo',ef.id_fornecedor_tipo,'link_website',ef.link_website)) FROM public.tb_evento_corridas_fornecedores ef WHERE ef.id_evento=e.id_evento),'[]')::text AS fornecedores
FROM public.tb_evento_corridas e WHERE e.organizador IN ({names}) OR e.cronometragem IN ({names}) OR e.realizacao IN ({names})
OR concat_ws(' ',e.url_inscricao,e.url_hotsite,e.url_regulamento) ILIKE ANY(ARRAY[{patterns}])
OR e.id_fornecedor IN ({fids}) OR EXISTS(SELECT 1 FROM public.tb_evento_corridas_fornecedores ef WHERE ef.id_evento=e.id_evento AND ef.id_fornecedor IN ({fids}))
OR EXISTS(SELECT 1 FROM public.tb_conta_eventos ce WHERE ce.id_evento=e.id_evento AND ce.id_conta IN (1,5,6,7,9,27))
ORDER BY e.data_inicial DESC,e.id_evento'''
(p/'business_events.sql').write_text(sql)
print('Exact role values',len(names.split(',')),'domains',len(set(v for vals in domains.values() for v in vals)))
