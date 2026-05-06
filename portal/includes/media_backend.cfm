<cfparam name="URL.pagina" default="1" type="numeric"/>
<cfset VARIABLES.mediaPageSize = 20/>
<cfset VARIABLES.mediaPage = max(1, int(URL.pagina))/>
<cfset VARIABLES.mediaOffset = (VARIABLES.mediaPage - 1) * VARIABLES.mediaPageSize/>

<cfquery name="qMediaColumns">
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'tb_media'
    AND column_name <> 'media_descricao'
    ORDER BY ordinal_position
</cfquery>

<cfset VARIABLES.mediaColumns = ValueList(qMediaColumns.column_name)/>
<cfset VARIABLES.mediaPk = ""/>
<cfset VARIABLES.mediaSelectColumns = ""/>

<cfloop list="id_media,media_id,id" item="mediaPkCandidate">
    <cfif NOT len(trim(VARIABLES.mediaPk)) AND ListFindNoCase(VARIABLES.mediaColumns, mediaPkCandidate)>
        <cfset VARIABLES.mediaPk = mediaPkCandidate/>
    </cfif>
</cfloop>

<cfif NOT len(trim(VARIABLES.mediaPk)) AND qMediaColumns.recordcount>
    <cfset VARIABLES.mediaPk = qMediaColumns.column_name/>
</cfif>

<cfloop query="qMediaColumns">
    <cfset VARIABLES.mediaSelectColumns = ListAppend(VARIABLES.mediaSelectColumns, '"' & Replace(qMediaColumns.column_name, '"', '""', 'all') & '"')/>
</cfloop>

<cfset VARIABLES.mediaHasPubStatus = ListFindNoCase(VARIABLES.mediaColumns, "pub_status")/>
<cfset VARIABLES.mediaHasUrl = ListFindNoCase(VARIABLES.mediaColumns, "media_url")/>
<cfset VARIABLES.mediaOrderColumn = len(trim(VARIABLES.mediaPk)) ? VARIABLES.mediaPk : (qMediaColumns.recordcount ? qMediaColumns.column_name : "")/>

<cfif isDefined("URL.acao")
    AND isDefined("qPerfil")
    AND qPerfil.recordcount
    AND qPerfil.is_admin
    AND len(trim(VARIABLES.mediaPk))
    AND isDefined("URL.media_id")>

    <cfif URL.acao EQ "pub_status"
        AND VARIABLES.mediaHasPubStatus
        AND isDefined("URL.status")>

        <cfquery>
            UPDATE tb_media
            SET pub_status = <cfqueryparam cfsqltype="cf_sql_bit" value="#URL.status#"/>
            WHERE "#Replace(VARIABLES.mediaPk, '"', '""', 'all')#" =
            <cfif IsNumeric(URL.media_id)>
                <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.media_id#"/>
            <cfelse>
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.media_id#"/>
            </cfif>
        </cfquery>

        <cflocation addtoken="false" url="./?pagina=#VARIABLES.mediaPage#"/>
    </cfif>

    <cfif URL.acao EQ "excluir">
        <cfquery>
            DELETE FROM tb_media
            WHERE "#Replace(VARIABLES.mediaPk, '"', '""', 'all')#" =
            <cfif IsNumeric(URL.media_id)>
                <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.media_id#"/>
            <cfelse>
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.media_id#"/>
            </cfif>
        </cfquery>

        <cflocation addtoken="false" url="./?pagina=#VARIABLES.mediaPage#"/>
    </cfif>
</cfif>

<cfquery name="qMediaCount">
    SELECT count(*) as total
    FROM tb_media
</cfquery>

<cfset VARIABLES.mediaTotalPages = max(1, ceiling(qMediaCount.total / VARIABLES.mediaPageSize))/>

<cfif VARIABLES.mediaPage GT VARIABLES.mediaTotalPages>
    <cfset VARIABLES.mediaPage = VARIABLES.mediaTotalPages/>
    <cfset VARIABLES.mediaOffset = (VARIABLES.mediaPage - 1) * VARIABLES.mediaPageSize/>
</cfif>

<cfif qMediaColumns.recordcount>
    <cfquery name="qMedia">
        SELECT #PreserveSingleQuotes(VARIABLES.mediaSelectColumns)#
        FROM tb_media
        ORDER BY "#Replace(VARIABLES.mediaOrderColumn, '"', '""', 'all')#" DESC
        LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.mediaPageSize#"/>
        OFFSET <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.mediaOffset#"/>
    </cfquery>
<cfelse>
    <cfset qMedia = QueryNew("")/>
</cfif>
