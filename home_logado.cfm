<!doctype html>
<html lang="pt-br" data-mdb-theme="dark">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- BACKEND --->
<cfinclude template="includes/backend/backend_login.cfm"/>
<cfset VARIABLES.theme = "dark"/>

<!--- HEAD --->
<head>

    <!--- REQUIRED META TAGS --->
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>

    <title>Runner Hub - BI</title>
    <cfinclude template="includes/seo-web-tools-head.cfm"/>

    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.5.0/css/font-awesome.min.css">

</head>

<body style="background-color:#222222">

    <cfif NOT isDefined("COOKIE.id")>

        <div class="g-signin2 ms-2" data-onsuccess="onSignIn"></div>

    <cfelse>

        <div class="container-fluid pt-3" style="background-image: repeating-linear-gradient(45deg, rgba(255, 255, 255, 0.02) 0px, rgba(255, 255, 255, 0.05) 1px, transparent 1px, transparent 10px);">


            <!--- HEADER --->

            <cfinclude template="includes/header_parceiro.cfm"/>


            <!--- CONTEUDO --->

            <div class="row g-3">

                <div class="col-12">
                    <div data-mdb-alert-init class="alert text-center" role="alert" data-mdb-color="light">
                        <b>Cadastro inicial realizado com sucesso.</b><br>Seu perfil está sob análise.
                    </div>
                </div>

                <div class="col-12">
                    <div class="card bg-warning bg-opacity-50">
                        <div class="row p-3">
                            <div class="col-md-6 text-center align-content-center"><img src="/lib/images/runpro.svg" class="w-50"></div>
                            <div class="col-md-6 align-content-center">
                                Plataforma Ads disponível a partir de <b>01 de novembro</b>.
                            </div>
                        </div>
                    </div>
                </div>

                <cfoutput query="qPermissoes" group="tipo">

                    <!---<hr/>--->

                    <div>
                        <h4 class="bg-black bg-opacity-25 px-2 py-1 rounded">#uCase(qPermissoes.tipo)#</h4>
                    </div>

                    <cfif NOT #qPermissoes.recordcount#>Seu cadastro está em análise, você receberá um email ou mensagem no momento da ativação.</cfif>

                    <cfoutput>

                        <div class="mb-1 col-sm-12 col-md-6 col-lg-4 col-xl-3">

                            <div class="card" data-mdb-theme="light">

                                <div class="card-header h6" style="background-color: #qPermissoes.cor_fundo#;">#qPermissoes.titulo#</div>

                                <div class="card-body text-center p-2 d-flex align-items-center justify-content-center" style="height: 100px">
                                    <div>
                                        <img src="/assets/logos/#qPermissoes.logo#.png?2" style="max-height:75px; max-width: 200px;" onerror="this.src='/assets/logos/runnerhub.png';">
                                    </div>
                                </div>

                                <div class="card-footer p-3" style="background-color: #qPermissoes.cor_fundo#;">
                                    <cfif qPermissoes.tipo EQ "eventos">
                                        <div class="btn-group w-100" role="group" aria-label="menuEvento">
                                            <a class="btn btn-light px-2" target="_blank" href="https://roadrunners.run/#qPermissoes.tipo_agregacao#/#qPermissoes.tag#/" data-mdb-ripple-init>Calendário</a>
                                            <a class="btn btn-light px-2" target="_blank" href="https://openresults.run/#qPermissoes.tipo_agregacao#/#qPermissoes.tag#/" data-mdb-ripple-init>Resultados</a>
                                            <a class="btn btn-dark px-2" href="/evento/#qPermissoes.tag#/" data-mdb-ripple-init>ACESSAR</a>
                                        </div>
                                    <cfelse>
                                        <a class="btn btn-dark w-100" href="/evento/#qPermissoes.tag#/" data-mdb-ripple-init>ACESSAR</a>
                                    </cfif>
                                </div>

                            </div>

                        </div>

                    </cfoutput>

                </cfoutput>

            </div>

        </div>

    </cfif>

    <cfinclude template="includes/footer_parceiro.cfm"/>

    <!---    <a href="https://wa.me/5548991534589"
           style="position: fixed;
                width: 52px;
                height: 52px;
                bottom: 20px;
                right: 20px;
                background-color: #25d366;
                color: #FFF;
                border-radius: 50px;
                text-align: center;
                font-size: 36px;
                box-shadow: 1px 1px 2px #888;
                z-index: 1000;" target="_blank">
            <i style="margin-top:8px" class="fa fa-whatsapp"></i>
        </a>--->

    <cfinclude template="includes/seo-web-tools-body-end.cfm"/>

</body>

</html>
