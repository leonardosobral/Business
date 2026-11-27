<cfif NOT isDefined("VARIABLES.requireAdminAllowed") OR NOT VARIABLES.requireAdminAllowed>
    <cfheader statuscode="403"/>
    <cfabort/>
</cfif>

<cfscript>
    VARIABLES.challengeSportLabels = {
        Run="Corrida", VirtualRun="Corrida", TrailRun="Corrida", Walk="Caminhada", Hike="Trilha a pé",
        WeightTraining="Musculação", Workout="Treino geral", Crossfit="CrossFit", HighIntensityIntervalTraining="HIIT",
        Ride="Ciclismo", VirtualRide="Ciclismo", MountainBikeRide="Ciclismo", GravelRide="Ciclismo",
        EBikeRide="Ciclismo", EMountainBikeRide="Ciclismo", Handcycle="Ciclismo", Velomobile="Ciclismo",
        Swim="Natação", Yoga="Yoga", Pilates="Pilates", Dance="Dança", Elliptical="Elíptico", StairStepper="Escada",
        Soccer="Futebol", Basketball="Basquete", Volleyball="Vôlei", Tennis="Tênis", TableTennis="Tênis de mesa",
        Padel="Padel", Pickleball="Pickleball", Racquetball="Raquetebol", Badminton="Badminton", Squash="Squash",
        Golf="Golfe", Cricket="Críquete", RockClimbing="Escalada", PhysicalTherapy="Fisioterapia",
        Rowing="Remo", VirtualRow="Remo", Canoeing="Canoagem", Kayaking="Caiaque", Sail="Vela",
        StandUpPaddling="Stand-up paddle", Surfing="Surfe", Windsurf="Windsurf", Kitesurf="Kitesurfe",
        InlineSkate="Patinação", IceSkate="Patinação no gelo", Skateboard="Skate", Wheelchair="Cadeira de rodas",
        AlpineSki="Esqui", BackcountrySki="Esqui", NordicSki="Esqui", RollerSki="Esqui sobre rodas",
        Snowboard="Snowboard", Snowshoe="Caminhada na neve", SemTipo="Não informada"
    };
    VARIABLES.challengeSportCounts = {};
    VARIABLES.challengeSportAthleteCounts = {};
    VARIABLES.challengeSportTotal = 0;
    for (row in qAthletesWithActivity) {
        sportCounts = deserializeJSON(row.tipos_atividade);
        athleteSportLabels = {};
        for (sport in sportCounts) {
            sportLabel = structKeyExists(VARIABLES.challengeSportLabels, sport)
                ? VARIABLES.challengeSportLabels[sport]
                : reReplace(sport, "([a-z])([A-Z])", "\1 \2", "all");
            sportCount = sportCounts[sport];
            VARIABLES.challengeSportCounts[sportLabel] = (VARIABLES.challengeSportCounts[sportLabel] ?: 0) + sportCount;
            VARIABLES.challengeSportTotal += sportCount;
            athleteSportLabels[sportLabel] = true;
        }
        for (sportLabel in athleteSportLabels) {
            VARIABLES.challengeSportAthleteCounts[sportLabel] = (VARIABLES.challengeSportAthleteCounts[sportLabel] ?: 0) + 1;
        }
    }
    VARIABLES.challengeSortedSports = structKeyArray(VARIABLES.challengeSportCounts);
    arraySort(VARIABLES.challengeSortedSports, function(leftLabel, rightLabel) {
        var difference = VARIABLES.challengeSportCounts[rightLabel] - VARIABLES.challengeSportCounts[leftLabel];
        return difference NEQ 0 ? difference : compareNoCase(leftLabel, rightLabel);
    });
</cfscript>

<section class="card mb-2" aria-labelledby="challenge-sports-heading">
    <h2 class="card-header px-3 py-2 fs-6 mb-0" id="challenge-sports-heading">Modalidades mais praticadas</h2>
    <div class="card-body p-3">
        <cfif VARIABLES.challengeSportTotal GT 0>
            <p class="small mb-2">Atividades válidas do Strava desde a inscrição, incluindo mais de uma no mesmo dia. Cada atleta conta uma vez por modalidade.</p>
            <div class="table-responsive" style="max-height: 18rem" tabindex="0" role="region" aria-labelledby="challenge-sports-heading">
                <table class="table table-sm mb-0">
                    <thead class="sticky-top bg-body-tertiary">
                        <tr>
                            <th scope="col">Modalidade</th>
                            <th scope="col" class="text-end">Atividades</th>
                            <th scope="col" class="text-end">% das atividades</th>
                            <th scope="col" class="text-end">Atletas únicos</th>
                        </tr>
                    </thead>
                    <tbody>
                        <cfloop array="#VARIABLES.challengeSortedSports#" item="sportLabel">
                            <cfset sportCount = VARIABLES.challengeSportCounts[sportLabel]/>
                            <cfoutput>
                                <tr>
                                    <th scope="row">#encodeForHTML(sportLabel)#</th>
                                    <td class="text-end">#lsNumberFormat(sportCount, '9,999', 'Portuguese (Brazilian)')#</td>
                                    <td class="text-end">#lsNumberFormat(sportCount * 100 / VARIABLES.challengeSportTotal, '9.9', 'Portuguese (Brazilian)')#%</td>
                                    <td class="text-end">#lsNumberFormat(VARIABLES.challengeSportAthleteCounts[sportLabel], '9,999', 'Portuguese (Brazilian)')#</td>
                                </tr>
                            </cfoutput>
                        </cfloop>
                    </tbody>
                </table>
            </div>
        <cfelse>
            <p class="mb-0">Ainda não há atividades do Strava para listar.</p>
        </cfif>
    </div>
</section>
