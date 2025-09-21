<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
    <meta http-equiv="x-ua-compatible" content="ie=edge" />
    <title>Material Design for Bootstrap</title>
    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.11.2/css/all.css" />
    <!-- Google Fonts Roboto -->
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap" />
    <!-- MDB -->
    <link rel="stylesheet" href="/assets/css/mdb.min.css" />
    <!-- Custom styles -->
    <link rel="stylesheet" href="css/style.css?17" />
</head>
<body data-mdb-theme="dark">
    <!--Main Navigation-->
<header>
  <!-- Sidenav -->
  <nav id="main-sidenav" data-mdb-sidenav-init class="sidenav sidenav-sm shadow-1" data-mdb-hidden="false" data-mdb-accordion="true">
    <a class="d-flex justify-content-center pt-4 pb-2" href="#!"  data-mdb-ripple-init data-mdb-ripple-color="primary">
      <img id="MDB-logo" src="../assets/runnerhub_logo_negativo.png"
           alt="RunnerHub Logo" draggable="false" class="w-responsive" />
    </a>

    <hr class="hr">

    <ul class="sidenav-menu px-2 pb-5">
      <li class="sidenav-item">
        <a class="sidenav-link" href="">
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
  <!-- Sidenav -->

  <!-- Navbar -->
  <nav id="main-navbar" class="navbar navbar-expand-lg fixed-top shadow-1">
    <!-- Container wrapper -->
    <div class="container-fluid">
      <!-- Toggler -->
      <button data-mdb-toggle="sidenav" data-mdb-target="#main-sidenav"
              class="btn shadow-0 p-0 me-3 d-block d-xxl-none"  data-mdb-ripple-init aria-controls="#main-sidenav" aria-haspopup="true">
        <i class="fas fa-bars fa-lg"></i>
      </button>

      <!-- Search form -->
      <form class="d-none d-md-flex input-group w-auto my-auto">
        <input id="search-focus" autocomplete="off" type="search" class="form-control rounded"
               placeholder='Search (ctrl + alt to focus)' style="min-width: 225px" />
        <span class="input-group-text border-0"><i class="fas fa-search text-secondary"></i></span>
      </form>

      <!-- Right links -->
      <ul class="navbar-nav ms-auto d-flex flex-row">
        <!-- Notification dropdown -->
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

        <!-- Icon dropdown -->
        <li class="nav-item dropdown">
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
        </li>

        <!-- Avatar -->
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
    <!-- Container wrapper -->
  </nav>
  <!-- Navbar -->

  <!-- Heading -->
  <section class="text-center text-md-start">
    <!-- Background gradient -->
    <div class="p-5" style="height: 165px;">
    </div>
    <!-- Background image -->
  </section>
  <!-- Heading -->

</header>
<!--Main Navigation-->

<!--Main layout-->
<main class="mb-5" style="margin-top: -55px;">
  <!-- Container for demo purpose -->
  <div class="container px-4">

    <!-- Section: Summary -->
    <section class="mb-5">

      <div class="row gx-xl-5">
        <div class="col-lg-4 mb-4 mb-lg-0">
          <div class="card shadow-0">
            <div class="card-body">
              <div class="d-flex align-items-center">
                <div class="flex-shrink-0">
                  <div class="p-3 badge-primary rounded-4">
                    <i class="fas fa-thermometer-half fa-lg fa-fw"></i>
                  </div>
                </div>
                <div class="flex-grow-1 ms-4">
                  <p class="text-muted mb-1">Temperature</p>
                  <h2 class="mb-0">
                    25
                    <span class="" style="font-size: 0.875rem">
                      <span>°C</span></span>
                  </h2>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="col-lg-4 mb-4 mb-lg-0">
          <div class="card shadow-0">
            <div class="card-body">
              <div class="d-flex align-items-center">
                <div class="flex-shrink-0">
                  <div class="p-3 badge-primary rounded-4">
                    <i class="fas fa-wind fa-lg fa-fw"></i>
                  </div>
                </div>
                <div class="flex-grow-1 ms-4">
                  <p class="text-muted mb-1">Air quality</p>
                  <h2 class="mb-0">
                    97
                    <span class="" style="font-size: 0.875rem">
                      <span>%</span></span>
                  </h2>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="col-lg-4 mb-lg-0">
          <div class="card shadow-0">
            <div class="card-body">
              <div class="d-flex align-items-center">
                <div class="flex-shrink-0">
                  <div class="p-3 badge-primary rounded-4">
                    <i class="fas fa-tint fa-lg fa-fw"></i>
                  </div>
                </div>
                <div class="flex-grow-1 ms-4">
                  <p class="text-muted mb-1">Humidity</p>
                  <h2 class="mb-0">
                    60
                    <span class="" style="font-size: 0.875rem">
                      <span>%</span></span>
                  </h2>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
    <!-- Section: Summary -->

    <!-- Section: MSC -->
    <section class="">

      <div class="row gx-xl-5">

        <div class="col-lg-8 mb-4 mb-lg-0 h-100">

          <div class="card shadow-0">
            <div class="card-body">

              <!-- Pills navs -->
              <ul class="nav nav-tabs nav-fill mb-4" id="ex1" role="tablist">
                <li class="nav-item" role="presentation">
                  <a class="nav-link active" id="ex1-tab-1" data-mdb-pill-init href="#ex1-pills-1" role="tab"
                     aria-controls="ex1-pills-1" aria-selected="true">Kitchen</a>
                </li>
                <li class="nav-item" role="presentation">
                  <a class="nav-link" id="ex1-tab-2" data-mdb-pill-init href="#ex1-pills-2" role="tab"
                     aria-controls="ex1-pills-2" aria-selected="false">Bedroom</a>
                </li>
                <li class="nav-item" role="presentation">
                  <a class="nav-link" id="ex1-tab-3" data-mdb-pill-init href="#ex1-pills-3" role="tab"
                     aria-controls="ex1-pills-3" aria-selected="false">Living room</a>
                </li>
              </ul>
              <!-- Pills navs -->

              <!-- Pills content -->
              <div class="tab-content" id="ex1-content">
                <div class="tab-pane fade show active" id="ex1-pills-1" role="tabpanel" aria-labelledby="ex1-tab-1">

                  <div class="bg-image rounded-4">
                    <img src="https://mdbootstrap.com/img/Photos/dashboard/home/kitchen.jpg" class="w-100"
                         alt="Louvre Museum" />
                    <div class="mask" style="background-color: rgba(0, 0, 0, 0.1)">
                      <div class="d-flex justify-content-between align-items-start h-100 p-4">
                        <small class="text-white">
                          23.05.2022 18:45
                        </small>

                        <span class="badge badge-light">
                          <i class="fas fa-video me-1 text-danger"></i>
                          <span>Recording</span>
                        </span>
                      </div>
                    </div>
                  </div>

                </div>
                <div class="tab-pane fade" id="ex1-pills-2" role="tabpanel" aria-labelledby="ex1-tab-2">
                  <div class="bg-image rounded-4">
                    <img src="https://mdbootstrap.com/img/Photos/dashboard/home/bedroom.jpg" class="w-100"
                         alt="Louvre Museum" />
                    <div class="mask" style="background-color: rgba(0, 0, 0, 0.1)">
                      <div class="d-flex justify-content-between align-items-start h-100 p-4">
                        <small class="text-white">
                          23.05.2022 18:45
                        </small>

                        <span class="badge badge-light">
                          <i class="fas fa-video me-1 text-danger"></i>
                          <span>Recording</span>
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
                <div class="tab-pane fade" id="ex1-pills-3" role="tabpanel" aria-labelledby="ex1-tab-3">
                  <div class="bg-image rounded-4">
                    <img src="https://mdbootstrap.com/img/Photos/dashboard/home/living-room.jpg" class="w-100"
                         alt="Louvre Museum" />
                    <div class="mask" style="background-color: rgba(0, 0, 0, 0.1)">
                      <div class="d-flex justify-content-between align-items-start h-100 p-4">
                        <small class="text-white">
                          23.05.2022 18:45
                        </small>

                        <span class="badge badge-light">
                          <i class="fas fa-video me-1 text-danger"></i>
                          <span>Recording</span>
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <!-- Pills content -->

            </div>
          </div>

        </div>

        <div class="col-lg-4 mb-4 mb-lg-0">

          <div class="card shadow-0 mb-5 h-100">

            <div class="card-header">
              <small>Energy consumption by room</small>
            </div>
            <div class="card-body h-100 d-flex align-items-center">

              <div id="chart-consumption-by-room" class="w-100"></div>

            </div>
          </div>

        </div>

      </div>

    </section>
    <!-- Section: MSC -->

  </div>
  <!-- Container for demo purpose -->
</main>
<!--Main layout-->

<!--Footer-->
<footer></footer>
<!--Footer-->
    <!-- MDB -->
    <script type="text/javascript" src="js/mdb.min.js"></script>
    <!-- Custom scripts -->
    <script type="text/javascript" src="js/script.js"></script>
</body>
</html>

