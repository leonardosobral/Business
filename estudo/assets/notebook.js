(() => {
'use strict';
const app=document.getElementById('study-app');if(!app)return;
const $=id=>document.getElementById(id), state={book:null,section:null,cells:[],pending:0};
const normalize=x=>Array.isArray(x)?x.map(normalize):(x&&typeof x==='object'?Object.fromEntries(Object.entries(x).map(([k,v])=>[k.toLowerCase(),normalize(v)])):x);
const el=(tag,cls,text)=>{const n=document.createElement(tag);if(cls)n.className=cls;if(text!==undefined)n.textContent=text;return n;};
const notice=(message,error=false)=>{const n=$('study-notice');n.replaceChildren(document.createTextNode(message));n.classList.toggle('error',error);};
async function api(action,values={},download=false){
 const response=await fetch('/estudo/api.cfm',{method:'POST',credentials:'same-origin',body:new URLSearchParams({csrf:app.dataset.csrf,action,...values})});
 if(download&&response.ok){const blob=await response.blob(),url=URL.createObjectURL(blob),a=el('a');a.href=url;a.download='estudo-execucao-'+values.id+'.json';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);return;}
 let packet;try{packet=normalize(await response.json());}catch{throw new Error('A sessão pode ter expirado. Recarregue a página.');}
 if(!response.ok||!packet.ok)throw new Error(packet.error||'Não foi possível concluir.');
 return packet.data;
}
function busy(delta){
 state.pending+=delta;state.cells.forEach(c=>c.editor?.setOption('readOnly',state.pending>0));
 ['study-book','study-section','new-book','new-section','rename-book','rename-section','add-sql','add-text','add-html','archived-cells'].forEach(id=>$(id).disabled=state.pending>0);
}
function button(text,action,cls='btn btn-outline-light btn-sm'){
 const b=el('button',cls,text);b.type='button';
 b.addEventListener('click',async()=>{if(b.disabled||state.pending)return;b.disabled=true;busy(1);try{await action(b);}catch(e){notice(e.message,true);}finally{busy(-1);b.disabled=b.dataset.disabled==="true";}});
 return b;
}
const dirty=()=>state.cells.some(c=>c.editor&&c.editor.getValue()!==c.content);
function canLeave(){if(state.pending){notice('Aguarde a operação em andamento.',true);return false;}if(dirty()){notice('Há alterações locais. Salve as células ou descarte as alterações antes de mudar de seção.',true);return false;}return true;}
function dirtyUI(){ $('discard').hidden=!dirty(); }
function selectOptions(select,items,label){select.replaceChildren();items.forEach(item=>{const o=el('option','',item[label]);o.value=item.id;select.append(o);});}
function date(value){if(!value)return '';const parsed=new Date(value);return Number.isNaN(parsed.valueOf())?value:parsed.toLocaleString('pt-BR');}
async function loadBooks(preferred){
 const books=await api('list');selectOptions($('study-book'),books,'titulo');
 state.book=books.find(b=>String(b.id)===String(preferred)||String(b.merged_ids||'').split(',').includes(String(preferred)))||books[0];
 if(!state.book){notice('Crie o primeiro caderno.');return;}
 $('study-book').value=state.book.id;await loadSections();
}
async function loadSections(preferred){
 const sections=await api('sections',{bookId:state.book.id});selectOptions($('study-section'),sections,'title');
 const wanted=sections.find(s=>String(s.id)===String(preferred))||sections[0];
 if(wanted){$('study-section').value=wanted.id;await loadSection(wanted.id);}
 else {state.section=null;state.cells=[];$('study-cells').replaceChildren();$('section-title').textContent='Crie uma seção para começar.';notice('Caderno criado. Adicione sua primeira seção.');}
}
async function loadSection(id){
 const data=await api('notebook',{id});state.section=data;state.cells=data.cells;
 $('study-section').value=id;$('section-title').textContent=data.title;
 $('study-cells').replaceChildren();state.cells.forEach(renderCell);dirtyUI();
 $('study-runs').replaceChildren();$('study-run-detail').replaceChildren();
 const url=new URL(location.href);url.searchParams.set('caderno',state.book.id);url.searchParams.set('secao',id);history.replaceState(null,'',url);
 notice('Células carregadas. Nenhuma query foi executada ao abrir.');
 if(!$('panel-runs').hidden)await loadRuns();
}
function compose(title,fields,submit){
 const holder=$('study-composer');holder.replaceChildren();holder.hidden=false;
 const form=el('form','study-form'),heading=el('h2','h6',title);form.append(heading);const inputs={};
 fields.forEach(f=>{const label=el('label','',f.label),input=el(f.multiline?'textarea':'input','form-control');
 input.name=f.name;input.value=f.value||'';input.required=!!f.required;if(f.type)input.type=f.type;if(f.max)input.maxLength=f.max;
 label.append(input);form.append(label);inputs[f.name]=input;});
 const actions=el('div','study-actions');const send=button('Salvar',async()=>{if(!form.reportValidity())return;if(dirty())throw new Error('Salve ou descarte as alterações nas células antes de continuar.');await submit(Object.fromEntries(Object.entries(inputs).map(([k,v])=>[k,v.value])));holder.hidden=true;},'btn btn-warning btn-sm');
 actions.append(send,button('Cancelar',()=>{holder.hidden=true;}));form.append(actions);form.addEventListener('submit',e=>{e.preventDefault();send.click();});holder.append(form);Object.values(inputs)[0].focus();
}
function preview(c){
 if(c.lang==='sql')return;
 const raw=c.lang==='html'?c.editor.getValue():marked.parse(c.editor.getValue());
 c.preview.innerHTML=DOMPurify.sanitize(raw,{FORBID_TAGS:['style','script','iframe','form','input','button','img','svg','math','video','audio'],FORBID_ATTR:['style','id']});
}
function cellBadge(c){c.badge.textContent='Célula '+c.id+' · revisão '+c.version+(c.editor.getValue()!==c.content?' · não salva':'');dirtyUI();}
async function save(c){
 const content=c.editor.getValue();if(content===c.content)return;
 const saved=await api('saveCell',{id:c.id,version:c.version,type:c.cell_type,lang:c.lang,content});c.version=saved.version;c.content=content;cellBadge(c);preview(c);notice('Célula '+c.id+' salva na revisão '+c.version+'.');
}
function renderCell(c){
 const card=el('article','study-card');card.dataset.cell=c.id;c.card=card;
 const head=el('div','study-cell-head'),label=el('strong','study-kind',c.lang==='sql'?'SQL':c.lang==='html'?'HTML histórico':'Texto');
 c.badge=el('span','study-meta');const actions=el('div','study-actions');
 actions.append(button('Salvar',()=>save(c),'btn btn-outline-warning btn-sm'));
 if(c.lang==='sql')actions.append(button('Executar',async b=>{
   const selection=c.editor.getSelection(),sql=selection||c.editor.getValue();await save(c);
   b.textContent='Executando…';notice('Executando '+(selection?'a seleção':'a célula')+' '+c.id+'…');
   try{const run=await api('run',{cellId:c.id,version:c.version,sql});renderResult(run,c.result);notice(run.status==='ok'?'Consulta concluída. Confira a tabela antes de congelar.':'A consulta retornou um erro.',run.status!=='ok');}
   finally{b.textContent='Executar';}
 },'btn btn-warning btn-sm'));
 else actions.append(button('Visualizar',()=>preview(c)));
 actions.append(button('Revisões',()=>showRevisions(c)));
 const move=async delta=>{if(dirty()){notice('Salve suas alterações antes de reordenar.',true);return;}const ids=state.cells.map(x=>x.id),index=ids.indexOf(c.id),target=index+delta;if(target<0||target>=ids.length)return;[ids[index],ids[target]]=[ids[target],ids[index]];await api('reorderCells',{notebookId:state.section.id,ids:JSON.stringify(ids)});await loadSection(state.section.id);};
 actions.append(button('↑',()=>move(-1)),button('↓',()=>move(1)));
 actions.lastChild.title='Mover célula para baixo';actions.children[actions.children.length-2].title='Mover célula para cima';
 actions.append(button('Arquivar',async()=>{
   if(dirty()){notice('Salve suas alterações antes de arquivar.',true);return;}
   const archived=await api('archiveCell',{id:c.id,version:c.version,archived:true});
   await loadSection(state.section.id);notice('Célula arquivada. O histórico foi preservado.');
   $('study-notice').append(button('Desfazer',async()=>{await api('archiveCell',{id:c.id,version:archived.version,archived:false});await loadSection(state.section.id);}));
 }));
 head.append(label,c.badge,actions);card.append(head);
 const textarea=el('textarea');textarea.value=c.content;textarea.setAttribute('aria-label','Conteúdo da célula '+c.id);card.append(textarea);
 c.preview=el('div','study-preview');c.result=el('div','study-result');card.append(c.preview,c.result);$('study-cells').append(card);
 c.editor=CodeMirror.fromTextArea(textarea,{mode:c.lang==='sql'?'text/x-pgsql':c.lang==='html'?'text/html':'text/x-markdown',lineNumbers:true,lineWrapping:true,readOnly:state.pending>0,viewportMargin:20,indentUnit:2,extraKeys:{'Ctrl-Enter':()=>actions.children[c.lang==='sql'?1:0].click(),'Cmd-Enter':()=>actions.children[c.lang==='sql'?1:0].click()}});
 c.editor.on('change',()=>cellBadge(c));cellBadge(c);preview(c);
 if(c.lang==='sql'){const hint=el('p','study-hint','Executa uma consulta por vez. Se houver várias, selecione o trecho desejado.');card.insertBefore(hint,c.editor.getWrapperElement());}
 if(c.lang==='html')c.preview.prepend(el('p','study-hint','Resultado legado colado manualmente; não é um congelamento vinculado à query.'));
}
function parseResult(raw){return StudyData.parse(raw);}
function renderResult(run,target){
 target.replaceChildren();const header=el('div','study-toolbar');
 header.append(el('strong','',run.frozen?run.title:'Execução #'+run.id),el('span','study-meta','Célula '+run.cell_id+' · revisão '+run.cell_version+' · '+date(run.started_at)+' · admin #'+run.executed_by));
 target.append(header);
 if(run.status!=='ok'){target.append(el('p','study-error',run.status==='running'?'Execução em andamento. Atualize o histórico em instantes.':run.error_message));return;}
 const result=parseResult(run.result_json),rows=result.rows,columns=result.columns;
 target.append(el('p','study-hint',run.row_count+' linhas · '+(Number(run.duration_ms)/1000).toLocaleString('pt-BR')+' s'+(run.truncated?' · RESULTADO INCOMPLETO — refine a consulta antes de congelar.':'')));
 const tableBox=el('div','study-table-wrap'),table=el('table','table table-sm'),thead=el('thead'),tr=el('tr');
 columns.forEach(name=>tr.append(el('th','',name)));thead.append(tr);const tbody=el('tbody');table.append(thead,tbody);tableBox.append(table);target.append(tableBox);
 let page=0;const pagination=el('div','study-actions'),label=el('span','study-meta'),back=button('Anterior',()=>{page--;draw();}),next=button('Próxima',()=>{page++;draw();});
 function draw(){tbody.replaceChildren();rows.slice(page*50,(page+1)*50).forEach(row=>{const r=el('tr');columns.forEach(name=>{const key=Object.keys(row).find(k=>k.toLowerCase()===name.toLowerCase()),value=row[key],td=el('td',value===null?'study-null':'',value===null?'NULL':typeof value==='object'?JSON.stringify(value):String(value??''));r.append(td);});tbody.append(r);});label.textContent=rows.length?'Linhas '+(page*50+1)+'–'+Math.min((page+1)*50,rows.length)+' de '+rows.length:'Nenhuma linha';back.disabled=page===0;next.disabled=(page+1)*50>=rows.length;back.dataset.disabled=String(back.disabled);next.dataset.disabled=String(next.disabled);}
 pagination.append(back,label,next,button('Exportar JSON',()=>api('export',{id:run.id},true)),button('Exportar CSV',()=>{
 const url=URL.createObjectURL(new Blob(['\uFEFF'+StudyData.csv(run.result_json)],{type:'text/csv;charset=utf-8'})),a=el('a');a.href=url;a.download='estudo-execucao-'+run.id+'.csv';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);
}));target.append(pagination);draw();
 const sql=el('details','study-sql-proof');sql.append(el('summary','','SQL executado · SHA-256 '+run.sql_sha256.slice(0,12)),el('pre','',run.sql_text));target.append(sql);
 if(run.frozen){target.append(el('p','study-frozen','Congelado em '+date(run.frozen_at)+' por admin #'+run.frozen_by+'.'),el('p','',run.note));}
 else if(!run.truncated){
   const freezeArea=el('div','study-freeze');const title=el('input','form-control');title.placeholder='Título do resultado';title.value=(state.section?.title||'Resultado')+' · célula '+run.cell_id;title.maxLength=200;title.setAttribute('aria-label','Título do congelamento');
   const note=el('textarea','form-control');note.placeholder='Recorte, filtros e ressalvas desta coleta';note.maxLength=10000;note.setAttribute('aria-label','Notas do congelamento');
   freezeArea.append(title,note,button('Congelar resultado',async()=>{const frozen=await api('freeze',{id:run.id,title:title.value,note:note.value});renderResult(frozen,target);notice('Resultado congelado. SQL e dados preservados sem reexecutar.');},'btn btn-warning btn-sm'));target.append(freezeArea);
 }
}
async function showRevisions(c){
 $("revision-title").textContent="Revisões da célula";
 const revisions=await api('revisions',{cellId:c.id}),box=$('revision-list');box.replaceChildren();
 revisions.forEach(r=>{const details=el('details','study-revision'),summary=el('summary','','Revisão '+r.version+' · '+date(r.saved_at)+' · '+(r.saved_by?'admin #'+r.saved_by:'acervo legado'));
 details.append(summary,el('pre','',r.content),button('Copiar esta revisão para o editor',()=>{if(r.cell_type!==c.cell_type||r.lang!==c.lang)throw new Error('Esta revisão usa outro tipo de célula. Copie o conteúdo para uma nova célula.');c.editor.setValue(r.content);$('revision-dialog').close();c.editor.focus();notice('Revisão copiada para o editor. Salve para registrar uma nova versão.');}));box.append(details);});$('revision-dialog').showModal();
}
async function loadRuns(){
 const box=$('study-runs');box.replaceChildren();if(!state.section)return;
 const records=await api('runs',{notebookId:state.section.id});if(!records.length){box.append(el('div','study-card','Ainda não há execuções nesta seção.'));return;}
 records.forEach(r=>{const card=el('div','study-run-row'),text=el('div');text.append(el('strong','',r.frozen?'❄ '+r.title:'Execução #'+r.id+' · célula '+r.cell_id),el('p','study-meta',date(r.started_at)+' · '+(r.status==='ok'?r.row_count+' linhas'+(r.truncated?' · incompleto':''):r.status==='running'?'em andamento':'erro')+' · revisão '+r.cell_version));card.append(text,button('Abrir resultado',async()=>{const run=await api('getRun',{id:r.id});renderResult(run,$('study-run-detail'));$('study-run-detail').scrollIntoView({behavior:'smooth',block:'start'});}));box.append(card);});
}
let webCatalog=[],webChecked=null;
function webChoice(){return webCatalog.find(d=>String(d.ano)===$('web-year').value);}
function clearWebPreview(){webChecked=null;$('web-preview-content').replaceChildren();$('web-publish-area').hidden=true;}
function chooseWebYear(){
 clearWebPreview();const d=webChoice();if(!d)return;
 selectOptions($('web-run'),d.runs.map(r=>({...r,label:'#'+r.id+' · '+r.title+' · revisão '+r.cell_version})),'label');
 if(d.runs.some(r=>String(r.id)===String(d.run_atual)))$('web-run').value=d.run_atual;
 $('web-current').textContent=d.publicacao_id?'No ar: versão '+d.versao+' · congelamento #'+d.run_atual+' · '+date(d.publicado_em):'Edição ainda não conectada à web.';
 $('web-notebook').href='/estudo/?caderno='+d.caderno_id+'&secao='+d.notebook_id;
 $('web-live').href='https://roadrunners.run/brasilquecorreprovas/web/?ano='+d.ano;
 $('web-preview').disabled=!d.runs.length;$('web-note').value='';
}
async function loadWeb(){const prior=$('web-year').value;webCatalog=await api('webCatalog');selectOptions($('web-year'),webCatalog.map(d=>({id:d.ano,label:String(d.ano)})),'label');if(webCatalog.some(d=>String(d.ano)===prior))$('web-year').value=prior;chooseWebYear();}
$('web-year').addEventListener('change',chooseWebYear);$('web-run').addEventListener('change',clearWebPreview);
$('web-refresh').addEventListener('click',()=>loadWeb().catch(e=>notice(e.message,true)));
$('web-preview').addEventListener('click',async()=>{
 if(state.pending)return;busy(1);clearWebPreview();
 try{const d=webChoice(),id=$('web-run').value,p=await api('webPreview',{year:d.ano,runId:id}),payload=JSON.parse(p.payload_json);
 if(webChoice()!==d||$('web-run').value!==id)return;
 webChecked={year:d.ano,runId:id,expected:d.publicacao_id};const box=$('web-preview-content');
 box.append(el('h3','h6','Congelamento #'+id+' · edição '+d.ano),el('p','study-hint',payload.meta.origem||'Fonte identificada no pacote.'));
 box.append(el('p','','Resultados: '+Number(payload.totais_atuais.resultados).toLocaleString('pt-BR')+' · Eventos cadastrados: '+Number(payload.totais_atuais.eventos).toLocaleString('pt-BR')));
 const details=el('details'),summary=el('summary','','Conferir '+payload.comparacoes.length+' valores, fontes e pendências'),wrap=el('div','study-table-wrap'),table=el('table','table table-sm'),head=el('thead'),tr=el('tr');
 ['Série / categoria','Valor','Fonte / ressalva'].forEach(t=>tr.append(el('th','',t)));head.append(tr);table.append(head);const body=el('tbody');
 payload.comparacoes.forEach(c=>{const row=el('tr');row.append(el('td','',c.serie+' / '+c.categoria),el('td','',c.atual?.valor===null||c.atual?.valor===undefined?'—':String(c.atual.valor)),el('td','',c.atual?[c.atual.fonte||payload.meta.origem,c.atual.nota||''].filter(Boolean).join(' · '):'Sem recálculo'));body.append(row);});table.append(body);wrap.append(table);details.append(summary,wrap);box.append(details);$('web-publish-area').hidden=false;
 notice('Pacote completo e compatível. Confira os valores e registre a nota antes de usar na web.');
 }catch(e){notice(e.message,true);}finally{busy(-1);}
});
$('web-publish').addEventListener('click',async()=>{
 if(state.pending||!webChecked)return;const checked={...webChecked},note=$('web-note').value.trim();if(!note){notice('Informe a nota pública desta versão.',true);return;}
 busy(1);try{await api('webPublish',{...checked,note});await loadWeb();notice('Versão web atualizada. O pacote anterior permanece no histórico.');}catch(e){notice(e.message,true);}finally{busy(-1);}
});

document.querySelectorAll('[data-tab]').forEach(tab=>tab.addEventListener('click',async()=>{
 document.querySelectorAll('[data-tab]').forEach(t=>{const active=t===tab;t.classList.toggle('active',active);t.setAttribute('aria-selected',active);$('panel-'+t.dataset.tab).hidden=!active;});
 try{if(tab.dataset.tab==='web')await loadWeb();else if(tab.dataset.tab==='runs')await loadRuns();else if(tab.dataset.tab==='notebook')state.cells.forEach(c=>c.editor.refresh());}catch(e){notice(e.message,true);}
}));
$('study-book').addEventListener('change',async()=>{if(!canLeave()){$('study-book').value=state.book.id;return;}busy(1);try{await loadBooks($('study-book').value);}catch(e){notice(e.message,true);}finally{busy(-1);}});
$('study-section').addEventListener('change',async()=>{if(!canLeave()){$('study-section').value=state.section.id;return;}busy(1);try{await loadSection($('study-section').value);}catch(e){notice(e.message,true);}finally{busy(-1);}});
$('rename-book').addEventListener('click',()=>{if(!canLeave()||!state.book)return;compose('Renomear caderno',[{name:'title',label:'Título',value:state.book.titulo,required:true,max:200}],async v=>{const sectionId=state.section?.id;await api('saveBook',{id:state.book.id,version:state.book.version,...v});await loadBooks(state.book.id);if(sectionId)await loadSections(sectionId);});});
$('archived-cells').addEventListener('click',async()=>{
 if(!canLeave()||!state.section)return;busy(1);
 try{const records=await api('archived',{notebookId:state.section.id}),box=$('revision-list');box.replaceChildren();$('revision-title').textContent='Células arquivadas';
 if(!records.length)box.append(el('p','','Nenhuma célula arquivada nesta seção.'));
 records.forEach(c=>{const item=el('details','study-revision');item.append(el('summary','','Célula '+c.id+' · revisão '+c.version+' · '+date(c.updated_at)),el('pre','',c.content),button('Restaurar célula',async()=>{
 if(dirty())throw new Error('Salve suas alterações antes de restaurar.');await api('archiveCell',{id:c.id,version:c.version,archived:false});$('revision-dialog').close();await loadSection(state.section.id);notice('Célula restaurada com seu histórico.');}));box.append(item);});$('revision-dialog').showModal();
 }catch(e){notice(e.message,true);}finally{busy(-1);}
});
$('new-book').addEventListener('click',()=>{if(!canLeave())return;compose('Novo caderno',[{name:'title',label:'Título',required:true,max:200},{name:'year',label:'Ano',type:'number',value:new Date().getFullYear(),required:true}],async v=>{const book=await api('createBook',v);await loadBooks(book.id);});});
$('new-section').addEventListener('click',()=>{if(!canLeave()||!state.book)return;compose('Nova seção',[{name:'title',label:'Título',required:true,max:200}],async v=>{const section=await api('createNotebook',{bookId:state.book.id,...v});await loadSections(section.id);});});
$('rename-section').addEventListener('click',()=>{if(!canLeave()||!state.section)return;compose('Renomear seção',[{name:'title',label:'Título',value:state.section.title,required:true,max:200}],async v=>{await api('saveNotebook',{id:state.section.id,version:state.section.version,...v});await loadSections(state.section.id);});});
[['add-sql','code','sql'],['add-text','markdown',''],['add-html','code','html']].forEach(([id,type,lang])=>{$(id).addEventListener('click',async()=>{if(!canLeave()||!state.section)return;busy(1);try{await api('createCell',{notebookId:state.section.id,type,lang,content:''});await loadSection(state.section.id);state.cells.at(-1)?.editor.focus();}catch(e){notice(e.message,true);}finally{busy(-1);}});});
$('discard').addEventListener('click',()=>{if(state.pending)return;state.cells.forEach(c=>c.editor.setValue(c.content));dirtyUI();notice('Alterações locais descartadas.');});
$('close-revisions').addEventListener('click',()=>$('revision-dialog').close());
$('refresh-runs').addEventListener('click',()=>loadRuns().catch(e=>notice(e.message,true)));
window.addEventListener('beforeunload',e=>{if(dirty()||state.pending){e.preventDefault();e.returnValue='';}});
(async()=>{busy(1);try{const params=new URLSearchParams(location.search);await loadBooks(params.get('caderno'));if(params.get('secao'))await loadSections(params.get('secao'));}catch(e){notice(e.message,true);}finally{busy(-1);}})();
})();
