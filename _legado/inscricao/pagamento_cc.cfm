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


            <!--- DADOS DO CARTAO DE CREDITO --->

            <div class="mb-3 col-md-6">
                <div class="form-outline" data-mdb-input-init>
                    <input type="text" class="form-control" id="inputCartaoNome" required maxlength="64" name="cartao_nome"/>
                    <label for="inputCartaoNome" class="form-label">Nome no Cartão</label>
                </div>
            </div>

            <div class="mb-3 col-md-6">
                <div class="form-outline" data-mdb-input-init>
                    <input type="text" class="form-control" id="inputCartaoNumero" required minlength="15" maxlength="16" name="cartao_numero"/>
                    <label for="inputCartaoNumero" class="form-label">Numero do Cartão</label>
                </div>
            </div>

            <div class="mb-3 col-4">
                <div class="form-outline" data-mdb-input-init>
                    <input type="text" class="form-control" id="inputCartaoMes" required minlength="2" maxlength="2" name="cartao_mes"/>
                    <label for="inputCartaoMes" class="form-label">Mês</label>
                </div>
            </div>

            <div class="mb-3 col-4">
                <div class="form-outline" data-mdb-input-init>
                    <input type="text" class="form-control" id="inputCartaoAno" required minlength="2" maxlength="2" name="cartao_ano"/>
                    <label for="inputCartaoAno" class="form-label">Ano</label>
                </div>
            </div>

            <div class="mb-3 col-4">
                <div class="form-outline" data-mdb-input-init>
                    <input type="text" class="form-control" id="inputCartaoCVV" required minlength="3" maxlength="4" name="cartao_cvv"/>
                    <label for="inputCartaoCVV" class="form-label">CVV</label>
                </div>
            </div>

            <hr class="mt-3 mb-0"/>


            <!--- DADOS DE ENDERECO --->

            <div class="col-12">
                <div class="form-outline" data-mdb-input-init>
                    <input type="text" class="form-control" id="inputCidade" required maxlength="128" name="endereco" value="<cfoutput>#qPerfilCheckCompleto.endereco#</cfoutput>"/>
                    <label for="inputCidade" class="form-label">Endereco</label>
                </div>
            </div>

            <div class="col-4">
                <div class="form-outline" data-mdb-input-init>
                    <input type="text" class="form-control" id="inputCidade" required maxlength="9" name="endereco_cep" value="<cfoutput>#qPerfilCheckCompleto.cep#</cfoutput>"/>
                    <label for="inputCidade" class="form-label">Cep</label>
                </div>
            </div>

            <div class="col-8">
                <div class="form-outline" data-mdb-input-init>
                    <input type="text" class="form-control" id="inputCidade" required maxlength="128" name="endereco_cidade" value="<cfoutput>#qPerfilCheckCompleto.cidade#</cfoutput>"/>
                    <label for="inputCidade" class="form-label">Cidade</label>
                </div>
            </div>

            <div class="mb-3 col-6">
                <select id="inputEstado" class="form-select" id="inputEstado" required name="endereco_estado">
                    <option value="AC" <cfif qPerfilCheckCompleto.estado EQ "AC">selected</cfif> >AC</option>
                    <option value="AL" <cfif qPerfilCheckCompleto.estado EQ "AL">selected</cfif> >AL</option>
                    <option value="AM" <cfif qPerfilCheckCompleto.estado EQ "AM">selected</cfif> >AM</option>
                    <option value="AP" <cfif qPerfilCheckCompleto.estado EQ "AP">selected</cfif> >AP</option>
                    <option value="BA" <cfif qPerfilCheckCompleto.estado EQ "BA">selected</cfif> >BA</option>
                    <option value="CE" <cfif qPerfilCheckCompleto.estado EQ "CE">selected</cfif> >CE</option>
                    <option value="DF" <cfif qPerfilCheckCompleto.estado EQ "DF">selected</cfif> >DF</option>
                    <option value="ES" <cfif qPerfilCheckCompleto.estado EQ "ES">selected</cfif> >ES</option>
                    <option value="GO" <cfif qPerfilCheckCompleto.estado EQ "GO">selected</cfif> >GO</option>
                    <option value="MA" <cfif qPerfilCheckCompleto.estado EQ "MA">selected</cfif> >MA</option>
                    <option value="MG" <cfif qPerfilCheckCompleto.estado EQ "MG">selected</cfif> >MG</option>
                    <option value="MS" <cfif qPerfilCheckCompleto.estado EQ "MS">selected</cfif> >MS</option>
                    <option value="MT" <cfif qPerfilCheckCompleto.estado EQ "MT">selected</cfif> >MT</option>
                    <option value="PA" <cfif qPerfilCheckCompleto.estado EQ "PA">selected</cfif> >PA</option>
                    <option value="PB" <cfif qPerfilCheckCompleto.estado EQ "PB">selected</cfif> >PB</option>
                    <option value="PE" <cfif qPerfilCheckCompleto.estado EQ "PE">selected</cfif> >PE</option>
                    <option value="PI" <cfif qPerfilCheckCompleto.estado EQ "PI">selected</cfif> >PI</option>
                    <option value="PR" <cfif qPerfilCheckCompleto.estado EQ "PR">selected</cfif> >PR</option>
                    <option value="RJ" <cfif qPerfilCheckCompleto.estado EQ "RJ">selected</cfif> >RJ</option>
                    <option value="RN" <cfif qPerfilCheckCompleto.estado EQ "RN">selected</cfif> >RN</option>
                    <option value="RO" <cfif qPerfilCheckCompleto.estado EQ "RO">selected</cfif> >RO</option>
                    <option value="RR" <cfif qPerfilCheckCompleto.estado EQ "RR">selected</cfif> >RR</option>
                    <option value="RS" <cfif qPerfilCheckCompleto.estado EQ "RS">selected</cfif> >RS</option>
                    <option value="SC" <cfif qPerfilCheckCompleto.estado EQ "SC">selected</cfif> >SC</option>
                    <option value="SE" <cfif qPerfilCheckCompleto.estado EQ "SE">selected</cfif> >SE</option>
                    <option value="SP" <cfif qPerfilCheckCompleto.estado EQ "SP">selected</cfif> >SP</option>
                    <option value="TO" <cfif qPerfilCheckCompleto.estado EQ "TO">selected</cfif> >TO</option>
                </select>
            </div>

            <div class="col-6">
                <div class="form-outline" data-mdb-input-init>
                    <cfquery name="qPaisesISO3166">
                        select cod_alpha2, COALESCE(nome_pais_br, nome_pais) as nome_pais from tb_paises_iso3166 order BY COALESCE(nome_pais_br, nome_pais)
                    </cfquery>
                    <select id="inputPais" class="form-select" required name="endereco_pais">
                        <cfoutput query="qPaisesISO3166">
                            <option value="#qPaisesISO3166.cod_alpha2#" <cfif len(trim(qPerfilCheckCompleto.pais)) AND qPerfilCheckCompleto.pais EQ qPaisesISO3166.cod_alpha2>selected</cfif> >#qPaisesISO3166.nome_pais#</option>
                        </cfoutput>
                    </select>
                </div>
            </div>


            <p class="text-end m-0 text-secondary" style="font-size: x-small;"><cfoutput>#isDefined('COOKIE.produto_codigo') ? 'produto: ' & COOKIE.produto_codigo : 'produto'# | #qPerfilCheckCompleto.pais#</cfoutput></p>


            <div class="col-md-12">
                <input type="hidden" name="id_produto" value="<cfoutput>#isDefined('COOKIE.produto_codigo') ? COOKIE.produto_codigo : 'runpro'#</cfoutput>"/>
                <input type="hidden" name="id" value="<cfoutput>#qPerfilCheckCompleto.id#</cfoutput>"/>
                <input type="hidden" name="id_pagina" value="<cfoutput>#qPerfil.id_pagina#</cfoutput>"/>
                <input type="hidden" name="forma_pagamento" value="cc"/>
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
