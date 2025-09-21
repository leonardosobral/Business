<cfhttp result="resultado" url="https://resultadoseventosapi.runking.com.br/transmission/json/iguana-sports/on-sp-city-marathon-2025?modality=42K&gender=M"/>

<cfset resultados = deserializeJSON(resultado.filecontent)/>

<cfloop array="#resultados#" index="item">
    <!---cfdump var=#item#/--->
    <cfoutput><p>#item.ponto_de_controle# | #item.nome# | #item.numero# | #item.time#</p></cfoutput>

    <cfif item.ponto_de_controle EQ "KM 5">

        <cfquery name="qItem" datasource="runner_dba">
            SELECT * FROM tb_leaderboard_marca
            WHERE num_peito = <cfqueryparam cfsqltype="cf_sql_integer" value="#item.numero#"/>
            AND id_pc = 5
        </cfquery>

        <cfif NOT qItem.recordcount>
            <cfquery name="qItem" datasource="runner_dba">
                INSERT INTO tb_leaderboard_marca
                (id_evento, num_peito, id_pc, tempo_total, marca)
                VALUES
                (
                    22792,
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#item.numero#"/>,
                    <cfif item.ponto_de_controle EQ "KM 5">
                        5,
                    <cfelseif item.ponto_de_controle EQ "KM 10">
                        10,
                    <cfelseif item.ponto_de_controle EQ "KM 15">
                        15,
                    <cfelseif item.ponto_de_controle EQ "KM 20">
                        20,
                    <cfelseif item.ponto_de_controle EQ "HALF MARATHON">
                        21,
                    <cfelseif item.ponto_de_controle EQ "KM 24">
                        25,
                    <cfelseif item.ponto_de_controle EQ "KM 30">
                        30,
                    <cfelseif item.ponto_de_controle EQ "KM 35">
                        35,
                    <cfelseif item.ponto_de_controle EQ "KM 40">
                        40,
                    <cfelseif item.ponto_de_controle EQ "Chegada">
                        42,
                    </cfif>
                    <cfqueryparam cfsqltype="cf_sql_time" value="#item.time#"/>,
                    <cfqueryparam cfsqltype="cf_sql_timestamp" value="#item.data_e_hora#"/>
                )
            </cfquery>
        </cfif>

    </cfif>

    <cfif item.ponto_de_controle EQ "KM 10">

        <cfquery name="qItem" datasource="runner_dba">
            SELECT * FROM tb_leaderboard_marca
            WHERE num_peito = <cfqueryparam cfsqltype="cf_sql_integer" value="#item.numero#"/>
            AND id_pc = 10
        </cfquery>

        <cfif NOT qItem.recordcount>
            <cfquery name="qItem" datasource="runner_dba">
                INSERT INTO tb_leaderboard_marca
                (id_evento, num_peito, id_pc, tempo_total, marca)
                VALUES
                (
                    22792,
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#item.numero#"/>,
                    <cfif item.ponto_de_controle EQ "KM 5">
                        5,
                    <cfelseif item.ponto_de_controle EQ "KM 10">
                        10,
                    <cfelseif item.ponto_de_controle EQ "KM 15">
                        15,
                    <cfelseif item.ponto_de_controle EQ "KM 20">
                        20,
                    <cfelseif item.ponto_de_controle EQ "HALF MARATHON">
                        21,
                    <cfelseif item.ponto_de_controle EQ "KM 24">
                        25,
                    <cfelseif item.ponto_de_controle EQ "KM 30">
                        30,
                    <cfelseif item.ponto_de_controle EQ "KM 35">
                        35,
                    <cfelseif item.ponto_de_controle EQ "KM 40">
                        40,
                    <cfelseif item.ponto_de_controle EQ "Chegada">
                        42,
                    </cfif>
                    <cfqueryparam cfsqltype="cf_sql_time" value="#item.time#"/>,
                    <cfqueryparam cfsqltype="cf_sql_timestamp" value="#item.data_e_hora#"/>
                )
            </cfquery>
        </cfif>

    </cfif>

    <cfif item.ponto_de_controle EQ "KM 15">

        <cfquery name="qItem" datasource="runner_dba">
            SELECT * FROM tb_leaderboard_marca
            WHERE num_peito = <cfqueryparam cfsqltype="cf_sql_integer" value="#item.numero#"/>
            AND id_pc = 15
        </cfquery>

        <cfif NOT qItem.recordcount>
            <cfquery name="qItem" datasource="runner_dba">
                INSERT INTO tb_leaderboard_marca
                (id_evento, num_peito, id_pc, tempo_total, marca)
                VALUES
                (
                    22792,
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#item.numero#"/>,
                    <cfif item.ponto_de_controle EQ "KM 5">
                        5,
                    <cfelseif item.ponto_de_controle EQ "KM 10">
                        10,
                    <cfelseif item.ponto_de_controle EQ "KM 15">
                        15,
                    <cfelseif item.ponto_de_controle EQ "KM 20">
                        20,
                    <cfelseif item.ponto_de_controle EQ "HALF MARATHON">
                        21,
                    <cfelseif item.ponto_de_controle EQ "KM 24">
                        24,
                    <cfelseif item.ponto_de_controle EQ "KM 30">
                        30,
                    <cfelseif item.ponto_de_controle EQ "KM 35">
                        35,
                    <cfelseif item.ponto_de_controle EQ "KM 40">
                        40,
                    <cfelseif item.ponto_de_controle EQ "Chegada">
                        42,
                    </cfif>
                    <cfqueryparam cfsqltype="cf_sql_time" value="#item.time#"/>,
                    <cfqueryparam cfsqltype="cf_sql_timestamp" value="#item.data_e_hora#"/>
                )
            </cfquery>
        </cfif>

    </cfif>

    <cfif item.ponto_de_controle EQ "KM 20">

        <cfquery name="qItem" datasource="runner_dba">
            SELECT * FROM tb_leaderboard_marca
            WHERE num_peito = <cfqueryparam cfsqltype="cf_sql_integer" value="#item.numero#"/>
            AND id_pc = 20
        </cfquery>

        <cfif NOT qItem.recordcount>
            <cfquery name="qItem" datasource="runner_dba">
                INSERT INTO tb_leaderboard_marca
                (id_evento, num_peito, id_pc, tempo_total, marca)
                VALUES
                (
                    22792,
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#item.numero#"/>,
                    <cfif item.ponto_de_controle EQ "KM 5">
                        5,
                    <cfelseif item.ponto_de_controle EQ "KM 10">
                        10,
                    <cfelseif item.ponto_de_controle EQ "KM 15">
                        15,
                    <cfelseif item.ponto_de_controle EQ "KM 20">
                        20,
                    <cfelseif item.ponto_de_controle EQ "HALF MARATHON">
                        21,
                    <cfelseif item.ponto_de_controle EQ "KM 24">
                        24,
                    <cfelseif item.ponto_de_controle EQ "KM 30">
                        30,
                    <cfelseif item.ponto_de_controle EQ "KM 35">
                        35,
                    <cfelseif item.ponto_de_controle EQ "KM 40">
                        40,
                    <cfelseif item.ponto_de_controle EQ "Chegada">
                        42,
                    </cfif>
                    <cfqueryparam cfsqltype="cf_sql_time" value="#item.time#"/>,
                    <cfqueryparam cfsqltype="cf_sql_timestamp" value="#item.data_e_hora#"/>
                )
            </cfquery>
        </cfif>

    </cfif>

    <cfif item.ponto_de_controle EQ "HALF MARATHON">

        <cfquery name="qItem" datasource="runner_dba">
            SELECT * FROM tb_leaderboard_marca
            WHERE num_peito = <cfqueryparam cfsqltype="cf_sql_integer" value="#item.numero#"/>
            AND id_pc = 21
        </cfquery>

        <cfif NOT qItem.recordcount>
            <cfquery name="qItem" datasource="runner_dba">
                INSERT INTO tb_leaderboard_marca
                (id_evento, num_peito, id_pc, tempo_total, marca)
                VALUES
                (
                    22792,
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#item.numero#"/>,
                    <cfif item.ponto_de_controle EQ "KM 5">
                        5,
                    <cfelseif item.ponto_de_controle EQ "KM 10">
                        10,
                    <cfelseif item.ponto_de_controle EQ "KM 15">
                        15,
                    <cfelseif item.ponto_de_controle EQ "KM 20">
                        20,
                    <cfelseif item.ponto_de_controle EQ "HALF MARATHON">
                        21,
                    <cfelseif item.ponto_de_controle EQ "KM 24">
                        24,
                    <cfelseif item.ponto_de_controle EQ "KM 30">
                        30,
                    <cfelseif item.ponto_de_controle EQ "KM 35">
                        35,
                    <cfelseif item.ponto_de_controle EQ "KM 40">
                        40,
                    <cfelseif item.ponto_de_controle EQ "Chegada">
                        42,
                    </cfif>
                    <cfqueryparam cfsqltype="cf_sql_time" value="#item.time#"/>,
                    <cfqueryparam cfsqltype="cf_sql_timestamp" value="#item.data_e_hora#"/>
                )
            </cfquery>
        </cfif>

    </cfif>

    <cfif item.ponto_de_controle EQ "KM 24">

        <cfquery name="qItem" datasource="runner_dba">
            SELECT * FROM tb_leaderboard_marca
            WHERE num_peito = <cfqueryparam cfsqltype="cf_sql_integer" value="#item.numero#"/>
            AND id_pc = 24
        </cfquery>

        <cfif NOT qItem.recordcount>
            <cfquery name="qItem" datasource="runner_dba">
                INSERT INTO tb_leaderboard_marca
                (id_evento, num_peito, id_pc, tempo_total, marca)
                VALUES
                (
                    22792,
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#item.numero#"/>,
                    <cfif item.ponto_de_controle EQ "KM 5">
                        5,
                    <cfelseif item.ponto_de_controle EQ "KM 10">
                        10,
                    <cfelseif item.ponto_de_controle EQ "KM 15">
                        15,
                    <cfelseif item.ponto_de_controle EQ "KM 20">
                        20,
                    <cfelseif item.ponto_de_controle EQ "HALF MARATHON">
                        21,
                    <cfelseif item.ponto_de_controle EQ "KM 24">
                        24,
                    <cfelseif item.ponto_de_controle EQ "KM 30">
                        30,
                    <cfelseif item.ponto_de_controle EQ "KM 35">
                        35,
                    <cfelseif item.ponto_de_controle EQ "KM 40">
                        40,
                    <cfelseif item.ponto_de_controle EQ "Chegada">
                        42,
                    </cfif>
                    <cfqueryparam cfsqltype="cf_sql_time" value="#item.time#"/>,
                    <cfqueryparam cfsqltype="cf_sql_timestamp" value="#item.data_e_hora#"/>
                )
            </cfquery>
        </cfif>

    </cfif>

    <cfif item.ponto_de_controle EQ "KM 27">

        <cfquery name="qItem" datasource="runner_dba">
            SELECT * FROM tb_leaderboard_marca
            WHERE num_peito = <cfqueryparam cfsqltype="cf_sql_integer" value="#item.numero#"/>
            AND id_pc = 27
        </cfquery>

        <cfif NOT qItem.recordcount>
            <cfquery name="qItem" datasource="runner_dba">
                INSERT INTO tb_leaderboard_marca
                (id_evento, num_peito, id_pc, tempo_total, marca)
                VALUES
                (
                    22792,
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#item.numero#"/>,
                    27,
                    <cfqueryparam cfsqltype="cf_sql_time" value="#item.time#"/>,
                    <cfqueryparam cfsqltype="cf_sql_timestamp" value="#item.data_e_hora#"/>
                )
            </cfquery>
        </cfif>

    </cfif>

    <cfif item.ponto_de_controle EQ "KM 30">

        <cfquery name="qItem" datasource="runner_dba">
            SELECT * FROM tb_leaderboard_marca
            WHERE num_peito = <cfqueryparam cfsqltype="cf_sql_integer" value="#item.numero#"/>
            AND id_pc = 30
        </cfquery>

        <cfif NOT qItem.recordcount>
            <cfquery name="qItem" datasource="runner_dba">
                INSERT INTO tb_leaderboard_marca
                (id_evento, num_peito, id_pc, tempo_total, marca)
                VALUES
                (
                    22792,
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#item.numero#"/>,
                    <cfif item.ponto_de_controle EQ "KM 5">
                        5,
                    <cfelseif item.ponto_de_controle EQ "KM 10">
                        10,
                    <cfelseif item.ponto_de_controle EQ "KM 15">
                        15,
                    <cfelseif item.ponto_de_controle EQ "KM 20">
                        20,
                    <cfelseif item.ponto_de_controle EQ "HALF MARATHON">
                        21,
                    <cfelseif item.ponto_de_controle EQ "KM 24">
                        24,
                    <cfelseif item.ponto_de_controle EQ "KM 30">
                        30,
                    <cfelseif item.ponto_de_controle EQ "KM 35">
                        35,
                    <cfelseif item.ponto_de_controle EQ "KM 40">
                        40,
                    <cfelseif item.ponto_de_controle EQ "Chegada">
                        42,
                    </cfif>
                    <cfqueryparam cfsqltype="cf_sql_time" value="#item.time#"/>,
                    <cfqueryparam cfsqltype="cf_sql_timestamp" value="#item.data_e_hora#"/>
                )
            </cfquery>
        </cfif>

    </cfif>

    <cfif item.ponto_de_controle EQ "KM 35">

        <cfquery name="qItem" datasource="runner_dba">
            SELECT * FROM tb_leaderboard_marca
            WHERE num_peito = <cfqueryparam cfsqltype="cf_sql_integer" value="#item.numero#"/>
            AND id_pc = 35
        </cfquery>

        <cfif NOT qItem.recordcount>
            <cfquery name="qItem" datasource="runner_dba">
                INSERT INTO tb_leaderboard_marca
                (id_evento, num_peito, id_pc, tempo_total, marca)
                VALUES
                (
                    22792,
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#item.numero#"/>,
                    <cfif item.ponto_de_controle EQ "KM 5">
                        5,
                    <cfelseif item.ponto_de_controle EQ "KM 10">
                        10,
                    <cfelseif item.ponto_de_controle EQ "KM 15">
                        15,
                    <cfelseif item.ponto_de_controle EQ "KM 20">
                        20,
                    <cfelseif item.ponto_de_controle EQ "HALF MARATHON">
                        21,
                    <cfelseif item.ponto_de_controle EQ "KM 24">
                        24,
                    <cfelseif item.ponto_de_controle EQ "KM 30">
                        30,
                    <cfelseif item.ponto_de_controle EQ "KM 35">
                        35,
                    <cfelseif item.ponto_de_controle EQ "KM 40">
                        40,
                    <cfelseif item.ponto_de_controle EQ "Chegada">
                        42,
                    </cfif>
                    <cfqueryparam cfsqltype="cf_sql_time" value="#item.time#"/>,
                    <cfqueryparam cfsqltype="cf_sql_timestamp" value="#item.data_e_hora#"/>
                )
            </cfquery>
        </cfif>

    </cfif>

    <cfif item.ponto_de_controle EQ "KM 40">

        <cfquery name="qItem" datasource="runner_dba">
            SELECT * FROM tb_leaderboard_marca
            WHERE num_peito = <cfqueryparam cfsqltype="cf_sql_integer" value="#item.numero#"/>
            AND id_pc = 40
        </cfquery>

        <cfif NOT qItem.recordcount>
            <cfquery name="qItem" datasource="runner_dba">
                INSERT INTO tb_leaderboard_marca
                (id_evento, num_peito, id_pc, tempo_total, marca)
                VALUES
                (
                    22792,
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#item.numero#"/>,
                    <cfif item.ponto_de_controle EQ "KM 5">
                        5,
                    <cfelseif item.ponto_de_controle EQ "KM 10">
                        10,
                    <cfelseif item.ponto_de_controle EQ "KM 15">
                        15,
                    <cfelseif item.ponto_de_controle EQ "KM 20">
                        20,
                    <cfelseif item.ponto_de_controle EQ "HALF MARATHON">
                        21,
                    <cfelseif item.ponto_de_controle EQ "KM 24">
                        24,
                    <cfelseif item.ponto_de_controle EQ "KM 30">
                        30,
                    <cfelseif item.ponto_de_controle EQ "KM 35">
                        35,
                    <cfelseif item.ponto_de_controle EQ "KM 40">
                        40,
                    <cfelseif item.ponto_de_controle EQ "Chegada">
                        42,
                    </cfif>
                    <cfqueryparam cfsqltype="cf_sql_time" value="#item.time#"/>,
                    <cfqueryparam cfsqltype="cf_sql_timestamp" value="#item.data_e_hora#"/>
                )
            </cfquery>
        </cfif>

    </cfif>

    <cfif item.ponto_de_controle EQ "Chegada">

        <cfquery name="qItem" datasource="runner_dba">
            SELECT * FROM tb_leaderboard_marca
            WHERE num_peito = <cfqueryparam cfsqltype="cf_sql_integer" value="#item.numero#"/>
            AND id_pc = 42
        </cfquery>

        <cfif NOT qItem.recordcount>
            <cfquery name="qItem" datasource="runner_dba">
                INSERT INTO tb_leaderboard_marca
                (id_evento, num_peito, id_pc, tempo_total, marca)
                VALUES
                (
                    22792,
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#item.numero#"/>,
                    <cfif item.ponto_de_controle EQ "KM 5">
                        5,
                    <cfelseif item.ponto_de_controle EQ "KM 10">
                        10,
                    <cfelseif item.ponto_de_controle EQ "KM 15">
                        15,
                    <cfelseif item.ponto_de_controle EQ "KM 20">
                        20,
                    <cfelseif item.ponto_de_controle EQ "HALF MARATHON">
                        21,
                    <cfelseif item.ponto_de_controle EQ "KM 24">
                        24,
                    <cfelseif item.ponto_de_controle EQ "KM 30">
                        30,
                    <cfelseif item.ponto_de_controle EQ "KM 35">
                        35,
                    <cfelseif item.ponto_de_controle EQ "KM 40">
                        40,
                    <cfelseif item.ponto_de_controle EQ "Chegada">
                        42,
                    </cfif>
                    <cfqueryparam cfsqltype="cf_sql_time" value="#item.time#"/>,
                    <cfqueryparam cfsqltype="cf_sql_timestamp" value="#item.data_e_hora#"/>
                )
            </cfquery>
        </cfif>

    </cfif>

</cfloop>

<meta http-equiv="refresh" content="10">

