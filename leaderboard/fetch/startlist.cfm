<cfparam name="URL.id_evento" type="numeric" default="22792"/>
<cfparam name="URL.percurso" type="numeric" default="42"/>
<cfparam name="URL.genero" type="string" default=""/>
<cfparam name="URL.ranking" type="string" default=""/>
<cfquery name="qEvento" datasource="runner_dba">
    select res.num_peito, lower(get_pais_padrao(res.nacionalidade)) as nacionalidade,
    res.nome, res.sexo,
    usr.id as id_usuario, usr.cidade, usr.estado, usr.assessoria,
    COALESCE(
        (
            SELECT elem
            FROM jsonb_array_elements(usr.rp) elem
            WHERE (elem ->> 'percurso')::int = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.percurso#"/>
            LIMIT 1
        ),
        '{}'::jsonb
    ) AS rp
    from tb_resultados_temp res
    left join tb_usuarios usr on usr.id = res.id_usuario
    WHERE percurso = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.percurso#"/>
    <cfif len(trim(URL.genero))>
        and sexo = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.genero#"/>
    </cfif>
    <cfif len(trim(URL.ranking))>
        and nacionalidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="BRA"/>
    </cfif>
    and res.id_evento = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.id_evento#"/>
    ORDER BY
    (
        SELECT (elem ->> 'tempo_total')::time
        FROM jsonb_array_elements(usr.rp) elem
        WHERE (elem ->> 'percurso')::int = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.percurso#"/>
        ORDER BY (elem ->> 'tempo_total')::time ASC
        LIMIT 1
    ) ASC NULLS LAST, num_peito ASC;
</cfquery>

<cfoutput query="qEvento">

    <tr onclick="carregarAthlete(#len(trim(qEvento.id_usuario)) ? qEvento.id_usuario : 0#)" class="listed" id="#qEvento.id_usuario#">
        <td class="text-center fw-bold lh-sm">#qEvento.num_peito#</td> <!---NUMERO DE PEITO--->
        <!---<td>#qEvento.nome# - #qEvento.assessoria# - #qEvento.cidade# #qEvento.estado#</td> <!---NOME--->--->

        <!--- NOME --->
        <td class="lh-sm">
            #qEvento.nome#
            <!---<br><span class="small opacity-50"><cfif len(trim(qEvento.cidade))>#qEvento.cidade#</cfif><cfif len(trim(qEvento.estado))>/#qEvento.estado#</cfif>&nbsp;</span>--->
        </td>

        <!--- NACIONALIDADE --->
        <td class="col-flag"><img src="//roadrunners.run/assets/flags/svg/#qEvento.nacionalidade#.svg" title="#uCase(qEvento.nacionalidade)#"></td>

        <!--- RECORDE PESSOAL --->
        <cfset VARIABLES.rp = deserializeJSON(qEvento.rp)/>
        <td class="text-center">
            #isDefined("VARIABLES.rp.tempo_total") ? VARIABLES.rp.tempo_total : "00:00:00"#
        </td>
    </tr>

</cfoutput>
