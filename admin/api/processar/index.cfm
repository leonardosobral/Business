<!doctype html>
<html lang="pt-br" data-mdb-theme="dark">

<cfparam name="URL.id_evento" default="0"/>

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Processador de Eventos - Runner Hub</title>
    <meta http-equiv="refresh" content="0">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.1/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-4bw+/aepP/YC94hEpVNVgiZdgIC5+VKNBQNGCHeKRQN+PtmoHDEXuppvnDJzQIu9" crossorigin="anonymous">
</head>

<body>

    <div class="container my-5">

        <div class="row mb-4">

            <div class="col-lg-6">
                <h1 class="h3">Processador de Eventos</h1>
            </div>

        </div>

        <cfquery name="qTag">
            UPDATE tb_evento_corridas
                SET tag = translate(
                lower( DATE_PART('Year', data_final) || '-' || nome_evento ), ' ''àáâãäéèëêíìïîóòõöôúùüûçÇ%.+!&ªº', '--aaaaaeeeeiiiiooooouuuucc'
              )
            WHERE tag IS NULL OR tag = '';
            UPDATE tb_evento_corridas SET tag = replace(tag, '--', '-');
            UPDATE tb_evento_corridas SET tag = replace(tag, '--', '-');
        </cfquery>

        <cfquery name="qTagAgrega">
            UPDATE tb_agrega_eventos
                SET tag = translate(
                lower( nome_evento_agregado ), ' ''àáâãäéèëêíìïîóòõöôúùüûçÇ%.+!&ªº', '--aaaaaeeeeiiiiooooouuuucc'
              )
            WHERE tag IS NULL OR tag = '';
            UPDATE tb_agrega_eventos SET tag = replace(tag, '--', '-');
            UPDATE tb_agrega_eventos SET tag = replace(tag, '--', '-');
        </cfquery>

        <cfquery name="qEvento">
            SELECT *
            FROM tb_evento_corridas
            WHERE data_final >= <cfqueryparam cfsqltype="cf_sql_date" value="#now()#"/>
            ORDER BY coalesce(data_processamento,'0001-01-01',data_processamento)
        </cfquery>

        <!--- UPDATE DO NOME SIMPLIFICADO --->

        <cfif NOT Len(trim(qEvento.nome_simplificado))>
            <cfquery name="qNomeSimplificado">
                UPDATE tb_evento_corridas SET nome_simplificado = trim(upper(unaccent(translate(nome_evento, 'çÇ%.+!&ªº°’/\,()-1234567890', 'CC')))) WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>;
                UPDATE tb_evento_corridas SET nome_simplificado = replace(nome_simplificado, ' - ', ' ') WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>;
                UPDATE tb_evento_corridas SET nome_simplificado = replace(nome_simplificado, ' KM', ' ') WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>;
                UPDATE tb_evento_corridas SET nome_simplificado = replace(nome_simplificado, ' K ', ' ') WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>;
                UPDATE tb_evento_corridas SET nome_simplificado = replace(nome_simplificado, ' K', ' ') WHERE nome_simplificado ilike '% K' AND id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>;
                UPDATE tb_evento_corridas SET nome_simplificado = replace(nome_simplificado, 'K ', ' ') WHERE nome_simplificado ilike 'K %' AND id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>;
                UPDATE tb_evento_corridas SET nome_simplificado = replace(nome_simplificado, ' DA ', ' ') WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>;
                UPDATE tb_evento_corridas SET nome_simplificado = replace(nome_simplificado, ' DE ', ' ') WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>;
                UPDATE tb_evento_corridas SET nome_simplificado = replace(nome_simplificado, ' DO ', ' ') WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>;
                UPDATE tb_evento_corridas SET nome_simplificado = replace(nome_simplificado, ' DAS ', ' ') WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>;
                UPDATE tb_evento_corridas SET nome_simplificado = replace(nome_simplificado, ' DOS ', ' ') WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>;
                UPDATE tb_evento_corridas SET nome_simplificado = replace(nome_simplificado, '  ', ' ') WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>;
                UPDATE tb_evento_corridas SET nome_simplificado = replace(nome_simplificado, '  ', ' ') WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>;
                UPDATE tb_evento_corridas SET nome_simplificado = replace(nome_simplificado, '  ', ' ') WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>;
                UPDATE tb_evento_corridas SET nome_simplificado = trim(nome_simplificado) WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>;
            </cfquery>
            <cfquery name="qEvento">
                SELECT *
                FROM tb_evento_corridas
                WHERE data_final >= <cfqueryparam cfsqltype="cf_sql_date" value="#now()#"/>
                ORDER BY coalesce(data_processamento,'0001-01-01',data_processamento)
            </cfquery>
        </cfif>

        <!--- VERIFICA SE TEM DUPLICIDADE --->

        <cfquery name="qMatch">
            SELECT *
            FROM tb_evento_corridas
            WHERE nome_simplificado ilike <cfqueryparam cfsqltype="cf_sql_varchar" value="%#qEvento.nome_evento#%"/>
            AND <cfqueryparam cfsqltype="cf_sql_date" value="#qEvento.data_inicial#"/> BETWEEN data_inicial AND data_final
            AND estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qEvento.estado#"/>
            AND cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qEvento.cidade#"/>
            AND id_evento <> <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
        </cfquery>

        <cfif qMatch.recordcount>

            <cfquery>
                UPDATE tb_evento_corridas
                SET info_duplicado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qMatch.id_evento#"/>
                WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
            </cfquery>

            <p>Duplicidade encontrada</p>

        </cfif>

        <!--- UPDATE DO CODIGO DA CIDADE --->

        <cfif NOT Len(trim(qEvento.cod_cidade))>

            <cfquery name="qCidade">
                SELECT cod_cidade, nome_cidade
                FROM tb_cidades
                where nome_cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qEvento.cidade#"/>
                AND uf = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qEvento.estado#"/>
            </cfquery>

            <cfif qCidade.recordcount EQ 1>

                <cfquery>
                    UPDATE tb_evento_corridas
                    SET cod_cidade = <cfqueryparam cfsqltype="cf_sql_integer" value="#qCidade.cod_cidade#"/>
                    WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
                </cfquery>

                <p>Cidade encontrada</p>

            </cfif>

        </cfif>


        <!--- UPDATE LAT LONG --->

        <cfif len(trim(qEvento.endereco))>

            <cfset VARIABLES.endereco = qEvento.endereco & " " & qEvento.cidade & " " & qEvento.estado/>
            <h3><cfoutput>#VARIABLES.endereco#</cfoutput></h3>

            <cfhttp result="resultado" url="https://maps.googleapis.com/maps/api/geocode/json?address=#VARIABLES.endereco#&key=AIzaSyCoPKGySXvZidw0cStoxN5SJGckbf9gwXU">
            </cfhttp>

            <cfset VARIABLES.coordenadas = deserializeJSON(resultado.Filecontent).results[1].geometry/>

            <cfdump var="#VARIABLES.coordenadas.location.lat#"/>
            <cfdump var="#VARIABLES.coordenadas.location.lng#"/>

            <cfif isDefined("VARIABLES.coordenadas")>
            <cfquery>
                UPDATE tb_evento_corridas
                SET coordenadas = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.coordenadas.location.lat#, #VARIABLES.coordenadas.location.lng#"/>
                WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
            </cfquery>
            </cfif>

        </cfif>

        <!--- UPDATE ORGANIZADOR --->

        <cfif len(trim(qEvento.organizador))>

            <cfquery>
                UPDATE tb_evento_corridas
                SET organizador = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qEvento.organizador#"/>
                WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
            </cfquery>

            <cfquery name="qRelaciona">
                SELECT *
                FROM tb_evento_corridas_fornecedores
                WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
            </cfquery>

            <cfdump var="#qRelaciona#"/>

        </cfif>

        <cfquery>
            UPDATE tb_evento_corridas
            SET data_processamento = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
        </cfquery>

        <p>
        <cfoutput>#qEvento.nome_evento# processado</cfoutput>
        </p>

    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.1/dist/js/bootstrap.bundle.min.js" integrity="sha384-HwwvtgBNo3bZJJLYd8oVXjrBZt8cqVSpeBNS5n7C8IVInixGAoxmnlMuBnhbgrkm" crossorigin="anonymous"></script>

</body>

</html>
