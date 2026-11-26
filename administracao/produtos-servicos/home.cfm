<cfprocessingdirective pageencoding="utf-8"/>
<cfif compareNoCase(getBaseTemplatePath(), getCurrentTemplatePath()) EQ 0 OR NOT isDefined("requireAdminAllowed") OR NOT requireAdminAllowed>
    <cfheader statuscode="403"/><cfabort/>
</cfif>
<h1 class="business-page-title mb-3">Produtos e serviços RH</h1>
<cfif NOT catalogoInstalado.pronto>
    <p role="status" class="business-panel p-3">O catálogo aguarda a instalação da tabela pelo DataGrip.</p>
<cfelseif NOT catalogo.recordCount>
    <p role="status" class="business-panel p-3">Nenhum produto ou serviço cadastrado.</p>
<cfelse>
    <p class="text-muted">Selecione um item para consultar as regras comerciais e a origem dos registros.</p>
    <div class="row g-4">
        <cfoutput query="catalogo" group="grupo">
            <section class="col-12 col-xl-6">
                <h2 class="h5 mb-3">#encodeForHTML(grupo)#</h2>
                <cfoutput>
                    <details class="business-panel mb-2" id="#encodeForHTMLAttribute(codigo)#"<cfif codigo EQ "selo-verificado"> open</cfif>>
                        <summary class="p-3 fw-bold">#encodeForHTML(nome)#</summary>
                        <dl class="row border-top g-0 mb-0 p-3 text-break">
                            <dt class="col-sm-4">Quem compra</dt>
                            <dd class="col-sm-8">#encodeForHTML(comprador)#</dd>
                            <dt class="col-sm-4">Como é cobrado</dt>
                            <dd class="col-sm-8">#encodeForHTML(cobranca)#</dd>
                            <dt class="col-sm-4">Quando começa</dt>
                            <dd class="col-sm-8">#encodeForHTML(inicio)#</dd>
                            <dt class="col-sm-4">Quando termina</dt>
                            <dd class="col-sm-8">#encodeForHTML(termino)#</dd>
                            <dt class="col-sm-4">Onde fica registrado</dt>
                            <dd class="col-sm-8 mb-0">#encodeForHTML(registro)#</dd>
                        </dl>
                        <cfif len(trim(a_confirmar))>
                            <p class="border-top px-3 py-2 mb-0"><strong class="text-warning">A confirmar</strong><br/>#encodeForHTML(a_confirmar)#</p>
                        </cfif>
                    </details>
                </cfoutput>
            </section>
        </cfoutput>
    </div>
</cfif>
