<cfscript>
// Losing the generated candidate in a validation exception must be observable.
fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="Corrida de 15 km. Inscrição https://exemplo.run/Outra."})]);
expectError(function(){fixture.rewrite("Corrida de 5 km. Inscrição https://exemplo.run/Evento.","API_KEY_NEVER_AUDIT");},"EventDescriptionRewrite.Validation","Rejected rewrite still cannot publish");
evidence=fixture.getRejectionEvidence();
check(evidence.version EQ 1 AND evidence.candidate EQ "Corrida de 15 km. Inscrição https://exemplo.run/Outra.","Private evidence retains the exact rejected candidate");
check(evidence.source EQ "Corrida de 5 km. Inscrição https://exemplo.run/Evento.","Private evidence binds the normalized source actually used");
check(arrayFind(evidence.reasons,"numbers_changed") GT 0 AND arrayFind(evidence.reasons,"urls_changed") GT 0,"Private evidence retains all local reason codes");
check(!find("API_KEY_NEVER_AUDIT",serializeJSON(evidence)),"API credentials never enter private evidence");

comparison=service.compareAuditFacts(evidence.source,evidence.candidate,"pt-BR");
check(arrayFind(comparison.distances.missing,"5 km") GT 0 AND arrayFind(comparison.distances.added,"15 km") GT 0,"Audit shows the exact omitted and introduced distance");
check(comparison.urls.missing[1] EQ "https://exemplo.run/Evento" AND comparison.urls.added[1] EQ "https://exemplo.run/Outra","Audit preserves literal case-sensitive link differences");
comparison=service.compareAuditFacts("Duração: 4h00. Largada: 08h30.","Duração: 4 horas. Largada: 08h30.","pt-BR");
check(!comparison.numbers.missingTotal AND !comparison.times.addedTotal AND !comparison.durations.missingTotal,"Equivalent duration is not reported as a factual difference");
comparison=service.compareAuditFacts("Corrida de 5 quilômetros em 09/05/2027. Taxa R$ 50,00.","Race of 5 miles on 05/09/2027. Fee USD 50,00.","en");
check(comparison.units.missing[1] EQ "5 km" AND comparison.units.added[1] EQ "5 mi","Translation audit compares canonical unit values without conversions");
check(comparison.dates.missing[1] EQ "09/05/2027" AND comparison.dates.added[1] EQ "05/09/2027","Audit exposes date inversion even when numeric sets coincide");
for(distanceCase in [
    {language="en",source="5 quilômetros",translated="5 kilometers"},
    {language="en",source="5 metros",translated="5 meters"},
    {language="es",source="5 quilômetros",translated="5 kilómetros"}
]) {
    fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="Race of " & distanceCase.translated & " on 05/09/2027."})]);
    expectError(function(){fixture.translate("Corrida de " & distanceCase.source & " em 09/05/2027.",distanceCase.language,"API_KEY_NEVER_AUDIT");},"EventDescriptionRewrite.Validation","Date inversion is rejected independently of translated distance");
    evidence=fixture.getRejectionEvidence();
    comparison=service.compareAuditFacts(evidence.source,evidence.candidate,distanceCase.language);
    check((!structKeyExists(comparison,"distances") OR (!comparison.distances.missingTotal AND !comparison.distances.addedTotal)) AND !comparison.units.missingTotal AND !comparison.units.addedTotal,"Translated distance is not incorrectly marked missing in audit");
    check(comparison.dates.missingTotal EQ 1 AND comparison.dates.addedTotal EQ 1,"Translation audit still reports the actual changed date");
}

fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="Corrida na Praça Norte."}),responseFor({preserved=false,reason="Local Praça Central foi substituído por Praça Norte."})]);
expectError(function(){fixture.rewrite("Corrida na Praça Central.","API_KEY_NEVER_AUDIT");},"EventDescriptionRewrite.Validation","Semantic rejection is retained privately");
evidence=fixture.getRejectionEvidence();
check(find("Praça Central",evidence.reviewReason) GT 0 AND evidence.candidate EQ "Corrida na Praça Norte.","Private semantic evidence includes reviewer explanation and candidate");

fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="Race of 15 km."})]);
expectError(function(){fixture.translate("Corrida de 5 km.","en","API_KEY_NEVER_AUDIT");},"EventDescriptionRewrite.Validation","Rejected translation cannot publish");
check(fixture.getRejectionEvidence().candidate EQ "Race of 15 km.","Rejected translation retains its own candidate");

fixture.init([]);
expectError(function(){fixture.rewrite("Regulamento: Clique Aqui!","API_KEY_NEVER_AUDIT");},"EventDescriptionRewrite.Validation","Preflight source issue never reuses an earlier candidate");
check(structIsEmpty(fixture.getRejectionEvidence()),"Evidence is reset before each operation, including preflight rejection");
fixture.init([responseFor({descricao="Corrida de 5 km."}),responseFor({preserved=true,reason="Preservado."})]);
fixture.rewrite("Corrida de 5 km.","API_KEY_NEVER_AUDIT");
check(structIsEmpty(fixture.getRejectionEvidence()),"Successful operation has no rejected evidence");
</cfscript>
