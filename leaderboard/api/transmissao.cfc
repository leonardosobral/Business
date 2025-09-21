<cffunction name="ranking" returnType="xml" access="remote" output="false">
    <cfargument name="id_evento" type="numeric" default="22792"/>
    <cfargument name="genero" type="string" default=""/>
    <cfargument name="categoria" type="string" default=""/>
    <cfquery name="qEvento" datasource="runner_dba">
        WITH ranked AS (
          SELECT
            res.num_peito,
            res.nacionalidade,
            COALESCE(usr.aka, res.nome) AS nome,
            res.sexo,
            marca.tempo_total,
            ponto.distancia,
            ROW_NUMBER() OVER (
              PARTITION BY COALESCE(usr.aka, res.nome)
              ORDER BY ponto.distancia DESC, marca.tempo_total
            ) AS rn
          FROM tb_resultados_temp res
          INNER JOIN tb_usuarios usr ON usr.id = res.id_usuario
          INNER JOIN tb_leaderboard_marca marca ON marca.num_peito = res.num_peito
          INNER JOIN tb_leaderboard_pc ponto ON ponto.id_pc = marca.id_pc
          WHERE modalidade = '42K'
            <cfif len(trim(ARGUMENTS.genero))>
            and sexo = <cfqueryparam cfsqltype="cf_sql_varchar" value="#ARGUMENTS.genero#"/>
            </cfif>
            <cfif len(trim(ARGUMENTS.categoria))>
                and id_categoria = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.categoria#"/>
            </cfif>
            and res.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.id_evento#"/>
        )
        SELECT
          num_peito,
          nacionalidade,
          nome,
          sexo,
          tempo_total,
          distancia
        FROM ranked
        WHERE rn = 1
        ORDER BY distancia DESC, tempo_total;
    </cfquery>
    <!---cfquery name="qEvento" datasource="runner_dba">
        select res.num_peito, res.nacionalidade, COALESCE(usr.aka, res.nome) as nome, res.sexo,
        max(marca.tempo_total) as tempo_total, max(ponto.distancia) as distancia
        from tb_resultados_temp res
        inner join tb_usuarios usr on usr.id = res.id_usuario
        inner join tb_leaderboard_marca marca on marca.num_peito = res.num_peito
        inner join tb_leaderboard_pc ponto on ponto.id_pc = marca.id_pc
        WHERE modalidade = '42K'
        <cfif len(trim(ARGUMENTS.genero))>
            and sexo = <cfqueryparam cfsqltype="cf_sql_varchar" value="#ARGUMENTS.genero#"/>
        </cfif>
        <cfif len(trim(ARGUMENTS.categoria))>
            and id_categoria = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.categoria#"/>
        </cfif>
        and res.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.id_evento#"/>
        group by res.num_peito, res.nacionalidade, COALESCE(usr.aka, res.nome), res.sexo,
        marca.tempo_total, ponto.distancia
        order by ponto.distancia DESC, marca.tempo_total
    </cfquery--->
	<cfset var xml = "">
    <cfset var tempo_referencia = qEvento.tempo_total>
    <cfset var ponto_referencia = qEvento.distancia>
	<cfxml variable="xml">
		<list>
            <cfoutput query="qEvento">

                <cfset totalSeconds = datediff('s', ('2025-07-27 ' & tempo_referencia), ('2025-07-27 ' & qEvento.tempo_total))>

                <cfset hours   = int(totalSeconds / 3600)>
                <cfset minutes = int((totalSeconds mod 3600) / 60)>
                <cfset seconds = totalSeconds mod 60>

                <cfif ponto_referencia EQ qEvento.distancia>

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

                <record>
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
                </record>

            </cfoutput>
		</list>
	</cfxml>
	<cfreturn xml>
</cffunction>

<cffunction name="parciais" returnType="xml" access="remote" output="false">
    <cfargument name="id_evento" type="numeric" default="22792"/>
    <cfargument name="genero" type="string" default=""/>
    <cfargument name="categoria" type="string" default=""/>
    <cfquery name="qVencedor" datasource="runner_dba">
        WITH ranked AS (
          SELECT
            res.num_peito,
            res.nacionalidade,
            COALESCE(usr.aka, res.nome) AS nome,
            res.sexo,
            marca.tempo_total,
            ponto.distancia,
            ROW_NUMBER() OVER (
              PARTITION BY COALESCE(usr.aka, res.nome)
              ORDER BY ponto.distancia DESC, marca.tempo_total
            ) AS rn
          FROM tb_resultados_temp res
          INNER JOIN tb_usuarios usr ON usr.id = res.id_usuario
          INNER JOIN tb_leaderboard_marca marca ON marca.num_peito = res.num_peito
          INNER JOIN tb_leaderboard_pc ponto ON ponto.id_pc = marca.id_pc
          WHERE modalidade = '42K'
            <cfif len(trim(ARGUMENTS.genero))>
            and sexo = <cfqueryparam cfsqltype="cf_sql_varchar" value="#ARGUMENTS.genero#"/>
            </cfif>
            <cfif len(trim(ARGUMENTS.categoria))>
                and id_categoria = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.categoria#"/>
            </cfif>
            and res.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.id_evento#"/>
        )
        SELECT
          num_peito,
          nacionalidade,
          nome,
          sexo,
          tempo_total,
          distancia
        FROM ranked
        WHERE rn = 1
        ORDER BY distancia DESC, tempo_total;
    </cfquery>
    <cfquery name="qEvento" datasource="runner_dba">
        select COALESCE(marca.tempo_total,'00:00:00') as tempo_total, ponto.distancia, COALESCE(marca.tempo_total/ponto.distancia, '00:00')::time as pace
        from tb_leaderboard_pc ponto
        left join tb_leaderboard_marca marca on ponto.id_pc = marca.id_pc
        and marca.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.id_evento#"/>
        AND marca.num_peito = <cfqueryparam cfsqltype="cf_sql_integer" value="#qVencedor.num_peito#"/>
        AND ponto.distancia > 0
        order by ponto.distancia
    </cfquery>
	<cfset var xml = "">
	<cfxml variable="xml">
        <final>
            <list>
                <record>
                    <nome><cfoutput>#qVencedor.nome#</cfoutput></nome>
                </record>
                <cfoutput query="qEvento">
                    <record>
                        <tempo_total>#qEvento.tempo_total#</tempo_total>
                        <pace>#timeFormat(qEvento.pace, "mm:ss")#</pace>
                        <ponto_controle>#qEvento.distancia#</ponto_controle>
                    </record>
                </cfoutput>
            </list>
        </final>
	</cfxml>
	<cfreturn xml>
</cffunction>

<cffunction name="parcial" returnType="string" access="remote" output="false">
    <cfargument name="id_evento" type="numeric" default="22792"/>
    <cfargument name="genero" type="string" default=""/>
    <cfargument name="categoria" type="string" default=""/>
    <cfquery name="qEvento" datasource="runner_dba">
        select *
        from tb_leaderboard_evento levt
        where levt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.id_evento#"/>
    </cfquery>
    <cfquery name="qVencedor" datasource="runner_dba">
        WITH ranked AS (
          SELECT
            res.num_peito,
            res.nacionalidade,
            COALESCE(usr.aka, res.nome) AS nome,
            res.sexo,
            marca.tempo_total,
            ponto.distancia,
            ROW_NUMBER() OVER (
              PARTITION BY COALESCE(usr.aka, res.nome)
              ORDER BY ponto.distancia DESC, marca.tempo_total
            ) AS rn
          FROM tb_resultados_temp res
          INNER JOIN tb_usuarios usr ON usr.id = res.id_usuario
          INNER JOIN tb_leaderboard_marca marca ON marca.num_peito = res.num_peito
          INNER JOIN tb_leaderboard_pc ponto ON ponto.id_pc = marca.id_pc
          WHERE modalidade = '42K'
            <cfif len(trim(ARGUMENTS.genero))>
            and sexo = <cfqueryparam cfsqltype="cf_sql_varchar" value="#ARGUMENTS.genero#"/>
            </cfif>
            and res.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.id_evento#"/>
        )
        SELECT
          num_peito,
          nacionalidade,
          nome,
          sexo,
          tempo_total,
          distancia
        FROM ranked
        WHERE rn = 1
        ORDER BY distancia DESC, tempo_total
        LIMIT 1
    </cfquery>
    <cfquery name="qParcial" datasource="runner_dba">
        select COALESCE(marca.tempo_total,'00:00:00') as tempo_total,
        ponto.distancia,
        COALESCE(marca.tempo_total/ponto.distancia, '00:00')::time as pace,
        COALESCE((marca.tempo_total/ponto.distancia)*42.195, '00:00:00')::time as previsao_chegada
        from tb_leaderboard_pc ponto
        inner join tb_leaderboard_marca marca on ponto.id_pc = marca.id_pc
        and marca.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.id_evento#"/>
        AND marca.num_peito = <cfqueryparam cfsqltype="cf_sql_integer" value="#qVencedor.num_peito#"/>
        AND ponto.distancia > 0
        order by ponto.distancia desc
    </cfquery>
    <cfset var xml = "">
	<cfxml variable="xml">
        <cfoutput>
            <record>
                <tempo_prova>#qParcial.tempo_total#</tempo_prova>
                <largada>#timeFormat(qEvento.largada, "hh:mm:ss")#</largada>
                <previsao_chegada>#timeFormat(qParcial.previsao_chegada, "hh:mm:ss")#</previsao_chegada>
                <ritmo>#timeFormat(qParcial.pace, "mm:ss")#</ritmo>
                <cfif qParcial.recordcount GT 1>
                    <cfif qParcial.previsao_chegada[2] GT qParcial.previsao_chegada>
                        <variacao_previsao_chegada>-#timeFormat(qParcial.previsao_chegada[2]-qParcial.previsao_chegada, "mm:ss")#</variacao_previsao_chegada>
                    <cfelse>
                        <variacao_previsao_chegada>+#timeFormat(qParcial.previsao_chegada-qParcial.previsao_chegada[2], "mm:ss")#</variacao_previsao_chegada>
                    </cfif>
                <cfelse>
                    <variacao_previsao_chegada>--:--</variacao_previsao_chegada>
                </cfif>
                <distancia_percorrida>#qParcial.distancia#</distancia_percorrida>
            </record>
        </cfoutput>
	</cfxml>
	<cfreturn xml>
</cffunction>

<cffunction name="widget" returnType="string" access="remote" output="false">
    <cfargument name="id_evento" type="numeric" default="22792"/>
    <cfquery name="qEvento" datasource="runner_dba">
        select *
        from tb_leaderboard_evento levt
        where levt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.id_evento#"/>
    </cfquery>
    <cfset var xml = "">
	<cfxml variable="xml">
        <cfoutput>
            <record>
                <tempo_prova>00:33:43</tempo_prova>
                <largada>#timeFormat(qEvento.largada, "hh:mm:ss")#</largada>
                <distancia_percorrida>12.45</distancia_percorrida>
                <tempo>#qEvento.tempo#</tempo>
                <temperatura>#qEvento.temperatura#</temperatura>
                <vento>#qEvento.vento#</vento>
                <umidade>#qEvento.umidade#</umidade>
            </record>
        </cfoutput>
	</cfxml>
	<cfreturn xml>
</cffunction>



<cffunction name="startlist" returnType="xml" access="remote" output="false">
    <cfargument name="id_evento" type="numeric" default="22792"/>
    <cfargument name="genero" type="string" default=""/>
    <cfargument name="categoria" type="string" default=""/>
    <cfquery name="qEvento" datasource="runner_dba">
        select res.num_peito, res.nacionalidade, COALESCE(usr.aka, res.nome) as nome, res.sexo,
        usr.assessoria as equipe, usr.cidade, usr.estado, '00:00:00' as rp
        from tb_resultados_temp res
        inner join tb_usuarios usr on usr.id = res.id_usuario
        WHERE modalidade = '42K'
        <cfif len(trim(ARGUMENTS.genero))>
            and sexo = <cfqueryparam cfsqltype="cf_sql_varchar" value="#ARGUMENTS.genero#"/>
        </cfif>
        <cfif len(trim(ARGUMENTS.categoria))>
            and id_categoria = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.categoria#"/>
        </cfif>
        and res.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#ARGUMENTS.id_evento#"/>
        order by num_peito
    </cfquery>
	<cfset var xml = "">
	<cfxml variable="xml">
		<list>
            <cfoutput query="qEvento">
                <record>
                    <num_peito>#qEvento.num_peito#</num_peito>
                    <bandeira>E:\bandeiras\#qEvento.nacionalidade#.png</bandeira>
                    <nacionalidade>#qEvento.nacionalidade#</nacionalidade>
                    <nome>#qEvento.nome#</nome>
                    <genero>#qEvento.sexo#</genero>
                    <rp>#qEvento.rp#</rp>
                    <tempo_recente>#qEvento.rp#</tempo_recente>
                    <cidade>#qEvento.cidade#</cidade>
                    <estado>#qEvento.estado#</estado>
                    <equipe>#qEvento.equipe#</equipe>
                    <idade>XX</idade>
                    <altura>XX</altura>
                    <peso>XX</peso>
                </record>
            </cfoutput>
		</list>
	</cfxml>
	<cfreturn xml>
</cffunction>
