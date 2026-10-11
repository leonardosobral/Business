from pathlib import Path
from datetime import datetime
from zoneinfo import ZoneInfo
import json,re,shutil
STAGE=Path(__file__).resolve().parent
for name in ('seo-circuit-intent-20261004','seo-date-ninth-20261004','seo-shared-assets-20261004'):
    assert json.loads((STAGE.parent/name/'handoff.json').read_text())['status']=='published_and_verified'

def cfstr(value):
    return '"'+value.replace('"','""').replace('#','##')+'"'

def item_blocks(source):
    start=source.index('    items = [')+len('    items = [')
    depth=0;quoted=False;begin=None;i=start
    while i<len(source):
        ch=source[i]
        if ch=='"':
            if quoted and i+1<len(source) and source[i+1]=='"':i+=2;continue
            quoted=not quoted
        elif not quoted:
            if ch=='{' and depth==0:begin=i
            if ch=='{':depth+=1
            if ch=='}':
                depth-=1
                if depth==0:yield begin,i+1,source[begin:i+1]
            if ch==']' and depth==0:return
        i+=1
    raise AssertionError('Items array not closed')

def revise(source,ident,changes):
    found=[(a,b,s) for a,b,s in item_blocks(source) if re.search(r'\bid\s*=\s*"'+re.escape(ident)+'"',s)]
    assert len(found)==1,ident
    a,b,block=found[0]
    for field,value in changes.items():
        pattern=r'(\b'+re.escape(field)+r'\s*=\s*)"(?:[^"\n]|"")*"'
        block,count=re.subn(pattern,lambda m:m.group(1)+cfstr(value),block,count=1)
        assert count==1,(ident,field)
    return source[:a]+block+source[b:]

def current(source,ident,field):
    block=next(s for _,_,s in item_blocks(source) if re.search(r'\bid\s*=\s*"'+ident+'"',s))
    value=re.search(r'\b'+field+r'\s*=\s*"((?:[^"\n]|"")*)"',block).group(1)
    return value.replace('""','"').replace('##','#')

def render(item):
    rows=[]
    for key,value in item.items():
        if isinstance(value,bool):value='true' if value else 'false'
        elif key=='sites':value='['+', '.join(map(cfstr,value))+']'
        elif key=='urls':value='['+', '.join('{url = '+cfstr(x['url'])+', label = '+cfstr(x['label'])+'}' for x in value)+']'
        else:value=cfstr(value)
        rows.append('            '+key+' = '+value)
    return '        {\n'+',\n'.join(rows)+'\n        },\n'

q=STAGE/'candidate/portal/includes/seo_queue_data.cfm'
s=(STAGE/'baseline/portal/includes/seo_queue_data.cfm').read_text()
assert len(list(item_blocks(s)))==29
items=[
 dict(resolved=False,id='RR-24',sites=['roadrunners'],priority='p1',priorityLabel='P1 · Disponibilidade',
 title='Estabilizar o servidor após saturação recorrente',
 summary='O acesso foi recuperado após saturação dos trabalhadores Apache; a causa permanente da recorrência ainda precisa ser demonstrada.',
 impact='Indisponibilidade pode impedir a entrega de páginas a usuários e rastreadores, mesmo quando metadados e sitemaps estão corretos.',
 owner='RunnerHub — infraestrutura e desempenho da aplicação',rule='availability.apache-workers',
 evidence='Em 04/10, duas ocorrências de indisponibilidade levaram à recuperação do Apache. Na ocorrência mais recente, início e arquivo estático não responderam; Apache tinha 148 trabalhadores ocupados e dois livres de 150, com aviso de limite de trabalhadores no log. A amostra agregada incluía requisições de eventos, APIs, resultados, busca e estado; isso não demonstra ataque nem identifica a causa. Configuração validada antes do reinício exclusivo do Apache, conforme autorização anterior. Serviço ativo após reinício; 121 segundos depois, um trabalhador ocupado e 74 livres, início HTTP 200 em 0,187 s. Nenhuma mudança em ColdFusion, configuração, credenciais ou Cloudflare. A recuperação pontual não encerra esta frente.',
 acceptance='Identificar a origem da retenção dos trabalhadores, corrigir a causa comprovada dentro do escopo autorizado e verificar disponibilidade sob tráfego real. Registrar períodos e fontes das medições; não prometer estabilidade com uma única resposta rápida.',
 urls=[dict(url='https://roadrunners.run/',label='Início — controle de disponibilidade')],stateLabel='Parcial — acesso recuperado; causa e estabilidade pendentes'),
 dict(resolved=True,id='RR-23',sites=['roadrunners'],priority='p2',priorityLabel='P2 · Recursos compartilhados',
 title='Compactar cinco recursos próprios compartilhados',
 summary='Cinco arquivos CSS/JavaScript passaram a ser entregues em versões compactadas, preservando fontes originais e comportamento.',
 impact='Reduz bytes dos recursos próprios apontados na amostra Semrush de arquivos sem minificação.',owner='RoadRunners — recursos de interface',rule='semrush.135; first-party-assets',
 evidence='Amostra de dez ocorrências do alerta 135 identificou cores.css, rr-audience-privacy.css/js, runnerhub-footer.css e runnerhub-entry-prompts.js, repetidos em diversas páginas. Versões geradas com compactação de espaços; arquivos originais preservados. Total bruto dos cinco arquivos: 42.208 para 33.932 bytes, redução aproximada de 19,6%; não é medição de transferência comprimida nem de Core Web Vitals. Vinte e dois cenários de comportamento passaram nos originais e nas versões compactadas; quatro templates compilados e nove verificações Adobe de referências aprovadas. Nove arquivos publicados com baseline e backup. Sete páginas e cinco recursos públicos responderam 200, com hashes dos recursos e metadados das páginas verificados. Estilos de desktop e celular permaneceram iguais nos elementos comparados; consentimento de privacidade preservado. O total de 2.809 ocorrências do fornecedor continua histórico e depende de nova auditoria.',
 acceptance='Entrega publicada e verificada em 04/10. Confirmar redução das ocorrências em nova auditoria Semrush, sem alterar o snapshot nem atribuir automaticamente ganho de ranking ou pontuação.',
 urls=[dict(url='https://roadrunners.run/circuitocatarinense/corridaderua/',label='Controle de recursos publicados')],stateLabel='Publicado e verificado — efeito na auditoria ainda não medido'),
 dict(resolved=True,id='RR-22',sites=['roadrunners'],priority='p2',priorityLabel='P2 · Intenção e estrutura',
 title='Distinguir as páginas de corrida de rua e trail run',
 summary='Os rankings catarinenses têm títulos e descrições próprios por modalidade e ano, com um único H1 por página.',
 impact='Explicita a intenção das páginas de ranking e diferencia as modalidades relacionadas à oportunidade SR-03.',owner='RoadRunners — Circuito Catarinense',rule='metadata.modality; heading.primary; semrush.opportunity.SR-03',
 evidence='Antes da alteração, as duas páginas tinham o mesmo título, a mesma descrição e dois H1 cada. Publicados títulos e descrições específicos de corrida de rua e trail run para 2026, ano já apresentado pelo ranking. O nome do logo deixou de ser H1; o título principal recebeu prefixo acessível do circuito, preservando aparência. Dois templates compilados e expressões de metadados renderizadas. Ambas as páginas públicas responderam 200, com um H1 e metadados distintos. Consultas, classificação, seis tabelas de cada página, canonical e robots preservados. Desktop e celular conferidos. Nenhum dado ou URL foi alterado; não comprova melhora de posição para SR-03.',
 acceptance='Entrega técnica publicada e verificada em 04/10. Acompanhar a página regional de Santa Catarina e efeito nas buscas separadamente; esta entrega não encerra toda a oportunidade SR-03.',
 urls=[dict(url='https://roadrunners.run/circuitocatarinense/corridaderua/',label='Corrida de rua'),dict(url='https://roadrunners.run/circuitocatarinense/trailrun/',label='Trail run')],stateLabel='Publicado e verificado — intenção por modalidade e ano')
]
for item in items:assert 'id = "'+item['id']+'"' not in s
s=s.replace('    items = [\n','    items = [\n'+''.join(map(render,items)),1)
ninth=' Nono lote factual publicado em 04/10: 29 datas de percursos em 15 eventos, conforme páginas e regulamentos oficiais individualmente conferidos. Início e término gerais e demais campos dos eventos preservados. Trinta e um IDs mantidos, incluindo dois percursos excluídos da correção por ausência de comprovação da distância/identidade: UNINTA Itapipoca 21 km e AB Run 2,6 km. Aplicação, inversão e rejeição de conflito ensaiadas; hashes dos eventos e percursos e treze tabelas de dependências conferidos. Quarenta e cinco URLs PT/EN/ES responderam 200 com canonical, alternates e JSON-LD preservados. Recontagem atual: 86 percursos em 48 eventos futuros fora do intervalo, para revisão factual; não são 86 erros confirmados nem alertas do Google.'
s=revise(s,'SH-02',{'evidence':current(s,'SH-02','evidence')+ninth,'summary':'Datas e fontes foram corrigidas em nove lotes comprovados. A recontagem mais recente conserva 86 percursos em 48 eventos para revisão; fontes conflitantes ou sem identidade suficiente não autorizam alterações. Fontes, revisões e histórico estão disponíveis no cadastro.','stateLabel':'Parcial — 86 percursos em 48 eventos para revisão; demais fatos pendentes'})
s=revise(s,'RR-20',{
 'evidence':current(s,'RR-20','evidence')+' Conferências posteriores: navegador real mostrou os links finais mailto nas páginas de privacidade PT/EN/ES, sem placeholders /cdn-cgi; na página do evento da amostra não havia link protegido nem mailto no DOM atual. Proteção de e-mail mantida e nenhum contato enviado. ABAVSE 2027 contém aviso de adiamento de 09/08/2026 para 02/05/2027; o PDF vinculado ainda mostra a data antiga. A fonte ao vivo não confirmou integralmente a identidade das duas URLs; não revertida a data nem criado redirect por inferência. Busca filtrada respondeu 200 em 2,11 s na verificação mais recente, contra cerca de 0,36 s em observações anteriores; a instabilidade recorrente está registrada em RR-24. Metadados dos circuitos e cinco recursos próprios compactados foram entregues em RR-22/RR-23. Essas verificações não substituem a nova auditoria do fornecedor.',
 'acceptance':'Confirmar ranking e recursos publicados em nova auditoria; investigar estabilidade da busca e do servidor em RR-24. Reconciliar ABAVSE com fonte atual e identidade comprovada antes de corrigir título, data ou redirect. Links de contato funcionaram no navegador; confirmar o comportamento do rastreador sem desligar proteção ou excluir regras para elevar a nota. Preservar os nove erros históricos até nova coleta.'})
now=datetime.now(ZoneInfo('America/Sao_Paulo'))
s=re.sub(r'updatedAt = "[^"]+"','updatedAt = "'+now.isoformat(timespec='seconds')+'"',s,count=1)
s=re.sub(r'updatedLabel = "[^"]+"','updatedLabel = "'+now.strftime('%d/%m/%Y às %H:%M')+' (Brasília)"',s,count=1)
blocks=list(item_blocks(s));assert len(blocks)==32
assert sum(bool(re.search(r'\bresolved\s*=\s*true',b)) for _,_,b in blocks)==24
q.write_text(s)
v=STAGE/'candidate/portal/conteudo/seo_semrush.cfm';s=(STAGE/'baseline/portal/conteudo/seo_semrush.cfm').read_text()
idx=s.index('  <p class="seo-note">Melhoria posterior à auditoria:');end=s.index('</p>',idx)+4
note='\n  <p class="seo-note">Outras entregas posteriores à coleta: títulos e H1 dos circuitos em <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-22">RR-22</a>, cinco recursos próprios compactados em <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-23">RR-23</a> e 29 datas de percursos conferidas em <a href="/portal/seo/?aba=fila&amp;site=roadrunners##SH-02">SH-02</a>. A disponibilidade permanece pendente em <a href="/portal/seo/?aba=fila&amp;site=roadrunners##RR-24">RR-24</a>: acesso recuperado não comprova estabilidade. Os totais do Semrush acima mantêm a data da coleta.</p>'
s=s[:end]+note+s[end:]
s=s.replace('Nenhuma destas ações está marcada como concluída.','SR-03 recebeu a melhoria de intenção dos circuitos em RR-22; a análise regional e os efeitos em posições continuam pendentes. As demais oportunidades permanecem em investigação.')
v.write_text(s)
template=STAGE.parent/'seo-ranking-performance-panel-20261004'
shutil.copyfile(template/'release.py',STAGE/'release.py')
p=STAGE/'release.py';p.write_text(p.read_text().replace('seo-ranking-performance-panel-20261004','seo-autonomous-panel-20261004'))
shutil.copyfile(template/'verify_panel.py',STAGE/'verify_panel.py')
p=STAGE/'verify_panel.py';s=p.read_text().replace("'29 frentes'","'32 frentes'").replace("'22 concluídas'","'24 concluídas'").replace("'7 pendentes'","'8 pendentes'")
s=s.replace("assert '114 percursos em 60 eventos futuros' in rendered['queue']","assert '86 percursos em 48 eventos futuros' in __import__('html').unescape(rendered['queue'])\nassert 'id=\"RR-22\"' in rendered['queue'] and 'id=\"RR-23\"' in rendered['queue'] and 'id=\"RR-24\"' in rendered['queue']\nassert 'causa e estabilidade pendentes' in __import__('html').unescape(rendered['queue'])\nassert '/portal/seo/?aba=fila&amp;site=roadrunners#RR-24' in h\nassert 'SR-03 recebeu a melhoria' in h")
p.write_text(s)
print(json.dumps({'items':32,'resolved':24,'pending':8,'semrush_score_unchanged':76,'snapshot_errors_unchanged':9}))
