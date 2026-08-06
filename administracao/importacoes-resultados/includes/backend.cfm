<cfparam name="URL.pagina" default="1"/>
<cfparam name="URL.busca" default=""/>
<cfparam name="URL.status" default=""/>
<cfparam name="URL.publicacao" default=""/>
<cfparam name="URL.timer" default=""/>
<cfparam name="URL.cliente" default=""/>
<cfparam name="URL.periodo" default="30"/>
<cfparam name="URL.id" default=""/>

<cfset VARIABLES.resultImportError = ""/>
<cfset VARIABLES.resultImportDetailError = ""/>
<cfset VARIABLES.resultImportSchemaReady = false/>
<cfset VARIABLES.resultImportPerPage = 25/>
<cfset VARIABLES.resultImportPage = max(1, val(URL.pagina))/>
<cfset VARIABLES.resultImportSearch = left(trim(URL.busca & ""), 160)/>
<cfset VARIABLES.resultImportStatus = lCase(trim(URL.status & ""))/>
<cfset VARIABLES.resultImportPublicationStatus = lCase(trim(URL.publicacao & ""))/>
<cfset VARIABLES.resultImportTimer = left(lCase(trim(URL.timer & "")), 64)/>
<cfset VARIABLES.resultImportClient = left(lCase(trim(URL.cliente & "")), 128)/>
<cfset VARIABLES.resultImportPeriodDays = listFind("0,1,7,30,90", trim(URL.periodo & "")) ? val(URL.periodo) : 30/>
<cfset VARIABLES.resultImportSelectedId = lCase(trim(URL.id & ""))/>
<cfset VARIABLES.resultImportTotal = 0/>
<cfset VARIABLES.resultImportTotalPages = 1/>
<cfset VARIABLES.resultImportOffset = 0/>

<cfif NOT listFindNoCase("pendente,processando,processado,falhou,cancelado", VARIABLES.resultImportStatus)>
    <cfset VARIABLES.resultImportStatus = ""/>
</cfif>
<cfif NOT listFindNoCase("extraoficial,final,atualizacao", VARIABLES.resultImportPublicationStatus)>
    <cfset VARIABLES.resultImportPublicationStatus = ""/>
</cfif>

<cfset qResultImportSummary = queryNew("total,pendentes,pendentes_atrasadas,processando,processados,falhas,cancelados,extraoficiais,finais,atualizacoes,total_resultados")/>
<cfset qResultImports = queryNew("id_resultado_importacao,submission_id,id_evento,id_evento_informado,tag_evento_informada,client_id,cod_timer,external_account_id,external_event_id,url_resultado,url_resultado_publica,status_publicacao,status_processamento,idempotency_key,tentativas,total_resultados,erro_codigo,erro_detalhe,data_recebimento,data_inicio,data_processamento,data_atualizacao,nome_evento,event_tag,event_city,event_state,event_date")/>
<cfset qResultImportDetail = duplicate(qResultImports)/>
<cfset qResultImportTimers = queryNew("cod_timer")/>
<cfset qResultImportClients = queryNew("client_id")/>

<cftry>
    <cfquery name="qResultImportSchema">
        SELECT count(*) AS total
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name = 'tb_resultados_importacoes'
    </cfquery>

    <cfset VARIABLES.resultImportSchemaReady = val(qResultImportSchema.total) EQ 1/>

    <cfif VARIABLES.resultImportSchemaReady>
        <cfquery name="qResultImportSummary">
            SELECT count(*) AS total,
                   count(*) FILTER (WHERE imp.status_processamento = 'pendente') AS pendentes,
                   count(*) FILTER (
                       WHERE imp.status_processamento = 'pendente'
                         AND imp.data_recebimento < now() - interval '15 minutes'
                   ) AS pendentes_atrasadas,
                   count(*) FILTER (WHERE imp.status_processamento = 'processando') AS processando,
                   count(*) FILTER (WHERE imp.status_processamento = 'processado') AS processados,
                   count(*) FILTER (WHERE imp.status_processamento = 'falhou') AS falhas,
                   count(*) FILTER (WHERE imp.status_processamento = 'cancelado') AS cancelados,
                   count(*) FILTER (WHERE imp.status_publicacao = 'extraoficial') AS extraoficiais,
                   count(*) FILTER (WHERE imp.status_publicacao = 'final') AS finais,
                   count(*) FILTER (WHERE imp.status_publicacao = 'atualizacao') AS atualizacoes,
                   coalesce(sum(imp.total_resultados) FILTER (WHERE imp.status_processamento = 'processado'), 0) AS total_resultados
            FROM public.tb_resultados_importacoes imp
            LEFT JOIN public.tb_evento_corridas evt ON evt.id_evento = imp.id_evento
            WHERE 1 = 1
            <cfif VARIABLES.resultImportPeriodDays GT 0>
                AND imp.data_recebimento >= now() - (
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.resultImportPeriodDays#"/> * interval '1 day'
                )
            </cfif>
            <cfif len(VARIABLES.resultImportPublicationStatus)>
                AND imp.status_publicacao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.resultImportPublicationStatus#"/>
            </cfif>
            <cfif len(VARIABLES.resultImportTimer)>
                AND lower(imp.cod_timer) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.resultImportTimer#"/>
            </cfif>
            <cfif len(VARIABLES.resultImportClient)>
                AND lower(imp.client_id) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.resultImportClient#"/>
            </cfif>
            <cfif len(VARIABLES.resultImportSearch)>
                AND position(
                    lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.resultImportSearch#"/>)
                    IN lower(concat_ws(' ',
                        imp.public_id::text,
                        imp.id_resultado_importacao::text,
                        imp.id_evento::text,
                        imp.id_evento_informado::text,
                        imp.tag_evento_informada,
                        imp.external_account_id,
                        imp.external_event_id,
                        imp.url_resultado,
                        imp.url_resultado_publica,
                        evt.nome_evento,
                        evt.tag
                    ))
                ) > 0
            </cfif>
        </cfquery>

        <cfquery name="qResultImportTimers">
            SELECT DISTINCT cod_timer
            FROM public.tb_resultados_importacoes
            WHERE cod_timer IS NOT NULL
              AND trim(cod_timer) <> ''
            ORDER BY cod_timer
        </cfquery>

        <cfquery name="qResultImportClients">
            SELECT DISTINCT client_id
            FROM public.tb_resultados_importacoes
            WHERE client_id IS NOT NULL
              AND trim(client_id) <> ''
            ORDER BY client_id
        </cfquery>

        <cfquery name="qResultImportCount">
            SELECT count(*) AS total
            FROM public.tb_resultados_importacoes imp
            LEFT JOIN public.tb_evento_corridas evt ON evt.id_evento = imp.id_evento
            WHERE 1 = 1
            <cfif VARIABLES.resultImportPeriodDays GT 0>
                AND imp.data_recebimento >= now() - (
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.resultImportPeriodDays#"/> * interval '1 day'
                )
            </cfif>
            <cfif len(VARIABLES.resultImportStatus)>
                AND imp.status_processamento = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.resultImportStatus#"/>
            </cfif>
            <cfif len(VARIABLES.resultImportPublicationStatus)>
                AND imp.status_publicacao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.resultImportPublicationStatus#"/>
            </cfif>
            <cfif len(VARIABLES.resultImportTimer)>
                AND lower(imp.cod_timer) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.resultImportTimer#"/>
            </cfif>
            <cfif len(VARIABLES.resultImportClient)>
                AND lower(imp.client_id) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.resultImportClient#"/>
            </cfif>
            <cfif len(VARIABLES.resultImportSearch)>
                AND position(
                    lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.resultImportSearch#"/>)
                    IN lower(concat_ws(' ',
                        imp.public_id::text,
                        imp.id_resultado_importacao::text,
                        imp.id_evento::text,
                        imp.id_evento_informado::text,
                        imp.tag_evento_informada,
                        imp.external_account_id,
                        imp.external_event_id,
                        imp.url_resultado,
                        imp.url_resultado_publica,
                        evt.nome_evento,
                        evt.tag
                    ))
                ) > 0
            </cfif>
        </cfquery>

        <cfset VARIABLES.resultImportTotal = val(qResultImportCount.total)/>
        <cfset VARIABLES.resultImportTotalPages = max(1, ceiling(VARIABLES.resultImportTotal / VARIABLES.resultImportPerPage))/>
        <cfset VARIABLES.resultImportPage = min(VARIABLES.resultImportPage, VARIABLES.resultImportTotalPages)/>
        <cfset VARIABLES.resultImportOffset = (VARIABLES.resultImportPage - 1) * VARIABLES.resultImportPerPage/>

        <cfquery name="qResultImports">
            SELECT imp.id_resultado_importacao,
                   imp.public_id::text AS submission_id,
                   imp.id_evento,
                   imp.id_evento_informado,
                   imp.tag_evento_informada,
                   imp.client_id,
                   imp.cod_timer,
                   imp.external_account_id,
                   imp.external_event_id,
                   imp.url_resultado,
                   imp.url_resultado_publica,
                   imp.status_publicacao,
                   imp.status_processamento,
                   imp.idempotency_key,
                   imp.tentativas,
                   imp.total_resultados,
                   imp.erro_codigo,
                   imp.erro_detalhe,
                   imp.data_recebimento,
                   imp.data_inicio,
                   imp.data_processamento,
                   imp.data_atualizacao,
                   evt.nome_evento,
                   evt.tag AS event_tag,
                   evt.cidade AS event_city,
                   evt.estado AS event_state,
                   evt.data_inicial AS event_date
            FROM public.tb_resultados_importacoes imp
            LEFT JOIN public.tb_evento_corridas evt ON evt.id_evento = imp.id_evento
            WHERE 1 = 1
            <cfif VARIABLES.resultImportPeriodDays GT 0>
                AND imp.data_recebimento >= now() - (
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.resultImportPeriodDays#"/> * interval '1 day'
                )
            </cfif>
            <cfif len(VARIABLES.resultImportStatus)>
                AND imp.status_processamento = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.resultImportStatus#"/>
            </cfif>
            <cfif len(VARIABLES.resultImportPublicationStatus)>
                AND imp.status_publicacao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.resultImportPublicationStatus#"/>
            </cfif>
            <cfif len(VARIABLES.resultImportTimer)>
                AND lower(imp.cod_timer) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.resultImportTimer#"/>
            </cfif>
            <cfif len(VARIABLES.resultImportClient)>
                AND lower(imp.client_id) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.resultImportClient#"/>
            </cfif>
            <cfif len(VARIABLES.resultImportSearch)>
                AND position(
                    lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.resultImportSearch#"/>)
                    IN lower(concat_ws(' ',
                        imp.public_id::text,
                        imp.id_resultado_importacao::text,
                        imp.id_evento::text,
                        imp.id_evento_informado::text,
                        imp.tag_evento_informada,
                        imp.external_account_id,
                        imp.external_event_id,
                        imp.url_resultado,
                        imp.url_resultado_publica,
                        evt.nome_evento,
                        evt.tag
                    ))
                ) > 0
            </cfif>
            ORDER BY imp.data_recebimento DESC, imp.id_resultado_importacao DESC
            LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.resultImportPerPage#"/>
            OFFSET <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.resultImportOffset#"/>
        </cfquery>

        <cfif len(VARIABLES.resultImportSelectedId)>
            <cfif reFindNoCase("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", VARIABLES.resultImportSelectedId)>
                <cfquery name="qResultImportDetail">
                    SELECT imp.id_resultado_importacao,
                           imp.public_id::text AS submission_id,
                           imp.id_evento,
                           imp.id_evento_informado,
                           imp.tag_evento_informada,
                           imp.client_id,
                           imp.cod_timer,
                           imp.external_account_id,
                           imp.external_event_id,
                           imp.url_resultado,
                           imp.url_resultado_publica,
                           imp.status_publicacao,
                           imp.status_processamento,
                           imp.idempotency_key,
                           imp.tentativas,
                           imp.total_resultados,
                           imp.erro_codigo,
                           imp.erro_detalhe,
                           imp.data_recebimento,
                           imp.data_inicio,
                           imp.data_processamento,
                           imp.data_atualizacao,
                           evt.nome_evento,
                           evt.tag AS event_tag,
                           evt.cidade AS event_city,
                           evt.estado AS event_state,
                           evt.data_inicial AS event_date
                    FROM public.tb_resultados_importacoes imp
                    LEFT JOIN public.tb_evento_corridas evt ON evt.id_evento = imp.id_evento
                    WHERE imp.public_id::text = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.resultImportSelectedId#"/>
                    LIMIT 1
                </cfquery>

                <cfif NOT qResultImportDetail.recordcount>
                    <cfset VARIABLES.resultImportDetailError = "Submissão não encontrada."/>
                </cfif>
            <cfelse>
                <cfset VARIABLES.resultImportDetailError = "Identificador de submissão inválido."/>
            </cfif>
        </cfif>
    <cfelse>
        <cfset VARIABLES.resultImportError = "A tabela public.tb_resultados_importacoes ainda não existe neste ambiente."/>
    </cfif>

    <cfcatch type="any">
        <cfset VARIABLES.resultImportError = "Não foi possível consultar a fila de importações: " & CFCATCH.message/>
    </cfcatch>
</cftry>
