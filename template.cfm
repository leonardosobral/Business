<!DOCTYPE html>
<html lang="pt-BR">
<!--- BACKEND --->
<cfinclude template="includes/backend/backend_login.cfm"/>
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
    <meta http-equiv="x-ua-compatible" content="ie=edge" />
    <title>RoadRunners Business</title>
    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://use.fontawesome.com/releases/v7.1.0/css/all.css" />
    <!-- Google Fonts Roboto -->
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap" />
    <!-- MDB -->
    <link rel="stylesheet" href="assets/css/mdb.min.css" />
    <link rel="stylesheet" href="assets/plugins/css/all.min.css">
    <!-- Custom styles -->
    <link rel="stylesheet" href="css/style.css?11" />
</head>
<body data-mdb-theme="dark" class="bg-dark-subtle">
    <!--Main Navigation-->
<header>
  <!-- Sidenav -->
    <cfinclude template="includes/estrutura/sidenav.cfm">
  <!-- Sidenav -->

  <!-- Navbar -->
    <cfinclude template="includes/estrutura/navbar.cfm">
  <!-- Navbar -->

  <!-- Heading -->
  <section class="text-center text-md-start">
    <!-- Background gradient -->
    <div class="p-5 bg-dark-subtle" style="height: 140px;
    /*                        background: linear-gradient(
                            to right,
                            hsl(209, 42.2%, 65%),
                            hsl(209, 42.2%, 85%)
                            );*/
    ">
    </div>
    <!-- Background image -->
  </section>
  <!-- Heading -->

</header>
<!--Main Navigation-->

<!--Main layout-->
<main class="" style="margin-top: -55px;">
  <!-- Container for demo purpose -->
  <div class="container px-4">

    <!---<cfinclude template="includes/estrutura/dashboard.cfm">--->
    <cfinclude template="ads/includes/home.cfm">

  </div>
  <!-- Container for demo purpose -->
</main>
<!--Main layout-->

<!--Footer-->
<footer></footer>
<!--Footer-->
    <!-- MDB -->
    <script type="text/javascript" src="assets/js/mdb.umd.min.js"></script>
    <script type="text/javascript" src="assets/plugins/js/all.min.js"></script>
    <!-- Custom scripts -->
    <script type="text/javascript" src="js/script.js"></script>
</body>

  <cfinclude template="includes/backend/backend_login.cfm">

</html>

