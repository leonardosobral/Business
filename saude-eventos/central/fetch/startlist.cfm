<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false"/>
<cfset VARIABLES.saudeAuthMode = "table"/>
<cfinclude template="/saude-eventos/central/includes/auth.cfm"/>
<cfparam name="URL.id_evento" type="numeric" default="0"/>
<cfparam name="URL.percurso" type="numeric" default="0"/>

<cfif URL.id_evento LTE 0>
    <tr><td colspan="4" class="saude-empty-row">Evento inválido.</td></tr><cfabort/>
</cfif>

<cfquery name="qFMStartList" datasource="runner_dba">
    SELECT ins.num_pedido, ins.num_peito, ins.modalidade,
           coalesce(
               nullif(trim(ins.nome), ''),
               nullif(trim(usr.name), ''),
               nullif(trim(atleta_pag.nome), ''),
               'Atleta · BIB ' || coalesce(ins.num_peito::text, 'não informado')
           ) AS nome_exibicao,
           ins.genero AS sexo,
           usr.id AS id_usuario, usr.ficha_medica
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
      AND (
          ins.num_peito IS NOT NULL
          OR (
              ins.id_usuario IS NOT NULL
              AND usr.ficha_medica IS NOT NULL
              AND trim(usr.ficha_medica::text) NOT IN ('','{}','null')
          )
      )
      AND coalesce(nullif(trim(ins.observacoes), ''), 'lista') NOT IN ('scan','acionado','diligencia','atendimento','atendido')
      <cfif URL.percurso GT 0>
          AND (
              nullif(trim(ins.modalidade), '') IS NULL
              OR coalesce(ins.modalidade, '') ~* (
                  '(^|[^0-9])'
                  || replace((<cfqueryparam cfsqltype="cf_sql_numeric" value="#URL.percurso#"/>)::numeric::text, '.', '[,.]')
                  || '([^0-9]|$)'
              )
          )
      </cfif>
    ORDER BY ins.num_peito ASC NULLS LAST, nome_exibicao
</cfquery>

<cfif NOT qFMStartList.recordcount>
    <tr><td colspan="4" class="saude-empty-row"><i class="fa-solid fa-person-running"></i><span>Nenhum atleta encontrado neste percurso.</span></td></tr>
<cfelse>
    <cfoutput query="qFMStartList">
        <tr class="saude-athlete-row" data-search="#htmlEditFormat(lCase(qFMStartList.num_peito & ' ' & qFMStartList.nome_exibicao & ' ' & qFMStartList.modalidade))#" onclick="carregarAtleta(#qFMStartList.num_pedido#)">
            <td><span class="saude-bib<cfif NOT len(trim(qFMStartList.num_peito & ''))> is-pending</cfif>">#(len(trim(qFMStartList.num_peito & '')) ? qFMStartList.num_peito : 'Sem BIB')#</span></td>
            <td>
                <strong class="saude-athlete-name <cfif VARIABLES.saudeMaskPrivateData>is-private</cfif>">#htmlEditFormat(qFMStartList.nome_exibicao)#</strong>
                <span class="saude-athlete-route">#(len(trim(qFMStartList.modalidade & '')) ? htmlEditFormat(qFMStartList.modalidade) : 'Percurso não informado')#</span>
            </td>
            <td class="saude-medical-flag"><cfif len(trim(qFMStartList.ficha_medica & ''))><i class="fa-regular fa-address-card" title="Ficha médica disponível"></i></cfif></td>
        </tr>
    </cfoutput>
</cfif>
