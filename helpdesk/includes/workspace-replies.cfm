<cfif NOT (VARIABLES.helpdeskCanManage ?: false)><cfheader statuscode="403"/><cfabort/></cfif>
<cfscript>
hdEditReply={id='',title='',text=''};
for(hdItem in hdReplyLibrary.items)if(hdItem.id EQ (URL.resposta_id ?: ''))hdEditReply=duplicate(hdItem);
if(len(hdError) AND (FORM.helpdesk_action ?: '') EQ 'salvar_resposta_rapida')hdEditReply={id=FORM.resposta_id ?: '',title=FORM.resposta_titulo ?: '',text=FORM.resposta_texto ?: ''};
</cfscript>
<cfoutput>
<section class="hd-replies-library" id="hd-replies" aria-label="Gerenciar respostas rápidas">
  <div class="hd-panel-heading"><div><h2>Respostas rápidas da equipe</h2><p>Compartilhadas entre atendentes. Inserir um modelo apenas preenche o rascunho; revise antes de enviar.</p></div><span class="hd-count">#arrayLen(hdReplyLibrary.items)# / 100</span></div>
  <cfif len(hdError)><div class="alert alert-warning" role="alert">#encodeForHTML(hdError)#</div></cfif>
  <cfif len(hdLibraryError)><div class="alert alert-warning" role="alert">#encodeForHTML(hdLibraryError)#</div></cfif>
  <cfif (URL.salvo ?: '') EQ 'modelo'><div class="alert alert-success" role="status">Biblioteca de respostas rápidas atualizada.</div></cfif>
  <div class="hd-library-grid">
    <div class="hd-library-list">
      <cfif NOT arrayLen(hdReplyLibrary.items)><p class="hd-empty">Nenhuma resposta cadastrada. Crie o primeiro modelo ao lado.</p></cfif>
      <cfloop array="#hdReplyLibrary.items#" item="hdItem">
        <article class="hd-library-item"><h3>#encodeForHTML(hdItem.title)#</h3><p>#encodeForHTML(hdItem.text)#</p><div class="hd-inline">
          <a class="btn btn-outline-secondary btn-sm" href="#encodeForHTMLAttribute(hdUrl({respostas=1,resposta_id=hdItem.id}))###hd-reply-edit">Editar</a>
          <form method="post" action="#encodeForHTMLAttribute(hdUrl({respostas=1}))###hd-replies" data-hd-remove-reply><input type="hidden" name="helpdesk_csrf" value="#encodeForHTMLAttribute(SESSION.helpdeskCsrf)#"/><input type="hidden" name="helpdesk_action" value="remover_resposta_rapida"/><input type="hidden" name="resposta_id" value="#encodeForHTMLAttribute(hdItem.id)#"/><input type="hidden" name="respostas_revision" value="#encodeForHTMLAttribute(hdReplyLibrary.revision)#"/><label class="hd-remove-confirm"><input type="checkbox" required name="confirmar_remocao" value="1"/> Confirmar remoção</label><button class="btn btn-outline-danger btn-sm" type="submit">Remover</button></form>
        </div></article>
      </cfloop>
    </div>
    <form class="hd-library-editor" id="hd-reply-edit" method="post" action="#encodeForHTMLAttribute(hdUrl({respostas=1,resposta_id=hdEditReply.id}))###hd-reply-edit" data-hd-library-editor>
      <h3><cfif len(hdEditReply.id)>Editar resposta rápida<cfelse>Nova resposta rápida</cfif></h3>
      <input type="hidden" name="helpdesk_csrf" value="#encodeForHTMLAttribute(SESSION.helpdeskCsrf)#"/><input type="hidden" name="helpdesk_action" value="salvar_resposta_rapida"/><input type="hidden" name="resposta_id" value="#encodeForHTMLAttribute(hdEditReply.id)#"/><input type="hidden" name="respostas_revision" value="#encodeForHTMLAttribute(hdReplyLibrary.revision)#"/>
      <label for="hd-reply-title">Título para a equipe</label><input id="hd-reply-title" name="resposta_titulo" class="form-control" maxlength="80" required value="#encodeForHTMLAttribute(hdEditReply.title)#" placeholder="Ex.: Solicitar número de peito"/>
      <label for="hd-reply-text">Mensagem do modelo</label><textarea id="hd-reply-text" name="resposta_texto" class="form-control" rows="10" maxlength="12000" required placeholder="Escreva a mensagem que será inserida no rascunho.">#encodeForHTML(hdEditReply.text)#</textarea>
      <p class="hd-action-note">Texto simples. Personalize nomes e dados no rascunho de cada chamado.</p>
      <div class="hd-inline mt-3"><button class="btn btn-warning" type="submit" <cfif len(hdLibraryError)>disabled</cfif>>Salvar resposta rápida</button><cfif len(hdEditReply.id)><a class="btn btn-outline-secondary" href="#encodeForHTMLAttribute(hdUrl({respostas=1}))###hd-reply-edit">Cancelar edição / Nova</a></cfif></div>
    </form>
  </div>
</section>
</cfoutput>
