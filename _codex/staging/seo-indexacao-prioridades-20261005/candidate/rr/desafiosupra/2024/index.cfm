<!doctype html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/desafiosupra/2024/"/>

<!--- TAG PARAM TREAT --->
<cfparam name="URL.tag" default=""/>
<cfset URL.tag = trim(replace(URL.tag, '/', ''))/>

<!--- BACKEND --->
<cfinclude template="/includes/estrutura/variaveis.cfm"/>
<cfinclude template="/includes/backend/backend.cfm"/>
<cfinclude template="/includes/backend/backend_login.cfm"/>

<cfquery name="qRankingSupraM">
    select tp.nome as name,
       evt.nome_evento,
        coalesce('https://roadrunners.run/assets/paginas/' || tp.path_imagem, usr.strava_profile, usr.imagem_usuario, '/assets/user.png?') as imagem_usuario,
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
    inner join tb_evento_corridas evt on evt.id_evento = tr.id_evento and evt.data_inicial < '2025-01-01'
    inner join tb_resultados_obs obs on obs.id_evento = tr.id_evento and obs.num_peito = tr.num_peito
    where obs.obs = 'Olympikus Supra'
    and tempo_total = (
        select min(tempo_total) from tb_resultados rr
               inner join tb_resultados_obs obb on obb.id_evento = rr.id_evento and
                          obb.num_peito = rr.num_peito and
                          obb.obs = 'Olympikus Supra' and
                          usr.id  = rr.id_usuario
            )
    AND usr.genero = 'M'
    order by sexo, tempo_total
</cfquery>

<cfquery name="qRankingSupraF">
    select tp.nome as name,
       evt.nome_evento,
        coalesce('https://roadrunners.run/assets/paginas/' || tp.path_imagem, usr.strava_profile, usr.imagem_usuario, '/assets/user.png?') as imagem_usuario,
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
    inner join tb_evento_corridas evt on evt.id_evento = tr.id_evento and evt.data_inicial < '2025-01-01'
    inner join tb_resultados_obs obs on obs.id_evento = tr.id_evento and obs.num_peito = tr.num_peito
    where obs.obs = 'Olympikus Supra'
    and tempo_total = (
        select min(tempo_total) from tb_resultados rr
               inner join tb_resultados_obs obb on obb.id_evento = rr.id_evento and
                          obb.num_peito = rr.num_peito and
                          obb.obs = 'Olympikus Supra' and
                          usr.id  = rr.id_usuario
            )
    AND usr.genero = 'F'
    order by sexo, tempo_total
</cfquery>

<!--- META INFO --->
<cfset VARIABLES.canonical = "#APPLICATION.baseCanonica##VARIABLES.template##URL.tag##Len(trim(URL.tag)) ? '/' : ''##VARIABLES.queryString#"/>
<cfset VARIABLES.title = "Ranking Desafio Corre Supra 2024 | #APPLICATION.nomeSite#"/>
<cfset VARIABLES.description = "Ranking do Desafio Corre Supra 2024, com classificações masculina e feminina e links para os resultados das provas."/>
<cfset VARIABLES.keywords = "resultados, corrida, competição, pódio, atletas, corredores"/>

<!--- HEAD --->
<cfinclude template="/includes/estrutura/head.cfm"/>

<style>

    @font-face {
        font-family: olympikus;
        src: url(../assets/fonts/FKOlympikus-Upright___00e3c62dd97c86e7a93745e13196a00a.ttf);
    }

    html,
    body,
    .intro {
        _height: 100%;
    }

    .olympikus {
        font-family: olympikus;
    }

    table td,
    table th {
        padding: 6px 2px !important;
        line-height: 1rem;
        font-size: 1.1rem;
        vertical-align: middle;
    }
    table th {
        font-family: olympikus;
        text-align: center;
    }

</style>

<body>

    <!--- SEO WEB TOOLS --->

    <cfinclude template="/includes/estrutura/seo-web-tools-body-start.cfm"/>


    <div class="container-fluid">


        <!--- HEADER --->

        <cfinclude template="/includes/estrutura/header.cfm"/>

    </div>

    <section class="intro" style="margin-top: -50px; margin-bottom: 50px;">

        <div class="bg-image py-5 bg-fixed" style="background-image: url('../assets/images/bg_supra.webp');">

            <div class="" style="">

                <div class="container py-5">

                    <h1 class="text-light text-center olympikus display-1">OLYMPIKUS : <br class="d-md-none"/>DESAFIO CORRE SUPRA 2024<a class="btn btn-secondary btn-lg shadow-3 btn-rounded fs-4 float-start mt-4 d-none d-md-block" href="../"><i class="fa-solid fa-chevron-left"></i></a></h1>

                    <div class="row d-fill text-light my-5 p-4">
                        <div class="col-12 col-md-6">
                            <div class="text-uppercase">
                                <h3 class="olympikus display-3">Provas incluídas <br/>no Desafio Supra:</h3>
                                <p class="small"> *obs: o desafio é exclusivo para a distância<br> total de uma maratona (42.195m)</p>
                                <a class="btn btn-primary shadow-3 btn-rounded btn-lg mb-5" href="#ranking"> Veja o ranking</a>
                            </div>
                        </div>
                        <div class="col-12 col-md-6 olympikus text-uppercase">
                            <a href="//openresults.run/evento/2024-maratona-internacional-de-sao-paulo-2024/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2><span class="h5 me-2">01.</span>Maratona Intl. de SÃO PAULO <img src="/assets/verified.png"></h2>
                            </a>
                            <a href="//openresults.run/evento/2024-maratona-internacional-do-rio-de-janeiro-2024/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2><span class="h5 me-2">02.</span>Maratona do RIO DE JANEIRO <img src="/assets/verified.png"></h2>
                            </a>
                            <a href="//openresults.run/evento/2024-maratona-internacional-de-manaus/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2><span class="h5 me-2">03.</span>Maratona Intl. de Manaus <img src="/assets/verified.png"></h2>
                            </a>
                            <a href="//openresults.run/evento/2024-sp-city-marathon-2024/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2><span class="h5 me-2">04.</span>SP City Marathon <img src="/assets/verified.png"></h2>
                            </a>
                            <a href="//openresults.run/evento/2024-maratona-internacional-de-floripa-2024/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2><span class="h5 me-2">05.</span>Maratona Intl. de Floripa <img src="/assets/verified.png"></h2>
                            </a>
                            <a href="//openresults.run/evento/2024-maratona-de-salvador-2024/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2><span class="h5 me-2">06.</span>Maratona de Salvador <img src="/assets/verified.png"></h2>
                            </a>
                            <a href="//openresults.run/evento/2024-maratona-internacional-de-porto-alegre/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2><span class="h5 me-2">07.</span>Maratona Intl. de PORTO ALEGRE <img src="/assets/verified.png"></h2>
                            </a>
                            <a href="//openresults.run/evento/2024-maratona-de-curitiba-2024/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2><span class="h5 me-2">08.</span>Maratona de Curitiba <img src="/assets/verified.png"></h2>
                            </a>
                            <a href="//openresults.run/evento/2024-maratona-monumental-de-brasilia-2024/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2><span class="h5 me-2">09.</span>Maratona Monumental de Brasília <img src="/assets/verified.png"></h2>
                            </a>
                        </div>

                    </div>

                    <hr class="text-light">

                    <a id="ranking" class="position-absolute" style="margin-top:-120px;"></a>

                    <h2 class="text-light text-center olympikus display-2">RANKING SUPRA 2024</h2>

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
                                                <td><a href="/atleta/#qRankingSupraM.tag#/"><img src="#qRankingSupraM.imagem_usuario#"
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
                                                <td><a href="/atleta/#qRankingSupraF.tag#/"><img src="#qRankingSupraF.imagem_usuario#"
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
                    </div>

                    <div class="text-center my-5">
                        <img src="https://openresults.run/assets/OR_selo_audit.png">
                        <hr class="text-light">
                    </div>

                    <!---<div class="text-center my-5">
                        <h2 class="text-light text-center fs-1 olympikus">O DESAFIO PREMIARÁ OS VENCEDORES COM BÔNUS EM DINHEIRO</h2>
                        <p class="text-light text-center">OS BRASILEIROS QUE ALCANÇAREM OS MELHORES TEMPOS DE MARATONAS SELECIONADAS NO BRASIL, TANTO NO MASCULINO QUANTO NO FEMININO, AO LONGO DE 2024 E UTILIZANDO OLYMPIKUS CORRE SUPRA, SERÃO PREMIADOS.</p>
                        <a class="btn btn-primary shadow-3 btn-rounded btn-lg" href="https://www.olympikus.com.br/corre_supra_desafio" target="_blank">Saiba mais</a>
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
