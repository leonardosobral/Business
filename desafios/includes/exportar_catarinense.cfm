<cfprocessingdirective pageencoding="utf-8"/>

<cfinclude template="../../includes/backend/backend_login.cfm"/>

<cfparam name="URL.desafio" default=""/>
<cfparam name="URL.periodo" default=""/>
<cfparam name="URL.preset" default=""/>
<cfparam name="URL.busca" default=""/>
<cfparam name="URL.regiao" default=""/>
<cfparam name="URL.estado" default=""/>
<cfparam name="URL.cidade" default=""/>
<cfparam name="URL.genero" default=""/>
<cfparam name="URL.medalha" default=""/>

<cfset URL.desafio = lcase(trim(replace(URL.desafio, "/", "")))/>
<cfif NOT listFindNoCase("catarinensecorridaderua,catarinensetrailrun", URL.desafio)>
    <cfheader statuscode="400" statustext="Bad Request"/>
    <cfcontent type="text/plain; charset=utf-8" reset="true"/>
    <cfoutput>Desafio catarinense invalido para exportacao.</cfoutput>
    <cfabort/>
</cfif>

<cfinclude template="../../includes/backend/require_catarinense_challenge_access.cfm"/>

<cfinclude template="backend.cfm"/>

<cfset VARIABLES.challengeExportSheet = spreadsheetNew("Atletas", true)/>
<cfset VARIABLES.challengeExportHeaders = [
    "ID", "Nome", "Email", "Telefone", "Genero", "Cidade", "UF", "Equipe",
    "Etapa 1", "Etapa 2", "Etapa 3", "Etapa 4", "Etapa 5", "Etapa 6",
    "Pontos", "Etapas reconhecidas", "Status medalha", "Data da entrega"
]/>

<cfloop array="#VARIABLES.challengeExportHeaders#" item="VARIABLES.challengeExportHeader" index="VARIABLES.challengeExportColumn">
    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, VARIABLES.challengeExportHeader, 1, VARIABLES.challengeExportColumn)/>
</cfloop>
<cfset spreadsheetFormatRow(VARIABLES.challengeExportSheet, {bold = true, fgcolor = "FAB120", color = "333333"}, 1)/>

<cfset VARIABLES.challengeExportRow = 2/>
<cfloop query="qStatsBase">
    <cfset VARIABLES.challengeExportPhone = trim(
        (isNull(qStatsBase.ddi_usuario) ? "" : qStatsBase.ddi_usuario) & " " &
        (isNull(qStatsBase.ddd_usuario) ? "" : qStatsBase.ddd_usuario) & " " &
        (isNull(qStatsBase.telefone_usuario) ? "" : qStatsBase.telefone_usuario)
    )/>
    <cfset VARIABLES.challengeExportMedalLabel = "Em progresso"/>
    <cfswitch expression="#qStatsBase.medalha_status#">
        <cfcase value="proxima_etapa"><cfset VARIABLES.challengeExportMedalLabel = "Apto na proxima etapa"/></cfcase>
        <cfcase value="imediata"><cfset VARIABLES.challengeExportMedalLabel = "Apto para entrega imediata"/></cfcase>
        <cfcase value="entregue"><cfset VARIABLES.challengeExportMedalLabel = "Medalha entregue"/></cfcase>
    </cfswitch>

    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, qStatsBase.id, VARIABLES.challengeExportRow, 1)/>
    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, isNull(qStatsBase.nome) ? "" : qStatsBase.nome, VARIABLES.challengeExportRow, 2)/>
    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, isNull(qStatsBase.email) ? "" : qStatsBase.email, VARIABLES.challengeExportRow, 3)/>
    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, VARIABLES.challengeExportPhone, VARIABLES.challengeExportRow, 4)/>
    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, isNull(qStatsBase.genero) ? "" : qStatsBase.genero, VARIABLES.challengeExportRow, 5)/>
    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, isNull(qStatsBase.cidade) ? "" : qStatsBase.cidade, VARIABLES.challengeExportRow, 6)/>
    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, isNull(qStatsBase.estado) ? "" : qStatsBase.estado, VARIABLES.challengeExportRow, 7)/>
    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, isNull(qStatsBase.equipe) ? "" : qStatsBase.equipe, VARIABLES.challengeExportRow, 8)/>

    <cfloop from="1" to="#VARIABLES.challengeCircuitTotalEvents#" index="VARIABLES.challengeExportStage">
        <cfset VARIABLES.challengeExportPointsColumn = "pontos_" & VARIABLES.challengeExportStage/>
        <cfset VARIABLES.challengeExportParticipationColumn = "participou_" & VARIABLES.challengeExportStage/>
        <cfset VARIABLES.challengeExportStageValue = ""/>
        <cfif val(qStatsBase[VARIABLES.challengeExportParticipationColumn][qStatsBase.currentRow]) GT 0>
            <cfset VARIABLES.challengeExportStageValue = val(qStatsBase[VARIABLES.challengeExportPointsColumn][qStatsBase.currentRow])/>
        </cfif>
        <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, VARIABLES.challengeExportStageValue, VARIABLES.challengeExportRow, 8 + VARIABLES.challengeExportStage)/>
    </cfloop>

    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, val(qStatsBase.distancia_percorrida), VARIABLES.challengeExportRow, 15)/>
    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, val(qStatsBase.nodesafio), VARIABLES.challengeExportRow, 16)/>
    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, VARIABLES.challengeExportMedalLabel, VARIABLES.challengeExportRow, 17)/>
    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, isNull(qStatsBase.medalha_entregue_em) ? "" : qStatsBase.medalha_entregue_em, VARIABLES.challengeExportRow, 18)/>
    <cfset VARIABLES.challengeExportRow++/>
</cfloop>

<cfset spreadsheetSetColumnWidth(VARIABLES.challengeExportSheet, 2, 32)/>
<cfset spreadsheetSetColumnWidth(VARIABLES.challengeExportSheet, 3, 30)/>
<cfset spreadsheetSetColumnWidth(VARIABLES.challengeExportSheet, 4, 18)/>
<cfset spreadsheetSetColumnWidth(VARIABLES.challengeExportSheet, 6, 22)/>
<cfset spreadsheetSetColumnWidth(VARIABLES.challengeExportSheet, 8, 24)/>
<cfset spreadsheetSetColumnWidth(VARIABLES.challengeExportSheet, 17, 26)/>
<cfset spreadsheetSetColumnWidth(VARIABLES.challengeExportSheet, 18, 20)/>

<cfset VARIABLES.challengeExportFilename = "#URL.desafio#_#dateFormat(now(), 'yyyy-mm-dd')#_#timeFormat(now(), 'HH-mm')#.xlsx"/>
<cfset VARIABLES.challengeExportBinary = spreadsheetReadBinary(VARIABLES.challengeExportSheet)/>
<cfheader name="Content-Disposition" value="attachment; filename=#VARIABLES.challengeExportFilename#"/>
<cfcontent type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" variable="#VARIABLES.challengeExportBinary#" reset="true"/>
<cfabort/>
