import csv, json, re, unicodedata
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
data=json.loads((ROOT/'research/baseline-v1/prepared.json').read_text())
baseline={r['id_filiado']:dict(r) for r in data['filiados']}
decisions=json.loads((ROOT/'research/decisions-v2.json').read_text())
registry=json.loads((ROOT/'research/revisao-registry.json').read_text())
DATE='2026-10-11'
def clean(v):return re.sub(r'\b\d{11}\b','[CPF omitido]',str(v or ''))
def digits(v):return re.sub(r'\D','',str(v or ''))
def valid(c):
    if len(c)!=14 or len(set(c))==1:return False
    n=list(map(int,c))
    for end,w in [(12,[5,4,3,2,9,8,7,6,5,4,3,2]),(13,[6,5,4,3,2,9,8,7,6,5,4,3,2])]:
        d=11-sum(a*b for a,b in zip(n[:end],w))%11
        if n[end]!=(0 if d>=10 else d):return False
    return True
def norm(s):return ''.join(c for c in unicodedata.normalize('NFD',str(s)) if unicodedata.category(c)!='Mn').lower()
def registry_fields(d):
    m={'razao_social':'razao_social','nome_fantasia':'nome_fantasia','descricao_situacao_cadastral':'situacao','bairro':'bairro','cep':'cep','municipio':'municipio','uf':'uf','cnae_fiscal':'cnae_principal','cnae_fiscal_descricao':'cnae_descricao','natureza_juridica':'natureza_juridica','porte':'porte','data_inicio_atividade':'abertura','fonte':'fonte'}
    out={target:clean(d.get(source)) for source,target in m.items()}
    out['endereco']=' '.join(str(d.get(k) or '') for k in ['descricao_tipo_de_logradouro','logradouro','numero','complemento']).strip() if d.get('logradouro') else ''
    out['situacao']=out['situacao'].upper()
    out['cep']=digits(out['cep'])
    return out
legal={(r['id_filiado'],r['cnpj']):r for r in data['juridicas']}
for r in legal.values():
    r['situacao']=r['situacao'].upper()
    if r['cnpj'] in registry:
        changes=registry_fields(registry[r['cnpj']])
        r.update({k:v for k,v in changes.items() if v})
        r['revisado_em']=DATE
    else:r['revisado_em']='2026-10-10'
    r['fonte_papel']=''
for id,d in decisions.items():
    for c in [d['cnpj'],*d.get('alternativas',{})]:
        if (id,c) not in legal:
            r={k:'' for k in data['juridicas'][0]}
            r.update(id_filiado=id,nome_abraceo=baseline[id]['nome_abraceo'],cnpj=c,digitos_verificadores='Válidos' if valid(c) else 'INVÁLIDOS',observacao='Pesquisa pública; confirmar titular da conta no primeiro acesso.',revisado_em=DATE)
            r.update(registry_fields(registry[c]));legal[id,c]=r
    for (mid,c),r in legal.items():
        if mid!=id:continue
        r['papel_na_pesquisa']='Selecionado para rascunho' if c==d['cnpj'] and d['apto'] else ('Candidato; confirmação pendente' if c==d['cnpj'] else d.get('alternativas',{}).get(c,'Alternativa não selecionada'))
        r['fonte_papel']=d['fonte']
        r['observacao']=d['decisao']+' '+d['pendencia']
        r['revisado_em']=DATE

review=[]; staging=[]
for r in data['filiados']:
    id=r['id_filiado'];old=baseline[id];d=decisions.get(id)
    r['revisado_em']=DATE if d or r['cnpj_pesquisado'] in registry else '2026-10-10'
    if d:r['cnpj_pesquisado']=d['cnpj']
    j=legal.get((id,r['cnpj_pesquisado']))
    if j:
        pairs={'razao_social':'razao_social_pesquisada','nome_fantasia':'nome_fantasia_cadastral','situacao':'situacao_cadastral_consultada','endereco':'endereco_cadastral','bairro':'bairro_cadastral','cep':'cep_cadastral','municipio':'municipio_cadastral','uf':'uf_cadastral','cnae_principal':'cnae_principal','cnae_descricao':'cnae_descricao','fonte':'fonte_cadastro'}
        r.update({target:j.get(source,'') for source,target in pairs.items()})
    primary=old['status_vinculo_cnpj']=='Vínculo em fonte primária' or bool(old['documento_para_revisao'])
    selected=primary and not old['cnpjs_alternativos']
    if d:
        primary=d['primaria'];selected=d['apto'];r['fonte_vinculo_cnpj']=d['fonte']
        r['observacoes']=d['decisao']+' '+d['pendencia']
        r['status_vinculo_cnpj']='Selecionado por evidência pública' if selected else 'Revisado; confirmação pendente'
        if d.get('tipo'):
            r['tipo_prestador_sugerido']=d['tipo']
            r['segmento']='Organização de eventos esportivos' if d['tipo']=='Organizador' else 'Serviços e produção de eventos; confirmar escopo'
            r['evidencia_atuacao']='Evidência pública de organização' if primary and d['tipo']=='Organizador' else 'Atuação sugerida; confirmar'
            r['fonte_atuacao']=d['fonte'] if primary else old['fonte_atuacao']
    r['site_revisado']=d.get('site',r['site_abraceo']) if d else r['site_abraceo']
    r['cnpjs_alternativos']='; '.join(c for (mid,c) in legal if mid==id and c!=r['cnpj_pesquisado'])
    r['evidencia_vinculo']='Fonte primária' if primary else 'Candidato em base cadastral'
    eligible=bool(selected and r['situacao_cadastral_consultada']=='ATIVA' and valid(r['cnpj_pesquisado']) and r['razao_social_pesquisada'] and r['tipo_prestador_sugerido'])
    r['documento_para_revisao']=r['cnpj_pesquisado'] if eligible else ''
    r['status_pre_cadastro']='APTO PARA RASCUNHO' if eligible else 'AGUARDA CONFIRMAÇÃO'
    r['tipo_titular_sugerido']='PJ'
    pending=[]
    if not eligible:pending.append(d['pendencia'] if d else 'Confirmar vínculo marca/CNPJ e tipo de atuação antes do lote')
    elif d and d['pendencia']!='Confirmar dados no primeiro acesso.':pending.append(d['pendencia'])
    if not r['endereco_cadastral']:pending.append('Endereço completo não localizado; campo opcional')
    pending.append('Deduplicar no Business e confirmar representante autenticado no primeiro acesso')
    r['pendencias']='; '.join(pending)
    if id=='voa-esportes':r['observacoes']='CNPJ e razão social no site. Consulta cadastral adicional confirmou situação ATIVA.'
    if d:
        review.append({'id_filiado':id,'nome_abraceo':r['nome_abraceo'],'cnpj_anterior':old['cnpj_pesquisado'],'cnpj_revisado':r['cnpj_pesquisado'],'situacao':r['situacao_cadastral_consultada'],'resultado':r['status_pre_cadastro'],'decisao':d['decisao'],'pendencia':d['pendencia'],'fonte_decisao':d['fonte'],'fonte_auxiliar':d.get('fonte_auxiliar',''),'fonte_cadastral':r['fonte_cadastro'],'revisado_em':DATE})
    if eligible:
        rawphone=digits(r['telefone_publico'])
        phone=rawphone if len(rawphone) in (10,11) else ''
        staging.append({'id_filiado':id,'nome_empresa':r['nome_abraceo'],'tipo_titular':'PJ','documento':r['cnpj_pesquisado'],'tipo_prestador':r['tipo_prestador_sugerido'],'site':r['site_revisado'],'cidade':r['cidade_abraceo'],'estado':r['uf_abraceo'],'telefone_publico':phone,'contato_publico':r['contato_publico'],'email_publico':r['email_publico'],'razao_social':r['razao_social_pesquisada'],'nome_fantasia':r['nome_fantasia_cadastral'],'logo_arquivo':r['logo_arquivo'],'fonte_cnpj':r['fonte_vinculo_cnpj'],'status_importacao':'RASCUNHO; NÃO ATIVAR CONTA','confirmacao_representante':'PENDENTE','deduplicacao_business':'PENDENTE','revisado_em':r['revisado_em']})
    if r['cnpj_pesquisado'] in registry:
        raw=registry[r['cnpj_pesquisado']]
        r['data_situacao_cadastral']=raw.get('data_situacao_cadastral','') or ''
    else:r['data_situacao_cadastral']=''

data['juridicas']=list(legal.values());data['revisoes']=review;data['pre_cadastro']=staging
s=data['resumo'];rows=data['filiados']
s.update(com_cnpj_pesquisado=sum(bool(r['cnpj_pesquisado']) for r in rows),com_razao_social=sum(bool(r['razao_social_pesquisada']) for r in rows),com_endereco=sum(bool(r['endereco_cadastral']) for r in rows),cnpj_fonte_primaria=sum(r['evidencia_vinculo']=='Fonte primária' for r in rows),documento_para_revisao=len(staging),multiplas_pjs=sum(bool(r['cnpjs_alternativos']) for r in rows),cnpj_principal_nao_ativo=sum(r['situacao_cadastral_consultada']!='ATIVA' for r in rows),pessoas_juridicas=len(legal),revisados=len(review),aguarda_confirmacao=96-len(staging),revisados_aptos=sum(r['resultado']=='APTO PARA RASCUNHO' for r in review))
(ROOT/'research/prepared.json').write_text(json.dumps(data,ensure_ascii=False,indent=2))
for name,records in [('abraceo_filiados.csv',rows),('abraceo_pessoas_juridicas.csv',data['juridicas']),('abraceo_revisao_cnpjs.csv',review),('abraceo_pre_cadastro_rascunhos.csv',staging)]:
    cols=list(dict.fromkeys(k for r in records for k in r if k not in ['logo_width','logo_height']))
    with (ROOT/name).open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=cols,delimiter=';',extrasaction='ignore');w.writeheader();w.writerows(records)
payload={'versao':'2','revisado_em':DATE,'finalidade':'Pré-preenchimento de rascunhos de organizações; não concede acesso','contas_criadas':False,'responsavel':'Obter nome_responsavel e email_responsavel da sessão autenticada; não preencher a partir de contatos públicos','deduplicacao':'Consultar contas existentes por CNPJ completo e raiz antes de criar','rascunhos':staging}
(ROOT/'abraceo_pre_cadastro_rascunhos.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2))
assert len(rows)==len({r['id_filiado'] for r in rows})==96
assert all(valid(r['cnpj']) for r in legal.values())
assert len({r['documento'] for r in staging})==len(staging)
assert all(len(r['nome_empresa'])<=160 and len(r['site'])<=256 and len(r['cidade'])<=128 and len(r['estado'])==2 for r in staging)
print(json.dumps(s,ensure_ascii=False,indent=2))
