<div class="row mb-3">

    <!--- LOGO --->

    <div class="col-6 row-cols-auto">
        <a href="/desafios/"><img src="https://cdn.bitrix24.com.br/b25804041/landing/b1e/b1e05d692982b45e353e62e93764dcf8/copy_of_copia_de_copia_de_4_1x_1x_png" class="w-150px"/></a>
        <div class="d-block d-md-inline">
            <a href="./fila.cfm?debug=true&auto=false&order=asc&desafio=<cfoutput>#URL.desafio#</cfoutput>" class="p-1 ano align-middle"><i class="fa-solid fa-list-check"></i> Fila</a>
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
