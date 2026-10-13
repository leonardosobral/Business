from pathlib import Path
import json,re,base64,hashlib
P=Path(__file__).parent; ROOT=P.parents[2]; OUT=P.parent
members=json.loads((P/'members.json').read_text());sources=json.loads((P/'research.json').read_text())+json.loads((P/'extra.json').read_text()); live=json.loads((P/'events.json').read_text());event_live={str(e['id_evento']):e for e in live['events']}
# Decisions are reviewed individually. Sources prove organizer activity, not current legal ownership.
confirmed={
'agencia-vqv-eventos':('5d21daa398277377.txt','Instituto de turismo de Maringá identifica a agência como organizadora de eventos. Não foi confirmado evento esportivo futuro.'),
'apuana-esportes':('56f969e0edd2f2f8.txt','Site institucional apresenta organização de corridas e portfólio próprio, incluindo Circuito Uberlândia Corre.'),
'ar2-eventos':('5ff8d674ccc4c1be.txt','Regulamentos identificam AR2 como responsável pelas provas e suas decisões operacionais.'),
'assessorar-producoes-festivas':('https://www.alagoinhas.ba.gov.br/index.php/saae-e-prefeitura-realizam-1a-corrida-da-agua-e-encerram-programacao-do-dia-mundial-da-agua-em-alagoinhas/','Prefeitura de Alagoinhas confirma a Assessorar Produções como organizadora da Corrida da Água.'),
'atra-e-eventos':('https://atraeeventos.com.br/','Site oficial descreve organização de eventos esportivos e apresenta calendário de corridas.'),
'avatar':('https://jogandojuntos.com.br/organizadora-de-corridas-de-rua-na-regiao-e-premiada/','Reportagem sobre premiação identifica Avatar Sports como organizadora e Sylvio Bitencourt como responsável, compatível com ABRACEO.'),
'capa-eventos':('f85aa779663f7269.txt','Regulamento da Maratona de Londrina declara organização e realização da Capa Eventos.'),
'chip-macapa':('49a15c24faecd37c.txt','Regulamento da Corrida do Comércio de Santana atribui responsabilidade de organização à CDL Santana e Chip Macapá. A atuação de cronometragem em outras provas não foi generalizada.'),
'chl-eventos':('f0666ff82d6c7c75.txt','Site oficial descreve planejamento, produção e execução de corridas pela CHL.'),
'cia-de-eventos':('55d1387775a3ca04.txt','Página de inscrição da Ultramaratona Bertioga Maresias identifica Cia de Eventos como organizador e o mesmo contato público. Evidência histórica. CNPJ pesquisado baixado não usado como titular.'),
'conceito-solucoes-esportivas':('dfd808357f70c3fb.txt','Regulamento da Meia da Conceição atribui a organização à Conceito Soluções Esportivas.'),
'corrente-running':('0adbae4947ee34e4.txt','Site oficial identifica organização de corridas em Belém pela Corrente Running. CNPJ pesquisado inapto não usado como titular.'),
'cpr-eventos-e-producoes':('fcfd59db4b8cb74d.txt','Regulamento RJ Half Marathon identifica realização e organização da CPR Eventos e Produções.'),
'dbueno-eventos':('e29ae6112162aede.txt','Site institucional descreve produção e organização de eventos pela DBueno.'),
'dto-sports-eventos-esportivos-e-marketing':('cda07ed1b50009ff.txt','Regulamento identifica a DTO Sports como empresa organizadora e responsável pelas decisões da prova.'),
'fg-eventos':('d793f42a53c775b9.txt','SINAIT identifica FG Assessoria Esportiva e Veridiana Ferraz como responsáveis pela organização da Corrida contra a Escravidão, compatíveis com o contato ABRACEO. Evidência histórica.'),
'fidalgo-eventos-esportivos':('43e3852ca5453a2d.txt','Regulamento da Corrida do Melo distingue realização da Prefeitura e organização da Fidalgo. Data divergente impede vínculo com a edição futura.'),
'g2p-eventos':('52aab0e3ebe7bfc2.txt','Regulamentos próprios da G2P identificam a responsável pelo percurso, inscrições e condução das provas.'),
'grupo-hjr':('a1fbba77c121a390.txt','Site oficial descreve produção e realização de eventos, inclusive esportivos. Nenhuma prova futura individual teve vínculo confirmado.'),
'ideal-5k':('e628bd5ed1fe1d7b.txt','Regulamentos declaram expressamente organização das provas pela Ideal 5k Sports.'),
'maria-isabel-eventos':('f9485648a5a6f5f4.txt','Regulamento da Corrida Colorida identifica Maria Isabel Eventos e sua comissão organizadora.'),
'mountain-do':('a48c634716db6287.txt','Site oficial da marca identifica Sports Do como organizadora responsável pelos eventos Mountain Do. Cadastro da marca com operador identificado, sem presumir CNPJ atual.'),
'nace-producoes':('70b66ed94c3dbff0.txt','Regulamento oficial Vai Corinthians identifica NACE Produções como empresa responsável pela realização, separada dos apoiadores institucionais. Titular atual permanece pendente.'),
'on-eventos-esportivos':('84bfa9ce76d976e0.txt','Regulamento Farol Fast Marathon distingue promoção Cortuba e organização ON Sports.'),
'pace-3-eventos-esportivos':('a6714521066f84a8.txt','Site oficial apresenta a Pace3 como empresa de promoção e execução de eventos esportivos.'),
'pace-eventos':('d2c3e9bf17d29d29.txt','Regulamento da Maratona de Vitória identifica PACE Eventos Ltda como organizadora.'),
'partiu-corrida':('eda0e60dade9a10e.txt','Regulamento da Corrida No Seu Ritmo distingue realizadores Ativamente e 96FM da organizadora Partiu Corrida.'),
'pepper-criativa-sport-business-agency':('https://www.ticketsports.com.uy/e/sorocaba-speed-run-full-life-2026-74787','Página oficial de inscrição identifica Pepper Sports como organizador e relaciona evento do mesmo produtor como Pepper Criativa Sports. Papel de marketing em outra prova não foi usado para vínculo.'),
'personew':('https://www.personew.esp.br/calendario','Calendário oficial identifica Personew como organizadora da Patrocínio Outono Run. Página Irmãos Patrocínio também traz seu logotipo em Organização.'),
'podium-sport':('bee13cc01e6e52d9.txt','Página de inscrição e regulamento identificam Podium Sport Eventos como produtor responsável pela Maratona YoPro.'),
'ponto-org-org':('1c4b9d9bf3a8a81b.txt','Site institucional apresenta criação e execução de eventos esportivos próprios e cuidado de todos os processos de organização.'),
'proworld':('948a164a662753e4.txt','Regulamento do Circuito Distritos de Campinas identifica organização da Proworld em conjunto com a Prefeitura.'),
'quanta-esportes-e-eventos':('285019a398bd819e.txt','Regulamento Circuito das Cidades Lagoa Santa identifica promoção e organização da Quanta Esportes e Eventos.'),
'rav-sports':('28e559a048404c27.txt','Regulamento da Corrida do Coração SOCERON declara organização da RAV Sports e equipe de apoio SOCERON.'),
'rg':('226877251d6b9ebb.txt','Regulamento Feira Night Run identifica RG+ como organizadora.'),
'run-eventos':('ec23abf6893b5104.txt','Site oficial identifica criação, planejamento, produção e realização de eventos esportivos, da estratégia à operação.'),
'run-sports':('bd27f7ddc319dc53.txt','Regulamentos identificam Run Sports como idealizadora, realizadora e organizadora das provas.'),
'runk-marketing-esportivo-ltda':('9f5c8f5974015a6c.txt','Regulamento Corrida Cinderela identifica Runk Sports como organizadora. Cabeçalho 2026 e data 2027 divergem; evento separado.'),
'sagaz-esportes':('c23a2e878dcc97f5.txt','Regulamento Urban Trail Run identifica organização Sagaz Esportes. Divergências de data ou edição dos candidatos impedem associação automática.'),
'speed-producoes-e-eventos':('e525efee450f8b63.txt','Regulamento SOEA distingue realizadores da Speed, responsável pela produção técnica e operacional, chamada Organização.'),
'spiridon-eventos':('229e450fad8c2319.txt','Regulamento da prova identifica organização Dream e Spiridon. CNPJ e relação societária entre as marcas não presumidos.'),
'sports360o-eventos-esportivos':('3b1cdf0aa67baa0e.txt','Site institucional descreve criação, planejamento, gerenciamento e execução de eventos esportivos.'),
'taboada-runners':('https://www.taboadarunners.fit/','Site institucional descreve serviço de organização de corridas de rua. Consulta indexada; acesso direto indisponível.'),
'to-goal-sports':('a43cba5fbca35189.txt','Regulamento Casa das Correias distingue realizador da organizadora To Goal Sports.'),
'ttk-marketing':('8cad156cb3b1aa1a.txt','Site institucional declara organização e realização de eventos esportivos, incluindo corridas de rua.'),
'wx-esportes-e-negocios':('https://wxesportes.com.br/','Site oficial descreve organização e realização de eventos, planejamento, logística e coordenação operacional.'),
'zbr-events':('c830ecab4b651497.txt','Regulamento oficial Guarani Race identifica ZBR Events como empresa organizadora.')
}
pending={
'amigos-do-horto-eventos':'Regulamento traz contato técnico e reembolso da Amigos do Horto, mas não identifica nominalmente o responsável pela organização; confirmar papel além da promoção do shopping.',
'cronustec':'Site consultado confirma serviços de cronometragem. Não foi obtida confirmação suficiente de responsabilidade como organizadora.',
'mmb-eventos-esportivos':'Regulamento distingue realização MMB da organização Instituto Meninos do Pôr do Sol. Confirmar papel operacional e titular responsável antes de criar conta de organizador.',
'mp3-solucoes':'Possível relação com conta existente MP3 Marketing (id 5), com CNPJ distinto. Não criar duplicata nem reaproveitar conta sem confirmação de identidade.',
'nk-sports':'Referências de terceiros indicam organização da Corrida Santa Casa Araraquara; página primária de inscrição não disponibilizou informação suficiente nesta revisão.',
'premium':'Site institucional indisponível e fontes localizadas insuficientes para confirmar atuação e identidade da organizadora.',
'soulmais':'Regulamentos trazem e-mail de produção e atendimento. Confirmar a responsabilidade pela organização antes de atribuir conta e provas à marca.',
'tm4-sports-business':'Referência localizada para TM4/Thiago Mansur não foi conciliada com Thiago de Oliveira informado pela ABRACEO. Confirmar identidade e responsável atual.'
}
assert len(confirmed)+len(pending)==55
rows=[]
for m in members:
 k=m['id_filiado'];r=dict(m)
 if k in confirmed:
  src,why=confirmed[k];found=next((x for x in sources if x.get('file')==src),None)
  r.update(status_organizacao='CONFIRMADO',evidencia_organizacao=why,fonte_organizacao=found['url'] if found else src,arquivo_evidencia=src if found else '',status_documento='CNPJ PENDENTE DE CONFIRMAÇÃO',acao_revisada='CRIAR PRÉ-CADASTRO PJ PENDENTE',status_pre_cadastro='PENDENTE DE CNPJ E REPRESENTANTE')
 else:r.update(status_organizacao='PENDENTE',evidencia_organizacao=pending[k],fonte_organizacao=next((x['url'] for x in sources if x['id']==k),m['fonte_abraceo']),status_documento='NÃO VALIDADO',acao_revisada='SEPARADO PARA CONFIRMAÇÃO')
 r['revisado_em']='2026-10-11';rows.append(r)
# Only explicitly reviewed future editions are eligible. Others remain in the review inventory.
approved=set(map(str,[46873,46047,47453,47780,45894,45279,46883,47406,47443,43242,46568,44270,46607,41123,47957,46210,47971,46928,44834,45899,47657,44158,43664,45000,43669,38361,42366,47146,46059,46060,46064,45663,36657,45365,47877,48990,44998,47686,36658,39399,47687,48978,47672,48085,48240,47888,48511]))
issues={'47202':'Regulamento atribui organização à ONG Carlos Daniel. Chip Macapá não confirmado como coorganizador.','44821':'Data do regulamento 09/08/2026 diverge do cadastro 02/05/2027. Não usar regulamento da edição antiga.','46516':'Regulamento informa 05/12/2025 e cadastro 05/12/2026.','48419':'Cabeçalho da prova indica 2026, enquanto data interna e cadastro indicam 31/01/2027. Confirmar edição.','48717':'Cadastro indica 2ª edição e regulamento 1ª edição.','39849':'Regulamento informa 02/08/2026 e cadastro 22/11/2026.','38571':'Regulamento identifica Etapa 2 e cadastro Etapa 3.','39395':'Realização MMB e organização de outro instituto; não atribuir automaticamente.','40716':'Regulamento consultado não identifica nominalmente a Fidalgo como organizadora.'}
events=[]
for x in sources:
 e=x.get('event');
 if not e or e['data_inicial']<='2026-10-11':continue
 e=dict(e); eid=e['id_evento'];e['fonte_confirmacao']=x['url'];e['status_revisao']='CONFIRMADO' if eid in approved and e['id_filiado'] in confirmed else 'PENDENTE'
 if eid in ['47888','48511']:e['fonte_confirmacao']='https://zbrevents.com.br/'+('igt23k/regulamento/' if eid=='47888' else 'guaranirace/pita/regulamento')
 e['motivo_revisao']='Organizador responsável e edição futura confirmados na fonte.' if e['status_revisao']=='CONFIRMADO' else issues.get(eid,'Não foi obtida confirmação suficiente do organizador responsável e da edição futura na fonte consultada.')
 if eid=='47146':e['motivo_revisao']='Organização PACE confirmada. Regulamento inclui 28 e 29/08/2027; o evento cadastrado corresponde à maratona de 29/08.'
 if eid=='47686':e['motivo_revisao']='Organização Run Sports confirmada. Há erro de digitação 20256; a cláusula de largada confirma 18/10/2026.'
 now=event_live[eid];assert now['data_inicial']==e['data_inicial'] and now['ativo'];assert not now['contas']
 events.append(e)
assert len({e['id_evento'] for e in events})==len(events)
(OUT/'revisao_empresas.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2));(OUT/'revisao_eventos.json').write_text(json.dumps(events,ensure_ascii=False,indent=2))
print({'empresas_revisadas':len(rows),'organizadores_confirmados':len(confirmed),'empresas_pendentes':len(pending),'eventos_candidatos':len(events),'eventos_confirmados':sum(e['status_revisao']=='CONFIRMADO' for e in events)})
