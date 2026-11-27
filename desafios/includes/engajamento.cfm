<cfif NOT isDefined("VARIABLES.requireAdminAllowed") OR NOT VARIABLES.requireAdminAllowed>
    <cfheader statuscode="403"/>
    <cfabort/>
</cfif>

<cfscript>
    VARIABLES.challengeEngagementCalendarDate = function(required string isoDay) {
        return createDate(left(arguments.isoDay, 4), mid(arguments.isoDay, 6, 2), right(arguments.isoDay, 2));
    };
    VARIABLES.challengeEngagementMonday = function(required date calendarDate) {
        return dateAdd("d", -((dayOfWeek(arguments.calendarDate) + 5) MOD 7), arguments.calendarDate);
    };

    VARIABLES.challengeEngagementTodayKey = dateTimeFormat(now(), "yyyy-mm-dd", "America/Sao_Paulo");
    VARIABLES.challengeEngagementToday = VARIABLES.challengeEngagementCalendarDate(VARIABLES.challengeEngagementTodayKey);
    VARIABLES.challengeEngagementFirstDay = dateAdd("d", -6, VARIABLES.challengeEngagementToday);
    VARIABLES.challengeEngagementFirstDayKey = dateFormat(VARIABLES.challengeEngagementFirstDay, "yyyy-mm-dd");
    VARIABLES.challengeEngagementThisWeek = VARIABLES.challengeEngagementMonday(VARIABLES.challengeEngagementToday);
    VARIABLES.challengeEngagementOldestCohort = dateFormat(dateAdd("d", -77, VARIABLES.challengeEngagementThisWeek), "yyyy-mm-dd");

    VARIABLES.challengeEngagementAthletes = {};
    for (engagementEnrollment in qBase) {
        engagementId = toString(engagementEnrollment.id);
        if (!structKeyExists(VARIABLES.challengeEngagementAthletes, engagementId)) {
            VARIABLES.challengeEngagementAthletes[engagementId] = { enrollmentDay="", activeDays=0, started=false, returned=false };
        }
        if (!isNull(engagementEnrollment.data_inscricao) && isDate(engagementEnrollment.data_inscricao)) {
            engagementDay = dateFormat(engagementEnrollment.data_inscricao, "yyyy-mm-dd");
            engagementAthlete = VARIABLES.challengeEngagementAthletes[engagementId];
            if (!len(engagementAthlete.enrollmentDay) || compare(engagementDay, engagementAthlete.enrollmentDay) LT 0) {
                engagementAthlete.enrollmentDay = engagementDay;
            }
        }
    }

    VARIABLES.challengeEngagementCohorts = {};
    for (engagementId in VARIABLES.challengeEngagementAthletes) {
        engagementAthlete = VARIABLES.challengeEngagementAthletes[engagementId];
        if (compare(engagementAthlete.enrollmentDay, VARIABLES.challengeEngagementOldestCohort) LT 0 ||
            compare(engagementAthlete.enrollmentDay, VARIABLES.challengeEngagementTodayKey) GT 0) {
            continue;
        }
        engagementMonday = VARIABLES.challengeEngagementMonday(VARIABLES.challengeEngagementCalendarDate(engagementAthlete.enrollmentDay));
        engagementCohortKey = dateFormat(engagementMonday, "yyyy-mm-dd");
        engagementAthlete.cohortKey = engagementCohortKey;
        if (!structKeyExists(VARIABLES.challengeEngagementCohorts, engagementCohortKey)) {
            engagementAfterNextWeek = dateAdd("d", 14, engagementMonday);
            VARIABLES.challengeEngagementCohorts[engagementCohortKey] = {
                start=engagementMonday,
                end=dateAdd("d", 6, engagementMonday),
                nextWeek=dateFormat(dateAdd("d", 7, engagementMonday), "yyyy-mm-dd"),
                afterNextWeek=dateFormat(engagementAfterNextWeek, "yyyy-mm-dd"),
                complete=dateCompare(engagementAfterNextWeek, VARIABLES.challengeEngagementToday, "d") LTE 0,
                started=0,
                returned=0
            };
        }
    }

    for (engagementActivity in qAthletesWithActivity) {
        engagementId = toString(engagementActivity.id);
        if (!structKeyExists(VARIABLES.challengeEngagementAthletes, engagementId)) {
            continue;
        }
        engagementAthlete = VARIABLES.challengeEngagementAthletes[engagementId];
        engagementHasCohort = structKeyExists(engagementAthlete, "cohortKey");
        if (engagementHasCohort) {
            engagementCohort = VARIABLES.challengeEngagementCohorts[engagementAthlete.cohortKey];
        }
        // O backend fornece uma data única por dia com atividade válida.
        for (engagementDay in listToArray(engagementActivity.datas_atividade)) {
            if (compare(engagementDay, VARIABLES.challengeEngagementFirstDayKey) GTE 0 &&
                compare(engagementDay, VARIABLES.challengeEngagementTodayKey) LTE 0) {
                engagementAthlete.activeDays++;
            }
            if (engagementHasCohort && compare(engagementDay, engagementAthlete.enrollmentDay) GTE 0) {
                if (compare(engagementDay, engagementCohort.nextWeek) LT 0) {
                    engagementAthlete.started = true;
                } else if (compare(engagementDay, engagementCohort.afterNextWeek) LT 0) {
                    engagementAthlete.returned = true;
                }
            }
        }
    }

    VARIABLES.challengeEngagementFrequency = [
        {label="0 dias", maxDays=0, athletes=0},
        {label="1 dia", maxDays=1, athletes=0},
        {label="2–3 dias", maxDays=3, athletes=0},
        {label="4–7 dias", maxDays=7, athletes=0}
    ];
    VARIABLES.challengeEngagementTotal = structCount(VARIABLES.challengeEngagementAthletes);
    for (engagementId in VARIABLES.challengeEngagementAthletes) {
        engagementAthlete = VARIABLES.challengeEngagementAthletes[engagementId];
        for (engagementBucket in VARIABLES.challengeEngagementFrequency) {
            if (engagementAthlete.activeDays LTE engagementBucket.maxDays) {
                engagementBucket.athletes++;
                break;
            }
        }
        if (structKeyExists(engagementAthlete, "cohortKey") && engagementAthlete.started) {
            engagementCohort = VARIABLES.challengeEngagementCohorts[engagementAthlete.cohortKey];
            engagementCohort.started++;
            if (engagementAthlete.returned) {
                engagementCohort.returned++;
            }
        }
    }
    VARIABLES.challengeEngagementCohortKeys = structKeyArray(VARIABLES.challengeEngagementCohorts);
    arraySort(VARIABLES.challengeEngagementCohortKeys, "text", "desc");
</cfscript>

<div class="row g-2 mb-2">
    <div class="col-12 col-xl-6">
        <section class="card h-100" aria-labelledby="challenge-engagement-frequency-heading">
            <h2 class="card-header px-3 py-2 fs-6 mb-0" id="challenge-engagement-frequency-heading">Frequência nos últimos 7 dias</h2>
            <div class="card-body p-3">
                <cfoutput>
                    <p class="small mb-2">#dateFormat(VARIABLES.challengeEngagementFirstDay, 'dd/mm')# a #dateFormat(VARIABLES.challengeEngagementToday, 'dd/mm/yyyy')#, horário de Brasília. Inclui todos os inscritos do desafio.</p>
                </cfoutput>
                <cfif VARIABLES.challengeEngagementTotal GT 0>
                    <table class="table table-sm mb-0">
                        <thead>
                            <tr><th scope="col">Dias com atividade</th><th scope="col" class="text-end">Atletas</th><th scope="col" class="text-end">% dos inscritos</th></tr>
                        </thead>
                        <tbody>
                            <cfloop array="#VARIABLES.challengeEngagementFrequency#" item="engagementBucket">
                                <cfset engagementPercent = engagementBucket.athletes * 100 / VARIABLES.challengeEngagementTotal/>
                                <cfoutput>
                                    <tr>
                                        <th scope="row">
                                            #engagementBucket.label#
                                            <div class="progress mt-1" style="height: .25rem" aria-hidden="true">
                                                <div class="progress-bar" style="width: #numberFormat(engagementPercent, '9.99')#%; background-color: var(--business-accent)"></div>
                                            </div>
                                        </th>
                                        <td class="text-end">#lsNumberFormat(engagementBucket.athletes, '9,999', 'Portuguese (Brazilian)')#</td>
                                        <td class="text-end">#lsNumberFormat(engagementPercent, '9.9', 'Portuguese (Brazilian)')#%</td>
                                    </tr>
                                </cfoutput>
                            </cfloop>
                        </tbody>
                    </table>
                <cfelse>
                    <p class="mb-0">Ainda não há inscritos no desafio.</p>
                </cfif>
            </div>
        </section>
    </div>
    <div class="col-12 col-xl-6">
        <section class="card h-100" aria-labelledby="challenge-engagement-retention-heading">
            <h2 class="card-header px-3 py-2 fs-6 mb-0" id="challenge-engagement-retention-heading">Retenção por semana de inscrição</h2>
            <div class="card-body p-3">
                <p class="small mb-2">Dos atletas que treinaram na semana da inscrição, quantos voltaram a treinar na semana seguinte. Veja as últimas 12 semanas, de segunda a domingo.</p>
                <cfif arrayLen(VARIABLES.challengeEngagementCohortKeys)>
                    <div class="table-responsive">
                        <table class="table table-sm mb-0">
                            <thead>
                                <tr><th scope="col">Inscrição</th><th scope="col" class="text-end">Começaram</th><th scope="col" class="text-end">Voltaram</th><th scope="col" class="text-end">Retenção</th></tr>
                            </thead>
                            <tbody>
                                <cfloop array="#VARIABLES.challengeEngagementCohortKeys#" item="engagementCohortKey">
                                    <cfset engagementCohort = VARIABLES.challengeEngagementCohorts[engagementCohortKey]/>
                                    <cfoutput>
                                        <tr>
                                            <th scope="row">#dateFormat(engagementCohort.start, 'dd/mm')# a #dateFormat(engagementCohort.end, 'dd/mm')#</th>
                                            <td class="text-end">#lsNumberFormat(engagementCohort.started, '9,999', 'Portuguese (Brazilian)')#</td>
                                            <cfif NOT engagementCohort.complete>
                                                <td colspan="2" class="text-end">Em andamento</td>
                                            <cfelseif NOT engagementCohort.started>
                                                <td class="text-end">0</td>
                                                <td class="text-end" aria-label="Sem atletas com atividade na semana da inscrição">—</td>
                                            <cfelse>
                                                <td class="text-end">#lsNumberFormat(engagementCohort.returned, '9,999', 'Portuguese (Brazilian)')#</td>
                                                <td class="text-end">#lsNumberFormat(engagementCohort.returned * 100 / engagementCohort.started, '9.9', 'Portuguese (Brazilian)')#%</td>
                                            </cfif>
                                        </tr>
                                    </cfoutput>
                                </cfloop>
                            </tbody>
                        </table>
                    </div>
                <cfelse>
                    <p class="mb-0">Ainda não há inscrições nesse período.</p>
                </cfif>
            </div>
        </section>
    </div>
</div>
