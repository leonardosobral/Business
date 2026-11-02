<cfprocessingdirective pageencoding="utf-8"/>
<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<cfif VARIABLES.postRace.enabled><cfoutput>
<section id="pos-prova" class="rr-race-guide rr-post-race" aria-labelledby="post-race-heading" data-post-race>
    <h2 id="post-race-heading">#encodeForHTML(VARIABLES.postRaceText.heading)#</h2>
    <p>#encodeForHTML(VARIABLES.postRaceText.intro)# <strong>#encodeForHTML(VARIABLES.postRace.dateLabel)#</strong> · #encodeForHTML(qEvento.cidade[1])#<cfif len(trim(qEvento.estado[1] & ""))> (#encodeForHTML(qEvento.estado[1])#)</cfif>.</p>
    <div class="rr-post-race-actions">
        <cfif VARIABLES.postRace.results>
            <a class="rr-race-cta" href="https://openresults.run/evento/#encodeForHTMLAttribute(replace(encodeForURL(qEvento.tag[1]),'+','%20','all'))#/" target="_blank" rel="noopener">#encodeForHTML(VARIABLES.postRaceText.results)#</a>
        <cfelseif NOT len(VARIABLES.postRace.resultSource)><p class="rr-race-note">#encodeForHTML(VARIABLES.postRaceText.missing)#</p></cfif>
        <cfif len(VARIABLES.postRace.resultSource)><a href="#encodeForHTMLAttribute(VARIABLES.postRace.resultSource)#" target="_blank" rel="noopener">#encodeForHTML(VARIABLES.postRaceText.source)#</a></cfif>
    </div>
    <cfif arrayLen(VARIABLES.postRace.galleries)>
        <button type="button" class="btn btn-light w-100 my-2" data-mdb-ripple-init data-mdb-modal-init data-mdb-target="##modal_cupom_foco"
            data-mdb-valor-badge="#encodeForHTMLAttribute(VARIABLES.eventFocoValor)#" data-mdb-numero-peito=""
            data-mdb-complemento-badge="#encodeForHTMLAttribute(VARIABLES.eventFocoGalleryToken)#"
            data-mdb-foco-galleries="#encodeForHTMLAttribute(serializeJSON(VARIABLES.postRace.galleries))#"><i class="fa-solid fa-camera" aria-hidden="true"></i> #encodeForHTML(VARIABLES.postRaceText.photos)#</button>
        <details class="rr-race-details"><summary>Foco Radical</summary><ul class="rr-race-links">
            <cfloop array="#VARIABLES.postRace.galleries#" index="postRacePhoto"><li><a href="#encodeForHTMLAttribute(postRacePhoto.url)#" target="_blank" rel="sponsored noopener">#encodeForHTML(postRacePhoto.name)#</a></li></cfloop>
        </ul></details>
    <cfelse><p class="rr-race-note">#encodeForHTML(VARIABLES.postRaceText.photosMissing)#</p></cfif>
    <cfif NOT structIsEmpty(VARIABLES.postRace.nextEdition)>
        <details class="rr-race-details"><summary>#encodeForHTML(VARIABLES.postRaceText.next)# · #encodeForHTML(VARIABLES.postRace.nextEdition.dateLabel)#</summary>
            <p>#encodeForHTML(VARIABLES.postRace.nextEdition.name)#</p><p><a href="#encodeForHTMLAttribute(VARIABLES.postRace.nextEdition.path)#">#encodeForHTML(VARIABLES.postRaceText.details)#</a></p>
        </details>
    <cfelseif qAgrega.recordCount AND qAgrega.tipo_agregacao[1] EQ "maratona"><p class="rr-race-note">#encodeForHTML(VARIABLES.postRaceText.noNext)#</p></cfif>
    <cfif len(VARIABLES.postRace.calendar)><p class="mt-2"><a href="#encodeForHTMLAttribute(VARIABLES.postRace.calendar)#" hreflang="pt-BR">#encodeForHTML(VARIABLES.postRaceText.calendar)#</a></p></cfif>
    <p class="rr-race-note">#encodeForHTML(VARIABLES.postRaceText.note)#</p>
</section>
</cfoutput></cfif>
