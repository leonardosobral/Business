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

  .business-navbar-account-context {
    align-items: center;
    display: flex;
    gap: .55rem;
    min-width: 0;
  }

  .business-navbar-account-icon {
    align-items: center;
    background: rgba(250, 177, 32, .12);
    border-radius: .6rem;
    color: #fab120;
    display: inline-flex;
    flex: 0 0 2.15rem;
    height: 2.15rem;
    justify-content: center;
  }

  .business-navbar-account-copy {
    min-width: 0;
  }

  .business-navbar-account-label {
    color: rgba(255, 255, 255, .52);
    display: block;
    font-size: .65rem;
    font-weight: 600;
    letter-spacing: .08em;
    line-height: 1;
    margin-bottom: .25rem;
    text-transform: uppercase;
  }

  .business-navbar-account-name {
    color: #fff;
    display: block;
    font-size: .92rem;
    font-weight: 700;
    line-height: 1.1;
    max-width: min(38vw, 28rem);
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .business-navbar-account-switch {
    align-items: center;
    border-color: rgba(255, 255, 255, .18);
    border-radius: 50%;
    color: rgba(255, 255, 255, .78);
    display: inline-flex;
    flex: 0 0 2rem;
    height: 2rem;
    justify-content: center;
    padding: 0;
    width: 2rem;
  }

  .business-navbar-account-switch:hover,
  .business-navbar-account-switch:focus {
    border-color: #fab120;
    color: #fab120;
  }

  @media (max-width: 767.98px) {
    .business-navbar-account-icon,
    .business-navbar-account-label {
      display: none;
    }

    .business-navbar-account-name {
      max-width: 42vw;
    }
  }
</style>

<nav id="main-navbar" class="navbar navbar-expand-lg navbar-light fixed-top shadow-1" style="background-color: #333333;">
    <!-- Container wrapper -->
    <div class="container-fluid">
        <!-- Toggler -->
        <button data-mdb-toggle="sidenav" data-mdb-target="#main-sidenav"
                class="btn shadow-0 p-0 me-3 d-block d-xl-none"
                data-mdb-ripple-init aria-controls="#main-sidenav" aria-haspopup="true">
            <i class="fas fa-bars fa-lg"></i>
        </button>

        <!-- Account context -->
        <cfset VARIABLES.businessNavbarAccountName = "Road Runners Business"/>
        <cfif isDefined("VARIABLES.businessActiveAccountName") AND len(trim(VARIABLES.businessActiveAccountName))>
            <cfset VARIABLES.businessNavbarAccountName = VARIABLES.businessActiveAccountName/>
        <cfelseif isDefined("VARIABLES.businessRealIsAdmin") AND VARIABLES.businessRealIsAdmin>
            <cfset VARIABLES.businessNavbarAccountName = "Todas as contas"/>
        </cfif>
        <div class="business-navbar-account-context my-auto">
            <span class="business-navbar-account-icon"><i class="fa-solid fa-building"></i></span>
            <span class="business-navbar-account-copy">
                <span class="business-navbar-account-label">Conta ativa</span>
                <cfoutput><span class="business-navbar-account-name" title="#htmlEditFormat(VARIABLES.businessNavbarAccountName)#">#htmlEditFormat(VARIABLES.businessNavbarAccountName)#</span></cfoutput>
            </span>
            <cfif isDefined("VARIABLES.businessAccountSwitchAvailable") AND VARIABLES.businessAccountSwitchAvailable>
                <button class="btn btn-outline-light business-navbar-account-switch" type="button" data-business-account-modal-open aria-label="Trocar conta" title="Trocar conta">
                    <i class="fa-solid fa-right-left"></i>
                </button>
            </cfif>
        </div>

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
                    <cfoutput><img src="#len(trim(qPerfil.imagem_usuario)) ? qPerfil.imagem_usuario : '/assets/user.png'#"
                    style="max-height: 22px;" alt="imagem do usuário" class="rounded-circle" onerror="this.onerror=null;this.src='/assets/user.png';"/></cfoutput>
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

<cfif isDefined("VARIABLES.businessAccountSwitchAvailable") AND VARIABLES.businessAccountSwitchAvailable>
    <cfset VARIABLES.businessAccountModalRequired = false/>
    <cfinclude template="account_context_modal.cfm"/>
</cfif>
