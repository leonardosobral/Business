<cfset VARIABLES.themeHeaderSuppressDivider = structKeyExists(VARIABLES, "eventThemeHeaderCompact") AND VARIABLES.eventThemeHeaderCompact/>

<cfif qTema.id_tema GT 1>

    <cfset themeHeaderCatalog = REQUEST.i18n.common.themeHeader />
    <cfset VARIABLES.themeHeaderLogoKey = reReplace(trim(qTema.logo & ""), "[^A-Za-z0-9._-]", "", "all") />
    <cfset VARIABLES.themeHeaderLogoUrl = "" />
    <cfset VARIABLES.themeHeaderIconUrl = "" />

    <cfif len(VARIABLES.themeHeaderLogoKey)>
        <cfif fileExists(expandPath("/assets/logos/#VARIABLES.themeHeaderLogoKey#.svg"))>
            <cfset VARIABLES.themeHeaderLogoUrl = "/assets/logos/#VARIABLES.themeHeaderLogoKey#.svg" />
        <cfelseif fileExists(expandPath("/assets/logos/#VARIABLES.themeHeaderLogoKey#.png"))>
            <cfset VARIABLES.themeHeaderLogoUrl = "/assets/logos/#VARIABLES.themeHeaderLogoKey#.png" />
        </cfif>

        <cfif fileExists(expandPath("/assets/icons/#VARIABLES.themeHeaderLogoKey#.png"))>
            <cfset VARIABLES.themeHeaderIconUrl = "/assets/icons/#VARIABLES.themeHeaderLogoKey#.png" />
        <cfelseif fileExists(expandPath("/assets/logos/#VARIABLES.themeHeaderLogoKey#.png"))>
            <cfset VARIABLES.themeHeaderIconUrl = "/assets/logos/#VARIABLES.themeHeaderLogoKey#.png" />
        <cfelseif fileExists(expandPath("/assets/logos/#VARIABLES.themeHeaderLogoKey#.svg"))>
            <cfset VARIABLES.themeHeaderIconUrl = "/assets/logos/#VARIABLES.themeHeaderLogoKey#.svg" />
        </cfif>
    </cfif>

    <cfoutput>

        <div class="row m-1 py-1<cfif NOT VARIABLES.themeHeaderSuppressDivider> mb-3 border-bottom border-secondary</cfif>">

            <!--- NOME OU LOGO --->

            <div class="col-10 px-0">

                <!--- /ORG OU /TIMER --->

                <cfif VARIABLES.template EQ "/org/" OR VARIABLES.template EQ "/timer/">

                    <a href="/#qFornecedor.tag_tipo#/#qFornecedor.tag#/">
                        <cfif len(VARIABLES.themeHeaderLogoUrl)>
                            <img src="#encodeForHTMLAttribute(VARIABLES.themeHeaderLogoUrl)#" alt="#REQUEST.t('common.themeHeader.logoAltOrganizer', { 'name' = qFornecedor.nome_fornecedor })#" style="max-width: 100%;max-height: 60px;" onload="document.getElementById('titulo').style.display = 'block'; return true;" onerror="this.style.display = 'none';document.getElementById('tema').style.display = 'block'; return true;"/>
                        </cfif>
                        <span style="display: <cfif len(VARIABLES.themeHeaderLogoUrl)>none<cfelse>block</cfif>;" class="display-6 text-dark fw-semibold" id="tema">#qFornecedor.nome_fornecedor#</span>
                        <span style="display: none;" class="mt-2 small opacity-50" id="titulo">
                            <i class="fa-solid fa-<cfif #qFornecedor.tag_tipo# EQ "org">building<cfelseif #qFornecedor.tag_tipo# EQ "timer">stopwatch</cfif>"></i>
                            #qFornecedor.nome_fornecedor#
                        </span>
                    </a>

                <cfelse>

                    <a href="/#qAgrega.tipo_agregacao#/#qAgrega.tag#/">
                        <cfif len(VARIABLES.themeHeaderLogoUrl)>
                            <img src="#encodeForHTMLAttribute(VARIABLES.themeHeaderLogoUrl)#" alt="#REQUEST.t('common.themeHeader.logoAltEvent', { 'name' = qAgrega.nome_evento_agregado })#" style="max-width: 100%;max-height: 60px;" onload="document.getElementById('titulo').style.display = 'block'; return true;" onerror="this.style.display = 'none';document.getElementById('tema').style.display = 'block'; return true;"/>
                        </cfif>
                        <span style="color:#qTema.cor_fonte#; display: <cfif len(VARIABLES.themeHeaderLogoUrl)>none<cfelse>block</cfif>;" class="display-6 text-dark fw-semibold" id="tema">#qAgrega.nome_evento_agregado#</span>
                        <span style="color:#qTema.cor_fonte#; display: none;" class="mt-2" id="titulo">#qAgrega.nome_evento_agregado#</span>
                    </a>

                </cfif>
            </div>

            <!--- LINKS DAS REDES SOCIAIS --->

            <div class="col-2 px-0" style="text-align: right; word-spacing: 2px; font-size: 24px">
                <cfif len(VARIABLES.themeHeaderIconUrl)>
                        <a href="#qTema.website#" target="_blank"><img src="#encodeForHTMLAttribute(VARIABLES.themeHeaderIconUrl)#" class="rounded-4" alt="#themeHeaderCatalog.website#" title="#themeHeaderCatalog.website#" style="width: 22px; height: 22px; object-fit: contain; vertical-align: middle; margin-bottom: 5px;" onload="document.getElementById('website').style.display = 'none'; return true;" onerror="this.style.display = 'none'; document.getElementById('website').style.display = 'inline-block'; return true;"><i id="website" class="fa-solid fa-link" title="#themeHeaderCatalog.website#" style="color:#qTema.cor_botoes#;"></i></a>
                <cfelse>
                        <a href="#qTema.website#" target="_blank"><i class="fa-solid fa-link" title="#themeHeaderCatalog.website#" style="color:#qTema.cor_botoes#;"></i></a>
                </cfif>
                <cfif len(trim(qTema.instagram))>
                        <a href="https://instagram.com/#qTema.instagram#" target="_blank"><i class="fa-brands fa-instagram" title="#themeHeaderCatalog.instagram#" style="color:#qTema.cor_botoes#;"></i></a>
                </cfif>
                <!---<cfif len(trim(qTema.app_ios))>
                        <a href="#qTema.app_ios#" target="_blank"><i class="fa-brands fa-app-store-ios" title="#themeHeaderCatalog.appStore#" style="color:#qTema.cor_botoes#;"></i></a>
                </cfif>
                <cfif len(trim(qTema.app_android))>
                        <a href="#qTema.app_android#" target="_blank"><i class="fa-brands fa-google-play" title="#themeHeaderCatalog.playStore#" style="color:#qTema.cor_botoes#;"></i></a>
                </cfif>--->

                <!---<a class="btn btn-secondary px-1 w-100" href="/#qAgrega.tipo_agregacao#/#qAgrega.tag#/">Ver mais</a>--->

            </div>

        </div>

    </cfoutput>

<cfelse>

    <cfoutput>

        <div class="m-1 py-1<cfif NOT VARIABLES.themeHeaderSuppressDivider> mb-3 border-bottom border-secondary</cfif>">

            <!--- /ORG OU /TIMER --->

            <cfif VARIABLES.template EQ "/org/" OR VARIABLES.template EQ "/timer/">

                <a href="/#qFornecedor.tag_tipo#/#qFornecedor.tag#/">
                    <div class="display-6 text-dark fw-semibold" id="tema">#qFornecedor.nome_fornecedor#</div>
                    <div class="small opacity-50" id="titulo">
                        <i class="fa-solid fa-<cfif #qFornecedor.tag_tipo# EQ "org">building<cfelseif #qFornecedor.tag_tipo# EQ "timer">stopwatch</cfif>"></i>
                        #qFornecedor.nome_fornecedor#
                    </div>
                </a>

            <cfelse>

                <a href="/#qAgrega.tipo_agregacao#/#qAgrega.tag#/">
                    <span class="display-6 text-dark fw-semibold" id="tema">#qAgrega.nome_evento_agregado#</span>
                    <!---<span class="mt-2" id="titulo">#qAgrega.nome_evento_agregado#</span>--->
                </a>

            </cfif>

        </div>

    </cfoutput>

</cfif>
