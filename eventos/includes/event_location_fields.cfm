<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"><cfabort></cfif>
<cfset VARIABLES.eventBasicForeign=VARIABLES.eventBasicPais NEQ "BR">
<cfset VARIABLES.eventRegionName=VARIABLES.eventLocationEditor.currentRegion({pais=qEvento.pais,localizacoes=qEvento.localizacoes})>
<cfoutput>
<section class="mb-3" aria-label="Localização do evento" data-event-location>
  <input type="hidden" name="location_mode" value="#VARIABLES.eventBasicForeign ? 'foreign' : 'br'#" data-event-location-mode>
  <div class="mb-3"><label class="form-label" for="eventCountry">País do evento</label><select id="eventCountry" name="pais" class="form-select" required data-event-country>
    <option value="">Selecione o país</option><cfloop array="#VARIABLES.eventLocationEditor.countries()#" index="VARIABLES.eventCountry"><option value="#VARIABLES.eventCountry.code#" <cfif VARIABLES.eventBasicPais EQ VARIABLES.eventCountry.code>selected</cfif>>#encodeForHTML(VARIABLES.eventCountry.label)# (#VARIABLES.eventCountry.code#)</option></cfloop>
  </select></div>
  <fieldset data-event-br-fields <cfif VARIABLES.eventBasicForeign>hidden disabled</cfif>>
    <legend class="visually-hidden">Município brasileiro</legend><div class="row">
      <div class="col-md-3 mb-3"><label class="form-label" for="selectEstado">Estado / UF</label>
        <cfif VARIABLES.eventBasicDelegated><input class="form-control" name="estado" id="selectEstado" readonly value="#encodeForHTMLAttribute(VARIABLES.eventBasicEstado)#">
        <cfelse><select class="form-select" name="estado" id="selectEstado" onchange="getCidades()" required><option value="">Estado</option><cfloop query="qEstados"><option value="#encodeForHTMLAttribute(qEstados.uf)#" <cfif VARIABLES.eventBasicEstado EQ qEstados.uf>selected</cfif>>#encodeForHTML(qEstados.uf)#</option></cfloop></select></cfif>
      </div>
      <div class="col-md-9 mb-3"><label class="form-label" for="selectCidade">Cidade / município</label><select data-mdb-select-init data-mdb-filter="true" class="form-select" name="cidade" id="selectCidade" required><option value="">Cidade</option><cfloop query="qCidades"><option value="#qCidades.cod_cidade#" <cfif NOT VARIABLES.eventBasicStateChanged AND qEvento.cod_cidade EQ qCidades.cod_cidade>selected</cfif>>#encodeForHTML(qCidades.nome_cidade)#</option></cfloop></select></div>
    </div>
  </fieldset>
  <fieldset data-event-foreign-fields <cfif NOT VARIABLES.eventBasicForeign>hidden disabled</cfif>>
    <legend class="visually-hidden">Localização internacional</legend>
    <div class="mb-3"><label class="form-label" for="eventForeignCity">Cidade no exterior</label><input id="eventForeignCity" name="cidade" class="form-control" maxlength="120" required value="#encodeForHTMLAttribute(VARIABLES.eventBasicForeign ? qEvento.cidade : '')#" autocomplete="address-level2"><div class="form-text">Informe o nome local da cidade. Não é necessário código de município brasileiro.</div></div>
    <div class="row"><div class="col-md-8 mb-3"><label class="form-label" for="eventForeignRegion">Estado / região / província</label><input id="eventForeignRegion" name="regiao_internacional" class="form-control" maxlength="120" value="#encodeForHTMLAttribute(VARIABLES.eventBasicForeign ? VARIABLES.eventRegionName : '')#" autocomplete="address-level1"><div class="form-text">Nome completo, quando aplicável. Ex.: Distrito do Porto, Califórnia.</div></div>
      <div class="col-md-4 mb-3"><label class="form-label" for="eventForeignRegionCode">Sigla/código (opcional)</label><input id="eventForeignRegionCode" name="estado" class="form-control" maxlength="2" pattern="[A-Za-z0-9]{1,2}" value="#encodeForHTMLAttribute(VARIABLES.eventBasicForeign ? VARIABLES.eventBasicEstado : '')#"><div class="form-text">Até 2 letras ou números, sem obrigatoriedade.</div></div></div>
  </fieldset>
  <p class="small text-body-secondary mb-0">O endereço e as coordenadas abaixo pertencem ao local da prova. A retirada de kit permanece separada.</p>
</section>
<script src="/eventos/assets/event-location.js?v=20261022-international"></script>
</cfoutput>
