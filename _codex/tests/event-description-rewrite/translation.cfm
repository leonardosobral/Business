<cfscript>
check(structKeyExists(service,"translate"),"Translation method is available without replacing rewrite");
translationSource="Corrida da Praça: 5 quilômetros e caminhada de 500 metros. Largada às 07h30 em 07/04/2026 na Praça Central, Rua das Flores, 10. Taxa R$ 89,99.";
englishTranslation="Corrida da Praça: a 5 kilometer race and a 500 meter walk. Start at 07h30 on 07/04/2026 at Praça Central, Rua das Flores, 10. Fee R$ 89,99.";
fixture=createObject("component","services.ProviderFixture").init([
    responseFor({descricao=englishTranslation}),
    responseFor({preserved=true,target_language=true,reason="Complete and faithful English translation."})
]);
translationResult=fixture.translate(translationSource,"en","SENSITIVE_FIXTURE");
check(translationResult.text EQ englishTranslation AND translationResult.language EQ "en" AND translationResult.model EQ "gpt-4.1-mini","English translation preserves facts and translates unit words");
check(arrayLen(fixture.getRequests()) EQ 2,"Translation requires exactly one independent review");
translationRequests=fixture.getRequests();
check(!translationRequests[1].store AND !translationRequests[2].store AND translationRequests[1].temperature EQ 0,"Both translation calls disable storage and use deterministic temperature");
check(translationRequests[1].text.format.type EQ "json_schema" AND translationRequests[1].text.format.strict,"Translation output is schema constrained");
check(find("inglês",translationRequests[1].input[1].content) GT 0 AND find("07/04/2026",translationRequests[1].input[2].content) GT 0,"Translator receives explicit target language and complete published source");
check(translationRequests[2].text.format.schema.properties.target_language.type EQ "boolean","Independent review must explicitly attest target language");
check(find("07/04/2026",translationRequests[2].input[2].content) GT 0,"Reviewer receives complete original and candidate");

spanishTranslation="Corrida da Praça: carrera de 5 kilómetros y caminata de 500 metros. Salida a las 07h30 el 07/04/2026 en Praça Central, Rua das Flores, 10. Tarifa R$ 89,99.";
fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao=spanishTranslation}),responseFor({preserved=true,target_language=true,reason="Traducción fiel al español."})]);
translationResult=fixture.translate(translationSource,"es","SENSITIVE_FIXTURE");
check(translationResult.text EQ spanishTranslation AND translationResult.language EQ "es","Spanish translation preserves facts and translated kilometer spelling");
check(find("espanhol",fixture.getRequests()[1].input[1].content) GT 0,"Spanish target is explicit in translation instructions");

fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="Race: 5 miles. Water: 500 millilitres. Limit: 2 hours and 30 minutes."}),responseFor({preserved=true,target_language=true,reason="Preserved units."})]);
translationResult=fixture.translate("Corrida: 5 milhas. Água: 500 mililitros. Limite: 2 horas e 30 minutos.","en","SENSITIVE_FIXTURE");
check(find("500 millilitres",translationResult.text) GT 0,"Distance, volume and duration units can translate without conversions");
fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="Carrera: 5 millas. Agua: 500 mililitros. Límite: 2 horas y 30 minutos."}),responseFor({preserved=true,target_language=true,reason="Unidades preservadas."})]);
translationResult=fixture.translate("Corrida: 5 milhas. Água: 500 mililitros. Limite: 2 horas e 30 minutos.","es","SENSITIVE_FIXTURE");
check(find("5 millas",translationResult.text) GT 0,"Spanish miles retain the source unit");
fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="A 5-kilometre race with a 500-metre walk."}),responseFor({preserved=true,target_language=true,reason="Faithful distance units."})]);
translationResult=fixture.translate("Corrida de 5 quilômetros com caminhada de 500 metros.","en","SENSITIVE_FIXTURE");
check(find("5-kilometre",translationResult.text) GT 0,"Hyphenated English unit adjectives retain distances");
fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="Altura: 1 pie. Ancho: 2 pies."}),responseFor({preserved=true,target_language=true,reason="Medidas preservadas."})]);
translationResult=fixture.translate("Altura: 1 pé. Largura: 2 pés.","es","SENSITIVE_FIXTURE");
check(find("1 pie",translationResult.text) GT 0 AND find("2 pies",translationResult.text) GT 0,"Spanish singular and plural feet preserve the source unit");

for(invalidLanguage in ["pt","fr","en-US",""]) {
    fixture=createObject("component","services.ProviderFixture").init([]);
    expectError(function(){fixture.translate("Corrida no parque.",invalidLanguage,"SENSITIVE_FIXTURE");},"EventDescriptionRewrite.Validation","Unsupported target language " & invalidLanguage);
    check(arrayLen(fixture.getRequests()) EQ 0,"Unsupported language makes no provider call");
}
fixture=createObject("component","services.ProviderFixture").init([]);
expectError(function(){fixture.translate(repeatString("a",20001),"en","SENSITIVE_FIXTURE");},"EventDescriptionRewrite.Validation","Translation cannot truncate long source");
check(arrayLen(fixture.getRequests()) EQ 0,"Oversized source makes no translation request");
expectError(function(){service.translate("Corrida no parque.","en","");},"EventDescriptionRewrite.Provider","Translation requires a configured API key");

for(invalidTranslation in [
    "Race of 15 km. Start at 07h30 on 07/04/2026. Fee R$ 50,00.",
    "Race of 5 km. Start at 07h07 on 07/04/2026. Fee R$ 50,00.",
    "Race of 5 miles. Start at 07h30 on 07/04/2026. Fee R$ 50,00.",
    "Race of 5 km. Start at 07h30 on 04/07/2026. Fee R$ 50,00.",
    "Race of 5 km. Start at 07h30 on 07/04/2026. Fee US$ 50,00."
]) {
    fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao=invalidTranslation})]);
    expectError(function(){fixture.translate("Corrida de 5 km. Largada às 07h30 em 07/04/2026. Taxa R$ 50,00.","en","SENSITIVE_FIXTURE");},"EventDescriptionRewrite.Validation","Local translation guard rejects changed numeric, time, unit, date or currency fact");
    check(arrayLen(fixture.getRequests()) EQ 1,"Invalid local translation does not consume reviewer call");
}
fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="Limit: 2 minutes and 30 hours."})]);
expectError(function(){fixture.translate("Limite: 2 horas e 30 minutos.","en","SENSITIVE_FIXTURE");},"EventDescriptionRewrite.Validation","Duration values cannot exchange units");

fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="Race at Praça Norte."}),responseFor({preserved=false,target_language=true,reason="SENSITIVE_FIXTURE changed official place."})]);
expectError(function(){fixture.translate("Corrida na Praça Central.","en","SENSITIVE_FIXTURE");},"EventDescriptionRewrite.Validation","Translation reviewer rejects changed official name");
fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="Corrida na Praça Central."}),responseFor({preserved=true,target_language=false,reason="SENSITIVE_FIXTURE Portuguese retained."})]);
expectError(function(){fixture.translate("Corrida na Praça Central.","en","SENSITIVE_FIXTURE");},"EventDescriptionRewrite.Validation","Translation reviewer rejects wrong output language");
fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="Race at Praça Central."}),responseFor({preserved=true,target_language="true",reason="SENSITIVE_FIXTURE"})]);
expectError(function(){fixture.translate("Corrida na Praça Central.","en","SENSITIVE_FIXTURE");},"EventDescriptionRewrite.Provider","Translation review language decision must be a JSON boolean");
fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="Race at Praça Central."}),responseFor({preserved=true,reason="SENSITIVE_FIXTURE missing language result"})]);
expectError(function(){fixture.translate("Corrida na Praça Central.","en","SENSITIVE_FIXTURE");},"EventDescriptionRewrite.Provider","Translation review cannot omit target-language decision");

fixture=createObject("component","services.ProviderFixture").init([{status="completed",output=[{type="message",content=[{type="refusal",refusal="SENSITIVE_FIXTURE"}]}]}]);
expectError(function(){fixture.translate("Corrida na Praça Central.","en","SENSITIVE_FIXTURE");},"EventDescriptionRewrite.Provider","Translation refusal is rejected");
fixture=createObject("component","services.ProviderFixture").init([{status="incomplete",output=responseFor({descricao="Race at Praça Central."}).output}]);
expectError(function(){fixture.translate("Corrida na Praça Central.","en","SENSITIVE_FIXTURE");},"EventDescriptionRewrite.Provider","Incomplete translation is rejected");
fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="<p>Race at Praça Central.</p>"})]);
expectError(function(){fixture.translate("Corrida na Praça Central.","en","SENSITIVE_FIXTURE");},"EventDescriptionRewrite.Validation","Translation HTML is rejected before review");
fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="Race & walk." & chr(10) & "Meeting at Praça Central."}),responseFor({preserved=true,target_language=true,reason="Complete faithful translation."})]);
translationResult=fixture.translate("<p>Corrida &amp; caminhada.</p><p>Encontro na Praça Central.</p>","en","SENSITIVE_FIXTURE");
check(find("&amp;",translationResult.html) GT 0 AND find("<br>",translationResult.html) GT 0 AND !find("<p>",translationResult.text),"Translation normalizes published HTML and safely encodes output lines");
</cfscript>
