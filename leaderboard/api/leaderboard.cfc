<cffunction name="rankingToHTML" returnType="string" access="remote" output="false">
    <cfargument name="id_evento" type="numeric" default="22792"/>
    <cfargument name="genero" type="string" default=""/>
    <cfquery name="qEvento" datasource="runner_dba">
        select res.num_peito, res.nacionalidade, res.nome, res.sexo,
        marca.tempo_total, ponto.distancia
        from tb_resultados_temp res
        inner join tb_leaderboard_marca marca on marca.num_peito = res.num_peito
        inner join tb_leaderboard_pc ponto on ponto.id_pc = marca.id_pc
        WHERE modalidade = '42K'
        <cfif len(trim(ARGUMENTS.genero))>
            and sexo = <cfqueryparam cfsqltype="cf_sql_varchar" value="#ARGUMENTS.genero#"/>
        </cfif>
        and res.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.id_evento#"/>
        order by marca.tempo_total
    </cfquery>
    <cfset var ponto_referencia = qEvento.tempo_total>
    <cfset var html = ''>

        <cfloop query="qEvento">
            <cfset totalSeconds = datediff('s', ('2025-07-27 ' & ponto_referencia), ('2025-07-27 ' & qEvento.tempo_total))>

            <cfset hours   = int(totalSeconds / 3600)>
            <cfset minutes = int((totalSeconds mod 3600) / 60)>
            <cfset seconds = totalSeconds mod 60>

            <cfset formattedTime =
                (hours ? numberFormat(hours, "+00") & ":" : "+") &
                numberFormat(minutes, "00") & ":" &
                numberFormat(seconds, "00")>

            <cfset html = html & '
                <tr>
                    <td>#qEvento.currentrow#.</td>
                    <td>#qEvento.num_peito#</td>
                    <td>#qEvento.nacionalidade#</td>
                    <td>#qEvento.nome#</td>
                    <td>#qEvento.sexo#</td>
                    <td>#qEvento.tempo_total#</td>
                    <td>#qEvento.distancia#</td>
                    <td>#formattedTime#</td>
                </tr>
                '/>

        </cfloop>

	<cfreturn html>

</cffunction>

<cffunction name="raceresulttoavelar" returnType="xml" access="remote" output="false">
    <cfargument name="maxchars" type="numeric" default="32"/>
    <cfargument name="caps" type="boolean" default="false"/>
    <cfhttp result="resultado" url="#ARGUMENTS.url#"/>
	<cfset var xml = xmlTransform(XMLPARSE(resultado.filecontent),
      expandPath('xml-to-json.xsl')
   )/>
    <cfset arrResultados = deserializeJSON(xml).list.record/>
    <cfloop array="#arrResultados#" index="i">
        <cfif ARGUMENTS.caps>
            <cfset i.Name = left(ucase(i.Name),ARGUMENTS.maxchars)/>
        <cfelse>
            <cfset i.Name = left((i.Name),ARGUMENTS.maxchars)/>
        </cfif>
    </cfloop>
	<cfset var xml = "">
	<cfxml variable="xml">
		<list>
            <cfloop array="#arrResultados#" index="qEvento">
            <record>
                <cfoutput>
                <cfif isDefined("qEvento.Rank")><Rank>#qEvento.Rank#</Rank></cfif>
                <Nationality>#qEvento.Nationality#</Nationality>
                <cfif isDefined("qEvento.Gap")><Gap>#qEvento.Gap#</Gap></cfif>
                <cfif isDefined("qEvento.Time")><Time>#qEvento.Time#</Time></cfif>
                <Bib>#qEvento.Bib#</Bib>
                <cfif isDefined("qEvento.UCIid")><UCIid>#qEvento.UCIid#</UCIid></cfif>
                <Name>#qEvento.Name#</Name>
                </cfoutput>
            </record>
            </cfloop>
		</list>
	</cfxml>
	<cfreturn xml>
</cffunction>

<cffunction name="raceresult" returnType="string" access="remote" output="false">
    <cfhttp result="resultado" url="#ARGUMENTS.url#"/>
	<cfset var xml = xmlTransform(XMLPARSE(resultado.filecontent),
      expandPath('xml-to-json.xsl')
   )/>
    <cfset arrResultados = deserializeJSON(xml).list.record/>
	<cfreturn serializeJSON(arrResultados)>
</cffunction>
