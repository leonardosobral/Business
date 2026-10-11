from pathlib import Path
import json,hashlib,base64
root=Path(__file__).resolve().parents[3]; base=root/'outputs/abraceo-20261010'; out=base/'importacao'
p=json.loads((base/'research/prepared.json').read_text());new={r['id_filiado']:r for r in p['pre_cadastro']};existing={r['id_filiado']:r for r in p['contas'] if r['correspondencia']=='CNPJ EXATO'}
assert len(new)==36 and len(existing)==5

def valid_cnpj(s):
 if len(s)!=14 or len(set(s))==1:return False
 for n,w in [(12,[5,4,3,2,9,8,7,6,5,4,3,2]),(13,[6,5,4,3,2,9,8,7,6,5,4,3,2])]:
  mod=sum(int(x)*y for x,y in zip(s[:n],w))%11
  if int(s[n])!=(0 if mod<2 else 11-mod):return False
 return True
rows=[];files={}
for f in p['filiados']:
 id=f['id_filiado']
 if id not in new and id not in existing:continue
 assert valid_cnpj(f['cnpj_pesquisado'])
 logo=base/f['logo_arquivo']; target='assets/contas/abraceo/'+logo.name
 files[target]=base64.b64encode(logo.read_bytes()).decode()
 rows.append({'id_filiado':id,'nome_empresa':f['nome_abraceo'],'documento':f['cnpj_pesquisado'],'razao_social':f['razao_social_pesquisada'],'email':f['email_publico'],'telefone':''.join(c for c in f['telefone_publico'] if c.isdigit()),'id_existente':int(existing[id]['id_conta']) if id in existing else None,'logo_path':'/'+target,'dados':f})
for name in ['administracao/contas/home.cfm','administracao/contas/includes/perfil_publico.cfm']:
 files[name]=base64.b64encode((root/name).read_bytes()).decode()
phones={'chelso-sports':'19993748756','corre-brasil':'4732286818','corre-paraiba':'83996025965','hl-eventos-esportivos':'11999673544','iguana-sports':'1130973215'}
for r in rows:
 if r['id_filiado'] in phones:r['telefone']=phones[r['id_filiado']]
 assert len(r['telefone'])<=13
assert len({r['documento'] for r in rows})==41
payload={'rows':rows,'files':files,'before':{'administracao/contas/home.cfm':'88a6fe61d6f35716ee252e728e169f32c6283c063dbe7e4a4ceea8a1e1936d0a'},'migration':(root/'_codex/sql/2026-10-11_tb_conta_perfis_publicos.sql').read_text()}
(out/'payload.json').write_text(json.dumps(payload,ensure_ascii=False))
print({'novas':len(new),'reuso':len(existing),'logos':41,'runtime':2})
