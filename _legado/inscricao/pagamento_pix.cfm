<!--- VERIFICA LOGIN COM O GOOGLE --->

<cfif isDefined("COOKIE.id")>

    <!--- CHECA SE TEM UMA CONTA STRAVA --->

    <cfquery name="qCheckStrava">
        select *, extract(epoch FROM current_timestamp) token_valid
        from tb_usuarios
        where id = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
        AND strava_access_token IS NOT NULL
        AND strava_expires_at IS NOT NULL
    </cfquery>

    <!--- CHECA SE TEM CUPOM --->

    <cfquery name="qCheckCupom365">
        select *
        from tb_convite
        where id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
        AND chave_acesso ILIKE 'CNA%' AND data_aceite is null
    </cfquery>

    <cfif isDefined("qCheckStrava") AND qCheckStrava.recordcount>

        <form class="row g-3 needs-validation" novalidate method="post" action="/carteira/?<cfif isDefined("URL.debug")>debug=true&</cfif>token=<cfoutput>#tobase64('roadrunners:'&now())#</cfoutput>">

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

            <div class="col-md-12">
                <div class="form-outline" data-mdb-input-init>
                    <input type="text" class="form-control" id="inputName" required maxlength="128" name="usuario_nome" aria-describedby="nameHelp" value="<cfoutput>#qPerfilCheckCompleto.name#</cfoutput>"/>
                    <label for="inputName" class="form-label">Nome Completo:</label>
                </div>
            </div>


            <!--- DADOS DE TELEFONE --->

            <div class="col-3">
                <div class="form-outline" data-mdb-input-init>
                    <input type="text" class="form-control" id="inputAssessoria" required maxlength="4" name="usuario_ddi" value="<cfoutput>#Len(trim(qPerfilCheckCompleto.ddi_usuario)) ? qPerfilCheckCompleto.ddi_usuario : '55'#</cfoutput>"/>
                    <label for="inputAssessoria" class="form-label">DDI:</label>
                </div>
            </div>

            <div class="col-3">
                <div class="form-outline" data-mdb-input-init>
                    <input type="text" class="form-control" id="inputAssessoria" required maxlength="4" name="usuario_ddd" value="<cfoutput>#qPerfilCheckCompleto.ddd_usuario#</cfoutput>"/>
                    <label for="inputAssessoria" class="form-label">DDD:</label>
                </div>
            </div>

            <div class="col-6">
                <div class="form-outline" data-mdb-input-init>
                    <input type="text" class="form-control" id="inputAssessoria" required maxlength="10" name="usuario_telefone" value="<cfoutput>#qPerfilCheckCompleto.telefone_usuario#</cfoutput>"/>
                    <label for="inputAssessoria" class="form-label">Telefone:</label>
                </div>
            </div>

            <hr class="mt-3 mb-0"/>


            <!--- CPF --->

            <div class="col-md-12">
                <div class="form-outline" data-mdb-input-init>
                    <input type="text" class="form-control" id="inputDocumento" required minlength="11" maxlength="14" name="usuario_documento"/>
                    <label for="inputDocumento" class="form-label">CPF</label>
                </div>
            </div>

            <p class="text-end m-0 text-secondary" style="font-size: x-small;"><cfoutput>#isDefined('COOKIE.produto_codigo') ? 'produto: ' & COOKIE.produto_codigo : 'produto'# | #qPerfilCheckCompleto.pais#</cfoutput></p>


            <div class="col-md-12">
                <input type="hidden" name="id_produto" value="<cfoutput>#isDefined('COOKIE.produto_codigo') ? COOKIE.produto_codigo : 'runpro'#</cfoutput>"/>
                <input type="hidden" name="id" value="<cfoutput>#qPerfilCheckCompleto.id#</cfoutput>"/>
                <input type="hidden" name="id_pagina" value="<cfoutput>#qPerfil.id_pagina#</cfoutput>"/>
                <input type="hidden" name="forma_pagamento" value="pix"/>
                <input type="hidden" name="document_type" value="CPF"/>
                <button type="submit" class="btn btn-primary shadow-3 w-100 fs-6" data-mdb-ripple-init>Enviar Dados de Pagamento</button>
            </div>

        </form>

        <script>
            // Example starter JavaScript for disabling form submissions if there are invalid fields
            (() => {
                'use strict';

                // Fetch all the forms we want to apply custom Bootstrap validation styles to
                const forms = document.querySelectorAll('.needs-validation');

                // Loop over them and prevent submission
                Array.prototype.slice.call(forms).forEach((form) => {
                    form.addEventListener('submit', (event) => {
                        if (!form.checkValidity()) {
                            event.preventDefault();
                            event.stopPropagation();
                        }
                        form.classList.add('was-validated');
                    }, false);
                });
            })();
        </script>

    <cfelse>

        <div class="text-center py-5 my-5">

            <p class="text-center">Vincule sua conta do Strava no passo anterior.</p>

        </div>

    </cfif>

<cfelse>

    <div class="text-center py-5 my-5">

        <p class="text-center">Identifique-se no primeiro passo para começarmos.</p>

    </div>

</cfif>
