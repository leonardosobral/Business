<!doctype html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/desafiosupra/2025/"/>

<!--- TAG PARAM TREAT --->
<cfparam name="URL.tag" default=""/>
<cfset URL.tag = trim(replace(URL.tag, '/', ''))/>

<!--- BACKEND --->
<cfinclude template="/includes/estrutura/variaveis.cfm"/>
<cfinclude template="/includes/backend/backend.cfm"/>
<cfinclude template="/includes/backend/backend_login.cfm"/>

<cfquery name="qRankingSupraM">
    select upper(tp.nome) as name,
    tr.classificacao_sexo,
    evt.nome_evento,
    coalesce('https://roadrunners.run/assets/paginas/' || tp.path_imagem, usr.strava_profile, usr.imagem_usuario, '/assets/user.png?') as imagem_usuario,
    tr.modalidade,
    evt.tag as tag_evento,
    usr.id,
    tr.sexo as genero,
    (select body ->> 'cbat' from desafios where id_usuario = usr.id and desafio = 'desafiosupra' limit 1) cbat,
    tr.tempo_total,
    tr.sexo,
    tp.tag
    from
    tb_resultados tr
    inner join tb_usuarios usr on usr.id = tr.id_usuario
    inner join public.tb_paginas_usuarios tpu on tpu.id_usuario = usr.id
    inner join public.tb_paginas tp on tp.id_pagina = tpu.id_pagina
    inner join tb_evento_corridas evt on evt.id_evento = tr.id_evento and evt.data_inicial >= '2025-01-01'
    inner join tb_resultados_obs obs on obs.id_evento = tr.id_evento and obs.num_peito = tr.num_peito
    inner join desafios dsf on dsf.id_usuario = tr.id_usuario and dsf.desafio = 'desafiosupra'
    where obs.obs = 'Olympikus Supra'
    <cfif NOT isDefined("URL.completo")>
    and tempo_total = (select min(tr_sub.tempo_total) from tb_resultados_obs obs_sub
        inner join public.tb_resultados tr_sub on obs_sub.num_peito = tr_sub.num_peito
            and obs_sub.id_evento = tr_sub.id_evento
        inner join tb_evento_corridas evt_sub on obs_sub.id_evento = evt_sub.id_evento
        where obs_sub.obs = 'Olympikus Supra'
        and evt_sub.data_inicial >= '2025-01-01'
        and usr.id = tr_sub.id_usuario)
    </cfif>
    AND tr.sexo = 'M'
    order by tr.sexo, tempo_total
</cfquery>

<cfquery name="qRankingSupraF">
    select upper(tp.nome) as name,
    tr.classificacao_sexo,
    evt.nome_evento,
    coalesce('https://roadrunners.run/assets/paginas/' || tp.path_imagem, usr.strava_profile, usr.imagem_usuario, '/assets/user.png?') as imagem_usuario,
    tr.modalidade,
    evt.tag as tag_evento,
    usr.id,
    tr.sexo as genero,
    (select body ->> 'cbat' from desafios where id_usuario = usr.id and desafio = 'desafiosupra' limit 1) cbat,
    tr.tempo_total,
    tr.sexo,
    tp.tag
    from
    tb_resultados tr
    inner join tb_usuarios usr on usr.id = tr.id_usuario
    inner join public.tb_paginas_usuarios tpu on tpu.id_usuario = usr.id
    inner join public.tb_paginas tp on tp.id_pagina = tpu.id_pagina
    inner join tb_evento_corridas evt on evt.id_evento = tr.id_evento and evt.data_inicial >= '2025-01-01'
    inner join tb_resultados_obs obs on obs.id_evento = tr.id_evento and obs.num_peito = tr.num_peito
    inner join desafios dsf on dsf.id_usuario = tr.id_usuario and dsf.desafio = 'desafiosupra'
    where obs.obs = 'Olympikus Supra'
    <cfif NOT isDefined("URL.completo")>
    and tempo_total = (select min(tr_sub.tempo_total) from tb_resultados_obs obs_sub
        inner join public.tb_resultados tr_sub on obs_sub.num_peito = tr_sub.num_peito
            and obs_sub.id_evento = tr_sub.id_evento
        inner join tb_evento_corridas evt_sub on obs_sub.id_evento = evt_sub.id_evento
        where obs_sub.obs = 'Olympikus Supra'
        and evt_sub.data_inicial >= '2025-01-01'
        and usr.id = tr_sub.id_usuario)
    </cfif>
    AND tr.sexo = 'F'
    order by tr.sexo, tempo_total
</cfquery>

<!--- META INFO --->
<cfset VARIABLES.canonical = "#APPLICATION.baseCanonica##VARIABLES.template##URL.tag##Len(trim(URL.tag)) ? '/' : ''##VARIABLES.queryString#"/>
<cfset VARIABLES.title = "Ranking Desafio Corra Supra 2025 | #APPLICATION.nomeSite#"/>
<cfset VARIABLES.description = "Ranking do Desafio Corra Supra 2025, com classificações masculina e feminina e links para os resultados das provas."/>
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
    .olympikus-blue {
        color: #2735d4;
    }
    .olympikus-bg-blue {
        background-color: #2735d4;
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

        <div class="bg-image pt-5 bg-fixed" style="background-image: url('../assets/images/bg_supra.webp');">

            <div class="bg-black bg-opacity-25" style="">

                <div class="container py-5">

                    <h1 class="text-light text-center olympikus display-1">OLYMPIKUS : <br class="d-md-none"/>DESAFIO CORRA SUPRA 2025<a class="btn btn-secondary btn-lg shadow-3 btn-rounded fs-4 float-start mt-4 d-none d-md-block" href="../"><i class="fa-solid fa-chevron-left"></i></a></h1>

                    <div class="row d-fill text-light my-5 p-4">
                        <div class="col-12 col-md-6">
                            <div class="text-uppercase">
                                <h3 class="olympikus display-3">Provas incluídas <br/>no Desafio Supra:</h3>
                                <p class="small"> *obs: o desafio é exclusivo para a distância<br> total de uma maratona (42.195m)</p>
                                <a class="btn btn-primary shadow-3 btn-rounded btn-lg mb-5" href="#ranking"> Veja o ranking</a>
                            </div>
                        </div>
                        <div class="col-12 col-md-6 olympikus text-uppercase">
                            <a href="/evento/2025-maratona-internacional-de-porto-alegre/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2><span class="h5 me-2">01.</span><span class="">Maratona Intl. de PORTO ALEGRE <img src="/assets/verified.png" class="<cfif '2025-06-08' GT now()>d-none</cfif>"></span><span class="h5 ms-2">08/06/2025</span></h2>
                            </a>
                            <a href="/evento/2025-maratona-internacional-do-rio-de-janeiro/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2><span class="h5 me-2">02.</span><span class="">Maratona do RIO DE JANEIRO <img src="/assets/verified.png" class="<cfif '2025-06-22' GT now()>d-none</cfif>"></span><span class="h5 ms-2">22/06/2025</span></h2>
                            </a>
                            <a href="/evento/2025-spcity-marathon-2025/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2><span class="h5 me-2">03.</span><span class="">SP City Marathon <img src="/assets/verified.png" class="<cfif '2025-07-27' GT now()>d-none</cfif>"></span><span class="h5 ms-2">27/07/2025</span></h2>
                            </a>
                            <a href="/evento/2025-maratona-internacional-de-joao-pessoa-2025/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2><span class="h5 me-2">04.</span><span class="">Maratona Intl. de Joào Pessoa <img src="/assets/verified.png" class="<cfif '2025-08-03' GT now()>d-none</cfif>"></span><span class="h5 ms-2">03/08/2025</span></h2>
                            </a>
                            <a href="/evento/2025-maratona-internacional-de-floripa/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2><span class="h5 me-2">05.</span><span class="">Maratona Intl. de Floripa <img src="/assets/verified.png" class="<cfif '2025-08-31' GT now()>d-none</cfif>"></span><span class="h5 ms-2">31/08/2025</span></h2>
                            </a>
                            <a href="/evento/2025-12-maratona-internacional-de-goiania-em-movimento/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2><span class="h5 me-2">06.</span><span class="">Maratona Intl. de Goiânia <img src="/assets/verified.png" class="<cfif '2025-08-31' GT now()>d-none</cfif>"></span><span class="h5 ms-2">31/08/2025</span></h2>
                            </a>
                            <a href="/evento/2025-maratona-salvador-2025/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2><span class="h5 me-2">07.</span><span class="">Maratona de Salvador <img src="/assets/verified.png" class="<cfif '2025-09-21' GT now()>d-none</cfif>"></span><span class="h5 ms-2">21/09/2025</span></h2>
                            </a>
                            <a href="/evento/2025-maratona-monumental-de-brasilia-2025/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2><span class="h5 me-2">08.</span><span class="">Maratona Monumental de Brasília <img src="/assets/verified.png" class="<cfif '2025-11-23' GT now()>d-none</cfif>"></span><span class="h5 ms-2">23/11/2025</span></h2>
                            </a>
                            <a href="/evento/2025-maratona-de-curitiba/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2><span class="h5 me-2">09.</span><span class="">Maratona de Curitiba <img src="/assets/verified.png" class="<cfif '2025-11-23' GT now()>d-none</cfif>"></span><span class="h5 ms-2">23/11/2025</span></h2>
                            </a>
                            <a href="/evento/2026-maratona-internacional-de-sao-paulo/" class="link-light link-opacity-50-hover" target="_blank">
                                <h2><span class="h5 me-2">10.</span><span class="">Maratona Intl. de SÃO PAULO <img src="/assets/verified.png" class="<cfif '2026-04-12' GT now()>d-none</cfif>"></span><span class="h5 ms-2">12/04/2026</span></h2>
                            </a>
                        </div>

                    </div>

                    <hr class="text-light">

                    <a id="ranking" class="position-absolute" style="margin-top:-120px;"></a>

                    <h2 class="text-light text-center olympikus display-2">RANKING SUPRA 2025</h2>

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
                                                <td><a href="/atleta/#qRankingSupraM.tag#/">#qRankingSupraM.name#</a><br/><small><a href="/evento/#qRankingSupraM.tag_evento#/?modalidade=#qRankingSupraM.modalidade#&genero=#qRankingSupraM.genero#" class="small">#qRankingSupraM.classificacao_sexo#º na #qRankingSupraM.nome_evento#</a></small></td>
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
                                                <td><a href="/atleta/#qRankingSupraF.tag#/">#qRankingSupraF.name#</a><br/><small><a href="/evento/#qRankingSupraF.tag_evento#/?modalidade=#qRankingSupraF.modalidade#&genero=#qRankingSupraF.genero#" class="small">#qRankingSupraF.classificacao_sexo#ª na #qRankingSupraF.nome_evento#</a></small></td>
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

                    <div class="col-12 px-3">
                        <a id="inscricao"></a>
                        <div class="row text-uppercase text-center text-white border border-2 border-warning rounded bg-black bg-opacity-25 my-5 p-4 g-3">
                            <div class="col-lg-6 m-0"><img src="../assets/images/supra_id.png?1" class="my-lg-n5 w-100"></div>
                            <div class="col-lg-6 m-0">
                                <h2 class="olympikus display-2 m-0">Corra!</h2>
                                <p class="m-0 px-lg-5">Você é atleta com registro ativo na CBAt? <br class="d-none d-md-block"/>Então inscreva-se, participe e faça parte.</p>
                                <a class="btn btn-light shadow-3 btn-rounded btn-lg my-3" href="../inscricao">Inscreva-se agora!</a>
                            <!---<a class="btn btn-secondary shadow-3 btn-rounded btn-lg my-3" href="#">em breve</a>--->
                            </div>
                        </div>
                    </div>

                    <!---<div class="text-center my-5">
                        <h2 class="text-light text-center fs-1 olympikus">O DESAFIO PREMIARÁ OS VENCEDORES COM BÔNUS EM DINHEIRO</h2>
                        <p class="text-light text-center">OS BRASILEIROS QUE ALCANÇAREM OS MELHORES TEMPOS DE MARATONAS SELECIONADAS NO BRASIL, TANTO NO MASCULINO QUANTO NO FEMININO, AO LONGO DE 2025 E UTILIZANDO OLYMPIKUS CORRE SUPRA, SERÃO PREMIADOS.</p>
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
