<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0 OR NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin><cfheader statuscode="403"/><cfabort/></cfif>
<cfif VARIABLES.mediaHasEventId AND VARIABLES.mediaEditId GT 0>
 <section class="media-event-editor p-3 mb-3" id="video-evento" aria-labelledby="media-event-heading">
  <cfif NOT qMediaEventEdit.recordcount>
   <div class="alert alert-warning mb-2">Vídeo não encontrado. Ele pode ter sido removido.</div>
   <cfoutput><a href="#encodeForHTMLAttribute(VARIABLES.mediaListUrl)#" class="btn btn-sm btn-outline-light">Voltar à lista</a></cfoutput>
  <cfelse>
   <cfoutput>
   <div class="d-flex justify-content-between align-items-start gap-3 mb-3">
    <div><h2 class="h5 mb-1" id="media-event-heading">Vincular vídeo a um evento</h2><div class="fw-semibold">#encodeForHTML(qMediaEventEdit.media_titulo)#</div><div class="small text-muted">Vídeo ###qMediaEventEdit.media_pk# · Esse vínculo não altera a publicação nem o destaque na home.</div></div>
    <a class="btn btn-sm btn-outline-light" href="#encodeForHTMLAttribute(VARIABLES.mediaListUrl)#" aria-label="Fechar edição do vínculo">Fechar</a>
   </div>
   <div class="row g-3">
    <div class="col-12 col-xl-4">
     <div class="small text-muted mb-1">Evento atual</div>
     <cfif val(qMediaEventEdit.id_evento) GT 0>
      <a class="fw-semibold text-reset" href="/eventos/?id_evento=#val(qMediaEventEdit.id_evento)#">#encodeForHTML(qMediaEventEdit.evento_nome ?: ('Evento ' & qMediaEventEdit.id_evento))#</a>
      <div class="small text-muted">ID #val(qMediaEventEdit.id_evento)#<cfif isDate(qMediaEventEdit.evento_data_inicial)> · #lsDateFormat(qMediaEventEdit.evento_data_inicial,"dd/mm/yyyy")#</cfif> · #encodeForHTML(qMediaEventEdit.evento_cidade ?: '')#<cfif len(qMediaEventEdit.evento_estado ?: '')>/#encodeForHTML(qMediaEventEdit.evento_estado)#</cfif></div>
      <form method="post" action="#encodeForHTMLAttribute(VARIABLES.mediaListUrl)#&amp;video_id=#qMediaEventEdit.media_pk###video-evento" class="mt-2" onsubmit="return confirm('Remover apenas o vínculo deste vídeo com o evento?');">
       <input type="hidden" name="media_event_action" value="remover"/><input type="hidden" name="media_event_csrf" value="#encodeForHTMLAttribute(VARIABLES.mediaEventCsrf)#"/>
       <input type="hidden" name="media_id" value="#qMediaEventEdit.media_pk#"/><input type="hidden" name="expected_event_id" value="#val(qMediaEventEdit.id_evento)#"/>
       <button type="submit" class="btn btn-sm btn-outline-danger">Remover vínculo</button>
      </form>
     <cfelse><p class="text-muted mb-0">Sem evento vinculado. Busque e selecione a prova ao lado.</p></cfif>
    </div>
    <div class="col-12 col-xl-8">
     <form method="get" action="./##video-evento" class="d-flex flex-wrap gap-2 align-items-end">
      <input type="hidden" name="pagina" value="#VARIABLES.mediaPage#"/><input type="hidden" name="busca" value="#encodeForHTMLAttribute(VARIABLES.mediaSearchTerm)#"/>
      <input type="hidden" name="status" value="#VARIABLES.mediaStatusFilter#"/><input type="hidden" name="destaque" value="#VARIABLES.mediaFeaturedFilter#"/><input type="hidden" name="vinculo" value="#VARIABLES.mediaLinkFilter#"/><input type="hidden" name="video_id" value="#qMediaEventEdit.media_pk#"/>
      <div class="flex-grow-1"><label class="form-label" for="media-event-search">Buscar evento por nome, cidade, tag ou ID</label><input class="form-control" type="search" name="evento_busca" id="media-event-search" value="#encodeForHTMLAttribute(URL.evento_busca)#" maxlength="150" placeholder="Ex.: Maratona de Maringá ou 43381" required/></div>
      <button class="btn btn-outline-warning" type="submit">Buscar evento</button>
     </form>
   </cfoutput>
     <cfif len(trim(URL.evento_busca))>
      <cfif qMediaFeaturedEventSearch.recordcount>
       <cfoutput><form method="post" action="#encodeForHTMLAttribute(VARIABLES.mediaListUrl)#&amp;video_id=#qMediaEventEdit.media_pk###video-evento" class="mt-3">
        <input type="hidden" name="media_event_action" value="salvar"/><input type="hidden" name="media_event_csrf" value="#encodeForHTMLAttribute(VARIABLES.mediaEventCsrf)#"/>
        <input type="hidden" name="media_id" value="#qMediaEventEdit.media_pk#"/><input type="hidden" name="expected_event_id" value="#val(qMediaEventEdit.id_evento)#"/>
        <fieldset><legend class="small fw-semibold">Selecione o evento correto · #qMediaFeaturedEventSearch.recordcount# resultado(s), até 30 por busca</legend>
         <div class="media-event-search-results mb-3">
          <cfloop query="qMediaFeaturedEventSearch">
           <label class="media-event-search-option"><input class="form-check-input mt-1" type="radio" name="id_evento" value="#qMediaFeaturedEventSearch.id_evento#" required/>
            <span><span class="fw-semibold d-block">#encodeForHTML(qMediaFeaturedEventSearch.nome_evento)#</span><span class="small text-muted d-block">ID #qMediaFeaturedEventSearch.id_evento#<cfif isDate(qMediaFeaturedEventSearch.data_inicial)> · #lsDateFormat(qMediaFeaturedEventSearch.data_inicial,"dd/mm/yyyy")#</cfif> · #encodeForHTML(qMediaFeaturedEventSearch.cidade ?: '')#<cfif len(qMediaFeaturedEventSearch.estado ?: '')>/#encodeForHTML(qMediaFeaturedEventSearch.estado)#</cfif><cfif NOT qMediaFeaturedEventSearch.ativo> · Inativo</cfif></span></span>
           </label>
          </cfloop>
         </div>
        </fieldset>
        <button class="btn btn-warning" type="submit">Salvar vínculo com o evento selecionado</button>
       </form></cfoutput>
      <cfelse><div role="status" class="alert alert-warning mt-3 mb-0">Nenhum evento encontrado. Use pelo menos dois caracteres, o ID ou outra parte do nome/cidade.</div></cfif>
     <cfelse><p class="small text-muted mt-2 mb-0">Confira a data e a cidade para evitar vincular a outra edição da prova.</p></cfif>
    </div>
   </div>
  </cfif>
 </section>
</cfif>
