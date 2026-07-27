<cfparam name="URL.busca" default="" />
<cfparam name="URL.id" default="" />
<cfparam name="URL.evento_busca" default="" />
<cfparam name="URL.sucesso" default="" />
<cfparam name="FORM.acao" default="" />
<cfparam name="FORM.csrf_token" default="" />

<cfset VARIABLES.aggregatorSearch = trim(URL.busca & "") />
<cfset VARIABLES.aggregatorId = isNumeric(URL.id) ? val(URL.id) : 0 />
<cfset VARIABLES.aggregatorEventSearch = trim(URL.evento_busca & "") />
<cfset VARIABLES.aggregatorNotice = "" />
<cfset VARIABLES.aggregatorError = "" />
<cfset qAggregators = queryNew("id_agrega_evento,nome_evento_agregado,tipo_agregacao,tag,id_tema,divisao,ordem,total_eventos") />
<cfset qAggregator = queryNew("id_agrega_evento,nome_evento_agregado,tipo_agregacao,tag,id_tema,divisao,ordem") />
<cfset qAggregatorEvents = queryNew("id_evento,nome_evento,tag,cidade,estado,data_inicial,data_final,ativo") />
<cfset qAggregatorEventSearch = queryNew("id_evento,nome_evento,tag,cidade,estado,data_inicial,data_final,id_agrega_evento,agregador_atual") />
<cfset qAggregatorThemes = queryNew("id_tema,nome_tema") />

<cfif NOT structKeyExists(SESSION, "aggregatorManagerCsrf") OR NOT len(trim(SESSION.aggregatorManagerCsrf & ""))>
  <cfset SESSION.aggregatorManagerCsrf = lCase(hash(createUUID() & now() & rand(), "SHA-256")) />
</cfif>
<cfset VARIABLES.aggregatorCsrf = SESSION.aggregatorManagerCsrf />

<cfswitch expression="#URL.sucesso#">
  <cfcase value="salvo"><cfset VARIABLES.aggregatorNotice = "Dados do agregador atualizados." /></cfcase>
  <cfcase value="adicionados"><cfset VARIABLES.aggregatorNotice = "Eventos adicionados ao agregador." /></cfcase>
  <cfcase value="removido"><cfset VARIABLES.aggregatorNotice = "Evento removido do agregador." /></cfcase>
</cfswitch>

<cfif len(trim(FORM.acao))>
  <cftry>
    <cfif compareNoCase(trim(FORM.csrf_token & ""), VARIABLES.aggregatorCsrf) NEQ 0>
      <cfthrow type="AggregatorManager.Validation" message="A sessão do formulário expirou. Recarregue a página." />
    </cfif>

    <cfif FORM.acao EQ "salvar">
      <cfset VARIABLES.saveAggregatorId = isDefined("FORM.id_agrega_evento") ? val(FORM.id_agrega_evento) : 0 />
      <cfset VARIABLES.saveAggregatorName = isDefined("FORM.nome_evento_agregado") ? trim(FORM.nome_evento_agregado) : "" />
      <cfset VARIABLES.saveAggregatorType = isDefined("FORM.tipo_agregacao") ? trim(FORM.tipo_agregacao) : "" />
      <cfset VARIABLES.saveAggregatorTag = isDefined("FORM.tag") ? trim(FORM.tag) : "" />
      <cfset VARIABLES.saveAggregatorThemeId = isDefined("FORM.id_tema") ? val(FORM.id_tema) : 0 />
      <cfset VARIABLES.saveAggregatorDivision = isDefined("FORM.divisao") ? trim(FORM.divisao) : "" />
      <cfset VARIABLES.saveAggregatorOrder = isDefined("FORM.ordem") AND isNumeric(FORM.ordem) ? val(FORM.ordem) : 300 />

      <cfif VARIABLES.saveAggregatorId LTE 0 OR NOT len(VARIABLES.saveAggregatorName) OR NOT len(VARIABLES.saveAggregatorType)>
        <cfthrow type="AggregatorManager.Validation" message="Informe o agregador, o nome e o tipo de agregação." />
      </cfif>
      <cfif VARIABLES.saveAggregatorThemeId LTE 0>
        <cfthrow type="AggregatorManager.Validation" message="Selecione um tema." />
      </cfif>

      <cfquery name="qAggregatorSaveTarget">
        SELECT id_agrega_evento FROM tb_agrega_eventos
        WHERE id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.saveAggregatorId#" />
        FOR UPDATE
      </cfquery>
      <cfif NOT qAggregatorSaveTarget.recordcount>
        <cfthrow type="AggregatorManager.Validation" message="Agregador não encontrado." />
      </cfif>
      <cfquery name="qAggregatorThemeTarget">
        SELECT id_tema FROM tb_temas
        WHERE id_tema = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.saveAggregatorThemeId#" />
      </cfquery>
      <cfif NOT qAggregatorThemeTarget.recordcount>
        <cfthrow type="AggregatorManager.Validation" message="Tema não encontrado." />
      </cfif>

      <cfif len(VARIABLES.saveAggregatorTag)>
        <cfquery name="qAggregatorTagConflict">
          SELECT id_agrega_evento FROM tb_agrega_eventos
          WHERE lower(trim(tag)) = lower(trim(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saveAggregatorTag#" />))
            AND id_agrega_evento <> <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.saveAggregatorId#" />
          LIMIT 1
        </cfquery>
        <cfif qAggregatorTagConflict.recordcount>
          <cfthrow type="AggregatorManager.Validation" message="Esta tag já pertence a outro agregador." />
        </cfif>
      </cfif>

      <cfquery>
        UPDATE tb_agrega_eventos
        SET nome_evento_agregado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saveAggregatorName#" />,
            tipo_agregacao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saveAggregatorType#" />,
            tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saveAggregatorTag#" null="#NOT len(VARIABLES.saveAggregatorTag)#" />,
            id_tema = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.saveAggregatorThemeId#" />,
            divisao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.saveAggregatorDivision#" null="#NOT len(VARIABLES.saveAggregatorDivision)#" />,
            ordem = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.saveAggregatorOrder#" />
        WHERE id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.saveAggregatorId#" />
      </cfquery>
      <cflocation addtoken="false" url="./?id=#VARIABLES.saveAggregatorId#&busca=#urlEncodedFormat(VARIABLES.aggregatorSearch)#&sucesso=salvo" />

    <cfelseif FORM.acao EQ "adicionar_eventos">
      <cfset VARIABLES.linkAggregatorId = isDefined("FORM.id_agrega_evento") ? val(FORM.id_agrega_evento) : 0 />
      <cfset VARIABLES.linkEventIds = [] />
      <cfif isDefined("FORM.eventos")>
        <cfloop list="#FORM.eventos#" index="VARIABLES.linkEventId">
          <cfif isNumeric(VARIABLES.linkEventId) AND val(VARIABLES.linkEventId) GT 0>
            <cfset arrayAppend(VARIABLES.linkEventIds, val(VARIABLES.linkEventId)) />
          </cfif>
        </cfloop>
      </cfif>
      <cfif VARIABLES.linkAggregatorId LTE 0 OR NOT arrayLen(VARIABLES.linkEventIds)>
        <cfthrow type="AggregatorManager.Validation" message="Selecione ao menos um evento para adicionar." />
      </cfif>
      <cfquery name="qAggregatorLinkTarget">
        SELECT id_agrega_evento FROM tb_agrega_eventos
        WHERE id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.linkAggregatorId#" />
      </cfquery>
      <cfif NOT qAggregatorLinkTarget.recordcount>
        <cfthrow type="AggregatorManager.Validation" message="Agregador não encontrado." />
      </cfif>
      <cfquery>
        UPDATE tb_evento_corridas
        SET id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.linkAggregatorId#" />
        WHERE id_evento IN (
          <cfqueryparam cfsqltype="cf_sql_integer" value="#arrayToList(VARIABLES.linkEventIds)#" list="true" />
        )
      </cfquery>
      <cflocation addtoken="false" url="./?id=#VARIABLES.linkAggregatorId#&busca=#urlEncodedFormat(VARIABLES.aggregatorSearch)#&sucesso=adicionados" />

    <cfelseif FORM.acao EQ "remover_evento">
      <cfset VARIABLES.unlinkAggregatorId = isDefined("FORM.id_agrega_evento") ? val(FORM.id_agrega_evento) : 0 />
      <cfset VARIABLES.unlinkEventId = isDefined("FORM.id_evento") ? val(FORM.id_evento) : 0 />
      <cfif VARIABLES.unlinkAggregatorId LTE 0 OR VARIABLES.unlinkEventId LTE 0>
        <cfthrow type="AggregatorManager.Validation" message="Vínculo inválido." />
      </cfif>
      <cfquery>
        UPDATE tb_evento_corridas
        SET id_agrega_evento = NULL
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.unlinkEventId#" />
          AND id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.unlinkAggregatorId#" />
      </cfquery>
      <cflocation addtoken="false" url="./?id=#VARIABLES.unlinkAggregatorId#&busca=#urlEncodedFormat(VARIABLES.aggregatorSearch)#&sucesso=removido" />
    </cfif>

    <cfcatch type="any">
      <cfset VARIABLES.aggregatorError = cfcatch.message />
    </cfcatch>
  </cftry>
</cfif>

<cfquery name="qAggregatorThemes">
  SELECT id_tema,
         coalesce(nullif(trim(logo), ''), nullif(trim(tag), ''), id_tema::varchar) AS nome_tema
  FROM tb_temas
  ORDER BY id_tema
</cfquery>

<cfquery name="qAggregators">
  SELECT agr.id_agrega_evento, agr.nome_evento_agregado, agr.tipo_agregacao,
         agr.tag, agr.id_tema, agr.divisao, agr.ordem,
         count(evt.id_evento) AS total_eventos
  FROM tb_agrega_eventos agr
  LEFT JOIN tb_evento_corridas evt ON evt.id_agrega_evento = agr.id_agrega_evento
  WHERE 1=1
  <cfif len(VARIABLES.aggregatorSearch)>
    AND (
      unaccent(lower(coalesce(agr.nome_evento_agregado,''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.aggregatorSearch#%" />))
      OR unaccent(lower(coalesce(agr.tag,''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.aggregatorSearch#%" />))
      <cfif isNumeric(VARIABLES.aggregatorSearch)>
        OR agr.id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.aggregatorSearch)#" />
      </cfif>
    )
  </cfif>
  GROUP BY agr.id_agrega_evento
  ORDER BY lower(agr.nome_evento_agregado), agr.id_agrega_evento
  LIMIT 100
</cfquery>

<cfif VARIABLES.aggregatorId GT 0>
  <cfquery name="qAggregator">
    SELECT id_agrega_evento, nome_evento_agregado, tipo_agregacao, tag, id_tema, divisao, ordem
    FROM tb_agrega_eventos
    WHERE id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.aggregatorId#" />
  </cfquery>
  <cfquery name="qAggregatorEvents">
    SELECT id_evento, nome_evento, tag, cidade, estado, data_inicial, data_final, ativo
    FROM tb_evento_corridas
    WHERE id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.aggregatorId#" />
    ORDER BY data_inicial DESC NULLS LAST, nome_evento
  </cfquery>

  <cfif len(VARIABLES.aggregatorEventSearch) GTE 3>
    <cfquery name="qAggregatorEventSearch">
      SELECT evt.id_evento, evt.nome_evento, evt.tag, evt.cidade, evt.estado,
             evt.data_inicial, evt.data_final, evt.id_agrega_evento,
             agr.nome_evento_agregado AS agregador_atual
      FROM tb_evento_corridas evt
      LEFT JOIN tb_agrega_eventos agr ON agr.id_agrega_evento = evt.id_agrega_evento
      WHERE evt.id_agrega_evento IS DISTINCT FROM <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.aggregatorId#" />
        AND (
          unaccent(lower(coalesce(evt.nome_evento,''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.aggregatorEventSearch#%" />))
          OR unaccent(lower(coalesce(evt.tag,''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.aggregatorEventSearch#%" />))
          <cfif isNumeric(VARIABLES.aggregatorEventSearch)>
            OR evt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.aggregatorEventSearch)#" />
          </cfif>
        )
      ORDER BY evt.data_inicial DESC NULLS LAST, evt.nome_evento
      LIMIT 100
    </cfquery>
  </cfif>
</cfif>
