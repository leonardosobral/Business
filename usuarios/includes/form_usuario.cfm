<form method="post">

    <div class="row mb-3 g-3">

        <div class="col">

            <div data-mdb-input-init class="form-outline mb-3">
                <input type="text" name="evento" id="formEmail" class="form-control"
                       placeholder="Email (conta google)"
                       <cfif isDefined("VARIABLES.usuario")>value="<cfoutput>#VARIABLES.usuario.email#</cfoutput>"</cfif>
                       <cfif isDefined("VARIABLES.usuario")>disabled</cfif>
                       required/>
                <label class="form-label" for="formEmail">Email (conta google)</label>
            </div>

        </div>

    </div>

    <div class="row mb-3 g-3">

        <div class="col">
            <div class="form-outline" data-mdb-input-init>
                <input type="text" name="nome_comercial" id="txtNomeComercial" class="form-control" maxlength="255"
                    style="font-size: large;" required/>
                <label for="txtNomeComercial" class="form-label">Nome da empresa, canal, creator.</label>
            </div>
        </div>

        <div class="col">
            <div class="form-outline" data-mdb-input-init>
                <input type="text" name="celular" id="txtCelular" class="form-control" maxlength="16"
                    style="font-size: large;"/>
                <label for="txtCelular" class="form-label">Celular com DDD</label>
            </div>
        </div>

        <div class="col">
        <div class="form-outline" data-mdb-input-init>
            <input type="text" name="documento" id="txtInscricao" class="form-control" maxlength="50"
                style="font-size: large;" required/>
            <label for="txtInscricao" class="form-label">CNPJ, CPF, Passaporte.</label>
            <div class="invalid-feedback">Número não inválido!</div>
        </div>
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

                <div class="form-check">
                  <input class="form-check-input" type="radio" name="perfil" id="flexRadioDefault6" value="assessoria" required/>
                  <label class="form-check-label" for="flexRadioDefault6"> Assessoria </label>
                </div>

            </div>

    <cfif isDefined("URL.usuario")>
        <input type="hidden" name="acao" value="editar_usuario">
        <input type="hidden" name="id_ad_evento" value="<cfoutput>#URL.usuario#</cfoutput>">
    <cfelse>
        <input type="hidden" name="acao" value="incluir_usuario">
    </cfif>

    <button data-mdb-ripple-init type="submit" class="btn btn-primary btn-block"><cfif NOT isDefined("VARIABLES.email")>Convidar<cfelse>Salvar</cfif></button>

</form>
