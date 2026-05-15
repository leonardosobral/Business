<cfparam name="URL.pagina" default="1" type="numeric"/>
<cfset VARIABLES.notificationTemplatePage = max(1, int(URL.pagina))/>

<cfquery name="qNotificationTemplateColumns">
    SELECT column_name, data_type, is_nullable, character_maximum_length
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'tb_notifica_template'
    ORDER BY ordinal_position
</cfquery>

<cfset VARIABLES.notificationTemplateColumns = ValueList(qNotificationTemplateColumns.column_name)/>
<cfset VARIABLES.notificationTemplatePk = ""/>
<cfset VARIABLES.notificationTemplateSelectColumns = ""/>
<cfset VARIABLES.notificationTemplateFormExcludedColumns = "created_at,updated_at,data_cadastro,data_atualizacao,data_criacao,data_alteracao,criado_em,atualizado_em"/>
<cfset VARIABLES.notificationTemplateVisibleColumns = "id_notifica_template,id_template,id,titulo,title,nome,name,chave,template_key,assunto,subject,status,ativo,is_active"/>

<cfloop list="id_notifica_template,id_template,id" item="notificationTemplatePkCandidate">
    <cfif NOT len(trim(VARIABLES.notificationTemplatePk)) AND ListFindNoCase(VARIABLES.notificationTemplateColumns, notificationTemplatePkCandidate)>
        <cfset VARIABLES.notificationTemplatePk = notificationTemplatePkCandidate/>
    </cfif>
</cfloop>

<cfif NOT len(trim(VARIABLES.notificationTemplatePk)) AND qNotificationTemplateColumns.recordcount>
    <cfset VARIABLES.notificationTemplatePk = qNotificationTemplateColumns.column_name/>
</cfif>

<cfloop query="qNotificationTemplateColumns">
    <cfset VARIABLES.notificationTemplateSelectColumns = ListAppend(VARIABLES.notificationTemplateSelectColumns, '"' & Replace(qNotificationTemplateColumns.column_name, '"', '""', 'all') & '"')/>
</cfloop>

<cfif isDefined("FORM.template_action")
    AND FORM.template_action EQ "salvar"
    AND isDefined("qPerfil")
    AND qPerfil.recordcount
    AND qPerfil.is_admin
    AND len(trim(VARIABLES.notificationTemplatePk))
    AND qNotificationTemplateColumns.recordcount>

    <cfset VARIABLES.notificationTemplateSavedRecordId = ""/>

    <cfif isDefined("FORM.template_record_id") AND len(trim(FORM.template_record_id))>
        <cfset VARIABLES.notificationTemplateSavedRecordId = FORM.template_record_id/>
        <cfquery>
            UPDATE tb_notifica_template
            SET
            <cfset VARIABLES.notificationTemplateFieldSeparator = ""/>
            <cfloop query="qNotificationTemplateColumns">
                <cfif qNotificationTemplateColumns.column_name NEQ VARIABLES.notificationTemplatePk
                    AND NOT ListFindNoCase(VARIABLES.notificationTemplateFormExcludedColumns, qNotificationTemplateColumns.column_name)
                    AND StructKeyExists(FORM, "template_" & qNotificationTemplateColumns.column_name)>
                    <cfset VARIABLES.notificationTemplateFieldValue = FORM["template_" & qNotificationTemplateColumns.column_name]/>
                    <cfset VARIABLES.notificationTemplateFieldType = lcase(qNotificationTemplateColumns.data_type)/>
                    <cfif VARIABLES.notificationTemplateFieldType EQ "boolean">
                        <cfset VARIABLES.notificationTemplateFieldValue = ListFindNoCase(VARIABLES.notificationTemplateFieldValue, "true")
                            OR ListFindNoCase(VARIABLES.notificationTemplateFieldValue, "1")
                            OR ListFindNoCase(VARIABLES.notificationTemplateFieldValue, "yes")
                            OR ListFindNoCase(VARIABLES.notificationTemplateFieldValue, "sim")
                            OR ListFindNoCase(VARIABLES.notificationTemplateFieldValue, "on")/>
                    </cfif>
                    <cfif qNotificationTemplateColumns.column_name EQ "data_publicacao"
                        AND ListFindNoCase("timestamp without time zone,timestamp with time zone", VARIABLES.notificationTemplateFieldType)
                        AND (NOT isSimpleValue(VARIABLES.notificationTemplateFieldValue) OR NOT len(trim(VARIABLES.notificationTemplateFieldValue)))>
                        <cfset VARIABLES.notificationTemplateFieldValue = now()/>
                    </cfif>
                    <cfif VARIABLES.notificationTemplateFieldType EQ "date"
                        AND isSimpleValue(VARIABLES.notificationTemplateFieldValue)
                        AND Find("T", VARIABLES.notificationTemplateFieldValue)>
                        <cfset VARIABLES.notificationTemplateFieldValue = left(VARIABLES.notificationTemplateFieldValue, 10)/>
                    <cfelseif ListFindNoCase("timestamp without time zone,timestamp with time zone", VARIABLES.notificationTemplateFieldType)
                        AND isSimpleValue(VARIABLES.notificationTemplateFieldValue)
                        AND len(trim(VARIABLES.notificationTemplateFieldValue))>
                        <cfset VARIABLES.notificationTemplateFieldValue = Replace(trim(VARIABLES.notificationTemplateFieldValue), "T", " ", "one")/>
                        <cfif reFind("^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$", VARIABLES.notificationTemplateFieldValue)>
                            <cfset VARIABLES.notificationTemplateFieldValue &= ":00"/>
                        </cfif>
                    </cfif>
                    <cfset VARIABLES.notificationTemplateFieldHasValue = VARIABLES.notificationTemplateFieldType EQ "boolean" OR (isSimpleValue(VARIABLES.notificationTemplateFieldValue) AND len(trim(VARIABLES.notificationTemplateFieldValue))) />
                    <cfset VARIABLES.notificationTemplateFieldIsNull = VARIABLES.notificationTemplateFieldType NEQ "boolean" AND NOT VARIABLES.notificationTemplateFieldHasValue/>
                    #VARIABLES.notificationTemplateFieldSeparator#"#Replace(qNotificationTemplateColumns.column_name, '"', '""', 'all')#" =
                    <cfswitch expression="#VARIABLES.notificationTemplateFieldType#">
                        <cfcase value="boolean">
                            <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.notificationTemplateFieldValue#"/>
                        </cfcase>
                        <cfcase value="integer,smallint">
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificationTemplateFieldValue#" null="#VARIABLES.notificationTemplateFieldIsNull#"/>
                        </cfcase>
                        <cfcase value="bigint">
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.notificationTemplateFieldValue#" null="#VARIABLES.notificationTemplateFieldIsNull#"/>
                        </cfcase>
                        <cfcase value="numeric,decimal,real,double precision">
                            <cfqueryparam cfsqltype="cf_sql_numeric" value="#VARIABLES.notificationTemplateFieldValue#" null="#VARIABLES.notificationTemplateFieldIsNull#"/>
                        </cfcase>
                        <cfcase value="date">
                            <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.notificationTemplateFieldValue#" null="#VARIABLES.notificationTemplateFieldIsNull#"/>
                        </cfcase>
                        <cfcase value="timestamp without time zone,timestamp with time zone">
                            <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.notificationTemplateFieldValue#" null="#VARIABLES.notificationTemplateFieldIsNull#"/>
                        </cfcase>
                        <cfdefaultcase>
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notificationTemplateFieldValue#" null="#VARIABLES.notificationTemplateFieldIsNull#"/>
                        </cfdefaultcase>
                    </cfswitch>
                    <cfset VARIABLES.notificationTemplateFieldSeparator = ", "/>
                </cfif>
            </cfloop>
            WHERE "#Replace(VARIABLES.notificationTemplatePk, '"', '""', 'all')#" =
            <cfif IsNumeric(FORM.template_record_id)>
                <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.template_record_id#"/>
            <cfelse>
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.template_record_id#"/>
            </cfif>
        </cfquery>
    <cfelse>
        <cfif VARIABLES.notificationTemplatePk EQ "id_notifica_template">
            <cfquery>
                SELECT setval(
                    pg_get_serial_sequence('tb_notifica_template', 'id_notifica_template'),
                    COALESCE((SELECT MAX(id_notifica_template) FROM tb_notifica_template), 0),
                    true
                )
            </cfquery>
        </cfif>

        <cfquery name="qNotificationTemplateInsert">
            INSERT INTO tb_notifica_template (
            <cfset VARIABLES.notificationTemplateFieldSeparator = ""/>
            <cfloop query="qNotificationTemplateColumns">
                <cfif qNotificationTemplateColumns.column_name NEQ VARIABLES.notificationTemplatePk
                    AND NOT ListFindNoCase(VARIABLES.notificationTemplateFormExcludedColumns, qNotificationTemplateColumns.column_name)
                    AND StructKeyExists(FORM, "template_" & qNotificationTemplateColumns.column_name)>
                    #VARIABLES.notificationTemplateFieldSeparator#"#Replace(qNotificationTemplateColumns.column_name, '"', '""', 'all')#"
                    <cfset VARIABLES.notificationTemplateFieldSeparator = ", "/>
                </cfif>
            </cfloop>
            ) VALUES (
            <cfset VARIABLES.notificationTemplateFieldSeparator = ""/>
            <cfloop query="qNotificationTemplateColumns">
                <cfif qNotificationTemplateColumns.column_name NEQ VARIABLES.notificationTemplatePk
                    AND NOT ListFindNoCase(VARIABLES.notificationTemplateFormExcludedColumns, qNotificationTemplateColumns.column_name)
                    AND StructKeyExists(FORM, "template_" & qNotificationTemplateColumns.column_name)>
                    <cfset VARIABLES.notificationTemplateFieldValue = FORM["template_" & qNotificationTemplateColumns.column_name]/>
                    <cfset VARIABLES.notificationTemplateFieldType = lcase(qNotificationTemplateColumns.data_type)/>
                    <cfif VARIABLES.notificationTemplateFieldType EQ "boolean">
                        <cfset VARIABLES.notificationTemplateFieldValue = ListFindNoCase(VARIABLES.notificationTemplateFieldValue, "true")
                            OR ListFindNoCase(VARIABLES.notificationTemplateFieldValue, "1")
                            OR ListFindNoCase(VARIABLES.notificationTemplateFieldValue, "yes")
                            OR ListFindNoCase(VARIABLES.notificationTemplateFieldValue, "sim")
                            OR ListFindNoCase(VARIABLES.notificationTemplateFieldValue, "on")/>
                    </cfif>
                    <cfif qNotificationTemplateColumns.column_name EQ "data_publicacao"
                        AND ListFindNoCase("timestamp without time zone,timestamp with time zone", VARIABLES.notificationTemplateFieldType)
                        AND (NOT isSimpleValue(VARIABLES.notificationTemplateFieldValue) OR NOT len(trim(VARIABLES.notificationTemplateFieldValue)))>
                        <cfset VARIABLES.notificationTemplateFieldValue = now()/>
                    </cfif>
                    <cfif VARIABLES.notificationTemplateFieldType EQ "date"
                        AND isSimpleValue(VARIABLES.notificationTemplateFieldValue)
                        AND Find("T", VARIABLES.notificationTemplateFieldValue)>
                        <cfset VARIABLES.notificationTemplateFieldValue = left(VARIABLES.notificationTemplateFieldValue, 10)/>
                    <cfelseif ListFindNoCase("timestamp without time zone,timestamp with time zone", VARIABLES.notificationTemplateFieldType)
                        AND isSimpleValue(VARIABLES.notificationTemplateFieldValue)
                        AND len(trim(VARIABLES.notificationTemplateFieldValue))>
                        <cfset VARIABLES.notificationTemplateFieldValue = Replace(trim(VARIABLES.notificationTemplateFieldValue), "T", " ", "one")/>
                        <cfif reFind("^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$", VARIABLES.notificationTemplateFieldValue)>
                            <cfset VARIABLES.notificationTemplateFieldValue &= ":00"/>
                        </cfif>
                    </cfif>
                    <cfset VARIABLES.notificationTemplateFieldHasValue = VARIABLES.notificationTemplateFieldType EQ "boolean" OR (isSimpleValue(VARIABLES.notificationTemplateFieldValue) AND len(trim(VARIABLES.notificationTemplateFieldValue))) />
                    <cfset VARIABLES.notificationTemplateFieldIsNull = VARIABLES.notificationTemplateFieldType NEQ "boolean" AND NOT VARIABLES.notificationTemplateFieldHasValue/>
                    #VARIABLES.notificationTemplateFieldSeparator#
                    <cfswitch expression="#VARIABLES.notificationTemplateFieldType#">
                        <cfcase value="boolean">
                            <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.notificationTemplateFieldValue#"/>
                        </cfcase>
                        <cfcase value="integer,smallint">
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificationTemplateFieldValue#" null="#VARIABLES.notificationTemplateFieldIsNull#"/>
                        </cfcase>
                        <cfcase value="bigint">
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.notificationTemplateFieldValue#" null="#VARIABLES.notificationTemplateFieldIsNull#"/>
                        </cfcase>
                        <cfcase value="numeric,decimal,real,double precision">
                            <cfqueryparam cfsqltype="cf_sql_numeric" value="#VARIABLES.notificationTemplateFieldValue#" null="#VARIABLES.notificationTemplateFieldIsNull#"/>
                        </cfcase>
                        <cfcase value="date">
                            <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.notificationTemplateFieldValue#" null="#VARIABLES.notificationTemplateFieldIsNull#"/>
                        </cfcase>
                        <cfcase value="timestamp without time zone,timestamp with time zone">
                            <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.notificationTemplateFieldValue#" null="#VARIABLES.notificationTemplateFieldIsNull#"/>
                        </cfcase>
                        <cfdefaultcase>
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notificationTemplateFieldValue#" null="#VARIABLES.notificationTemplateFieldIsNull#"/>
                        </cfdefaultcase>
                    </cfswitch>
                    <cfset VARIABLES.notificationTemplateFieldSeparator = ", "/>
                </cfif>
            </cfloop>
            )
            RETURNING "#Replace(VARIABLES.notificationTemplatePk, '"', '""', 'all')#"
        </cfquery>
        <cfif qNotificationTemplateInsert.recordcount>
            <cfset VARIABLES.notificationTemplateSavedRecordId = qNotificationTemplateInsert[VARIABLES.notificationTemplatePk][1]/>
        </cfif>
    </cfif>

    <cflocation addtoken="false" url="./?pagina=#VARIABLES.notificationTemplatePage#"/>
</cfif>

<cfif isDefined("URL.acao")
    AND URL.acao EQ "excluir"
    AND isDefined("URL.template_id")
    AND isDefined("qPerfil")
    AND qPerfil.recordcount
    AND qPerfil.is_admin
    AND len(trim(VARIABLES.notificationTemplatePk))>

    <cfquery>
        DELETE FROM tb_notifica_template
        WHERE "#Replace(VARIABLES.notificationTemplatePk, '"', '""', 'all')#" =
        <cfif IsNumeric(URL.template_id)>
            <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.template_id#"/>
        <cfelse>
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.template_id#"/>
        </cfif>
    </cfquery>

    <cflocation addtoken="false" url="./?pagina=#VARIABLES.notificationTemplatePage#"/>
</cfif>

<cfif qNotificationTemplateColumns.recordcount>
    <cfquery name="qNotificationTemplateCount">
        SELECT count(*) AS total
        FROM tb_notifica_template
    </cfquery>
<cfelse>
    <cfset qNotificationTemplateCount = QueryNew("total", "integer")/>
    <cfset QueryAddRow(qNotificationTemplateCount, 1)/>
    <cfset QuerySetCell(qNotificationTemplateCount, "total", 0, 1)/>
</cfif>

<cfif qNotificationTemplateColumns.recordcount>
    <cfquery name="qNotificationTemplates">
        SELECT #PreserveSingleQuotes(VARIABLES.notificationTemplateSelectColumns)#
        FROM tb_notifica_template
        ORDER BY "#Replace(VARIABLES.notificationTemplatePk, '"', '""', 'all')#" DESC
    </cfquery>
<cfelse>
    <cfset qNotificationTemplates = QueryNew("")/>
</cfif>

<cfset qNotificationTemplateEdit = QueryNew("")/>

<cfif qNotificationTemplateColumns.recordcount
    AND len(trim(VARIABLES.notificationTemplatePk))
    AND isDefined("URL.template_editar")
    AND len(trim(URL.template_editar))>
    <cfquery name="qNotificationTemplateEdit">
        SELECT #PreserveSingleQuotes(VARIABLES.notificationTemplateSelectColumns)#
        FROM tb_notifica_template
        WHERE "#Replace(VARIABLES.notificationTemplatePk, '"', '""', 'all')#" =
        <cfif IsNumeric(URL.template_editar)>
            <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.template_editar#"/>
        <cfelse>
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.template_editar#"/>
        </cfif>
        LIMIT 1
    </cfquery>
</cfif>
