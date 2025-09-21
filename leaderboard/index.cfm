<!DOCTYPE html>
<html lang="pt-br">

<cfparam name="URL.id_evento" type="numeric" default="22792"/>
<cfparam name="URL.percurso" type="numeric" default="42"/>

<cfquery name="qLBEvento" datasource="runner_dba">
    select perc.*, evt.nome_evento
    from tb_evento_corridas_percursos perc
    inner join tb_evento_corridas evt on perc.id_evento = evt.id_evento
    WHERE perc.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>
    and perc.percurso_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.percurso#"/>
</cfquery>

<head>
    <meta charset="UTF-8">
    <title>Road Runners - Race Board</title>
    <meta name="viewport" content="width=1024">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        /*Definições configuráveis*/


        :root {
            --leaderbord-width: 620px;
            --athleteprofile-height: 140px;
            --athletename-fontsize: 12px;
        }

        html {
            height: 100%;
            min-height: 100%;
            cursor: default;
        }
        body {
            background: #fafafa;
            height: 100vh;
            min-height: 100vh;
        }
        .main-row {
            height: 100vh;
            min-height: 100vh;
        }
        .col-fixed {
            width: var(--leaderbord-width);
            min-width: var(--leaderbord-width);
            max-width: var(--leaderbord-width);
            padding-right: 2px !important;
            background: #fafafa;
        }
        .darkbar-top {
            height: 40px;
            background: #343434;
            margin-bottom: 2px;
            border-radius: 3px;
        }
        .graybar {
            height: 32px;
            background: #848484;
            margin-bottom: 2px;
            border-radius: 3px;
        }
        .listtitle {
            height: 26px;
            background: #343434;
            margin-bottom: 2px;
            border-radius: 3px;
        }
        .list-left {
            padding-right:2px !important;
        }
        .list-right {
            padding-left:2px !important;
        }
        .row * {
            padding: 0;
        }
        .col-flex {
            background: #fff;
            padding-left: 2px;
        }
        .darkbar-right-top {
            height: 40px;
            background: #343434;
            margin-bottom: 2px;
            border-radius: 3px;
        }
        .graybar-right {
            height: 32px;
            background: #848484;
            margin-bottom: 2px;
            border-radius: 3px;
        }
        .big-darkbar {
            height: 38px;
            background: #343434;
            margin-bottom: 2px;
            margin-top: 2px;
            border-radius: 3px;
        }
        /* PRINCIPAL */
        .leaderboard-1 {
            background: #fff;
            min-height: 0;
            /*height: calc(50vh - 18px); !*COM PAN*! */
            height: calc(100vh - 180px); /*SEM PAN*/
        }
        /* PAN */
        .leaderboard-2 {
            background: #fff;
            min-height: 0;
            height: calc(50vh - 200px);
        }
        .area-branca {
            background: #fff;
            min-height: 0;
            height: calc(50vh - 109px);
        }
        .area-branca-dir {
            background: #fff;
            min-height: 0;
            height: calc(100vh - 112px);
        }
        .startlist-min {
            background: #fff;
            min-height: 0;
            height: calc(100vh - 344px - var(--athleteprofile-height));
        }
        .listed {}
        .listed-selected td {
            background-color: var(--bs-warning) ;
        }
        .divAthlete {
            position: absolute;
            bottom: 4px;
            right: 4px;
            background: #fff;
            min-height: 0;
            width: calc(100% - var(--leaderbord-width) - 6px) !important;
        }
        .atleteprofile {
            height: var(--athleteprofile-height);
        }
        .invert-color {
            filter: invert(100%);
        }
        .cursor-pointer {
            cursor: pointer;
        }
        /* Ajuste para o espaçamento mínimo das bordas */
        .borda-2px {
            border-right: 2px solid #fff;
        }
        .table {
            font-size: var(--athletename-fontsize);
            margin-bottom: 0;
        }
        th {
            position: sticky;
            top: 0;
        }
        td {
            cursor: pointer !important;
        }
        .table-sm>:not(caption)>*>* {
            padding: .25rem .05rem;
        }
        .col-pace, .col-gap {
            width: 44px;
            max-width: 44px;
            overflow: hidden;
        }
        .col-flag {
            width: 20px;
        }
        .col-flag img {
            width: 20px;
        }
        .lastraces {
            height: 190px;
            max-height: 190px;
            overflow: hidden;
        }
        /*TIMER*/
           .timer {
               background: -webkit-linear-gradient(left, #fab120 50%, #666 50%);
               border-radius: 100%;
               height: calc(var(--size) * 1px);
               width: calc(var(--size) * 1px);
               position: absolute;
               top: 12px;
               left: calc(var(--leaderbord-width) - 36px);
               -webkit-animation: time calc(var(--duration) * 1s) steps(1000, start) infinite;
               -webkit-mask: radial-gradient(transparent 50%,#000 50%);
               mask: radial-gradient(transparent 50%,#000 50%);
           }
        .mask {
            border-radius: 100% 0 0 100% / 50% 0 0 50%;
            height: 100%;
            left: 0;
            position: absolute;
            top: 0;
            width: 50%;
            -webkit-animation: mask calc(var(--duration) * 1s) steps(500, start) infinite;
            -webkit-transform-origin: 100% 50%;
        }
        @-webkit-keyframes time {
            100% {
                -webkit-transform: rotate(360deg);
            }
        }
        @-webkit-keyframes mask {
            0% {
                background: #666;
                -webkit-transform: rotate(0deg);
            }
            50% {
                background: #666;
                -webkit-transform: rotate(-180deg);
            }
            50.01% {
                background: #fab120;
                -webkit-transform: rotate(0deg);
            }
            100% {
                background: #fab120;
                -webkit-transform: rotate(-180deg);
            }
        }
    </style>
</head>

<body>

<div class="container-fluid gx-0">

    <div class="row main-row gx-0">

        <!-- Coluna Esquerda - Largura Fixa -->

        <div class="col-fixed d-flex flex-column border-end border-1 border-dark p-1">

            <div class="darkbar-top w-100 text-center align-content-center">
                <svg xmlns="http://www.w3.org/2000/svg" class="float-start ms-1" xmlns:xlink="http://www.w3.org/1999/xlink" width="32" zoomAndPan="magnify" viewBox="0 0 120.75 141.749996" height="32" preserveAspectRatio="xMidYMid meet" version="1.2"><defs/><g id="9010597adc"><g style="fill:#ffffff;fill-opacity:1;"><g transform="translate(10.920228, 116.104309)"><path style="stroke:none" d="M 15.125 -15.015625 C 14.851562 -15.015625 14.640625 -14.9375 14.484375 -14.78125 C 14.335938 -14.632812 14.25 -14.359375 14.21875 -13.953125 L 12.390625 -1.15625 C 12.328125 -0.65625 12.191406 -0.335938 11.984375 -0.203125 C 11.785156 -0.0664062 11.378906 0 10.765625 0 L 1.921875 0 C 1.484375 0 1.195312 -0.0390625 1.0625 -0.125 C 0.925781 -0.207031 0.859375 -0.382812 0.859375 -0.65625 L 0.90625 -1.109375 L 5.921875 -36.671875 C 5.953125 -37.035156 6.023438 -37.269531 6.140625 -37.375 C 6.265625 -37.476562 6.476562 -37.53125 6.78125 -37.53125 L 16.84375 -37.53125 C 17.039062 -37.53125 17.179688 -37.492188 17.265625 -37.421875 C 17.359375 -37.359375 17.40625 -37.242188 17.40625 -37.078125 C 17.40625 -36.910156 17.382812 -36.773438 17.34375 -36.671875 L 15.671875 -24.578125 L 15.625 -24.28125 C 15.625 -23.90625 15.84375 -23.71875 16.28125 -23.71875 L 25.1875 -23.71875 C 25.625 -23.71875 25.910156 -24.15625 26.046875 -25.03125 L 27.71875 -36.765625 C 27.75 -37.066406 27.832031 -37.269531 27.96875 -37.375 C 28.101562 -37.476562 28.320312 -37.53125 28.625 -37.53125 L 38.59375 -37.53125 C 38.789062 -37.53125 38.929688 -37.476562 39.015625 -37.375 C 39.097656 -37.269531 39.140625 -37.066406 39.140625 -36.765625 C 39.140625 -36.492188 39.125 -36.257812 39.09375 -36.0625 L 34.140625 -0.96875 C 34.078125 -0.519531 33.984375 -0.242188 33.859375 -0.140625 C 33.742188 -0.046875 33.414062 0 32.875 0 L 24.03125 0 C 23.550781 0 23.207031 -0.0664062 23 -0.203125 C 22.800781 -0.335938 22.703125 -0.570312 22.703125 -0.90625 C 22.703125 -1.113281 22.722656 -1.285156 22.765625 -1.421875 L 24.578125 -14.5625 L 24.578125 -14.671875 C 24.578125 -14.898438 24.328125 -15.015625 23.828125 -15.015625 Z M 15.125 -15.015625 "/></g></g><g style="fill:#ffffff;fill-opacity:1;"><g transform="translate(19.31153, 65.652103)"><path style="stroke:none" d="M 33.734375 -1.359375 C 33.804688 -1.191406 33.84375 -0.992188 33.84375 -0.765625 C 33.84375 -0.253906 33.519531 0 32.875 0 L 23.0625 0 C 22.6875 0 22.398438 -0.09375 22.203125 -0.28125 C 22.003906 -0.46875 21.851562 -0.8125 21.75 -1.3125 L 18.8125 -14.359375 C 18.75 -14.566406 18.675781 -14.710938 18.59375 -14.796875 C 18.507812 -14.878906 18.332031 -14.921875 18.0625 -14.921875 L 15.015625 -14.921875 C 14.742188 -14.921875 14.554688 -14.867188 14.453125 -14.765625 C 14.359375 -14.660156 14.296875 -14.507812 14.265625 -14.3125 L 12.390625 -1.15625 C 12.328125 -0.65625 12.164062 -0.335938 11.90625 -0.203125 C 11.65625 -0.0664062 11.210938 0 10.578125 0 L 2.078125 0 C 1.203125 0 0.832031 -0.519531 0.96875 -1.5625 L 5.921875 -36.671875 C 5.953125 -37.035156 6.023438 -37.269531 6.140625 -37.375 C 6.265625 -37.476562 6.476562 -37.53125 6.78125 -37.53125 L 23.671875 -37.53125 C 28.148438 -37.53125 31.628906 -36.675781 34.109375 -34.96875 C 36.585938 -33.269531 37.828125 -30.90625 37.828125 -27.875 C 37.828125 -25.40625 37.109375 -23.125 35.671875 -21.03125 C 34.242188 -18.945312 32.382812 -17.445312 30.09375 -16.53125 C 29.65625 -16.363281 29.394531 -16.210938 29.3125 -16.078125 C 29.226562 -15.941406 29.21875 -15.757812 29.28125 -15.53125 Z M 21.09375 -22.453125 C 22.476562 -22.453125 23.632812 -22.921875 24.5625 -23.859375 C 25.488281 -24.804688 25.953125 -25.90625 25.953125 -27.15625 C 25.953125 -28.101562 25.601562 -28.820312 24.90625 -29.3125 C 24.21875 -29.800781 23.332031 -30.046875 22.25 -30.046875 L 17.09375 -30.046875 C 16.851562 -30.046875 16.679688 -29.976562 16.578125 -29.84375 C 16.484375 -29.707031 16.40625 -29.4375 16.34375 -29.03125 L 15.484375 -23.21875 L 15.484375 -22.96875 C 15.484375 -22.757812 15.523438 -22.617188 15.609375 -22.546875 C 15.691406 -22.484375 15.832031 -22.453125 16.03125 -22.453125 Z M 21.09375 -22.453125 "/></g></g><g style="fill:#f4b120;fill-opacity:1;"><g transform="translate(58.537533, 101.958999)"><path style="stroke:none" d="M 2.09375 14.4375 C 1.21875 14.4375 0.578125 14.113281 0.171875 13.46875 C -0.234375 12.832031 -0.378906 12.015625 -0.265625 11.015625 L 11.453125 -72.34375 C 11.578125 -73.15625 11.753906 -73.648438 11.984375 -73.828125 C 12.210938 -74.003906 12.738281 -74.09375 13.5625 -74.09375 L 21.6875 -74.09375 C 22.332031 -74.09375 22.859375 -73.859375 23.265625 -73.390625 C 23.671875 -72.921875 23.816406 -72.425781 23.703125 -71.90625 L 11.71875 13.375 C 11.664062 13.84375 11.550781 14.132812 11.375 14.25 C 11.195312 14.375 10.816406 14.4375 10.234375 14.4375 Z M 2.09375 14.4375 "/></g></g><g style="fill:#f4b120;fill-opacity:1;"><g transform="translate(79.967559, 101.958999)"><path style="stroke:none" d="M 2.09375 14.4375 C 1.21875 14.4375 0.578125 14.113281 0.171875 13.46875 C -0.234375 12.832031 -0.378906 12.015625 -0.265625 11.015625 L 11.453125 -72.34375 C 11.578125 -73.15625 11.753906 -73.648438 11.984375 -73.828125 C 12.210938 -74.003906 12.738281 -74.09375 13.5625 -74.09375 L 21.6875 -74.09375 C 22.332031 -74.09375 22.859375 -73.859375 23.265625 -73.390625 C 23.671875 -72.921875 23.816406 -72.425781 23.703125 -71.90625 L 11.71875 13.375 C 11.664062 13.84375 11.550781 14.132812 11.375 14.25 C 11.195312 14.375 10.816406 14.4375 10.234375 14.4375 Z M 2.09375 14.4375 "/></g></g></g></svg>
                <h4 class="text-light text-uppercase fw-bold fst-italic m-0">
                    Leaderboard <cfoutput>#URL.percurso#</cfoutput>k
                </h4>
                <span id="timer" class="d-none">60</span>
                <div class="timer" style="--duration: 60;--size: 24;">
                    <div class="mask"></div>
                </div>
            </div>

            <div class="graybar bg-light w-100 text-center align-content-center">
                <h4 class="text-dark text-uppercase fw-bold m-0"><img src="assets/images/ico_time.svg" style="width:18px" class="invert-color pb-1"> 00:00:00</h4>
            </div>

            <div class="row m-0">

                <!---LEADERBOARD MASC--->
                <div class="col-6 list-left border-end border-1 border-warning">
                    <div class="graybar w-100 text-center align-content-center"><h5 class="text-light text-uppercase fw-bold m-0"><img src="assets/images/ico_record.svg" style="width:18px" class="pb-1"> <cfoutput>#qLBEvento.rp_m#</cfoutput></h5></div>
                    <div class="graybar w-100 text-center align-content-center"><h5 class="text-light text-uppercase fw-bold m-0"><img src="assets/images/ico_champs.svg" style="width:18px" class="pb-1"> 0:00:00</h5></div>
                    <div class="listtitle w-100 text-center align-content-center"><h6 class="text-light m-0"><img src="assets/images/ico_mens.svg" style="width:13px" class="pb-1">  Mens</h6></div>
                    <div class="leaderboard-1 flex-grow-1 w-100 overflow-auto">
                        <table class="table table-sm table-striped table-hover">
                            <thead class="thead-dark">
                                <tr>
                                    <th scope="col" class="text-center">POS</th>
                                    <th scope="col" class="text-center">BIB</th>
                                    <th scope="col">ATHLETE</th>
                                    <th scope="col"></th>
                                    <th scope="col" class="text-center">KM</th>
                                    <th scope="col" class="text-center col-pace">PACE</th>
                                    <th scope="col" class="text-center col-gap">GAP</th>
                                </tr>
                            </thead>
                            <tbody id="divRankingM">
                                <!---tr>
                                    <th class="text-center" scope="row">1</th> <!---POSICAO--->
                                    <td class="text-center">1</td> <!---NUMERO DE PEITO--->
                                    <td>Name Lastname</td> <!---NOME--->
                                    <td><img src="//roadrunners.run/assets/flags/w20/br.png" title="BRASIL"></td> <!---NACIONALIDADE--->
                                    <td class="text-end">00:00</td> <!---RITMO MEDIO--->
                                </tr--->
                            </tbody>
                        </table>
                    </div>
                </div>

                <!---LEADERBOARD FEM--->
                <div class="col-6 list-right">
                    <div class="graybar w-100 text-center align-content-center"><h5 class="text-light text-uppercase fw-bold m-0"><img src="assets/images/ico_record.svg" style="width:18px" class="pb-1"> <cfoutput>#qLBEvento.rp_f#</cfoutput></h5></div>
                    <div class="graybar w-100 text-center align-content-center"><h5 class="text-light text-uppercase fw-bold m-0"><img src="assets/images/ico_champs.svg" style="width:18px" class="pb-1"> 0:00:00</h5></div>
                    <div class="listtitle w-100 text-center align-content-center"><h6 class="text-light m-0"><img src="assets/images/ico_womens.svg" style="width:13px" class="pb-1">  Womens</h6></div>
                    <div class="leaderboard-1 flex-grow-1 w-100 overflow-auto">
                        <table class="table table-sm table-striped table-hover">
                            <thead class="thead-dark">
                                <tr>
                                    <th scope="col" class="text-center">POS</th>
                                    <th scope="col" class="text-center">BIB</th>
                                    <th scope="col">ATHLETE</th>
                                    <th scope="col"></th>
                                    <th scope="col" class="text-center">KM</th>
                                    <th scope="col" class="text-center col-pace">PACE</th>
                                    <th scope="col" class="text-center col-gap">GAP</th>
                                </tr>
                            </thead>
                            <tbody id="divRankingF">
                            <!---tr>
                                <th class="text-center" scope="row">1</th> <!---POSICAO--->
                                <td class="text-center">1</td> <!---NUMERO DE PEITO--->
                                <td>Name Lastname</td> <!---NOME--->
                                <td><img src="//roadrunners.run/assets/flags/w20/br.png" title="BRASIL"></td> <!---NACIONALIDADE--->
                                <td class="text-end">00:00</td> <!---RITMO MEDIO--->
                            </tr--->
                            </tbody>
                        </table>
                    </div>
                </div>

            </div>

            <!---<div class="row m-0">
                <!---LEADERBOARD MASC PAN--->
                <div class="col-6 list-left border-end border-1 border-warning">
                    <div class="listtitle w-100 text-center align-content-center"><h6 class="text-light m-0"><img src="assets/images/ico_mens.svg" style="width:13px" class="pb-1"> Pan-Americans</h6></div>
                    <div class="leaderboard-2 flex-grow-1 w-100 overflow-auto">
                        <table class="table table-sm table-striped table-hover">
                            <thead class="thead-dark">
                                <tr>
                                    <th scope="col" class="text-center">POS</th>
                                    <th scope="col" class="text-center">BIB</th>
                                    <th scope="col">ATHLETE</th>
                                    <th scope="col"></th>
                                    <th scope="col" class="text-center">KM</th>
                                    <th scope="col" class="text-center col-pace">PACE</th>
                                    <th scope="col" class="text-center col-gap">GAP</th>
                                </tr>
                            </thead>
                            <tbody id="divRankingMPan">
                                <!---tr>
                                    <th class="text-center" scope="row">1</th> <!---POSICAO--->
                                    <td class="text-center">1</td> <!---NUMERO DE PEITO--->
                                    <td>Name Lastname</td> <!---NOME--->
                                    <td><img src="//roadrunners.run/assets/flags/w20/br.png" title="BRASIL"></td> <!---NACIONALIDADE--->
                                    <td class="text-end">00:00</td> <!---RITMO MEDIO--->
                                </tr--->
                            </tbody>
                        </table>
                    </div>
                </div>
                <!---LEADERBOARD FEM PAN--->
                <div class="col-6 list-right">
                    <div class="listtitle w-100 text-center align-content-center"><h6 class="text-light m-0"><img src="assets/images/ico_womens.svg" style="width:13px" class="pb-1"> Pan-Americans</h6></div>
                    <div class="leaderboard-2 flex-grow-1 w-100 overflow-auto">
                        <table class="table table-sm table-striped table-hover">
                            <thead class="thead-dark">
                                <tr>
                                    <th scope="col" class="text-center">POS</th>
                                    <th scope="col" class="text-center">BIB</th>
                                    <th scope="col">ATHLETE</th>
                                    <th scope="col"></th>
                                    <th scope="col" class="text-center">KM</th>
                                    <th scope="col" class="text-center col-pace">PACE</th>
                                    <th scope="col" class="text-center col-gap">GAP</th>
                                </tr>
                            </thead>
                            <tbody id="divRankingFPan">
                                <!---tr>
                                    <th class="text-center" scope="row">1</th> <!---POSICAO--->
                                    <td class="text-center">1</td> <!---NUMERO DE PEITO--->
                                    <td>Name Lastname</td> <!---NOME--->
                                    <td><img src="//roadrunners.run/assets/flags/w20/br.png" title="BRASIL"></td> <!---NACIONALIDADE--->
                                    <td class="text-end">00:00</td> <!---RITMO MEDIO--->
                                </tr--->
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>--->

        </div>

        <!-- Coluna Direita - Responsiva -->

        <div class="col col-flex d-flex flex-column py-1 pe-1">

            <div class="darkbar-right-top w-100 text-center align-content-center">
                <svg xmlns="http://www.w3.org/2000/svg" class="position-absolute top-1 end-0 me-2" xmlns:xlink="http://www.w3.org/1999/xlink" zoomAndPan="magnify" viewBox="0 0 269.25 56.999997" width="150" preserveAspectRatio="xMidYMid meet" version="1.2">
                    <defs></defs>
                    <g id="e75d27301e">
                        <g style="fill:#ffffff;fill-opacity:1;">
                            <g transform="translate(7.431296, 40.790583)">
                                <path style="stroke:none" d="M 23.359375 -0.953125 C 23.410156 -0.828125 23.4375 -0.6875 23.4375 -0.53125 C 23.4375 -0.175781 23.210938 0 22.765625 0 L 15.96875 0 C 15.71875 0 15.519531 -0.0625 15.375 -0.1875 C 15.238281 -0.320312 15.132812 -0.5625 15.0625 -0.90625 L 13.03125 -9.953125 C 12.988281 -10.085938 12.9375 -10.179688 12.875 -10.234375 C 12.8125 -10.296875 12.6875 -10.328125 12.5 -10.328125 L 10.40625 -10.328125 C 10.21875 -10.328125 10.085938 -10.289062 10.015625 -10.21875 C 9.941406 -10.15625 9.894531 -10.050781 9.875 -9.90625 L 8.578125 -0.8125 C 8.535156 -0.457031 8.425781 -0.234375 8.25 -0.140625 C 8.070312 -0.046875 7.765625 0 7.328125 0 L 1.4375 0 C 0.832031 0 0.578125 -0.363281 0.671875 -1.09375 L 4.09375 -25.390625 C 4.125 -25.648438 4.175781 -25.816406 4.25 -25.890625 C 4.332031 -25.960938 4.476562 -26 4.6875 -26 L 16.390625 -26 C 19.492188 -26 21.90625 -25.40625 23.625 -24.21875 C 25.34375 -23.039062 26.203125 -21.398438 26.203125 -19.296875 C 26.203125 -17.597656 25.703125 -16.023438 24.703125 -14.578125 C 23.710938 -13.128906 22.425781 -12.085938 20.84375 -11.453125 C 20.539062 -11.335938 20.359375 -11.234375 20.296875 -11.140625 C 20.242188 -11.046875 20.238281 -10.914062 20.28125 -10.75 Z M 14.609375 -15.546875 C 15.566406 -15.546875 16.363281 -15.875 17 -16.53125 C 17.644531 -17.1875 17.96875 -17.945312 17.96875 -18.8125 C 17.96875 -19.46875 17.726562 -19.960938 17.25 -20.296875 C 16.769531 -20.640625 16.15625 -20.8125 15.40625 -20.8125 L 11.84375 -20.8125 C 11.675781 -20.8125 11.554688 -20.765625 11.484375 -20.671875 C 11.421875 -20.578125 11.363281 -20.390625 11.3125 -20.109375 L 10.71875 -16.078125 L 10.71875 -15.90625 C 10.71875 -15.757812 10.742188 -15.660156 10.796875 -15.609375 C 10.859375 -15.566406 10.960938 -15.546875 11.109375 -15.546875 Z M 14.609375 -15.546875 "></path>
                            </g>
                        </g>
                        <g style="fill:#ffffff;fill-opacity:1;">
                            <g transform="translate(33.317082, 40.790583)">
                                <path style="stroke:none" d="M 24.0625 -10.046875 C 23.53125 -6.222656 22.21875 -3.535156 20.125 -1.984375 C 18.03125 -0.429688 15.210938 0.34375 11.671875 0.34375 C 8.117188 0.34375 5.546875 -0.367188 3.953125 -1.796875 C 2.367188 -3.234375 1.578125 -5.367188 1.578125 -8.203125 C 1.578125 -8.972656 1.660156 -9.960938 1.828125 -11.171875 L 3.8125 -25.390625 C 3.84375 -25.648438 3.894531 -25.816406 3.96875 -25.890625 C 4.050781 -25.960938 4.195312 -26 4.40625 -26 L 11.0625 -26 C 11.28125 -26 11.453125 -25.894531 11.578125 -25.6875 C 11.703125 -25.488281 11.742188 -25.273438 11.703125 -25.046875 L 9.59375 -9.90625 C 9.5 -9.164062 9.453125 -8.664062 9.453125 -8.40625 C 9.453125 -7.257812 9.707031 -6.441406 10.21875 -5.953125 C 10.738281 -5.460938 11.5 -5.21875 12.5 -5.21875 C 13.789062 -5.21875 14.894531 -5.628906 15.8125 -6.453125 C 16.738281 -7.285156 17.328125 -8.613281 17.578125 -10.4375 L 19.6875 -25.390625 C 19.707031 -25.648438 19.757812 -25.816406 19.84375 -25.890625 C 19.925781 -25.960938 20.070312 -26 20.28125 -26 L 25.53125 -26 C 25.75 -26 25.921875 -25.894531 26.046875 -25.6875 C 26.171875 -25.488281 26.210938 -25.273438 26.171875 -25.046875 Z M 24.0625 -10.046875 "></path>
                            </g>
                        </g>
                        <g style="fill:#ffffff;fill-opacity:1;">
                            <g transform="translate(58.817557, 40.790583)">
                                <path style="stroke:none" d="M 26.6875 -26 C 27.019531 -26 27.160156 -25.8125 27.109375 -25.4375 L 23.578125 -0.421875 C 23.554688 -0.253906 23.488281 -0.140625 23.375 -0.078125 C 23.269531 -0.0234375 23.101562 0 22.875 0 L 18.078125 0 C 17.910156 0 17.769531 -0.0507812 17.65625 -0.15625 C 17.539062 -0.257812 17.398438 -0.441406 17.234375 -0.703125 L 9.359375 -13.765625 C 9.285156 -13.878906 9.210938 -13.9375 9.140625 -13.9375 C 9.003906 -13.9375 8.921875 -13.785156 8.890625 -13.484375 L 7.078125 -0.671875 C 7.054688 -0.390625 6.988281 -0.207031 6.875 -0.125 C 6.769531 -0.0390625 6.554688 0 6.234375 0 L 1.1875 0 C 0.75 0 0.5625 -0.300781 0.625 -0.90625 L 4.09375 -25.390625 C 4.125 -25.648438 4.179688 -25.816406 4.265625 -25.890625 C 4.359375 -25.960938 4.535156 -26 4.796875 -26 L 10.515625 -26 C 10.765625 -26 10.960938 -25.929688 11.109375 -25.796875 C 11.265625 -25.671875 11.425781 -25.46875 11.59375 -25.1875 L 18.421875 -13.5625 C 18.546875 -13.375 18.664062 -13.28125 18.78125 -13.28125 C 18.84375 -13.28125 18.90625 -13.316406 18.96875 -13.390625 C 19.03125 -13.472656 19.070312 -13.585938 19.09375 -13.734375 L 20.734375 -25.46875 C 20.765625 -25.695312 20.820312 -25.84375 20.90625 -25.90625 C 21 -25.96875 21.175781 -26 21.4375 -26 Z M 26.6875 -26 "></path>
                            </g>
                        </g>
                        <g style="fill:#ffffff;fill-opacity:1;">
                            <g transform="translate(85.473962, 40.790583)">
                                <path style="stroke:none" d="M 26.6875 -26 C 27.019531 -26 27.160156 -25.8125 27.109375 -25.4375 L 23.578125 -0.421875 C 23.554688 -0.253906 23.488281 -0.140625 23.375 -0.078125 C 23.269531 -0.0234375 23.101562 0 22.875 0 L 18.078125 0 C 17.910156 0 17.769531 -0.0507812 17.65625 -0.15625 C 17.539062 -0.257812 17.398438 -0.441406 17.234375 -0.703125 L 9.359375 -13.765625 C 9.285156 -13.878906 9.210938 -13.9375 9.140625 -13.9375 C 9.003906 -13.9375 8.921875 -13.785156 8.890625 -13.484375 L 7.078125 -0.671875 C 7.054688 -0.390625 6.988281 -0.207031 6.875 -0.125 C 6.769531 -0.0390625 6.554688 0 6.234375 0 L 1.1875 0 C 0.75 0 0.5625 -0.300781 0.625 -0.90625 L 4.09375 -25.390625 C 4.125 -25.648438 4.179688 -25.816406 4.265625 -25.890625 C 4.359375 -25.960938 4.535156 -26 4.796875 -26 L 10.515625 -26 C 10.765625 -26 10.960938 -25.929688 11.109375 -25.796875 C 11.265625 -25.671875 11.425781 -25.46875 11.59375 -25.1875 L 18.421875 -13.5625 C 18.546875 -13.375 18.664062 -13.28125 18.78125 -13.28125 C 18.84375 -13.28125 18.90625 -13.316406 18.96875 -13.390625 C 19.03125 -13.472656 19.070312 -13.585938 19.09375 -13.734375 L 20.734375 -25.46875 C 20.765625 -25.695312 20.820312 -25.84375 20.90625 -25.90625 C 21 -25.96875 21.175781 -26 21.4375 -26 Z M 26.6875 -26 "></path>
                            </g>
                        </g>
                        <g style="fill:#ffffff;fill-opacity:1;">
                            <g transform="translate(112.130367, 40.790583)">
                                <path style="stroke:none" d="M 4.09375 -25.390625 C 4.125 -25.648438 4.175781 -25.816406 4.25 -25.890625 C 4.332031 -25.960938 4.476562 -26 4.6875 -26 L 23.75 -26 C 24.101562 -26 24.28125 -25.785156 24.28125 -25.359375 C 24.28125 -25.222656 24.265625 -25.117188 24.234375 -25.046875 L 23.640625 -20.984375 C 23.597656 -20.703125 23.515625 -20.507812 23.390625 -20.40625 C 23.273438 -20.300781 23.066406 -20.25 22.765625 -20.25 L 11.90625 -20.25 C 11.695312 -20.25 11.539062 -20.207031 11.4375 -20.125 C 11.332031 -20.039062 11.269531 -19.875 11.25 -19.625 L 10.796875 -16.390625 L 10.75 -16.15625 C 10.75 -16.03125 10.78125 -15.953125 10.84375 -15.921875 C 10.90625 -15.890625 11.015625 -15.875 11.171875 -15.875 L 17.796875 -15.875 C 18.023438 -15.875 18.175781 -15.828125 18.25 -15.734375 C 18.320312 -15.640625 18.332031 -15.488281 18.28125 -15.28125 L 17.65625 -10.6875 C 17.632812 -10.5 17.585938 -10.375 17.515625 -10.3125 C 17.441406 -10.257812 17.300781 -10.234375 17.09375 -10.234375 L 10.328125 -10.234375 C 10.171875 -10.234375 10.054688 -10.191406 9.984375 -10.109375 C 9.910156 -10.023438 9.851562 -9.878906 9.8125 -9.671875 L 9.3125 -6.203125 L 9.3125 -6.03125 C 9.3125 -5.84375 9.394531 -5.75 9.5625 -5.75 L 21.234375 -5.75 C 21.460938 -5.75 21.613281 -5.703125 21.6875 -5.609375 C 21.757812 -5.515625 21.769531 -5.335938 21.71875 -5.078125 L 21.125 -0.5625 C 21.070312 -0.351562 21 -0.207031 20.90625 -0.125 C 20.820312 -0.0390625 20.640625 0 20.359375 0 L 1.5 0 C 1.195312 0 0.972656 -0.0625 0.828125 -0.1875 C 0.691406 -0.320312 0.625 -0.515625 0.625 -0.765625 L 0.671875 -1.09375 Z M 4.09375 -25.390625 "></path>
                            </g>
                        </g>
                        <g style="fill:#ffffff;fill-opacity:1;">
                            <g transform="translate(135.634244, 40.790583)">
                                <path style="stroke:none" d="M 23.359375 -0.953125 C 23.410156 -0.828125 23.4375 -0.6875 23.4375 -0.53125 C 23.4375 -0.175781 23.210938 0 22.765625 0 L 15.96875 0 C 15.71875 0 15.519531 -0.0625 15.375 -0.1875 C 15.238281 -0.320312 15.132812 -0.5625 15.0625 -0.90625 L 13.03125 -9.953125 C 12.988281 -10.085938 12.9375 -10.179688 12.875 -10.234375 C 12.8125 -10.296875 12.6875 -10.328125 12.5 -10.328125 L 10.40625 -10.328125 C 10.21875 -10.328125 10.085938 -10.289062 10.015625 -10.21875 C 9.941406 -10.15625 9.894531 -10.050781 9.875 -9.90625 L 8.578125 -0.8125 C 8.535156 -0.457031 8.425781 -0.234375 8.25 -0.140625 C 8.070312 -0.046875 7.765625 0 7.328125 0 L 1.4375 0 C 0.832031 0 0.578125 -0.363281 0.671875 -1.09375 L 4.09375 -25.390625 C 4.125 -25.648438 4.175781 -25.816406 4.25 -25.890625 C 4.332031 -25.960938 4.476562 -26 4.6875 -26 L 16.390625 -26 C 19.492188 -26 21.90625 -25.40625 23.625 -24.21875 C 25.34375 -23.039062 26.203125 -21.398438 26.203125 -19.296875 C 26.203125 -17.597656 25.703125 -16.023438 24.703125 -14.578125 C 23.710938 -13.128906 22.425781 -12.085938 20.84375 -11.453125 C 20.539062 -11.335938 20.359375 -11.234375 20.296875 -11.140625 C 20.242188 -11.046875 20.238281 -10.914062 20.28125 -10.75 Z M 14.609375 -15.546875 C 15.566406 -15.546875 16.363281 -15.875 17 -16.53125 C 17.644531 -17.1875 17.96875 -17.945312 17.96875 -18.8125 C 17.96875 -19.46875 17.726562 -19.960938 17.25 -20.296875 C 16.769531 -20.640625 16.15625 -20.8125 15.40625 -20.8125 L 11.84375 -20.8125 C 11.675781 -20.8125 11.554688 -20.765625 11.484375 -20.671875 C 11.421875 -20.578125 11.363281 -20.390625 11.3125 -20.109375 L 10.71875 -16.078125 L 10.71875 -15.90625 C 10.71875 -15.757812 10.742188 -15.660156 10.796875 -15.609375 C 10.859375 -15.566406 10.960938 -15.546875 11.109375 -15.546875 Z M 14.609375 -15.546875 "></path>
                            </g>
                        </g>
                        <g style="fill:#ffffff;fill-opacity:1;">
                            <g transform="translate(161.520763, 40.790583)">
                                <path style="stroke:none" d=""></path>
                            </g>
                        </g>
                        <g style="fill:#ffffff;fill-opacity:1;">
                            <g transform="translate(168.526388, 40.790583)">
                                <path style="stroke:none" d=""></path>
                            </g>
                        </g>
                        <g style="fill:#ffffff;fill-opacity:1;">
                            <g transform="translate(175.532012, 40.790583)">
                                <path style="stroke:none" d=""></path>
                            </g>
                        </g>
                        <g style="fill:#ffffff;fill-opacity:1;">
                            <g transform="translate(182.541047, 40.790583)">
                                <path style="stroke:none" d="M 10.46875 -10.40625 C 10.28125 -10.40625 10.132812 -10.351562 10.03125 -10.25 C 9.925781 -10.144531 9.863281 -9.953125 9.84375 -9.671875 L 8.578125 -0.8125 C 8.535156 -0.457031 8.441406 -0.234375 8.296875 -0.140625 C 8.160156 -0.046875 7.882812 0 7.46875 0 L 1.328125 0 C 1.023438 0 0.828125 -0.0234375 0.734375 -0.078125 C 0.640625 -0.140625 0.59375 -0.265625 0.59375 -0.453125 L 0.625 -0.765625 L 4.09375 -25.390625 C 4.125 -25.648438 4.175781 -25.816406 4.25 -25.890625 C 4.332031 -25.960938 4.476562 -26 4.6875 -26 L 11.671875 -26 C 11.804688 -26 11.898438 -25.972656 11.953125 -25.921875 C 12.015625 -25.878906 12.046875 -25.796875 12.046875 -25.671875 C 12.046875 -25.554688 12.035156 -25.460938 12.015625 -25.390625 L 10.859375 -17.03125 L 10.828125 -16.8125 C 10.828125 -16.5625 10.976562 -16.4375 11.28125 -16.4375 L 17.453125 -16.4375 C 17.753906 -16.4375 17.953125 -16.738281 18.046875 -17.34375 L 19.203125 -25.46875 C 19.222656 -25.675781 19.28125 -25.816406 19.375 -25.890625 C 19.46875 -25.960938 19.617188 -26 19.828125 -26 L 26.734375 -26 C 26.867188 -26 26.960938 -25.960938 27.015625 -25.890625 C 27.078125 -25.816406 27.109375 -25.675781 27.109375 -25.46875 C 27.109375 -25.28125 27.097656 -25.117188 27.078125 -24.984375 L 23.640625 -0.671875 C 23.597656 -0.359375 23.535156 -0.164062 23.453125 -0.09375 C 23.367188 -0.03125 23.140625 0 22.765625 0 L 16.640625 0 C 16.316406 0 16.082031 -0.046875 15.9375 -0.140625 C 15.800781 -0.234375 15.734375 -0.394531 15.734375 -0.625 C 15.734375 -0.769531 15.742188 -0.890625 15.765625 -0.984375 L 17.03125 -10.09375 L 17.03125 -10.15625 C 17.03125 -10.320312 16.851562 -10.40625 16.5 -10.40625 Z M 10.46875 -10.40625 "></path>
                            </g>
                        </g>
                        <g style="fill:#ffffff;fill-opacity:1;">
                            <g transform="translate(209.232478, 40.790583)">
                                <path style="stroke:none" d="M 24.0625 -10.046875 C 23.53125 -6.222656 22.21875 -3.535156 20.125 -1.984375 C 18.03125 -0.429688 15.210938 0.34375 11.671875 0.34375 C 8.117188 0.34375 5.546875 -0.367188 3.953125 -1.796875 C 2.367188 -3.234375 1.578125 -5.367188 1.578125 -8.203125 C 1.578125 -8.972656 1.660156 -9.960938 1.828125 -11.171875 L 3.8125 -25.390625 C 3.84375 -25.648438 3.894531 -25.816406 3.96875 -25.890625 C 4.050781 -25.960938 4.195312 -26 4.40625 -26 L 11.0625 -26 C 11.28125 -26 11.453125 -25.894531 11.578125 -25.6875 C 11.703125 -25.488281 11.742188 -25.273438 11.703125 -25.046875 L 9.59375 -9.90625 C 9.5 -9.164062 9.453125 -8.664062 9.453125 -8.40625 C 9.453125 -7.257812 9.707031 -6.441406 10.21875 -5.953125 C 10.738281 -5.460938 11.5 -5.21875 12.5 -5.21875 C 13.789062 -5.21875 14.894531 -5.628906 15.8125 -6.453125 C 16.738281 -7.285156 17.328125 -8.613281 17.578125 -10.4375 L 19.6875 -25.390625 C 19.707031 -25.648438 19.757812 -25.816406 19.84375 -25.890625 C 19.925781 -25.960938 20.070312 -26 20.28125 -26 L 25.53125 -26 C 25.75 -26 25.921875 -25.894531 26.046875 -25.6875 C 26.171875 -25.488281 26.210938 -25.273438 26.171875 -25.046875 Z M 24.0625 -10.046875 "></path>
                            </g>
                        </g>
                        <g style="fill:#ffffff;fill-opacity:1;">
                            <g transform="translate(234.732953, 40.790583)">
                                <path style="stroke:none" d="M 1.125 0 C 0.9375 0 0.804688 -0.0390625 0.734375 -0.125 C 0.660156 -0.207031 0.625 -0.34375 0.625 -0.53125 C 0.625 -0.71875 0.640625 -0.867188 0.671875 -0.984375 L 4.0625 -25.296875 C 4.082031 -25.546875 4.160156 -25.722656 4.296875 -25.828125 C 4.441406 -25.941406 4.644531 -26 4.90625 -26 L 15.34375 -26 C 18.6875 -26 21.238281 -25.46875 23 -24.40625 C 24.757812 -23.34375 25.640625 -21.804688 25.640625 -19.796875 C 25.640625 -16.753906 23.832031 -14.628906 20.21875 -13.421875 C 20.050781 -13.367188 19.953125 -13.300781 19.921875 -13.21875 C 19.898438 -13.144531 19.960938 -13.082031 20.109375 -13.03125 C 21.671875 -12.488281 22.804688 -11.796875 23.515625 -10.953125 C 24.234375 -10.117188 24.59375 -9.070312 24.59375 -7.8125 C 24.59375 -4.863281 23.484375 -2.820312 21.265625 -1.6875 C 19.046875 -0.5625 16.171875 0 12.640625 0 Z M 14.46875 -15.828125 C 15.28125 -15.828125 16.023438 -16.128906 16.703125 -16.734375 C 17.378906 -17.347656 17.71875 -18.085938 17.71875 -18.953125 C 17.71875 -19.515625 17.488281 -19.953125 17.03125 -20.265625 C 16.582031 -20.578125 15.972656 -20.734375 15.203125 -20.734375 L 12.15625 -20.734375 C 11.851562 -20.734375 11.632812 -20.679688 11.5 -20.578125 C 11.375 -20.472656 11.289062 -20.28125 11.25 -20 L 10.796875 -16.390625 L 10.75 -16.109375 C 10.75 -15.992188 10.78125 -15.914062 10.84375 -15.875 C 10.90625 -15.84375 11.003906 -15.828125 11.140625 -15.828125 Z M 12.828125 -5.25 C 13.429688 -5.25 14.007812 -5.398438 14.5625 -5.703125 C 15.125 -6.015625 15.585938 -6.425781 15.953125 -6.9375 C 16.316406 -7.445312 16.5 -8.019531 16.5 -8.65625 C 16.5 -9.21875 16.28125 -9.65625 15.84375 -9.96875 C 15.414062 -10.28125 14.804688 -10.4375 14.015625 -10.4375 L 10.546875 -10.4375 C 10.304688 -10.4375 10.140625 -10.382812 10.046875 -10.28125 C 9.953125 -10.175781 9.882812 -9.992188 9.84375 -9.734375 L 9.28125 -5.8125 L 9.25 -5.5625 C 9.25 -5.425781 9.273438 -5.335938 9.328125 -5.296875 C 9.390625 -5.265625 9.503906 -5.25 9.671875 -5.25 Z M 12.828125 -5.25 "></path>
                            </g>
                        </g>
                        <g style="fill:#f4b120;fill-opacity:1;">
                            <g transform="translate(162.891715, 40.354679)">
                                <path style="stroke:none" d="M 0.84375 5.765625 C 0.488281 5.765625 0.226562 5.632812 0.0625 5.375 C -0.09375 5.125 -0.148438 4.800781 -0.109375 4.40625 L 4.578125 -28.875 C 4.617188 -29.207031 4.6875 -29.40625 4.78125 -29.46875 C 4.875 -29.539062 5.082031 -29.578125 5.40625 -29.578125 L 8.65625 -29.578125 C 8.914062 -29.578125 9.125 -29.484375 9.28125 -29.296875 C 9.445312 -29.109375 9.507812 -28.910156 9.46875 -28.703125 L 4.671875 5.34375 C 4.648438 5.53125 4.601562 5.644531 4.53125 5.6875 C 4.46875 5.738281 4.316406 5.765625 4.078125 5.765625 Z M 0.84375 5.765625 "></path>
                            </g>
                        </g>
                        <g style="fill:#f4b120;fill-opacity:1;">
                            <g transform="translate(171.44819, 40.354679)">
                                <path style="stroke:none" d="M 0.84375 5.765625 C 0.488281 5.765625 0.226562 5.632812 0.0625 5.375 C -0.09375 5.125 -0.148438 4.800781 -0.109375 4.40625 L 4.578125 -28.875 C 4.617188 -29.207031 4.6875 -29.40625 4.78125 -29.46875 C 4.875 -29.539062 5.082031 -29.578125 5.40625 -29.578125 L 8.65625 -29.578125 C 8.914062 -29.578125 9.125 -29.484375 9.28125 -29.296875 C 9.445312 -29.109375 9.507812 -28.910156 9.46875 -28.703125 L 4.671875 5.34375 C 4.648438 5.53125 4.601562 5.644531 4.53125 5.6875 C 4.46875 5.738281 4.316406 5.765625 4.078125 5.765625 Z M 0.84375 5.765625 "></path>
                            </g>
                        </g>
                    </g>
                </svg>
                <h4 class="text-light text-uppercase fw-bold fst-italic m-0">Data Board</h4>
            </div>

            <div class="graybar-right w-100 text-center align-content-center">
                <a href="/leaderboard/?percurso=21"><button class="btn btn-sm px-4 py-0 <cfif URL.percurso EQ '21'>btn-warning<cfelse>btn-light</cfif>">21k</button></a>
                <a href="/leaderboard/?percurso=42"><button class="btn btn-sm px-4 py-0 <cfif URL.percurso EQ '42'>btn-warning<cfelse>btn-light</cfif>">42k</button></a> |
                <button class="btn btn-sm btn-warning px-4 py-0" onclick="carregaStartlist()">Elite Start List</button>
                <button class="btn btn-sm btn-light px-4 py-0 disabled">General Start List</button>
                <button class="btn btn-sm btn-light px-4 py-0 disabled">Finisher Board</button>
                <button class="btn btn-sm btn-light px-4 py-0 disabled">Results</button>
            </div>

            <div id="startlist" class="area-branca-dir w-100">
                <div class="row m-0">

                    <cfquery name="qLBCountM" datasource="runner_dba">
                        select res.num_peito
                        from tb_resultados_temp res
                        left join tb_usuarios usr on usr.id = res.id_usuario
                        WHERE percurso = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.percurso#"/>
                        and sexo = <cfqueryparam cfsqltype="cf_sql_varchar" value="M"/>
                        and res.id_evento = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.id_evento#"/>
                    </cfquery>

                    <div class="col-6 list-left border-end border-1 border-warning">
                        <div class="listtitle w-100 text-center align-content-center"><h6 class="text-light m-0"><img src="assets/images/ico_mens.svg" style="width:13px" class="pb-1"> Mens (<cfoutput>#qLBCountM.recordcount#</cfoutput>)</h6></div>
                            <div id="startlist-m" class="area-branca-dir flex-grow-1 w-100 overflow-auto">
                                <table class="table table-sm table-striped table-hover">
                                    <thead class="thead-dark">
                                        <tr>
                                            <th scope="col" class="text-center">BIB</th>
                                            <th scope="col">ATHLETE</th>
                                            <th scope="col"></th>
                                            <th scope="col" style="width:60px" class="text-center">PB</th>
                                        </tr>
                                    </thead>
                                    <tbody id="divRankingMStartlist">
                                        <!---tr>
                                            <td class="text-center">1</td> <!---BIBERO DE PEITO--->
                                            <td>Name Lastname - Team/Club - Location</td> <!---NOME--->
                                            <td><img src="//roadrunners.run/assets/flags/w20/br.png" title="BRASIL"></td> <!---NACIONALIDADE--->
                                            <td class="text-end">00:00:00</td> <!---RECORDE PESSOAL--->
                                        </tr--->
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        <cfquery name="qLBCountF" datasource="runner_dba">
                            select res.num_peito
                            from tb_resultados_temp res
                            left join tb_usuarios usr on usr.id = res.id_usuario
                            WHERE percurso = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.percurso#"/>
                            and sexo = <cfqueryparam cfsqltype="cf_sql_varchar" value="F"/>
                            and res.id_evento = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.id_evento#"/>
                        </cfquery>

                        <div class="col-6 list-right">
                        <div class="listtitle w-100 text-center align-content-center"><h6 class="text-light m-0"><img src="assets/images/ico_womens.svg" style="width:13px" class="pb-1"> Womens (<cfoutput>#qLBCountF.recordcount#</cfoutput>)</h6></div>
                        <div id="startlist-w" class="area-branca-dir flex-grow-1 w-100 overflow-auto">
                            <table class="table table-sm table-striped table-hover">
                                <thead class="thead-dark">
                                <tr>
                                    <th scope="col" class="text-center">BIB</th>
                                    <th scope="col">ATHLETE</th>
                                    <th scope="col"></th>
                                    <th scope="col" style="width:60px" class="text-center">PB</th>
                                </tr>
                                </thead>
                                <tbody id="divRankingFStartlist">
                                    <!---tr>
                                        <td class="text-center">1</td> <!---BIBERO DE PEITO--->
                                        <td>Name Lastname - Team/Club - Location</td> <!---NOME--->
                                        <td><img src="//roadrunners.run/assets/flags/w20/br.png" title="BRASIL"></td> <!---NACIONALIDADE--->
                                        <td class="text-end">00:00:00</td> <!---RECORDE PESSOAL--->
                                    </tr--->
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            <!--- PROFILE --->
            <div id="divAthlete" class="divAthlete flex-grow-1 w-100">

            </div>

        </div>

    </div>

</div>

  <script>
    let minutosRestantes = 60; // tempo em minutos
    const timerEl = document.getElementById("timer");
    const tbodyElM = document.getElementById("divRankingM");
    const tbodyElF = document.getElementById("divRankingF");
    const tbodyElMPan = document.getElementById("divRankingMPan");
    const tbodyElFPan = document.getElementById("divRankingFPan");
    const tbodyElMStartlist = document.getElementById("divRankingMStartlist");
    const tbodyElFStartlist = document.getElementById("divRankingFStartlist");
    const divAthlete = document.getElementById("divAthlete");

    // Timer regressivo que chama fetch ao fim
    function iniciarTimer() {
      atualizarContador();
      const intervalo = setInterval(() => {
        minutosRestantes--;
        atualizarContador();

        if (minutosRestantes <= 0) {
          clearInterval(intervalo);
          atualizarTabela();
          carregaStartlist();
          minutosRestantes = 60;
          iniciarTimer(); // reinicia o ciclo
        }
      }, 1000); // a cada minuto
    }

    // Atualiza o contador visual
    function atualizarContador() {
      timerEl.textContent = minutosRestantes;
    }

    // Atualiza o contador visual
    async function carregarAthlete(id_usuario) {
        try {
        const resposta = await fetch("/leaderboard/fetch/athlete.cfm?percurso=<cfoutput>#URL.percurso#</cfoutput>&id_usuario=" + id_usuario); // coloque sua URL real aqui
        const html = await resposta.text(); // espera resposta como HTML
        divAthlete.innerHTML = html; // injeta no tbody
        document.getElementById("startlist").classList.remove("area-branca-dir");
        document.getElementById("startlist-m").classList.remove("area-branca-dir");
        document.getElementById("startlist-w").classList.remove("area-branca-dir");
        document.getElementById("startlist").classList.add("startlist-min");
        document.getElementById("startlist-m").classList.add("startlist-min");
        document.getElementById("startlist-w").classList.add("startlist-min");
        const collection = document.getElementsByTagName("tr");
        for (let i = 0; i < collection.length; i++) {
            collection[i].classList.remove("listed-selected");
        }
        document.getElementById(id_usuario).classList.add("listed-selected");
        document.getElementById("divAthlete").style.display="block";
        console.log("Ficha atualizada.");
      } catch (erro) {
        console.error("Erro ao buscar dados:", erro);
      }
    }

    function descarregarAthlete() {
            document.getElementById("startlist").classList.remove("startlist-min");
            document.getElementById("startlist-m").classList.remove("startlist-min");
            document.getElementById("startlist-w").classList.remove("startlist-min");
            document.getElementById("startlist").classList.add("area-branca-dir");
            document.getElementById("startlist-m").classList.add("area-branca-dir");
            document.getElementById("startlist-w").classList.add("area-branca-dir");
            const collection = document.getElementsByTagName("tr");
            for (let i = 0; i < collection.length; i++) {
                collection[i].classList.remove("listed-selected");
            }
            document.getElementById("divAthlete").style.display="none";
        }

    // Faz fetch do HTML e injeta no tbody
    async function atualizarTabela() {
      try {
        const resposta = await fetch("/leaderboard/fetch/leaderboard.cfm?percurso=<cfoutput>#URL.percurso#</cfoutput>&genero=M"); // coloque sua URL real aqui
        const html = await resposta.text(); // espera resposta como HTML
        tbodyElM.innerHTML = html; // injeta no tbody
        console.log("Tabela atualizada.");
      } catch (erro) {
        console.error("Erro ao buscar dados:", erro);
      }
      try {
        const resposta = await fetch("/leaderboard/fetch/leaderboard.cfm?percurso=<cfoutput>#URL.percurso#</cfoutput>&genero=F"); // coloque sua URL real aqui
        const html = await resposta.text(); // espera resposta como HTML
        tbodyElF.innerHTML = html; // injeta no tbody
        console.log("Tabela atualizada.");
      } catch (erro) {
        console.error("Erro ao buscar dados:", erro);
      }

      // Exibe coluna PACE e oculta coluna GAP no carregamento
      document.querySelectorAll('.col-pace').forEach(cell => cell.style.display = '');
      document.querySelectorAll('.col-gap').forEach(cell => cell.style.display = 'none');
    }

    // Faz fetch do HTML e injeta no tbody
    async function carregaStartlist() {
      try {
        const resposta = await fetch("/leaderboard/fetch/startlist.cfm?percurso=<cfoutput>#URL.percurso#</cfoutput>&genero=M"); // coloque sua URL real aqui
        const html = await resposta.text(); // espera resposta como HTML
        tbodyElMStartlist.innerHTML = html; // injeta no tbody
        console.log("Tabela atualizada.");
      } catch (erro) {
        console.error("Erro ao buscar dados:", erro);
      }
      try {
        const resposta = await fetch("/leaderboard/fetch/startlist.cfm?percurso=<cfoutput>#URL.percurso#</cfoutput>&genero=F"); // coloque sua URL real aqui
        const html = await resposta.text(); // espera resposta como HTML
        tbodyElFStartlist.innerHTML = html; // injeta no tbody
        console.log("Tabela atualizada.");
      } catch (erro) {
        console.error("Erro ao buscar dados:", erro);
      }
    }

    // Alternador das colunas de PACE e GAP no Leaderbord
    let mostrarPace = true;

    function alternarColunas() {
        document.querySelectorAll('.col-pace').forEach(function(cell) {
            cell.style.display = mostrarPace ? '' : 'none';
        });
        document.querySelectorAll('.col-gap').forEach(function(cell) {
            cell.style.display = mostrarPace ? 'none' : '';
        });
        mostrarPace = !mostrarPace;
    }

    // Primeira execução
    iniciarTimer();
    atualizarTabela(); // também atualiza logo no início
    carregaStartlist(); // também atualiza logo no início
    alternarColunas(); // também alterna logo no início

    // Inicia temporizadores diferentes
    setInterval(alternarColunas, 3000);
    // 05:10:05

  </script>

</body>
</html>
