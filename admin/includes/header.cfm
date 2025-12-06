<div class="row mb-3">

    <!--- LOGO --->

    <div class="col-md-2">
        <a href="/admin/"><img src="../../assets/RH_branco.png" class="img-fluid"/></a>
    </div>

    <div class="col-md-10">

        <table class="float-end w-auto">

            <tr style="font-size: small;">
                <td>Administração</td>
                <td>Stats</td>
                <td>Resultados</td>
                <td>Manutenção</td>
                <td></td>
            </tr>

            <tr>

                <td>
                    <a href="/admin/?<cfoutput>preset=#URL.preset#&periodo=#URL.periodo#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#</cfoutput>">Eventos</a>
                    | <a href="/admin/users.cfm?<cfoutput>preset=#URL.preset#&periodo=24horas&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#</cfoutput>">Usuários</a>
                    <img src="/assets/separador.png" alt="separador de breadcrumb" class="mx-2" style="max-height: 20px; margin-top: -4px">
                </td>

                <td>
                    <a href="/admin/stats_rr.cfm?<cfoutput>preset=#URL.preset#&periodo=#URL.periodo#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#</cfoutput>">RR</a>
                    | <a href="/admin/stats_or.cfm?<cfoutput>preset=#URL.preset#&periodo=#URL.periodo#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#</cfoutput>">OR</a>
                    <img src="/assets/separador.png" alt="separador de breadcrumb" class="mx-2" style="max-height: 20px; margin-top: -4px">
                </td>

                <td>
                    <a href="/admin/stats_obs.cfm?<cfoutput>preset=#URL.preset#&periodo=#(len(trim(URL.periodo)) ? URL.periodo : 2025)#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#</cfoutput>">Status</a>
                    | <a href="/admin/homologacao.cfm?<cfoutput>preset=#URL.preset#&periodo=#(len(trim(URL.periodo)) ? URL.periodo : 2025)#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#</cfoutput>">Homolog</a>
                    | <a href="/admin/resultados.cfm?<cfoutput>preset=#URL.preset#&periodo=#(len(trim(URL.periodo)) ? URL.periodo : 2025)#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#</cfoutput>">Results</a>
                    <img src="/assets/separador.png" alt="separador de breadcrumb" class="mx-2" style="max-height: 20px; margin-top: -4px">
                </td>

                <td>
                    <!---a href="/admin/comparador/">Comparador</a>
                    <img src="/assets/separador.png" alt="separador de breadcrumb" class="mx-2" style="max-height: 20px; margin-top: -4px"--->
                    <a href="/admin/importacao_eventos/?<cfoutput>preset=#URL.preset#&periodo=#URL.periodo#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#</cfoutput>">Eventos</a>
                    | <a href="/admin/importacao/?<cfoutput>preset=#URL.preset#&periodo=#URL.periodo#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#</cfoutput>">Results</a>
                    | <a href="/admin/listas/?<cfoutput>preset=#URL.preset#&periodo=#URL.periodo#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#</cfoutput>">Listas</a>
                    | <a href="/admin/mnt.cfm?<cfoutput>preset=#URL.preset#&periodo=#URL.periodo#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#</cfoutput>">Dicas</a>
                </td>

                <td>

                <a href="https://roadrunners.run/" target="_blank"><img src="../../assets/rr_icon.jpg" class="w-40px rounded-5 shadow-5 mx-0 px-1 ms-2"/></a>
                <a href="https://openresults.run/" target="_blank"><img src="../../assets/or_icon.jpg" class="w-40px rounded-5 shadow-5 mx-0 px-1"/></a>
                <a href="https://runnerhub.run/bi/" target="_blank"><img src="../../assets/rbi_icon.jpg" class="w-40px rounded-5 shadow-5 mx-0 px-1"/></a>

                <div class="btn-group ms-2">
                    <cfoutput>
                        <a href="/" id="dropdownMenuAdmin" class="dropdown-toggle link-light" data-mdb-dropdown-init data-mdb-ripple-init aria-expanded="false">
                            <i class="fas fa-screwdriver-wrench"></i>
                        </a>
                    </cfoutput>
                    <ul class="dropdown-menu dropdown-menu-lg-end" aria-labelledby="dropdownMenuAdmin">
                        <li><a class="dropdown-item" target="_blank" href="https://trello.com/b/WhkXXw2i/runnerhub/">Trello</a></li>
                        <li><a class="dropdown-item" target="_blank" href="https://drive.google.com/drive/u/0/folders/0AHB4S7So5I7xUk9PVA">Drive</a></li>
                        <li><hr class="dropdown-divider"/></li>
                        <li><a class="dropdown-item" target="_blank" href="https://runnerhub.run/api/feed/">Importar Feed de Notícias</a></li>
                        <li><a class="dropdown-item" target="_blank" href="https://runnerhub.run/api/youtube/?channel=UCxmZoyAOr6HkyAkW2c2YSog">Importar Vídeos Youtube</a></li>
                        <li><hr class="dropdown-divider"/></li>
                        <li><a class="dropdown-item" target="_blank" href="https://analytics.google.com/analytics/web/#/p403771752/reports/intelligenthome">Google Analytics</a></li>
                        <li><a class="dropdown-item" target="_blank" href="https://search.google.com/search-console/performance/search-analytics?resource_id=sc-domain%3Aroadrunners.run">Google Search Console</a></li>
                        <li><a class="dropdown-item" target="_blank" href="https://pagespeed.web.dev/report?url=https%3A%2F%2Froadrunners.run%2Fhome%2F&hl=pt_BR">PageSpeed Insights</a></li>
                        <li><hr class="dropdown-divider"/></li>
                        <li><a class="dropdown-item" target="_blank" href="https://cloud.linode.com/">Linode/Akamai</a></li>
                        <li><a class="dropdown-item" target="_blank" href="https://dash.cloudflare.com/">CloudFlare</a></li>
                        <li><a class="dropdown-item" target="_blank" href="http://ssh.runnerhub.run:8500/CFIDE/administrator/">Coldfusion Admin</a></li>
                        <li><a class="dropdown-item" target="_blank" href="http://ssh.runnerhub.run:9101/">Coldfusion Monitoring</a></li>
                    </ul>
                </div>

                <!--- USER --->
                <div class="g-signin2 d-none" data-onsuccess="onSignIn"></div>
                <div class="btn-group ms-2 rounded-circle">
                    <cfoutput><img src="#len(trim(qPerfil.imagem_usuario)) ? qPerfil.imagem_usuario : '/assets/user.png'#" style="max-height: 24px; margin-top: -4px; cursor: pointer;" alt="imagem do usuário" class="rounded-circle" data-mdb-dropdown-init data-mdb-ripple-init aria-expanded="false"/></cfoutput>
                    <ul class="dropdown-menu dropdown-menu-end dropdown-menu-lg-start" style="z-index: 999999;">
                        <li><a class="dropdown-item" href="/perfil/">Meu Perfil</a></li>
                        <!---<li><a class="dropdown-item" href="/powerups/">Power Ups</a></li>--->
                        <li><hr class="dropdown-divider"></li>
                        <li><a class="dropdown-item" href="#" onclick="signOut()">Sair</a></li>
                    </ul>
                </div>
                </td>

            </tr>

        </table>

    </div>

</div>
