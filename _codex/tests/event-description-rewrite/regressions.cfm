<cfscript>
// Imported providers sometimes strip <style> tags but leave the complete stylesheet.
orphanCss="Detalhes: @import url('https://fonts.googleapis.com/css2?family=Quicksand:wght@500');" & chr(10)
    & "body{margin:0px;padding:0px;}" & chr(10)
    & ".table-principal > tbody > tr > td{line-height:25px;font-size:13px;}" & chr(10)
    & ".info-box p {" & chr(10) & "margin:0;" & chr(10) & "font-size:14px;" & chr(10)
    & "palavra que quer em negrito" & chr(10)
    & "PARA DEIXAR EM VERMELHO: palavra que quer em vermelho" & chr(10) & "-->" & chr(10);
cleanEvent="Corrida de 5 km em 08/11/2026. Largada às 08h30. Inscrição https://exemplo.run/prova.";
check(service.normalizeSource(orphanCss & cleanEvent) EQ cleanEvent,"Orphan stylesheet and exact template instructions are not event facts");
check(service.normalizeSource("Regras {atletas: 50; equipes: 10}. Saiba mais https://exemplo.run/500.") EQ "Regras {atletas: 50; equipes: 10}. Saiba mais https://exemplo.run/500.","Ordinary braces, numbers and URLs survive cleanup");
check(find("https://exemplo.run/regulamento",service.normalizeSource(orphanCss & "Regulamento: https://exemplo.run/regulamento")) GT 0,"Real regulation link survives stylesheet cleanup");
eventBeforeCss="Detalhes: Corrida de 5 km" & chr(10) & "body{margin:0px;padding:0px;}" & chr(10) & "Largada às 08h30.";
check(service.normalizeSource(eventBeforeCss) EQ eventBeforeCss,"Stylesheet selector cannot cross editorial lines and swallow event facts");
check(service.normalizeSource("Corrida no parque" & chr(10) & "body{margin:0px;}" & chr(10) & cleanEvent) EQ "Corrida no parque" & chr(10) & "body{margin:0px;}" & chr(10) & cleanEvent,"Prose without numeric tokens also ends prefix-only CSS cleanup");
check(service.normalizeSource("Corrida no parque body{margin:0px;}") EQ "Corrida no parque body{margin:0px;}","Ordinary opening words are not accepted as a stylesheet prefix");

for(placeholder in ["Regulamento: Clique Aqui!","Em breve Inscrições. Aguardem....."]) {
    fixture=createObject("component","services.ProviderFixture").init([]);
    try {fixture.rewrite(orphanCss & placeholder,"SENSITIVE_FIXTURE");check(false,"Placeholder must be rejected");}
    catch(EventDescriptionRewrite.Validation rejectedPlaceholder) {
        details=service.validationDetails(rejectedPlaceholder);
        check(details.code EQ "source_placeholder","Placeholder reports an actionable source issue");
        check(!find("SENSITIVE_FIXTURE",serializeJSON(details)),"Placeholder diagnostics contain no credential");
    }
    check(arrayLen(fixture.getRequests()) EQ 0,"Template-only source consumes no provider calls");
}
check(service.validateRewrite("Duração máxima do evento: 4h00.","A duração máxima do evento será de 4 horas.").valid,"Equivalent whole-hour duration does not become a changed clock");
check(service.validateRewrite("Largada 08h30. Duração máxima: 4h00.","Duração máxima: 4 horas. Largada 08h30.").valid,"Duration equivalent preserves the independent start time");
check(!service.validateRewrite("Duração máxima: 4h00. Taxa: 5 reais.","Duração máxima: 5 horas. Taxa: 4 reais.").valid,"Duration value cannot change even if numeric set is unchanged");
check(!service.validateRewrite("Largada: 04h00.","Largada: 4 horas.").valid,"Clock cannot be reinterpreted as a duration");
check(!service.validateRewrite("Duração: 4h00. Largada: 08h30.","Duração: 4 horas. Largada: 08h00.").valid,"Duration cleanup cannot hide a changed start time");
check(!service.validateRewrite("Duração: 4h30.","Duração: 4 horas.").valid,"Partial hours cannot lose minutes");
check(!service.validateRewrite("Duração: 4h00.","Duração: 240 minutos.").valid,"Duration unit conversions remain forbidden");
check(!service.validateRewrite("Duração: 4 horas. Largada: 08h00.","Duração: 4 horas. Largada: 08h04.").valid,"Duration context ends before a new clock sentence");
check(!service.validateRewrite("Duração: 4h00 e largada: 08h00.","Duração: 4 horas e largada: 8 horas.").valid,"A new clock label ends duration context even in the same sentence");
check(!service.validateRewrite("Duração: 1,5 horas.","Duração: 1,05 horas.").valid,"Fractional duration cannot be parsed as an independent integer hour");
fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="Maximum time: 4h00."}),responseFor({preserved=true,target_language=true,reason="Preserved."})]);
check(fixture.translate("Tempo máximo: 4h00.","en","SENSITIVE_FIXTURE").text EQ "Maximum time: 4h00.","Literal compact duration survives translated English context");
fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="Límite de tiempo: 4h00."}),responseFor({preserved=true,target_language=true,reason="Preservado."})]);
check(fixture.translate("Limite de tempo: 4h00.","es","SENSITIVE_FIXTURE").text EQ "Límite de tiempo: 4h00.","Literal compact duration survives translated Spanish context");

fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="Corrida de 15 km."})]);
try {fixture.rewrite("Corrida de 5 km.","SENSITIVE_FIXTURE");check(false,"Changed facts must reject");}
catch(EventDescriptionRewrite.Validation rejectionDetails) {
    details=service.validationDetails(rejectionDetails);
    check(arrayFind(details.reasons,"numbers_changed") GT 0 AND arrayFind(details.reasons,"distances_changed") GT 0,"Local rejection retains all reason codes");
    check(find("números",details.message) GT 0,"Rejection has a Portuguese operator explanation");
}
fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="Corrida na Praça Norte."}),responseFor({preserved=false,reason="SENSITIVE_FIXTURE"})]);
try {fixture.rewrite("Corrida na Praça Central.","SENSITIVE_FIXTURE");check(false,"Semantic change must reject");}
catch(EventDescriptionRewrite.Validation semanticDetails) {
    details=service.validationDetails(semanticDetails);
    check(details.code EQ "facts_not_preserved" AND !find("SENSITIVE_FIXTURE",serializeJSON(details)),"Semantic rejection uses safe enum instead of raw provider reason");
}
details=service.validationDetails({errorCode="SENSITIVE_FIXTURE",extendedInfo='["<script>unsafe</script>"]'});
check(details.code EQ "validation_rejected" AND !find("unsafe",serializeJSON(details)),"Unknown exception details cannot leak into cron history");
</cfscript>
