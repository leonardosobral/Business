<!doctype html>
<html lang="pt-br" data-mdb-theme="dark">

<!--- DEFINE THE PAGE REQUEST PROPERTIES --->
<cfsetting requesttimeout="180" showdebugoutput="false" enablecfoutputonly="false" />
<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/inscricao/"/>
<cfset VARIABLES.theme = "dark"/>

<!--- TAG PARAM TREAT --->
<cfparam name="URL.tag" default=""/>
<cfset URL.tag = trim(replace(URL.tag, '/', ''))/>

<!--- PRODUTO --->
<cfif isDefined("FORM.produto_codigo")>
    <cfcookie name="produto_codigo" secure="yes" encodevalue="yes" value="#FORM.produto_codigo#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
<cfelseif NOT isDefined("COOKIE.produto_codigo") OR (isDefined("COOKIE.produto_codigo") AND COOKIE.produto_codigo EQ "inscricao365")>
    <cfcookie name="produto_codigo" secure="yes" encodevalue="yes" value="runpro" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
</cfif>

<!--- BACKEND --->
<cfinclude template="../includes/estrutura/variaveis.cfm"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>

<!--- META INFO --->
<cfset VARIABLES.canonical = "#APPLICATION.baseCanonica##VARIABLES.template##URL.tag##Len(trim(URL.tag)) ? '/' : ''##VARIABLES.queryString#"/>
<cfset VARIABLES.title = "Desafio 365 CNA - Parceria #APPLICATION.nomeSite#"/>
<cfset VARIABLES.description = "Desafio 365 CNA - Parceria #APPLICATION.nomeSite#"/>
<cfset VARIABLES.keywords = "resultados, corrida, competição, pódio, atletas, corredores"/>

<!--- HEAD --->
<head>

    <!--- REQUIRED META TAGS --->
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>

    <title>Runner Hub - BI</title>
    <cfinclude template="../includes/seo-web-tools-head.cfm"/>

    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.5.0/css/font-awesome.min.css">

</head>

<style>
    .stepper-active .stepper-head-icon {
        background-color: #f4b120 !important;
        color: #333333 !important;
    }
</style>

<body>


    <!--- CONTAINER DE CONTEUDO --->

    <div class="container mt-2">


        <!--- AREA LOGADA --->

        <cfif isDefined("COOKIE.id")>

            <cfquery name="qPerfil">
                SELECT usr.id, usr.name, usr.email, usr.is_admin, usr.is_partner, usr.is_dev, usr.strava_id, usr.aka, usr.fonte_lead,
                coalesce('/assets/paginas/' || pg.path_imagem, usr.imagem_usuario, '/assets/user.png?') as imagem_usuario,
                pg.tag, pg.tag_prefix, pg.id_pagina, coalesce(pg.nome, usr.name) as nome, pg.verificado, pg.cidade, pg.uf,
                pg.instagram, pg.youtube, pg.tiktok, pg.website, pg.loja, pg.whatsapp, pg.whatsapp_publico, pg.descricao
                FROM tb_usuarios usr
                inner join tb_paginas_usuarios pgusr on usr.id = pgusr.id_usuario
                inner join tb_paginas pg on pg.id_pagina = pgusr.id_pagina
                WHERE usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
            </cfquery>

            <div class="row g-3 mt-0">

                <!--- LOGO CNA 365 --->

                <div class="col-lg-6">
                    <div class="card h-100">
                        <div class="card-body d-flex align-items-center justify-content-center">
                            <img class="w-100" src="../assets/runpro_cover.png">
                        </div>
                    </div>
                </div>

                <!--- STEPS --->

                <div class="col-lg-6">

                    <div class="card">

                        <div class="card-header">

                            <!--- CONTADOR DE PASSOS --->

                            <ul class="stepper" style="text-shadow: none !important;">
                                <li class="stepper-step <cfif URL.filtro EQ "">stepper-active</cfif>">
                                    <div class="stepper-head">
                                        <span class="stepper-head-icon">1</span>
                                        <span class="stepper-head-text d-none d-lg-block">Criar Conta</span>
                                    </div>
                                </li>
                                <li class="stepper-step <cfif URL.filtro EQ "inscricao">stepper-active</cfif>">
                                    <div class="stepper-head">
                                        <span class="stepper-head-icon">2</span>
                                        <span class="stepper-head-text d-none d-lg-block">Perfil</span>
                                    </div>
                                </li>
                                <li class="stepper-step <cfif URL.filtro CONTAINS "pagamento">stepper-active</cfif>">
                                    <div class="stepper-head">
                                        <span class="stepper-head-icon">3</span>
                                        <span class="stepper-head-text d-none d-lg-block">Inscrição</span>
                                    </div>
                                </li>
                            </ul>

                        </div>

                        <div class="card-body p-3">

                            <cfif URL.filtro EQ "">
                                <cfinclude template="cadastro.cfm"/>
                            </cfif>

                            <cfif URL.filtro EQ "inscricao">
                                <cfinclude template="inscricao.cfm"/>
                            </cfif>

                            <cfif URL.filtro EQ "pagamento">

                                <cfif isDefined("forma_pagamento") AND FORM.forma_pagamento EQ "pix">

                                    <cfinclude template="pagamento_pix.cfm"/>

                                <cfelseif isDefined("forma_pagamento") AND FORM.forma_pagamento EQ "cc">

                                    <cfinclude template="pagamento_cc.cfm"/>

                                <cfelseif isDefined("forma_pagamento") AND FORM.forma_pagamento EQ "internacional">

                                    <cfinclude template="pagamento_internacional.cfm"/>

                                <cfelse>

                                    <cfinclude template="pagamento.cfm"/>

                                </cfif>

                            </cfif>

                        </div>

                        <div class="card-footer text-center">
                            <span class="small">Está com alguma dificuldade?</span>
                            <a href="https://wa.me/554891534589?text=RunPro" target="_blank">
                                <button type="button" class="btn btn-sm shadow-0 mx-2 btn-outline-success">
                                    <i class="fa-brands fa-whatsapp"></i>
                                    Fale com o suporte
                                </button>
                            </a>
                        </div>

                    </div>

                </div>

            </div>

        <cfelse>

            <!--- AREA NAO LOGADA --->

            <div class="row g-3 mt-0">

                <!--- LOGO CNA 365 --->

                <div class="col-lg-6">
                    <div class="card h-100">
                        <div class="card-body d-flex align-items-center justify-content-center">
                            <img class="d-block d-lg-none w-100" src="../assets/logo_365_horiz.svg">
                            <img class="d-none d-lg-block w-100" src="../assets/logo_365.svg">
                        </div>
                    </div>
                </div>

                <!--- LOGIN --->

                <div class="col-lg-6">
                    <div class="card h-100">
                        <!---<div class="card-header h2">Passo 1 - Login com Google</div>--->
                        <div class="card-body align-content-center">

                            <h4 class="card-text text-center">Para aceitar o desafio,<br/>leia com atenção!</h4>
                            <p class="text-center small">Para a sua segurança, não guardamos senhas no Road Runners.
                                Por este motivo, você precisa se identificar utilizando sua conta Google.
                                E não precisa ser com o mesmo email de sua conta Strava.</p>

                            <!--- GOOGLE LOGIN NOVO --->

                            <div class="d-flex justify-content-center">

                                <div id="g_id_onload"
                                     data-client_id="921450846888-qa9a1alk06v6i0ao4jbiihdfrn8j7528.apps.googleusercontent.com"
                                     data-callback="handleCredentialResponse"
                                     data-auto_select="true"
                                     data-auto_prompt="false">
                                </div>

                                <div class="g_id_signin text-center"
                                     data-type="standard"
                                     data-size="large"
                                     data-theme="outline"
                                     data-text="sign_in_with"
                                     data-shape="rectangular"
                                     data-logo_alignment="left">
                                </div>

                            </div>

                        </div>

                        <div class="card-footer text-center">
                            <span class="small">Está com alguma dificuldade?</span>
                            <a href="https://wa.me/554891534589?text=Desafio365" target="_blank">
                                <button type="button" class="btn btn-success btn-sm shadow-0 mx-2">
                                    <i class="fa-brands fa-whatsapp"></i>
                                    Fale com o suporte
                                </button>
                            </a>
                        </div>

                    </div>
                </div>

            </div>

        </cfif>


        <!--- FOOTER --->

        <cfinclude template="../includes/footer_parceiro.cfm"/>

    </div>


    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/seo-web-tools-body-end.cfm"/>


</body>

</html>

