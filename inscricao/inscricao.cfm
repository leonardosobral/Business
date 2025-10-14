<!--- VERIFICA LOGIN COM O GOOGLE --->

<cfif isDefined("COOKIE.id")>

        <form class="row g-3 needs-validation" novalidate method="post" action="<cfoutput>#VARIABLES.template#</cfoutput>?filtro=pagamento">

            <p class="mb-0">Dados comerciais</p>

            <div class="col-md-12">
                <div class="form-outline" data-mdb-input-init>
                    <input type="text" name="nome_comercial" id="txtNomeComercial" class="form-control" maxlength="255"
                        style="font-size: large;" required/>
                    <label for="txtNomeComercial" class="form-label">Nome da empresa, canal, creator.</label>
                </div>
            </div>

            <div class="col-md-12">
                <div class="form-outline" data-mdb-input-init>
                    <input type="text" name="celular" id="txtCelular" class="form-control" maxlength="16"
                        style="font-size: large;"/>
                    <label for="txtCelular" class="form-label">Celular com DDD</label>
                </div>
            </div>

            <div class="col-md-12">
                <div class="form-outline" data-mdb-input-init>
                    <input type="text" name="documento" id="txtInscricao" class="form-control" maxlength="50"
                        style="font-size: large;" required/>
                    <label for="txtInscricao" class="form-label">CNPJ, CPF, Passaporte.</label>
                    <div class="invalid-feedback">Número não inválido!</div>
                </div>
            </div>

            <p class="mt-3 mb-0">Atuação no mercado</p>

            <div class="col-md-12">

                <div class="form-check">
                  <input class="form-check-input" type="radio" name="perfil" id="flexRadioDefault1" value="org" required/>
                  <label class="form-check-label" for="flexRadioDefault1"> Organizador </label>
                </div>

                <div class="form-check">
                  <input class="form-check-input" type="radio" name="perfil" id="flexRadioDefault2" value="timer" required/>
                  <label class="form-check-label" for="flexRadioDefault2"> Cronometrador / Timer </label>
                </div>

                <div class="form-check">
                  <input class="form-check-input" type="radio" name="perfil" id="flexRadioDefault3" value="midia" required/>
                  <label class="form-check-label" for="flexRadioDefault3"> Creator / Media </label>
                </div>

                <div class="form-check">
                  <input class="form-check-input" type="radio" name="perfil" id="flexRadioDefault4" value="agencia" required/>
                  <label class="form-check-label" for="flexRadioDefault4"> Agência </label>
                </div>

                <div class="form-check">
                  <input class="form-check-input" type="radio" name="perfil" id="flexRadioDefault5" value="marca" required/>
                  <label class="form-check-label" for="flexRadioDefault5"> Marca </label>
                </div>

            </div>

            <div class="col-md-12">
                <input type="hidden" name="action" value="confirmar_business"/>
                <input type="hidden" name="tag_prefix" value="<cfoutput>#qPerfil.tag_prefix#</cfoutput>"/>
                <input type="hidden" name="tag" value="<cfoutput>#qPerfil.tag#</cfoutput>"/>
                <input type="hidden" name="email" value="<cfoutput>#qPerfil.email#</cfoutput>"/>
                <input type="hidden" name="id_pagina" value="<cfoutput>#qPerfil.id_pagina#</cfoutput>"/>
                <button type="submit" class="btn btn-primary shadow-3 fs-6 w-100" data-mdb-ripple-init>Prosseguir</button>
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

        <p class="text-center">Identifique-se no primeiro passo para começarmos.</p>

    </div>

</cfif>
