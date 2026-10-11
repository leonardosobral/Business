<!doctype html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/circuitocatarinense/corridaderua/"/>
<cfset VARIABLES.theme = "dark"/>

<!--- TAG PARAM TREAT --->
<cfparam name="URL.tag" default=""/>
<cfset URL.tag = trim(replace(URL.tag, '/', ''))/>

<!--- BACKEND --->
<cfinclude template="/includes/estrutura/variaveis.cfm"/>
<cfinclude template="/includes/backend/backend.cfm"/>
<cfinclude template="/includes/backend/backend_login.cfm"/>

<cfquery name="qDesafioSelecionado">
    SELECT * FROM desafios_eventos
    WHERE tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.tag#"/>
</cfquery>

<!--- META INFO --->
<cfset VARIABLES.canonical = "#APPLICATION.baseCanonica##VARIABLES.template##URL.tag##Len(trim(URL.tag)) ? '/' : ''##VARIABLES.queryString#"/>
<cfset VARIABLES.title = "Circuito Catarinense 2026: Corrida de Rua | #APPLICATION.nomeSite#"/>
<cfset VARIABLES.description = "Consulte as etapas, a pontuação e a classificação de atletas e equipes no Circuito Catarinense de Corrida de Rua 2026."/>
<cfset VARIABLES.keywords = "resultados, corrida, competição, pódio, atletas, corredores"/>

<!--- HEAD --->
<cfinclude template="/includes/estrutura/head.cfm"/>

<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Agdasima:wght@400;700&display=swap" rel="stylesheet">

<style>
    :root{
        --mdb-danger-rgb: 250, 50, 50 !important;
    }
    /*CORES*/
    .btn-danger {
        --mdb-btn-bg: rgb(var(--mdb-danger-rgb));
        --mdb-btn-box-shadow: 0 4px 9px -4px rgb(var(--mdb-danger-rgb));
        --mdb-btn-hover-bg: rgb(var(--mdb-danger-rgb));
        --mdb-btn-focus-bg: rgb(var(--mdb-danger-rgb));
        --mdb-btn-box-shadow-state: 0 8px 9px -4px rgba(var(--mdb-danger-rgb);, 0.3), 0 4px 18px 0 rgba(var(--mdb-danger-rgb), 0.2);
    }
    .btn-outline-danger {
        --mdb-btn-bg: transparent;
        --mdb-btn-color: rgb(var(--mdb-danger-rgb));
        --mdb-btn-hover-bg: #fdf6f7;
        --mdb-btn-hover-color: rgb(var(--mdb-danger-rgb));
        --mdb-btn-focus-bg: #fdf6f7;
        --mdb-btn-focus-color: rgb(var(--mdb-danger-rgb));
        --mdb-btn-active-bg: #fdf6f7;
        --mdb-btn-active-color: rgb(var(--mdb-danger-rgb));
        --mdb-btn-outline-border-color: rgb(var(--mdb-danger-rgb));
        --mdb-btn-outline-focus-border-color: rgb(var(--mdb-danger-rgb));
        --mdb-btn-outline-hover-border-color: rgb(var(--mdb-danger-rgb));
        border-color: var(--mdb-btn-outline-border-color);
    }

    .font-regular {
        font-family: "Agdasima", sans-serif;
        font-weight: 400;
        font-style: normal;
    }

    .font-bold {
        font-family: "Agdasima", sans-serif;
        font-weight: 700;
        font-style: normal;
    }


    html,
    body,
    .intro {
        _height: 100%;
        color: #ffffff;
    }

    .back-gradient {
        background: #666666;
        background: radial-gradient(circle, #666666 0%, #111111 100%);
    }

    table td,
    table th {
        padding: 6px 2px !important;
        line-height: 1rem;
        font-size: 1.1rem;
        vertical-align: middle;
    }
    table th {
        /*font-family: lastica;*/
        text-align: center;
    }

    .xsmall {
        font-size: 10px;
    }

</style>

<body class="back-gradient">

    <!--- SEO WEB TOOLS --->

    <cfinclude template="/includes/estrutura/seo-web-tools-body-start.cfm"/>


    <div class="container">


        <!--- HEADER --->

        <cfinclude template="/includes/estrutura/header.cfm"/>

    </div>


    <section class="intro" style="margin-top: -50px; margin-bottom: 50px;">

        <div class="pt-2 bg-image bg-fixed" style="background-image:url('../assets/images/fca_bg_rua.jpg')">

            <div class="" style="">

                <div class="fixed-top bg-black mb-5 mt-4 pt-4 z-1">
                    <div class="container py-1">
                        <div class="row">
                            <div class="col-12 col-md-8 align-content-center">
                                <a href="/circuitocatarinense/"><p class="h3 text-light font-bold m-0 text-center text-md-start"><img src="../assets/images/logo_fca_branco.png" class="w-75px">Circuito Catarinense de Corrida</p></a>
                            </div>
                            <div class="col-12 col-md-4 text-center text-md-end">
                                <a class="btn btn-sm btn-dark shadow-3 btn-rounded my-1 px-3" href="/circuitocatarinense/"><i class="fa-solid fa-angle-left"></i></a>
                                <a class="btn btn-sm btn-danger shadow-3 btn-rounded my-1" href="/circuitocatarinense/corridaderua/"><i class="fa-solid fa-person-running"></i>Corrida de Rua</a>
                                <a class="btn btn-sm btn-success shadow-3 btn-rounded my-1" href="/circuitocatarinense/trailrun/"><i class="fa-solid fa-mountain"></i>Trail Run</a>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="container py-5 mt-5">

                    <!---<div class="text-center"><img src="../assets/images/logo_fca_branco.png" width="200px" class=""></div>--->
                    <div class="text-center m-0 fs-1 font-regular mt-5">Circuito Catarinense de</div>

                    <h1 class="text-danger text-center font-bold display-1 mt-n3"><span class="visually-hidden">Circuito Catarinense de </span>Corrida de Rua
                        <!---<a class="text-light p-2 fs-4 mt-2 float-start" href="../"><i class="fa-solid fa-chevron-left"></i></a>--->
                    </h1>

                    <div class="row d-fill text-light my-5 p-4">
                        <div class="col-12 col-md-6">
                            <div class="text-uppercase">
                                <h2 class="font-bold display-6"><i class="fa-solid fa-person-running float-start fa-2x mt-2 me-2 text-danger"></i>Provas incluídas <br/>no Circuito da FCA:</h2>
                                <p class="small"> *obs: o circuito é exclusivo para a distância<br class="d-none d-md-block"> total de uma meia-maratona (21.0975m)</p>
                                <a class="btn btn-outline-danger shadow-3 btn-rounded btn-lg mb-3 me-2" href="#ranking"> Veja o ranking</a>
                                <a class="btn btn-danger shadow-3 btn-rounded btn-lg mb-5 mb-md-3" href="./inscricao/"> Inscreva-se</a>
                            </div>
                        </div>
                        <div class="col-12 col-md-6 lastica text-uppercase">
                            <a href="/evento/2026-31-meia-maratona-de-joinville/" class="link-light link-opacity-50-hover" target="_blank">
                                <p><span class="me-2 text-danger">01.</span><span class="h3 font-bold">Meia Maratona de Joinville <img src="/assets/verified.png" class="<cfif '2026-03-01' GT now()>d-none</cfif> mb-1"></span><span class=" ms-2">01/03/2026</span></p>
                            </a>
                            <a href="/evento/2026-meia-maratona-de-balneario-camboriu-2026/" class="link-light link-opacity-50-hover" target="_blank">
                                <p><span class=" me-2 text-danger">02.</span><span class="h3 font-bold">Meia Maratona de Balneário Camboriú <img src="/assets/verified.png" class="<cfif '2026-04-26' GT now()>d-none</cfif> mb-1"></span><span class=" ms-2">26/04/2026</span></p>
                            </a>
                            <a href="/evento/2026-meia-maratona-internacional-de-florianopolis-2026/" class="link-light link-opacity-50-hover" target="_blank">
                                <p><span class=" me-2 text-danger">03.</span><span class="h3 font-bold">Meia Maratona Intl. de Florianópolis <img src="/assets/verified.png" class="<cfif '2026-05-03' GT now()>d-none</cfif> mb-1"></span><span class=" ms-2">03/05/2026</span></p>
                            </a>
                            <a href="/evento/2026-meia-maratona-de-chapeco-2026/" class="link-light link-opacity-50-hover" target="_blank">
                                <p><span class=" me-2 text-danger">04.</span><span class="h3 font-bold">Meia Maratona de Chapecó <img src="/assets/verified.png" class="<cfif '2026-08-02' GT now()>d-none</cfif> mb-1"></span><span class=" ms-2">02/08/2026</span></p>
                            </a>
                            <a href="/evento/2026-maratona-internacional-de-floripa-2026/" class="link-light link-opacity-50-hover" target="_blank">
                                <p><span class=" me-2 text-danger">05.</span><span class="h3 font-bold">21K da Maratona Intl. de Floripa <img src="/assets/verified.png" class="<cfif '2026-08-29' GT now()>d-none</cfif> mb-1"></span><span class=" ms-2">29/08/2026</span></p>
                            </a>
                            <a href="/evento/2026-maratona-de-criciuma-2026/" class="link-light link-opacity-50-hover" target="_blank">
                                <p><span class=" me-2 text-danger">06.</span><span class="h3 font-bold">21K da Maratona de Criciúma <img src="/assets/verified.png" class="<cfif '2026-09-27' GT now()>d-none</cfif> mb-1"></span><span class=" ms-2">27/09/2026</span></p>
                            </a>
                        </div>

                    </div>

                    <hr class="text-light my-5">

                    <div class="text-center my-5 py-5">
                        <div class="row">
                            <!---<div class="col-sm-auto col-lg-2"></div>--->
                            <div class="col-sm-12 col-lg-6 text-center">
                                <h2 class="text-danger text-center display-3 font-bold">6 etapas</h2>
                                <p class="text-light text-center">O circuito será composto por 6 meias maratonas, todas com distância oficial de 21 km. Os
                                    atletas poderão descartar 1 etapa para o ranking final. Quem completar 5 ou mais etapas
                                    receberá uma mandala comemorativa oficial, entregue como participação especial.</p>
                                <p class="text-light text-center">Haverá premiação para os 5 primeiros colocados geral Masculino e Feminino, além de
                                    reconhecimento das 5 maiores assessorias esportivas inscritas.</p>
                                <!---<a class="btn btn-primary shadow-3 btn-rounded btn-lg" href="https://www.lastica.com.br/corre_supra_desafio" target="_blank">Saiba mais</a>--->
                                <a class="btn btn-danger shadow-3 btn-rounded btn-lg" href="./inscricao/">Inscreva-se agora</a>

                                <p class="text-centern small fw-lighter mt-5">Organizadores</p>
                                <img src="/circuitocatarinense/assets/images/orgs_corridaderua.png?2" class="d-flex my-3 mx-auto w-100">
                            </div>
                            <!---<div class="col-sm-auto col-lg-2"></div>--->

                            <div class="col-12 col-md-6 pt-5">
                                <h2 class="text-light text-center display-4 font-bold">Já somos</h2>

                                <cfquery name="qStats">
                                    select * from desafios
                                    where produto = <cfqueryparam cfsqltype="cf_sql_varchar" value="catarinensecorridaderua"/>
                                </cfquery>
                                <cfquery name="qImages">
                                    select * from desafios cna inner join tb_usuarios usr on usr.id = cna.id_usuario
                                    where produto = <cfqueryparam cfsqltype="cf_sql_varchar" value="catarinensecorridaderua"/> and strava_profile ilike '%https%'
                                    order by RANDOM()
                                </cfquery>
                                <cfquery name="qStatsCidades">
                                        select distinct upper(trim(unaccent(usr.cidade))) as cidade
                                        from desafios cna inner join tb_usuarios usr on usr.id = cna.id_usuario
                                        where produto = <cfqueryparam cfsqltype="cf_sql_varchar" value="catarinensecorridaderua"/>
                                </cfquery>

                                <div class="event-counter event-counter-2 py-10 py-xxl-20">
                                    <div class="row row-cols-2 gy-lg-0 gy-2 justify-content-between">
                                        <div class="col-5 text-end">
                                                <span class="text-danger display-2 font-bold"><cfoutput>#qStats.recordcount#</cfoutput></span>
                                                <h3 class="fw-extra-bold d-flex flex-column mb-0 font-regular"><span>inscritos</span></h3>
                                        </div>
                                        <div class="col-2 text-center align-content-center">
                                            <h3 class="fw-extra-bold d-flex flex-column mb-0 font-regular"><span>de</span></h3>
                                        </div>
                                        <div class="col-5 text-start">
                                                <span class="text-danger display-2 font-bold"><cfoutput>#qStatsCidades.recordcount#</cfoutput></span>
                                                <h3 class="fw-extra-bold d-flex flex-column mb-0 font-regular"><span>cidades</span></h3>
                                        </div>
                                    </div>
                                </div>

                                <div class="d-flex flex-row gap-3 align-items-lg-center">
                                    <div class="d-flex gap-3 py-5 align-items-center w-100 justify-content-center">
                                        <div class="author-image d-flex gap-0 ps-10">
                                            <cfoutput query="qImages" maxrows="1">
                                                <img class="border border-white border-2 rounded-circle w-50px bg-light" src="#qImages.strava_profile#" alt="img"onerror="this.src='/assets/user.png';" width="50" height="50">
                                            </cfoutput>
                                            <cfoutput query="qImages" startrow="2" maxrows="4">
                                                <img class="ms-n3 border border-white border-2 rounded-circle w-50px bg-light" src="#qImages.strava_profile#" alt="img"onerror="this.src='/assets/user.png';" width="50" height="50">
                                            </cfoutput>
                                            <div class="ms-n3 border border-white border-2 text-center rounded-circle w-50px align-content-center bg-danger">
                                                <h5 class="text-white fw-extra-bold mb-0">+<cfoutput>#qStats.recordcount-5#</cfoutput></h5>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <a class="btn btn-outline-danger shadow-3 btn-rounded" href="#ranking">Todos os participantes</a>

                            </div>

                        </div>
                    </div>

                    <hr class="text-light my-5">

                    <a id="ranking" class="position-absolute" style="margin-top:-120px;"></a>


                    <!--- RANKINGS --->

                    <h2 class="text-light text-center font-bold display-4"><i class="fa-solid fa-person-running text-danger"></i> RANKING FCA 2026</h2>

                    <div class="row justify-content-center">
                        <div class="col-12">
                            <div class="card border border-2 border-danger">
                                <div class="card-body">

                                <div class="row">

                                    <cfquery name="qRankingCatarina">
                                        WITH inscritos AS MATERIALIZED (
                                            SELECT DISTINCT id_usuario FROM desafios
                                            WHERE desafio = 'catarinensecorridaderua'
                                        ), resultados AS MATERIALIZED (
                                            SELECT res.id_usuario, res.id_evento, res.num_peito
                                            FROM tb_resultados res
                                            JOIN inscritos ON inscritos.id_usuario = res.id_usuario
                                            WHERE res.id_evento IN ('35612','35095','37004','37085','34529','37006')
                                              AND res.percurso = 21
                                        ), pontuacoes AS MATERIALIZED (
                                            SELECT res.id_usuario,
                                                sum(obs.obs::int) FILTER (WHERE res.id_evento = '35612') AS pontos_1,
                                                sum(obs.obs::int) FILTER (WHERE res.id_evento = '35095') AS pontos_2,
                                                sum(obs.obs::int) FILTER (WHERE res.id_evento = '37004') AS pontos_3,
                                                sum(obs.obs::int) FILTER (WHERE res.id_evento = '37085') AS pontos_4,
                                                sum(obs.obs::int) FILTER (WHERE res.id_evento = '34529') AS pontos_5,
                                                sum(obs.obs::int) FILTER (WHERE res.id_evento = '37006') AS pontos_6
                                            FROM tb_resultados_obs obs
                                            JOIN resultados res
                                              ON obs.id_evento = res.id_evento
                                             AND obs.num_peito = res.num_peito
                                            GROUP BY res.id_usuario
                                        )
                                        SELECT *,
                                               (pontos_1 + pontos_2 + pontos_3 + pontos_4 + pontos_5 + pontos_6) AS pontos,
                                               (CASE WHEN pontos_1 > 0 THEN 1 ELSE 0 END
                                                + CASE WHEN pontos_2 > 0 THEN 1 ELSE 0 END
                                                + CASE WHEN pontos_3 > 0 THEN 1 ELSE 0 END
                                                + CASE WHEN pontos_4 > 0 THEN 1 ELSE 0 END
                                                + CASE WHEN pontos_5 > 0 THEN 1 ELSE 0 END
                                                + CASE WHEN pontos_6 > 0 THEN 1 ELSE 0 END) AS participacoes,
                                               CASE WHEN pontos_1 > 0 THEN 1 ELSE 0 END AS participacoes_1,
                                               CASE WHEN pontos_2 > 0 THEN 1 ELSE 0 END AS participacoes_2,
                                               CASE WHEN pontos_3 > 0 THEN 1 ELSE 0 END AS participacoes_3,
                                               CASE WHEN pontos_4 > 0 THEN 1 ELSE 0 END AS participacoes_4,
                                               CASE WHEN pontos_5 > 0 THEN 1 ELSE 0 END AS participacoes_5,
                                               CASE WHEN pontos_6 > 0 THEN 1 ELSE 0 END AS participacoes_6
                                        FROM (
                                            SELECT
                                                upper(body ->> 'nome_completo') as nome_completo,
                                                (body ->> 'data_nascimento')::date as data_nascimento,

                                                Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(Replace(
                                                upper(unaccent(trim(body ->> 'equipe'))),
                                                'NAO TENHO',''),'NA',''),'NAO TEM',''),'AVULSO',''),
                                                'AVULSA',''),'SEM',''),'NENHUM',''),'INDIVIDUAL',''),'O TEM','') as equipe,

                                                upper(body ->> 'genero') as genero,
                                                pag.tag,
                                                pag.verificado,
                                                usr.is_admin,
                                                COALESCE(pag.cidade,usr.cidade) as cidade,
                                                COALESCE(pag.uf,usr.estado) as estado,

                                                COALESCE(
                                                    'https://roadrunners.run/assets/paginas/' || NULLIF(trim(pag.path_imagem), ''),
                                                    CASE WHEN trim(coalesce(usr.strava_profile, '')) ~* '^https?://' OR left(trim(coalesce(usr.strava_profile, '')), 1) = '/' THEN nullif(trim(usr.strava_profile), '') END,
                                                    CASE WHEN trim(coalesce(usr.imagem_usuario, '')) ~* '^https?://' OR left(trim(coalesce(usr.imagem_usuario, '')), 1) = '/' THEN nullif(trim(usr.imagem_usuario), '') END,
                                                    '/assets/user.png?'
                                                ) as imagem_usuario,

                                                COALESCE(score.pontos_1, 0) as pontos_1,

                                                COALESCE(score.pontos_2, 0) as pontos_2,

                                                COALESCE(score.pontos_3, 0) as pontos_3,

                                                COALESCE(score.pontos_4, 0) as pontos_4,

                                                COALESCE(score.pontos_5, 0) as pontos_5,

                                                COALESCE(score.pontos_6, 0) as pontos_6

                                            FROM desafios
                                            JOIN tb_usuarios usr ON usr.id = desafios.id_usuario
                                            LEFT JOIN tb_paginas pag
                                              ON pag.id_usuario_cadastro = usr.id
                                             AND pag.tag_prefix = 'atleta'
                                            LEFT JOIN pontuacoes score ON score.id_usuario = usr.id
                                            WHERE desafio = 'catarinensecorridaderua'
                                        ) t
                                        ORDER BY pontos DESC, data_nascimento ASC;
                                    </cfquery>
                                    <cfset REQUEST.normalizeDisplayQuery(qRankingCatarina, "nome_completo", "cidade")/>

                                    <cfquery name="qRankingCatarinaF" dbtype="query">
                                        SELECT * FROM qRankingCatarina
                                        where genero = 'FEMININO'
                                    </cfquery>

                                    <cfquery name="qRankingCatarinaM" dbtype="query">
                                        SELECT * FROM qRankingCatarina
                                        where genero = 'MASCULINO'
                                    </cfquery>

                                    <cfquery name="qRankingAssessoriaCatarina" dbtype="query">
                                        SELECT equipe,
                                               sum(participacoes) as pontos,
                                               sum(participacoes_1) as pontos_1,
                                               sum(participacoes_2) as pontos_2,
                                               sum(participacoes_3) as pontos_3,
                                               sum(participacoes_4) as pontos_4,
                                               sum(participacoes_5) as pontos_5,
                                               sum(participacoes_6) as pontos_6
                                        FROM qRankingCatarina
                                        WHERE pontos > 0 and equipe <> '' and equipe is not null
                                        AND equipe IN
                                            (
                                            'ALEM DO PACE',
                                            'CARLOS VENTURINI',
                                            'CPH',
                                            'DIORGIA BRESSAN',
                                            'EDUCATIVE RUNNERS',
                                            'ENDURANCE ON',
                                            'FORMACO',
                                            'FR - FLORIPA RUNNERS',
                                            'G3 RUNNERS',
                                            'GAMBOA SPORTS',
                                            'GD - GUILHERME DUTRA',
                                            'GPA - GUSTAVO PINTO',
                                            'IRON MIND',
                                            'JUST RUN',
                                            'LAP',
                                            'MOOVING',
                                            'MOOVING BODY',
                                            'MOVE ON',
                                            'NEW PACE',
                                            'PASSO A PASSO',
                                            'R2 - RICKEN',
                                            'RICARDO SARDÁ',
                                            'RN - RENATA NICOLAU',
                                            'STEADY',
                                            'TA',
                                            'TIME',
                                            'TREINE BEM',
                                            'TRIBO DO ESPORTE',
                                            'VIDA E SAUDE',
                                            'VIDATIVA',
                                            'VIVA BEM',
                                            'VL - VIVI LAMOUNIER'
                                            )
                                        GROUP BY equipe
                                        order by pontos DESC, equipe
                                    </cfquery>

                                    <div class="col-lg-6 p-0 px-lg-2">

                                    <h4 class="text-center">
                                        Feminino
                                    </h4>
                                    <table class="table table-hover mb-0">
                                        <thead>
                                        <tr>
                                            <th scope="col" class="small">Atleta</th>
                                            <th scope="col" class="small w-100px">Pontos</th>
                                        </tr>
                                        </thead>
                                    </table>
                                    <div class="table-responsive overflow-auto" style="max-height: 50vh;">
                                        <table class="table table-hover mb-0">
                                            <tbody>
                                            <cfset VARIABLES.posicao = 1/>
                                            <cfoutput query="qRankingCatarinaF">
                                            <tr>
                                                <th scope="row" class="h1 opacity-50 text-center w-50px font-bold">#VARIABLES.posicao#</th>
                                                <td class="text-center w-50px"><a href="/atleta/#qRankingCatarinaF.tag#/" target="_blank"><img src="#qRankingCatarinaF.imagem_usuario#"
                                                        onerror="this.onerror=null;this.src='/assets/user.png';"
                                                        class="rounded-circle object-cover border border-danger border-2"
                                                        height="32"
                                                        width="32"
                                                        loading="lazy"/></a></td>
                                                <td class="small"><a href="/atleta/#qRankingCatarinaF.tag#/" target="_blank">#qRankingCatarinaF.nome_completo#</a>
                                                <br/><small>#qRankingCatarinaF.cidade# - #qRankingCatarinaF.estado#</small>
                                                <br/><small>#qRankingCatarinaF.equipe#</small>
                                                </td>
                                                <td class="text-center w-100px">
                                                    <div class="row m-0">
                                                        <div class="col-12">#qRankingCatarinaF.pontos#</div>
                                                        <div class="col-2 xsmall text-nowrap p-0">#qRankingCatarinaF.pontos_1#</div>
                                                        <div class="col-2 xsmall text-nowrap p-0">#qRankingCatarinaF.pontos_2#</div>
                                                        <div class="col-2 xsmall text-nowrap p-0">#qRankingCatarinaF.pontos_3#</div>
                                                        <div class="col-2 xsmall text-nowrap p-0">#qRankingCatarinaF.pontos_4#</div>
                                                        <div class="col-2 xsmall text-nowrap p-0">#qRankingCatarinaF.pontos_5#</div>
                                                        <div class="col-2 xsmall text-nowrap p-0">#qRankingCatarinaF.pontos_6#</div>
                                                    </div>
                                                </td>
                                            </tr>
                                            <cfset VARIABLES.posicao = VARIABLES.posicao + 1/>
                                            </cfoutput>
                                            </tbody>
                                        </table>
                                    </div>

                                    </div>

                                    <div class="col-lg-6 p-0 px-lg-2">

                                    <hr class="d-sm-block d-lg-none my-4">

                                    <h4 class="text-center">
                                        Masculino
                                    </h4>
                                    <table class="table table-hover mb-0">
                                        <thead>
                                        <tr>
                                            <th scope="col" class="small">Atleta</th>
                                            <th scope="col" class="small w-100px">Pontos</th>
                                        </tr>
                                        </thead>
                                    </table>
                                    <div class="table-responsive overflow-auto" style="max-height: 50vh;">
                                        <table class="table table-hover mb-0 small">
                                            <tbody>
                                            <cfset VARIABLES.posicao = 1/>
                                            <cfoutput query="qRankingCatarinaM">
                                            <tr>
                                                <th scope="row" class="h1 opacity-50 text-center w-50px font-bold">#VARIABLES.posicao#</th>
                                                <td class="text-center w-50px"><a href="/atleta/#qRankingCatarinaM.tag#/" target="_blank"><img src="#qRankingCatarinaM.imagem_usuario#"
                                                        onerror="this.onerror=null;this.src='/assets/user.png';"
                                                        class="rounded-circle object-cover border border-danger border-2"
                                                        height="32"
                                                        width="32"
                                                        loading="lazy"/></a></td>
                                                <td class="small">
                                                    <a href="/atleta/#qRankingCatarinaM.tag#/" target="_blank">#qRankingCatarinaM.nome_completo#</a>
                                                    <cfif qRankingCatarinaM.verificado OR qRankingCatarinaM.is_admin>
                                                        <cfset VARIABLES.verificadoBadgeIsAdmin = qRankingCatarinaM.is_admin/>
                                                        <span class="d-inline-flex"><cfinclude template="/includes/verificado.cfm"/></span>
                                                    </cfif>
                                                    <br/><small>#qRankingCatarinaM.cidade# - #qRankingCatarinaM.estado#</small>
                                                    <br/><small>#qRankingCatarinaM.equipe#</small>
                                                </td>
                                                <td class="text-center w-100px">
                                                    <div class="row m-0">
                                                        <div class="col-12">#qRankingCatarinaM.pontos#</div>
                                                        <div class="col-2 xsmall text-nowrap p-0">#qRankingCatarinaM.pontos_1#</div>
                                                        <div class="col-2 xsmall text-nowrap p-0">#qRankingCatarinaM.pontos_2#</div>
                                                        <div class="col-2 xsmall text-nowrap p-0">#qRankingCatarinaM.pontos_3#</div>
                                                        <div class="col-2 xsmall text-nowrap p-0">#qRankingCatarinaM.pontos_4#</div>
                                                        <div class="col-2 xsmall text-nowrap p-0">#qRankingCatarinaM.pontos_5#</div>
                                                        <div class="col-2 xsmall text-nowrap p-0">#qRankingCatarinaM.pontos_6#</div>
                                                    </div>
                                                </td>
                                            </tr>
                                            <cfset VARIABLES.posicao = VARIABLES.posicao + 1/>
                                            </cfoutput>
                                            </tbody>
                                        </table>
                                    </div>

                                    </div>

                                </div>

                                <div class="text-center small mt-2"><small>Atletas por ordem de pontuação e critério de desempate.</small></div>

                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="text-center my-5">
                        <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="162" zoomAndPan="magnify" viewBox="0 0 121.5 24.749999" height="33" preserveAspectRatio="xMidYMid meet" version="1.0"><defs><g/><clipPath id="e093c4c24c"><path d="M 56.882812 2.371094 L 118 2.371094 L 118 21.960938 L 56.882812 21.960938 Z M 56.882812 2.371094 " clip-rule="nonzero"/></clipPath><clipPath id="22aebae550"><path d="M 60.59375 2.371094 L 114.28125 2.371094 C 116.332031 2.371094 117.996094 4.03125 117.996094 6.082031 L 117.996094 18.246094 C 117.996094 20.296875 116.332031 21.960938 114.28125 21.960938 L 60.59375 21.960938 C 58.542969 21.960938 56.882812 20.296875 56.882812 18.246094 L 56.882812 6.082031 C 56.882812 4.03125 58.542969 2.371094 60.59375 2.371094 Z M 60.59375 2.371094 " clip-rule="nonzero"/></clipPath><clipPath id="e5fc362095"><path d="M 0.882812 0.371094 L 62 0.371094 L 62 19.960938 L 0.882812 19.960938 Z M 0.882812 0.371094 " clip-rule="nonzero"/></clipPath><clipPath id="9e89cbbad4"><path d="M 4.59375 0.371094 L 58.28125 0.371094 C 60.332031 0.371094 61.996094 2.03125 61.996094 4.082031 L 61.996094 16.246094 C 61.996094 18.296875 60.332031 19.960938 58.28125 19.960938 L 4.59375 19.960938 C 2.542969 19.960938 0.882812 18.296875 0.882812 16.246094 L 0.882812 4.082031 C 0.882812 2.03125 2.542969 0.371094 4.59375 0.371094 Z M 4.59375 0.371094 " clip-rule="nonzero"/></clipPath><clipPath id="9e93e12c1c"><rect x="0" width="62" y="0" height="20"/></clipPath><clipPath id="7391b83ae2"><path d="M 56.886719 2.371094 L 117.765625 2.371094 L 117.765625 21.675781 L 56.886719 21.675781 Z M 56.886719 2.371094 " clip-rule="nonzero"/></clipPath><clipPath id="30fc39a0b6"><path d="M 60.597656 2.371094 L 114.269531 2.371094 C 116.320312 2.371094 117.980469 4.03125 117.980469 6.082031 L 117.980469 18.242188 C 117.980469 20.292969 116.320312 21.953125 114.269531 21.953125 L 60.597656 21.953125 C 58.546875 21.953125 56.886719 20.292969 56.886719 18.242188 L 56.886719 6.082031 C 56.886719 4.03125 58.546875 2.371094 60.597656 2.371094 Z M 60.597656 2.371094 " clip-rule="nonzero"/></clipPath><clipPath id="63850e096b"><path d="M 0.402344 1 L 7 1 L 7 8 L 0.402344 8 Z M 0.402344 1 " clip-rule="nonzero"/></clipPath><clipPath id="3007638956"><path d="M 31 1 L 36.519531 1 L 36.519531 8 L 31 8 Z M 31 1 " clip-rule="nonzero"/></clipPath><clipPath id="ac88b4c11d"><rect x="0" width="37" y="0" height="10"/></clipPath><clipPath id="0f0ab54dac"><path d="M 17 1 L 22.941406 1 L 22.941406 8 L 17 8 Z M 17 1 " clip-rule="nonzero"/></clipPath><clipPath id="bc52da2559"><rect x="0" width="23" y="0" height="10"/></clipPath><clipPath id="a1b24b0743"><path d="M 0.46875 1 L 5 1 L 5 15 L 0.46875 15 Z M 0.46875 1 " clip-rule="nonzero"/></clipPath><clipPath id="70d091ab23"><path d="M 3 1 L 7.597656 1 L 7.597656 15 L 3 15 Z M 3 1 " clip-rule="nonzero"/></clipPath><clipPath id="67eb4404ee"><rect x="0" width="8" y="0" height="16"/></clipPath><clipPath id="3d737aff31"><path d="M 44.210938 0 L 69.453125 0 L 69.453125 24.503906 L 44.210938 24.503906 Z M 44.210938 0 " clip-rule="nonzero"/></clipPath><clipPath id="933ed974eb"><path d="M 0.546875 1 L 5 1 L 5 7 L 0.546875 7 Z M 0.546875 1 " clip-rule="nonzero"/></clipPath><clipPath id="77fbe158ad"><path d="M 29 2 L 33 2 L 33 7.679688 L 29 7.679688 Z M 29 2 " clip-rule="nonzero"/></clipPath><clipPath id="9518586072"><rect x="0" width="42" y="0" height="8"/></clipPath></defs><g clip-path="url(#e093c4c24c)"><g clip-path="url(#22aebae550)"><g transform="matrix(1, 0, 0, 1, 56, 2)"><g clip-path="url(#9e93e12c1c)"><g clip-path="url(#e5fc362095)"><g clip-path="url(#9e89cbbad4)"><path fill="#ffffff" d="M 0.882812 0.371094 L 62.019531 0.371094 L 62.019531 19.960938 L 0.882812 19.960938 Z M 0.882812 0.371094 " fill-opacity="1" fill-rule="nonzero"/></g></g></g></g></g></g><g clip-path="url(#7391b83ae2)"><g clip-path="url(#30fc39a0b6)"><path stroke-linecap="butt" transform="matrix(0.7425, 0, 0, 0.7425, 56.886411, 2.370976)" fill="none" stroke-linejoin="miter" d="M 4.99831 0.000158566 L 77.28367 0.000158566 C 80.045665 0.000158566 82.281566 2.236059 82.281566 4.998055 L 82.281566 21.375371 C 82.281566 24.137366 80.045665 26.373267 77.28367 26.373267 L 4.99831 26.373267 C 2.236315 26.373267 0.000414305 24.137366 0.000414305 21.375371 L 0.000414305 4.998055 C 0.000414305 2.236059 2.236315 0.000158566 4.99831 0.000158566 Z M 4.99831 0.000158566 " stroke="#d9d9d9" stroke-width="2" stroke-opacity="1" stroke-miterlimit="4"/></g></g><g transform="matrix(1, 0, 0, 1, 71, 11)"><g clip-path="url(#ac88b4c11d)"><g clip-path="url(#63850e096b)"><g fill="#333333" fill-opacity="1"><g transform="translate(0.627271, 7.313161)"><g><path d="M 4.890625 -0.203125 C 4.898438 -0.171875 4.90625 -0.140625 4.90625 -0.109375 C 4.90625 -0.0351562 4.859375 0 4.765625 0 L 3.34375 0 C 3.289062 0 3.25 -0.0078125 3.21875 -0.03125 C 3.1875 -0.0625 3.164062 -0.113281 3.15625 -0.1875 L 2.71875 -2.078125 C 2.71875 -2.109375 2.707031 -2.128906 2.6875 -2.140625 C 2.675781 -2.148438 2.648438 -2.15625 2.609375 -2.15625 L 2.171875 -2.15625 C 2.140625 -2.15625 2.113281 -2.148438 2.09375 -2.140625 C 2.082031 -2.128906 2.070312 -2.109375 2.0625 -2.078125 L 1.796875 -0.171875 C 1.785156 -0.0976562 1.757812 -0.0507812 1.71875 -0.03125 C 1.6875 -0.0078125 1.625 0 1.53125 0 L 0.296875 0 C 0.171875 0 0.117188 -0.078125 0.140625 -0.234375 L 0.859375 -5.3125 C 0.859375 -5.363281 0.867188 -5.394531 0.890625 -5.40625 C 0.910156 -5.425781 0.941406 -5.4375 0.984375 -5.4375 L 3.421875 -5.4375 C 4.078125 -5.4375 4.582031 -5.3125 4.9375 -5.0625 C 5.300781 -4.820312 5.484375 -4.476562 5.484375 -4.03125 C 5.484375 -3.675781 5.378906 -3.347656 5.171875 -3.046875 C 4.960938 -2.742188 4.691406 -2.523438 4.359375 -2.390625 C 4.296875 -2.367188 4.257812 -2.347656 4.25 -2.328125 C 4.238281 -2.304688 4.238281 -2.28125 4.25 -2.25 Z M 3.0625 -3.25 C 3.257812 -3.25 3.425781 -3.316406 3.5625 -3.453125 C 3.695312 -3.585938 3.765625 -3.75 3.765625 -3.9375 C 3.765625 -4.070312 3.710938 -4.175781 3.609375 -4.25 C 3.503906 -4.320312 3.375 -4.359375 3.21875 -4.359375 L 2.484375 -4.359375 C 2.441406 -4.359375 2.410156 -4.347656 2.390625 -4.328125 C 2.378906 -4.304688 2.367188 -4.265625 2.359375 -4.203125 L 2.25 -3.359375 L 2.25 -3.328125 C 2.25 -3.296875 2.253906 -3.273438 2.265625 -3.265625 C 2.273438 -3.253906 2.296875 -3.25 2.328125 -3.25 Z M 3.0625 -3.25 "/></g></g></g></g><g fill="#333333" fill-opacity="1"><g transform="translate(6.041112, 7.313161)"><g><path d="M 0.859375 -5.3125 C 0.859375 -5.363281 0.867188 -5.394531 0.890625 -5.40625 C 0.910156 -5.425781 0.941406 -5.4375 0.984375 -5.4375 L 4.96875 -5.4375 C 5.039062 -5.4375 5.078125 -5.394531 5.078125 -5.3125 C 5.078125 -5.28125 5.078125 -5.253906 5.078125 -5.234375 L 4.953125 -4.390625 C 4.941406 -4.328125 4.921875 -4.285156 4.890625 -4.265625 C 4.867188 -4.242188 4.828125 -4.234375 4.765625 -4.234375 L 2.484375 -4.234375 C 2.441406 -4.234375 2.410156 -4.222656 2.390625 -4.203125 C 2.367188 -4.191406 2.359375 -4.160156 2.359375 -4.109375 L 2.25 -3.421875 L 2.25 -3.375 C 2.25 -3.351562 2.253906 -3.335938 2.265625 -3.328125 C 2.273438 -3.316406 2.300781 -3.3125 2.34375 -3.3125 L 3.71875 -3.3125 C 3.769531 -3.3125 3.800781 -3.300781 3.8125 -3.28125 C 3.832031 -3.269531 3.835938 -3.238281 3.828125 -3.1875 L 3.6875 -2.234375 C 3.6875 -2.191406 3.675781 -2.164062 3.65625 -2.15625 C 3.644531 -2.144531 3.617188 -2.140625 3.578125 -2.140625 L 2.15625 -2.140625 C 2.125 -2.140625 2.097656 -2.128906 2.078125 -2.109375 C 2.066406 -2.097656 2.054688 -2.066406 2.046875 -2.015625 L 1.953125 -1.296875 L 1.953125 -1.265625 C 1.953125 -1.222656 1.96875 -1.203125 2 -1.203125 L 4.4375 -1.203125 C 4.488281 -1.203125 4.519531 -1.191406 4.53125 -1.171875 C 4.550781 -1.148438 4.554688 -1.113281 4.546875 -1.0625 L 4.421875 -0.125 C 4.410156 -0.0703125 4.394531 -0.0351562 4.375 -0.015625 C 4.351562 -0.00390625 4.3125 0 4.25 0 L 0.3125 0 C 0.25 0 0.203125 -0.0078125 0.171875 -0.03125 C 0.140625 -0.0625 0.125 -0.101562 0.125 -0.15625 L 0.140625 -0.234375 Z M 0.859375 -5.3125 "/></g></g></g><g fill="#333333" fill-opacity="1"><g transform="translate(10.956793, 7.313161)"><g><path d="M 3.953125 -4.046875 C 3.691406 -4.265625 3.359375 -4.375 2.953125 -4.375 C 2.703125 -4.375 2.503906 -4.332031 2.359375 -4.25 C 2.210938 -4.175781 2.140625 -4.066406 2.140625 -3.921875 C 2.140625 -3.753906 2.289062 -3.628906 2.59375 -3.546875 L 3.765625 -3.15625 C 4.148438 -3.03125 4.4375 -2.863281 4.625 -2.65625 C 4.820312 -2.457031 4.921875 -2.203125 4.921875 -1.890625 C 4.921875 -1.484375 4.804688 -1.128906 4.578125 -0.828125 C 4.359375 -0.535156 4.050781 -0.3125 3.65625 -0.15625 C 3.269531 0 2.835938 0.078125 2.359375 0.078125 C 1.796875 0.078125 1.320312 -0.0078125 0.9375 -0.1875 C 0.550781 -0.375 0.269531 -0.628906 0.09375 -0.953125 C 0.0625 -1.023438 0.046875 -1.066406 0.046875 -1.078125 C 0.046875 -1.109375 0.0664062 -1.140625 0.109375 -1.171875 L 0.890625 -1.640625 C 0.929688 -1.660156 0.972656 -1.671875 1.015625 -1.671875 C 1.078125 -1.671875 1.140625 -1.632812 1.203125 -1.5625 C 1.335938 -1.414062 1.453125 -1.304688 1.546875 -1.234375 C 1.640625 -1.160156 1.757812 -1.101562 1.90625 -1.0625 C 2.050781 -1.019531 2.25 -1 2.5 -1 C 2.726562 -1 2.914062 -1.035156 3.0625 -1.109375 C 3.21875 -1.191406 3.296875 -1.320312 3.296875 -1.5 C 3.296875 -1.675781 3.144531 -1.804688 2.84375 -1.890625 L 1.765625 -2.21875 C 1.390625 -2.332031 1.097656 -2.507812 0.890625 -2.75 C 0.691406 -2.988281 0.59375 -3.269531 0.59375 -3.59375 C 0.59375 -3.96875 0.703125 -4.300781 0.921875 -4.59375 C 1.140625 -4.882812 1.429688 -5.109375 1.796875 -5.265625 C 2.171875 -5.429688 2.570312 -5.515625 3 -5.515625 C 3.457031 -5.515625 3.863281 -5.429688 4.21875 -5.265625 C 4.570312 -5.109375 4.835938 -4.914062 5.015625 -4.6875 C 5.054688 -4.632812 5.078125 -4.585938 5.078125 -4.546875 C 5.078125 -4.515625 5.054688 -4.488281 5.015625 -4.46875 L 4.171875 -3.921875 C 4.148438 -3.910156 4.125 -3.910156 4.09375 -3.921875 C 4.0625 -3.941406 4.03125 -3.960938 4 -3.984375 C 3.976562 -4.015625 3.960938 -4.035156 3.953125 -4.046875 Z M 3.953125 -4.046875 "/></g></g></g><g fill="#333333" fill-opacity="1"><g transform="translate(16.09225, 7.313161)"><g><path d="M 5.03125 -2.109375 C 4.914062 -1.304688 4.640625 -0.738281 4.203125 -0.40625 C 3.765625 -0.0820312 3.175781 0.078125 2.4375 0.078125 C 1.695312 0.078125 1.160156 -0.0703125 0.828125 -0.375 C 0.492188 -0.675781 0.328125 -1.125 0.328125 -1.71875 C 0.328125 -1.875 0.34375 -2.082031 0.375 -2.34375 L 0.796875 -5.3125 C 0.804688 -5.363281 0.816406 -5.394531 0.828125 -5.40625 C 0.847656 -5.425781 0.878906 -5.4375 0.921875 -5.4375 L 2.3125 -5.4375 C 2.351562 -5.4375 2.390625 -5.414062 2.421875 -5.375 C 2.453125 -5.332031 2.460938 -5.285156 2.453125 -5.234375 L 2.015625 -2.078125 C 1.992188 -1.921875 1.984375 -1.816406 1.984375 -1.765625 C 1.984375 -1.523438 2.035156 -1.351562 2.140625 -1.25 C 2.242188 -1.144531 2.398438 -1.09375 2.609375 -1.09375 C 2.878906 -1.09375 3.109375 -1.175781 3.296875 -1.34375 C 3.492188 -1.519531 3.617188 -1.800781 3.671875 -2.1875 L 4.125 -5.3125 C 4.125 -5.363281 4.128906 -5.394531 4.140625 -5.40625 C 4.160156 -5.425781 4.195312 -5.4375 4.25 -5.4375 L 5.34375 -5.4375 C 5.382812 -5.4375 5.414062 -5.414062 5.4375 -5.375 C 5.46875 -5.332031 5.476562 -5.285156 5.46875 -5.234375 Z M 5.03125 -2.109375 "/></g></g></g><g fill="#333333" fill-opacity="1"><g transform="translate(21.425507, 7.313161)"><g><path d="M 0.84375 -5.296875 C 0.851562 -5.347656 0.867188 -5.382812 0.890625 -5.40625 C 0.910156 -5.425781 0.941406 -5.4375 0.984375 -5.4375 L 2.421875 -5.4375 C 2.484375 -5.4375 2.515625 -5.394531 2.515625 -5.3125 C 2.515625 -5.28125 2.507812 -5.253906 2.5 -5.234375 L 1.953125 -1.328125 L 1.953125 -1.296875 C 1.953125 -1.234375 1.976562 -1.203125 2.03125 -1.203125 L 4.265625 -1.203125 C 4.347656 -1.203125 4.382812 -1.140625 4.375 -1.015625 L 4.25 -0.125 C 4.25 -0.0703125 4.234375 -0.0351562 4.203125 -0.015625 C 4.179688 -0.00390625 4.140625 0 4.078125 0 L 0.3125 0 C 0.1875 0 0.128906 -0.078125 0.140625 -0.234375 Z M 0.84375 -5.296875 "/></g></g></g><g fill="#333333" fill-opacity="1"><g transform="translate(26.136062, 7.313161)"><g><path d="M 0.6875 -5.3125 C 0.695312 -5.363281 0.710938 -5.394531 0.734375 -5.40625 C 0.753906 -5.425781 0.789062 -5.4375 0.84375 -5.4375 L 5.3125 -5.4375 C 5.363281 -5.4375 5.394531 -5.425781 5.40625 -5.40625 C 5.425781 -5.394531 5.429688 -5.363281 5.421875 -5.3125 L 5.296875 -4.359375 C 5.285156 -4.316406 5.269531 -4.285156 5.25 -4.265625 C 5.226562 -4.253906 5.191406 -4.25 5.140625 -4.25 L 3.84375 -4.25 C 3.800781 -4.25 3.769531 -4.242188 3.75 -4.234375 C 3.738281 -4.222656 3.726562 -4.191406 3.71875 -4.140625 L 3.15625 -0.140625 C 3.144531 -0.0859375 3.128906 -0.0507812 3.109375 -0.03125 C 3.085938 -0.0078125 3.054688 0 3.015625 0 L 1.640625 0 C 1.535156 0 1.484375 -0.0390625 1.484375 -0.125 C 1.484375 -0.144531 1.488281 -0.164062 1.5 -0.1875 L 2.0625 -4.171875 L 2.0625 -4.1875 C 2.0625 -4.226562 2.035156 -4.25 1.984375 -4.25 L 0.671875 -4.25 C 0.617188 -4.25 0.582031 -4.257812 0.5625 -4.28125 C 0.550781 -4.300781 0.546875 -4.332031 0.546875 -4.375 Z M 0.6875 -5.3125 "/></g></g></g><g clip-path="url(#3007638956)"><g fill="#333333" fill-opacity="1"><g transform="translate(31.293497, 7.313161)"><g><path d="M 3.953125 -4.046875 C 3.691406 -4.265625 3.359375 -4.375 2.953125 -4.375 C 2.703125 -4.375 2.503906 -4.332031 2.359375 -4.25 C 2.210938 -4.175781 2.140625 -4.066406 2.140625 -3.921875 C 2.140625 -3.753906 2.289062 -3.628906 2.59375 -3.546875 L 3.765625 -3.15625 C 4.148438 -3.03125 4.4375 -2.863281 4.625 -2.65625 C 4.820312 -2.457031 4.921875 -2.203125 4.921875 -1.890625 C 4.921875 -1.484375 4.804688 -1.128906 4.578125 -0.828125 C 4.359375 -0.535156 4.050781 -0.3125 3.65625 -0.15625 C 3.269531 0 2.835938 0.078125 2.359375 0.078125 C 1.796875 0.078125 1.320312 -0.0078125 0.9375 -0.1875 C 0.550781 -0.375 0.269531 -0.628906 0.09375 -0.953125 C 0.0625 -1.023438 0.046875 -1.066406 0.046875 -1.078125 C 0.046875 -1.109375 0.0664062 -1.140625 0.109375 -1.171875 L 0.890625 -1.640625 C 0.929688 -1.660156 0.972656 -1.671875 1.015625 -1.671875 C 1.078125 -1.671875 1.140625 -1.632812 1.203125 -1.5625 C 1.335938 -1.414062 1.453125 -1.304688 1.546875 -1.234375 C 1.640625 -1.160156 1.757812 -1.101562 1.90625 -1.0625 C 2.050781 -1.019531 2.25 -1 2.5 -1 C 2.726562 -1 2.914062 -1.035156 3.0625 -1.109375 C 3.21875 -1.191406 3.296875 -1.320312 3.296875 -1.5 C 3.296875 -1.675781 3.144531 -1.804688 2.84375 -1.890625 L 1.765625 -2.21875 C 1.390625 -2.332031 1.097656 -2.507812 0.890625 -2.75 C 0.691406 -2.988281 0.59375 -3.269531 0.59375 -3.59375 C 0.59375 -3.96875 0.703125 -4.300781 0.921875 -4.59375 C 1.140625 -4.882812 1.429688 -5.109375 1.796875 -5.265625 C 2.171875 -5.429688 2.570312 -5.515625 3 -5.515625 C 3.457031 -5.515625 3.863281 -5.429688 4.21875 -5.265625 C 4.570312 -5.109375 4.835938 -4.914062 5.015625 -4.6875 C 5.054688 -4.632812 5.078125 -4.585938 5.078125 -4.546875 C 5.078125 -4.515625 5.054688 -4.488281 5.015625 -4.46875 L 4.171875 -3.921875 C 4.148438 -3.910156 4.125 -3.910156 4.09375 -3.921875 C 4.0625 -3.941406 4.03125 -3.960938 4 -3.984375 C 3.976562 -4.015625 3.960938 -4.035156 3.953125 -4.046875 Z M 3.953125 -4.046875 "/></g></g></g></g></g></g><g transform="matrix(1, 0, 0, 1, 86, 4)"><g clip-path="url(#bc52da2559)"><g fill="#333333" fill-opacity="1"><g transform="translate(0.914943, 7.003765)"><g><path d="M 2.640625 0.078125 C 2.148438 0.078125 1.726562 -0.015625 1.375 -0.203125 C 1.03125 -0.390625 0.765625 -0.65625 0.578125 -1 C 0.398438 -1.351562 0.3125 -1.769531 0.3125 -2.25 C 0.3125 -2.445312 0.320312 -2.625 0.34375 -2.78125 C 0.425781 -3.332031 0.597656 -3.8125 0.859375 -4.21875 C 1.128906 -4.632812 1.472656 -4.953125 1.890625 -5.171875 C 2.316406 -5.398438 2.789062 -5.515625 3.3125 -5.515625 C 3.78125 -5.515625 4.1875 -5.414062 4.53125 -5.21875 C 4.882812 -5.03125 5.15625 -4.757812 5.34375 -4.40625 C 5.53125 -4.050781 5.625 -3.632812 5.625 -3.15625 C 5.625 -2.945312 5.609375 -2.769531 5.578125 -2.625 C 5.503906 -2.070312 5.332031 -1.59375 5.0625 -1.1875 C 4.800781 -0.789062 4.460938 -0.476562 4.046875 -0.25 C 3.628906 -0.03125 3.160156 0.078125 2.640625 0.078125 Z M 2.6875 -1.0625 C 3.019531 -1.0625 3.273438 -1.191406 3.453125 -1.453125 C 3.640625 -1.722656 3.773438 -2.160156 3.859375 -2.765625 C 3.898438 -3.054688 3.921875 -3.296875 3.921875 -3.484375 C 3.921875 -3.804688 3.867188 -4.035156 3.765625 -4.171875 C 3.660156 -4.304688 3.492188 -4.375 3.265625 -4.375 C 2.929688 -4.375 2.671875 -4.234375 2.484375 -3.953125 C 2.296875 -3.679688 2.15625 -3.226562 2.0625 -2.59375 C 2.03125 -2.3125 2.015625 -2.082031 2.015625 -1.90625 C 2.015625 -1.601562 2.066406 -1.382812 2.171875 -1.25 C 2.273438 -1.125 2.445312 -1.0625 2.6875 -1.0625 Z M 2.6875 -1.0625 "/></g></g></g><g fill="#333333" fill-opacity="1"><g transform="translate(6.629146, 7.003765)"><g><path d="M 2.15625 -1.953125 C 2.113281 -1.953125 2.082031 -1.941406 2.0625 -1.921875 C 2.039062 -1.898438 2.03125 -1.867188 2.03125 -1.828125 L 1.796875 -0.171875 C 1.785156 -0.0976562 1.765625 -0.0507812 1.734375 -0.03125 C 1.703125 -0.0078125 1.644531 0 1.5625 0 L 0.265625 0 C 0.210938 0 0.175781 -0.0078125 0.15625 -0.03125 C 0.132812 -0.0507812 0.125 -0.0820312 0.125 -0.125 C 0.125 -0.164062 0.128906 -0.203125 0.140625 -0.234375 L 0.859375 -5.3125 C 0.859375 -5.363281 0.867188 -5.394531 0.890625 -5.40625 C 0.910156 -5.425781 0.941406 -5.4375 0.984375 -5.4375 L 3.40625 -5.4375 C 3.78125 -5.4375 4.117188 -5.375 4.421875 -5.25 C 4.722656 -5.132812 4.960938 -4.957031 5.140625 -4.71875 C 5.316406 -4.488281 5.40625 -4.203125 5.40625 -3.859375 C 5.40625 -3.472656 5.304688 -3.132812 5.109375 -2.84375 C 4.921875 -2.550781 4.65625 -2.328125 4.3125 -2.171875 C 3.96875 -2.023438 3.585938 -1.953125 3.171875 -1.953125 Z M 3.71875 -3.859375 C 3.71875 -3.984375 3.671875 -4.082031 3.578125 -4.15625 C 3.484375 -4.226562 3.359375 -4.265625 3.203125 -4.265625 L 2.515625 -4.265625 C 2.460938 -4.265625 2.421875 -4.25 2.390625 -4.21875 C 2.367188 -4.195312 2.351562 -4.160156 2.34375 -4.109375 L 2.234375 -3.234375 L 2.21875 -3.1875 C 2.21875 -3.164062 2.222656 -3.148438 2.234375 -3.140625 C 2.253906 -3.128906 2.28125 -3.125 2.3125 -3.125 L 3.03125 -3.125 C 3.15625 -3.125 3.269531 -3.15625 3.375 -3.21875 C 3.476562 -3.289062 3.5625 -3.382812 3.625 -3.5 C 3.6875 -3.613281 3.71875 -3.734375 3.71875 -3.859375 Z M 3.71875 -3.859375 "/></g></g></g><g fill="#333333" fill-opacity="1"><g transform="translate(11.984381, 7.003765)"><g><path d="M 0.859375 -5.3125 C 0.859375 -5.363281 0.867188 -5.394531 0.890625 -5.40625 C 0.910156 -5.425781 0.941406 -5.4375 0.984375 -5.4375 L 4.96875 -5.4375 C 5.039062 -5.4375 5.078125 -5.394531 5.078125 -5.3125 C 5.078125 -5.28125 5.078125 -5.253906 5.078125 -5.234375 L 4.953125 -4.390625 C 4.941406 -4.328125 4.921875 -4.285156 4.890625 -4.265625 C 4.867188 -4.242188 4.828125 -4.234375 4.765625 -4.234375 L 2.484375 -4.234375 C 2.441406 -4.234375 2.410156 -4.222656 2.390625 -4.203125 C 2.367188 -4.191406 2.359375 -4.160156 2.359375 -4.109375 L 2.25 -3.421875 L 2.25 -3.375 C 2.25 -3.351562 2.253906 -3.335938 2.265625 -3.328125 C 2.273438 -3.316406 2.300781 -3.3125 2.34375 -3.3125 L 3.71875 -3.3125 C 3.769531 -3.3125 3.800781 -3.300781 3.8125 -3.28125 C 3.832031 -3.269531 3.835938 -3.238281 3.828125 -3.1875 L 3.6875 -2.234375 C 3.6875 -2.191406 3.675781 -2.164062 3.65625 -2.15625 C 3.644531 -2.144531 3.617188 -2.140625 3.578125 -2.140625 L 2.15625 -2.140625 C 2.125 -2.140625 2.097656 -2.128906 2.078125 -2.109375 C 2.066406 -2.097656 2.054688 -2.066406 2.046875 -2.015625 L 1.953125 -1.296875 L 1.953125 -1.265625 C 1.953125 -1.222656 1.96875 -1.203125 2 -1.203125 L 4.4375 -1.203125 C 4.488281 -1.203125 4.519531 -1.191406 4.53125 -1.171875 C 4.550781 -1.148438 4.554688 -1.113281 4.546875 -1.0625 L 4.421875 -0.125 C 4.410156 -0.0703125 4.394531 -0.0351562 4.375 -0.015625 C 4.351562 -0.00390625 4.3125 0 4.25 0 L 0.3125 0 C 0.25 0 0.203125 -0.0078125 0.171875 -0.03125 C 0.140625 -0.0625 0.125 -0.101562 0.125 -0.15625 L 0.140625 -0.234375 Z M 0.859375 -5.3125 "/></g></g></g><g clip-path="url(#0f0ab54dac)"><g fill="#333333" fill-opacity="1"><g transform="translate(16.900062, 7.003765)"><g><path d="M 5.578125 -5.4375 C 5.648438 -5.4375 5.679688 -5.394531 5.671875 -5.3125 L 4.9375 -0.09375 C 4.925781 -0.0507812 4.910156 -0.0234375 4.890625 -0.015625 C 4.867188 -0.00390625 4.832031 0 4.78125 0 L 3.78125 0 C 3.75 0 3.71875 -0.0078125 3.6875 -0.03125 C 3.664062 -0.0507812 3.640625 -0.0859375 3.609375 -0.140625 L 1.953125 -2.875 C 1.941406 -2.90625 1.925781 -2.921875 1.90625 -2.921875 C 1.882812 -2.921875 1.867188 -2.890625 1.859375 -2.828125 L 1.484375 -0.140625 C 1.472656 -0.078125 1.457031 -0.0351562 1.4375 -0.015625 C 1.414062 -0.00390625 1.367188 0 1.296875 0 L 0.25 0 C 0.15625 0 0.113281 -0.0625 0.125 -0.1875 L 0.859375 -5.3125 C 0.859375 -5.363281 0.867188 -5.394531 0.890625 -5.40625 C 0.910156 -5.425781 0.945312 -5.4375 1 -5.4375 L 2.203125 -5.4375 C 2.253906 -5.4375 2.296875 -5.421875 2.328125 -5.390625 C 2.359375 -5.367188 2.390625 -5.328125 2.421875 -5.265625 L 3.859375 -2.84375 C 3.878906 -2.800781 3.898438 -2.78125 3.921875 -2.78125 C 3.941406 -2.78125 3.957031 -2.785156 3.96875 -2.796875 C 3.976562 -2.816406 3.988281 -2.84375 4 -2.875 L 4.34375 -5.328125 C 4.34375 -5.378906 4.351562 -5.410156 4.375 -5.421875 C 4.394531 -5.429688 4.429688 -5.4375 4.484375 -5.4375 Z M 5.578125 -5.4375 "/></g></g></g></g></g></g><g transform="matrix(1, 0, 0, 1, 108, 4)"><g clip-path="url(#67eb4404ee)"><g clip-path="url(#a1b24b0743)"><g fill="#f4b120" fill-opacity="1"><g transform="translate(0.744995, 12.170075)"><g><path d="M 0.296875 2.09375 C 0.171875 2.09375 0.078125 2.046875 0.015625 1.953125 C -0.0351562 1.859375 -0.0507812 1.738281 -0.03125 1.59375 L 1.65625 -10.484375 C 1.675781 -10.597656 1.703125 -10.664062 1.734375 -10.6875 C 1.765625 -10.71875 1.84375 -10.734375 1.96875 -10.734375 L 3.140625 -10.734375 C 3.234375 -10.734375 3.304688 -10.695312 3.359375 -10.625 C 3.421875 -10.5625 3.445312 -10.492188 3.4375 -10.421875 L 1.703125 1.9375 C 1.691406 2.007812 1.671875 2.050781 1.640625 2.0625 C 1.617188 2.082031 1.566406 2.09375 1.484375 2.09375 Z M 0.296875 2.09375 "/></g></g></g></g><g clip-path="url(#70d091ab23)"><g fill="#f4b120" fill-opacity="1"><g transform="translate(3.848885, 12.170075)"><g><path d="M 0.296875 2.09375 C 0.171875 2.09375 0.078125 2.046875 0.015625 1.953125 C -0.0351562 1.859375 -0.0507812 1.738281 -0.03125 1.59375 L 1.65625 -10.484375 C 1.675781 -10.597656 1.703125 -10.664062 1.734375 -10.6875 C 1.765625 -10.71875 1.84375 -10.734375 1.96875 -10.734375 L 3.140625 -10.734375 C 3.234375 -10.734375 3.304688 -10.695312 3.359375 -10.625 C 3.421875 -10.5625 3.445312 -10.492188 3.4375 -10.421875 L 1.703125 1.9375 C 1.691406 2.007812 1.671875 2.050781 1.640625 2.0625 C 1.617188 2.082031 1.566406 2.09375 1.484375 2.09375 Z M 0.296875 2.09375 "/></g></g></g></g></g></g><g clip-path="url(#3d737aff31)"><path fill="#f4b120" d="M 57.40625 1.074219 L 59.742188 0.242188 C 60.417969 0.00390625 61.164062 0.246094 61.570312 0.835938 L 62.972656 2.882812 C 63.175781 3.179688 63.476562 3.398438 63.824219 3.503906 L 66.207031 4.203125 C 66.890625 4.40625 67.355469 5.042969 67.335938 5.757812 L 67.265625 8.238281 C 67.257812 8.601562 67.371094 8.953125 67.59375 9.242188 L 69.105469 11.207031 C 69.542969 11.773438 69.542969 12.5625 69.105469 13.128906 L 67.59375 15.09375 C 67.371094 15.382812 67.257812 15.734375 67.265625 16.097656 L 67.335938 18.578125 C 67.355469 19.292969 66.890625 19.929688 66.207031 20.132812 L 63.824219 20.832031 C 63.476562 20.9375 63.175781 21.15625 62.972656 21.453125 L 61.570312 23.5 C 61.164062 24.089844 60.417969 24.332031 59.742188 24.09375 L 57.40625 23.261719 C 57.0625 23.140625 56.691406 23.140625 56.351562 23.261719 L 54.011719 24.09375 C 53.339844 24.332031 52.589844 24.089844 52.1875 23.5 L 50.785156 21.453125 C 50.578125 21.15625 50.277344 20.9375 49.929688 20.832031 L 47.550781 20.132812 C 46.863281 19.929688 46.402344 19.292969 46.421875 18.578125 L 46.488281 16.097656 C 46.5 15.734375 46.382812 15.382812 46.164062 15.09375 L 44.648438 13.128906 C 44.214844 12.5625 44.214844 11.773438 44.648438 11.207031 L 46.164062 9.242188 C 46.382812 8.953125 46.5 8.601562 46.488281 8.238281 L 46.421875 5.757812 C 46.402344 5.042969 46.863281 4.40625 47.550781 4.203125 L 49.929688 3.503906 C 50.277344 3.398438 50.578125 3.179688 50.785156 2.882812 L 52.1875 0.835938 C 52.589844 0.246094 53.339844 0.00390625 54.011719 0.242188 L 56.351562 1.074219 C 56.691406 1.195312 57.0625 1.195312 57.40625 1.074219 " fill-opacity="1" fill-rule="nonzero"/></g><path fill="#ffffff" d="M 63.890625 8.46875 L 61.910156 6.488281 L 54.515625 13.886719 L 51.84375 11.21875 L 49.867188 13.199219 L 51.761719 15.09375 L 54.515625 17.84375 L 63.890625 8.46875 " fill-opacity="1" fill-rule="nonzero"/><g transform="matrix(1, 0, 0, 1, 1, 8)"><g clip-path="url(#9518586072)"><g clip-path="url(#933ed974eb)"><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(0.583643, 6.14539)"><g><path d="M 0.09375 0 C 0.0625 0 0.046875 -0.015625 0.046875 -0.046875 C 0.046875 -0.078125 0.0507812 -0.0976562 0.0625 -0.109375 L 2.203125 -4.328125 C 2.210938 -4.359375 2.226562 -4.378906 2.25 -4.390625 C 2.269531 -4.398438 2.296875 -4.40625 2.328125 -4.40625 L 2.796875 -4.40625 C 2.859375 -4.40625 2.894531 -4.375 2.90625 -4.3125 L 3.828125 -0.09375 L 3.84375 -0.0625 C 3.84375 -0.0195312 3.820312 0 3.78125 0 L 3.359375 0 C 3.304688 0 3.273438 -0.0234375 3.265625 -0.078125 L 3.015625 -1.21875 C 3.015625 -1.226562 3.007812 -1.238281 3 -1.25 C 2.988281 -1.257812 2.972656 -1.265625 2.953125 -1.265625 L 1.234375 -1.265625 C 1.203125 -1.265625 1.175781 -1.242188 1.15625 -1.203125 L 0.5625 -0.046875 C 0.550781 -0.0234375 0.539062 -0.0078125 0.53125 0 C 0.519531 0 0.5 0 0.46875 0 Z M 2.875 -1.703125 C 2.914062 -1.703125 2.929688 -1.726562 2.921875 -1.78125 L 2.484375 -3.734375 C 2.472656 -3.773438 2.460938 -3.796875 2.453125 -3.796875 C 2.429688 -3.796875 2.410156 -3.773438 2.390625 -3.734375 L 1.40625 -1.78125 C 1.382812 -1.757812 1.375 -1.738281 1.375 -1.71875 C 1.382812 -1.707031 1.398438 -1.703125 1.421875 -1.703125 Z M 2.875 -1.703125 "/></g></g></g></g><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(5.139653, 6.14539)"><g><path d="M 1.15625 0.0625 C 0.90625 0.0625 0.703125 -0.0078125 0.546875 -0.15625 C 0.390625 -0.300781 0.3125 -0.488281 0.3125 -0.71875 C 0.3125 -0.78125 0.3125 -0.828125 0.3125 -0.859375 L 0.625 -3.0625 C 0.632812 -3.101562 0.644531 -3.125 0.65625 -3.125 C 0.664062 -3.132812 0.6875 -3.140625 0.71875 -3.140625 L 1.046875 -3.140625 C 1.078125 -3.140625 1.097656 -3.128906 1.109375 -3.109375 C 1.117188 -3.097656 1.125 -3.078125 1.125 -3.046875 L 0.828125 -0.96875 C 0.816406 -0.90625 0.8125 -0.863281 0.8125 -0.84375 C 0.8125 -0.5 0.984375 -0.328125 1.328125 -0.328125 C 1.492188 -0.328125 1.660156 -0.375 1.828125 -0.46875 C 1.992188 -0.5625 2.175781 -0.691406 2.375 -0.859375 L 2.6875 -3.078125 C 2.695312 -3.109375 2.707031 -3.125 2.71875 -3.125 C 2.726562 -3.132812 2.75 -3.140625 2.78125 -3.140625 L 3.109375 -3.140625 C 3.140625 -3.140625 3.160156 -3.128906 3.171875 -3.109375 C 3.191406 -3.097656 3.195312 -3.078125 3.1875 -3.046875 L 2.765625 -0.0625 C 2.753906 -0.0390625 2.742188 -0.0234375 2.734375 -0.015625 C 2.734375 -0.00390625 2.722656 0 2.703125 0 L 2.359375 0 C 2.304688 0 2.285156 -0.0195312 2.296875 -0.0625 L 2.34375 -0.390625 L 2.34375 -0.421875 C 2.34375 -0.429688 2.335938 -0.4375 2.328125 -0.4375 C 2.316406 -0.4375 2.300781 -0.429688 2.28125 -0.421875 C 2.050781 -0.242188 1.847656 -0.117188 1.671875 -0.046875 C 1.492188 0.0234375 1.320312 0.0625 1.15625 0.0625 Z M 1.15625 0.0625 "/></g></g></g><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(8.816535, 6.14539)"><g><path d="M 2.484375 0 C 2.460938 0 2.441406 -0.00390625 2.421875 -0.015625 C 2.410156 -0.0351562 2.40625 -0.0546875 2.40625 -0.078125 L 2.4375 -0.34375 L 2.453125 -0.359375 C 2.453125 -0.378906 2.441406 -0.390625 2.421875 -0.390625 C 2.410156 -0.390625 2.394531 -0.375 2.375 -0.34375 C 2.238281 -0.238281 2.09375 -0.144531 1.9375 -0.0625 C 1.789062 0.0195312 1.609375 0.0625 1.390625 0.0625 C 1.046875 0.0625 0.769531 -0.046875 0.5625 -0.265625 C 0.351562 -0.484375 0.25 -0.789062 0.25 -1.1875 C 0.25 -1.519531 0.3125 -1.84375 0.4375 -2.15625 C 0.570312 -2.46875 0.765625 -2.71875 1.015625 -2.90625 C 1.265625 -3.101562 1.550781 -3.203125 1.875 -3.203125 C 2.0625 -3.203125 2.21875 -3.171875 2.34375 -3.109375 C 2.46875 -3.054688 2.578125 -2.976562 2.671875 -2.875 C 2.691406 -2.851562 2.710938 -2.84375 2.734375 -2.84375 C 2.753906 -2.84375 2.773438 -2.875 2.796875 -2.9375 L 2.984375 -4.34375 C 2.992188 -4.363281 3.003906 -4.378906 3.015625 -4.390625 C 3.023438 -4.398438 3.039062 -4.40625 3.0625 -4.40625 L 3.421875 -4.40625 C 3.460938 -4.40625 3.484375 -4.375 3.484375 -4.3125 L 2.890625 -0.078125 C 2.878906 -0.046875 2.867188 -0.0234375 2.859375 -0.015625 C 2.847656 -0.00390625 2.820312 0 2.78125 0 Z M 2.734375 -2.46875 C 2.628906 -2.59375 2.515625 -2.6875 2.390625 -2.75 C 2.265625 -2.8125 2.128906 -2.84375 1.984375 -2.84375 C 1.734375 -2.84375 1.515625 -2.757812 1.328125 -2.59375 C 1.140625 -2.425781 1 -2.21875 0.90625 -1.96875 C 0.8125 -1.71875 0.765625 -1.460938 0.765625 -1.203125 C 0.765625 -0.898438 0.835938 -0.671875 0.984375 -0.515625 C 1.128906 -0.367188 1.320312 -0.296875 1.5625 -0.296875 C 1.71875 -0.296875 1.863281 -0.332031 2 -0.40625 C 2.144531 -0.488281 2.265625 -0.585938 2.359375 -0.703125 C 2.453125 -0.816406 2.507812 -0.925781 2.53125 -1.03125 Z M 2.734375 -2.46875 "/></g></g></g><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(12.61222, 6.14539)"><g><path d="M 1.296875 -3.8125 C 1.285156 -3.769531 1.269531 -3.742188 1.25 -3.734375 C 1.238281 -3.722656 1.21875 -3.71875 1.1875 -3.71875 L 0.8125 -3.71875 C 0.757812 -3.71875 0.738281 -3.753906 0.75 -3.828125 L 0.828125 -4.3125 C 0.835938 -4.375 0.867188 -4.40625 0.921875 -4.40625 L 1.296875 -4.40625 C 1.328125 -4.40625 1.347656 -4.394531 1.359375 -4.375 C 1.367188 -4.351562 1.367188 -4.328125 1.359375 -4.296875 Z M 0.75 -0.078125 C 0.75 -0.046875 0.738281 -0.0234375 0.71875 -0.015625 C 0.707031 -0.00390625 0.679688 0 0.640625 0 L 0.34375 0 C 0.269531 0 0.238281 -0.03125 0.25 -0.09375 L 0.671875 -3.078125 C 0.671875 -3.109375 0.675781 -3.125 0.6875 -3.125 C 0.695312 -3.132812 0.710938 -3.140625 0.734375 -3.140625 L 1.109375 -3.140625 C 1.160156 -3.140625 1.179688 -3.113281 1.171875 -3.0625 Z M 0.75 -0.078125 "/></g></g></g><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(14.269492, 6.14539)"><g><path d="M 1.265625 0 C 0.828125 0 0.609375 -0.179688 0.609375 -0.546875 C 0.609375 -0.628906 0.613281 -0.695312 0.625 -0.75 L 0.90625 -2.71875 L 0.90625 -2.734375 C 0.90625 -2.765625 0.882812 -2.78125 0.84375 -2.78125 L 0.359375 -2.78125 C 0.328125 -2.78125 0.316406 -2.800781 0.328125 -2.84375 L 0.359375 -3.109375 C 0.359375 -3.117188 0.359375 -3.125 0.359375 -3.125 C 0.367188 -3.132812 0.382812 -3.140625 0.40625 -3.140625 L 0.921875 -3.140625 C 0.929688 -3.140625 0.941406 -3.144531 0.953125 -3.15625 C 0.960938 -3.175781 0.972656 -3.195312 0.984375 -3.21875 L 1.171875 -4.15625 C 1.179688 -4.195312 1.207031 -4.21875 1.25 -4.21875 L 1.5625 -4.21875 C 1.59375 -4.21875 1.609375 -4.1875 1.609375 -4.125 L 1.46875 -3.1875 C 1.46875 -3.15625 1.484375 -3.140625 1.515625 -3.140625 L 2.25 -3.140625 C 2.300781 -3.140625 2.328125 -3.125 2.328125 -3.09375 L 2.28125 -2.828125 C 2.28125 -2.804688 2.273438 -2.789062 2.265625 -2.78125 C 2.253906 -2.78125 2.238281 -2.78125 2.21875 -2.78125 L 1.46875 -2.78125 C 1.425781 -2.78125 1.398438 -2.753906 1.390625 -2.703125 L 1.140625 -0.828125 C 1.128906 -0.785156 1.125 -0.734375 1.125 -0.671875 C 1.125 -0.554688 1.144531 -0.476562 1.1875 -0.4375 C 1.238281 -0.394531 1.320312 -0.375 1.4375 -0.375 L 1.859375 -0.375 C 1.867188 -0.375 1.878906 -0.363281 1.890625 -0.34375 C 1.910156 -0.332031 1.921875 -0.316406 1.921875 -0.296875 L 1.875 -0.09375 C 1.875 -0.0507812 1.859375 -0.03125 1.828125 -0.03125 C 1.710938 -0.0078125 1.523438 0 1.265625 0 Z M 1.265625 0 "/></g></g></g><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(16.805885, 6.14539)"><g><path d="M 2.125 -0.375 C 1.800781 -0.0820312 1.429688 0.0625 1.015625 0.0625 C 0.734375 0.0625 0.515625 -0.00390625 0.359375 -0.140625 C 0.203125 -0.273438 0.125 -0.457031 0.125 -0.6875 C 0.125 -1.070312 0.285156 -1.359375 0.609375 -1.546875 C 0.941406 -1.734375 1.347656 -1.84375 1.828125 -1.875 L 2.296875 -1.90625 C 2.328125 -1.90625 2.351562 -1.914062 2.375 -1.9375 C 2.40625 -1.957031 2.421875 -1.976562 2.421875 -2 L 2.453125 -2.171875 C 2.453125 -2.234375 2.453125 -2.273438 2.453125 -2.296875 C 2.453125 -2.472656 2.394531 -2.609375 2.28125 -2.703125 C 2.175781 -2.796875 2.023438 -2.84375 1.828125 -2.84375 C 1.460938 -2.84375 1.148438 -2.679688 0.890625 -2.359375 C 0.878906 -2.347656 0.867188 -2.335938 0.859375 -2.328125 C 0.847656 -2.328125 0.832031 -2.332031 0.8125 -2.34375 L 0.5 -2.453125 C 0.476562 -2.460938 0.46875 -2.476562 0.46875 -2.5 C 0.46875 -2.519531 0.476562 -2.546875 0.5 -2.578125 C 0.644531 -2.773438 0.832031 -2.925781 1.0625 -3.03125 C 1.289062 -3.144531 1.554688 -3.203125 1.859375 -3.203125 C 2.210938 -3.203125 2.476562 -3.125 2.65625 -2.96875 C 2.84375 -2.820312 2.9375 -2.617188 2.9375 -2.359375 C 2.9375 -2.316406 2.929688 -2.253906 2.921875 -2.171875 L 2.640625 -0.078125 C 2.628906 -0.046875 2.617188 -0.0234375 2.609375 -0.015625 C 2.597656 -0.00390625 2.578125 0 2.546875 0 L 2.25 0 C 2.195312 0 2.171875 -0.03125 2.171875 -0.09375 L 2.203125 -0.375 C 2.203125 -0.40625 2.195312 -0.421875 2.1875 -0.421875 C 2.175781 -0.421875 2.15625 -0.40625 2.125 -0.375 Z M 2.34375 -1.53125 L 2.359375 -1.5625 C 2.359375 -1.59375 2.335938 -1.609375 2.296875 -1.609375 L 1.875 -1.5625 C 1.550781 -1.539062 1.257812 -1.46875 1 -1.34375 C 0.75 -1.226562 0.625 -1.035156 0.625 -0.765625 C 0.625 -0.617188 0.675781 -0.503906 0.78125 -0.421875 C 0.882812 -0.347656 1.023438 -0.3125 1.203125 -0.3125 C 1.335938 -0.3125 1.46875 -0.332031 1.59375 -0.375 C 1.71875 -0.425781 1.832031 -0.488281 1.9375 -0.5625 C 2.03125 -0.632812 2.109375 -0.710938 2.171875 -0.796875 C 2.242188 -0.878906 2.28125 -0.957031 2.28125 -1.03125 Z M 2.34375 -1.53125 "/></g></g></g><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(20.298629, 6.14539)"><g><path d="M 2.484375 0 C 2.460938 0 2.441406 -0.00390625 2.421875 -0.015625 C 2.410156 -0.0351562 2.40625 -0.0546875 2.40625 -0.078125 L 2.4375 -0.34375 L 2.453125 -0.359375 C 2.453125 -0.378906 2.441406 -0.390625 2.421875 -0.390625 C 2.410156 -0.390625 2.394531 -0.375 2.375 -0.34375 C 2.238281 -0.238281 2.09375 -0.144531 1.9375 -0.0625 C 1.789062 0.0195312 1.609375 0.0625 1.390625 0.0625 C 1.046875 0.0625 0.769531 -0.046875 0.5625 -0.265625 C 0.351562 -0.484375 0.25 -0.789062 0.25 -1.1875 C 0.25 -1.519531 0.3125 -1.84375 0.4375 -2.15625 C 0.570312 -2.46875 0.765625 -2.71875 1.015625 -2.90625 C 1.265625 -3.101562 1.550781 -3.203125 1.875 -3.203125 C 2.0625 -3.203125 2.21875 -3.171875 2.34375 -3.109375 C 2.46875 -3.054688 2.578125 -2.976562 2.671875 -2.875 C 2.691406 -2.851562 2.710938 -2.84375 2.734375 -2.84375 C 2.753906 -2.84375 2.773438 -2.875 2.796875 -2.9375 L 2.984375 -4.34375 C 2.992188 -4.363281 3.003906 -4.378906 3.015625 -4.390625 C 3.023438 -4.398438 3.039062 -4.40625 3.0625 -4.40625 L 3.421875 -4.40625 C 3.460938 -4.40625 3.484375 -4.375 3.484375 -4.3125 L 2.890625 -0.078125 C 2.878906 -0.046875 2.867188 -0.0234375 2.859375 -0.015625 C 2.847656 -0.00390625 2.820312 0 2.78125 0 Z M 2.734375 -2.46875 C 2.628906 -2.59375 2.515625 -2.6875 2.390625 -2.75 C 2.265625 -2.8125 2.128906 -2.84375 1.984375 -2.84375 C 1.734375 -2.84375 1.515625 -2.757812 1.328125 -2.59375 C 1.140625 -2.425781 1 -2.21875 0.90625 -1.96875 C 0.8125 -1.71875 0.765625 -1.460938 0.765625 -1.203125 C 0.765625 -0.898438 0.835938 -0.671875 0.984375 -0.515625 C 1.128906 -0.367188 1.320312 -0.296875 1.5625 -0.296875 C 1.71875 -0.296875 1.863281 -0.332031 2 -0.40625 C 2.144531 -0.488281 2.265625 -0.585938 2.359375 -0.703125 C 2.453125 -0.816406 2.507812 -0.925781 2.53125 -1.03125 Z M 2.734375 -2.46875 "/></g></g></g><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(24.094314, 6.14539)"><g><path d="M 1.5625 0.0625 C 1.164062 0.0625 0.847656 -0.0546875 0.609375 -0.296875 C 0.367188 -0.546875 0.25 -0.875 0.25 -1.28125 C 0.25 -1.644531 0.328125 -1.972656 0.484375 -2.265625 C 0.640625 -2.554688 0.847656 -2.785156 1.109375 -2.953125 C 1.378906 -3.117188 1.671875 -3.203125 1.984375 -3.203125 C 2.390625 -3.203125 2.707031 -3.078125 2.9375 -2.828125 C 3.175781 -2.578125 3.296875 -2.242188 3.296875 -1.828125 C 3.296875 -1.472656 3.21875 -1.148438 3.0625 -0.859375 C 2.914062 -0.578125 2.707031 -0.351562 2.4375 -0.1875 C 2.175781 -0.0195312 1.882812 0.0625 1.5625 0.0625 Z M 1.578125 -0.3125 C 1.816406 -0.3125 2.023438 -0.375 2.203125 -0.5 C 2.378906 -0.632812 2.519531 -0.820312 2.625 -1.0625 C 2.738281 -1.3125 2.796875 -1.59375 2.796875 -1.90625 C 2.796875 -2.195312 2.722656 -2.425781 2.578125 -2.59375 C 2.429688 -2.757812 2.234375 -2.84375 1.984375 -2.84375 C 1.753906 -2.84375 1.546875 -2.773438 1.359375 -2.640625 C 1.171875 -2.503906 1.023438 -2.3125 0.921875 -2.0625 C 0.816406 -1.820312 0.765625 -1.546875 0.765625 -1.234375 C 0.765625 -0.953125 0.832031 -0.726562 0.96875 -0.5625 C 1.113281 -0.394531 1.316406 -0.3125 1.578125 -0.3125 Z M 1.578125 -0.3125 "/></g></g></g><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(27.889998, 6.14539)"><g/></g></g><g clip-path="url(#77fbe158ad)"><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(29.404705, 6.14539)"><g><path d="M 0.171875 0.984375 C 0.117188 0.984375 0.0976562 0.953125 0.109375 0.890625 L 0.671875 -3.0625 C 0.671875 -3.101562 0.675781 -3.125 0.6875 -3.125 C 0.695312 -3.132812 0.722656 -3.140625 0.765625 -3.140625 L 1.078125 -3.140625 C 1.128906 -3.140625 1.15625 -3.113281 1.15625 -3.0625 L 1.109375 -2.8125 L 1.109375 -2.796875 C 1.109375 -2.773438 1.117188 -2.765625 1.140625 -2.765625 C 1.148438 -2.765625 1.171875 -2.78125 1.203125 -2.8125 C 1.210938 -2.820312 1.257812 -2.863281 1.34375 -2.9375 C 1.4375 -3.007812 1.554688 -3.070312 1.703125 -3.125 C 1.847656 -3.175781 2.003906 -3.203125 2.171875 -3.203125 C 2.503906 -3.203125 2.773438 -3.09375 2.984375 -2.875 C 3.191406 -2.664062 3.296875 -2.359375 3.296875 -1.953125 C 3.296875 -1.628906 3.234375 -1.3125 3.109375 -1 C 2.984375 -0.695312 2.800781 -0.441406 2.5625 -0.234375 C 2.320312 -0.0351562 2.03125 0.0625 1.6875 0.0625 C 1.507812 0.0625 1.351562 0.03125 1.21875 -0.03125 C 1.082031 -0.09375 0.96875 -0.171875 0.875 -0.265625 C 0.851562 -0.285156 0.835938 -0.296875 0.828125 -0.296875 C 0.796875 -0.296875 0.773438 -0.257812 0.765625 -0.1875 L 0.609375 0.921875 C 0.597656 0.941406 0.585938 0.957031 0.578125 0.96875 C 0.578125 0.976562 0.566406 0.984375 0.546875 0.984375 Z M 1.5625 -0.296875 C 1.820312 -0.296875 2.039062 -0.378906 2.21875 -0.546875 C 2.40625 -0.710938 2.546875 -0.921875 2.640625 -1.171875 C 2.734375 -1.429688 2.78125 -1.691406 2.78125 -1.953125 C 2.78125 -2.253906 2.707031 -2.476562 2.5625 -2.625 C 2.414062 -2.769531 2.226562 -2.84375 2 -2.84375 C 1.832031 -2.84375 1.675781 -2.804688 1.53125 -2.734375 C 1.394531 -2.660156 1.28125 -2.566406 1.1875 -2.453125 C 1.101562 -2.347656 1.054688 -2.242188 1.046875 -2.140625 L 0.828125 -0.6875 C 0.929688 -0.5625 1.039062 -0.460938 1.15625 -0.390625 C 1.28125 -0.328125 1.414062 -0.296875 1.5625 -0.296875 Z M 1.5625 -0.296875 "/></g></g></g></g><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(33.188509, 6.14539)"><g><path d="M 1.5625 0.0625 C 1.164062 0.0625 0.847656 -0.0546875 0.609375 -0.296875 C 0.367188 -0.546875 0.25 -0.875 0.25 -1.28125 C 0.25 -1.644531 0.328125 -1.972656 0.484375 -2.265625 C 0.640625 -2.554688 0.847656 -2.785156 1.109375 -2.953125 C 1.378906 -3.117188 1.671875 -3.203125 1.984375 -3.203125 C 2.390625 -3.203125 2.707031 -3.078125 2.9375 -2.828125 C 3.175781 -2.578125 3.296875 -2.242188 3.296875 -1.828125 C 3.296875 -1.472656 3.21875 -1.148438 3.0625 -0.859375 C 2.914062 -0.578125 2.707031 -0.351562 2.4375 -0.1875 C 2.175781 -0.0195312 1.882812 0.0625 1.5625 0.0625 Z M 1.578125 -0.3125 C 1.816406 -0.3125 2.023438 -0.375 2.203125 -0.5 C 2.378906 -0.632812 2.519531 -0.820312 2.625 -1.0625 C 2.738281 -1.3125 2.796875 -1.59375 2.796875 -1.90625 C 2.796875 -2.195312 2.722656 -2.425781 2.578125 -2.59375 C 2.429688 -2.757812 2.234375 -2.84375 1.984375 -2.84375 C 1.753906 -2.84375 1.546875 -2.773438 1.359375 -2.640625 C 1.171875 -2.503906 1.023438 -2.3125 0.921875 -2.0625 C 0.816406 -1.820312 0.765625 -1.546875 0.765625 -1.234375 C 0.765625 -0.953125 0.832031 -0.726562 0.96875 -0.5625 C 1.113281 -0.394531 1.316406 -0.3125 1.578125 -0.3125 Z M 1.578125 -0.3125 "/></g></g></g><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(36.984193, 6.14539)"><g><path d="M 0.328125 0 C 0.304688 0 0.285156 -0.00390625 0.265625 -0.015625 C 0.253906 -0.0351562 0.25 -0.0625 0.25 -0.09375 L 0.671875 -3.09375 C 0.671875 -3.113281 0.675781 -3.125 0.6875 -3.125 C 0.695312 -3.132812 0.710938 -3.140625 0.734375 -3.140625 L 1.078125 -3.140625 C 1.128906 -3.140625 1.148438 -3.113281 1.140625 -3.0625 L 1.09375 -2.71875 L 1.09375 -2.703125 C 1.09375 -2.679688 1.097656 -2.671875 1.109375 -2.671875 C 1.117188 -2.671875 1.132812 -2.679688 1.15625 -2.703125 C 1.488281 -3.035156 1.8125 -3.203125 2.125 -3.203125 C 2.269531 -3.203125 2.34375 -3.175781 2.34375 -3.125 L 2.296875 -2.78125 C 2.296875 -2.738281 2.28125 -2.722656 2.25 -2.734375 C 2.144531 -2.742188 2.054688 -2.75 1.984375 -2.75 C 1.867188 -2.75 1.738281 -2.710938 1.59375 -2.640625 C 1.445312 -2.566406 1.316406 -2.472656 1.203125 -2.359375 C 1.097656 -2.253906 1.035156 -2.144531 1.015625 -2.03125 L 0.75 -0.078125 C 0.75 -0.046875 0.738281 -0.0234375 0.71875 -0.015625 C 0.707031 -0.00390625 0.6875 0 0.65625 0 Z M 0.328125 0 "/></g></g></g><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(39.496832, 6.14539)"><g><path d="M 1.046875 -2.421875 C 1.035156 -2.390625 1.019531 -2.367188 1 -2.359375 C 0.988281 -2.347656 0.96875 -2.34375 0.9375 -2.34375 L 0.515625 -2.34375 C 0.484375 -2.34375 0.457031 -2.351562 0.4375 -2.375 C 0.425781 -2.394531 0.425781 -2.421875 0.4375 -2.453125 L 0.5 -2.953125 C 0.507812 -2.972656 0.515625 -2.988281 0.515625 -3 C 0.523438 -3.007812 0.539062 -3.015625 0.5625 -3.015625 L 1.046875 -3.015625 C 1.066406 -3.015625 1.082031 -3.003906 1.09375 -2.984375 C 1.101562 -2.972656 1.109375 -2.953125 1.109375 -2.921875 Z M 0.71875 -0.09375 C 0.707031 -0.0625 0.695312 -0.0390625 0.6875 -0.03125 C 0.675781 -0.0195312 0.644531 -0.015625 0.59375 -0.015625 L 0.1875 -0.015625 C 0.125 -0.015625 0.0976562 -0.0507812 0.109375 -0.125 L 0.171875 -0.625 C 0.179688 -0.644531 0.1875 -0.65625 0.1875 -0.65625 C 0.195312 -0.664062 0.210938 -0.671875 0.234375 -0.671875 L 0.71875 -0.671875 C 0.738281 -0.671875 0.753906 -0.664062 0.765625 -0.65625 C 0.785156 -0.644531 0.789062 -0.625 0.78125 -0.59375 Z M 0.71875 -0.09375 "/></g></g></g></g></g></svg>
                        <hr class="text-light my-5">
                    </div>



                    <!--- RANKINGS ASSESSORIAS --->

                    <h2 class="text-light text-center font-bold display-4"><i class="fa-solid fa-person-running text-danger"></i> RANKING EQUIPES FCA 2026</h2>

                    <div class="row justify-content-center">

                        <div class="col-lg-6">

                            <div class="card border border-2 border-danger">

                                <div class="card-body p-3">

                                    <div class="row">

                                        <div class="col p-0 px-lg-2">

                                            <table class="table table-hover mb-0">
                                                <thead>
                                                <tr>
                                                    <th scope="col" class="small">Assessoria</th>
                                                    <th scope="col" class="small w-100px">Participantes</th>
                                                </tr>
                                                </thead>
                                            </table>

                                            <div class="table-responsive overflow-auto" style="max-height: 50vh;">
                                                <table class="table table-hover mb-0">
                                                    <tbody>
                                                    <cfset VARIABLES.posicao = 1/>
                                                    <cfoutput query="qRankingAssessoriaCatarina">
                                                    <tr>
                                                        <th scope="row" class="h1 opacity-50 text-center w-50px font-bold">#VARIABLES.posicao#</th>
                                                        <td class="small">#qRankingAssessoriaCatarina.equipe#
                                                        </td>
                                                        <td class="text-center w-100px">
                                                            <div class="row m-0">
                                                                <div class="col-12">#qRankingAssessoriaCatarina.pontos#</div>
                                                                <div class="col-2 xsmall p-0 text-nowrap">#qRankingAssessoriaCatarina.pontos_1#</div>
                                                                <div class="col-2 xsmall p-0 text-nowrap">#qRankingAssessoriaCatarina.pontos_2#</div>
                                                                <div class="col-2 xsmall p-0 text-nowrap">#qRankingAssessoriaCatarina.pontos_3#</div>
                                                                <div class="col-2 xsmall p-0 text-nowrap">#qRankingAssessoriaCatarina.pontos_4#</div>
                                                                <div class="col-2 xsmall p-0 text-nowrap">#qRankingAssessoriaCatarina.pontos_5#</div>
                                                                <div class="col-2 xsmall p-0 text-nowrap">#qRankingAssessoriaCatarina.pontos_6#</div>
                                                            </div>
                                                        </td>
                                                    </tr>
                                                    <cfset VARIABLES.posicao = VARIABLES.posicao + 1/>
                                                    </cfoutput>
                                                    </tbody>
                                                </table>
                                            </div>

                                        </div>

                                    </div>

                                    <div class="text-center small mt-2"><small>Assessorias por ordem de pontuação e critério de desempate.</small></div>

                                </div>

                            </div>

                        </div>

                    </div>

                    <div class="text-center my-5">
                        <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="162" zoomAndPan="magnify" viewBox="0 0 121.5 24.749999" height="33" preserveAspectRatio="xMidYMid meet" version="1.0"><defs><g/><clipPath id="e093c4c24c"><path d="M 56.882812 2.371094 L 118 2.371094 L 118 21.960938 L 56.882812 21.960938 Z M 56.882812 2.371094 " clip-rule="nonzero"/></clipPath><clipPath id="22aebae550"><path d="M 60.59375 2.371094 L 114.28125 2.371094 C 116.332031 2.371094 117.996094 4.03125 117.996094 6.082031 L 117.996094 18.246094 C 117.996094 20.296875 116.332031 21.960938 114.28125 21.960938 L 60.59375 21.960938 C 58.542969 21.960938 56.882812 20.296875 56.882812 18.246094 L 56.882812 6.082031 C 56.882812 4.03125 58.542969 2.371094 60.59375 2.371094 Z M 60.59375 2.371094 " clip-rule="nonzero"/></clipPath><clipPath id="e5fc362095"><path d="M 0.882812 0.371094 L 62 0.371094 L 62 19.960938 L 0.882812 19.960938 Z M 0.882812 0.371094 " clip-rule="nonzero"/></clipPath><clipPath id="9e89cbbad4"><path d="M 4.59375 0.371094 L 58.28125 0.371094 C 60.332031 0.371094 61.996094 2.03125 61.996094 4.082031 L 61.996094 16.246094 C 61.996094 18.296875 60.332031 19.960938 58.28125 19.960938 L 4.59375 19.960938 C 2.542969 19.960938 0.882812 18.296875 0.882812 16.246094 L 0.882812 4.082031 C 0.882812 2.03125 2.542969 0.371094 4.59375 0.371094 Z M 4.59375 0.371094 " clip-rule="nonzero"/></clipPath><clipPath id="9e93e12c1c"><rect x="0" width="62" y="0" height="20"/></clipPath><clipPath id="7391b83ae2"><path d="M 56.886719 2.371094 L 117.765625 2.371094 L 117.765625 21.675781 L 56.886719 21.675781 Z M 56.886719 2.371094 " clip-rule="nonzero"/></clipPath><clipPath id="30fc39a0b6"><path d="M 60.597656 2.371094 L 114.269531 2.371094 C 116.320312 2.371094 117.980469 4.03125 117.980469 6.082031 L 117.980469 18.242188 C 117.980469 20.292969 116.320312 21.953125 114.269531 21.953125 L 60.597656 21.953125 C 58.546875 21.953125 56.886719 20.292969 56.886719 18.242188 L 56.886719 6.082031 C 56.886719 4.03125 58.546875 2.371094 60.597656 2.371094 Z M 60.597656 2.371094 " clip-rule="nonzero"/></clipPath><clipPath id="63850e096b"><path d="M 0.402344 1 L 7 1 L 7 8 L 0.402344 8 Z M 0.402344 1 " clip-rule="nonzero"/></clipPath><clipPath id="3007638956"><path d="M 31 1 L 36.519531 1 L 36.519531 8 L 31 8 Z M 31 1 " clip-rule="nonzero"/></clipPath><clipPath id="ac88b4c11d"><rect x="0" width="37" y="0" height="10"/></clipPath><clipPath id="0f0ab54dac"><path d="M 17 1 L 22.941406 1 L 22.941406 8 L 17 8 Z M 17 1 " clip-rule="nonzero"/></clipPath><clipPath id="bc52da2559"><rect x="0" width="23" y="0" height="10"/></clipPath><clipPath id="a1b24b0743"><path d="M 0.46875 1 L 5 1 L 5 15 L 0.46875 15 Z M 0.46875 1 " clip-rule="nonzero"/></clipPath><clipPath id="70d091ab23"><path d="M 3 1 L 7.597656 1 L 7.597656 15 L 3 15 Z M 3 1 " clip-rule="nonzero"/></clipPath><clipPath id="67eb4404ee"><rect x="0" width="8" y="0" height="16"/></clipPath><clipPath id="3d737aff31"><path d="M 44.210938 0 L 69.453125 0 L 69.453125 24.503906 L 44.210938 24.503906 Z M 44.210938 0 " clip-rule="nonzero"/></clipPath><clipPath id="933ed974eb"><path d="M 0.546875 1 L 5 1 L 5 7 L 0.546875 7 Z M 0.546875 1 " clip-rule="nonzero"/></clipPath><clipPath id="77fbe158ad"><path d="M 29 2 L 33 2 L 33 7.679688 L 29 7.679688 Z M 29 2 " clip-rule="nonzero"/></clipPath><clipPath id="9518586072"><rect x="0" width="42" y="0" height="8"/></clipPath></defs><g clip-path="url(#e093c4c24c)"><g clip-path="url(#22aebae550)"><g transform="matrix(1, 0, 0, 1, 56, 2)"><g clip-path="url(#9e93e12c1c)"><g clip-path="url(#e5fc362095)"><g clip-path="url(#9e89cbbad4)"><path fill="#ffffff" d="M 0.882812 0.371094 L 62.019531 0.371094 L 62.019531 19.960938 L 0.882812 19.960938 Z M 0.882812 0.371094 " fill-opacity="1" fill-rule="nonzero"/></g></g></g></g></g></g><g clip-path="url(#7391b83ae2)"><g clip-path="url(#30fc39a0b6)"><path stroke-linecap="butt" transform="matrix(0.7425, 0, 0, 0.7425, 56.886411, 2.370976)" fill="none" stroke-linejoin="miter" d="M 4.99831 0.000158566 L 77.28367 0.000158566 C 80.045665 0.000158566 82.281566 2.236059 82.281566 4.998055 L 82.281566 21.375371 C 82.281566 24.137366 80.045665 26.373267 77.28367 26.373267 L 4.99831 26.373267 C 2.236315 26.373267 0.000414305 24.137366 0.000414305 21.375371 L 0.000414305 4.998055 C 0.000414305 2.236059 2.236315 0.000158566 4.99831 0.000158566 Z M 4.99831 0.000158566 " stroke="#d9d9d9" stroke-width="2" stroke-opacity="1" stroke-miterlimit="4"/></g></g><g transform="matrix(1, 0, 0, 1, 71, 11)"><g clip-path="url(#ac88b4c11d)"><g clip-path="url(#63850e096b)"><g fill="#333333" fill-opacity="1"><g transform="translate(0.627271, 7.313161)"><g><path d="M 4.890625 -0.203125 C 4.898438 -0.171875 4.90625 -0.140625 4.90625 -0.109375 C 4.90625 -0.0351562 4.859375 0 4.765625 0 L 3.34375 0 C 3.289062 0 3.25 -0.0078125 3.21875 -0.03125 C 3.1875 -0.0625 3.164062 -0.113281 3.15625 -0.1875 L 2.71875 -2.078125 C 2.71875 -2.109375 2.707031 -2.128906 2.6875 -2.140625 C 2.675781 -2.148438 2.648438 -2.15625 2.609375 -2.15625 L 2.171875 -2.15625 C 2.140625 -2.15625 2.113281 -2.148438 2.09375 -2.140625 C 2.082031 -2.128906 2.070312 -2.109375 2.0625 -2.078125 L 1.796875 -0.171875 C 1.785156 -0.0976562 1.757812 -0.0507812 1.71875 -0.03125 C 1.6875 -0.0078125 1.625 0 1.53125 0 L 0.296875 0 C 0.171875 0 0.117188 -0.078125 0.140625 -0.234375 L 0.859375 -5.3125 C 0.859375 -5.363281 0.867188 -5.394531 0.890625 -5.40625 C 0.910156 -5.425781 0.941406 -5.4375 0.984375 -5.4375 L 3.421875 -5.4375 C 4.078125 -5.4375 4.582031 -5.3125 4.9375 -5.0625 C 5.300781 -4.820312 5.484375 -4.476562 5.484375 -4.03125 C 5.484375 -3.675781 5.378906 -3.347656 5.171875 -3.046875 C 4.960938 -2.742188 4.691406 -2.523438 4.359375 -2.390625 C 4.296875 -2.367188 4.257812 -2.347656 4.25 -2.328125 C 4.238281 -2.304688 4.238281 -2.28125 4.25 -2.25 Z M 3.0625 -3.25 C 3.257812 -3.25 3.425781 -3.316406 3.5625 -3.453125 C 3.695312 -3.585938 3.765625 -3.75 3.765625 -3.9375 C 3.765625 -4.070312 3.710938 -4.175781 3.609375 -4.25 C 3.503906 -4.320312 3.375 -4.359375 3.21875 -4.359375 L 2.484375 -4.359375 C 2.441406 -4.359375 2.410156 -4.347656 2.390625 -4.328125 C 2.378906 -4.304688 2.367188 -4.265625 2.359375 -4.203125 L 2.25 -3.359375 L 2.25 -3.328125 C 2.25 -3.296875 2.253906 -3.273438 2.265625 -3.265625 C 2.273438 -3.253906 2.296875 -3.25 2.328125 -3.25 Z M 3.0625 -3.25 "/></g></g></g></g><g fill="#333333" fill-opacity="1"><g transform="translate(6.041112, 7.313161)"><g><path d="M 0.859375 -5.3125 C 0.859375 -5.363281 0.867188 -5.394531 0.890625 -5.40625 C 0.910156 -5.425781 0.941406 -5.4375 0.984375 -5.4375 L 4.96875 -5.4375 C 5.039062 -5.4375 5.078125 -5.394531 5.078125 -5.3125 C 5.078125 -5.28125 5.078125 -5.253906 5.078125 -5.234375 L 4.953125 -4.390625 C 4.941406 -4.328125 4.921875 -4.285156 4.890625 -4.265625 C 4.867188 -4.242188 4.828125 -4.234375 4.765625 -4.234375 L 2.484375 -4.234375 C 2.441406 -4.234375 2.410156 -4.222656 2.390625 -4.203125 C 2.367188 -4.191406 2.359375 -4.160156 2.359375 -4.109375 L 2.25 -3.421875 L 2.25 -3.375 C 2.25 -3.351562 2.253906 -3.335938 2.265625 -3.328125 C 2.273438 -3.316406 2.300781 -3.3125 2.34375 -3.3125 L 3.71875 -3.3125 C 3.769531 -3.3125 3.800781 -3.300781 3.8125 -3.28125 C 3.832031 -3.269531 3.835938 -3.238281 3.828125 -3.1875 L 3.6875 -2.234375 C 3.6875 -2.191406 3.675781 -2.164062 3.65625 -2.15625 C 3.644531 -2.144531 3.617188 -2.140625 3.578125 -2.140625 L 2.15625 -2.140625 C 2.125 -2.140625 2.097656 -2.128906 2.078125 -2.109375 C 2.066406 -2.097656 2.054688 -2.066406 2.046875 -2.015625 L 1.953125 -1.296875 L 1.953125 -1.265625 C 1.953125 -1.222656 1.96875 -1.203125 2 -1.203125 L 4.4375 -1.203125 C 4.488281 -1.203125 4.519531 -1.191406 4.53125 -1.171875 C 4.550781 -1.148438 4.554688 -1.113281 4.546875 -1.0625 L 4.421875 -0.125 C 4.410156 -0.0703125 4.394531 -0.0351562 4.375 -0.015625 C 4.351562 -0.00390625 4.3125 0 4.25 0 L 0.3125 0 C 0.25 0 0.203125 -0.0078125 0.171875 -0.03125 C 0.140625 -0.0625 0.125 -0.101562 0.125 -0.15625 L 0.140625 -0.234375 Z M 0.859375 -5.3125 "/></g></g></g><g fill="#333333" fill-opacity="1"><g transform="translate(10.956793, 7.313161)"><g><path d="M 3.953125 -4.046875 C 3.691406 -4.265625 3.359375 -4.375 2.953125 -4.375 C 2.703125 -4.375 2.503906 -4.332031 2.359375 -4.25 C 2.210938 -4.175781 2.140625 -4.066406 2.140625 -3.921875 C 2.140625 -3.753906 2.289062 -3.628906 2.59375 -3.546875 L 3.765625 -3.15625 C 4.148438 -3.03125 4.4375 -2.863281 4.625 -2.65625 C 4.820312 -2.457031 4.921875 -2.203125 4.921875 -1.890625 C 4.921875 -1.484375 4.804688 -1.128906 4.578125 -0.828125 C 4.359375 -0.535156 4.050781 -0.3125 3.65625 -0.15625 C 3.269531 0 2.835938 0.078125 2.359375 0.078125 C 1.796875 0.078125 1.320312 -0.0078125 0.9375 -0.1875 C 0.550781 -0.375 0.269531 -0.628906 0.09375 -0.953125 C 0.0625 -1.023438 0.046875 -1.066406 0.046875 -1.078125 C 0.046875 -1.109375 0.0664062 -1.140625 0.109375 -1.171875 L 0.890625 -1.640625 C 0.929688 -1.660156 0.972656 -1.671875 1.015625 -1.671875 C 1.078125 -1.671875 1.140625 -1.632812 1.203125 -1.5625 C 1.335938 -1.414062 1.453125 -1.304688 1.546875 -1.234375 C 1.640625 -1.160156 1.757812 -1.101562 1.90625 -1.0625 C 2.050781 -1.019531 2.25 -1 2.5 -1 C 2.726562 -1 2.914062 -1.035156 3.0625 -1.109375 C 3.21875 -1.191406 3.296875 -1.320312 3.296875 -1.5 C 3.296875 -1.675781 3.144531 -1.804688 2.84375 -1.890625 L 1.765625 -2.21875 C 1.390625 -2.332031 1.097656 -2.507812 0.890625 -2.75 C 0.691406 -2.988281 0.59375 -3.269531 0.59375 -3.59375 C 0.59375 -3.96875 0.703125 -4.300781 0.921875 -4.59375 C 1.140625 -4.882812 1.429688 -5.109375 1.796875 -5.265625 C 2.171875 -5.429688 2.570312 -5.515625 3 -5.515625 C 3.457031 -5.515625 3.863281 -5.429688 4.21875 -5.265625 C 4.570312 -5.109375 4.835938 -4.914062 5.015625 -4.6875 C 5.054688 -4.632812 5.078125 -4.585938 5.078125 -4.546875 C 5.078125 -4.515625 5.054688 -4.488281 5.015625 -4.46875 L 4.171875 -3.921875 C 4.148438 -3.910156 4.125 -3.910156 4.09375 -3.921875 C 4.0625 -3.941406 4.03125 -3.960938 4 -3.984375 C 3.976562 -4.015625 3.960938 -4.035156 3.953125 -4.046875 Z M 3.953125 -4.046875 "/></g></g></g><g fill="#333333" fill-opacity="1"><g transform="translate(16.09225, 7.313161)"><g><path d="M 5.03125 -2.109375 C 4.914062 -1.304688 4.640625 -0.738281 4.203125 -0.40625 C 3.765625 -0.0820312 3.175781 0.078125 2.4375 0.078125 C 1.695312 0.078125 1.160156 -0.0703125 0.828125 -0.375 C 0.492188 -0.675781 0.328125 -1.125 0.328125 -1.71875 C 0.328125 -1.875 0.34375 -2.082031 0.375 -2.34375 L 0.796875 -5.3125 C 0.804688 -5.363281 0.816406 -5.394531 0.828125 -5.40625 C 0.847656 -5.425781 0.878906 -5.4375 0.921875 -5.4375 L 2.3125 -5.4375 C 2.351562 -5.4375 2.390625 -5.414062 2.421875 -5.375 C 2.453125 -5.332031 2.460938 -5.285156 2.453125 -5.234375 L 2.015625 -2.078125 C 1.992188 -1.921875 1.984375 -1.816406 1.984375 -1.765625 C 1.984375 -1.523438 2.035156 -1.351562 2.140625 -1.25 C 2.242188 -1.144531 2.398438 -1.09375 2.609375 -1.09375 C 2.878906 -1.09375 3.109375 -1.175781 3.296875 -1.34375 C 3.492188 -1.519531 3.617188 -1.800781 3.671875 -2.1875 L 4.125 -5.3125 C 4.125 -5.363281 4.128906 -5.394531 4.140625 -5.40625 C 4.160156 -5.425781 4.195312 -5.4375 4.25 -5.4375 L 5.34375 -5.4375 C 5.382812 -5.4375 5.414062 -5.414062 5.4375 -5.375 C 5.46875 -5.332031 5.476562 -5.285156 5.46875 -5.234375 Z M 5.03125 -2.109375 "/></g></g></g><g fill="#333333" fill-opacity="1"><g transform="translate(21.425507, 7.313161)"><g><path d="M 0.84375 -5.296875 C 0.851562 -5.347656 0.867188 -5.382812 0.890625 -5.40625 C 0.910156 -5.425781 0.941406 -5.4375 0.984375 -5.4375 L 2.421875 -5.4375 C 2.484375 -5.4375 2.515625 -5.394531 2.515625 -5.3125 C 2.515625 -5.28125 2.507812 -5.253906 2.5 -5.234375 L 1.953125 -1.328125 L 1.953125 -1.296875 C 1.953125 -1.234375 1.976562 -1.203125 2.03125 -1.203125 L 4.265625 -1.203125 C 4.347656 -1.203125 4.382812 -1.140625 4.375 -1.015625 L 4.25 -0.125 C 4.25 -0.0703125 4.234375 -0.0351562 4.203125 -0.015625 C 4.179688 -0.00390625 4.140625 0 4.078125 0 L 0.3125 0 C 0.1875 0 0.128906 -0.078125 0.140625 -0.234375 Z M 0.84375 -5.296875 "/></g></g></g><g fill="#333333" fill-opacity="1"><g transform="translate(26.136062, 7.313161)"><g><path d="M 0.6875 -5.3125 C 0.695312 -5.363281 0.710938 -5.394531 0.734375 -5.40625 C 0.753906 -5.425781 0.789062 -5.4375 0.84375 -5.4375 L 5.3125 -5.4375 C 5.363281 -5.4375 5.394531 -5.425781 5.40625 -5.40625 C 5.425781 -5.394531 5.429688 -5.363281 5.421875 -5.3125 L 5.296875 -4.359375 C 5.285156 -4.316406 5.269531 -4.285156 5.25 -4.265625 C 5.226562 -4.253906 5.191406 -4.25 5.140625 -4.25 L 3.84375 -4.25 C 3.800781 -4.25 3.769531 -4.242188 3.75 -4.234375 C 3.738281 -4.222656 3.726562 -4.191406 3.71875 -4.140625 L 3.15625 -0.140625 C 3.144531 -0.0859375 3.128906 -0.0507812 3.109375 -0.03125 C 3.085938 -0.0078125 3.054688 0 3.015625 0 L 1.640625 0 C 1.535156 0 1.484375 -0.0390625 1.484375 -0.125 C 1.484375 -0.144531 1.488281 -0.164062 1.5 -0.1875 L 2.0625 -4.171875 L 2.0625 -4.1875 C 2.0625 -4.226562 2.035156 -4.25 1.984375 -4.25 L 0.671875 -4.25 C 0.617188 -4.25 0.582031 -4.257812 0.5625 -4.28125 C 0.550781 -4.300781 0.546875 -4.332031 0.546875 -4.375 Z M 0.6875 -5.3125 "/></g></g></g><g clip-path="url(#3007638956)"><g fill="#333333" fill-opacity="1"><g transform="translate(31.293497, 7.313161)"><g><path d="M 3.953125 -4.046875 C 3.691406 -4.265625 3.359375 -4.375 2.953125 -4.375 C 2.703125 -4.375 2.503906 -4.332031 2.359375 -4.25 C 2.210938 -4.175781 2.140625 -4.066406 2.140625 -3.921875 C 2.140625 -3.753906 2.289062 -3.628906 2.59375 -3.546875 L 3.765625 -3.15625 C 4.148438 -3.03125 4.4375 -2.863281 4.625 -2.65625 C 4.820312 -2.457031 4.921875 -2.203125 4.921875 -1.890625 C 4.921875 -1.484375 4.804688 -1.128906 4.578125 -0.828125 C 4.359375 -0.535156 4.050781 -0.3125 3.65625 -0.15625 C 3.269531 0 2.835938 0.078125 2.359375 0.078125 C 1.796875 0.078125 1.320312 -0.0078125 0.9375 -0.1875 C 0.550781 -0.375 0.269531 -0.628906 0.09375 -0.953125 C 0.0625 -1.023438 0.046875 -1.066406 0.046875 -1.078125 C 0.046875 -1.109375 0.0664062 -1.140625 0.109375 -1.171875 L 0.890625 -1.640625 C 0.929688 -1.660156 0.972656 -1.671875 1.015625 -1.671875 C 1.078125 -1.671875 1.140625 -1.632812 1.203125 -1.5625 C 1.335938 -1.414062 1.453125 -1.304688 1.546875 -1.234375 C 1.640625 -1.160156 1.757812 -1.101562 1.90625 -1.0625 C 2.050781 -1.019531 2.25 -1 2.5 -1 C 2.726562 -1 2.914062 -1.035156 3.0625 -1.109375 C 3.21875 -1.191406 3.296875 -1.320312 3.296875 -1.5 C 3.296875 -1.675781 3.144531 -1.804688 2.84375 -1.890625 L 1.765625 -2.21875 C 1.390625 -2.332031 1.097656 -2.507812 0.890625 -2.75 C 0.691406 -2.988281 0.59375 -3.269531 0.59375 -3.59375 C 0.59375 -3.96875 0.703125 -4.300781 0.921875 -4.59375 C 1.140625 -4.882812 1.429688 -5.109375 1.796875 -5.265625 C 2.171875 -5.429688 2.570312 -5.515625 3 -5.515625 C 3.457031 -5.515625 3.863281 -5.429688 4.21875 -5.265625 C 4.570312 -5.109375 4.835938 -4.914062 5.015625 -4.6875 C 5.054688 -4.632812 5.078125 -4.585938 5.078125 -4.546875 C 5.078125 -4.515625 5.054688 -4.488281 5.015625 -4.46875 L 4.171875 -3.921875 C 4.148438 -3.910156 4.125 -3.910156 4.09375 -3.921875 C 4.0625 -3.941406 4.03125 -3.960938 4 -3.984375 C 3.976562 -4.015625 3.960938 -4.035156 3.953125 -4.046875 Z M 3.953125 -4.046875 "/></g></g></g></g></g></g><g transform="matrix(1, 0, 0, 1, 86, 4)"><g clip-path="url(#bc52da2559)"><g fill="#333333" fill-opacity="1"><g transform="translate(0.914943, 7.003765)"><g><path d="M 2.640625 0.078125 C 2.148438 0.078125 1.726562 -0.015625 1.375 -0.203125 C 1.03125 -0.390625 0.765625 -0.65625 0.578125 -1 C 0.398438 -1.351562 0.3125 -1.769531 0.3125 -2.25 C 0.3125 -2.445312 0.320312 -2.625 0.34375 -2.78125 C 0.425781 -3.332031 0.597656 -3.8125 0.859375 -4.21875 C 1.128906 -4.632812 1.472656 -4.953125 1.890625 -5.171875 C 2.316406 -5.398438 2.789062 -5.515625 3.3125 -5.515625 C 3.78125 -5.515625 4.1875 -5.414062 4.53125 -5.21875 C 4.882812 -5.03125 5.15625 -4.757812 5.34375 -4.40625 C 5.53125 -4.050781 5.625 -3.632812 5.625 -3.15625 C 5.625 -2.945312 5.609375 -2.769531 5.578125 -2.625 C 5.503906 -2.070312 5.332031 -1.59375 5.0625 -1.1875 C 4.800781 -0.789062 4.460938 -0.476562 4.046875 -0.25 C 3.628906 -0.03125 3.160156 0.078125 2.640625 0.078125 Z M 2.6875 -1.0625 C 3.019531 -1.0625 3.273438 -1.191406 3.453125 -1.453125 C 3.640625 -1.722656 3.773438 -2.160156 3.859375 -2.765625 C 3.898438 -3.054688 3.921875 -3.296875 3.921875 -3.484375 C 3.921875 -3.804688 3.867188 -4.035156 3.765625 -4.171875 C 3.660156 -4.304688 3.492188 -4.375 3.265625 -4.375 C 2.929688 -4.375 2.671875 -4.234375 2.484375 -3.953125 C 2.296875 -3.679688 2.15625 -3.226562 2.0625 -2.59375 C 2.03125 -2.3125 2.015625 -2.082031 2.015625 -1.90625 C 2.015625 -1.601562 2.066406 -1.382812 2.171875 -1.25 C 2.273438 -1.125 2.445312 -1.0625 2.6875 -1.0625 Z M 2.6875 -1.0625 "/></g></g></g><g fill="#333333" fill-opacity="1"><g transform="translate(6.629146, 7.003765)"><g><path d="M 2.15625 -1.953125 C 2.113281 -1.953125 2.082031 -1.941406 2.0625 -1.921875 C 2.039062 -1.898438 2.03125 -1.867188 2.03125 -1.828125 L 1.796875 -0.171875 C 1.785156 -0.0976562 1.765625 -0.0507812 1.734375 -0.03125 C 1.703125 -0.0078125 1.644531 0 1.5625 0 L 0.265625 0 C 0.210938 0 0.175781 -0.0078125 0.15625 -0.03125 C 0.132812 -0.0507812 0.125 -0.0820312 0.125 -0.125 C 0.125 -0.164062 0.128906 -0.203125 0.140625 -0.234375 L 0.859375 -5.3125 C 0.859375 -5.363281 0.867188 -5.394531 0.890625 -5.40625 C 0.910156 -5.425781 0.941406 -5.4375 0.984375 -5.4375 L 3.40625 -5.4375 C 3.78125 -5.4375 4.117188 -5.375 4.421875 -5.25 C 4.722656 -5.132812 4.960938 -4.957031 5.140625 -4.71875 C 5.316406 -4.488281 5.40625 -4.203125 5.40625 -3.859375 C 5.40625 -3.472656 5.304688 -3.132812 5.109375 -2.84375 C 4.921875 -2.550781 4.65625 -2.328125 4.3125 -2.171875 C 3.96875 -2.023438 3.585938 -1.953125 3.171875 -1.953125 Z M 3.71875 -3.859375 C 3.71875 -3.984375 3.671875 -4.082031 3.578125 -4.15625 C 3.484375 -4.226562 3.359375 -4.265625 3.203125 -4.265625 L 2.515625 -4.265625 C 2.460938 -4.265625 2.421875 -4.25 2.390625 -4.21875 C 2.367188 -4.195312 2.351562 -4.160156 2.34375 -4.109375 L 2.234375 -3.234375 L 2.21875 -3.1875 C 2.21875 -3.164062 2.222656 -3.148438 2.234375 -3.140625 C 2.253906 -3.128906 2.28125 -3.125 2.3125 -3.125 L 3.03125 -3.125 C 3.15625 -3.125 3.269531 -3.15625 3.375 -3.21875 C 3.476562 -3.289062 3.5625 -3.382812 3.625 -3.5 C 3.6875 -3.613281 3.71875 -3.734375 3.71875 -3.859375 Z M 3.71875 -3.859375 "/></g></g></g><g fill="#333333" fill-opacity="1"><g transform="translate(11.984381, 7.003765)"><g><path d="M 0.859375 -5.3125 C 0.859375 -5.363281 0.867188 -5.394531 0.890625 -5.40625 C 0.910156 -5.425781 0.941406 -5.4375 0.984375 -5.4375 L 4.96875 -5.4375 C 5.039062 -5.4375 5.078125 -5.394531 5.078125 -5.3125 C 5.078125 -5.28125 5.078125 -5.253906 5.078125 -5.234375 L 4.953125 -4.390625 C 4.941406 -4.328125 4.921875 -4.285156 4.890625 -4.265625 C 4.867188 -4.242188 4.828125 -4.234375 4.765625 -4.234375 L 2.484375 -4.234375 C 2.441406 -4.234375 2.410156 -4.222656 2.390625 -4.203125 C 2.367188 -4.191406 2.359375 -4.160156 2.359375 -4.109375 L 2.25 -3.421875 L 2.25 -3.375 C 2.25 -3.351562 2.253906 -3.335938 2.265625 -3.328125 C 2.273438 -3.316406 2.300781 -3.3125 2.34375 -3.3125 L 3.71875 -3.3125 C 3.769531 -3.3125 3.800781 -3.300781 3.8125 -3.28125 C 3.832031 -3.269531 3.835938 -3.238281 3.828125 -3.1875 L 3.6875 -2.234375 C 3.6875 -2.191406 3.675781 -2.164062 3.65625 -2.15625 C 3.644531 -2.144531 3.617188 -2.140625 3.578125 -2.140625 L 2.15625 -2.140625 C 2.125 -2.140625 2.097656 -2.128906 2.078125 -2.109375 C 2.066406 -2.097656 2.054688 -2.066406 2.046875 -2.015625 L 1.953125 -1.296875 L 1.953125 -1.265625 C 1.953125 -1.222656 1.96875 -1.203125 2 -1.203125 L 4.4375 -1.203125 C 4.488281 -1.203125 4.519531 -1.191406 4.53125 -1.171875 C 4.550781 -1.148438 4.554688 -1.113281 4.546875 -1.0625 L 4.421875 -0.125 C 4.410156 -0.0703125 4.394531 -0.0351562 4.375 -0.015625 C 4.351562 -0.00390625 4.3125 0 4.25 0 L 0.3125 0 C 0.25 0 0.203125 -0.0078125 0.171875 -0.03125 C 0.140625 -0.0625 0.125 -0.101562 0.125 -0.15625 L 0.140625 -0.234375 Z M 0.859375 -5.3125 "/></g></g></g><g clip-path="url(#0f0ab54dac)"><g fill="#333333" fill-opacity="1"><g transform="translate(16.900062, 7.003765)"><g><path d="M 5.578125 -5.4375 C 5.648438 -5.4375 5.679688 -5.394531 5.671875 -5.3125 L 4.9375 -0.09375 C 4.925781 -0.0507812 4.910156 -0.0234375 4.890625 -0.015625 C 4.867188 -0.00390625 4.832031 0 4.78125 0 L 3.78125 0 C 3.75 0 3.71875 -0.0078125 3.6875 -0.03125 C 3.664062 -0.0507812 3.640625 -0.0859375 3.609375 -0.140625 L 1.953125 -2.875 C 1.941406 -2.90625 1.925781 -2.921875 1.90625 -2.921875 C 1.882812 -2.921875 1.867188 -2.890625 1.859375 -2.828125 L 1.484375 -0.140625 C 1.472656 -0.078125 1.457031 -0.0351562 1.4375 -0.015625 C 1.414062 -0.00390625 1.367188 0 1.296875 0 L 0.25 0 C 0.15625 0 0.113281 -0.0625 0.125 -0.1875 L 0.859375 -5.3125 C 0.859375 -5.363281 0.867188 -5.394531 0.890625 -5.40625 C 0.910156 -5.425781 0.945312 -5.4375 1 -5.4375 L 2.203125 -5.4375 C 2.253906 -5.4375 2.296875 -5.421875 2.328125 -5.390625 C 2.359375 -5.367188 2.390625 -5.328125 2.421875 -5.265625 L 3.859375 -2.84375 C 3.878906 -2.800781 3.898438 -2.78125 3.921875 -2.78125 C 3.941406 -2.78125 3.957031 -2.785156 3.96875 -2.796875 C 3.976562 -2.816406 3.988281 -2.84375 4 -2.875 L 4.34375 -5.328125 C 4.34375 -5.378906 4.351562 -5.410156 4.375 -5.421875 C 4.394531 -5.429688 4.429688 -5.4375 4.484375 -5.4375 Z M 5.578125 -5.4375 "/></g></g></g></g></g></g><g transform="matrix(1, 0, 0, 1, 108, 4)"><g clip-path="url(#67eb4404ee)"><g clip-path="url(#a1b24b0743)"><g fill="#f4b120" fill-opacity="1"><g transform="translate(0.744995, 12.170075)"><g><path d="M 0.296875 2.09375 C 0.171875 2.09375 0.078125 2.046875 0.015625 1.953125 C -0.0351562 1.859375 -0.0507812 1.738281 -0.03125 1.59375 L 1.65625 -10.484375 C 1.675781 -10.597656 1.703125 -10.664062 1.734375 -10.6875 C 1.765625 -10.71875 1.84375 -10.734375 1.96875 -10.734375 L 3.140625 -10.734375 C 3.234375 -10.734375 3.304688 -10.695312 3.359375 -10.625 C 3.421875 -10.5625 3.445312 -10.492188 3.4375 -10.421875 L 1.703125 1.9375 C 1.691406 2.007812 1.671875 2.050781 1.640625 2.0625 C 1.617188 2.082031 1.566406 2.09375 1.484375 2.09375 Z M 0.296875 2.09375 "/></g></g></g></g><g clip-path="url(#70d091ab23)"><g fill="#f4b120" fill-opacity="1"><g transform="translate(3.848885, 12.170075)"><g><path d="M 0.296875 2.09375 C 0.171875 2.09375 0.078125 2.046875 0.015625 1.953125 C -0.0351562 1.859375 -0.0507812 1.738281 -0.03125 1.59375 L 1.65625 -10.484375 C 1.675781 -10.597656 1.703125 -10.664062 1.734375 -10.6875 C 1.765625 -10.71875 1.84375 -10.734375 1.96875 -10.734375 L 3.140625 -10.734375 C 3.234375 -10.734375 3.304688 -10.695312 3.359375 -10.625 C 3.421875 -10.5625 3.445312 -10.492188 3.4375 -10.421875 L 1.703125 1.9375 C 1.691406 2.007812 1.671875 2.050781 1.640625 2.0625 C 1.617188 2.082031 1.566406 2.09375 1.484375 2.09375 Z M 0.296875 2.09375 "/></g></g></g></g></g></g><g clip-path="url(#3d737aff31)"><path fill="#f4b120" d="M 57.40625 1.074219 L 59.742188 0.242188 C 60.417969 0.00390625 61.164062 0.246094 61.570312 0.835938 L 62.972656 2.882812 C 63.175781 3.179688 63.476562 3.398438 63.824219 3.503906 L 66.207031 4.203125 C 66.890625 4.40625 67.355469 5.042969 67.335938 5.757812 L 67.265625 8.238281 C 67.257812 8.601562 67.371094 8.953125 67.59375 9.242188 L 69.105469 11.207031 C 69.542969 11.773438 69.542969 12.5625 69.105469 13.128906 L 67.59375 15.09375 C 67.371094 15.382812 67.257812 15.734375 67.265625 16.097656 L 67.335938 18.578125 C 67.355469 19.292969 66.890625 19.929688 66.207031 20.132812 L 63.824219 20.832031 C 63.476562 20.9375 63.175781 21.15625 62.972656 21.453125 L 61.570312 23.5 C 61.164062 24.089844 60.417969 24.332031 59.742188 24.09375 L 57.40625 23.261719 C 57.0625 23.140625 56.691406 23.140625 56.351562 23.261719 L 54.011719 24.09375 C 53.339844 24.332031 52.589844 24.089844 52.1875 23.5 L 50.785156 21.453125 C 50.578125 21.15625 50.277344 20.9375 49.929688 20.832031 L 47.550781 20.132812 C 46.863281 19.929688 46.402344 19.292969 46.421875 18.578125 L 46.488281 16.097656 C 46.5 15.734375 46.382812 15.382812 46.164062 15.09375 L 44.648438 13.128906 C 44.214844 12.5625 44.214844 11.773438 44.648438 11.207031 L 46.164062 9.242188 C 46.382812 8.953125 46.5 8.601562 46.488281 8.238281 L 46.421875 5.757812 C 46.402344 5.042969 46.863281 4.40625 47.550781 4.203125 L 49.929688 3.503906 C 50.277344 3.398438 50.578125 3.179688 50.785156 2.882812 L 52.1875 0.835938 C 52.589844 0.246094 53.339844 0.00390625 54.011719 0.242188 L 56.351562 1.074219 C 56.691406 1.195312 57.0625 1.195312 57.40625 1.074219 " fill-opacity="1" fill-rule="nonzero"/></g><path fill="#ffffff" d="M 63.890625 8.46875 L 61.910156 6.488281 L 54.515625 13.886719 L 51.84375 11.21875 L 49.867188 13.199219 L 51.761719 15.09375 L 54.515625 17.84375 L 63.890625 8.46875 " fill-opacity="1" fill-rule="nonzero"/><g transform="matrix(1, 0, 0, 1, 1, 8)"><g clip-path="url(#9518586072)"><g clip-path="url(#933ed974eb)"><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(0.583643, 6.14539)"><g><path d="M 0.09375 0 C 0.0625 0 0.046875 -0.015625 0.046875 -0.046875 C 0.046875 -0.078125 0.0507812 -0.0976562 0.0625 -0.109375 L 2.203125 -4.328125 C 2.210938 -4.359375 2.226562 -4.378906 2.25 -4.390625 C 2.269531 -4.398438 2.296875 -4.40625 2.328125 -4.40625 L 2.796875 -4.40625 C 2.859375 -4.40625 2.894531 -4.375 2.90625 -4.3125 L 3.828125 -0.09375 L 3.84375 -0.0625 C 3.84375 -0.0195312 3.820312 0 3.78125 0 L 3.359375 0 C 3.304688 0 3.273438 -0.0234375 3.265625 -0.078125 L 3.015625 -1.21875 C 3.015625 -1.226562 3.007812 -1.238281 3 -1.25 C 2.988281 -1.257812 2.972656 -1.265625 2.953125 -1.265625 L 1.234375 -1.265625 C 1.203125 -1.265625 1.175781 -1.242188 1.15625 -1.203125 L 0.5625 -0.046875 C 0.550781 -0.0234375 0.539062 -0.0078125 0.53125 0 C 0.519531 0 0.5 0 0.46875 0 Z M 2.875 -1.703125 C 2.914062 -1.703125 2.929688 -1.726562 2.921875 -1.78125 L 2.484375 -3.734375 C 2.472656 -3.773438 2.460938 -3.796875 2.453125 -3.796875 C 2.429688 -3.796875 2.410156 -3.773438 2.390625 -3.734375 L 1.40625 -1.78125 C 1.382812 -1.757812 1.375 -1.738281 1.375 -1.71875 C 1.382812 -1.707031 1.398438 -1.703125 1.421875 -1.703125 Z M 2.875 -1.703125 "/></g></g></g></g><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(5.139653, 6.14539)"><g><path d="M 1.15625 0.0625 C 0.90625 0.0625 0.703125 -0.0078125 0.546875 -0.15625 C 0.390625 -0.300781 0.3125 -0.488281 0.3125 -0.71875 C 0.3125 -0.78125 0.3125 -0.828125 0.3125 -0.859375 L 0.625 -3.0625 C 0.632812 -3.101562 0.644531 -3.125 0.65625 -3.125 C 0.664062 -3.132812 0.6875 -3.140625 0.71875 -3.140625 L 1.046875 -3.140625 C 1.078125 -3.140625 1.097656 -3.128906 1.109375 -3.109375 C 1.117188 -3.097656 1.125 -3.078125 1.125 -3.046875 L 0.828125 -0.96875 C 0.816406 -0.90625 0.8125 -0.863281 0.8125 -0.84375 C 0.8125 -0.5 0.984375 -0.328125 1.328125 -0.328125 C 1.492188 -0.328125 1.660156 -0.375 1.828125 -0.46875 C 1.992188 -0.5625 2.175781 -0.691406 2.375 -0.859375 L 2.6875 -3.078125 C 2.695312 -3.109375 2.707031 -3.125 2.71875 -3.125 C 2.726562 -3.132812 2.75 -3.140625 2.78125 -3.140625 L 3.109375 -3.140625 C 3.140625 -3.140625 3.160156 -3.128906 3.171875 -3.109375 C 3.191406 -3.097656 3.195312 -3.078125 3.1875 -3.046875 L 2.765625 -0.0625 C 2.753906 -0.0390625 2.742188 -0.0234375 2.734375 -0.015625 C 2.734375 -0.00390625 2.722656 0 2.703125 0 L 2.359375 0 C 2.304688 0 2.285156 -0.0195312 2.296875 -0.0625 L 2.34375 -0.390625 L 2.34375 -0.421875 C 2.34375 -0.429688 2.335938 -0.4375 2.328125 -0.4375 C 2.316406 -0.4375 2.300781 -0.429688 2.28125 -0.421875 C 2.050781 -0.242188 1.847656 -0.117188 1.671875 -0.046875 C 1.492188 0.0234375 1.320312 0.0625 1.15625 0.0625 Z M 1.15625 0.0625 "/></g></g></g><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(8.816535, 6.14539)"><g><path d="M 2.484375 0 C 2.460938 0 2.441406 -0.00390625 2.421875 -0.015625 C 2.410156 -0.0351562 2.40625 -0.0546875 2.40625 -0.078125 L 2.4375 -0.34375 L 2.453125 -0.359375 C 2.453125 -0.378906 2.441406 -0.390625 2.421875 -0.390625 C 2.410156 -0.390625 2.394531 -0.375 2.375 -0.34375 C 2.238281 -0.238281 2.09375 -0.144531 1.9375 -0.0625 C 1.789062 0.0195312 1.609375 0.0625 1.390625 0.0625 C 1.046875 0.0625 0.769531 -0.046875 0.5625 -0.265625 C 0.351562 -0.484375 0.25 -0.789062 0.25 -1.1875 C 0.25 -1.519531 0.3125 -1.84375 0.4375 -2.15625 C 0.570312 -2.46875 0.765625 -2.71875 1.015625 -2.90625 C 1.265625 -3.101562 1.550781 -3.203125 1.875 -3.203125 C 2.0625 -3.203125 2.21875 -3.171875 2.34375 -3.109375 C 2.46875 -3.054688 2.578125 -2.976562 2.671875 -2.875 C 2.691406 -2.851562 2.710938 -2.84375 2.734375 -2.84375 C 2.753906 -2.84375 2.773438 -2.875 2.796875 -2.9375 L 2.984375 -4.34375 C 2.992188 -4.363281 3.003906 -4.378906 3.015625 -4.390625 C 3.023438 -4.398438 3.039062 -4.40625 3.0625 -4.40625 L 3.421875 -4.40625 C 3.460938 -4.40625 3.484375 -4.375 3.484375 -4.3125 L 2.890625 -0.078125 C 2.878906 -0.046875 2.867188 -0.0234375 2.859375 -0.015625 C 2.847656 -0.00390625 2.820312 0 2.78125 0 Z M 2.734375 -2.46875 C 2.628906 -2.59375 2.515625 -2.6875 2.390625 -2.75 C 2.265625 -2.8125 2.128906 -2.84375 1.984375 -2.84375 C 1.734375 -2.84375 1.515625 -2.757812 1.328125 -2.59375 C 1.140625 -2.425781 1 -2.21875 0.90625 -1.96875 C 0.8125 -1.71875 0.765625 -1.460938 0.765625 -1.203125 C 0.765625 -0.898438 0.835938 -0.671875 0.984375 -0.515625 C 1.128906 -0.367188 1.320312 -0.296875 1.5625 -0.296875 C 1.71875 -0.296875 1.863281 -0.332031 2 -0.40625 C 2.144531 -0.488281 2.265625 -0.585938 2.359375 -0.703125 C 2.453125 -0.816406 2.507812 -0.925781 2.53125 -1.03125 Z M 2.734375 -2.46875 "/></g></g></g><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(12.61222, 6.14539)"><g><path d="M 1.296875 -3.8125 C 1.285156 -3.769531 1.269531 -3.742188 1.25 -3.734375 C 1.238281 -3.722656 1.21875 -3.71875 1.1875 -3.71875 L 0.8125 -3.71875 C 0.757812 -3.71875 0.738281 -3.753906 0.75 -3.828125 L 0.828125 -4.3125 C 0.835938 -4.375 0.867188 -4.40625 0.921875 -4.40625 L 1.296875 -4.40625 C 1.328125 -4.40625 1.347656 -4.394531 1.359375 -4.375 C 1.367188 -4.351562 1.367188 -4.328125 1.359375 -4.296875 Z M 0.75 -0.078125 C 0.75 -0.046875 0.738281 -0.0234375 0.71875 -0.015625 C 0.707031 -0.00390625 0.679688 0 0.640625 0 L 0.34375 0 C 0.269531 0 0.238281 -0.03125 0.25 -0.09375 L 0.671875 -3.078125 C 0.671875 -3.109375 0.675781 -3.125 0.6875 -3.125 C 0.695312 -3.132812 0.710938 -3.140625 0.734375 -3.140625 L 1.109375 -3.140625 C 1.160156 -3.140625 1.179688 -3.113281 1.171875 -3.0625 Z M 0.75 -0.078125 "/></g></g></g><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(14.269492, 6.14539)"><g><path d="M 1.265625 0 C 0.828125 0 0.609375 -0.179688 0.609375 -0.546875 C 0.609375 -0.628906 0.613281 -0.695312 0.625 -0.75 L 0.90625 -2.71875 L 0.90625 -2.734375 C 0.90625 -2.765625 0.882812 -2.78125 0.84375 -2.78125 L 0.359375 -2.78125 C 0.328125 -2.78125 0.316406 -2.800781 0.328125 -2.84375 L 0.359375 -3.109375 C 0.359375 -3.117188 0.359375 -3.125 0.359375 -3.125 C 0.367188 -3.132812 0.382812 -3.140625 0.40625 -3.140625 L 0.921875 -3.140625 C 0.929688 -3.140625 0.941406 -3.144531 0.953125 -3.15625 C 0.960938 -3.175781 0.972656 -3.195312 0.984375 -3.21875 L 1.171875 -4.15625 C 1.179688 -4.195312 1.207031 -4.21875 1.25 -4.21875 L 1.5625 -4.21875 C 1.59375 -4.21875 1.609375 -4.1875 1.609375 -4.125 L 1.46875 -3.1875 C 1.46875 -3.15625 1.484375 -3.140625 1.515625 -3.140625 L 2.25 -3.140625 C 2.300781 -3.140625 2.328125 -3.125 2.328125 -3.09375 L 2.28125 -2.828125 C 2.28125 -2.804688 2.273438 -2.789062 2.265625 -2.78125 C 2.253906 -2.78125 2.238281 -2.78125 2.21875 -2.78125 L 1.46875 -2.78125 C 1.425781 -2.78125 1.398438 -2.753906 1.390625 -2.703125 L 1.140625 -0.828125 C 1.128906 -0.785156 1.125 -0.734375 1.125 -0.671875 C 1.125 -0.554688 1.144531 -0.476562 1.1875 -0.4375 C 1.238281 -0.394531 1.320312 -0.375 1.4375 -0.375 L 1.859375 -0.375 C 1.867188 -0.375 1.878906 -0.363281 1.890625 -0.34375 C 1.910156 -0.332031 1.921875 -0.316406 1.921875 -0.296875 L 1.875 -0.09375 C 1.875 -0.0507812 1.859375 -0.03125 1.828125 -0.03125 C 1.710938 -0.0078125 1.523438 0 1.265625 0 Z M 1.265625 0 "/></g></g></g><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(16.805885, 6.14539)"><g><path d="M 2.125 -0.375 C 1.800781 -0.0820312 1.429688 0.0625 1.015625 0.0625 C 0.734375 0.0625 0.515625 -0.00390625 0.359375 -0.140625 C 0.203125 -0.273438 0.125 -0.457031 0.125 -0.6875 C 0.125 -1.070312 0.285156 -1.359375 0.609375 -1.546875 C 0.941406 -1.734375 1.347656 -1.84375 1.828125 -1.875 L 2.296875 -1.90625 C 2.328125 -1.90625 2.351562 -1.914062 2.375 -1.9375 C 2.40625 -1.957031 2.421875 -1.976562 2.421875 -2 L 2.453125 -2.171875 C 2.453125 -2.234375 2.453125 -2.273438 2.453125 -2.296875 C 2.453125 -2.472656 2.394531 -2.609375 2.28125 -2.703125 C 2.175781 -2.796875 2.023438 -2.84375 1.828125 -2.84375 C 1.460938 -2.84375 1.148438 -2.679688 0.890625 -2.359375 C 0.878906 -2.347656 0.867188 -2.335938 0.859375 -2.328125 C 0.847656 -2.328125 0.832031 -2.332031 0.8125 -2.34375 L 0.5 -2.453125 C 0.476562 -2.460938 0.46875 -2.476562 0.46875 -2.5 C 0.46875 -2.519531 0.476562 -2.546875 0.5 -2.578125 C 0.644531 -2.773438 0.832031 -2.925781 1.0625 -3.03125 C 1.289062 -3.144531 1.554688 -3.203125 1.859375 -3.203125 C 2.210938 -3.203125 2.476562 -3.125 2.65625 -2.96875 C 2.84375 -2.820312 2.9375 -2.617188 2.9375 -2.359375 C 2.9375 -2.316406 2.929688 -2.253906 2.921875 -2.171875 L 2.640625 -0.078125 C 2.628906 -0.046875 2.617188 -0.0234375 2.609375 -0.015625 C 2.597656 -0.00390625 2.578125 0 2.546875 0 L 2.25 0 C 2.195312 0 2.171875 -0.03125 2.171875 -0.09375 L 2.203125 -0.375 C 2.203125 -0.40625 2.195312 -0.421875 2.1875 -0.421875 C 2.175781 -0.421875 2.15625 -0.40625 2.125 -0.375 Z M 2.34375 -1.53125 L 2.359375 -1.5625 C 2.359375 -1.59375 2.335938 -1.609375 2.296875 -1.609375 L 1.875 -1.5625 C 1.550781 -1.539062 1.257812 -1.46875 1 -1.34375 C 0.75 -1.226562 0.625 -1.035156 0.625 -0.765625 C 0.625 -0.617188 0.675781 -0.503906 0.78125 -0.421875 C 0.882812 -0.347656 1.023438 -0.3125 1.203125 -0.3125 C 1.335938 -0.3125 1.46875 -0.332031 1.59375 -0.375 C 1.71875 -0.425781 1.832031 -0.488281 1.9375 -0.5625 C 2.03125 -0.632812 2.109375 -0.710938 2.171875 -0.796875 C 2.242188 -0.878906 2.28125 -0.957031 2.28125 -1.03125 Z M 2.34375 -1.53125 "/></g></g></g><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(20.298629, 6.14539)"><g><path d="M 2.484375 0 C 2.460938 0 2.441406 -0.00390625 2.421875 -0.015625 C 2.410156 -0.0351562 2.40625 -0.0546875 2.40625 -0.078125 L 2.4375 -0.34375 L 2.453125 -0.359375 C 2.453125 -0.378906 2.441406 -0.390625 2.421875 -0.390625 C 2.410156 -0.390625 2.394531 -0.375 2.375 -0.34375 C 2.238281 -0.238281 2.09375 -0.144531 1.9375 -0.0625 C 1.789062 0.0195312 1.609375 0.0625 1.390625 0.0625 C 1.046875 0.0625 0.769531 -0.046875 0.5625 -0.265625 C 0.351562 -0.484375 0.25 -0.789062 0.25 -1.1875 C 0.25 -1.519531 0.3125 -1.84375 0.4375 -2.15625 C 0.570312 -2.46875 0.765625 -2.71875 1.015625 -2.90625 C 1.265625 -3.101562 1.550781 -3.203125 1.875 -3.203125 C 2.0625 -3.203125 2.21875 -3.171875 2.34375 -3.109375 C 2.46875 -3.054688 2.578125 -2.976562 2.671875 -2.875 C 2.691406 -2.851562 2.710938 -2.84375 2.734375 -2.84375 C 2.753906 -2.84375 2.773438 -2.875 2.796875 -2.9375 L 2.984375 -4.34375 C 2.992188 -4.363281 3.003906 -4.378906 3.015625 -4.390625 C 3.023438 -4.398438 3.039062 -4.40625 3.0625 -4.40625 L 3.421875 -4.40625 C 3.460938 -4.40625 3.484375 -4.375 3.484375 -4.3125 L 2.890625 -0.078125 C 2.878906 -0.046875 2.867188 -0.0234375 2.859375 -0.015625 C 2.847656 -0.00390625 2.820312 0 2.78125 0 Z M 2.734375 -2.46875 C 2.628906 -2.59375 2.515625 -2.6875 2.390625 -2.75 C 2.265625 -2.8125 2.128906 -2.84375 1.984375 -2.84375 C 1.734375 -2.84375 1.515625 -2.757812 1.328125 -2.59375 C 1.140625 -2.425781 1 -2.21875 0.90625 -1.96875 C 0.8125 -1.71875 0.765625 -1.460938 0.765625 -1.203125 C 0.765625 -0.898438 0.835938 -0.671875 0.984375 -0.515625 C 1.128906 -0.367188 1.320312 -0.296875 1.5625 -0.296875 C 1.71875 -0.296875 1.863281 -0.332031 2 -0.40625 C 2.144531 -0.488281 2.265625 -0.585938 2.359375 -0.703125 C 2.453125 -0.816406 2.507812 -0.925781 2.53125 -1.03125 Z M 2.734375 -2.46875 "/></g></g></g><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(24.094314, 6.14539)"><g><path d="M 1.5625 0.0625 C 1.164062 0.0625 0.847656 -0.0546875 0.609375 -0.296875 C 0.367188 -0.546875 0.25 -0.875 0.25 -1.28125 C 0.25 -1.644531 0.328125 -1.972656 0.484375 -2.265625 C 0.640625 -2.554688 0.847656 -2.785156 1.109375 -2.953125 C 1.378906 -3.117188 1.671875 -3.203125 1.984375 -3.203125 C 2.390625 -3.203125 2.707031 -3.078125 2.9375 -2.828125 C 3.175781 -2.578125 3.296875 -2.242188 3.296875 -1.828125 C 3.296875 -1.472656 3.21875 -1.148438 3.0625 -0.859375 C 2.914062 -0.578125 2.707031 -0.351562 2.4375 -0.1875 C 2.175781 -0.0195312 1.882812 0.0625 1.5625 0.0625 Z M 1.578125 -0.3125 C 1.816406 -0.3125 2.023438 -0.375 2.203125 -0.5 C 2.378906 -0.632812 2.519531 -0.820312 2.625 -1.0625 C 2.738281 -1.3125 2.796875 -1.59375 2.796875 -1.90625 C 2.796875 -2.195312 2.722656 -2.425781 2.578125 -2.59375 C 2.429688 -2.757812 2.234375 -2.84375 1.984375 -2.84375 C 1.753906 -2.84375 1.546875 -2.773438 1.359375 -2.640625 C 1.171875 -2.503906 1.023438 -2.3125 0.921875 -2.0625 C 0.816406 -1.820312 0.765625 -1.546875 0.765625 -1.234375 C 0.765625 -0.953125 0.832031 -0.726562 0.96875 -0.5625 C 1.113281 -0.394531 1.316406 -0.3125 1.578125 -0.3125 Z M 1.578125 -0.3125 "/></g></g></g><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(27.889998, 6.14539)"><g/></g></g><g clip-path="url(#77fbe158ad)"><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(29.404705, 6.14539)"><g><path d="M 0.171875 0.984375 C 0.117188 0.984375 0.0976562 0.953125 0.109375 0.890625 L 0.671875 -3.0625 C 0.671875 -3.101562 0.675781 -3.125 0.6875 -3.125 C 0.695312 -3.132812 0.722656 -3.140625 0.765625 -3.140625 L 1.078125 -3.140625 C 1.128906 -3.140625 1.15625 -3.113281 1.15625 -3.0625 L 1.109375 -2.8125 L 1.109375 -2.796875 C 1.109375 -2.773438 1.117188 -2.765625 1.140625 -2.765625 C 1.148438 -2.765625 1.171875 -2.78125 1.203125 -2.8125 C 1.210938 -2.820312 1.257812 -2.863281 1.34375 -2.9375 C 1.4375 -3.007812 1.554688 -3.070312 1.703125 -3.125 C 1.847656 -3.175781 2.003906 -3.203125 2.171875 -3.203125 C 2.503906 -3.203125 2.773438 -3.09375 2.984375 -2.875 C 3.191406 -2.664062 3.296875 -2.359375 3.296875 -1.953125 C 3.296875 -1.628906 3.234375 -1.3125 3.109375 -1 C 2.984375 -0.695312 2.800781 -0.441406 2.5625 -0.234375 C 2.320312 -0.0351562 2.03125 0.0625 1.6875 0.0625 C 1.507812 0.0625 1.351562 0.03125 1.21875 -0.03125 C 1.082031 -0.09375 0.96875 -0.171875 0.875 -0.265625 C 0.851562 -0.285156 0.835938 -0.296875 0.828125 -0.296875 C 0.796875 -0.296875 0.773438 -0.257812 0.765625 -0.1875 L 0.609375 0.921875 C 0.597656 0.941406 0.585938 0.957031 0.578125 0.96875 C 0.578125 0.976562 0.566406 0.984375 0.546875 0.984375 Z M 1.5625 -0.296875 C 1.820312 -0.296875 2.039062 -0.378906 2.21875 -0.546875 C 2.40625 -0.710938 2.546875 -0.921875 2.640625 -1.171875 C 2.734375 -1.429688 2.78125 -1.691406 2.78125 -1.953125 C 2.78125 -2.253906 2.707031 -2.476562 2.5625 -2.625 C 2.414062 -2.769531 2.226562 -2.84375 2 -2.84375 C 1.832031 -2.84375 1.675781 -2.804688 1.53125 -2.734375 C 1.394531 -2.660156 1.28125 -2.566406 1.1875 -2.453125 C 1.101562 -2.347656 1.054688 -2.242188 1.046875 -2.140625 L 0.828125 -0.6875 C 0.929688 -0.5625 1.039062 -0.460938 1.15625 -0.390625 C 1.28125 -0.328125 1.414062 -0.296875 1.5625 -0.296875 Z M 1.5625 -0.296875 "/></g></g></g></g><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(33.188509, 6.14539)"><g><path d="M 1.5625 0.0625 C 1.164062 0.0625 0.847656 -0.0546875 0.609375 -0.296875 C 0.367188 -0.546875 0.25 -0.875 0.25 -1.28125 C 0.25 -1.644531 0.328125 -1.972656 0.484375 -2.265625 C 0.640625 -2.554688 0.847656 -2.785156 1.109375 -2.953125 C 1.378906 -3.117188 1.671875 -3.203125 1.984375 -3.203125 C 2.390625 -3.203125 2.707031 -3.078125 2.9375 -2.828125 C 3.175781 -2.578125 3.296875 -2.242188 3.296875 -1.828125 C 3.296875 -1.472656 3.21875 -1.148438 3.0625 -0.859375 C 2.914062 -0.578125 2.707031 -0.351562 2.4375 -0.1875 C 2.175781 -0.0195312 1.882812 0.0625 1.5625 0.0625 Z M 1.578125 -0.3125 C 1.816406 -0.3125 2.023438 -0.375 2.203125 -0.5 C 2.378906 -0.632812 2.519531 -0.820312 2.625 -1.0625 C 2.738281 -1.3125 2.796875 -1.59375 2.796875 -1.90625 C 2.796875 -2.195312 2.722656 -2.425781 2.578125 -2.59375 C 2.429688 -2.757812 2.234375 -2.84375 1.984375 -2.84375 C 1.753906 -2.84375 1.546875 -2.773438 1.359375 -2.640625 C 1.171875 -2.503906 1.023438 -2.3125 0.921875 -2.0625 C 0.816406 -1.820312 0.765625 -1.546875 0.765625 -1.234375 C 0.765625 -0.953125 0.832031 -0.726562 0.96875 -0.5625 C 1.113281 -0.394531 1.316406 -0.3125 1.578125 -0.3125 Z M 1.578125 -0.3125 "/></g></g></g><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(36.984193, 6.14539)"><g><path d="M 0.328125 0 C 0.304688 0 0.285156 -0.00390625 0.265625 -0.015625 C 0.253906 -0.0351562 0.25 -0.0625 0.25 -0.09375 L 0.671875 -3.09375 C 0.671875 -3.113281 0.675781 -3.125 0.6875 -3.125 C 0.695312 -3.132812 0.710938 -3.140625 0.734375 -3.140625 L 1.078125 -3.140625 C 1.128906 -3.140625 1.148438 -3.113281 1.140625 -3.0625 L 1.09375 -2.71875 L 1.09375 -2.703125 C 1.09375 -2.679688 1.097656 -2.671875 1.109375 -2.671875 C 1.117188 -2.671875 1.132812 -2.679688 1.15625 -2.703125 C 1.488281 -3.035156 1.8125 -3.203125 2.125 -3.203125 C 2.269531 -3.203125 2.34375 -3.175781 2.34375 -3.125 L 2.296875 -2.78125 C 2.296875 -2.738281 2.28125 -2.722656 2.25 -2.734375 C 2.144531 -2.742188 2.054688 -2.75 1.984375 -2.75 C 1.867188 -2.75 1.738281 -2.710938 1.59375 -2.640625 C 1.445312 -2.566406 1.316406 -2.472656 1.203125 -2.359375 C 1.097656 -2.253906 1.035156 -2.144531 1.015625 -2.03125 L 0.75 -0.078125 C 0.75 -0.046875 0.738281 -0.0234375 0.71875 -0.015625 C 0.707031 -0.00390625 0.6875 0 0.65625 0 Z M 0.328125 0 "/></g></g></g><g fill="#d9d9d9" fill-opacity="1"><g transform="translate(39.496832, 6.14539)"><g><path d="M 1.046875 -2.421875 C 1.035156 -2.390625 1.019531 -2.367188 1 -2.359375 C 0.988281 -2.347656 0.96875 -2.34375 0.9375 -2.34375 L 0.515625 -2.34375 C 0.484375 -2.34375 0.457031 -2.351562 0.4375 -2.375 C 0.425781 -2.394531 0.425781 -2.421875 0.4375 -2.453125 L 0.5 -2.953125 C 0.507812 -2.972656 0.515625 -2.988281 0.515625 -3 C 0.523438 -3.007812 0.539062 -3.015625 0.5625 -3.015625 L 1.046875 -3.015625 C 1.066406 -3.015625 1.082031 -3.003906 1.09375 -2.984375 C 1.101562 -2.972656 1.109375 -2.953125 1.109375 -2.921875 Z M 0.71875 -0.09375 C 0.707031 -0.0625 0.695312 -0.0390625 0.6875 -0.03125 C 0.675781 -0.0195312 0.644531 -0.015625 0.59375 -0.015625 L 0.1875 -0.015625 C 0.125 -0.015625 0.0976562 -0.0507812 0.109375 -0.125 L 0.171875 -0.625 C 0.179688 -0.644531 0.1875 -0.65625 0.1875 -0.65625 C 0.195312 -0.664062 0.210938 -0.671875 0.234375 -0.671875 L 0.71875 -0.671875 C 0.738281 -0.671875 0.753906 -0.664062 0.765625 -0.65625 C 0.785156 -0.644531 0.789062 -0.625 0.78125 -0.59375 Z M 0.71875 -0.09375 "/></g></g></g></g></g></svg>
                        <hr class="text-light my-5">
                    </div>



                    <!---CTA--->
                    <cfinclude template="../cta.cfm">

                    <!---<div class="text-center my-5">
                        <h2 class="text-light text-center fs-1 lastica">O DESAFIO PREMIARÁ OS VENCEDORES COM BÔNUS EM DINHEIRO</h2>
                        <p class="text-light text-center">OS BRASILEIROS QUE ALCANÇAREM OS MELHORES TEMPOS DE MARATONAS SELECIONADAS NO BRASIL, TANTO NO MASCULINO QUANTO NO FEMININO, AO LONGO DE 2025 E UTILIZANDO lastica CORRE SUPRA, SERÃO PREMIADOS.</p>
                        <a class="btn btn-primary shadow-3 btn-rounded btn-lg" href="https://www.lastica.com.br/corre_supra_desafio" target="_blank">Saiba mais</a>
                    </div>--->

                </div>

            </div>

        </div>

    </section>


    <!--- FOOTER --->

    <cfinclude template="/includes/estrutura/footer.cfm"/>


    <!--- MODAL LOGIN --->

    <cfinclude template="/includes/modal/modal_login.cfm"/>


    <!--- SEO WEB TOOLS --->

    <cfinclude template="/includes/estrutura/seo-web-tools-body-end.cfm"/>

</body>

</html>
