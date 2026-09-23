<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false"/>
<cfset VARIABLES.saudeAuthMode = "json"/>
<cfinclude template="/saude-eventos/central/includes/auth.cfm"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfparam name="URL.id_evento" type="numeric" default="0"/>

<cfif URL.id_evento LTE 0>
    <cfheader statuscode="400" statustext="Bad Request"/>
    <cfoutput>#serializeJSON({success=false,message="Evento inválido."})#</cfoutput>
    <cfabort/>
</cfif>

<cfquery name="qSaudeStats" datasource="runner_dba">
    SELECT count(*) AS total,
           count(*) FILTER (WHERE ins.observacoes IN ('scan','acionado')) AS triagem,
           count(*) FILTER (WHERE ins.observacoes IN ('diligencia','atendimento')) AS atendimento,
           count(*) FILTER (WHERE ins.observacoes = 'atendido') AS atendidos,
           count(*) FILTER (WHERE ins.observacoes IN ('scan','acionado','diligencia','atendimento','atendido')) AS monitorados,
           count(*) FILTER (WHERE usr.ficha_medica IS NOT NULL AND trim(usr.ficha_medica::text) NOT IN ('','{}','null')) AS fichas_medicas,
           max(ins.data_scan) AS ultima_movimentacao
    FROM tb_inscricoes ins
    LEFT JOIN tb_usuarios usr ON usr.id = ins.id_usuario
    INNER JOIN tb_evento_saude_config cfg ON cfg.id_evento = ins.id_evento AND cfg.ativo = true
    WHERE ins.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#int(URL.id_evento)#"/>
      AND (
          ins.num_peito IS NOT NULL
          OR (
              ins.id_usuario IS NOT NULL
              AND usr.ficha_medica IS NOT NULL
              AND trim(usr.ficha_medica::text) NOT IN ('','{}','null')
          )
      )
</cfquery>

<cfoutput>#serializeJSON({
    success=true,
    total=val(qSaudeStats.total),
    triagem=val(qSaudeStats.triagem),
    atendimento=val(qSaudeStats.atendimento),
    atendidos=val(qSaudeStats.atendidos),
    monitorados=val(qSaudeStats.monitorados),
    fichas_medicas=val(qSaudeStats.fichas_medicas),
    ultima_movimentacao=isDate(qSaudeStats.ultima_movimentacao) ? dateTimeFormat(qSaudeStats.ultima_movimentacao,"HH:nn:ss") : ""
})#</cfoutput>
