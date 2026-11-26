from pathlib import Path
W=Path(__file__).resolve().parent

def read(n):return(W/'baseline'/n).read_text()
def out(n,text):
 p=W/'runtime'/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text)
s=read('estudos/lancamento/index.cfm').replace('20261104-lista-plano','20261104-faixa-compacta')
s=s.replace('Veja o próximo passo de cada etapa na lista. Abra “Ver observações e editar” para consultar o que está pronto, as pendências e o responsável. Salve as informações para compartilhar com a equipe; valide a etapa quando estiver concluída.','Use “Expandir” à direita para consultar e editar o plano da etapa. Data, responsável e validação ficam sempre visíveis; as observações salvas continuam compartilhadas com a equipe.')
s=s.replace('class="launch-checklist launch-list"','class="launch-checklist launch-list launch-compact"')
needle='''<cfif len(launchPreview) GT 260><cfset launchPreview=left(launchPreview,257) & '…'/></cfif>'''
parse='''
<cfset launchDateText=trim(launchStep.date)/><cfset launchDatePrefix=''/>
<cfif left(launchDateText,4) EQ 'ATÉ '><cfset launchDatePrefix='ATÉ'/><cfset launchDateText=trim(removeChars(launchDateText,1,4))/></cfif>
<cfif reFind('^[0-9]{2} / [0-9]{2} ',launchDateText)><cfset launchDay=left(launchDateText,7)/><cfset launchDateCaption=trim(removeChars(launchDateText,1,7))/><cfelse><cfset launchDay=listFirst(launchDateText,' ')/><cfset launchDateCaption=trim(removeChars(launchDateText,1,len(launchDay)))/></cfif>
<cfif NOT len(launchDateCaption)><cfset launchDateCaption='2026'/></cfif>'''
assert s.count(needle)==1;s=s.replace(needle,needle+parse)
needle='''<div class="step-row-header"><time>#encodeForHTML(launchStep.date)#</time><h3>#encodeForHTML(launchStep.title)#</h3>'''
replacement='''<div class="step-row-header"><time class="step-date" aria-label="#encodeForHTMLAttribute(launchStep.date)#"><cfif len(launchDatePrefix)><span class="step-date-prefix">#encodeForHTML(launchDatePrefix)#</span></cfif><strong class="step-date-day<cfif NOT reFind('^[0-9]',launchDay)> is-period<cfelseif len(launchDay) GT 5> is-long<cfelseif len(launchDay) GT 3> is-range</cfif>">#encodeForHTML(launchDay)#</strong><span class="step-date-caption">#encodeForHTML(launchDateCaption)#</span></time><div class="step-title-wrap"><h3>#encodeForHTML(launchStep.title)#</h3><span class="draft-badge" data-draft-badge hidden>Alterações não salvas</span></div>'''
assert s.count(needle)==1;s=s.replace(needle,replacement)
needle='''</cfif></p></div></div>
<p class="step-notes-preview"'''
button='''</cfif></p></div><button class="step-toggle" type="button" data-toggle-step aria-expanded="false" aria-controls="painel-#encodeForHTMLAttribute(launchStep.key)#" aria-label="Expandir etapa: #encodeForHTMLAttribute(launchStep.title)#" disabled><span data-toggle-label>Expandir</span><svg viewBox="0 0 20 20" width="18" height="18" aria-hidden="true" focusable="false"><path d="m5 7.5 5 5 5-5" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg></button></div>
<details class="step-editor" id="painel-#encodeForHTMLAttribute(launchStep.key)#"><summary hidden>Detalhes da etapa</summary><div class="step-editor-body">
<p class="step-notes-preview"'''
assert s.count(needle)==1;s=s.replace(needle,button)
needle='''<details class="step-editor"><summary><span>Ver observações e editar</span><span class="draft-badge" data-draft-badge hidden>Alterações não salvas</span></summary><div class="step-editor-body"><p class="step-description">'''
assert s.count(needle)==1;s=s.replace(needle,'''<p class="step-description">''')
out('estudos/lancamento/index.cfm',s)

js=read('estudos/lancamento/checklist.js')
needle="    form.closest('.step-editor').addEventListener('toggle', function () { resizeNotes(form); });"
replacement='''    var editor = form.closest('.step-editor');
    var row = form.closest('.launch-step');
    var toggle = row.querySelector('[data-toggle-step]');
    function syncExpanded() {
      var label = editor.open ? 'Recolher' : 'Expandir';
      toggle.setAttribute('aria-expanded', String(editor.open));
      toggle.setAttribute('aria-label', label + ' etapa: ' + row.querySelector('h3').textContent);
      toggle.querySelector('[data-toggle-label]').textContent = label;
      resizeNotes(form);
    }
    toggle.disabled = false;
    toggle.addEventListener('click', function () { editor.open = !editor.open; syncExpanded(); });
    editor.addEventListener('toggle', syncExpanded);
    syncExpanded();'''
assert js.count(needle)==1;js=js.replace(needle,replacement)
out('estudos/lancamento/checklist.js',js)

css=read('estudos/lancamento/lancamento.css');marker='/* Wide rows keep the launch plan readable; editing opens inside the selected row. */'
a=css.index(marker);css=css[:a]+'''/* Compact date band. One control reveals the whole step without nested panels. */
.launch-list{display:flex;flex-direction:column;gap:10px;margin:12px 0 22px}.launch-list .launch-step{display:block;border:1px solid var(--line);border-radius:12px;background:white;padding:16px 22px;min-width:0;scroll-margin-top:88px}.launch-list .launch-step.contract{border-color:#b49bce;background:#f9f6fd}.launch-list .launch-step.launch{background:#fff0b3;border-color:#e9c65c}.launch-list .launch-step.is-complete{box-shadow:inset 4px 0 #398263}.step-row-header{display:grid;grid-template-columns:140px minmax(0,1fr) 140px 164px 108px;gap:16px;align-items:center}.launch-list .step-date{font-family:LibreFranklin,sans-serif;display:flex;flex-direction:column;align-items:flex-start;gap:5px;line-height:1}.step-date-prefix{font:600 10px/1.1 Poppins,sans-serif;letter-spacing:1px}.step-date-day{font-size:42px;font-weight:900;letter-spacing:-2px;line-height:1}.step-date-day.is-range{font-size:35px;letter-spacing:-1.5px}.step-date-day.is-long{font-size:29px;letter-spacing:-1.3px}.step-date-day.is-period{font-size:25px;letter-spacing:-1px}.step-date-caption{font:600 10px/1.4 Poppins,sans-serif;letter-spacing:.4px}.step-title-wrap{min-width:0}.launch-list .step-title-wrap h3{font-size:23px;line-height:1.2;margin:0;overflow-wrap:anywhere}.step-assignee{font-size:14px;line-height:1.5;overflow-wrap:anywhere}.step-assignee>span{display:block;font-size:10px;letter-spacing:.6px;text-transform:uppercase;color:var(--muted);margin-bottom:3px}.step-assignee>strong{font-weight:600}.launch-list .step-validation{padding:0;border:0;margin:0;justify-content:flex-end;gap:8px;font-size:14px}.launch-list .step-history{min-height:0;text-align:right;font-size:11px;line-height:1.5;margin:6px 0 0}.step-toggle{display:flex;align-items:center;justify-content:center;gap:8px;min-width:0;width:108px;min-height:40px;padding:9px 10px;border:1px solid #d1c9dc;border-radius:8px;background:white;color:#4c3b6a;font:600 12px/1.4 Poppins,sans-serif;cursor:pointer}.step-toggle:hover{background:#eee7f6}.step-toggle:focus-visible{outline:3px solid #7058b5;outline-offset:3px}.step-toggle svg{flex-shrink:0;transition:transform .15s ease}.step-toggle[aria-expanded=true]{background:#4c3b6a;border-color:#4c3b6a;color:white}.step-toggle[aria-expanded=true] svg{transform:rotate(180deg)}.step-toggle:disabled{opacity:.6;cursor:wait}.draft-badge{display:block;font:400 11px/1.5 Poppins,sans-serif;color:#9c4b15;margin-top:6px}.draft-badge[hidden]{display:none}.step-editor{margin:0;padding:0;border:0}.step-editor>summary[hidden]{display:none}.step-editor-body{border-top:1px solid #0002;margin-top:18px;padding-top:20px}.launch-list .step-notes-preview{font-size:15px;line-height:1.65;margin:0 0 12px;color:#4b4843;overflow-wrap:anywhere}.launch-list .step-description{font-size:14px;line-height:1.6;color:var(--muted);margin:0 0 18px}.launch-list .step-details{display:grid;grid-template-columns:220px minmax(0,1fr);gap:18px 24px;margin:0;padding:0;border:0}.step-owner-field,.step-notes-field{min-width:0}.step-details .step-owner-field>label,.step-details .step-notes-field>label{display:block;font-size:14px;font-weight:600;margin:0 0 8px}.step-details .step-owner-field>input,.step-details .step-notes-field>textarea{display:block;width:100%;max-width:100%;min-width:0;padding:11px 13px;border:1px solid #c9c7c1;border-radius:7px;background:white;color:var(--ink);font:15px/1.65 Poppins,sans-serif}.step-details .step-notes-field>textarea{min-height:230px;max-height:560px;resize:vertical}.step-detail-actions{grid-column:1/-1;display:flex;align-items:center;gap:12px 20px;flex-wrap:wrap}.step-detail-actions>button{padding:11px 18px;border:1px solid #54504a;border-radius:7px;background:var(--ink);color:white;font:600 14px/1.5 Poppins,sans-serif;cursor:pointer}.step-detail-actions .details-feedback{min-height:0;margin:0;font-size:13px}.step-detail-actions .details-history{font-size:12px}.launch-list .details-conflict{grid-column:1/-1;margin:0}.step-details .step-owner-field>input:focus-visible,.step-details .step-notes-field>textarea:focus-visible{outline:3px solid #7058b5;outline-offset:2px}
@media(max-width:1050px){.step-row-header{grid-template-columns:120px minmax(0,1fr) 120px 150px 42px;gap:12px}.launch-list .step-title-wrap h3{font-size:21px}.step-toggle{width:42px;padding:9px}.step-toggle [data-toggle-label]{display:none}.launch-list .step-details{grid-template-columns:180px minmax(0,1fr)}}
@media(max-width:800px){.step-row-header{grid-template-columns:85px minmax(0,1fr) 42px;gap:10px 12px}.step-row-header>.step-date{grid-column:1;grid-row:1/3}.step-row-header>.step-title-wrap{grid-column:2;grid-row:1}.step-row-header>.step-assignee{grid-column:2;grid-row:2}.step-row-header>.step-completion{grid-column:1/-1;grid-row:3;display:flex;align-items:center;justify-content:space-between;gap:15px;padding-top:8px}.step-row-header>.step-toggle{grid-column:3;grid-row:1;align-self:start}.step-date-day{font-size:39px}.step-date-day.is-range{font-size:29px}.step-date-day.is-long{font-size:24px}.step-date-day.is-period{font-size:20px}.step-date-caption{font-size:9px}.step-assignee>span{display:inline;margin:0 6px 0 0;font-size:10px}.launch-list .step-history{margin:0;max-width:170px}.launch-list .launch-step{padding:17px 18px}.launch-list .step-details{grid-template-columns:1fr}.launch-list .step-title-wrap h3{font-size:21px}.step-detail-actions{display:block}.step-detail-actions>button{width:100%;margin-bottom:12px}.step-detail-actions .details-feedback{margin-top:10px}.step-details .step-owner-field>input,.step-details .step-notes-field>textarea{font-size:16px}.launch-list .step-notes-preview{font-size:14px}}
@media(prefers-reduced-motion:reduce){.step-toggle svg{transition:none}}
'''
out('estudos/lancamento/lancamento.css',css)
print('Built compact date bands: header only, right toggle, all remaining content in one panel.')
