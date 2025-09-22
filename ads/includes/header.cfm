<header>

    <!--- Sidenav --->
    <nav id="main-sidenav" data-mdb-sidenav-init class="sidenav sidenav-sm shadow-1" data-mdb-hidden="false"
      data-mdb-accordion="true">
      <a class="ripple d-flex justify-content-center pt-4 pb-2" href="#!" data-mdb-ripple-init
        data-mdb-ripple-color="primary">
        <img id="MDB-logo" src="../assets/runnerhub_logo_negativo.png"
          alt="RunnerHub Logo" draggable="false" class="w-responsive" />
      </a>

      <hr class="hr">

      <ul class="sidenav-menu px-2 pb-5">
        <li class="sidenav-item">
          <a class="sidenav-link" href="./">
            <i class="fas fa-tachometer-alt fa-fw me-3"></i><span>Overview</span></a>
        </li>

        <li class="sidenav-item pt-3">
          <span class="sidenav-subheading text-muted text-uppercase fw-bold">Create</span>
        </li>
        <li class="sidenav-item">
          <a class="sidenav-link" href="">
            <i class="fas fa-plus fa-fw me-3"></i><span>Project</span></a>
        </li>
        <li class="sidenav-item">
          <a class="sidenav-link" href="">
            <i class="fas fa-plus fa-fw me-3"></i><span>Database</span></a>
        </li>

        <li class="sidenav-item pt-3">
          <span class="sidenav-subheading text-muted text-uppercase fw-bold">Manage</span>
        </li>
        <li class="sidenav-item">
          <a class="sidenav-link" href="">
            <i class="fas fa-cubes fa-fw me-3"></i><span>Projects</span></a>
        </li>
        <li class="sidenav-item">
          <a class="sidenav-link" href="">
            <i class="fas fa-database fa-fw me-3"></i><span>Databases</span></a>
        </li>
        <li class="sidenav-item">
          <a class="sidenav-link" href="">
            <i class="fas fa-stream fa-fw me-3"></i><span>Custom domains</span></a>
        </li>
        <li class="sidenav-item">
          <a class="sidenav-link" href="">
            <i class="fas fa-code-branch fa-fw me-3"></i><span>Repositories</span></a>
        </li>
        <li class="sidenav-item">
          <a class="sidenav-link" href="">
            <i class="fas fa-users fa-fw me-3"></i><span>Team</span></a>
        </li>


        <li class="sidenav-item pt-3">
          <span class="sidenav-subheading text-muted text-uppercase fw-bold">Maintain</span>
        </li>
        <li class="sidenav-item">
          <a class="sidenav-link" href="">
            <i class="fas fa-chart-pie fa-fw me-3"></i><span>Analytics</span></a>
        </li>
        <li class="sidenav-item">
          <a class="sidenav-link" href="">
            <i class="fas fa-sync fa-fw me-3"></i><span>Backups</span></a>
        </li>
        <li class="sidenav-item">
          <a class="sidenav-link" href="">
            <i class="fas fa-shield-alt fa-fw me-3"></i><span>Security</span></a>
        </li>


        <li class="sidenav-item pt-3">
          <span class="sidenav-subheading text-muted text-uppercase fw-bold">Admin</span>
        </li>
        <li class="sidenav-item">
          <a class="sidenav-link" href="">
            <i class="fas fa-money-bill fa-fw me-3"></i><span>Billing</span></a>
        </li>
        <li class="sidenav-item">
          <a class="sidenav-link" href="">
            <i class="fas fa-file-contract fa-fw me-3"></i><span>License</span></a>
        </li>

        <li class="sidenav-item pt-3">
          <span class="sidenav-subheading text-muted text-uppercase fw-bold">Tools</span>
        </li>
        <li class="sidenav-item">
          <a class="sidenav-link"><i class="fas fa-hand-pointer fa-fw me-3"></i>Drag & drop builder</a>
        </li>
        <li class="sidenav-item">
          <a class="sidenav-link"><i class="fas fa-code fa-fw me-3"></i>Online code editor</a>
        </li>
        <li class="sidenav-item">
          <a class="sidenav-link"><i class="fas fa-copy fa-fw me-3"></i>SFTP</a>
        </li>
        <li class="sidenav-item">
          <a class="sidenav-link"><i class="fab fa-jenkins fa-fw me-3"></i>Jenkins</a>
        </li>
        <li class="sidenav-item">
          <a class="sidenav-link" href="">
            <i class="fab fa-gitlab fa-fw me-3"></i><span>GitLab</span></a>
        </li>
      </ul>
    </nav>

    <!--- Navbar --->
    <nav id="main-navbar" class="navbar navbar-expand-lg fixed-top shadow-1">

      <!--- Container wrapper --->
      <div class="container-fluid">

        <!--- Toggler --->
        <button data-mdb-toggle="sidenav" data-mdb-target="#main-sidenav"
          class="btn shadow-0 p-0 me-3 d-block d-xxl-none" data-mdb-ripple-init aria-controls="#main-sidenav"
          aria-haspopup="true">
          <i class="fas fa-bars fa-lg"></i>
        </button>

        <!--- Search form --->
        <form class="d-none d-md-flex input-group w-auto my-auto">
          <input id="search-focus" autocomplete="off" type="search" class="form-control rounded"
            placeholder='Search (ctrl + alt to focus)' style="min-width: 225px" />
          <span class="input-group-text border-0"><i class="fas fa-search text-secondary"></i></span>
        </form>

        <!--- Right links --->
        <ul class="navbar-nav ms-auto d-flex flex-row">

          <!--- Notification dropdown --->
          <li class="nav-item dropdown">
            <a class="nav-link me-3 me-lg-0 dropdown-toggle hidden-arrow" href="#" id="navbarDropdownMenuLink"
              role="button" data-mdb-dropdown-init aria-expanded="false">
              <i class="fas fa-bell link-secondary"></i>
              <span class="badge rounded-pill badge-notification bg-danger">1</span>
            </a>
            <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="navbarDropdownMenuLink">
              <li><a class="dropdown-item" href="#">Some news</a></li>
              <li><a class="dropdown-item" href="#">Another news</a></li>
              <li>
                <a class="dropdown-item" href="#">Something else here</a>
              </li>
            </ul>
          </li>

          <!--- Icon dropdown --->
          <li class="nav-item dropdown">
            <a class="nav-link me-3 me-lg-0 dropdown-toggle hidden-arrow" href="#" id="navbarDropdown" role="button"
              data-mdb-dropdown-init aria-expanded="false">
              <i class="flag flag-united-kingdom m-0"></i>
            </a>
            <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="navbarDropdown">
              <li>
                <a class="dropdown-item" href="#"><i class="flag flag-kingdom flag"></i>English
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
          </li>

          <!--- Avatar --->
          <li class="nav-item dropdown">
            <a class="nav-link dropdown-toggle hidden-arrow d-flex align-items-center" href="#"
              id="navbarDropdownMenuLink" role="button" data-mdb-dropdown-init aria-expanded="false">
              <img src="https://mdbootstrap.com/img/new/avatars/2.jpg" class="rounded-circle" height="22" alt="Avatar"
                loading="lazy" />
            </a>
            <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="navbarDropdownMenuLink">
              <li><a class="dropdown-item " href="#">My profile</a></li>
              <li><a class="dropdown-item" href="#">Settings</a></li>
              <li><a class="dropdown-item" href="#">Logout</a></li>
            </ul>
          </li>
        </ul>
      </div>

    </nav>

    <!--- Heading --->
    <section class="text-center text-md-start">

      <!--- Background gradient --->
      <div class="p-5" style="height: 200px;">
      </div>

    </section>

</header>
