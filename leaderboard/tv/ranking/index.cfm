<!DOCTYPE html>
<html lang="pt-br">

<cfparam name="URL.id_evento" type="numeric" default="22792"/>
<cfparam name="URL.percurso" type="numeric" default="21"/>
<cfparam name="URL.genero" type="string" default="M"/>
<cfparam name="URL.ponto_controle" type="string" default="21"/>

<head>
    <meta charset="UTF-8">
    <title>Road Runners - Race Board</title>
    <meta name="viewport" content="width=1024">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        .flag {
            width: 22px;
        }
    </style>
</head>

<body class="bg-transparent">

    <cfquery name="qEvento" datasource="runner_dba">
        WITH ranked AS (
          SELECT
            res.num_peito,
            res.id_usuario,
            lower(get_pais_padrao(res.nacionalidade)) as nacionalidade,
            COALESCE(res.nome, usr.aka, usr.name) AS nome,
            res.sexo,
            marca.tempo_total,
            ponto.distancia,
            ROW_NUMBER() OVER (
              PARTITION BY COALESCE(res.nome, usr.aka, usr.name)
              ORDER BY ponto.distancia DESC, marca.tempo_total
            ) AS rn
          FROM tb_resultados_temp res
          INNER JOIN tb_usuarios usr ON usr.id = res.id_usuario
          INNER JOIN tb_leaderboard_marca marca ON marca.num_peito = res.num_peito::int and marca.id_evento = res.id_evento::int
          INNER JOIN tb_leaderboard_pc ponto ON ponto.id_pc = marca.id_pc
          WHERE percurso = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.percurso#"/>
            <cfif len(trim(URL.genero))>
                and sexo = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.genero#"/>
            </cfif>
            and res.id_evento = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.id_evento#"/>
        )
        SELECT
          num_peito,
          id_usuario,
          nacionalidade,
          nome,
          sexo,
          tempo_total,
          distancia
        FROM ranked
        WHERE rn = 1
        ORDER BY distancia DESC, tempo_total
        LIMIT 5;
    </cfquery>

    <cfset VARIABLES.tempo_referencia = qEvento.tempo_total>
    <cfset VARIABLES.ponto_referencia = qEvento.distancia>

    <div class="card rounded-2 border border-1 border-white text-white mb-3" style="background-color:#2e3191; width: 500px">
        <div class="card-header text-center border-white">KM <cfoutput>#qEvento.distancia#</cfoutput> • CLASSIFICAÇÃO PARCIAL</div>
        <div class="card-header text-center h4 fw-bold"><cfoutput>#URL.percurso#</cfoutput>K ELITE <cfif URL.genero EQ 'M'>MASCULINA<cfelseif URL.genero EQ 'F'>FEMININA</cfif></div>
        <div class="card-body small p-0">
            <div class="row g-0 p-1 border-top border-1 border-white">
                <div class="col-1"></div>
                <div class="col-4">Atleta</div>
                <div class="col-1"></div>
                <div class="col-2 text-center">Tempo</div>
                <div class="col-2 text-center">Pace</div>
                <div class="col-2 text-center">Gap</div>
            </div>

            <cfoutput query="qEvento">

                <cfset totalSeconds = datediff('s', ('2025-07-27 ' & VARIABLES.tempo_referencia), ('2025-07-27 ' & qEvento.tempo_total))>

                <cfset hours   = int(totalSeconds / 3600)>
                <cfset minutes = int((totalSeconds mod 3600) / 60)>
                <cfset seconds = totalSeconds mod 60>

                <cfif VARIABLES.ponto_referencia EQ qEvento.distancia>

                    <cfset formattedTime =
                        (hours ? numberFormat(hours, "+00") & ":" : "+") &
                        numberFormat(minutes, "00") & ":" &
                        numberFormat(seconds, "00")>

                <cfelse>
                    <cfset formattedTime = "--:--"/>
                </cfif>

                <cfif qEvento.distancia GT 0>

            <cfset totalSecondsPace = datediff('s', ('2025-07-27 00:00:00'), ('2025-07-27 ' & qEvento.tempo_total))/qEvento.distancia>

            <cfset minutes = int((totalSecondsPace mod 3600) / 60)>
            <cfset seconds = totalSecondsPace mod 60>

            <cfset formattedPace =
                numberFormat(minutes, "00") & ":" &
                numberFormat(seconds, "00")>

            <cfelse>

                <cfset formattedPace = "00:00"/>

            </cfif>

                <!---record>
                    <posicao>#qEvento.currentrow#</posicao>
                    <num_peito>#qEvento.num_peito#</num_peito>
                    <bandeira>E:\bandeiras\#qEvento.nacionalidade#.png</bandeira>
                    <nacionalidade>#qEvento.nacionalidade#</nacionalidade>
                    <nome>#qEvento.nome#</nome>
                    <genero>#qEvento.sexo#</genero>
                    <tempo_total>#qEvento.tempo_total#</tempo_total>
                    <pace>#formattedPace#</pace>
                    <ponto_controle>#qEvento.distancia#</ponto_controle>
                    <gap>#formattedTime#</gap>
                </record--->

                <div class="row g-0 p-1 border-top border-1 border-white">
                    <div class="col-1 text-center">#qEvento.currentrow#º</div>
                    <div class="col-4">#left(qEvento.nome, 20)#</div>
                    <div class="col-1"><img src="//roadrunners.run/assets/flags/svg/#qEvento.nacionalidade#.svg" class="flag" title="BR"></div>
                    <div class="col-2 text-center">#qEvento.tempo_total#</div>
                    <div class="col-2 text-center">#formattedPace#</div>
                    <div class="col-2 text-center">#formattedTime#</div>
                </div>

            </cfoutput>

        </div>

        <div class="card-footer text-center border-white p-0">
            <svg id="Camada_2" data-name="Camada 2" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 336.39 47.13" height="12">
                <defs>
                    <style>
                        .cls-1 {
                            fill: #f4b120;
                        }

                        .cls-2 {
                            fill: #ffffff;
                        }
                    </style>
                </defs>
                <g id="Camada_1-2" data-name="Camada 1">
                    <g>
                        <path class="cls-2" d="M30.28,38.75c.07.17.1.35.1.56,0,.47-.3.71-.9.71h-9.06c-.33,0-.6-.08-.79-.25-.18-.18-.32-.5-.42-.96l-2.71-12.06c-.06-.18-.13-.3-.21-.38-.08-.08-.25-.13-.5-.13h-2.79c-.25,0-.43.05-.52.15-.1.08-.16.22-.19.42l-1.73,12.13c-.06.47-.2.77-.44.9-.24.13-.65.19-1.23.19H1.05c-.81,0-1.15-.48-1.02-1.46L4.59,6.16c.04-.34.11-.57.21-.67.11-.09.3-.15.58-.15h15.6c4.14,0,7.35.79,9.65,2.38,2.29,1.57,3.44,3.76,3.44,6.56,0,2.27-.67,4.36-2,6.29-1.32,1.93-3.04,3.32-5.15,4.17-.41.16-.65.29-.73.42-.07.13-.08.3-.02.52l4.1,13.06ZM18.61,19.29c1.28,0,2.34-.44,3.19-1.31.86-.88,1.29-1.89,1.29-3.04,0-.88-.32-1.53-.96-1.98-.64-.46-1.46-.69-2.46-.69h-4.75c-.22,0-.39.06-.48.19-.08.13-.16.38-.23.75l-.79,5.38v.23c0,.2.03.33.1.4.08.06.22.08.42.08h4.67Z"></path>
                        <path class="cls-2" d="M65.73,26.62c-.71,5.1-2.46,8.68-5.25,10.75-2.79,2.07-6.55,3.1-11.27,3.1s-8.17-.95-10.29-2.85c-2.11-1.92-3.17-4.76-3.17-8.54,0-1.03.11-2.34.33-3.96l2.65-18.96c.04-.34.11-.57.21-.67.11-.09.3-.15.58-.15h8.88c.29,0,.52.14.69.42.17.27.22.55.17.85l-2.81,20.19c-.13.99-.19,1.66-.19,2,0,1.53.34,2.62,1.02,3.27.69.66,1.71.98,3.04.98,1.72,0,3.19-.55,4.42-1.65,1.23-1.11,2.02-2.88,2.35-5.31l2.81-19.94c.03-.34.09-.57.21-.67.11-.09.3-.15.58-.15h7c.29,0,.52.14.69.42.17.27.22.55.17.85l-2.81,20Z"></path>
                        <path class="cls-2" d="M103.23,5.35c.44,0,.63.25.56.75l-4.71,33.35c-.03.22-.12.38-.27.46-.14.07-.36.1-.67.1h-6.4c-.22,0-.41-.07-.56-.21-.16-.14-.34-.38-.56-.73l-10.5-17.42c-.1-.15-.2-.23-.29-.23-.18,0-.29.2-.33.6l-2.42,17.08c-.03.38-.12.62-.27.73-.14.11-.43.17-.85.17h-6.73c-.58,0-.83-.4-.75-1.21l4.63-32.65c.04-.34.11-.57.23-.67.13-.09.36-.15.71-.15h7.63c.33,0,.59.09.79.27.21.17.42.44.65.81l9.1,15.5c.17.25.32.38.48.38.08,0,.17-.05.25-.15.08-.11.14-.26.17-.46l2.19-15.65c.04-.3.11-.5.23-.58.13-.08.36-.13.71-.13h7Z"></path>
                        <path class="cls-2" d="M138.77,5.35c.44,0,.63.25.56.75l-4.71,33.35c-.03.22-.12.38-.27.46-.14.07-.36.1-.67.1h-6.4c-.22,0-.41-.07-.56-.21-.16-.14-.34-.38-.56-.73l-10.5-17.42c-.1-.15-.2-.23-.29-.23-.18,0-.29.2-.33.6l-2.42,17.08c-.03.38-.12.62-.27.73-.14.11-.43.17-.85.17h-6.73c-.58,0-.83-.4-.75-1.21l4.63-32.65c.04-.34.11-.57.23-.67.13-.09.36-.15.71-.15h7.63c.33,0,.59.09.79.27.21.17.42.44.65.81l9.1,15.5c.17.25.32.38.48.38.08,0,.17-.05.25-.15.08-.11.14-.26.17-.46l2.19-15.65c.04-.3.11-.5.23-.58.13-.08.36-.13.71-.13h7Z"></path>
                        <path class="cls-2" d="M144.19,6.16c.04-.34.11-.57.21-.67.11-.09.3-.15.58-.15h25.42c.47,0,.71.29.71.85,0,.18-.02.32-.06.42l-.79,5.42c-.06.38-.17.64-.33.77-.16.14-.43.21-.83.21h-14.48c-.28,0-.49.06-.63.17-.14.11-.22.33-.25.67l-.6,4.31-.06.31c0,.17.04.27.13.31s.23.06.44.06h8.83c.3,0,.51.06.6.19.09.13.11.33.04.6l-.83,6.13c-.03.25-.09.42-.19.5-.1.07-.29.1-.56.1h-9.02c-.21,0-.36.06-.46.17-.1.11-.18.31-.23.58l-.67,4.63v.23c0,.25.11.38.33.38h15.56c.3,0,.51.06.6.19.09.13.11.36.04.71l-.79,6.02c-.07.28-.17.47-.29.58-.11.11-.35.17-.73.17h-25.15c-.41,0-.7-.08-.9-.25-.18-.18-.27-.44-.27-.77l.06-.44,4.56-32.4Z"></path>
                        <path class="cls-2" d="M201.21,38.75c.07.17.1.35.1.56,0,.47-.3.71-.9.71h-9.06c-.33,0-.6-.08-.79-.25-.18-.18-.32-.5-.42-.96l-2.71-12.06c-.06-.18-.13-.3-.21-.38-.08-.08-.25-.13-.5-.13h-2.79c-.25,0-.43.05-.52.15-.1.08-.16.22-.19.42l-1.73,12.13c-.06.47-.2.77-.44.9-.24.13-.65.19-1.23.19h-7.85c-.81,0-1.15-.48-1.02-1.46l4.56-32.4c.04-.34.11-.57.21-.67.11-.09.3-.15.58-.15h15.6c4.14,0,7.35.79,9.65,2.38,2.29,1.57,3.44,3.76,3.44,6.56,0,2.27-.67,4.36-2,6.29-1.32,1.93-3.04,3.32-5.15,4.17-.41.16-.65.29-.73.42-.07.13-.08.3-.02.52l4.1,13.06ZM189.55,19.29c1.28,0,2.34-.44,3.19-1.31.86-.88,1.29-1.89,1.29-3.04,0-.88-.32-1.53-.96-1.98-.64-.46-1.46-.69-2.46-.69h-4.75c-.22,0-.39.06-.48.19-.08.13-.16.38-.23.75l-.79,5.38v.23c0,.2.03.33.1.4.08.06.22.08.42.08h4.67Z"></path>
                        <path class="cls-2" d="M246.57,26.14c-.25,0-.45.07-.58.21s-.22.4-.25.77l-1.69,11.81c-.06.47-.18.77-.38.9-.18.13-.55.19-1.1.19h-8.19c-.41,0-.67-.03-.79-.1-.13-.08-.19-.25-.19-.5l.04-.42,4.63-32.83c.04-.34.11-.57.21-.67.11-.09.3-.15.58-.15h9.31c.18,0,.3.04.38.1.08.06.13.17.13.33,0,.16-.02.28-.04.38l-1.54,11.15-.04.29c0,.33.2.5.6.5h8.23c.4,0,.67-.4.79-1.21l1.54-10.83c.03-.28.1-.46.23-.56.13-.09.32-.15.6-.15h9.21c.18,0,.3.05.38.15.08.1.13.29.13.56,0,.25-.02.47-.04.65l-4.58,32.42c-.06.42-.14.68-.25.77-.11.08-.42.13-.92.13h-8.17c-.43,0-.74-.06-.94-.19-.18-.13-.27-.34-.27-.65,0-.19.01-.35.04-.48l1.69-12.15v-.08c0-.22-.24-.33-.71-.33h-8.04Z"></path>
                        <path class="cls-2" d="M300.28,26.62c-.71,5.1-2.46,8.68-5.25,10.75-2.79,2.07-6.55,3.1-11.27,3.1s-8.17-.95-10.29-2.85c-2.11-1.92-3.17-4.76-3.17-8.54,0-1.03.11-2.34.33-3.96l2.65-18.96c.04-.34.11-.57.21-.67.11-.09.3-.15.58-.15h8.88c.29,0,.52.14.69.42.17.27.22.55.17.85l-2.81,20.19c-.13.99-.19,1.66-.19,2,0,1.53.34,2.62,1.02,3.27.69.66,1.71.98,3.04.98,1.72,0,3.19-.55,4.42-1.65,1.23-1.11,2.02-2.88,2.35-5.31l2.81-19.94c.03-.34.09-.57.21-.67.11-.09.3-.15.58-.15h7c.29,0,.52.14.69.42.17.27.22.55.17.85l-2.81,20Z"></path>
                        <path class="cls-2" d="M303.7,40.02c-.25,0-.43-.05-.52-.17-.1-.11-.15-.29-.15-.54s.02-.45.06-.6l4.52-32.42c.03-.33.13-.57.31-.71.19-.15.46-.23.81-.23h13.92c4.46,0,7.86.71,10.21,2.13,2.34,1.42,3.52,3.47,3.52,6.15,0,4.06-2.41,6.89-7.23,8.5-.22.07-.35.16-.4.27-.03.1.05.18.25.25,2.08.72,3.59,1.65,4.54,2.77.96,1.11,1.44,2.51,1.44,4.19,0,3.93-1.48,6.66-4.44,8.17-2.96,1.5-6.79,2.25-11.5,2.25h-15.35ZM321.49,18.91c1.08,0,2.07-.4,2.98-1.21.9-.82,1.35-1.8,1.35-2.96,0-.75-.31-1.33-.92-1.75-.6-.42-1.41-.63-2.44-.63h-4.06c-.41,0-.7.07-.88.21-.17.14-.28.4-.33.77l-.6,4.81-.06.38c0,.16.04.26.13.31.08.04.21.06.4.06h4.44ZM319.3,33.02c.8,0,1.57-.2,2.31-.6.75-.42,1.36-.96,1.85-1.65.48-.68.73-1.44.73-2.29,0-.75-.29-1.33-.88-1.75-.57-.42-1.39-.63-2.44-.63h-4.63c-.32,0-.54.07-.67.21-.13.14-.22.39-.27.73l-.75,5.23-.04.33c0,.18.03.3.1.35.08.04.23.06.46.06h4.21Z"></path>
                    </g>
                    <g>
                        <path class="cls-1" d="M207.53,47.13c-.47,0-.82-.18-1.04-.52-.21-.33-.28-.77-.23-1.29L212.51.94c.05-.44.15-.71.27-.79.13-.09.4-.15.83-.15h4.33c.34,0,.63.13.83.38.22.25.3.52.25.79l-6.4,45.4c-.03.25-.09.4-.19.46-.08.07-.29.1-.6.1h-4.31Z"></path>
                        <path class="cls-1" d="M218.94,47.13c-.47,0-.82-.18-1.04-.52-.21-.33-.28-.77-.23-1.29L223.92.94c.05-.44.15-.71.27-.79.13-.09.4-.15.83-.15h4.33c.34,0,.63.13.83.38.22.25.3.52.25.79l-6.4,45.4c-.03.25-.09.4-.19.46-.08.07-.29.1-.6.1h-4.31Z"></path>
                    </g>
                </g>
            </svg>
        </div>

    </div>

    <!--<div class="card rounded-2 border border-1 border-white text-white" style="background-color:#2e3191; width: 400px">
        <div class="card-header text-center border-white">CLASSIFICAÇÃO FINAL</div>
        <div class="card-header text-center h4 fw-bold">42K ELITE MASCULINA</div>
        <div class="card-body small p-0">
            <div class="row g-0 p-1 border-top border-1 border-white">
                <div class="col-1"></div>
                <div class="col-8">Atleta</div>
                <div class="col-1"></div>
                <div class="col-2 text-center">Tempo</div>
            </div>
            <div class="row g-0 p-1 border-top border-1 border-white">
                <div class="col-1 text-center">1º</div>
                <div class="col-8">Wilson Mutua Maina</div>
                <div class="col-1"><img src="//roadrunners.run/assets/flags/svg/ke.svg" class="flag" title="BR"></div>
                <div class="col-2 text-center">01:04:42</div>
            </div>
            <div class="row g-0 p-1 border-top border-1 border-white">
                <div class="col-1 text-center">2º</div>
                <div class="col-8">Daniel Nascimento</div>
                <div class="col-1"><img src="//roadrunners.run/assets/flags/svg/br.svg" class="flag" title="BR"></div>
                <div class="col-2 text-center">01:08:06</div>
            </div>
            <div class="row g-0 p-1 border-top border-1 border-white">
                <div class="col-1 text-center">3º</div>
                <div class="col-8">Miguel Morone Neto</div>
                <div class="col-1"><img src="//roadrunners.run/assets/flags/svg/br.svg" class="flag" title="BR"></div>
                <div class="col-2 text-center">01:08:14</div>
            </div>
        </div>
    </div>-->

</body>
</html>
