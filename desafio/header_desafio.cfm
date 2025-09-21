<div class="row mb-3">

    <!--- LOGO --->

    <div class="col-6 row-cols-auto">
        <a href="/bi/desafio/"><img src="../../assets/desafio_cna.svg" class="w-150px"/></a>
        <div class="d-block d-md-inline">
            <a href="./" class="p-1 ano"><img src="../../assets/desafio_365.svg" class="w-50px <cfif VARIABLES.template EQ "365">active<cfelse>opacity-20</cfif>"/></a>
            <a href="./366.cfm" class="p-1 ano"><img src="../../assets/desafio_366.svg" class="w-50px <cfif VARIABLES.template EQ "366">active<cfelse>opacity-20</cfif>"/></a>
            <a href="./fila.cfm?debug=true&auto=true&order=asc" class="p-1 ano align-middle"><i class="fa-solid fa-list-check <cfif VARIABLES.template EQ "fila">active<cfelse>opacity-20</cfif>"></i></a>
        </div>
    </div>

    <div class="col-6 text-end">

        <cfif isDefined("qAgrega")>
            <img src="/assets/logos/<cfoutput>#qTema.logo#.png</cfoutput>" class="w-50px"  onerror="this.src='/assets/logos/runnerhub.png';">
        </cfif>

        <!--- USER --->
        <div class="g-signin2 d-none" data-onsuccess="onSignIn"></div>
        <div class="btn-group rounded-circle">
            <cfoutput><img src="#len(trim(qPerfil.imagem_usuario)) ? qPerfil.imagem_usuario : '/assets/user.png'#" style="max-height: 38px; cursor: pointer;" alt="imagem do usuário" class="rounded-circle" data-mdb-dropdown-init data-mdb-ripple-init aria-expanded="false"/></cfoutput>
            <ul class="dropdown-menu dropdown-menu-end dropdown-menu-lg-start" style="z-index: 999999;">
                <li><a class="dropdown-item" href="https://roadrunners.run/perfil/">Meu Perfil</a></li>
                <!---<li><a class="dropdown-item" href="/powerups/">Power Ups</a></li>--->
                <li><hr class="dropdown-divider"></li>
                <li><a class="dropdown-item" href="#" onclick="signOut()">Sair</a></li>
            </ul>
        </div>

    </div>

</div>
