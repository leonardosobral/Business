<cfprocessingdirective pageencoding="utf-8"/>

<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_brasil_gigante_challenge_access.cfm"/>

<cfparam name="URL.desafio" default="circuitobrasilgigante"/>
<cfparam name="URL.periodo" default=""/>
<cfparam name="URL.preset" default=""/>
<cfparam name="URL.busca" default=""/>
<cfparam name="URL.regiao" default=""/>
<cfparam name="URL.estado" default=""/>
<cfparam name="URL.cidade" default=""/>
<cfparam name="URL.genero" default=""/>
<cfparam name="URL.medalha" default=""/>
<cfparam name="URL.mandala" default=""/>

<cfset URL.desafio = "circuitobrasilgigante"/>

<cfinclude template="backend.cfm"/>

<cfset VARIABLES.challengeExportSheet = spreadsheetNew("Atletas CBG", true)/>
<cfset VARIABLES.challengeExportHeaders = [
    "ID", "Nome", "Email", "Telefone", "Gênero", "Cidade", "UF", "Equipe",
    "São Paulo", "Paraná", "Porto Alegre", "Campo Grande", "João Pessoa", "Floripa", "Salvador", "Aracaju",
    "Etapas reconhecidas", "Status mandala", "Data da entrega", "Data da inscrição"
]/>

<cfloop array="#VARIABLES.challengeExportHeaders#" item="VARIABLES.challengeExportHeader" index="VARIABLES.challengeExportColumn">
    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, VARIABLES.challengeExportHeader, 1, VARIABLES.challengeExportColumn)/>
</cfloop>
<cfset spreadsheetFormatRow(VARIABLES.challengeExportSheet, {bold = true, fgcolor = "FAB120", color = "333333"}, 1)/>

<cfset VARIABLES.challengeExportRow = 2/>
<cfloop query="qBrasilGiganteRanking">
    <cfset VARIABLES.challengeExportPhone = trim(
        (isNull(qBrasilGiganteRanking.ddi_usuario) ? "" : qBrasilGiganteRanking.ddi_usuario) & " " &
        (isNull(qBrasilGiganteRanking.ddd_usuario) ? "" : qBrasilGiganteRanking.ddd_usuario) & " " &
        (isNull(qBrasilGiganteRanking.telefone_usuario) ? "" : qBrasilGiganteRanking.telefone_usuario)
    )/>
    <cfset VARIABLES.challengeExportMandalaLabel = "Em progresso"/>
    <cfswitch expression="#qBrasilGiganteRanking.mandala_status#">
        <cfcase value="proxima_etapa"><cfset VARIABLES.challengeExportMandalaLabel = "Apto na proxima etapa"/></cfcase>
        <cfcase value="imediata"><cfset VARIABLES.challengeExportMandalaLabel = "Apto para entrega imediata"/></cfcase>
        <cfcase value="entregue"><cfset VARIABLES.challengeExportMandalaLabel = "Mandala entregue"/></cfcase>
    </cfswitch>

    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, qBrasilGiganteRanking.id, VARIABLES.challengeExportRow, 1)/>
    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, isNull(qBrasilGiganteRanking.nome) ? "" : qBrasilGiganteRanking.nome, VARIABLES.challengeExportRow, 2)/>
    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, isNull(qBrasilGiganteRanking.email) ? "" : qBrasilGiganteRanking.email, VARIABLES.challengeExportRow, 3)/>
    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, VARIABLES.challengeExportPhone, VARIABLES.challengeExportRow, 4)/>
    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, isNull(qBrasilGiganteRanking.genero) ? "" : qBrasilGiganteRanking.genero, VARIABLES.challengeExportRow, 5)/>
    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, isNull(qBrasilGiganteRanking.cidade) ? "" : qBrasilGiganteRanking.cidade, VARIABLES.challengeExportRow, 6)/>
    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, isNull(qBrasilGiganteRanking.estado) ? "" : qBrasilGiganteRanking.estado, VARIABLES.challengeExportRow, 7)/>
    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, isNull(qBrasilGiganteRanking.equipe) ? "" : qBrasilGiganteRanking.equipe, VARIABLES.challengeExportRow, 8)/>

    <cfloop from="1" to="#VARIABLES.challengeCircuitTotalEvents#" index="VARIABLES.challengeExportStage">
        <cfset VARIABLES.challengeExportParticipationColumn = "participou_" & VARIABLES.challengeExportStage/>
        <cfset VARIABLES.challengeExportYearColumn = "ano_" & VARIABLES.challengeExportStage/>
        <cfset VARIABLES.challengeExportStageValue = ""/>
        <cfif val(qBrasilGiganteRanking[VARIABLES.challengeExportParticipationColumn][qBrasilGiganteRanking.currentRow]) GT 0>
            <cfset VARIABLES.challengeExportStageYear = val(qBrasilGiganteRanking[VARIABLES.challengeExportYearColumn][qBrasilGiganteRanking.currentRow])/>
            <cfset VARIABLES.challengeExportStageValue = VARIABLES.challengeExportStageYear GT 0 ? VARIABLES.challengeExportStageYear : "Sim"/>
        </cfif>
        <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, VARIABLES.challengeExportStageValue, VARIABLES.challengeExportRow, 8 + VARIABLES.challengeExportStage)/>
    </cfloop>

    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, val(qBrasilGiganteRanking.nodesafio), VARIABLES.challengeExportRow, 17)/>
    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, VARIABLES.challengeExportMandalaLabel, VARIABLES.challengeExportRow, 18)/>
    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, isNull(qBrasilGiganteRanking.mandala_entregue_em) ? "" : qBrasilGiganteRanking.mandala_entregue_em, VARIABLES.challengeExportRow, 19)/>
    <cfset spreadsheetSetCellValue(VARIABLES.challengeExportSheet, isNull(qBrasilGiganteRanking.data_inscricao) ? "" : qBrasilGiganteRanking.data_inscricao, VARIABLES.challengeExportRow, 20)/>
    <cfset VARIABLES.challengeExportRow++/>
</cfloop>

<cfset spreadsheetSetColumnWidth(VARIABLES.challengeExportSheet, 2, 34)/>
<cfset spreadsheetSetColumnWidth(VARIABLES.challengeExportSheet, 3, 30)/>
<cfset spreadsheetSetColumnWidth(VARIABLES.challengeExportSheet, 4, 18)/>
<cfset spreadsheetSetColumnWidth(VARIABLES.challengeExportSheet, 6, 22)/>
<cfset spreadsheetSetColumnWidth(VARIABLES.challengeExportSheet, 8, 24)/>
<cfset spreadsheetSetColumnWidth(VARIABLES.challengeExportSheet, 18, 28)/>
<cfset spreadsheetSetColumnWidth(VARIABLES.challengeExportSheet, 19, 20)/>
<cfset spreadsheetSetColumnWidth(VARIABLES.challengeExportSheet, 20, 20)/>

<cfset VARIABLES.challengeExportFilename = "circuito_brasil_gigante_#dateFormat(now(), 'yyyy-mm-dd')#_#timeFormat(now(), 'HH-mm')#.xlsx"/>
<cfset VARIABLES.challengeExportBinary = spreadsheetReadBinary(VARIABLES.challengeExportSheet)/>
<cfheader name="Content-Disposition" value="attachment; filename=#VARIABLES.challengeExportFilename#"/>
<cfcontent type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" variable="#VARIABLES.challengeExportBinary#" reset="true"/>
<cfabort/>
