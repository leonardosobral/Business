<!DOCTYPE html>
<html lang="pt-BR">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- BACKEND --->
<cfinclude template="../includes/backend/backend_login.cfm"/>

<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
    <meta http-equiv="x-ua-compatible" content="ie=edge" />
    <title>RoadRunners Business</title>
    <!--- Font Awesome --->
    <link rel="stylesheet" href="https://use.fontawesome.com/releases/v7.1.0/css/all.css" />
    <!--- Google Fonts Roboto --->
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap" />
    <!--- MDB --->
    <link rel="stylesheet" href="/assets/css/mdb.min.css" />
    <!--- Custom styles --->
    <link rel="stylesheet" href="css/style.css?15" />
</head>

<body data-mdb-theme="dark">

  <!--- HEADER E NAVAGACAO --->

  <cfinclude template="includes/header.cfm"/>

  <!--- CONTEUDO --->

  <main class="mb-5" id="content">

    <div class="container px-4">

      <cfinclude template="includes/home.cfm"/>

    </div>

  </main>

  <!--- RODAPE --->

  <cfinclude template="includes/footer.cfm"/>
    
  <!--- MDB --->
  <script type="text/javascript" src="../assets/js/mdb.umd.min.js"></script>

  <!--- CUSTOM SCRIPTS --->
  <script type="text/javascript" src="js/script.js"></script>

</body>

</html>
