<!--- VERIFICA LOGIN COM O GOOGLE --->

<cfif isDefined("COOKIE.id")>

    <!--- CHECA SE TEM CUPOM --->

    <!---cfquery name="qCheckCupom365">
        select *
        from tb_convite
        where id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
        AND chave_acesso ILIKE 'CNA%' AND data_aceite is null
    </cfquery--->

    <form class="row g-3 needs-validation" novalidate method="post" action="<cfoutput>#VARIABLES.template#</cfoutput>?filtro=finalizar">

    <div class="card bg-black bg-opacity-50">
        <div class="row p-3">
            <div class="col-md-6"><img src="/lib/images/runpro.svg" class="w-100"></div>
            <div class="col-md-6 align-content-center">
                <div class="form-check">
                    <input class="form-check-input bg-warning border-white" type="checkbox" value="" id="flexCheckChecked" checked/>
                    <label class="form-check-label" for="flexCheckChecked">Assinatura gratuita <b>Run Pro</b> para profissionais do mercado da corrida.</label>
                </div>
            </div>
        </div>
    </div>

        <!---cfif qCheckCupom365.recordcount--->
            <div class="col-md-12 text-center">
                <div class="alert alert-success">Voucher de <b>R$ 100,00</b> aplicado com sucesso. <!--- Cód.: <cfoutput>#qCheckCupom365.chave_acesso#</cfoutput>---></div>
            </div>
        <!---/cfif--->

        <!--- PERFIL DO USER LOGADO --->

        <cfquery name="qPerfilCheckCompleto">
            SELECT usr.*
            FROM tb_usuarios usr
            inner join tb_paginas_usuarios pgusr on usr.id = pgusr.id_usuario
            inner join tb_paginas pg on pg.id_pagina = pgusr.id_pagina
            WHERE usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
        </cfquery>

        <hr class="mt-3 mb-0"/>


        <!--- FORMA DE PAGAMENTO --->

        <div class="col-md-12 opacity-50">
            <label class="form-label">Pagamento:</label>
            <input type="radio" id="radioFormaPagamentoPIX" disabled class="ms-3" checked required name="forma_pagamento" value="pix"/> <label for="radioFormaPagamentoPIX">PIX</label>
            <input type="radio" id="radioFormaPagamentoCC" disabled class="ms-3" required name="forma_pagamento" value="cc"/> <label for="radioFormaPagamentoCC">Cartão de Crédito</label>
            <input type="radio" id="radioFormaPagamentointernacional" disabled class="ms-3" required name="forma_pagamento" value="internacional"/> <label for="radioFormaPagamentointernacional">Cartão Internacional</label>
        </div>


        <p class="text-end m-0 text-secondary" style="font-size: x-small;"><cfoutput>#isDefined('COOKIE.produto_codigo') ? 'produto: ' & COOKIE.produto_codigo : 'produto'# | #qPerfilCheckCompleto.pais#</cfoutput></p>


        <div class="col-md-12">
            <input type="hidden" name="id_produto" value="<cfoutput>#isDefined('COOKIE.produto_codigo') ? COOKIE.produto_codigo : 'runpro'#</cfoutput>"/>
            <input type="hidden" name="id" value="<cfoutput>#qPerfilCheckCompleto.id#</cfoutput>"/>
            <input type="hidden" name="id_pagina" value="<cfoutput>#qPerfil.id_pagina#</cfoutput>"/>
            <button type="submit" class="btn btn-primary shadow-3 w-100 fs-6" data-mdb-ripple-init>Prosseguir</button>
        </div>

    </form>

<cfelse>

    <div class="text-center py-5 my-5">

        <p class="text-center">Identifique-se no primeiro passo para começarmos.</p>

    </div>

</cfif>
