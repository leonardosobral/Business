<cfquery name="qChallengeRegistrationsByDay">
    SELECT to_char(data_inscricao::date, 'YYYY-MM-DD') AS dia, count(*) AS inscricoes
    FROM desafios
    WHERE desafio = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.challengeTag#"/>
    GROUP BY data_inscricao::date
</cfquery>

<cfset VARIABLES.challengeRegistrationsByDay = {}/>
<cfloop query="qChallengeRegistrationsByDay">
    <cfset VARIABLES.challengeRegistrationsByDay[qChallengeRegistrationsByDay.dia] = qChallengeRegistrationsByDay.inscricoes/>
</cfloop>
<cfset VARIABLES.challengeDays = structKeyArray(VARIABLES.challengeRegistrationsByDay)/>
<cfset arrayAppend(VARIABLES.challengeDays, structKeyArray(VARIABLES.challengeActivitiesByDay), true)/>

<section aria-label="Indicadores diários do desafio" data-challenge-daily-stats>
    <cfif arrayLen(VARIABLES.challengeDays)>
        <cfset arraySort(VARIABLES.challengeDays, "text")/>
        <cfset VARIABLES.challengeFirstDay = listToArray(VARIABLES.challengeDays[1], "-")/>
        <cfset VARIABLES.challengeLastDay = listToArray(VARIABLES.challengeDays[arrayLen(VARIABLES.challengeDays)], "-")/>
        <cfset VARIABLES.challengeChartStart = createDate(VARIABLES.challengeFirstDay[1], VARIABLES.challengeFirstDay[2], VARIABLES.challengeFirstDay[3])/>
        <cfset VARIABLES.challengeChartEnd = createDate(VARIABLES.challengeLastDay[1], VARIABLES.challengeLastDay[2], VARIABLES.challengeLastDay[3])/>
        <div class="row g-2 mb-2" data-challenge-chart-area>
            <div class="col-12 col-lg-6">
                <div class="card">
                    <h2 class="card-header px-3 py-2 fs-6 mb-0">Inscrições por dia</h2>
                    <div class="card-body px-3 py-2">
                        <div style="position:relative;height:16rem">
                            <canvas data-challenge-daily-chart="registrations" role="img" aria-label="Inscrições por dia"></canvas>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-12 col-lg-6">
                <div class="card">
                    <h2 class="card-header px-3 py-2 fs-6 mb-0">Atividades registradas por dia</h2>
                    <div class="card-body px-3 py-2">
                        <div style="position:relative;height:16rem">
                            <canvas data-challenge-daily-chart="activities" role="img" aria-label="Atividades registradas por dia"></canvas>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <details class="card mb-2 px-3 py-2">
            <summary>Ver dados por dia</summary>
            <div class="table-responsive mt-2">
                <table class="table table-sm mb-0">
                    <thead><tr><th scope="col">Data</th><th scope="col" class="text-end">Inscrições</th><th scope="col" class="text-end">Atividades registradas</th></tr></thead>
                    <tbody>
                        <cfloop from="0" to="#dateDiff('d', VARIABLES.challengeChartStart, VARIABLES.challengeChartEnd)#" index="challengeDayOffset">
                            <cfset VARIABLES.challengeChartDay = dateAdd("d", challengeDayOffset, VARIABLES.challengeChartStart)/>
                            <cfset VARIABLES.challengeChartDate = dateFormat(VARIABLES.challengeChartDay, "yyyy-mm-dd")/>
                            <cfset VARIABLES.challengeDailyRegistrations = structKeyExists(VARIABLES.challengeRegistrationsByDay, VARIABLES.challengeChartDate) ? VARIABLES.challengeRegistrationsByDay[VARIABLES.challengeChartDate] : 0/>
                            <cfset VARIABLES.challengeDailyActivities = structKeyExists(VARIABLES.challengeActivitiesByDay, VARIABLES.challengeChartDate) ? VARIABLES.challengeActivitiesByDay[VARIABLES.challengeChartDate] : 0/>
                            <cfoutput>
                                <tr data-challenge-date="#VARIABLES.challengeChartDate#">
                                    <th scope="row">#dateFormat(VARIABLES.challengeChartDay, "dd/mm/yyyy")#</th>
                                    <td class="text-end">#VARIABLES.challengeDailyRegistrations#</td>
                                    <td class="text-end">#VARIABLES.challengeDailyActivities#</td>
                                </tr>
                            </cfoutput>
                        </cfloop>
                    </tbody>
                </table>
            </div>
        </details>
        <script type="module" src="/desafios/assets/atividade-diaria.js?v=2026112602"></script>
    <cfelse>
        <p class="card mb-2 px-3 py-2">Ainda não há inscrições ou atividades registradas.</p>
    </cfif>
</section>
