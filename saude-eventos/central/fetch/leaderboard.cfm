<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false"/>
<cfset VARIABLES.saudeAuthMode = "table"/>
<cfinclude template="/saude-eventos/central/includes/auth.cfm"/>
<cfparam name="URL.id_evento" type="numeric" default="0"/>
<cfparam name="URL.categoria" type="string" default="scan"/>

<cfif URL.id_evento LTE 0>
    <tr><td colspan="6" class="saude-empty-row">Evento inválido.</td></tr><cfabort/>
</cfif>

<cfquery name="qFMLeaderboard" datasource="runner_dba">
    SELECT ins.num_pedido, ins.num_peito, usr.ficha_medica, ins.observacoes, ins.data_scan,
           coalesce(
               nullif(trim(ins.nome), ''),
               nullif(trim(usr.name), ''),
               nullif(trim(atleta_pag.nome), ''),
               'Atleta · BIB ' || coalesce(ins.num_peito::text, 'não informado')
           ) AS nome_exibicao,
           ins.genero AS sexo, ins.modalidade,
           usr.id AS id_usuario, usr.cidade, usr.estado, usr.assessoria
    FROM tb_inscricoes ins
    LEFT JOIN tb_usuarios usr ON usr.id = ins.id_usuario
    LEFT JOIN LATERAL (
        SELECT pag.nome
        FROM tb_paginas_usuarios pgusr
        INNER JOIN tb_paginas pag ON pag.id_pagina = pgusr.id_pagina
        WHERE pgusr.id_usuario = ins.id_usuario
        ORDER BY (pag.tag_prefix = 'atleta') DESC, pag.id_pagina
        LIMIT 1
    ) atleta_pag ON true
    INNER JOIN tb_evento_saude_config cfg ON cfg.id_evento = ins.id_evento AND cfg.ativo = true
    WHERE ins.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#int(URL.id_evento)#"/>
      <cfswitch expression="#lCase(trim(URL.categoria))#">
          <cfcase value="scan">AND ins.observacoes IN ('scan','acionado')</cfcase>
          <cfcase value="atendimento">AND ins.observacoes IN ('diligencia','atendimento')</cfcase>
          <cfcase value="atendidos">AND ins.observacoes = 'atendido'</cfcase>
          <cfdefaultcase>AND 1 = 0</cfdefaultcase>
      </cfswitch>
    ORDER BY CASE WHEN ins.observacoes = 'acionado' THEN 0 ELSE 1 END,
             ins.data_scan DESC NULLS LAST, ins.num_peito
</cfquery>

<cfif NOT qFMLeaderboard.recordcount>
    <tr><td colspan="6" class="saude-empty-row"><i class="fa-regular fa-circle-check"></i><span>Nenhum atleta nesta fila.</span></td></tr>
<cfelse>
    <cfoutput query="qFMLeaderboard">
        <cfset VARIABLES.saudeStatus = lCase(trim(qFMLeaderboard.observacoes & ""))/>
        <cfset VARIABLES.saudeStatusLabel = VARIABLES.saudeStatus EQ "scan" ? "Scan" : (VARIABLES.saudeStatus EQ "acionado" ? "Acionado" : (VARIABLES.saudeStatus EQ "diligencia" ? "Diligência" : (VARIABLES.saudeStatus EQ "atendimento" ? "Atendimento" : "Atendido")))/>
        <tr class="saude-athlete-row" data-search="#htmlEditFormat(lCase(qFMLeaderboard.num_peito & ' ' & qFMLeaderboard.nome_exibicao & ' ' & qFMLeaderboard.modalidade))#" onclick="carregarAtleta(#qFMLeaderboard.num_pedido#)">
            <td><span class="saude-bib<cfif NOT len(trim(qFMLeaderboard.num_peito & ''))> is-pending</cfif>">#(len(trim(qFMLeaderboard.num_peito & '')) ? qFMLeaderboard.num_peito : 'Sem BIB')#</span></td>
            <td>
                <strong class="saude-athlete-name <cfif VARIABLES.saudeMaskPrivateData>is-private</cfif>">#htmlEditFormat(qFMLeaderboard.nome_exibicao)#</strong>
                <span class="saude-athlete-route">#(len(trim(qFMLeaderboard.modalidade & '')) ? htmlEditFormat(qFMLeaderboard.modalidade) : 'Percurso não informado')#</span>
            </td>
            <td><span class="saude-status-badge is-#htmlEditFormat(VARIABLES.saudeStatus)#">#VARIABLES.saudeStatusLabel#</span></td>
            <td class="saude-row-time">#(isDate(qFMLeaderboard.data_scan) ? timeFormat(qFMLeaderboard.data_scan, 'HH:mm') : '—')#</td>
            <td class="saude-medical-flag"><cfif len(trim(qFMLeaderboard.ficha_medica & ''))><i class="fa-regular fa-address-card" title="Ficha médica disponível"></i></cfif></td>
        </tr>
    </cfoutput>
</cfif>
