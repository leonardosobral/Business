<!--- VERIFICA LOGIN COM O GOOGLE --->

<cfif isDefined("COOKIE.id")>

    <!--- CHECA SE TEM CUPOM --->

    <cfquery name="qCheckCupom365">
        select *
        from tb_convite
        where id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
        AND chave_acesso ILIKE 'CNA%' AND data_aceite is null
    </cfquery>

    <form class="row g-3 needs-validation" novalidate method="post" action="<cfoutput>#VARIABLES.template#</cfoutput>?filtro=pagamento">

        <cfif qCheckCupom365.recordcount>
            <div class="col-md-12">
                <div class="alert alert-success">Cupom <b>de 10% de desconto</b> aplicado com sucesso. Cód.: <cfoutput>#qCheckCupom365.chave_acesso#</cfoutput></div>
            </div>
        </cfif>

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

        <div class="col-md-12">
            <label for="radioFormaPagamentoPIX" class="form-label">Pagamento:</label>
            <input type="radio" id="radioFormaPagamentoPIX" class="ms-3" checked required name="forma_pagamento" value="pix"/> PIX
            <input type="radio" id="radioFormaPagamentoCC" class="ms-3" required name="forma_pagamento" value="cc"/> Cartão de Crédito
            <input type="radio" id="radioFormaPagamentointernacional" class="ms-3" required name="forma_pagamento" value="internacional"/> Cartão Internacional
        </div>


        <p class="text-end m-0 text-secondary" style="font-size: x-small;"><cfoutput>#isDefined('COOKIE.produto_codigo') ? 'produto: ' & COOKIE.produto_codigo : 'produto'# | #qPerfilCheckCompleto.pais#</cfoutput></p>


        <div class="col-md-12">
            <input type="hidden" name="id_produto" value="<cfoutput>#isDefined('COOKIE.produto_codigo') ? COOKIE.produto_codigo : 'runpro'#</cfoutput>"/>
            <input type="hidden" name="id" value="<cfoutput>#qPerfilCheckCompleto.id#</cfoutput>"/>
            <input type="hidden" name="id_pagina" value="<cfoutput>#qPerfil.id_pagina#</cfoutput>"/>
            <button type="submit" class="btn btn-primary shadow-3 w-100 fs-6" data-mdb-ripple-init>Escolher Forma de Pagamento</button>
        </div>

    </form>

<cfelse>

    <div class="text-center py-5 my-5">

        <p class="text-center">Identifique-se no primeiro passo para começarmos.</p>

    </div>

</cfif>
