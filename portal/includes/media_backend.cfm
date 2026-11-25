<cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin><cfheader statuscode="403"/><cfabort/></cfif>
<cfparam name="URL.pagina" default="1" type="numeric"/>
<cfparam name="URL.busca" default=""/>
<cfparam name="URL.status" default="todos"/>
<cfparam name="URL.destaque" default="todos"/>
<cfparam name="URL.vinculo" default="todos"/>
<cfparam name="URL.video_id" default=""/>
<cfparam name="URL.published" default=""/>
<cfparam name="URL.evento_busca" default=""/>
<cfparam name="URL.sucesso" default=""/>
<cfparam name="FORM.media_event_action" default=""/>
<cfset VARIABLES.mediaPageSize = 20/>
<cfset VARIABLES.mediaPage = max(1, int(URL.pagina))/>
<cfset VARIABLES.mediaOffset = (VARIABLES.mediaPage - 1) * VARIABLES.mediaPageSize/>
<cfset VARIABLES.mediaSearchTerm = left(trim(URL.busca),200)/>
<cfset VARIABLES.mediaStatusFilter = lCase(trim(URL.status))/>
<cfset VARIABLES.mediaFeaturedFilter = lCase(trim(URL.destaque))/>
<cfset VARIABLES.mediaLinkFilter = listFindNoCase("todos,sim,nao",URL.vinculo) ? lCase(URL.vinculo) : "todos"/>
<cfset VARIABLES.mediaEditId = reFind("^[1-9][0-9]{0,9}$",URL.video_id) AND val(URL.video_id) LTE 2147483647 ? val(URL.video_id) : 0/>
<cflock scope="session" type="exclusive" timeout="5">
  <cfif NOT structKeyExists(SESSION,"mediaEventCsrf")><cfset SESSION.mediaEventCsrf=lCase(hash(generateSecretKey("AES",256),"SHA-256"))/></cfif>
  <cfset VARIABLES.mediaEventCsrf=SESSION.mediaEventCsrf/>
</cflock>

<cfif NOT ListFindNoCase("todos,publicados,ocultos", VARIABLES.mediaStatusFilter)>
    <cfset VARIABLES.mediaStatusFilter = "todos"/>
</cfif>

<cfif NOT ListFindNoCase("todos,sim,nao", VARIABLES.mediaFeaturedFilter)>
    <cfset VARIABLES.mediaFeaturedFilter = "todos"/>
</cfif>

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
    <cfset VARIABLES.mediaSelectColumns = ListAppend(VARIABLES.mediaSelectColumns, 'media."' & Replace(qMediaColumns.column_name, '"', '""', 'all') & '"')/>
</cfloop>

<cfset VARIABLES.mediaHasPubStatus = ListFindNoCase(VARIABLES.mediaColumns, "pub_status")/>
<cfset VARIABLES.mediaHasUrl = ListFindNoCase(VARIABLES.mediaColumns, "media_url")/>
<cfset VARIABLES.mediaHasDurationSeconds = ListFindNoCase(VARIABLES.mediaColumns, "youtube_duration_seconds")/>
<cfset VARIABLES.mediaHasIsFeatured = ListFindNoCase(VARIABLES.mediaColumns, "is_featured")/>
<cfset VARIABLES.mediaHasEventId = ListFindNoCase(VARIABLES.mediaColumns, "id_evento")/>
<cfset VARIABLES.mediaMinimumPublishDurationSeconds = 210/>
<cfset VARIABLES.mediaOrderColumn = len(trim(VARIABLES.mediaPk)) ? VARIABLES.mediaPk : (qMediaColumns.recordcount ? qMediaColumns.column_name : "")/>
<cfset VARIABLES.mediaFeaturedEventAlert = {type = "", message = ""}/>

<cfset VARIABLES.mediaListUrl = "./?pagina=" & VARIABLES.mediaPage & "&busca=" & urlEncodedFormat(VARIABLES.mediaSearchTerm) & "&status=" & VARIABLES.mediaStatusFilter & "&destaque=" & VARIABLES.mediaFeaturedFilter & "&vinculo=" & VARIABLES.mediaLinkFilter/>
<cfinclude template="media_event_action.cfm"/>
<cfif len(VARIABLES.mediaEventSuccess)>
    <cflocation addtoken="false" url="#VARIABLES.mediaListUrl#&video_id=#VARIABLES.mediaEditId#&sucesso=#VARIABLES.mediaEventSuccess###video-evento"/>
</cfif>

<!--- Mantem a publicacao alinhada ao mesmo limite visual usado pela listagem. --->
<cfif VARIABLES.mediaHasPubStatus AND VARIABLES.mediaHasDurationSeconds>
    <cfquery>
        UPDATE tb_media
        SET pub_status = false
            <cfif VARIABLES.mediaHasIsFeatured>
                , is_featured = false
            </cfif>
        WHERE pub_status = true
          AND youtube_duration_seconds > 0
          AND youtube_duration_seconds < <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.mediaMinimumPublishDurationSeconds#"/>
    </cfquery>
</cfif>

<cfif VARIABLES.mediaHasPubStatus AND VARIABLES.mediaHasIsFeatured>
    <cfquery>
        UPDATE tb_media
        SET is_featured = false
        WHERE is_featured = true
          AND coalesce(pub_status, false) = false
    </cfquery>
</cfif>

<cfif isDefined("URL.acao")
    AND isDefined("qPerfil")
    AND qPerfil.recordcount
    AND qPerfil.is_admin
    AND len(trim(VARIABLES.mediaPk))
    AND isDefined("URL.media_id")>

    <cfif URL.acao EQ "pub_status"
        AND VARIABLES.mediaHasPubStatus
        AND len(trim(URL.published))>

        <cfset VARIABLES.mediaRequestedPubStatus = IsBoolean(URL.published) ? URL.published : ListFindNoCase("true,1,yes,sim", trim(URL.published & "")) GT 0/>

        <cfquery>
            UPDATE tb_media
            SET pub_status = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.mediaRequestedPubStatus#"/>
                <cfif VARIABLES.mediaHasIsFeatured AND NOT VARIABLES.mediaRequestedPubStatus>
                    , is_featured = false
                </cfif>
            WHERE "#Replace(VARIABLES.mediaPk, '"', '""', 'all')#" =
            <cfif IsNumeric(URL.media_id)>
                <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.media_id#"/>
            <cfelse>
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.media_id#"/>
            </cfif>
            <cfif VARIABLES.mediaRequestedPubStatus AND VARIABLES.mediaHasDurationSeconds>
                AND (
                    youtube_duration_seconds IS NULL
                    OR youtube_duration_seconds = 0
                    OR youtube_duration_seconds >= <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.mediaMinimumPublishDurationSeconds#"/>
                )
            </cfif>
        </cfquery>

        <cflocation addtoken="false" url="./?pagina=#VARIABLES.mediaPage#&busca=#urlEncodedFormat(VARIABLES.mediaSearchTerm)#&status=#urlEncodedFormat(VARIABLES.mediaStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.mediaFeaturedFilter)#&vinculo=#VARIABLES.mediaLinkFilter#"/>
    </cfif>

    <cfif URL.acao EQ "destaque"
        AND VARIABLES.mediaHasIsFeatured
        AND isDefined("URL.featured")
        AND len(trim(URL.featured))>

        <cfset VARIABLES.mediaToggleFeatured = IsBoolean(URL.featured) ? URL.featured : ListFindNoCase("true,1,yes,sim", trim(URL.featured & "")) GT 0/>

        <cftransaction>
            <cfif VARIABLES.mediaToggleFeatured>
                <cfquery name="qMediaFeaturedTarget">
                    SELECT "#Replace(VARIABLES.mediaPk, '"', '""', 'all')#" AS media_pk
                    FROM tb_media
                    WHERE "#Replace(VARIABLES.mediaPk, '"', '""', 'all')#" =
                    <cfif IsNumeric(URL.media_id)>
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.media_id#"/>
                    <cfelse>
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.media_id#"/>
                    </cfif>
                    <cfif VARIABLES.mediaHasPubStatus>
                        AND pub_status = true
                    </cfif>
                    FOR UPDATE
                </cfquery>

                <cfif qMediaFeaturedTarget.recordcount>
                    <cfquery>
                        UPDATE tb_media
                        SET is_featured = false
                        WHERE is_featured = true
                          AND "#Replace(VARIABLES.mediaPk, '"', '""', 'all')#" <>
                          <cfif IsNumeric(URL.media_id)>
                              <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.media_id#"/>
                          <cfelse>
                              <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.media_id#"/>
                          </cfif>
                    </cfquery>
                </cfif>
            </cfif>

            <cfquery>
                UPDATE tb_media
                SET is_featured = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.mediaToggleFeatured#"/>
                WHERE "#Replace(VARIABLES.mediaPk, '"', '""', 'all')#" =
                <cfif IsNumeric(URL.media_id)>
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.media_id#"/>
                <cfelse>
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.media_id#"/>
                </cfif>
                <cfif VARIABLES.mediaToggleFeatured AND VARIABLES.mediaHasPubStatus>
                    AND pub_status = true
                </cfif>
            </cfquery>
        </cftransaction>

        <cflocation addtoken="false" url="./?pagina=#VARIABLES.mediaPage#&busca=#urlEncodedFormat(VARIABLES.mediaSearchTerm)#&status=#urlEncodedFormat(VARIABLES.mediaStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.mediaFeaturedFilter)#&vinculo=#VARIABLES.mediaLinkFilter#"/>
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

        <cflocation addtoken="false" url="./?pagina=#VARIABLES.mediaPage#&busca=#urlEncodedFormat(VARIABLES.mediaSearchTerm)#&status=#urlEncodedFormat(VARIABLES.mediaStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.mediaFeaturedFilter)#&vinculo=#VARIABLES.mediaLinkFilter#"/>
    </cfif>
</cfif>

<cfquery name="qMediaCount">
    SELECT count(*) as total
    FROM tb_media media
    <cfif VARIABLES.mediaHasEventId>LEFT JOIN tb_evento_corridas evt ON evt.id_evento=media.id_evento</cfif>
    WHERE 1 = 1
      <cfif VARIABLES.mediaHasPubStatus AND VARIABLES.mediaStatusFilter EQ "publicados">
        AND coalesce(pub_status, false) = true
      <cfelseif VARIABLES.mediaHasPubStatus AND VARIABLES.mediaStatusFilter EQ "ocultos">
        AND coalesce(pub_status, false) = false
      </cfif>
      <cfif VARIABLES.mediaHasIsFeatured AND VARIABLES.mediaFeaturedFilter EQ "sim">
        AND coalesce(is_featured, false) = true
      <cfelseif VARIABLES.mediaHasIsFeatured AND VARIABLES.mediaFeaturedFilter EQ "nao">
        AND coalesce(is_featured, false) = false
      </cfif>
      <cfif VARIABLES.mediaHasEventId AND VARIABLES.mediaLinkFilter EQ "sim">AND coalesce(media.id_evento,0)>0
      <cfelseif VARIABLES.mediaHasEventId AND VARIABLES.mediaLinkFilter EQ "nao">AND coalesce(media.id_evento,0)=0</cfif>
      <cfif len(VARIABLES.mediaSearchTerm)>
        AND (
            unaccent(lower(coalesce(media_titulo, ''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.mediaSearchTerm#%"/>))
            OR unaccent(lower(coalesce(media_canal_nome, ''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.mediaSearchTerm#%"/>))
            OR unaccent(lower(coalesce(media_url, ''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.mediaSearchTerm#%"/>))
            <cfif VARIABLES.mediaHasEventId>OR unaccent(lower(coalesce(evt.nome_evento,''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.mediaSearchTerm#%"/>))</cfif>
        )
      </cfif>
</cfquery>

<cfset VARIABLES.mediaTotalPages = max(1, ceiling(qMediaCount.total / VARIABLES.mediaPageSize))/>

<cfif VARIABLES.mediaPage GT VARIABLES.mediaTotalPages>
    <cfset VARIABLES.mediaPage = VARIABLES.mediaTotalPages/>
    <cfset VARIABLES.mediaOffset = (VARIABLES.mediaPage - 1) * VARIABLES.mediaPageSize/>
</cfif>

<cfset VARIABLES.mediaListUrl = "./?pagina=" & VARIABLES.mediaPage & "&busca=" & urlEncodedFormat(VARIABLES.mediaSearchTerm) & "&status=" & VARIABLES.mediaStatusFilter & "&destaque=" & VARIABLES.mediaFeaturedFilter & "&vinculo=" & VARIABLES.mediaLinkFilter/>

<cfquery name="qMediaStats">
    SELECT
        count(*) AS total,
        count(*) FILTER (WHERE <cfif VARIABLES.mediaHasPubStatus>coalesce(pub_status, false) = true<cfelse>false</cfif>) AS total_publicados,
        count(*) FILTER (WHERE <cfif VARIABLES.mediaHasPubStatus>coalesce(pub_status, false) = false<cfelse>false</cfif>) AS total_ocultos,
        count(*) FILTER (WHERE <cfif VARIABLES.mediaHasIsFeatured>coalesce(is_featured, false) = true<cfelse>false</cfif>) AS total_destaques,
        count(*) FILTER (WHERE <cfif VARIABLES.mediaHasEventId>coalesce(id_evento,0)>0<cfelse>false</cfif>) AS total_vinculados
    FROM tb_media
</cfquery>

<cfif VARIABLES.mediaHasIsFeatured>
    <cfquery name="qMediaFeaturedCurrent">
        SELECT media."#Replace(VARIABLES.mediaPk, '"', '""', 'all')#" AS media_pk,
               <cfif ListFindNoCase(VARIABLES.mediaColumns, "media_titulo")>media.media_titulo<cfelse>NULL::text</cfif> AS media_titulo,
               <cfif VARIABLES.mediaHasUrl>media.media_url<cfelse>NULL::text</cfif> AS media_url,
               <cfif VARIABLES.mediaHasPubStatus>coalesce(media.pub_status, false)<cfelse>true</cfif> AS pub_status,
               <cfif VARIABLES.mediaHasEventId>
                   media.id_evento,
                   evt.nome_evento AS evento_nome,
                   evt.tag AS evento_tag,
                   evt.data_inicial AS evento_data_inicial,
                   evt.cidade AS evento_cidade,
                   evt.estado AS evento_estado
               <cfelse>
                   NULL::integer AS id_evento,
                   NULL::text AS evento_nome,
                   NULL::text AS evento_tag,
                   NULL::timestamp AS evento_data_inicial,
                   NULL::text AS evento_cidade,
                   NULL::text AS evento_estado
               </cfif>
        FROM tb_media media
        <cfif VARIABLES.mediaHasEventId>
            LEFT JOIN tb_evento_corridas evt ON evt.id_evento = media.id_evento
        </cfif>
        WHERE coalesce(media.is_featured, false) = true
        ORDER BY media."#Replace(VARIABLES.mediaOrderColumn, '"', '""', 'all')#" DESC
        LIMIT 1
    </cfquery>
<cfelse>
    <cfset qMediaFeaturedCurrent = QueryNew("media_pk,media_titulo,media_url,pub_status,id_evento,evento_nome,evento_tag,evento_data_inicial,evento_cidade,evento_estado")/>
</cfif>

<cfset qMediaEventEdit=QueryNew("media_pk,media_titulo,media_url,id_evento,evento_nome,evento_data_inicial,evento_cidade,evento_estado")/>
<cfif VARIABLES.mediaHasEventId AND VARIABLES.mediaEditId GT 0>
 <cfquery name="qMediaEventEdit">
  SELECT media."#Replace(VARIABLES.mediaPk,'"','""','all')#" AS media_pk,media.media_titulo,media.media_url,media.id_evento,
    evt.nome_evento AS evento_nome,evt.data_inicial AS evento_data_inicial,evt.cidade AS evento_cidade,evt.estado AS evento_estado
  FROM tb_media media LEFT JOIN tb_evento_corridas evt ON evt.id_evento=media.id_evento
  WHERE media."#Replace(VARIABLES.mediaPk,'"','""','all')#"=<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.mediaEditId#"/>
 </cfquery>
</cfif>
<cfset qMediaFeaturedEventSearch = QueryNew("id_evento,nome_evento,tag,data_inicial,data_final,cidade,estado,status_evento,ativo")/>
<cfif VARIABLES.mediaHasEventId
    AND VARIABLES.mediaEditId GT 0
    AND (len(trim(URL.evento_busca)) GTE 2 OR reFind("^[1-9][0-9]{0,9}$",trim(URL.evento_busca)))>
    <cfset VARIABLES.mediaFeaturedEventSearchTerm = left(trim(URL.evento_busca),150)/>
    <cfquery name="qMediaFeaturedEventSearch">
        SELECT evt.id_evento,
               evt.nome_evento,
               evt.tag,
               evt.data_inicial,
               evt.data_final,
               evt.cidade,
               evt.estado,
               evt.status_evento,
               evt.ativo
        FROM tb_evento_corridas evt
        WHERE
            <cfif reFind("^[1-9][0-9]{0,9}$",VARIABLES.mediaFeaturedEventSearchTerm) AND val(VARIABLES.mediaFeaturedEventSearchTerm) LTE 2147483647>
                evt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.mediaFeaturedEventSearchTerm#"/>
                OR
            </cfif>
            unaccent(lower(coalesce(evt.nome_evento, ''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.mediaFeaturedEventSearchTerm#%"/>))
            OR unaccent(lower(coalesce(evt.tag, ''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.mediaFeaturedEventSearchTerm#%"/>))
            OR unaccent(lower(coalesce(evt.cidade, ''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.mediaFeaturedEventSearchTerm#%"/>))
        ORDER BY
            CASE WHEN coalesce(evt.data_final, evt.data_inicial) >= current_date THEN 0 ELSE 1 END,
            CASE WHEN coalesce(evt.data_final, evt.data_inicial) >= current_date THEN evt.data_inicial END ASC NULLS LAST,
            CASE WHEN coalesce(evt.data_final, evt.data_inicial) < current_date THEN evt.data_inicial END DESC NULLS LAST,
            evt.id_evento DESC
        LIMIT 30
    </cfquery>
</cfif>

<cfif qMediaColumns.recordcount>
    <cfquery name="qMedia">
        SELECT #PreserveSingleQuotes(VARIABLES.mediaSelectColumns)#,
          <cfif VARIABLES.mediaHasEventId>evt.nome_evento,evt.data_inicial AS evento_data,evt.cidade AS evento_cidade,evt.estado AS evento_estado
          <cfelse>NULL::text AS nome_evento,NULL::timestamp AS evento_data,NULL::text AS evento_cidade,NULL::text AS evento_estado</cfif>
        FROM tb_media media
        <cfif VARIABLES.mediaHasEventId>LEFT JOIN tb_evento_corridas evt ON evt.id_evento=media.id_evento</cfif>
        WHERE 1 = 1
          <cfif VARIABLES.mediaHasPubStatus AND VARIABLES.mediaStatusFilter EQ "publicados">
            AND coalesce(pub_status, false) = true
          <cfelseif VARIABLES.mediaHasPubStatus AND VARIABLES.mediaStatusFilter EQ "ocultos">
            AND coalesce(pub_status, false) = false
          </cfif>
          <cfif VARIABLES.mediaHasIsFeatured AND VARIABLES.mediaFeaturedFilter EQ "sim">
            AND coalesce(is_featured, false) = true
          <cfelseif VARIABLES.mediaHasIsFeatured AND VARIABLES.mediaFeaturedFilter EQ "nao">
            AND coalesce(is_featured, false) = false
          </cfif>
          <cfif VARIABLES.mediaHasEventId AND VARIABLES.mediaLinkFilter EQ "sim">AND coalesce(media.id_evento,0)>0
      <cfelseif VARIABLES.mediaHasEventId AND VARIABLES.mediaLinkFilter EQ "nao">AND coalesce(media.id_evento,0)=0</cfif>
      <cfif len(VARIABLES.mediaSearchTerm)>
            AND (
                unaccent(lower(coalesce(media_titulo, ''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.mediaSearchTerm#%"/>))
                OR unaccent(lower(coalesce(media_canal_nome, ''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.mediaSearchTerm#%"/>))
                OR unaccent(lower(coalesce(media_url, ''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.mediaSearchTerm#%"/>))
            <cfif VARIABLES.mediaHasEventId>OR unaccent(lower(coalesce(evt.nome_evento,''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.mediaSearchTerm#%"/>))</cfif>
            )
          </cfif>
        ORDER BY "#Replace(VARIABLES.mediaOrderColumn, '"', '""', 'all')#" DESC
        LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.mediaPageSize#"/>
        OFFSET <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.mediaOffset#"/>
    </cfquery>
<cfelse>
    <cfset qMedia = QueryNew("")/>
</cfif>
