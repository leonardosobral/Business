<cfif NOT structKeyExists(VARIABLES,"pilot") OR NOT VARIABLES.pilot><cfheader statuscode="404"/><cfabort/></cfif>
<cfif !structIsEmpty(row)>
    <cfoutput>
    <section class="card p-4 mb-3">
        <h2 class="h5">#esc(len(row.sponsor_name ?: "") ? row.sponsor_name : "Cotação de zona patrocinada")#</h2>
        <p class="mb-1">#esc(row.hex_count)# área(s) de #dateFormat(row.starts_on,"dd/mm/yyyy")# até #dateFormat(row.ends_on,"dd/mm/yyyy")# (término exclusivo)</p>
        <p class="h4 my-2">#esc(money(row.amount_cents))#</p>
        <p class="mb-1">Jogo · #esc(gameLabel(row))#</p><p>Cobrança · #esc(paymentLabel(row))#</p>
        <cfif !val(row.order_id ?: 0)><p class="mb-0">Válida até #dateTimeFormat(row.expires_at,"dd/mm/yyyy HH:nn","America/Sao_Paulo")# (Brasília).</p></cfif>
    </section>
    <cfif canBuy>
    <form method="post" class="card p-4 mb-3">
        <input type="hidden" name="zone_ref" value="#encodeForHTMLAttribute(row.reference)#"><input type="hidden" name="zone_csrf" value="#encodeForHTMLAttribute(csrf)#">
        <cfif !val(row.order_id ?: 0)>
            <cfif !len(row.game_status ?: "")>
                <button class="btn btn-warning align-self-start" name="zone_action" value="reserve">Reservar a área</button>
            <cfelse>
                <h2 class="h5">Dados da compra</h2>
                <div class="row g-3 mb-3">
                    <label class="col-md-6">Marca exibida no mapa<input class="form-control" name="zone_brand" required maxlength="80" minlength="2"></label>
                    <label class="col-md-6">URL da logo (opcional)<input class="form-control" type="url" name="zone_logo" maxlength="1000" placeholder="https://"></label>
                    <label class="col-md-6">Nome do cliente<input class="form-control" name="zone_customer" required maxlength="200"></label>
                    <label class="col-md-6">E-mail do cliente<input class="form-control" type="email" name="zone_email" required maxlength="200"></label>
                    <label class="col-md-6">CPF ou CNPJ (opcional)<input class="form-control" name="zone_document" maxlength="20"></label>
                </div><button class="btn btn-warning align-self-start" name="zone_action" value="order">Criar pedido de teste</button>
            </cfif>
        <cfelse>
            <div class="d-flex flex-wrap gap-2">
            <cfif listFind("pending_payment,draft",row.game_status ?: "") && !len(row.received_at ?: "")>
                <cfif row.checkout_state=="new"><button class="btn btn-warning" name="zone_action" value="checkout">Gerar cobrança de teste</button></cfif>
                <cfif row.checkout_state=="ready" && api.payments().isCheckoutUrlAllowed(row.checkout_url ?: "")><a class="btn btn-warning" rel="noopener noreferrer" target="_blank" href="#encodeForHTMLAttribute(row.checkout_url)#">Abrir pagamento de teste</a></cfif>
            </cfif>
            <button class="btn btn-outline-light" name="zone_action" value="sync">Conferir pagamento</button></div>
        </cfif>
    </form></cfif>
    <cfif val(row.order_id ?: 0)>
        <cfif structIsEmpty(stats)><a href="?ref=#encodeForURL(row.reference)#&amp;report=1">Ver relatório da zona</a>
        <cfelse><section class="card p-4"><h2 class="h5">Desempenho da zona</h2>
        <p class="mb-0">Visualizações da logo · #esc(stats.logo_views)#<br>Alcance · #esc(stats.reach)#<br>Passagens · #esc(stats.passes)#<br>Corredores únicos · #esc(stats.unique_runners)#</p></section></cfif>
    </cfif></cfoutput>
<cfelseif view=="nova" AND canBuy>
    <form method="post" class="card p-3 p-md-4" id="zone-sale">
        <cfoutput><input type="hidden" name="zone_csrf" value="#encodeForHTMLAttribute(csrf)#"></cfoutput>
        <h2 class="h5">Selecionar área</h2>
        <cfinclude template="zone_map.cfm"/>
        <div class="row g-3 mb-3"><label class="col-sm-6">Primeiro dia<input class="form-control" type="date" name="zone_start" required></label><label class="col-sm-6">Término (dia já fora da campanha)<input class="form-control" type="date" name="zone_end" required></label></div>
        <button class="btn btn-warning align-self-start" name="zone_action" value="quote">Consultar preço e disponibilidade</button>
    </form>
<cfelse>
    <h2 class="h5">Pedidos da conta</h2>
    <cfif rows.recordCount><div class="list-group"><cfoutput query="rows"><a class="list-group-item list-group-item-action py-3" href="?ref=#encodeForURL(rows.reference)#"><strong>#esc(len(rows.sponsor_name) ? rows.sponsor_name : "Cotação")# · #esc(money(rows.amount_cents))#</strong><br>#esc(rows.hex_count)# área(s) · #dateFormat(rows.starts_on,"dd/mm/yyyy")# a #dateFormat(rows.ends_on,"dd/mm/yyyy")# · #esc(gameLabel(queryGetRow(rows,rows.currentRow)))#</a></cfoutput></div>
    <cfelse><p>A conta ainda não tem pedidos ou cotações em aberto.</p></cfif>
</cfif>
