<cfparam name="URL.id_evento" type="numeric" default="22792"/>
<cfparam name="URL.percurso" type="numeric" default="42"/>
<cfparam name="URL.genero" type="string" default=""/>
<cfparam name="URL.categoria" type="string" default=""/>

<!---cfquery name="qEvento" datasource="runner_dba">
    select res.num_peito, lower(get_pais_padrao(res.nacionalidade)) as nacionalidade, res.nome, res.id_usuario, res.sexo,
    marca.tempo_total, ponto.distancia, res.id_categoria, usr.aka
    from tb_resultados_temp res
    inner join tb_leaderboard_marca marca on marca.num_peito = res.num_peito
    inner join tb_leaderboard_pc ponto on ponto.id_pc = marca.id_pc
    left join tb_usuarios usr on usr.id = res.id_usuario
    WHERE modalidade = '42K'
    <cfif len(trim(URL.genero))>
        and sexo = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.genero#"/>
    </cfif>
    <cfif len(trim(URL.ranking))>
        and id_categoria = <cfqueryparam cfsqltype="cf_sql_integer" value="1"/>
    </cfif>
    and res.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>
    order by marca.tempo_total
</cfquery--->

<cfquery name="qEvento" datasource="runner_dba">
    WITH ranked AS (
      SELECT
        res.num_peito,
        res.id_usuario,
        lower(get_pais_padrao(res.nacionalidade)) as nacionalidade,
        COALESCE(res.nome, usr.aka, res.nome) AS aka,
        COALESCE(res.nome, usr.aka, res.nome) AS nome,
        res.sexo,
        marca.tempo_total,
        ponto.distancia,
        ROW_NUMBER() OVER (
          PARTITION BY COALESCE(usr.aka, res.nome)
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
      aka,
      sexo,
      tempo_total,
      distancia
    FROM ranked
    WHERE rn = 1
    ORDER BY distancia DESC, tempo_total;
</cfquery>

<cfset VARIABLES.tempo_referencia = qEvento.tempo_total>
<cfset VARIABLES.ponto_referencia = qEvento.distancia>

<cfoutput query="qEvento">

    <cfset totalSeconds = datediff('s', ('2025-08-30 ' & VARIABLES.tempo_referencia), ('2025-08-30 ' & qEvento.tempo_total))>

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

    <cfset totalSecondsPace = datediff('s', ('2025-08-30 00:00:00'), ('2025-08-30 ' & qEvento.tempo_total))/qEvento.distancia>

    <cfset minutes = int((totalSecondsPace mod 3600) / 60)>
    <cfset seconds = totalSecondsPace mod 60>

    <cfset formattedPace =
        numberFormat(minutes, "00") & ":" &
        numberFormat(seconds, "00")>

    <cfelse>

        <cfset formattedPace = "00:00"/>

    </cfif>

    <tr onclick="carregarAthlete(#len(trim(qEvento.id_usuario)) ? qEvento.id_usuario : 0#)">
        <td class="text-center text-warning fw-bold" scope="row">#qEvento.currentrow#º</td> <!---POSICAO--->
        <td class="text-center fw-bold">#qEvento.num_peito#</td> <!---NUMERO DE PEITO--->
        <td title="#qEvento.nome#" class="">#qEvento.aka#</td> <!---NOME--->
        <td class="col-flag"><img src="//roadrunners.run/assets/flags/svg/#qEvento.nacionalidade#.svg" title="#uCase(qEvento.nacionalidade)#"></td> <!---NACIONALIDADE--->
        <td class="text-center">#qEvento.distancia#</td> <!---KM DA ULTIMA PARCIAL--->
        <!---<td class="text-end">#qEvento.tempo_total#</td> <!---RITMO MEDIO--->--->
        <td class="text-center col-pace">#formattedPace#</td>
        <td class="text-center col-gap">#formattedTime#</td>
    </tr>

    <!---tr>
        <td>#qEvento.currentrow#.</td>
        <td></td>
        <td>#qEvento.nacionalidade#</td>
        <td>#qEvento.nome#</td>
        <td>#qEvento.sexo#</td>
        <td>#qEvento.tempo_total#</td>
        <td>#qEvento.distancia#</td>
        <td>#formattedTime#</td>
    </tr--->

</cfoutput>
