from pathlib import Path
import json
W=Path(__file__).resolve().parent

def read(n):return(W/'baseline'/n).read_text()
def out(n,text):
 p=W/'runtime'/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text)
s=read('estudos/lancamento/index.cfm').replace('20261104-responsaveis','20261104-lista-plano')
s=s.replace('Defina quem cuida de cada etapa e registre pendências nas observações. Clique em “Salvar informações” para compartilhar com a equipe. A validação continua independente: marque após conferir a conclusão; desmarque para reabrir.','Veja o próximo passo de cada etapa na lista. Abra “Ver observações e editar” para consultar o que está pronto, as pendências e o responsável. Salve as informações para compartilhar com a equipe; valide a etapa quando estiver concluída.')
a=s.index('<div class="timeline launch-checklist">');b=s.index('</article></cfloop></cfoutput></div>',a)+len('</article></cfloop></cfoutput></div>')
markup='''<div class="launch-checklist launch-list"><cfoutput><cfloop array="#launchChecklist.steps#" index="launchStep">
<cfset launchPreview=listFirst(replace(launchStep.notes,chr(13),'','all'),chr(10))/>
<cfif len(launchPreview) GT 260><cfset launchPreview=left(launchPreview,257) & '…'/></cfif>
<article id="etapa-#encodeForHTMLAttribute(launchStep.key)#" class="launch-step<cfif launchStep.key EQ 'lancamento'> launch</cfif><cfif launchStep.key EQ 'contrato-abraceo'> contract</cfif><cfif launchStep.completed> is-complete</cfif>">
<div class="step-row-header"><time>#encodeForHTML(launchStep.date)#</time><h3>#encodeForHTML(launchStep.title)#</h3><div class="step-assignee"><span>Responsável</span><strong data-responsible-summary><cfif len(trim(launchStep.responsible))>#encodeForHTML(launchStep.responsible)#<cfelse>A definir</cfif></strong></div>
<div class="step-completion"><label class="step-validation"><input type="checkbox" data-launch-step="#encodeForHTMLAttribute(launchStep.key)#" data-version="#encodeForHTMLAttribute(launchStep.version)#" aria-label="Validar: #encodeForHTMLAttribute(launchStep.title)#"<cfif launchStep.completed> checked</cfif> disabled><span data-step-label><cfif launchStep.completed>Etapa validada<cfelse>Validar etapa</cfif></span></label>
<p class="step-history" data-step-history><cfif len(launchStep.author)><cfif launchStep.completed>Validado<cfelse>Reaberto</cfif> por #encodeForHTML(launchStep.author)# · #encodeForHTML(launchStep.changed_at)#<cfelse>Aguardando validação.</cfif></p></div></div>
<p class="step-notes-preview" data-notes-preview><cfif len(trim(launchPreview))>#encodeForHTML(launchPreview)#<cfelse>Observações ainda não preenchidas.</cfif></p>
<details class="step-editor"><summary><span>Ver observações e editar</span><span class="draft-badge" data-draft-badge hidden>Alterações não salvas</span></summary><div class="step-editor-body"><p class="step-description">#encodeForHTML(launchStep.description)#</p>
<form class="step-details" data-step-details="#encodeForHTMLAttribute(launchStep.key)#" data-version="#encodeForHTMLAttribute(launchStep.details_version)#">
<div class="step-owner-field"><label for="responsavel-#encodeForHTMLAttribute(launchStep.key)#">Responsável</label><input id="responsavel-#encodeForHTMLAttribute(launchStep.key)#" name="responsible" type="text" value="#encodeForHTMLAttribute(launchStep.responsible)#" maxlength="120" placeholder="Nome ou equipe" autocomplete="off" disabled></div>
<div class="step-notes-field"><label for="observacoes-#encodeForHTMLAttribute(launchStep.key)#">Observações · o que falta</label><textarea id="observacoes-#encodeForHTMLAttribute(launchStep.key)#" name="notes" rows="10" maxlength="2000" placeholder="O que está pronto, pendências e próximos passos" disabled>#encodeForHTML(launchStep.notes)#</textarea></div>
<div class="step-detail-actions"><button type="submit" data-save-details disabled>Salvar informações</button><p class="details-history" data-details-history><cfif len(launchStep.details_author)>Atualizado por #encodeForHTML(launchStep.details_author)# · #encodeForHTML(launchStep.details_changed_at)#<cfelse>Informações ainda não preenchidas.</cfif></p><p class="details-feedback" data-details-feedback role="status" aria-live="polite"></p></div>
<aside class="details-conflict" data-details-conflict hidden><b>Versão salva pela equipe</b><p data-saved-author></p><span>Responsável</span><p data-saved-responsible></p><span>Observações</span><p data-saved-notes></p><div><button type="button" data-use-saved>Usar versão salva</button><button type="button" data-reapply-draft>Salvar meu rascunho</button></div></aside>
</form></div></details></article></cfloop></cfoutput></div>'''
s=s[:a]+markup+s[b:];out('estudos/lancamento/index.cfm',s)

js=read('estudos/lancamento/checklist.js')
needle='  function fillDetails(form, step) {'
helpers='''  function updateSummary(form, step) {
    var row = form.closest('.launch-step');
    row.querySelector('[data-responsible-summary]').textContent = step.responsible.trim() || 'A definir';
    var first = step.notes.split(/\\r?\\n/).find(function (line) { return line.trim(); }) || 'Observações ainda não preenchidas.';
    row.querySelector('[data-notes-preview]').textContent = first.length > 260 ? first.slice(0, 257) + '…' : first;
  }
  function resizeNotes(form) {
    if (!form.closest('.step-editor').open) return;
    var field = form.elements.notes;
    field.style.height = 'auto';
    field.style.height = Math.min(560, Math.max(230, field.scrollHeight + 2)) + 'px';
  }
'''
assert js.count(needle)==1;js=js.replace(needle,helpers+needle)
js=js.replace("    form.dataset.dirty = 'false';","    form.dataset.dirty = 'false';\n    form.closest('.launch-step').querySelector('[data-draft-badge]').hidden = true;\n    updateSummary(form, step);\n    resizeNotes(form);",1)
js=js.replace("      if (form && (form === savedForm || form.dataset.dirty !== 'true')) fillDetails(form, step);","      if (form) updateSummary(form, step);\n      if (form && (form === savedForm || form.dataset.dirty !== 'true')) fillDetails(form, step);")
js=js.replace("    var status = form.querySelector('[data-details-feedback]');","    var status = form.querySelector('[data-details-feedback]');\n    form.closest('.step-editor').addEventListener('toggle', function () { resizeNotes(form); });",1)
js=js.replace("      form.dataset.dirty = 'true';","      form.dataset.dirty = 'true';\n      form.closest('.launch-step').querySelector('[data-draft-badge]').hidden = false;\n      resizeNotes(form);",1)
js=js.replace("        : 'Aguardando validação da equipe.';","        : 'Aguardando validação.';",1)
js=js.replace("  });\n})();","  });\n  function openLinkedStep() {\n    var row = document.getElementById(location.hash.slice(1));\n    if (row && row.matches('.launch-step')) row.querySelector('.step-editor').open = true;\n  }\n  window.addEventListener('hashchange', openLinkedStep);\n  openLinkedStep();\n})();")
out('estudos/lancamento/checklist.js',js)
css='''
/* Wide rows keep the launch plan readable; editing opens inside the selected row. */
.launch-list{display:flex;flex-direction:column;gap:12px;margin:12px 0 22px}.launch-list .launch-step{display:block;border:1px solid var(--line);border-radius:12px;background:white;padding:20px 24px;min-width:0;scroll-margin-top:88px}.launch-list .launch-step.contract{border-color:#b49bce;background:#f9f6fd}.launch-list .launch-step.launch{background:#fff0b3;border-color:#e9c65c}.launch-list .launch-step.is-complete{box-shadow:inset 4px 0 #398263}.step-row-header{display:grid;grid-template-columns:150px minmax(0,1fr) 170px 180px;gap:22px;align-items:center}.launch-list .step-row-header time{font-size:13px;font-weight:600;line-height:1.55}.launch-list .step-row-header h3{font-size:23px;line-height:1.2;margin:0;overflow-wrap:anywhere}.step-assignee{font-size:14px;line-height:1.5;overflow-wrap:anywhere}.step-assignee>span{display:block;font-size:11px;letter-spacing:.6px;text-transform:uppercase;color:var(--muted);margin-bottom:3px}.step-assignee>strong{font-weight:600}.launch-list .step-validation{padding:0;border:0;margin:0;justify-content:flex-end;gap:9px;font-size:14px}.launch-list .step-history{min-height:0;text-align:right;font-size:11px;line-height:1.5;margin:7px 0 0}.launch-list .step-notes-preview{font-size:15px;line-height:1.65;margin:14px 0 8px;color:#4b4843;overflow-wrap:anywhere}.step-editor{border-top:1px solid #0001;padding-top:9px}.step-editor>summary{font-size:13px;font-weight:600;cursor:pointer;display:list-item;list-style-position:inside;color:#4c3b6a;line-height:1.6}.step-editor>summary:focus-visible{outline:3px solid #7058b5;outline-offset:4px}.draft-badge{font-weight:400;font-size:12px;color:#9c4b15;margin-left:16px}.step-editor-body{padding-top:18px}.launch-list .step-description{font-size:14px;line-height:1.6;color:var(--muted);margin:0 0 18px}.launch-list .step-details{display:grid;grid-template-columns:220px minmax(0,1fr);gap:18px 24px;margin:0;padding:0;border:0}.step-owner-field,.step-notes-field{min-width:0}.step-details .step-owner-field>label,.step-details .step-notes-field>label{display:block;font-size:14px;font-weight:600;margin:0 0 8px}.step-details .step-owner-field>input,.step-details .step-notes-field>textarea{display:block;width:100%;max-width:100%;min-width:0;padding:11px 13px;border:1px solid #c9c7c1;border-radius:7px;background:white;color:var(--ink);font:15px/1.65 Poppins,sans-serif}.step-details .step-notes-field>textarea{min-height:230px;max-height:560px;resize:vertical}.step-detail-actions{grid-column:1/-1;display:flex;align-items:center;gap:12px 20px;flex-wrap:wrap}.step-detail-actions>button{padding:11px 18px;border:1px solid #54504a;border-radius:7px;background:var(--ink);color:white;font:600 14px/1.5 Poppins,sans-serif;cursor:pointer}.step-detail-actions .details-feedback{min-height:0;margin:0;font-size:13px}.step-detail-actions .details-history{font-size:12px}.launch-list .details-conflict{grid-column:1/-1;margin:0}.step-details .step-owner-field>input:focus-visible,.step-details .step-notes-field>textarea:focus-visible{outline:3px solid #7058b5;outline-offset:2px}
@media(max-width:1050px){.step-row-header{grid-template-columns:120px minmax(0,1fr) 140px 155px;gap:16px}.launch-list .step-row-header h3{font-size:21px}.launch-list .step-details{grid-template-columns:180px minmax(0,1fr))}}@media(max-width:800px){.step-row-header{grid-template-columns:minmax(0,1fr) auto;gap:12px 18px}.step-row-header>time{grid-column:1;grid-row:1}.step-row-header>h3{grid-column:1/-1;grid-row:2}.step-assignee{grid-column:1/-1;grid-row:3}.step-assignee>span{display:inline;margin:0 7px 0 0;font-size:11px}.step-completion{grid-column:2;grid-row:1}.launch-list .step-history{max-width:170px}.launch-list .launch-step{padding:18px 20px}.launch-list .step-details{grid-template-columns:1fr}.step-detail-actions{display:block}.step-detail-actions>button{width:100%;margin-bottom:12px}.step-detail-actions .details-feedback{margin-top:10px}.draft-badge{display:block;margin:4px 0 0}.draft-badge[hidden]{display:none}.step-details .step-owner-field>input,.step-details .step-notes-field>textarea{font-size:16px}.launch-list .step-notes-preview{font-size:14px}.launch-list .step-row-header h3{font-size:22px}}
'''.replace('grid-template-columns:180px minmax(0,1fr))','grid-template-columns:180px minmax(0,1fr)')
out('estudos/lancamento/lancamento.css',read('estudos/lancamento/lancamento.css')+css)
notes={
'organizar':'''PRÓXIMO PASSO: definir o dono do lançamento e fechar as listas do piloto e de criadores.

PRONTO (04/11)
• Prévia de janeiro a setembro de 2026 no Business, com 37 páginas, fontes e exportações agregadas.
• Hotsite público e comparativos: +2,1% de concluintes nas mesmas provas e +33,9% no calendário cadastrado, com universos distintos.
• Kit com dez artes, PDF de sete páginas, legendas, release e convite curto atualizados para 13/11.
• Central com materiais, cronograma e histórico de acompanhamento.

FALTA
• Nomear responsáveis por lançamento, aprovação editorial, convites e suporte.
• Selecionar 5–10 leitores para o piloto e a primeira lista de 5–8 criadores/influenciadores.
• Aprovação editorial final das chamadas e dos destinatários. Registrar as decisões aqui.''',
'piloto':'''PRÓXIMO PASSO: selecionar 5–10 leitores e autorizar os convites para testar o acesso completo.

PRONTO (04/11)
• Login Google, biblioteca, leitor profissional e gestão de convites no Business.
• Primeiro acesso ABRACEO por CNPJ/voucher preparado; 95 vouchers nominais prontos, com resgate até 24/11.
• Testes técnicos administrativos já executados em desktop e celular.

FALTA
• Ativar as campanhas de piloto/editorial quando houver autorização: ambas estão em rascunho e sem vouchers emitidos.
• Testar com convidados reais: conta Google, e-mail correto, resgate, retorno posterior à biblioteca, gráficos e exportações, também no celular.
• Conferir o primeiro acesso dos representantes e registrar problemas e correções.
• Na conferência de 04/11: zero resgates, zero acessos concedidos e zero representantes declarados. O piloto com convidados ainda precisa acontecer.''',
'contrato-abraceo':'''PRÓXIMO PASSO: concluir a aprovação do contrato e alinhar a comunicação com a ABRACEO até 12/11.

PRONTO
• Fluxo de primeiro acesso dos associados, pré-cadastros e vouchers preparado no Business.
• Proposta da prévia por convite e do anual vendido separadamente já refletida nos materiais internos.

FALTA
• Concluir a revisão e obter a aprovação das partes sobre o contrato.
• Confirmar público elegível, responsabilidades, contrapartidas, uso das marcas e autorização da comunicação conjunta.
• Confirmar os benefícios prometidos: a proposta prevê compra antecipada do anual com 50% de desconto para o público elegível; o primeiro acesso ABRACEO está configurado com benefício de 0% e precisa de alinhamento antes dos convites.
• Validar prazo de resgate até 24/11 e a primeira onda de associados. Registrar aqui a aprovação e quem a confirmou.''',
'liberacao':'''PRÓXIMO PASSO: alinhar o desconto do primeiro acesso e revisar a abertura temporária da área de imprensa.

PRONTO (04/11)
• Hotsite, kit e central publicados; materiais preparados para 13/11 e links principais respondendo.
• Área de imprensa oferece quatro edições: estudo principal e maratonas, 2025 e prévia 2026.
• Cronograma e acompanhamento compartilhado funcionando no desktop e celular.

FALTA ATÉ 12/11
• Resolver a diferença entre a promessa de 50% no anual e o benefício de 0% da campanha abraceo-primeiro-acesso, conforme o acordo aprovado.
• Definir se a imprensa continuará com acesso temporariamente aberto, sem login/código, ou voltará ao convite; testar o fluxo escolhido antes de divulgar.
• Concluir o piloto com não administradores e revisar login, resgate, leitura e exportações.
• Conferir aprovação do contrato, comunicação da parceria, chamadas, links e destinatários. Registrar a liberação final.''',
'lancamento':'''PRÓXIMO PASSO: confirmar horário, canais e responsáveis pela divulgação de 13/11.

PRONTO
• Hotsite público com destaques e caminhos para solicitar acesso.
• Kit, release, convite curto, artes para Instagram/YouTube e legendas disponíveis nos endereços atuais.
• Chamada principal atualizada: +2,1% nas mesmas provas versus +33,9% no calendário cadastrado, comparando janeiro a setembro dos dois anos.

FALTA PARA COLOCAR NA RUA
• Confirmar a liberação das etapas de preparação e o texto autorizado sobre a parceria.
• Fechar horário, perfis/canais, lista de imprensa e primeira onda de criadores e organizadores.
• Publicar post principal e stories, encaminhar o release e enviar os convites autorizados com os links corretos.
• Conferir o caminho do público geral ao pedido de acesso e organizar o suporte no dia.
• Envios e postagens continuam pendentes de execução pela equipe; os materiais preparados não significam divulgação já realizada.''',
'continuidade':'''PRÓXIMO PASSO: definir quem acompanha pedidos de acesso, dúvidas e repercussão entre 14 e 20/11.

PRONTO
• Cinco pautas no kit, com comparativos, fontes, artes e sugestões para Instagram e YouTube.
• Release e convite curto centralizados; leitura profissional disponível para aprofundamento.
• Gestão de pedidos, vouchers e acessos no Business.

FALTA APÓS A ESTREIA
• Acompanhar solicitações, resgates, dificuldades de leitura e dúvidas sobre os critérios.
• Responder à imprensa e apoiar entrevistas, análises e reviews que surgirem.
• Registrar matérias e publicações, feedback dos leitores e novas pautas.
• Ajustar materiais quando houver correção de fonte e manter a fonte das queries no notebook.
• Preparar uma segunda onda de divulgação com base no retorno real, com responsável e data definidos.''',
'venda-anual':'''PRÓXIMO PASSO: fechar oferta, licença e checkout do anual durante novembro e dezembro.

PRONTO
• Funil definido: prévia pública enxuta → convite/conta Business → leitura profissional → oferta anual.
• Produto anual de 2026 cadastrado em rascunho; infraestrutura de pagamento já existe no Business.
• Hipóteses de preço e benefício estão na central, ainda sujeitas à validação comercial.

FALTA
• Aprovar preço, licença, condições da oferta e público elegível à compra antecipada com 50% de desconto.
• Alinhar o benefício dos vouchers/primeiro acesso com a comunicação e verificar a elegibilidade antes da venda.
• Configurar a oferta do estudo no pagamento e testar compra, confirmação e liberação de leitura.
• Preparar a comunicação com quem usou a prévia e os materiais comerciais antes do recesso.
• Este trabalho prepara janeiro; não impede a estreia da prévia de 13/11.''',
'edicao-anual':'''PRÓXIMO PASSO: confirmar 6/1 e 11/1 conforme o fechamento e a revisão da edição anual de 2026.

PRONTO
• Notebook centralizado como fonte de queries e resultados congelados; base dinâmica e leitura web da prévia já disponíveis.
• Produto anual separado da prévia, atualmente em rascunho.
• Proposta: compra antecipada em 06/01/2027 e abertura geral em 11/01/2027.

FALTA PARA JANEIRO
• Fechar o quarto trimestre e o ano completo, revisar os recortes e gerar os congelamentos finais no notebook.
• Nutrir e revisar os temas reservados ao anual: inscrições/categorias/kits/lotes, CNA e desempenho nacional dos 42 km.
• Confirmar escopo, oferta, datas, benefício e acesso após o pagamento; validar a leitura final antes da estreia.
• Gerar o PDF final depois da aprovação da versão web, se fizer parte da entrega.
• Datas de janeiro continuam propostas. Estas pendências são do anual, não do recorte de três trimestres lançado em novembro.'''
}
for key,note in notes.items():assert len(note)<=2000,(key,len(note))
(W/'observacoes-propostas.json').write_text(json.dumps(notes,ensure_ascii=False,indent=2))
print('Built 3 runtime files and 8 notes:',{k:len(v)for k,v in notes.items()})
