<!doctype html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/circuitocatarinense/"/>
<cfset VARIABLES.theme = "dark"/>

<!--- TAG PARAM TREAT --->
<cfparam name="URL.tag" default=""/>
<cfset URL.tag = trim(replace(URL.tag, '/', ''))/>

<!--- BACKEND --->
<cfinclude template="../includes/estrutura/variaveis.cfm"/>
<cfinclude template="../includes/backend/backend.cfm"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>

<cfquery name="qRankingSupraM">
    select tp.nome as name,
       evt.nome_evento,
        tr.modalidade,
       evt.tag as tag_evento,
       usr.id,
       usr.genero,
       usr.cbat,
       tr.tempo_total,
       tr.sexo,
        tp.tag
    from
    tb_resultados tr
    inner join tb_usuarios usr on usr.id = tr.id_usuario
    inner join public.tb_paginas_usuarios tpu on tpu.id_usuario = usr.id
    inner join public.tb_paginas tp on tp.id_pagina = tpu.id_pagina
    inner join tb_evento_corridas evt on evt.id_evento = tr.id_evento
    inner join tb_resultados_obs obs on obs.id_evento = tr.id_evento and obs.num_peito = tr.num_peito
    where obs.obs = 'lastica Supra'
    and tempo_total = (
        select min(tempo_total) from tb_resultados rr
               inner join tb_resultados_obs obb on obb.id_evento = rr.id_evento and
                          obb.num_peito = rr.num_peito and
                          obb.obs = 'lastica Supra' and
                          usr.id  = rr.id_usuario
            )
    AND usr.genero = 'M'
    order by sexo, tempo_total
</cfquery>

<cfquery name="qRankingSupraF">
    select tp.nome as name,
       evt.nome_evento,
       tr.modalidade,
       evt.tag as tag_evento,
       usr.id,
        usr.genero,
       usr.cbat,
       tr.tempo_total,
       tr.sexo,
        tp.tag
    from
    tb_resultados tr
    inner join tb_usuarios usr on usr.id = tr.id_usuario
    inner join public.tb_paginas_usuarios tpu on tpu.id_usuario = usr.id
    inner join public.tb_paginas tp on tp.id_pagina = tpu.id_pagina
    inner join tb_evento_corridas evt on evt.id_evento = tr.id_evento
    inner join tb_resultados_obs obs on obs.id_evento = tr.id_evento and obs.num_peito = tr.num_peito
    where obs.obs = 'lastica Supra'
    and tempo_total = (
        select min(tempo_total) from tb_resultados rr
               inner join tb_resultados_obs obb on obb.id_evento = rr.id_evento and
                          obb.num_peito = rr.num_peito and
                          obb.obs = 'lastica Supra' and
                          usr.id  = rr.id_usuario
            )
    AND usr.genero = 'F'
    order by sexo, tempo_total
</cfquery>

<!--- META INFO --->
<cfset VARIABLES.canonical = "#APPLICATION.baseCanonica##VARIABLES.template##URL.tag##Len(trim(URL.tag)) ? '/' : ''##VARIABLES.queryString#"/>
<cfset VARIABLES.title = "Circuito Catarinense de Corridas - #APPLICATION.nomeSite#"/>
<cfset VARIABLES.description = "Ranking de Atletas do Circuito de Corridas da Federação Catarinense de Atletismo"/>
<cfset VARIABLES.keywords = "resultados, corrida, competição, pódio, atletas, corredores, sant catarina, catarinense, sul, meia maratona, trail, run, running"/>

<!--- HEAD --->
<cfinclude template="../includes/estrutura/head.cfm"/>

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
</style>

<body class="back-gradient">

    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/estrutura/seo-web-tools-body-start.cfm"/>


    <div class="container">


        <!--- HEADER --->

        <cfinclude template="../includes/estrutura/header.cfm"/>

    </div>

    <section class="intro" style="margin-top: -80px; margin-bottom: 50px;">

        <div class="pt-5">

            <div class="" style="">

                <div class="fixed-top bg-black mb-5 mt-4 pt-4 z-1">
                    <div class="container py-1">
                        <div class="row">
                            <div class="col-12 col-md-8 align-content-center">
                                <a href="/circuitocatarinense/"><h1 class="h3 text-light font-bold m-0 text-center text-md-start"><img src="assets/images/logo_fca_branco.png" class="w-75px">Circuito Catarinense de Corrida</h1></a>
                            </div>
                            <div class="col-12 col-md-4 text-center text-md-end">
                                <!---<a class="btn btn-sm btn-dark shadow-3 btn-rounded my-1 px-3" href="/circuitocatarinense/"><i class="fa-solid fa-angle-left"></i></a>--->
                                <a class="btn btn-sm btn-danger shadow-3 btn-rounded my-1" href="/circuitocatarinense/corridaderua/"><i class="fa-solid fa-person-running"></i>Corrida de Rua</a>
                                <a class="btn btn-sm btn-success shadow-3 btn-rounded my-1" href="/circuitocatarinense/trailrun/"><i class="fa-solid fa-mountain"></i>Trail Run</a>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="container py-5 mt-5">

                    <!---<div class="text-center"><img src="assets/images/logo_fca_branco.png" width="200px" class=""></div>--->

                    <!---<h1 class="text-light text-center display-2 font-bold">Federação Catarinense <br class="d-md-none"> de Atletismo</h1>--->
                    <!---<h5 class="text-light text-center fw-lighter font-regular">Apresenta:</h5>--->

                    <div class="row text-light my-2 p-4 g-3">

                        <div class="col-12 col-md-6 mb-2">
                        <div class="text-uppercase text-center rounded-3 py-5 bg-black bg-opacity-25 border border-2 border-danger bg-image" style="background-image:url('assets/images/fca_bg_rua.jpg?1')">
                                <div class="text-center font-regular">Circuito Catarinense de</div>
                                <h2 class="font-bold display-5">Corrida de rua</h2>
                                <div class="text-danger">
                                    <i class="fa-solid fa-person-running"></i>
                                    <i class="fa-solid fa-person-running"></i>
                                    <i class="fa-solid fa-person-running"></i>
                                    <i class="fa-solid fa-person-running"></i>
                                    <i class="fa-solid fa-person-running"></i>
                                    <i class="fa-solid fa-person-running"></i>
                                </div>
                                <h4 class="font-regular">6 etapas</h4>
                                <cfquery name="qStatsRua">
                                    select * from desafios
                                    where produto = <cfqueryparam cfsqltype="cf_sql_varchar" value="catarinensecorridaderua"/>
                                </cfquery>
                                <cfquery name="qImagesRua">
                                    select * from desafios cna inner join tb_usuarios usr on usr.id = cna.id_usuario
                                    where produto = <cfqueryparam cfsqltype="cf_sql_varchar" value="catarinensecorridaderua"/> and strava_profile ilike '%https%'
                                    order by RANDOM()
                                </cfquery>
                                <h4 class="fw-extra-bold d-flex flex-column mb-0 font-regular text-center">
                                    <cfoutput>#qStatsRua.recordcount#</cfoutput> atletas
                                </h4>
                                <div class="author-image d-flex gap-0 ps-10 justify-content-center my-3">
                                    <cfoutput query="qImagesRua" maxrows="1">
                                        <img class="border border-white border-2 rounded-circle w-50px bg-light" src="#qImagesRua.strava_profile#" alt="img"onerror="this.src='/assets/user.png';" width="50" height="50">
                                    </cfoutput>
                                    <cfoutput query="qImagesRua" startrow="2" maxrows="4">
                                        <img class="ms-n3 border border-white border-2 rounded-circle w-50px bg-light" src="#qImagesRua.strava_profile#" alt="img"onerror="this.src='/assets/user.png';" width="50" height="50">
                                    </cfoutput>
                                    <div class="ms-n3 border border-white border-2 text-center rounded-circle w-50px align-content-center bg-danger">
                                        <h6 class="text-white fw-extra-bold mb-0">+<cfoutput>#qStatsRua.recordcount-5#</cfoutput></h6>
                                    </div>
                                </div>
                                <a class="btn btn-danger shadow-3 btn-rounded btn-lg my-3" href="corridaderua">Saiba mais</a>
                            </div>
                        </div>

                        <div class="col-12 col-md-6 mb-2">
                            <div class="text-uppercase text-center rounded-3 py-5 bg-black bg-opacity-25 border border-2 border-success bg-image" style="background-image:url('assets/images/fca_bg_trail.jpg?1')">
                                <div class="text-center font-regular">Circuito Catarinense de</div>
                                <h2 class="font-bold display-5">Trail Run</h2>
                                <div class="text-success">
                                    <i class="fa-solid fa-mountain"></i>
                                    <i class="fa-solid fa-mountain"></i>
                                    <i class="fa-solid fa-mountain"></i>
                                    <i class="fa-solid fa-mountain"></i>
                                    <i class="fa-solid fa-mountain"></i>
                                    <i class="fa-solid fa-mountain"></i>
                                </div>
                                <h4 class="font-regular">6 etapas</h4>
                                <cfquery name="qStatsTrail">
                                    select * from desafios
                                    where produto = <cfqueryparam cfsqltype="cf_sql_varchar" value="catarinensetrailrun"/>
                                </cfquery>
                                <cfquery name="qImagesTrail">
                                    select * from desafios cna inner join tb_usuarios usr on usr.id = cna.id_usuario
                                    where produto = <cfqueryparam cfsqltype="cf_sql_varchar" value="catarinensetrailrun"/> and strava_profile ilike '%https%'
                                    order by RANDOM()
                                </cfquery>
                                <h4 class="fw-extra-bold d-flex flex-column mb-0 font-regular text-center">
                                    <cfoutput>#qStatsTrail.recordcount#</cfoutput> atletas
                                </h4>
                                <div class="author-image d-flex gap-0 ps-10 justify-content-center my-3">
                                    <cfoutput query="qImagesTrail" maxrows="1">
                                        <img class="border border-white border-2 rounded-circle w-50px bg-light" src="#qImagesTrail.strava_profile#" alt="img"onerror="this.src='/assets/user.png';" width="50" height="50">
                                    </cfoutput>
                                    <cfoutput query="qImagesTrail" startrow="2" maxrows="4">
                                        <img class="ms-n3 border border-white border-2 rounded-circle w-50px bg-light" src="#qImagesTrail.strava_profile#" alt="img"onerror="this.src='/assets/user.png';" width="50" height="50">
                                    </cfoutput>
                                    <div class="ms-n3 border border-white border-2 text-center rounded-circle w-50px align-content-center bg-success">
                                        <h6 class="text-white fw-extra-bold mb-0">+<cfoutput>#qStatsTrail.recordcount-5#</cfoutput></h6>
                                    </div>
                                </div>
                                <a class="btn btn-success shadow-3 btn-rounded btn-lg my-3" href="trailrun">Saiba mais</a>
                            </div>
                        </div>

                        <hr class="text-light my-5">

                        <div class="text-center my-2">
                            <div class="row">
                                <div class="col-sm-auto col-lg-2"></div>
                                <div class="col-sm-12 col-lg-8 text-center">
                                    <h2 class="text-light text-center fs-1 font-bold">Corra e faça parte deste marco com a gente</h2>
                                    <p class="text-light text-center">O Circuito Catarinense de Corridas de Rua e Trail Run 2026 vem para unir atletas,
                                        organizadores e comunidades em torno de um mesmo propósito: fortalecer o esporte e
                                        construir um novo capítulo para o Atletismo Catarinense.</p>
                                    <!---<a class="btn btn-primary shadow-3 btn-rounded btn-lg" href="https://www.lastica.com.br/corre_supra_desafio" target="_blank">Saiba mais</a>--->
                                    <a class="btn btn-secondary shadow-3 btn-rounded btn-lg" href="#inscricao">Participe</a>
                                </div>
                                <div class="col-sm-auto col-lg-2"></div>
                            </div>
                        </div>

                        <hr class="text-light my-5">

                        <!---CTA--->
                        <cfinclude template="cta.cfm">

                        <!---<div class="col-12 col-md-6">
                            <div class="text-uppercase">
                                <h3 class="lastica display-3">Provas incluídas <br/>no Desafio Supra:</h3>
                                <p class="small"> *obs: o desafio é exclusivo para a distância<br> total de uma maratona (42.195m)</p>
                                <a class="btn btn-primary shadow-3 btn-rounded btn-lg mb-5" href="#ranking"> Veja o ranking</a>
                            </div>
                        </div>--->

                        <!---<div class="col-12 col-md-6 lastica text-uppercase">
                            <a href="/evento/2024-maratona-internacional-de-sao-paulo-2024/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2>Maratona Intl. de SÃO PAULO <img src="/assets/verified.png"></h2>
                            </a>
                            <a href="/evento/2024-maratona-internacional-do-rio-de-janeiro-2024/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2>Maratona do RIO DE JANEIRO <img src="/assets/verified.png"></h2>
                            </a>
                            <a href="/evento/2024-maratona-internacional-de-manaus/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2>Maratona Intl. de Manaus <img src="/assets/verified.png"></h2>
                            </a>
                            <a href="/evento/2024-sp-city-marathon-2024/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2>SP City Marathon <img src="/assets/verified.png"></h2>
                            </a>
                            <a href="/evento/2024-maratona-internacional-de-floripa-2024/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2>Maratona Intl. de Floripa <img src="/assets/verified.png"></h2>
                            </a>
                            <a href="/evento/2024-maratona-de-salvador-2024/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2>Maratona de Salvador <img src="/assets/verified.png"></h2>
                            </a>
                            <a href="/evento/2024-maratona-internacional-de-porto-alegre/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2>Maratona Intl. de PORTO ALEGRE <img src="/assets/verified.png"></h2>
                            </a>
                            <a href="/evento/2024-maratona-de-curitiba-2024/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2>Maratona de Curitiba <img src="/assets/verified.png"></h2>
                            </a>
                            <a href="/evento/2024-maratona-monumental-de-brasilia-2024/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2>Maratona Monumental de Brasília <img src="/assets/verified.png"></h2>
                            </a>
                        </div>--->

                    </div>

                    <!---<hr class="text-light">

                    <a id="ranking" class="position-absolute" style="margin-top:-120px;"></a>

                    <h2 class="text-light text-center lastica display-2">RANKING SUPRA 2024</h2>

                    <div class="row justify-content-center">
                        <div class="col-12">
                            <div class="card">
                                <div class="card-body row">

                                    <div class="table-responsive col-lg-6 p-0 p-lg-2">
                                        <h4 class="text-center">
                                            Masculino
                                        </h4>
                                        <table class="table table-hover mb-0 small">
                                            <thead>
                                            <tr>
                                                <th colspan="3" scope="col">Atleta / Evento</th>
                                                <th scope="col">Tempo</th>
                                                <th scope="col">Recorde*</th>
                                                <th scope="col">CBAt</th>
                                            </tr>
                                            </thead>
                                            <tbody>
                                            <cfset VARIABLES.posicao = 1/>
                                            <cfoutput query="qRankingSupraM">
                                            <tr>
                                                <th scope="row" class="h1 opacity-50">#VARIABLES.posicao#</th>
                                                <td><a href="/atleta/#qRankingSupraM.tag#/"><img src="https://sge.cbat.org.br/_uploads/fotoAtleta/old/Atletas/#qRankingSupraM.cbat#.jpg"
                                                        onerror="this.onerror=null;this.src='/assets/user.png';"
                                                        class="rounded-circle object-cover"
                                                        height="32"
                                                        width="32"
                                                        loading="lazy"/></a></td>
                                                <td><a href="/atleta/#qRankingSupraM.tag#/">#qRankingSupraM.name#</a><br/><small><a href="/evento/#qRankingSupraM.tag_evento#/?modalidade=#qRankingSupraM.modalidade#&genero=#qRankingSupraM.genero#" class="small">#qRankingSupraM.nome_evento#</a></small></td>
                                                <td class="small text-center"><a href="/atleta/#qRankingSupraM.tag#/">#qRankingSupraM.tempo_total#</a></td>
                                                <td class="small text-center">#lsTimeFormat((qRankingSupraM.tempo_total - '02:11:19'), "-mm:ss")#</td>
                                                <td class="small text-center"><a href="https://cbat.org.br/atletas/#qRankingSupraM.cbat#/#qRankingSupraM.tag#" target="_blank" class="text-gray-light"><i class="fa-solid fa-up-right-from-square"></i></a></td>
                                            </tr>
                                            <cfset VARIABLES.posicao = VARIABLES.posicao + 1/>
                                            </cfoutput>
                                            </tbody>
                                        </table>
                                        <p class="mt-3" style="font-size: x-small">* Diferença em relação ao recorde de <b>Vanderlei Cordeiro</b> na Maratona de São Paulo em 2002 <b>(2:11:19)</b></p>
                                    </div>

                                    <div class="table-responsive col-lg-6 p-0 p-lg-2">
                                        <hr class="d-sm-block d-lg-none my-4">
                                        <h4 class="text-center">
                                            Feminino
                                        </h4>
                                        <table class="table table-hover mb-0">
                                            <thead>
                                            <tr>
                                                <th colspan="3" scope="col">Atleta / Evento</th>
                                                <th scope="col">Tempo</th>
                                                <th scope="col">Recorde*</th>
                                                <th scope="col">CBAt</th>
                                            </tr>
                                            </thead>
                                            <tbody>
                                            <cfset VARIABLES.posicao = 1/>
                                            <cfoutput query="qRankingSupraF">
                                            <tr>
                                                <th scope="row" class="h1 opacity-50">#VARIABLES.posicao#</th>
                                                <td><a href="/atleta/#qRankingSupraF.tag#/"><img src="https://sge.cbat.org.br/_uploads/fotoAtleta/old/Atletas/#qRankingSupraF.cbat#.jpg"
                                                        onerror="this.onerror=null;this.src='/assets/user.png';"
                                                        class="rounded-circle object-cover"
                                                        height="32"
                                                        width="32"
                                                        loading="lazy"/></a></td>
                                                <td><a href="/atleta/#qRankingSupraF.tag#/">#qRankingSupraF.name#</a><br/><small><a href="/evento/#qRankingSupraF.tag_evento#/?modalidade=#qRankingSupraF.modalidade#&genero=#qRankingSupraF.genero#" class="small">#qRankingSupraF.nome_evento#</a></small></td>
                                                <td class="small text-center"><a href="/atleta/#qRankingSupraF.tag#/">#qRankingSupraF.tempo_total#</a></td>
                                                <td class="small text-center">#lsTimeFormat((qRankingSupraF.tempo_total - '02:34:18'), "-mm:ss")#</td>
                                                <td class="small text-center"><a href="https://cbat.org.br/atletas/#qRankingSupraF.cbat#/#qRankingSupraF.tag#" target="_blank" class="text-gray-light"><i class="fa-solid fa-up-right-from-square"></i></a></td>
                                            </tr>
                                            <cfset VARIABLES.posicao = VARIABLES.posicao + 1/>
                                            </cfoutput>
                                            </tbody>
                                        </table>
                                        <p class="mt-3" style="font-size: x-small">* Diferença em relação ao recorde de <b>Márcia Narloch</b> na Maratona de Porto Alegre em 2000 <b>(2:34:18)</b></p>
                                    </div>

                                </div>
                            </div>
                        </div>
                    </div>--->

                    <!---<div class="text-center my-5">
                        <img src="https://openresults.run/assets/OR_selo_audit.png">
                    </div>--->



                </div>
            </div>
        </div>
    </section>

    <!--- FOOTER --->

    <cfinclude template="../includes/estrutura/footer.cfm"/>


    <!--- MODAL LOGIN --->

    <cfinclude template="../includes/modal/modal_login.cfm"/>


    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/estrutura/seo-web-tools-body-end.cfm"/>

</body>

</html>

