<cfparam name="URL.id_evento" default=""/>
<cfparam name="URL.busca" default=""/>

<cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin>
    <cflocation addtoken="false" url="/"/>
</cfif>

<cfif NOT len(trim(URL.id_evento)) OR NOT isNumeric(URL.id_evento)>
    <cflocation addtoken="false" url="/treinos-config/"/>
</cfif>

<cfquery name="qTreinoEventoInfo">
    SELECT evt.id_evento,
           evt.nome_evento,
           evt.tipo_corrida,
           evt.tag,
           evt.data_inicial,
           evt.data_final
    FROM tb_evento_corridas evt
    WHERE evt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>
    LIMIT 1
</cfquery>

<cfif NOT qTreinoEventoInfo.recordcount>
    <cflocation addtoken="false" url="/treinos-config/"/>
</cfif>

<cfquery name="qTreinoInscritos">
    SELECT insc.id_usuario,
           insc.data_pedido,
           insc.num_pedido,
           insc.data_checkin,
           COALESCE(insc.flag_sorteio::int, 0) AS flag_sorteio,
           insc.observacoes,
           upper(COALESCE(pag.nome, usr.name)) AS nome_atleta,
           usr.email,
           pag.tag AS slug_pagina,
           trim(unaccent(upper(insc.body ->> 'assessoria'))) AS assessoria,
           trim(upper(insc.body ->> 'pace')) AS pace,
           trim(upper(insc.body ->> 'celular')) AS celular,
           trim(upper(insc.body ->> 'documento')) AS documento,
           trim(upper(insc.body ->> 'nascimento')) AS nascimento,
           trim(upper(unaccent(COALESCE(pag.cidade, usr.cidade)))) AS cidade,
           COALESCE(pag.uf, usr.estado) AS estado
    FROM tb_inscricoes insc
    LEFT JOIN tb_usuarios usr ON usr.id = insc.id_usuario
    LEFT JOIN tb_paginas pag ON pag.id_usuario_cadastro = usr.id
    WHERE insc.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>
    <cfif len(trim(URL.busca))>
      AND (
        unaccent(upper(COALESCE(pag.nome, usr.name, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.busca)#%"/>))
        OR unaccent(upper(COALESCE(usr.email, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.busca)#%"/>))
        OR COALESCE(insc.num_pedido::varchar, '') LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.busca)#%"/>
        OR COALESCE(insc.body ->> 'documento', '') LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.busca)#%"/>
        OR COALESCE(insc.body ->> 'celular', '') LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.busca)#%"/>
      )
    </cfif>
    ORDER BY upper(COALESCE(pag.nome, usr.name, '')), insc.data_pedido DESC, insc.num_pedido DESC
</cfquery>
