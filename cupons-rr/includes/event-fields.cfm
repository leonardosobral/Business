<cfif NOT structKeyExists(VARIABLES,'cpAccess')><cfheader statuscode="403"/><cfabort/></cfif>
<cfoutput>
<div data-cp-picker>
<label for="cp-event-#cpPickerPrefix#">Pesquisar evento *</label>
<div class="cp-event-search"><input class="form-control" type="search" id="cp-event-#cpPickerPrefix#" data-cp-search placeholder="Nome ou tag do evento" maxlength="100" autocomplete="off"/><button type="button" class="btn btn-outline-secondary" data-cp-find>Buscar eventos</button></div>
<label for="cp-event-select-#cpPickerPrefix#" class="mt-2">Evento selecionado *</label>
<select class="form-select" id="cp-event-select-#cpPickerPrefix#" name="id_evento" required data-cp-results><option value="">Pesquise e escolha um evento</option>
<cfif len(cpError) AND cpService.id(FORM.id_evento ?: '')><cfset cpKeep=cpService.events(cpAccess,'',cpService.id(FORM.id_evento))/><cfloop query="cpKeep"><cfif cpKeep.id_evento EQ cpService.id(FORM.id_evento)><option value="#cpKeep.id_evento#" selected>#encodeForHTML(cpKeep.nome_evento)#</option></cfif></cfloop></cfif>
</select><small data-cp-search-status role="status">Apenas eventos que você pode operar são selecionáveis.</small>
</div>
<div class="cp-fields mt-3"><div><label for="cp-start-#cpPickerPrefix#">Válido a partir de *</label><input class="form-control" id="cp-start-#cpPickerPrefix#" name="inicio" type="date" required value="#encodeForHTMLAttribute(len(cpError) ? (FORM.inicio ?: '') : dateFormat(now(),'yyyy-mm-dd'))#"/></div><div><label for="cp-end-#cpPickerPrefix#">Válido até *</label><input class="form-control" id="cp-end-#cpPickerPrefix#" name="fim" type="date" required value="#encodeForHTMLAttribute(len(cpError) ? (FORM.fim ?: '') : '')#"/></div><div class="cp-full"><label for="cp-quantity-#cpPickerPrefix#">Quantidade acordada (opcional)</label><input class="form-control" id="cp-quantity-#cpPickerPrefix#" name="quantidade" type="number" min="1" max="999999999" step="1" value="#encodeForHTMLAttribute(len(cpError) ? (FORM.quantidade ?: '') : '')#"/><small>Registro do limite combinado. O consumo deve ser controlado na plataforma de inscrição.</small></div></div>
</cfoutput>
