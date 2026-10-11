from pathlib import Path
import base64,collections,json,re
root=Path(__file__).resolve().parents[3];base=root/'outputs/abraceo-20261010';out=base/'importacao'
p=json.loads((base/'research/prepared.json').read_text());accounts=json.loads((out/'contas-final.json').read_text());linked=json.loads((out/'eventos-linked.json').read_text())['EVENTOS'];after=json.loads((out/'eventos-after.json').read_text());payload=json.loads((out/'payload.json').read_text())
assert len(accounts)==41 and len([a for a in accounts if a['status']=='PENDENTE'])==36
newids={a['id_conta'] for a in accounts if a['id_conta']>=28}
assert len(newids)==36 and all(a['usuarios']==0 for a in accounts if a['id_conta'] in newids)
assert all(not a['email_principal'] or re.fullmatch(r'[^\s@|,;]+@[^\s@|,;]+\.[^\s@|,;]+',a['email_principal']) for a in accounts)
expected={e['id_evento']:e['id_conta'] for e in linked}
for e in after:
 links=json.loads(e['contas']); assert len(links)==1 and links[0]['id_conta']==expected[e['id_evento']] and links[0]['status']=='ATIVO'
assert len(after)==11
by_fid={a['id_origem']:a for a in accounts};lookup={(e['id_conta'],e['id_evento']):e for e in linked}
future=[]
for e in p['eventos']:
 if e['data_final']<'2026-10-11' or e['evento_ativo']!='SIM':continue
 e=e.copy(); a=by_fid.get(e['id_filiado']);key=(a['id_conta'],e['id_evento']) if a else None
 e['id_conta_importacao']=a['id_conta'] if a else None
 if key in lookup:e['resultado_importacao']='VÍNCULO CRIADO';e['pendencia_importacao']=''
 elif e['classificacao']=='JÁ VINCULADO À CONTA':e['resultado_importacao']='VÍNCULO EXISTENTE PRESERVADO';e['pendencia_importacao']=e['ressalvas']
 else:
  e['resultado_importacao']='PENDENTE';e['pendencia_importacao']='Confirmar organização e PJ responsável em fonte primária antes de vincular.'
  if e['outras_contas_ativas']:e['pendencia_importacao']='Outra conta vinculada: confirmar coexistência e responsabilidades.'
  if not a:e['pendencia_importacao']='Empresa fora dos 36 novos e 5 reaproveitados; resolver pendência cadastral antes de associar.'
  if e['id_filiado']=='corre-brasil' and e['id_evento'] in [43625,46988]:e['pendencia_importacao']='Fornecedor atribuído em Pernambuco, sem confirmação suficiente da organização pela PJ catarinense.'
 future.append(e)
counts=collections.Counter(e['resultado_importacao'] for e in future)
result={'data':'2026-10-11','contas_novas':36,'contas_reaproveitadas':5,'logos_publicados':41,'eventos_futuros_vinculados':11,'contas':accounts,'eventos_criados':linked,'revisao_eventos_futuros_em_curso':future,'contagem_revisao':dict(counts)}
(out/'resultado_business.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
lines=['ABRACEO — PRÉ-CADASTROS NO BUSINESS — 11/10/2026','','36 contas novas PENDENTE, sem usuários ou liberação de acesso.','5 contas existentes reaproveitadas, com cadastro e titulares preservados.','41 logos publicados e complementos de dados na aba Pré-cadastro.','11 novos vínculos de eventos futuros; 5 vínculos futuros preexistentes preservados.','HL Eventos: luiz@hleventos.com como principal, conforme autorização; ambos os contatos preservados no complemento.','','CONTAS']
for a in accounts:lines.append(f"{a['id_conta']} | {a['nome_conta']} | CNPJ {a['documento']} | {a['status']} | https://business.roadrunners.run/administracao/contas/?conta_id={a['id_conta']}&tab=precadastro")
lines+=['','EVENTOS FUTUROS ASSOCIADOS']
for e in linked:lines.append(f"{e['id_evento']} | {e['nome_evento']} | {e['data_inicial']} | conta {e['id_conta']}")
lines+=['','PENDÊNCIAS',f"{counts['PENDENTE']} relações candidatas de eventos futuros/em curso permanecem sem nova associação. Incluem empresas ainda sem CNPJ apto, menções por nome/site e divergências de responsabilidade.",'MP3: pessoas jurídicas distintas; sem fusão de contas.','Iguana: fornecedor com CNPJ divergente; sem transferência de eventos.','Corre Brasil: eventos de Pernambuco não associados.','Maratona de São Paulo 2027: já vinculada a outra conta; coexistência a confirmar.','','VALIDAÇÃO','Compilação ColdFusion dos dois arquivos: passou. Simulação da importação com reversão: passou.','Contagens e integridade verificadas diretamente no banco de produção.','Exibição real de logo/dados e eventos verificada na interface; largura desktop e 390px, navegação por teclado.','Logos validados por HTTPS e comparação de hash (ver logos-http-verificados.json).','','RECUPERAÇÃO','Backup de produção: /var/backups/business-abraceo-precadastro-20261011','Contas novas e vínculos identificados em release-commit.json/eventos-linked.json; arquivos anteriores em baseline/.','Antes de reverter dados, bloquear operação se contas tiverem adquirido usuários, novos vínculos ou alterações posteriores. Não excluir contas que já tenham sido utilizadas.','A tabela complementar é aditiva. Reversão de runtime pode preservar todos os dados.','','ESCOPO','Runtime: administracao/contas/home.cfm, administracao/contas/includes/perfil_publico.cfm e 41 imagens em assets/contas/abraceo/.','Dados: tb_contas, nova tb_conta_perfis_publicos e 11 inserções em tb_conta_eventos.','Não foram criados vouchers nem alterado o fluxo público de primeiro acesso. Os pré-cadastros ficam disponíveis para revisão administrativa.','Os arquivos de pesquisa anteriores são fotografias pré-importação; resultado_business.json registra o estado posterior.']
(out/'RESULTADO.txt').write_text('\n'.join(lines)+'\n')
for name,b64 in payload['files'].items():
 if name.startswith('assets/'):
  dest=root/name;dest.parent.mkdir(parents=True,exist_ok=True)
  assert not dest.exists() or dest.read_bytes()==base64.b64decode(b64)
  dest.write_bytes(base64.b64decode(b64))
print({'accounts':len(accounts),'new_links':len(linked),'future_review':dict(counts)})
