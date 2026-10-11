from pathlib import Path
import json,csv,re,hashlib,shutil
from collections import Counter
from urllib.parse import urlparse
from PIL import Image
p=Path(__file__).resolve().parent;root=p.parent
baseline=p/'baseline-v2'
if not baseline.exists():
    baseline.mkdir()
    for f in root.iterdir():
        if f.is_file() and not f.name.endswith('.zip'):shutil.copy2(f,baseline/f.name)
    for name in ['prepared.json','build.mjs','validate_package.py']:shutil.copy2(p/name,baseline/name)
d=json.loads((baseline/'prepared.json').read_text());b=json.loads((p/'business_inventory.json').read_text());events=json.loads((p/'business_events.json').read_text());roles=json.loads((p/'role_matches-v3.json').read_text());domains=json.loads((p/'domains-v3.json').read_text())
digits=lambda s:re.sub(r'\D','',s or '')
account_by_id={x['id_conta']:x for x in b['contas']}
suppliers={x['id_fornecedor']:x for x in b['fornecedores']}
supplier_map={'3lr-eventos':[23],'chelso-sports':[351],'clube-dos-corredores':[22],'corre-brasil':[25],'global-vita':[353],'grupo-stc-eventos-ltda':[2],'iguana-sports':[8],'spiridon-eventos':[7],'sportsland':[27],'trcrono':[347],'x3m-entretenimento-ltda':[60],'yescom':[21],'zbr-events':[59]}
type_map={x['id_fornecedor_tipo']:x['descricao_tipo'] for x in b['tipos_fornecedor']}
account_rows=[];supplier_rows=[];event_rows=[];logo_rows=[];member_status=[]
consulted=b['consultado_em']
for m in d['filiados']:
    key=m['id_filiado'];selected=m['cnpj_pesquisado'];known={x['cnpj'] for x in d['juridicas'] if x['id_filiado']==key}
    exact=[x for x in b['contas'] if digits(x['documento'])==selected]
    other=[x for x in b['contas'] if digits(x['documento']) in known and x not in exact]
    probable=[account_by_id[5]] if key=='mp3-solucoes' else []
    for c in exact+other+probable:
        isexact=c in exact
        account_rows.append(dict(id_filiado=key,nome_abraceo=m['nome_abraceo'],id_conta=c['id_conta'],nome_conta=c['nome_conta'],cnpj_pesquisado=selected,cnpj_conta=digits(c['documento']),status_conta=c['status'],correspondencia='CNPJ EXATO' if isexact else 'OUTRO CNPJ; CONFIRMAR EMPRESA',evidencia='Documento idêntico em tb_contas e na base ABRACEO' if isexact else 'MP3: mesmo e-mail e telefone da ficha ABRACEO; sócios e endereço coincidentes nas bases públicas, porém CNPJs distintos.',usuarios_ativos=c['usuarios_ativos'],eventos_vinculados=c['eventos_ativos'],acao='Reaproveitar conta; confirmar representante e acesso ao estudo' if isexact else 'Confirmar uso da conta 5 ou cadastro da outra PJ; conta sem usuário ativo',fonte='Business produção: public.tb_contas e contagens de tb_conta_usuarios/tb_conta_eventos',fonte_publica=m['fonte_abraceo'],fonte_complementar='' if isexact else 'https://www.econodata.com.br/consulta-empresa/28434613000156-mp3-marketing-promocional-ltda ; https://www.econodata.com.br/consulta-empresa/11194903000177-mp3-solucoes-ltda',consultado_em=consulted))
    for sid in supplier_map.get(key,[]):
        s=suppliers[sid];cnpj=digits(s.get('cnpj'))
        status='CNPJ EXATO' if cnpj==selected else 'MARCA E SITE; CNPJ AUSENTE' if not cnpj.strip('0') else 'MARCA E SITE; CNPJ DIVERGENTE'
        supplier_rows.append(dict(id_filiado=key,nome_abraceo=m['nome_abraceo'],id_fornecedor=sid,nome_fornecedor=s['nome_fornecedor'],cnpj_fornecedor=cnpj,cnpj_pesquisado=selected,correspondencia=status,site=s['site_fornecedor'],tipo=s['tag_tipo'],ativo=s['ativo'],observacao='Cadastro de fornecedor não equivale a conta Business. '+('Iguana: revisar 08.370.818/0001-08 antes de usar como identificação jurídica.' if key=='iguana-sports' else 'Confirmar PJ no pré-cadastro quando o CNPJ não coincide.' if status!='CNPJ EXATO' else ''),fonte='Business produção: public.tb_fornecedores',consultado_em=consulted))
    patterns={(x['campo'],x['valor']) for x in roles[key]}
    for e in events:
        links=[x for x in e['contas'] if x['id_conta'] in [a['id_conta'] for a in exact+other+probable]]
        sf=[x for x in e['fornecedores'] if x['id_fornecedor'] in supplier_map.get(key,[])]
        legacy=e['id_fornecedor'] in supplier_map.get(key,[])
        matchingroles=[field for field in ['organizador','cronometragem','realizacao'] if (field,e[field]) in patterns]
        if key=='metodo-grupo-chokito' and e['estado']!='BA':matchingroles=[]
        matchingurls=[]
        for field in ['url_inscricao','url_hotsite','url_regulamento']:
            host=(urlparse(e[field] or '').hostname or '').lower().removeprefix('www.')
            for domain in domains[key]:
                if host==domain or host.endswith('.'+domain):matchingurls.append((field,domain))
        if not (links or sf or legacy or matchingroles or matchingurls):continue
        active_links=[x for x in links if x['status']=='ATIVO']
        active_exact=[x for x in active_links if x['id_conta'] in [a['id_conta'] for a in exact]]
        if active_exact:level='JÁ VINCULADO À CONTA'
        elif active_links:level='VÍNCULO EM CONTA DE OUTRA PJ'
        elif sf:level='FORNECEDOR CADASTRADO NO EVENTO'
        elif matchingroles:level='NOME INFORMADO NO EVENTO'
        elif legacy:level='FORNECEDOR PRINCIPAL; PAPEL A REVISAR'
        else:level='SITE RELACIONADO; PAPEL A CONFIRMAR'
        evidence=[];role=[]
        for x in links:evidence.append('tb_conta_eventos: conta '+str(x['id_conta'])+' '+x['status'])
        for x in sf:
            role.append(type_map.get(x['id_fornecedor_tipo'],str(x['id_fornecedor_tipo'])))
            evidence.append('tb_evento_corridas_fornecedores: fornecedor '+str(x['id_fornecedor'])+' / '+role[-1])
        for f in matchingroles:
            role.append({'organizador':'Organização','cronometragem':'Cronometragem','realizacao':'Realização'}[f]);evidence.append(f+': '+e[f])
        if legacy:evidence.append('tb_evento_corridas.id_fornecedor='+str(e['id_fornecedor']))
        for f,domain in matchingurls:evidence.append(f+': domínio '+domain)
        otheraccounts=[x for x in e['contas'] if x['status']=='ATIVO' and x['id_conta'] not in [a['id_conta'] for a in exact+other+probable]]
        warnings=[]
        if not e['ativo']:warnings.append('Evento inativo no catálogo')
        if otheraccounts:warnings.append('Outra conta já vinculada; verificar coexistência e papel')
        if m['status_pre_cadastro']!='APTO PARA RASCUNHO' and not exact:warnings.append('PJ do filiado ainda depende de confirmação')
        if key=='iguana-sports' and (sf or legacy):warnings.append('CNPJ do fornecedor diverge da pesquisa')
        if key=='mp3-solucoes':warnings.append('Conta MP3 Marketing tem outro CNPJ; não transferir titularidade automaticamente')
        if matchingurls and not (active_links or sf or matchingroles):warnings.append('Domínio pode ser plataforma ou prestador; não prova organização')
        event_rows.append(dict(id_filiado=key,nome_abraceo=m['nome_abraceo'],id_evento=e['id_evento'],nome_evento=e['nome_evento'],data_inicial=e['data_inicial'],data_final=e['data_final'],periodo='FUTURO/EM CURSO' if e['data_final']>='2026-10-11' else 'HISTÓRICO',cidade=e['cidade'],uf=e['estado'],evento_ativo='SIM' if e['ativo'] else 'NÃO',classificacao=level,papel='; '.join(dict.fromkeys(role)) or 'A confirmar',id_conta_filiado='; '.join(str(x['id_conta']) for x in links),outras_contas_ativas='; '.join(str(x['id_conta']) for x in otheraccounts),id_fornecedor='; '.join(str(x['id_fornecedor']) for x in sf) or (str(e['id_fornecedor']) if legacy else ''),evidencia='; '.join(evidence),ressalvas='; '.join(warnings),acao='Manter vínculo existente; confirmar acesso do representante' if active_exact else 'Confirmar vínculo e papel antes de associar; não conceder acesso automaticamente',url_evento='https://roadrunners.run/evento/'+e['tag']+'/' if e['tag'] else '',url_business='https://business.roadrunners.run/eventos/?id_evento='+str(e['id_evento']),url_inscricao=e['url_inscricao'],url_regulamento=e['url_regulamento'],fonte='Business produção: tb_evento_corridas, tb_conta_eventos e tb_evento_corridas_fornecedores',consultado_em=consulted))
    logo=root/m['logo_arquivo']
    with Image.open(logo) as im:width,height=im.size;fmt=im.format;im.verify()
    logo_rows.append(dict(id_filiado=key,nome_abraceo=m['nome_abraceo'],arquivo=m['logo_arquivo'],fonte=m['logo_url'],formato=fmt,largura=width,altura=height,bytes=logo.stat().st_size,sha256=hashlib.sha256(logo.read_bytes()).hexdigest(),status='BAIXADO E VALIDADO',validado_em='2026-10-11'))
    mine=[x for x in event_rows if x['id_filiado']==key]
    status='CONTA EXISTENTE — CNPJ EXATO' if exact else 'CONTA RELACIONADA — OUTRO CNPJ' if other or probable else 'NÃO LOCALIZADA'
    if exact:action='REAPROVEITAR CONTA'
    elif other or probable:action='CONFIRMAR CONTA / PJ'
    elif m['status_pre_cadastro']=='APTO PARA RASCUNHO':action='PREPARAR NOVO RASCUNHO'
    else:action='CONFIRMAR DADOS DA EMPRESA'
    member_status.append(dict(id_filiado=key,nome_abraceo=m['nome_abraceo'],cnpj_pesquisado=selected,conta_business=status,id_conta='; '.join(str(x['id_conta']) for x in exact+other+probable),acao=action,fornecedores='; '.join(map(str,supplier_map.get(key,[]))),eventos_total=len(mine),eventos_ja_vinculados=sum(x['classificacao']=='JÁ VINCULADO À CONTA' for x in mine),eventos_por_confirmar=sum(x['classificacao']!='JÁ VINCULADO À CONTA' for x in mine),eventos_futuros=sum(x['periodo']=='FUTURO/EM CURSO' for x in mine),logo=m['logo_arquivo'],observacao='Nenhuma conta localizada pelos CNPJs pesquisados, nomes e contatos; reconferir no momento da criação.' if not exact+other+probable else 'Não criar duplicata; revisar representante.' if exact else 'MP3: conta 5, mesmo e-mail e telefone, CNPJ distinto e nenhum usuário ativo.',consultado_em=consulted))
    m.update(conta_business=status,id_conta_business='; '.join(str(x['id_conta']) for x in exact+other+probable),acao_business=action,eventos_relacionados=len(mine),eventos_vinculados=sum(x['classificacao']=='JÁ VINCULADO À CONTA' for x in mine),consultado_business_em=consulted)
    if exact:m['status_pre_cadastro']='CONTA EXISTENTE';m['pendencias']='Reaproveitar conta '+m['id_conta_business']+'; confirmar representante e acesso ao estudo'
    if probable:m['pendencias']='Confirmar relação com conta 5 (MP3 Marketing, outro CNPJ); não criar duplicata sem conferir'
d['pre_cadastro']=[x for x in d['pre_cadastro'] if not next(m for m in d['filiados'] if m['id_filiado']==x['id_filiado'])['id_conta_business']]
for x in d['pre_cadastro']:x['deduplicacao_business']='NÃO LOCALIZADA EM 11/10/2026; RECONFERIR AO CRIAR'
d.update(cruzamento=member_status,contas=account_rows,fornecedores=supplier_rows,eventos=event_rows,logos_manifesto=logo_rows)
external=json.loads((p/'external_events-v3.json').read_text())
for x in external:
    x['nome_abraceo']=next(m['nome_abraceo'] for m in d['filiados'] if m['id_filiado']==x['id_filiado'])
    x['consultado_em']='2026-10-11'
d['eventos_externos']=external
for row in member_status:row['eventos_fontes_externas']=sum(x['id_filiado']==row['id_filiado'] for x in external)
d['resumo']['documento_para_revisao']=len(d['pre_cadastro'])
d['resumo']['aguarda_confirmacao']=sum(x['status_pre_cadastro']=='AGUARDA CONFIRMAÇÃO' for x in d['filiados'])
d['business_resumo']={'contas_exatas':len([x for x in member_status if x['conta_business']=='CONTA EXISTENTE — CNPJ EXATO']),'contas_outro_cnpj':len([x for x in member_status if x['conta_business']=='CONTA RELACIONADA — OUTRO CNPJ']),'novos_rascunhos':len(d['pre_cadastro']),'filiados_com_eventos':len({x['id_filiado'] for x in event_rows}),'eventos_distintos':len({x['id_evento'] for x in event_rows}),'relacoes':len(event_rows),'vinculos_existentes':sum(x['classificacao']=='JÁ VINCULADO À CONTA' for x in event_rows),'relacoes_por_classe':dict(Counter(x['classificacao'] for x in event_rows)),'consulta':consulted,'catalogo_total':b['eventos_totais']}
(p/'prepared.json').write_text(json.dumps(d,ensure_ascii=False,indent=2))
def csvout(name,rows):
    with (root/name).open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(dict.fromkeys(k for row in rows for k in row)),delimiter=';');w.writeheader();w.writerows(rows)
for name,key in [('abraceo_filiados.csv','filiados'),('abraceo_cruzamento_business.csv','cruzamento'),('abraceo_contas_existentes.csv','contas'),('abraceo_fornecedores_existentes.csv','fornecedores'),('abraceo_eventos_relacionados.csv','eventos'),('abraceo_eventos_fontes_externas.csv','eventos_externos'),('abraceo_logotipos_manifesto.csv','logos_manifesto'),('abraceo_pre_cadastro_rascunhos.csv','pre_cadastro')]:csvout(name,d[key])
payload=json.loads((baseline/'abraceo_pre_cadastro_rascunhos.json').read_text());payload.update(versao='3',deduplicacao='Cruzamento de produção em 11/10/2026; contas localizadas excluídas deste lote. Reconferir antes de criar.',rascunhos=d['pre_cadastro']);(root/'abraceo_pre_cadastro_rascunhos.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2))
print(json.dumps(d['business_resumo'],ensure_ascii=False,indent=2))
print('Sem eventos:',', '.join(x['nome_abraceo'] for x in member_status if not x['eventos_total']))
