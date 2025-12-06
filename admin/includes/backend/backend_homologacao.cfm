<!--- HOMOLOGAR CORRIDA --->

<cfif isDefined("URL.acao") AND URL.acao EQ "homologar" AND isDefined("URL.id_evento") AND Len(trim(URL.id_evento))>

    <cfquery>
        UPDATE tb_evento_corridas
        SET homologado = <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>,
        ranking = <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>
    </cfquery>

    <cflocation addtoken="false" url="homologacao.cfm?preset=#URL.preset#&periodo=#URL.periodo#&busca=#URL.busca#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#"/>

</cfif>

<!--- HOMOLOGAR CORRIDA --->

<cfif isDefined("URL.acao") AND URL.acao EQ "naohomologar" AND isDefined("URL.id_evento") AND Len(trim(URL.id_evento))>

    <cfquery>
        UPDATE tb_evento_corridas
        SET homologado = <cfqueryparam cfsqltype="cf_sql_bit" value="false"/>,
        ranking = <cfqueryparam cfsqltype="cf_sql_bit" value="false"/>
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>
    </cfquery>

    <cflocation addtoken="false" url="homologacao.cfm?preset=#URL.preset#&periodo=#URL.periodo#&busca=#URL.busca#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#"/>

</cfif>


<!--- RANKING CORRIDA --->

<cfif isDefined("URL.acao") AND URL.acao EQ "ranking" AND isDefined("URL.id_evento") AND Len(trim(URL.id_evento))>

    <cfquery>
        UPDATE tb_evento_corridas
        SET ranking = <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>
    </cfquery>

    <cflocation addtoken="false" url="homologacao.cfm?preset=#URL.preset#&&periodo=#URL.periodo#busca=#URL.busca#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#"/>

</cfif>

<!--- RANKING CORRIDA --->

<cfif isDefined("URL.acao") AND URL.acao EQ "naoranking" AND isDefined("URL.id_evento") AND Len(trim(URL.id_evento))>

    <cfquery>
        UPDATE tb_evento_corridas
        SET ranking = <cfqueryparam cfsqltype="cf_sql_bit" value="false"/>
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>
    </cfquery>

    <cflocation addtoken="false" url="homologacao.cfm?preset=#URL.preset#&periodo=#URL.periodo#&busca=#URL.busca#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#"/>

</cfif>
