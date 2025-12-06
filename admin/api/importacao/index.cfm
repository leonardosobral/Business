<!doctype html>
<html lang="pt-br" data-mdb-theme="dark">

<!--- Define the page request properties. --->
<cfsetting
        requesttimeout="180"
        showdebugoutput="false"
        enablecfoutputonly="false"
        />

<!--- HEAD --->
<head>

    <!--- REQUIRED META TAGS --->
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>

    <title>Runner Hub - Importador de Eventos</title>
    <cfinclude template="../../includes/seo-web-tools-head.cfm"/>
</head>

<body>

    <div class="container my-5">

        <div class="row mb-4">

            <div class="col-lg-6">
                <h1 class="h3">Importador de Eventos</h1>
            </div>

        </div>

        <cfif isDefined("URL.acao") AND URL.acao EQ "apagar" AND isDefined("URL.id_evento")>

            <cfquery>
                UPDATE tb_evento_corridas_temp
                SET obs = <cfqueryparam cfsqltype="cf_sql_varchar" value="duplicado"/>
                WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>
            </cfquery>

            <cflocation addtoken="false" url="/admin/api/importacao/"/>

        </cfif>

        <cfif isDefined("URL.acao") AND URL.acao EQ "importar" AND isDefined("URL.id_evento")>

            <!---cftry--->

                <cfquery name="qImportacao">
                    SELECT imp.*
                    FROM tb_evento_corridas_temp imp
                    WHERE imp.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>
                </cfquery>

                <cfquery name="qInsertEvento">
                    insert into tb_evento_corridas
                    (
                        nome_evento, cidade, data_inicial, data_final, estado, tipo_corrida,
                        descricao, endereco, coordenadas, categorias, url_inscricao,
                        pais, url_resultado, nome_simplificado, organizador, obs
                    )
                    values
                    (
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.nome_evento#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.cidade#"/>,
                        <cfqueryparam cfsqltype="cf_sql_date" value="#qImportacao.data_inicial#"/>,
                        <cfqueryparam cfsqltype="cf_sql_date" value="#qImportacao.data_final#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.estado#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.tipo_corrida#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.descricao#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.endereco#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.coordenadas#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.categorias#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.url_inscricao#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.pais#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.url_resultado#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.nome_simplificado#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.organizador#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="importado em #now()#"/>
                    ) RETURNING id_evento;
                </cfquery>

                <cfquery>
                    UPDATE tb_evento_corridas_temp
                    SET obs = <cfqueryparam cfsqltype="cf_sql_varchar" value="importado em #now()#"/>
                    WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>
                </cfquery>

                <cfif Len(trim(qImportacao.cod_evento))>

                <cfquery result="qUpdateORG">
                    insert into tb_evento_corridas_relaciona
                    (id_evento, id_parceiro, id_evento_parceiro, nome_variavel)
                    values
                    (
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#qInsertEvento.id_evento#"/>,
                    1,
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#qImportacao.cod_evento#"/>,
                    'competition_id'
                    );
                </cfquery>

                <cfif qUpdateORG.RECORDCOUNT><br/><span class="fw-bold text-info">UPDATE DO COMPETITION_ID</span></cfif>

                </cfif>

            <!---cfcatch type="any">
                <br/><cfdump var="#cfcatch.detail#"/>
            </cfcatch>
            </cftry--->

            <cflocation addtoken="false" url="/admin/api/importacao/"/>

        </cfif>


        <!--- EVENTOS PARA IMPORTACAO --->

        <cfquery name="qUpdate">
            UPDATE tb_evento_corridas_temp set tipo_corrida = lower(tipo_corrida);
            UPDATE tb_evento_corridas_temp set data_final = data_inicial WHERE data_final is null;
            UPDATE tb_evento_corridas_temp
                SET tag = translate(
                lower( DATE_PART('Year', data_final::date) || '-' || nome_evento ), ' ''àáâãäéèëêíìïîóòõöôúùüûçÇ%.+!&ªº°’/', '--aaaaaeeeeiiiiooooouuuucc'
              )
            WHERE tag IS NULL OR tag = '';
            UPDATE tb_evento_corridas_temp SET tag = replace(tag, '--', '-');
            UPDATE tb_evento_corridas_temp SET tag = replace(tag, '--', '-');
        </cfquery>

        <cfquery name="qImportacao">
            SELECT imp.*,
            cor.nome_evento as nome_evento_original
            FROM tb_evento_corridas_temp imp
            LEFT JOIN tb_evento_corridas cor ON cor.id_evento = imp.id_evento_match
            WHERE imp.obs is null
            ORDER BY imp.data_inicial, imp.nome_evento
            LIMIT 10
        </cfquery>

        <!--- LOOP DE VERIFICACAO IMPORTACAO --->

        <cfloop query="qImportacao">

            <!--- NOME DO EVENTO --->

            <hr/>
            <p>
            <cfoutput>#qImportacao.data_inicial# #qImportacao.data_final# - #qImportacao.nome_evento# - #qImportacao.cidade# - #qImportacao.estado#</cfoutput>

            <!--- VERIFICA SE DA MATCH COM ALGUM EVENTO EM PRODUCAO --->

            <cfquery name="qMatch">
                SELECT *
                FROM tb_evento_corridas
                WHERE nome_simplificado ilike <cfqueryparam cfsqltype="cf_sql_varchar" value="%#qImportacao.nome_simplificado#%"/>
                AND <cfqueryparam cfsqltype="cf_sql_date" value="#qImportacao.data_inicial#"/> BETWEEN data_inicial AND data_final
                AND estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.estado#"/>
                AND cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.cidade#"/>
            </cfquery>

            <!--- SE ACHOU SOMENTE 1 REGISTRO --->

            <cfif qMatch.recordcount EQ 1>

                <br/><span class="fw-bold text-info"Achou 1</span>

                <cfif Len(trim(qImportacao.url_inscricao))>

                    <cfquery result="qUpdateURL">
                        UPDATE tb_evento_corridas
                        SET url_inscricao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.url_inscricao#"/>
                        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qMatch.id_evento#"/>
                        AND url_inscricao is NULL
                    </cfquery>

                    <cfif qUpdateURL.RECORDCOUNT><br/><span class="fw-bold text-info">UPDATE DO LINK DE INSCRICAO</span></cfif>

                </cfif>

                <cfif Len(trim(qImportacao.url_resultado))>

                    <cfquery result="qUpdateURL">
                        UPDATE tb_evento_corridas
                        SET url_resultado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.url_resultado#"/>
                        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qMatch.id_evento#"/>
                        AND url_resultado is NULL
                    </cfquery>

                    <cfif qUpdateURL.RECORDCOUNT><br/><span class="fw-bold text-info">UPDATE DO LINK DE RESULTADO</span></cfif>

                </cfif>

                <cfif Len(trim(qImportacao.organizador))>

                    <cfquery result="qUpdateORG">
                        UPDATE tb_evento_corridas
                        SET organizador = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.organizador#"/>
                        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qMatch.id_evento#"/>
                        AND organizador is NULL
                    </cfquery>

                    <cfif qUpdateORG.RECORDCOUNT><br/><span class="fw-bold text-info">UPDATE DO ORGANIZADOR</span></cfif>

                </cfif>

                <cfif Len(trim(qImportacao.endereco))>

                    <cfquery result="qUpdateORG">
                        UPDATE tb_evento_corridas
                        SET endereco = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.endereco#"/>
                        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qMatch.id_evento#"/>
                        AND endereco is NULL
                    </cfquery>

                    <cfif qUpdateORG.RECORDCOUNT><br/><span class="fw-bold text-info">UPDATE DO ENDERECO</span></cfif>

                </cfif>

                <cfif Len(trim(qImportacao.categorias))>

                    <cfquery result="qUpdateORG">
                        UPDATE tb_evento_corridas
                        SET categorias = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.categorias#"/>
                        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qMatch.id_evento#"/>
                        AND categorias is NULL
                    </cfquery>

                    <cfif qUpdateORG.RECORDCOUNT><br/><span class="fw-bold text-info">UPDATE DAS CATEGORIAS</span></cfif>

                </cfif>

                <cfif Len(trim(qImportacao.cod_evento))>

                    <cftry>

                        <cfquery result="qUpdateORG">
                            insert into tb_evento_corridas_relaciona
                            (id_evento, id_parceiro, id_evento_parceiro, nome_variavel)
                            values
                            (
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#qMatch.id_evento#"/>,
                            1,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#qImportacao.cod_evento#"/>,
                            'competition_id'
                            );
                        </cfquery>

                        <cfif qUpdateORG.RECORDCOUNT><br/><span class="fw-bold text-info">UPDATE DO COMPETITION_ID</span></cfif>

                    <cfcatch type="any">
                        <br/><cfdump var="#cfcatch.detail#"/>
                    </cfcatch>
                    </cftry>

                </cfif>

                <cfquery>
                    UPDATE tb_evento_corridas_temp
                    SET obs = 'update'
                    WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qImportacao.id_evento#"/>
                </cfquery>

            </cfif>

            <!--- SE ACHOU MAIS DE 1 REGISTRO --->

            <cfif qMatch.recordcount GT 1>

                <br/><span class="fw-bold text-info"Achou mais de 1</span>

            </cfif>

            <!--- SE NAO ACHOU --->

            <cfif NOT qMatch.recordcount>

                <!--- BUSCA COM FULL TEXT --->

                <cfquery name="qVector">
                    SELECT * FROM tb_evento_corridas
                    WHERE ( to_tsvector(nome_simplificado) @@ plainto_tsquery(<cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.nome_simplificado#"/>))
                    AND <cfqueryparam cfsqltype="cf_sql_date" value="#qImportacao.data_inicial#"/> BETWEEN data_inicial AND data_final
                    AND estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.estado#"/>
                    AND cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.cidade#"/>
                </cfquery>

                <!--- SE ACHOU SOMENTE 1 REGISTRO --->

                <cfif qVector.recordcount EQ 1>

                    <cfif Len(trim(qImportacao.url_inscricao))>

                        <cfquery result="qUpdateURL">
                            UPDATE tb_evento_corridas
                            SET url_inscricao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.url_inscricao#"/>
                            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qVector.id_evento#"/>
                            AND url_inscricao is NULL
                        </cfquery>

                        <cfif qUpdateURL.RECORDCOUNT><br/><span class="fw-bold text-info">UPDATE DO LINK DE INSCRICAO</span></cfif>

                    </cfif>

                    <cfif Len(trim(qImportacao.url_resultado))>

                        <cfquery result="qUpdateURL">
                            UPDATE tb_evento_corridas
                            SET url_resultado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.url_resultado#"/>
                            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qVector.id_evento#"/>
                            AND url_resultado is NULL
                        </cfquery>

                        <cfif qUpdateURL.RECORDCOUNT><br/><span class="fw-bold text-info">UPDATE DO LINK DE RESULTADO</span></cfif>

                    </cfif>

                    <cfif Len(trim(qImportacao.organizador))>

                        <cfquery result="qUpdateORG">
                            UPDATE tb_evento_corridas
                            SET organizador = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.organizador#"/>
                            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qVector.id_evento#"/>
                            AND organizador is NULL
                        </cfquery>

                        <cfif qUpdateORG.RECORDCOUNT><br/><span class="fw-bold text-info">UPDATE DO ORGANIZADOR</span></cfif>

                    </cfif>

                    <cfif Len(trim(qImportacao.endereco))>

                        <cfquery result="qUpdateORG">
                            UPDATE tb_evento_corridas
                            SET endereco = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.endereco#"/>
                            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qVector.id_evento#"/>
                            AND endereco is NULL
                        </cfquery>

                        <cfif qUpdateORG.RECORDCOUNT><br/><span class="fw-bold text-info">UPDATE DO ENDERECO</span></cfif>

                    </cfif>

                    <cfif Len(trim(qImportacao.categorias))>

                        <cfquery result="qUpdateORG">
                            UPDATE tb_evento_corridas
                            SET categorias = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.categorias#"/>
                            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qVector.id_evento#"/>
                            AND categorias is NULL
                        </cfquery>

                        <cfif qUpdateORG.RECORDCOUNT><br/><span class="fw-bold text-info">UPDATE DAS CATEGORIAS</span></cfif>

                    </cfif>

                    <cfif Len(trim(qImportacao.cod_evento))>

                        <cftry>

                            <cfquery result="qUpdateORG">
                                insert into tb_evento_corridas_relaciona
                                (id_evento, id_parceiro, id_evento_parceiro, nome_variavel)
                                values
                                (
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#qVector.id_evento#"/>,
                                1,
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#qImportacao.cod_evento#"/>,
                                'competition_id'
                                );
                            </cfquery>

                            <cfif qUpdateORG.RECORDCOUNT><br/><span class="fw-bold text-info">UPDATE DO COMPETITION_ID</span></cfif>

                        <cfcatch type="any">
                            <br/><cfdump var="#cfcatch.detail#"/>
                        </cfcatch>
                        </cftry>

                    </cfif>

                    <cfquery>
                        UPDATE tb_evento_corridas_temp
                        SET obs = 'update'
                        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qImportacao.id_evento#"/>
                    </cfquery>

                </cfif>

                <!--- SE ACHOU MAIS DE 1 REGISTRO --->

                <cfif qVector.recordcount GT 1>

                    <br/><span class="fw-bold text-info">Achou mais de 1</span>

                </cfif>

                <!--- SE NAO ACHOU --->

                <cfif NOT qVector.recordcount>

                    <br/><span class="fw-bold text-gray-light">Não achou nada</span>

                    <!--- BUSCA EVENTOS NA DATA --->

                    <cfquery name="qData">
                        SELECT * FROM tb_evento_corridas
                        WHERE <cfqueryparam cfsqltype="cf_sql_date" value="#qImportacao.data_inicial#"/> BETWEEN data_inicial AND data_final
                        AND estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.estado#"/>
                        AND cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qImportacao.cidade#"/>
                    </cfquery>

                    <cfoutput query="qData">
                        <br/><span class="fw-bold text-info">#qData.nome_evento#</span>
                    </cfoutput>

                    <cfoutput>
                        <br/>
                        <a href="./?acao=importar&id_evento=#qImportacao.id_evento#"><button class="btn btn-sm btn-info">Importar</button></a>
                        <a href="./?acao=apagar&id_evento=#qImportacao.id_evento#"><button class="btn btn-sm btn-danger ms-2">Apagar</button></a>
                    </cfoutput>

                </cfif>

            </cfif>


            <cfif Len(trim(qImportacao.id_evento_match))><br/><span class="fw-bold text-success">Tab Importação: <cfoutput>#qImportacao.nome_evento_original# | Tab. Produção: #qImportacao.nome_evento# </cfoutput></span></cfif>
            <cfif qMatch.recordcount><br/><span class="fw-bold text-danger">Perfect Match: <cfoutput query="qMatch">#qMatch.id_evento# </cfoutput></span></cfif>
            <cfif isDefined("qVector") AND qVector.recordcount><br/><span class="fw-bold text-warning">Full Text Search: <cfoutput query="qVector">#qVector.id_evento# </cfoutput></span></cfif>
            </p>

        </cfloop>

    </div>

    <cfinclude template="../../includes/seo-web-tools-body-end.cfm"/>

</body>

</html>
