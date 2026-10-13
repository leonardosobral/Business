from pathlib import Path
import csv,json,shutil
P=Path(__file__).parent;ROOT=P.parents[2];OUT=P.parent
base=list(csv.DictReader((ROOT/'outputs/abraceo-20261010/abraceo_filiados.csv').open(encoding='utf-8-sig'),delimiter=';'))
review55={r['id_filiado']:r for r in json.loads((ROOT/'outputs/abraceo-revisao55-20261011/revisao_empresas.json').read_text())};review8={r['id_filiado']:r for r in json.loads((OUT/'revisao_8.json').read_text())};live={r['id_filiado']:r for r in json.loads((P/'master-live.json').read_text())}
verified=json.loads((P/'verify.json').read_text());invites={str(r['company']):r['email'] for r in verified['previous_vouchers']};invites.update({str(r['id_conta']):r['email'] for r in verified['codes']})
for r in base:
 id=r['id_filiado'];r.update(review55.get(id,{}));r.update(review8.get(id,{}));db=live.get(id)
 if db:
  r.update(id_conta_business=db['id_conta'],status_conta_business=db['status'],cnpj_titular_business=db['documento'] or '',email_principal_business=db['email'],logo_business='https://business.roadrunners.run'+db['logo_path'],vouchers_emitidos=db['vouchers'],eventos_vinculados=db['eventos'],acao_business='PRÉ-CADASTRO PREPARADO / VOUCHER EMITIDO',status_pre_cadastro='PENDENTE DE CNPJ E REPRESENTANTE' if db['documento_pendente'] else 'CADASTRO PREPARADO / REPRESENTANTE A CONFIRMAR')
  r['email_convite']=invites[str(db['id_conta'])]
  if id in review8:r['acao_revisada']='PRÉ-CADASTRO CRIADO / VOUCHER EMITIDO'
  if id in ['pace-eventos','morro-mt']:r['email_publico']=db['email']
 else:r.update(id_conta_business='',status_conta_business='PENDENTE DE DECISÃO',cnpj_titular_business='',email_principal_business='',logo_business='',vouchers_emitidos=0,eventos_vinculados=0,acao_business='CONFIRMAR CONTA / PJ',status_pre_cadastro='SEPARADO — CONTA/PJ A CONFIRMAR')
 r['revisado_em']='2026-10-11'
assert len(base)==96 and len(live)==95 and sum(r['vouchers_emitidos'] for r in base)==95
(OUT/'revisao_8.json').write_text(json.dumps([r for r in base if r['id_filiado'] in review8],ensure_ascii=False,indent=2))
(OUT/'empresas_96.json').write_text(json.dumps(base,ensure_ascii=False,indent=2));fields=list(dict.fromkeys(k for r in base for k in r))
with (OUT/'empresas_96.csv').open('w',encoding='utf-8-sig',newline='') as f:
 w=csv.DictWriter(f,fieldnames=fields,delimiter=';');w.writeheader();w.writerows({k:json.dumps(v,ensure_ascii=False) if isinstance(v,(dict,list)) else v for k,v in r.items()} for r in base)
shutil.copy2(ROOT/'outputs/abraceo-convites-completos-20261011/convite_abraceo.txt',OUT/'convite_abraceo.txt')
for f in OUT.glob('*'):
 if f.is_file():f.chmod(0o600)
print({'empresas':96,'contas':95,'vouchers':95,'pendente':1})
