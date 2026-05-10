<cfparam name="URL.pagina" default="1" type="numeric"/>
<cfset VARIABLES.mediaPage = max(1, int(URL.pagina))/>

<cfquery name="qChannelColumns">
    SELECT column_name, data_type, is_nullable, column_default, character_maximum_length
    FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'tb_youtube_canais'
    ORDER BY ordinal_position
</cfquery>

<cfset VARIABLES.channelColumns = ValueList(qChannelColumns.column_name)/>
<cfset VARIABLES.channelPk = ""/>
<cfset VARIABLES.channelSelectColumns = ""/>
<cfset VARIABLES.channelFormExcludedColumns = "created_at,updated_at,createdon,modifiedon,data_cadastro,data_atualizacao,data_criacao,data_alteracao,data_importacao,ultima_importacao,data_ultima_importacao,logotipo,logo,logo_url,imagem_url,image_url,avatar_url,thumbnail_url,logotipo_arquivo,logo_arquivo,logotipo_blob,logo_blob,logotipo_mime,logo_mime,logotipo_nome_arquivo,logo_nome_arquivo,logotipo_atualizado_em,logo_atualizado_em"/>

<cfloop list="id_canal,id_youtube_canal,youtube_canal_id,id" item="channelPkCandidate">
    <cfif NOT len(trim(VARIABLES.channelPk)) AND ListFindNoCase(VARIABLES.channelColumns, channelPkCandidate)>
        <cfset VARIABLES.channelPk = channelPkCandidate/>
    </cfif>
</cfloop>

<cfif NOT len(trim(VARIABLES.channelPk)) AND qChannelColumns.recordcount>
    <cfset VARIABLES.channelPk = qChannelColumns.column_name/>
</cfif>

<cfloop query="qChannelColumns">
    <cfset VARIABLES.channelSelectColumns = ListAppend(VARIABLES.channelSelectColumns, '"' & Replace(qChannelColumns.column_name, '"', '""', 'all') & '"')/>
</cfloop>

<cfset VARIABLES.channelOrderColumn = len(trim(VARIABLES.channelPk)) ? VARIABLES.channelPk : (qChannelColumns.recordcount ? qChannelColumns.column_name : "")/>

<cfset VARIABLES.channelActiveColumn = ""/>
<cfloop query="qChannelColumns">
    <cfif NOT len(trim(VARIABLES.channelActiveColumn))
        AND lcase(qChannelColumns.data_type) EQ "boolean"
        AND ListFindNoCase("ativo,is_active,active,habilitado,enabled,status,pub_status", qChannelColumns.column_name)>
        <cfset VARIABLES.channelActiveColumn = qChannelColumns.column_name/>
    </cfif>
</cfloop>

<cfif isDefined("FORM.canal_action")
    AND isDefined("qPerfil")
    AND qPerfil.recordcount
    AND qPerfil.is_admin
    AND FORM.canal_action EQ "salvar"
    AND len(trim(VARIABLES.channelPk))
    AND qChannelColumns.recordcount>

    <cfset VARIABLES.savedChannelRecordId = ""/>

    <cfif isDefined("FORM.canal_record_id") AND len(trim(FORM.canal_record_id))>
        <cfset VARIABLES.savedChannelRecordId = FORM.canal_record_id/>
        <cfquery>
            UPDATE tb_youtube_canais
            SET
            <cfset VARIABLES.channelFieldSeparator = ""/>
            <cfloop query="qChannelColumns">
                <cfif qChannelColumns.column_name NEQ VARIABLES.channelPk
                    AND NOT ListFindNoCase(VARIABLES.channelFormExcludedColumns, qChannelColumns.column_name)
                    AND StructKeyExists(FORM, "canal_" & qChannelColumns.column_name)>
                    <cfset VARIABLES.channelFieldValue = FORM["canal_" & qChannelColumns.column_name]/>
                    <cfset VARIABLES.channelFieldType = lcase(qChannelColumns.data_type)/>
                    <cfif VARIABLES.channelFieldType EQ "boolean">
                        <cfset VARIABLES.channelFieldValue = ListFindNoCase(VARIABLES.channelFieldValue, "true")
                            OR ListFindNoCase(VARIABLES.channelFieldValue, "1")
                            OR ListFindNoCase(VARIABLES.channelFieldValue, "yes")
                            OR ListFindNoCase(VARIABLES.channelFieldValue, "sim")
                            OR ListFindNoCase(VARIABLES.channelFieldValue, "on")/>
                    </cfif>
                    <cfset VARIABLES.channelFieldNullable = qChannelColumns.is_nullable EQ "YES"/>
                    <cfset VARIABLES.channelFieldHasValue = VARIABLES.channelFieldType EQ "boolean" OR (isSimpleValue(VARIABLES.channelFieldValue) AND len(trim(VARIABLES.channelFieldValue)))/>
                    <cfset VARIABLES.channelFieldIsNull = VARIABLES.channelFieldType NEQ "boolean" AND NOT VARIABLES.channelFieldHasValue/>
                    #VARIABLES.channelFieldSeparator#"#Replace(qChannelColumns.column_name, '"', '""', 'all')#" =
                    <cfswitch expression="#VARIABLES.channelFieldType#">
                        <cfcase value="boolean">
                            <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.channelFieldValue#"/>
                        </cfcase>
                        <cfcase value="integer,smallint">
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.channelFieldValue#" null="#VARIABLES.channelFieldIsNull#"/>
                        </cfcase>
                        <cfcase value="bigint">
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.channelFieldValue#" null="#VARIABLES.channelFieldIsNull#"/>
                        </cfcase>
                        <cfcase value="numeric,decimal,real,double precision">
                            <cfqueryparam cfsqltype="cf_sql_numeric" value="#VARIABLES.channelFieldValue#" null="#VARIABLES.channelFieldIsNull#"/>
                        </cfcase>
                        <cfcase value="date">
                            <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.channelFieldValue#" null="#VARIABLES.channelFieldIsNull#"/>
                        </cfcase>
                        <cfcase value="timestamp without time zone,timestamp with time zone">
                            <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.channelFieldValue#" null="#VARIABLES.channelFieldIsNull#"/>
                        </cfcase>
                        <cfdefaultcase>
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.channelFieldValue#" null="#VARIABLES.channelFieldIsNull#"/>
                        </cfdefaultcase>
                    </cfswitch>
                    <cfset VARIABLES.channelFieldSeparator = ", "/>
                </cfif>
            </cfloop>
            WHERE "#Replace(VARIABLES.channelPk, '"', '""', 'all')#" =
            <cfif IsNumeric(FORM.canal_record_id)>
                <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.canal_record_id#"/>
            <cfelse>
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.canal_record_id#"/>
            </cfif>
        </cfquery>
    <cfelse>
        <cfquery name="qChannelInsert">
            INSERT INTO tb_youtube_canais (
            <cfset VARIABLES.channelFieldSeparator = ""/>
            <cfloop query="qChannelColumns">
                <cfif qChannelColumns.column_name NEQ VARIABLES.channelPk
                    AND NOT ListFindNoCase(VARIABLES.channelFormExcludedColumns, qChannelColumns.column_name)
                    AND StructKeyExists(FORM, "canal_" & qChannelColumns.column_name)>
                    #VARIABLES.channelFieldSeparator#"#Replace(qChannelColumns.column_name, '"', '""', 'all')#"
                    <cfset VARIABLES.channelFieldSeparator = ", "/>
                </cfif>
            </cfloop>
            ) VALUES (
            <cfset VARIABLES.channelFieldSeparator = ""/>
            <cfloop query="qChannelColumns">
                <cfif qChannelColumns.column_name NEQ VARIABLES.channelPk
                    AND NOT ListFindNoCase(VARIABLES.channelFormExcludedColumns, qChannelColumns.column_name)
                    AND StructKeyExists(FORM, "canal_" & qChannelColumns.column_name)>
                    <cfset VARIABLES.channelFieldValue = FORM["canal_" & qChannelColumns.column_name]/>
                    <cfset VARIABLES.channelFieldType = lcase(qChannelColumns.data_type)/>
                    <cfif VARIABLES.channelFieldType EQ "boolean">
                        <cfset VARIABLES.channelFieldValue = ListFindNoCase(VARIABLES.channelFieldValue, "true")
                            OR ListFindNoCase(VARIABLES.channelFieldValue, "1")
                            OR ListFindNoCase(VARIABLES.channelFieldValue, "yes")
                            OR ListFindNoCase(VARIABLES.channelFieldValue, "sim")
                            OR ListFindNoCase(VARIABLES.channelFieldValue, "on")/>
                    </cfif>
                    <cfset VARIABLES.channelFieldNullable = qChannelColumns.is_nullable EQ "YES"/>
                    <cfset VARIABLES.channelFieldHasValue = VARIABLES.channelFieldType EQ "boolean" OR (isSimpleValue(VARIABLES.channelFieldValue) AND len(trim(VARIABLES.channelFieldValue)))/>
                    <cfset VARIABLES.channelFieldIsNull = VARIABLES.channelFieldType NEQ "boolean" AND NOT VARIABLES.channelFieldHasValue/>
                    #VARIABLES.channelFieldSeparator#
                    <cfswitch expression="#VARIABLES.channelFieldType#">
                        <cfcase value="boolean">
                            <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.channelFieldValue#"/>
                        </cfcase>
                        <cfcase value="integer,smallint">
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.channelFieldValue#" null="#VARIABLES.channelFieldIsNull#"/>
                        </cfcase>
                        <cfcase value="bigint">
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.channelFieldValue#" null="#VARIABLES.channelFieldIsNull#"/>
                        </cfcase>
                        <cfcase value="numeric,decimal,real,double precision">
                            <cfqueryparam cfsqltype="cf_sql_numeric" value="#VARIABLES.channelFieldValue#" null="#VARIABLES.channelFieldIsNull#"/>
                        </cfcase>
                        <cfcase value="date">
                            <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.channelFieldValue#" null="#VARIABLES.channelFieldIsNull#"/>
                        </cfcase>
                        <cfcase value="timestamp without time zone,timestamp with time zone">
                            <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.channelFieldValue#" null="#VARIABLES.channelFieldIsNull#"/>
                        </cfcase>
                        <cfdefaultcase>
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.channelFieldValue#" null="#VARIABLES.channelFieldIsNull#"/>
                        </cfdefaultcase>
                    </cfswitch>
                    <cfset VARIABLES.channelFieldSeparator = ", "/>
                </cfif>
            </cfloop>
            )
            RETURNING "#Replace(VARIABLES.channelPk, '"', '""', 'all')#"
        </cfquery>
        <cfif qChannelInsert.recordcount>
            <cfset VARIABLES.savedChannelRecordId = qChannelInsert[VARIABLES.channelPk][1]/>
        </cfif>
    </cfif>

    <cfset VARIABLES.channelRedirectUrl = "./?pagina=" & VARIABLES.mediaPage/>
    <cflocation addtoken="false" url="#VARIABLES.channelRedirectUrl#"/>
</cfif>

<cfif isDefined("URL.canal_acao")
    AND isDefined("qPerfil")
    AND qPerfil.recordcount
    AND qPerfil.is_admin
    AND len(trim(VARIABLES.channelPk))
    AND isDefined("URL.canal_id")>

    <cfif URL.canal_acao EQ "status"
        AND len(trim(VARIABLES.channelActiveColumn))
        AND isDefined("URL.status")>
        <cfquery>
            UPDATE tb_youtube_canais
            SET "#Replace(VARIABLES.channelActiveColumn, '"', '""', 'all')#" = <cfqueryparam cfsqltype="cf_sql_bit" value="#URL.status#"/>
            WHERE "#Replace(VARIABLES.channelPk, '"', '""', 'all')#" =
            <cfif IsNumeric(URL.canal_id)>
                <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.canal_id#"/>
            <cfelse>
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.canal_id#"/>
            </cfif>
        </cfquery>

        <cflocation addtoken="false" url="./?pagina=#VARIABLES.mediaPage#"/>
    </cfif>

    <cfif URL.canal_acao EQ "excluir">
        <cfquery>
            DELETE FROM tb_youtube_canais
            WHERE "#Replace(VARIABLES.channelPk, '"', '""', 'all')#" =
            <cfif IsNumeric(URL.canal_id)>
                <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.canal_id#"/>
            <cfelse>
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.canal_id#"/>
            </cfif>
        </cfquery>

        <cflocation addtoken="false" url="./?pagina=#VARIABLES.mediaPage#"/>
    </cfif>
</cfif>

<cfquery name="qChannelsCount">
    SELECT count(*) as total
    FROM tb_youtube_canais
</cfquery>

<cfif qChannelColumns.recordcount>
    <cfquery name="qChannels">
        SELECT #PreserveSingleQuotes(VARIABLES.channelSelectColumns)#
        FROM tb_youtube_canais
        ORDER BY "#Replace(VARIABLES.channelOrderColumn, '"', '""', 'all')#" DESC
    </cfquery>
<cfelse>
    <cfset qChannels = QueryNew("")/>
</cfif>

<cfset qChannelEdit = QueryNew("")/>

<cfif qChannelColumns.recordcount
    AND len(trim(VARIABLES.channelPk))
    AND isDefined("URL.canal_editar")
    AND len(trim(URL.canal_editar))>
    <cfquery name="qChannelEdit">
        SELECT #PreserveSingleQuotes(VARIABLES.channelSelectColumns)#
        FROM tb_youtube_canais
        WHERE "#Replace(VARIABLES.channelPk, '"', '""', 'all')#" =
        <cfif IsNumeric(URL.canal_editar)>
            <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.canal_editar#"/>
        <cfelse>
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.canal_editar#"/>
        </cfif>
        LIMIT 1
    </cfquery>
</cfif>
