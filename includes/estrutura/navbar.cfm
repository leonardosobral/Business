<style>
  .business-topbar-notification-menu {
    width: min(22rem, calc(100vw - 1rem));
    min-width: 18rem;
    max-width: calc(100vw - 1rem);
  }

  .business-topbar-notification-item {
    display: flex;
    align-items: flex-start;
    gap: 0.7rem;
    white-space: normal;
    line-height: 1.35;
  }

  .business-topbar-notification-icon {
    flex: 0 0 auto;
    margin-top: 0.1rem;
  }

  .business-topbar-notification-text {
    min-width: 0;
  }

  .business-account-context-form {
    min-width: min(420px, calc(100vw - 8rem));
  }

  .business-account-context-form .form-select {
    min-width: 260px;
  }

  @media (max-width: 767.98px) {
    .business-account-context-form {
      min-width: 0;
      width: 100%;
    }

    .business-account-context-form .form-select {
      min-width: 0;
    }
  }
</style>

<nav id="main-navbar" class="navbar navbar-expand-lg navbar-light fixed-top shadow-1" style="background-color: #333333;">
    <!-- Container wrapper -->
    <div class="container-fluid">
        <!-- Toggler -->
        <button data-mdb-toggle="sidenav" data-mdb-target="#main-sidenav"
                class="btn shadow-0 p-0 me-3 d-block d-xxl-none"
                data-mdb-ripple-init aria-controls="#main-sidenav" aria-haspopup="true">
            <i class="fas fa-bars fa-lg"></i>
        </button>

        <!-- Account context -->
        <cfset VARIABLES.businessNavbarCurrentUrl = CGI.SCRIPT_NAME/>
        <cfif len(trim(CGI.QUERY_STRING))>
            <cfset VARIABLES.businessNavbarCurrentUrl = VARIABLES.businessNavbarCurrentUrl & "?" & CGI.QUERY_STRING/>
        </cfif>

        <cfif isDefined("VARIABLES.businessRealIsAdmin") AND VARIABLES.businessRealIsAdmin>
            <cfoutput>
                <form class="d-none d-md-flex input-group w-auto my-auto business-account-context-form" method="get" action="/">
                    <input type="hidden" name="business_account_context_redirect" value="#htmlEditFormat(VARIABLES.businessNavbarCurrentUrl)#"/>
                    <span class="input-group-text border-0"><i class="fa-solid fa-building-user text-secondary"></i></span>
                    <select class="form-select" name="business_account_context_id" onchange="this.form.submit()" <cfif NOT isDefined("qBusinessAccountContextOptions") OR NOT qBusinessAccountContextOptions.recordcount>disabled</cfif>>
                        <option value="">Admin: todas as contas</option>
                        <cfif isDefined("qBusinessAccountContextOptions") AND qBusinessAccountContextOptions.recordcount>
                            <cfloop query="qBusinessAccountContextOptions">
                                <option value="#qBusinessAccountContextOptions.id_conta#" <cfif isDefined("VARIABLES.businessSimulatedAccountId") AND len(trim(VARIABLES.businessSimulatedAccountId)) AND VARIABLES.businessSimulatedAccountId EQ qBusinessAccountContextOptions.id_conta>selected</cfif>>
                                    #htmlEditFormat(qBusinessAccountContextOptions.nome_conta)#<cfif qBusinessAccountContextOptions.status NEQ "ATIVA"> - #htmlEditFormat(qBusinessAccountContextOptions.status)#</cfif>
                                </option>
                            </cfloop>
                        </cfif>
                    </select>
                    <cfif isDefined("VARIABLES.businessAccountSimulationActive") AND VARIABLES.businessAccountSimulationActive>
                        <span class="input-group-text border-0 bg-warning text-dark">Simulando</span>
                    </cfif>
                </form>
            </cfoutput>
        <cfelse>
            <!-- Search form -->
            <form class="d-none d-md-flex input-group w-auto my-auto">
                <input id="search-focus" autocomplete="off" type="search" class="form-control rounded"
                       placeholder='Pesquisa [ctrl+alt]' style="min-width: 225px" />
                <span class="input-group-text border-0"><i class="fas fa-search text-secondary"></i></span>
            </form>
        </cfif>

        <!-- Right links -->
        <ul class="navbar-nav ms-auto d-flex flex-row">
            <!-- Notification dropdown -->
            <li class="nav-item dropdown">
                <a class="nav-link me-3 me-lg-0 dropdown-toggle hidden-arrow" href="#" id="navbarDropdownNotifications"
                   role="button" data-mdb-dropdown-init aria-expanded="false">
                    <i class="fas fa-bell link-secondary"></i>
                    <span class="badge rounded-pill badge-notification bg-danger"><cfif isDefined("qNotificacoesNaoLidas") AND qNotificacoesNaoLidas.recordcount>1</cfif></span>
                </a>
                <ul class="dropdown-menu dropdown-menu-end business-topbar-notification-menu" aria-labelledby="navbarDropdownNotifications">
                    <li class="bg-light-subtle"><span class="dropdown-header text-center">Notificações</span></li>
                    <cfif isDefined("qNotificacoes") AND qNotificacoes.recordcount>
                        <cfoutput query="qNotificacoes">
                            <cfset VARIABLES.businessNotificationHref = trim(qNotificacoes.link)/>
                            <cfif len(VARIABLES.businessNotificationHref)>
                                <cfif reFindNoCase("^https?://", VARIABLES.businessNotificationHref)>
                                    <cfset VARIABLES.businessNotificationUrl = VARIABLES.businessNotificationHref/>
                                <cfelseif left(VARIABLES.businessNotificationHref, 1) EQ "/">
                                    <cfset VARIABLES.businessNotificationUrl = VARIABLES.roadRunnersBaseUrl & VARIABLES.businessNotificationHref/>
                                <cfelse>
                                    <cfset VARIABLES.businessNotificationUrl = VARIABLES.roadRunnersBaseUrl & "/" & VARIABLES.businessNotificationHref/>
                                </cfif>
                                <cfset VARIABLES.businessNotificationReadUrl = "/?action=abrir_notificacao&id_notifica=" & qNotificacoes.id_notifica & "&destino=" & urlEncodedFormat(VARIABLES.businessNotificationUrl)/>
                                <li class="border-top border-1 border-light-subtle">
                                    <a class="dropdown-item business-topbar-notification-item" href="#VARIABLES.businessNotificationReadUrl#" target="_blank">
                                        <i class="#len(trim(qNotificacoes.icone)) ? qNotificacoes.icone : 'fa-solid fa-bell'# business-topbar-notification-icon"></i>
                                        <span class="business-topbar-notification-text">#qNotificacoes.conteudo_notifica#</span>
                                    </a>
                                </li>
                            </cfif>
                        </cfoutput>
                    <cfelse>
                        <li><span class="dropdown-item text-muted">Nenhuma notificação</span></li>
                    </cfif>
                </ul>
            </li>

            <!-- Icon dropdown -->
            <!---<li class="nav-item dropdown">
                <a class="nav-link me-3 me-lg-0 dropdown-toggle hidden-arrow" href="#" id="navbarDropdown" role="button"
                   data-mdb-dropdown-init aria-expanded="false">
                    <i class="flag flag-united-kingdom m-0"></i>
                </a>
                <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="navbarDropdown">
                    <li>
                        <a class="dropdown-item" href="#"><i class="flag flag-united-kingdom"></i>English
                            <i class="fa fa-check text-success ms-2"></i></a>
                    </li>
                    <li>
                        <hr class="dropdown-divider" />
                    </li>
                    <li>
                        <a class="dropdown-item" href="#"><i class="flag flag-poland"></i>Polski</a>
                    </li>
                    <li>
                        <a class="dropdown-item" href="#"><i class="flag flag-china"></i>中文</a>
                    </li>
                    <li>
                        <a class="dropdown-item" href="#"><i class="flag flag-japan"></i>日本語</a>
                    </li>
                    <li>
                        <a class="dropdown-item" href="#"><i class="flag flag-germany"></i>Deutsch</a>
                    </li>
                    <li>
                        <a class="dropdown-item" href="#"><i class="flag flag-france"></i>Français</a>
                    </li>
                    <li>
                        <a class="dropdown-item" href="#"><i class="flag flag-spain"></i>Español</a>
                    </li>
                    <li>
                        <a class="dropdown-item" href="#"><i class="flag flag-russia"></i>Русский</a>
                    </li>
                    <li>
                        <a class="dropdown-item" href="#"><i class="flag flag-portugal"></i>Português</a>
                    </li>
                </ul>
            </li>--->

            <!-- Avatar -->
            <div class="g-signin2 d-none" data-onsuccess="onSignIn"></div>
            <li class="nav-item dropdown">

                <!---<a class="nav-link dropdown-toggle hidden-arrow d-flex align-items-center" href="#"--->
                   <!---id="navbarDropdownMenuLink" role="button" data-mdb-dropdown-init aria-expanded="false">--->
                    <!---<img src="https://mdbootstrap.com/img/new/avatars/2.jpg" class="rounded-circle" height="22" alt="Avatar"--->
                         <!---loading="lazy" />--->
                <!---</a>--->
                <!---<ul class="dropdown-menu dropdown-menu-end" aria-labelledby="navbarDropdownMenuLink">--->
                    <!---<li><a class="dropdown-item " href="#">Cadastro</a></li>--->
                    <!---<li><a class="dropdown-item" href="#">Configurações</a></li>--->
                    <!---<li><a class="dropdown-item" href="#">Sair</a></li>--->
                <!---</ul>--->


                <!--- USER --->

                <a class="nav-link dropdown-toggle hidden-arrow d-flex align-items-center" href="#" id="navbarDropdownMenuLink" role="button" data-mdb-dropdown-init aria-expanded="false">
                    <cfoutput><img src="#len(trim(qPerfil.imagem_usuario)) ? qPerfil.imagem_usuario : 'https://roadrunners.run/assets/user.png'#"
                    style="max-height: 22px;" alt="imagem do usuário" class="rounded-circle" onerror="this.src='https://roadrunners.run/assets/user.png';"/></cfoutput>
                </a>
                <ul class="dropdown-menu dropdown-menu-end dropdown-menu-lg-start" style="z-index: 999999;">
                    <li><a class="dropdown-item" href="/">Meus Painéis</a></li>
                    <li><a class="dropdown-item" href="https://roadrunners.run/atleta/" target="_blank">Meu Perfil</a></li>
                    <!---<li><a class="dropdown-item" href="/powerups/">Power Ups</a></li>--->
                    <li><hr class="dropdown-divider"></li>
                    <li><a class="dropdown-item" href="/logout.cfm" onclick="return typeof signOut === 'function' ? signOut(event) : true">Sair</a></li>
                </ul>

            </li>
        </ul>
    </div>
    <!-- Container wrapper -->
</nav>
