<!--- VERIFICA LOGIN COM O GOOGLE --->

<cfif isDefined("COOKIE.id")>

    <form class="row g-3 needs-validation" novalidate method="post" action="<cfoutput>#VARIABLES.template#</cfoutput>?filtro=inscricao">

        <div class="col-md-12">
            <div class="form-outline" data-mdb-input-init>
                <input type="text" class="form-control" id="inputNome" maxlength="128" name="nome"
                    value="<cfoutput>#qPerfil.nome#</cfoutput>" onblur="getTag(this.value)" required/>
                <label for="inputNome" class="form-label">Nome no Perfil:</label>
            </div>
        </div>

        <div class="col-md-12">
            <div class="input-group form-outline" data-mdb-input-init>
                <span class="input-group-text" id="inputGroupPrepend">@</span>
                    <input type="text" class="form-control <cfif isDefined("URL.info") AND URL.info EQ "tag">is-invalid</cfif>"
                        id="inputTag" maxlength="128" name="tag" aria-describedby="inputGroupPrepend"
                        value="<cfif isDefined("URL.info") AND URL.info EQ "tag" AND isDefined("URL.tag")><cfoutput>#URL.tag#</cfoutput><cfelse><cfoutput>#qPerfil.tag#</cfoutput></cfif>" onblur="getTag(this.value)" required />
                <label for="inputTag" class="form-label">Nome de usuário</label>
                <div class="invalid-feedback">Este nome de usuário já existe ou não é permitido.</div>
            </div>
        </div>

        <hr class="hr mb-0"/>

        <div class="col-md-5">
            <div class="form-outline">
                <cfquery name="qPaisesISO3166">
                    select cod_alpha2, COALESCE(nome_pais_br, nome_pais) as nome_pais from tb_paises_iso3166 order BY COALESCE(nome_pais_br, nome_pais)
                </cfquery>
                <select id="inputPais" class="form-select" id="inputPais" name="pais" data-mdb-select-init data-mdb-placeholder="Escolha um País">
                    <cfoutput query="qPaisesISO3166">
                        <option value="#qPaisesISO3166.cod_alpha2#" <cfif qPaisesISO3166.cod_alpha2 EQ "BR">selected</cfif> >#qPaisesISO3166.nome_pais#</option>
                    </cfoutput>
                </select>
            </div>
        </div>

        <div class="col-md-5">
            <div class="form-outline" data-mdb-input-init>
                <input type="text" class="form-control" id="inputCidade" maxlength="128" name="cidade" value="<cfoutput>#qPerfil.cidade#</cfoutput>"/>
                <label for="inputCidade" class="form-label">Cidade:</label>
            </div>
        </div>

        <div class="col-md-2">
            <div class="form-outline">
                <select id="inputUF" class="form-select" id="inputUF" name="uf" data-mdb-select-init data-mdb-placeholder="Escolha um estado">
                    <option value="AC" <cfif qPerfil.uf EQ "AC">selected</cfif> >AC</option>
                    <option value="AL" <cfif qPerfil.uf EQ "AL">selected</cfif> >AL</option>
                    <option value="AM" <cfif qPerfil.uf EQ "AM">selected</cfif> >AM</option>
                    <option value="AP" <cfif qPerfil.uf EQ "AP">selected</cfif> >AP</option>
                    <option value="BA" <cfif qPerfil.uf EQ "BA">selected</cfif> >BA</option>
                    <option value="CE" <cfif qPerfil.uf EQ "CE">selected</cfif> >CE</option>
                    <option value="DF" <cfif qPerfil.uf EQ "DF">selected</cfif> >DF</option>
                    <option value="ES" <cfif qPerfil.uf EQ "ES">selected</cfif> >ES</option>
                    <option value="GO" <cfif qPerfil.uf EQ "GO">selected</cfif> >GO</option>
                    <option value="MA" <cfif qPerfil.uf EQ "MA">selected</cfif> >MA</option>
                    <option value="MG" <cfif qPerfil.uf EQ "MG">selected</cfif> >MG</option>
                    <option value="MS" <cfif qPerfil.uf EQ "MS">selected</cfif> >MS</option>
                    <option value="MT" <cfif qPerfil.uf EQ "MT">selected</cfif> >MT</option>
                    <option value="PA" <cfif qPerfil.uf EQ "PA">selected</cfif> >PA</option>
                    <option value="PB" <cfif qPerfil.uf EQ "PB">selected</cfif> >PB</option>
                    <option value="PE" <cfif qPerfil.uf EQ "PE">selected</cfif> >PE</option>
                    <option value="PI" <cfif qPerfil.uf EQ "PI">selected</cfif> >PI</option>
                    <option value="PR" <cfif qPerfil.uf EQ "PR">selected</cfif> >PR</option>
                    <option value="RJ" <cfif qPerfil.uf EQ "RJ">selected</cfif> >RJ</option>
                    <option value="RN" <cfif qPerfil.uf EQ "RN">selected</cfif> >RN</option>
                    <option value="RO" <cfif qPerfil.uf EQ "RO">selected</cfif> >RO</option>
                    <option value="RR" <cfif qPerfil.uf EQ "RR">selected</cfif> >RR</option>
                    <option value="RS" <cfif qPerfil.uf EQ "RS">selected</cfif> >RS</option>
                    <option value="SC" <cfif qPerfil.uf EQ "SC">selected</cfif> >SC</option>
                    <option value="SE" <cfif qPerfil.uf EQ "SE">selected</cfif> >SE</option>
                    <option value="SP" <cfif qPerfil.uf EQ "SP">selected</cfif> >SP</option>
                    <option value="TO" <cfif qPerfil.uf EQ "TO">selected</cfif> >TO</option>
                    <option value="XX" <cfif qPerfil.uf EQ "XX">selected</cfif> >EXTERIOR</option>
                </select>
            </div>
        </div>

        <!---div class="col-md-12">
            <div class="form-outline" data-mdb-input-init>
                <textarea class="form-control" name="descricao" id="inputDescricao" maxlength="150" rows="2"><cfoutput>#qPerfil.descricao#</cfoutput></textarea>
                <label class="form-label" for="inputDescricao">Texto da Bio</label>
            </div>
        </div--->

        <p class="text-end m-0 text-secondary" style="font-size: x-small;"><cfoutput>#isDefined('COOKIE.produto_codigo') ? 'produto: ' & COOKIE.produto_codigo : 'produto'#</cfoutput></p>

        <div class="col-md-12">
            <input type="hidden" name="descricao" value="<cfoutput>#qPerfil.descricao#</cfoutput>"/>
            <input type="hidden" name="action" value="atualizar_cadastro_pocket"/>
            <input type="hidden" name="tag_prefix" value="atleta"/>
            <input type="hidden" name="id_pagina" value="<cfoutput>#qPerfil.id_pagina#</cfoutput>"/>
            <button type="submit" class="btn btn-primary shadow-3 w-100 fs-6" data-mdb-ripple-init>Salvar e prosseguir</button>
        </div>

    </form>

    <script>
        function getTag(tag) {
            if (tag) {
                $.getJSON("/api/Util.cfc?method=getUserTag&id_pagina=" + <cfoutput>#qPerfil.id_pagina#</cfoutput> + "&texto=" + tag + "&token=jf8w3ynr73840rync848udq07yrc89q2h4nr08ync743c9r8h328f42fc8n23", function(result) {
                    if (result.status.mensagem !== 'OK') {
                        inputTag.classList.add('is-invalid');
                        inputTag.classList.remove('is-valid');
                        inputTag.setCustomValidity('patternMismatch');
                    } else {
                        inputTag.classList.add('is-valid');
                        inputTag.classList.remove('is-invalid');
                        inputTag.setCustomValidity('');
                    }
                    $("#inputTag").val(result.data);
                });
            }
        }
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

    <p class="text-center">Identifique-se no primeiro passo para começarmos.</p>

</cfif>
