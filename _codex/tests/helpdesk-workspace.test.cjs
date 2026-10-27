const test=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const {JSDOM}=require('jsdom');
const script=fs.readFileSync('helpdesk/assets/workspace.js','utf8');
const doms=[];
test.afterEach(()=>doms.splice(0).forEach(dom=>dom.window.close()));
test('includes internos rejeitam acesso sem contexto administrativo',()=>{for(const name of ['workspace-init.cfm','workspace-actions.cfm','workspace-sectors.cfm','workspace.cfm']){const source=fs.readFileSync('helpdesk/includes/'+name,'utf8');assert.match(source,/NOT structKeyExists\(VARIABLES,"helpdeskCanManage"\) OR NOT VARIABLES.helpdeskCanManage/);assert.match(source,/<cfheader statuscode="403"\/><cfabort\/>/);}});
function fixture(text='') {
  const dom=new JSDOM(`<form data-hd-reply>
    <input type="radio" name="message_kind" value="publica" checked>
    <input type="radio" name="message_kind" value="nota">
    <span data-hd-editor-title></span><span data-hd-visibility></span>
    <textarea name="ticket_mensagem"></textarea>
    <span data-hd-feedback></span><span data-hd-count></span>
    <div data-hd-public-panel><select data-hd-template>
      <option value="">Escolha</option><option value="contexto" data-text="Olá! Pode nos enviar mais informações?">Contexto</option>
    </select><button type="button" data-hd-insert>Inserir</button></div>
    <button data-hd-public-panel value="responder_ticket">Responder</button>
    <button data-hd-public-panel value="atualizar_ticket">Salvar status</button>
    <button data-hd-note-button value="nota_ticket">Salvar nota interna</button>
    </form>`,{runScripts:'outside-only'});
  doms.push(dom);const {window}=dom;const form=window.document.querySelector('form');
  const nodes={};let confirm=true;
  for(const key of ['[name="ticket_mensagem"]','[data-hd-feedback]','[data-hd-count]','[data-hd-insert]','[data-hd-template]']) nodes[key]=form.querySelector(key);
  const editor=nodes['[name="ticket_mensagem"]'];editor.value=text;
  window.confirm=()=>confirm;window.eval(script);
  return {editor,nodes,confirm:value=>confirm=value,insert(key){nodes['[data-hd-template]'].value=key;nodes['[data-hd-insert]'].click();},
    submit(value){const button=window.document.createElement('button');button.value=value;form.append(button);const e=new window.SubmitEvent('submit',{submitter:button,cancelable:true});form.dispatchEvent(e);button.remove();return {prevented:e.defaultPrevented};},
    leave(){const e=new window.Event('beforeunload',{cancelable:true});window.dispatchEvent(e);return {prevented:e.defaultPrevented};},pageshow(){window.dispatchEvent(new window.Event('pageshow'));},edit(value){editor.value=value;editor.dispatchEvent(new window.Event('input',{bubbles:true}));}};
}
test('resposta rápida preserva o texto humano e não envia',()=>{const f=fixture('Texto humano');f.insert('contexto');assert.match(f.editor.value,/^Texto humano\n\nOlá!/);assert.equal(f.leave().prevented,true);});
test('resposta rápida respeita o limite sem truncar o rascunho',()=>{const initial='a'.repeat(11990),f=fixture(initial);f.insert('contexto');assert.equal(f.editor.value,initial);assert.match(f.nodes['[data-hd-feedback]'].textContent,/ultrapassaria/);});
test('modelo não escolhido não altera o editor',()=>{const f=fixture('texto');f.insert('');assert.equal(f.editor.value,'texto');});
test('envio em branco é bloqueado; status sem mensagem é permitido',()=>{const f=fixture('  ');assert.equal(f.submit('responder_ticket').prevented,true);assert.notEqual(f.submit('atualizar_ticket').prevented,true);});
test('salvar somente status exige confirmação para descartar texto',()=>{const f=fixture('Rascunho importante');f.confirm(false);assert.equal(f.submit('atualizar_ticket').prevented,true);assert.equal(f.editor.value,'Rascunho importante');f.confirm(true);assert.notEqual(f.submit('atualizar_ticket').prevented,true);});
test('duplo envio é bloqueado e retorno pelo navegador reabilita',()=>{const f=fixture('Resposta');assert.notEqual(f.submit('responder_ticket').prevented,true);assert.equal(f.submit('responder_ticket').prevented,true);assert.notEqual(f.leave().prevented,true);f.pageshow();assert.notEqual(f.submit('responder_ticket').prevented,true);});
test('edição atualiza contador e protege contra navegação acidental',()=>{const f=fixture();assert.notEqual(f.leave().prevented,true);f.edit('12345');assert.match(f.nodes['[data-hd-count]'].textContent,/5 \/ 12/);assert.equal(f.leave().prevented,true);});
test('ação desconhecida e resposta longa não submetem',()=>{const f=fixture('a'.repeat(12001));assert.equal(f.submit('responder_ticket').prevented,true);assert.equal(f.submit('outra').prevented,true);});
test('ações administrativas exigem POST, CSRF, revisão e transação',()=>{const source=fs.readFileSync('helpdesk/includes/workspace-actions.cfm','utf8');assert.match(source,/CGI.request_method NEQ "POST"/);assert.match(source,/SESSION.helpdeskCsrf/);assert.match(source,/<cftransaction>/);assert.match(source,/FOR UPDATE/);assert.match(source,/ticket_revision/);assert.match(source,/ticket_last_message/);assert.match(source,/<cfif hdActionReply>[\s\S]*INSERT INTO tb_helpdesk_mensagens/);assert.match(source,/<cfif hdActionReply><cftry><cfset helpdeskNotifyTicketOwner/);});
test('paginação no servidor e busca parametrizada compartilham o filtro',()=>{const source=fs.readFileSync('helpdesk/includes/HelpdeskWorkspace.cfc','utf8');assert.match(source,/LIMIT :limite OFFSET :deslocamento/);assert.match(source,/ESCAPE '!'/);assert.match(source,/p.params.busca=/);assert.match(source,/result.total=queryExecute\("SELECT count\(\*\) AS total" & base & p.sql/);assert.match(source,/result.page=min\(arguments.filters.pagina,result.pages\)/);});
test('área do usuário preserva escopo por dono e oculta mensagens internas',()=>{const source=fs.readFileSync('helpdesk/includes/backend.cfm','utf8');assert.match(source,/VARIABLES.helpdeskCanManage><cfinclude template="workspace-init.cfm"/);assert.match(source,/AND cham.id_usuario = <cfqueryparam/);assert.match(source,/NOT VARIABLES.helpdeskCanManage>AND msg.interno=false/);assert.doesNotMatch(source,/SET ativo =[^\n]*URL.setor_status/);});
test('editor oferece respostas rápidas e distingue resposta pública de nota interna',()=>{const source=fs.readFileSync('helpdesk/includes/workspace.cfm','utf8');assert.match(source,/template="workspace-replies.cfm"/);assert.match(source,/data-hd-template/);assert.match(source,/value="publica"/);assert.match(source,/value="nota"/);assert.match(source,/value="nota_ticket"/);assert.match(source,/indicadores não usam os filtros da fila/);assert.match(source,/encodeForHTML\(qHelpdeskMensagens.mensagem\)/);assert.match(source,/name="ticket_mensagem"/);});
