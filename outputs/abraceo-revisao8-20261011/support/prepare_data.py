from pathlib import Path
import json,base64,hashlib
P=Path(__file__).parent;ROOT=P.parents[2]
rows=json.loads((P/'original-eight.json').read_text()); sources=json.loads((P/'sources/sources.json').read_text())+json.loads((P/'sources/sources-extra.json').read_text());src={r.get('file',''):r['source'] for r in sources}
evidence={
'amigos-do-horto-eventos':('horto-ticket.html','Página primária Ticket Sports identifica Amigos do Horto Eventos Esportivos como organizador da Kids Trimais Places de 12/10/2026. Regulamento anterior da Corrida de Escada também nomeia expressamente a organizadora.'),
'cronustec':('cronustec.html','Site oficial declara serviços de organização, realização e assessoria de corridas de rua, além da cronometragem; e-mail coincide com a ABRACEO. Não se atribuem automaticamente as provas apenas cronometradas.'),
'mmb-eventos-esportivos':('mmb-ticket.html','Página primária Ticket Sports identifica MMB Eventos Esportivos como organizadora e a ABRACEO vincula a marca à Maratona Monumental. Cadastro da marca confirmado; vínculo operacional da edição 2026 separado porque o regulamento nomeia Instituto Meninos do Pôr do Sol como organização e MMB como realização.'),
'nk-sports':('nk-ticket.html','Dados públicos estruturados SportsEvent da Ticket Sports identificam NK SPORTS como organizador da 2ª Corrida Santa Casa Araraquara 2026. Contato nominal para convite mantido da ABRACEO; não usado e-mail da cronometragem.'),
'premium':('premium-future.html','Regulamento oficial da Meia Maratona dos Reis Magos de 18/10/2026 nomeia Premium Comunicação e Marketing Ltda como organizadora. Domínio de atendimento premium.srv.br coincide com os contatos ABRACEO.'),
'soulmais':('assai-48766.pdf','Comunicado oficial do Assaí identifica Soul+ Esportes como responsável por produção, organização e promoção da Corrida Assaí Fortaleza 2025. Regulamentos de Teresina e Vitória 2026 confirmam realização Soul+ Esportes e contato no mesmo domínio. Papel operacional das edições 2026 separado: catálogo indica Instituto Novos Talentos.'),
 'tm4-sports-business':('tm4.html','Site oficial TM4 descreve organização de eventos, incluindo Meia Maratona Internacional de Florianópolis. Marca, cidade, domínio tm4.business e telefone (48) 99822-5595 coincidem com a ABRACEO. Nome do contato permanece como publicado pela ABRACEO; não se presume equivalência pessoal entre Thiago de Oliveira e Thiago Mansur.')}
confirmed=[];files={}
for r in rows:
 r['revisado_em']='2026-10-11'
 if r['id_filiado']=='mp3-solucoes':
  r.update(status_organizacao='CONFIRMADO — CONTA/PJ PENDENTE',acao_revisada='SEPARADO — NÃO CRIAR NEM FUNDIR',evidencia_organizacao='Atuação confirmada por Permit CBAt Ouro 06/2025 para 21k Salvador. E-mail e telefone ABRACEO coincidem com conta Business 5 (MP3 Marketing). Conta usa CNPJ 28434613000156; pesquisa do filiado indica 11194903000177. Mesmo contato e sócios não tornam duas PJs equivalentes. Confirmar com Douglas qual conta/PJ deve representar o filiado antes do convite.',fonte_organizacao='https://corridamarcozero.com.br/wp-content/uploads/2025/07/CBAT_NOTA_OFICIAL_HOMOLOGAC%CC%A7A%CC%83O.pdf',pendencias='Confirmar com Douglas se filiado deve usar conta 5 / CNPJ 28434613000156 ou conta distinta / CNPJ 11194903000177. Não emitir voucher até definir destinatário empresarial.')
  continue
 name,reason=evidence[r['id_filiado']]
 r.update(status_organizacao='CONFIRMADO',evidencia_organizacao=reason,fonte_organizacao=src[name],arquivo_evidencia='sources/'+name,status_documento='CNPJ PENDENTE DE CONFIRMAÇÃO',status_pre_cadastro='PENDENTE DE CNPJ E REPRESENTANTE',acao_revisada='CRIAR PRÉ-CADASTRO PJ PENDENTE',pendencias='Confirmar CNPJ e razão social do titular atual e representante. Documento pesquisado não vinculado como titular.')
 if r['id_filiado']=='soulmais':r['fontes_complementares']=['https://www.assai.com.br/imprensa/corrida-assai-em-fortaleza-dobra-de-tamanho-e-abre-novo-lote-de-inscricoes',src['assai-48783.pdf']]
 if r['id_filiado']=='tm4-sports-business':r['pendencias']+=' Confirmar nome completo do representante; não presumir equivalência dos nomes publicados.'
 email=r['email_publico'].split(' / ')[0].lower().strip();phone=r['telefone_publico']
 if r['id_filiado']=='premium':phone='(27) 98146-7060';r['motivo_email']='Roberta é a responsável nominal publicada pela ABRACEO. Bruno mantido como contato adicional.'
 else:r['motivo_email']='Contato literalmente publicado na ficha do filiado na ABRACEO, consultada em 11/10/2026; entrega não testada.'
 original=ROOT/'outputs/abraceo-20261010'/r['logo_arquivo'];ext=original.suffix.lower().replace('.jpeg','.jpg');logo='/assets/contas/abraceo/'+r['id_filiado']+ext
 files[logo.lstrip('/')]=base64.b64encode(original.read_bytes()).decode()
 confirmed.append(dict(id_filiado=r['id_filiado'],nome_empresa=r['nome_abraceo'],email=email,telefone=phone,logo_path=logo,dados=r))
events=[]
for id,slug,source in [(47688,'amigos-do-horto-eventos',src['horto-ticket.html']),(45413,'premium',src['premium-future.html'])]:
 e=next(x for x in json.loads((P/'event-details.json').read_text())['events'] if x['id_evento']==id);assert not e['contas'];e.update(id_filiado=slug,fonte_confirmacao=source);events.append(e)
for r in confirmed:r['dados']['eventos_confirmados']=[e['id_evento'] for e in events if e['id_filiado']==r['id_filiado']]
payload=dict(rows=confirmed,events=events,files=files,hashes={n:hashlib.sha256((ROOT/n).read_bytes()).hexdigest() for n in ['estudos/includes/FirstAccess.cfc','estudos/includes/StudyAccess.cfc','administracao/contas/includes/perfil_publico.cfm']})
(P/'payload.json').write_text(json.dumps(payload,ensure_ascii=False));(P.parent/'revisao_8.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2));print({'confirmed':len(confirmed),'pending':len(rows)-len(confirmed),'future_links':len(events)})
