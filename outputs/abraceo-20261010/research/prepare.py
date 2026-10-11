from collect import *
import csv, unicodedata
from PIL import Image

def norm(s): return ''.join(c for c in unicodedata.normalize('NFD',str(s or '')) if unicodedata.category(c)!='Mn').lower()
def digits(s): return re.sub(r'\D','',str(s or ''))
def fmt(c): return f'{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:]}' if len(c)==14 else c
def valid(c):
    if len(c)!=14 or len(set(c))==1:return False
    n=list(map(int,c))
    for end,w in [(12,[5,4,3,2,9,8,7,6,5,4,3,2]),(13,[6,5,4,3,2,9,8,7,6,5,4,3,2])]:
        d=11-sum(a*b for a,b in zip(n[:end],w))%11
        if n[end]!=(0 if d>=10 else d):return False
    return True
def scrub(s): return re.sub(r'\b\d{11}\b','[CPF omitido]',str(s or ''))

members=json.loads((ROOT/'research/filiados.json').read_text())
registry=json.loads((ROOT/'research/registry.json').read_text())
selected={a[0]:a[1:] for a in (line.split() for line in (ROOT/'research/selected.txt').read_text().splitlines())}
sites={r['id']:r['paginas'] for r in json.loads((ROOT/'research/sites.json').read_text())}
blocks=[]
for p in list((ROOT/'research').glob('q-*.txt'))+list((ROOT/'research').glob('search-*.txt')):
    for block in p.read_text().split('--------------------------------------------------------------------------------'):
        u=re.search(r'\((https?://[^\n]+)\)\n',block)
        if u: blocks.append((u[1],block))

# Sources explicitly linking the brand to the CNPJ (not merely a same-name registry hit).
primary={
'3lr-eventos':'https://pesquisa.in.gov.br/imprensa/servlet/INPDFViewer?captchafield=firstAccess&data=15%2F08%2F2025&jornal=530&pagina=89',
'aclive-sports':'https://www.race83.com.br/evento/6106/trun-trail-run-series-etapa-belem',
'bee-sports':'https://www.beesports.com.br/',
'beta-sports':'https://www.betasports.com.br/vpo',
'bolt-producoes':'https://cdn.ticketsports.com.br/ticketagora/arquivos/evento/72011/b01fe3077cf74014aee9bcdc6bbe4522638796490963275570.pdf',
'clube-dos-corredores':'https://travessiatttrs.com.br/',
'global-vita':'https://loja.maratonadecuritiba.com.br/',
'hl-eventos-esportivos':'https://www.ativo.com/calendario/eventos/america-do-sul/br/sp/sao-jose-dos-campos/corrida-de-rua/37957/10a-corrida-da-virada-joseense-2020/',
'letape-brasil':'https://arquivos.letapebrasil.com.br/wp-content/uploads/2025/02/Regulamento-Geral-_-LETAPE-BRASIL-2025-PTBR.pdf',
'metodo-grupo-chokito':'https://www.centraldasinscricoes.com.br/painel/upload/doc/inscricao/doc-47-cb7026f8a84a91bb616e53b424fa84b7.pdf',
'morro-mt':'https://assets.zyrosite.com/dOq8P3q5RpsQ78Jb/regulamento_utm_po-c3-9aro_2025-ALp7rP0e6rUe0Mgq.pdf',
'mp-sports-brasil':'https://xcrono.com.br/site/wp-content/uploads/2025/08/reg-corrida-maior-1.pdf',
'noblu-sports':'https://chiptimingstorage.blob.core.windows.net/eventos/2026/10520/regulamentos/regulamento.pdf',
'oxe-eventos':'https://www.tce.ce.gov.br/downloads/RH/Portarias/2025/Portaria969_2025.pdf',
'rg':'https://www.transparencia.feiradesantana.ba.leg.br/adm/upload/licitacao/PL-012-2017-%20REDE%20GERAL%20TV%20Parte%202%2090-160.pdf',
'seven-eco':'https://beta.ticketsports.com.br/e/1-etapa-circuito-estacoes-park-lagos-33043',
'top-chip':'https://acailandia.ma.gov.br/arquivos/licitacoes/1dace1bcc5f11401cc10e13a92eab42a/830105b447de8e263d5881d352fcd28e.pdf',
'tour-da-roca':'https://tourdaroca.com.br/tour-da-roca-cicloturismo-piracaia-2026/',
'tvcom-running':'https://www.mauadaserra.pr.gov.br/diariooficial/publicacoes/2025/abril/edicao-2861-maua-da-serra_a1cf4c42803bdf2b82b88eecebe79753.pdf',
'uhuw-eventos':'https://stag.ticketsports.com.br/e/9-corrida-unifaccamp-88562',
'voa-esportes':'https://voaesportes.com/'
}
for id,ps in sites.items():
    c=selected.get(id,[''])[0]
    for p in ps:
        if c and c in [digits(x) for x in p.get('cnpj',[])]:primary.setdefault(id,p['url'])

# Supplementary registry fields: exact labeled facts from cited search pages only.
labels={'razao_social':['Razão Social'],'nome_fantasia':['Nome Fantasia'],'descricao_situacao_cadastral':['Situação Cadastral','Situação'],'logradouro':['Logradouro'],'numero':['Número'],'complemento':['Complemento'],'bairro':['Bairro'],'cep':['CEP'],'municipio':['Municipio','Município'],'uf':['Estado'],'data_inicio_atividade':['Data de Abertura','Data da Abertura'],'natureza_juridica':['Natureza Jurídica'],'porte':['Porte'],'ddd_telefone_1':['Telefone'],'email':['Email']}
for c in set(c for cs in selected.values() for c in cs):
    if registry.get(c,{}).get('razao_social'): continue
    candidates=[(u,b) for u,b in blocks if (c in u or fmt(c) in b) and any(x in u for x in ['casadosdados.com.br/solucao','cnpj.biz/','econodata.com.br/consulta'])]
    candidates.sort(key=lambda x:sum(bool(re.search(r'\n'+re.escape(l)+r':\s*\n?',x[1])) for ll in labels.values() for l in ll),reverse=True)
    if not candidates:continue
    u,b=candidates[0]; d={'cnpj':c,'fonte':u}
    for key,ls in labels.items():
        for l in ls:
            m=re.search(r'(?:^|\n)'+re.escape(l)+r':[^\S\n]*\n?\s*([^\n]+)',b)
            if m:
                value=m[1].split('Clique para copiar')[0].strip()
                if value.endswith(':') or value=='-':continue
                d[key]=value;break
    if not d.get('razao_social'):
        m=re.search(r'com razão social (.*?), (?:está|esta)',b,re.I)
        if m:d['razao_social']=m[1]
    if not d.get('razao_social') and 'casadosdados' in u:
        m=re.search(r'# ([^\n]+?) - (?:CNPJ |\d)',b)
        if m:d['razao_social']=m[1]
    m=re.search(r'(?:CNAE Principal:|Principal:)\s*\n?\s*([\d./-]+)\s*-\s*([^\n]+)',b)
    if m:d['cnae_fiscal']=digits(m[1]);d['cnae_fiscal_descricao']=m[2].rstrip('⇩')
    if d.get('razao_social'): registry[c]=d

# Explicit source facts that were not supplied in a labeled registry layout.
registry.setdefault('68245814000120',{})
if not registry['68245814000120'].get('razao_social'):registry['68245814000120']={'cnpj':'68245814000120','razao_social':'VOA ESPORTES LTDA','municipio':'Curitiba','uf':'PR','fonte':'https://voaesportes.com/'}
if not registry.get('55417996000127',{}).get('razao_social'):registry['55417996000127']={'cnpj':'55417996000127','razao_social':'CRONUSTEC TECNOLOGIA E SERVICOS LTDA','nome_fantasia':'Cronustec','logradouro':'R Jose Galdino Maia','numero':'193','complemento':'Térreo','bairro':'Centro','municipio':'Alagoinhas','uf':'BA','cep':'48000045','cnae_fiscal':'7312200','cnae_fiscal_descricao':'Agenciamento de espaços para publicidade, exceto em veículos de comunicação','fonte':'https://consultas.plus/lista-de-empresas/bahia/alagoinhas/'}
if not registry.get('54070504000107',{}).get('razao_social'):registry['54070504000107']={'cnpj':'54070504000107','razao_social':'BRB CRONOMETRAGEM, ESTRUTURAS E EVENTOS LTDA','nome_fantasia':'Brb Crono E Estruturas','logradouro':'Rua 06 De Marco','numero':'S/n','bairro':'Centro','municipio':'Jijoca De Jericoacoara','uf':'CE','cep':'62598000','cnae_fiscal':'7739003','cnae_fiscal_descricao':'Aluguel de palcos, coberturas e outras estruturas de uso temporário, exceto andaimes','fonte':'https://consultas.plus/lista-de-empresas/ceara/jijoca-de-jericoacoara/'}

ufs={'sao paulo':'SP','paraiba':'PB','mato grosso':'MT','amapa':'AP','bahia':'BA','para':'PA','sergipe':'SE'}
regions={'Sul':'PR RS SC','Sudeste':'SP RJ MG ES','Centro-Oeste':'GO DF MT MS','Nordeste':'BA SE AL PE PB RN CE PI MA','Norte':'AM PA AP AC RO RR TO'}
state_names=dict(ufs,**{'rio grande do sul':'RS','santa catarina':'SC','parana':'PR','minas gerais':'MG','espirito santo':'ES','rio de janeiro':'RJ','goias':'GO','distrito federal':'DF','rondonia':'RO','mato grosso do sul':'MS','rio grande do norte':'RN','ceara':'CE','piaui':'PI','maranhao':'MA','pernambuco':'PE','alagoas':'AL','amazonas':'AM'})
for d in registry.values():
    if norm(d.get('uf','')) in state_names:d['uf']=state_names[norm(d['uf'])]
def location(v):
    s=v.replace('Cidade:','').strip(); s=re.sub(r'\s+',' ',s)
    if s=='Bahia/Salvador':return 'Salvador','BA'
    for name,uf in ufs.items():
        if norm(s).endswith(name):return re.sub(r'\s*[-/]?\s*$','',s[:len(s)-len(name)]),uf
    m=re.search(r'(?:\s*[-/]\s*|\s+)([A-Za-z]{2})$',s)
    if m:return s[:m.start()].strip(),m[1].upper()
    return s,''

confirmed_org=set('3lr-eventos ar2-eventos atra-e-eventos bee-sports beta-sports bolt-producoes clube-dos-corredores correr-com-propositos fidalgo-eventos-esportivos global-vita hl-eventos-esportivos ice-sports letape-brasil metodo-grupo-chokito mp-sports-brasil noblu-sports oxe-eventos pda-esportes seven-eco top-chip tvcom-running uhuw-eventos unlimited vida-sport voa-esportes wine-run-brasil yescom zbr-events'.split())
special={'chip-macapa':('Cronometragem e organização','Cronometragem'),'cronustec':('Cronometragem e serviços para eventos','Cronometragem'),'podium-chip':('Cronometragem e inscrições','Cronometragem'),'trcrono':('Cronometragem e inscrições','Cronometragem'),'corre-paraiba':('Inscrições e serviços para eventos','Fornecedor'),'nace-producoes':('Treinamento e eventos','Outro'),'personew':('Assessoria esportiva','Assessoria'),'wx-esportes-e-negocios':('Assessoria esportiva e negócios','Assessoria'),'agencia-vqv-eventos':('Agência e organização de eventos','Agencia'),'pepper-criativa-sport-business-agency':('Marketing e projetos esportivos','Agencia'),'mp3-solucoes':('Marketing e eventos','Agencia')}
notes={
'ar2-eventos':'Fonte de inscrições usa CNPJ de MEI baixado, diferente da empresa AR2 ativa. Confirmar titular antes de vincular.',
'aclive-sports':'CNPJ histórico da marca consta BAIXADA. Solicitar CNPJ atual.',
'cia-de-eventos':'CBM-X aparece como Cia de Eventos. Há CBM matriz suspensa e filial no histórico. Confirmar a PJ atual.',
'brb-marketing-esportivo':'CNPJ do site diverge do associado à marca em diretórios. Confirmar PJ de contratação.',
'chelso-sports':'Matriz e filial encontradas. Confirmar qual unidade deve possuir a conta.',
'chl-eventos':'CNPJ novo e CNPJ em regulamento anterior. Confirmar migração da operação.',
'corre-brasil':'Foram encontradas PJ de organização de eventos e de marketplace. Selecionar a titular da conta.',
'corrente-running':'CNPJ do site consta INAPTA. Existe associação com a mesma marca. Confirmar PJ atual.',
'grupo-hjr':'Grupo com múltiplas empresas. R. Sandoval coincide com responsável divulgado, mas titular exige confirmação.',
'iguana-sports':'IGN Esportes e Iguana Mídia aparecem ligadas à marca. Confirmar PJ atual.',
'jardel-moura-assessoria-esportiva':'Há assessoria Jardel Moura e Jotate com a mesma marca. Confirmar titular.',
'nk-sports':'Candidato associado ao responsável em Jaú. Não usar homônima de Jaraguá do Sul. Confirmar marca/PJ.',
'sbs-sports':'Site indicado é Proeesp e informa CNPJ de associação, diferente de SBS Sports. Confirmar titular.',
'sportsland':'Duas empresas homônimas. Principal selecionada pelo domínio e telefone, sujeito a confirmação.',
'superacao-eventos':'CNPJ encontrado consta BAIXADA. Responsável cadastral difere do contato ABRACEO. Solicitar PJ atual.',
'tour-da-roca':'Site do evento e loja informam CNPJs diferentes. Confirmar titular da organização.',
'vega-sports':'Mais de uma PJ ligada à marca. Confirmar titular da conta.',
'x3m-entretenimento-ltda':'Matriz e filial encontradas. Razão social da base consultada é LTDA; há fonte antiga S.A.',
'run-eventos':'E-mail ABRACEO contém gmai.com. Preservado como publicado; confirmar antes de envio.',
'morro-mt':'E-mail ABRACEO inicia com dois sublinhados. Confirmar antes de envio.',
'letape-brasil':'CNPJ identificado no regulamento como PIX da organização; confirmar titular do acesso.',
'voa-esportes':'CNPJ e razão social publicados no site; situação cadastral não recuperada nesta rodada.'}

juridicas=[]; rows=[]
for m in members:
    id=m['id']; vals=m['campos_abraceo']; telefone,email,instagram,cid,reg=(vals+['']*5)[:5]
    cidade,uf=location(cid); reg=reg.replace('Regional:','').strip()
    h=(ROOT/'research'/f'{id}.html').read_text(); reps=re.findall(r'Responsável:([^<]*)',h)
    contato=plain(reps[0]) if reps else ''
    cs=selected.get(id,[]); c=cs[0] if cs else ''; d=registry.get(c,{})
    fonte_identidade=primary.get(id,'')
    if not fonte_identidade and c:
        hits=[(u,b) for u,b in blocks if c in u and any(x in u for x in ['cnpj.biz/','casadosdados.com.br/solucao','econodata.com.br/consulta'])]
        fonte_identidade=hits[0][0] if hits else d.get('fonte','')
    situacao=d.get('descricao_situacao_cadastral','').upper()
    status='Não localizado' if not c else ('Conflito / múltiplas PJs' if len(cs)>1 else ('Vínculo em fonte primária' if id in primary else 'Candidato em base pública'))
    if c and situacao and situacao!='ATIVA':status='CNPJ '+situacao
    obs=[notes[id]] if id in notes else []
    true_reg=next((k for k,v in regions.items() if uf in v.split()),'') if uf else ''
    if true_reg and reg!=true_reg:obs.append(f'Regional ABRACEO = {reg}; pela UF = {true_reg}.')
    if d.get('municipio') and norm(cidade)!=norm(d['municipio']):obs.append('Município cadastral difere da ficha ABRACEO; manter ambos até confirmação.')
    if id=='run-eventos': pass
    cnae=str(d.get('cnae_fiscal',''))
    if id in special: segmento,tipo=special[id]; evidencia='Atuação sugerida; revisar fonte'; fonte_atuacao=m['site'] or fonte_identidade
    elif id in confirmed_org:segmento,tipo='Organização de eventos esportivos','Organizador';evidencia='Evidência pública de organização';fonte_atuacao=primary.get(id) or m['site'] or fonte_identidade
    elif cnae=='9319101':segmento,tipo='Produção e promoção de eventos esportivos','Organizador';evidencia='Indício pelo CNAE principal';fonte_atuacao=d.get('fonte','')
    else:segmento,tipo='Atuação a confirmar','';evidencia='Não classificado';fonte_atuacao=''
    if id=='ice-sports':fonte_atuacao='https://goias.gov.br/policiacivil/abertas-as-inscricoes-para-a-1a-corrida-do-coracao/'
    if id=='fidalgo-eventos-esportivos':fonte_atuacao='https://www.fidalgo.esp.br/quem-somos'
    if id=='chip-macapa':fonte_atuacao='https://www.chipmacapa.com.br/empresa'
    if id=='corre-paraiba':fonte_atuacao='https://correparaiba.com.br/termos-e-condicoes-de-uso'
    documento=c if c and id in primary and len(cs)==1 and situacao=='ATIVA' and valid(c) else ''
    pend=[]
    if not c:pend.append('Localizar CNPJ e razão social')
    elif not documento:pend.append('Confirmar vínculo e situação do CNPJ')
    if not contato:pend.append('Confirmar contato nominal')
    if not email:pend.append('Localizar e-mail')
    if not telefone:pend.append('Localizar telefone')
    if not tipo or evidencia!='Evidência pública de organização':pend.append('Confirmar tipo de atuação')
    pend.append('Deduplicar no Business e confirmar responsável no primeiro acesso')
    logo=ROOT/m.get('logo_arquivo',''); im=Image.open(logo); dims=im.size
    row={'id_filiado':id,'nome_abraceo':m['nome'],'segmento':segmento,'tipo_prestador_sugerido':tipo,'evidencia_atuacao':evidencia,'cnpj_pesquisado':c,'razao_social_pesquisada':scrub(d.get('razao_social','')),'nome_fantasia_cadastral':d.get('nome_fantasia',''),'status_vinculo_cnpj':status,'situacao_cadastral_consultada':situacao,'contato_publico':contato,'email_publico':email,'telefone_publico':telefone,'cidade_abraceo':cidade,'uf_abraceo':uf,'regional_abraceo':reg,'site_abraceo':m['site'],'instagram_publicado':instagram,'endereco_cadastral':' '.join(str(d.get(k) or '') for k in ['descricao_tipo_de_logradouro','logradouro','numero','complemento']).strip(),'bairro_cadastral':d.get('bairro',''),'cep_cadastral':digits(d.get('cep','')),'municipio_cadastral':d.get('municipio',''),'uf_cadastral':d.get('uf',''),'cnae_principal':cnae,'cnae_descricao':d.get('cnae_fiscal_descricao',''),'tipo_titular_sugerido':'PJ' if c else '', 'documento_para_revisao':documento,'nome_responsavel_login':'','email_responsavel_login':'','cnpjs_alternativos':'; '.join(cs[1:]),'pendencias':'; '.join(pend),'observacoes':' '.join(obs),'fonte_abraceo':m['fonte_abraceo'],'fonte_vinculo_cnpj':fonte_identidade,'fonte_cadastro':d.get('fonte','') if d.get('razao_social') else '', 'fonte_atuacao':fonte_atuacao,'logo_url':m['logo_url'],'logo_arquivo':m.get('logo_arquivo',''),'consultado_em':'2026-10-10','logo_width':dims[0],'logo_height':dims[1]}
    rows.append(row)
    for j,cc in enumerate(cs):
        dd=registry.get(cc,{})
        juridicas.append({'id_filiado':id,'nome_abraceo':m['nome'],'cnpj':cc,'papel_na_pesquisa':'Principal pesquisado' if j==0 else 'Alternativo; confirmar','digitos_verificadores':'Válidos' if valid(cc) else 'INVÁLIDOS','razao_social':scrub(dd.get('razao_social','')),'nome_fantasia':dd.get('nome_fantasia',''),'situacao':dd.get('descricao_situacao_cadastral',''),'endereco':' '.join(str(dd.get(k) or '') for k in ['descricao_tipo_de_logradouro','logradouro','numero','complemento']).strip(),'bairro':dd.get('bairro',''),'cep':digits(dd.get('cep','')),'municipio':dd.get('municipio',''),'uf':dd.get('uf',''),'cnae_principal':str(dd.get('cnae_fiscal','')),'cnae_descricao':dd.get('cnae_fiscal_descricao',''),'natureza_juridica':dd.get('natureza_juridica',''),'porte':dd.get('porte',''),'abertura':dd.get('data_inicio_atividade',''),'fonte':dd.get('fonte','') if dd.get('razao_social') else '', 'observacao':'Consulta cadastral não confirma filiação nem titularidade da conta. '+('Dados cadastrais não recuperados; consultar fonte do vínculo.' if not dd.get('razao_social') else '')})

summary={'membros_informados_reuniao':98,'fichas_publicadas':len(rows),'diferenca_a_conciliar':98-len(rows),'com_cnpj_pesquisado':sum(bool(r['cnpj_pesquisado']) for r in rows),'com_razao_social':sum(bool(r['razao_social_pesquisada']) for r in rows),'com_email':sum(bool(r['email_publico']) for r in rows),'com_telefone':sum(bool(r['telefone_publico']) for r in rows),'com_contato_nominal':sum(bool(r['contato_publico']) for r in rows),'com_endereco':sum(bool(r['endereco_cadastral']) for r in rows),'com_logo':sum(bool(r['logo_arquivo']) for r in rows),'cnpj_fonte_primaria':sum(r['id_filiado'] in primary for r in rows),'documento_para_revisao':sum(bool(r['documento_para_revisao']) for r in rows),'multiplas_pjs':sum(bool(r['cnpjs_alternativos']) for r in rows),'cnpj_principal_nao_ativo':sum(bool(r['situacao_cadastral_consultada']) and r['situacao_cadastral_consultada']!='ATIVA' for r in rows),'pessoas_juridicas':len(juridicas)}
(ROOT/'research/prepared.json').write_text(json.dumps({'filiados':rows,'juridicas':juridicas,'resumo':summary},ensure_ascii=False,indent=2))
for name,data in [('abraceo_filiados.csv',rows),('abraceo_pessoas_juridicas.csv',juridicas)]:
    cols=[k for k in data[0] if not k.startswith('logo_width') and not k.startswith('logo_height')]
    with (ROOT/name).open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=cols,delimiter=';',extrasaction='ignore');w.writeheader();w.writerows(data)
print(json.dumps(summary,ensure_ascii=False,indent=2))
print('SEM RAZAO SOCIAL',[(r['id_filiado'],r['cnpj_pesquisado']) for r in rows if not r['razao_social_pesquisada']])
print('CNPJ INVALIDO',[(r['id_filiado'],r['cnpj']) for r in juridicas if r['digitos_verificadores']=='INVÁLIDOS'])
