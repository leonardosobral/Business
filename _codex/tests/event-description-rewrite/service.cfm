<cfscript>
assertions=0;
function check(required boolean condition,required string name) {
    if(!arguments.condition) throw(type="Test.Failed",message=arguments.name);
    assertions++;
    writeOutput("PASS " & arguments.name & chr(10));
}
function expectError(required any operation,required string expectedType,required string name) {
    var caught=false;
    try {arguments.operation();} catch(any error) {
        caught=true;
        check(compareNoCase(error.type,arguments.expectedType) EQ 0,arguments.name & " type");
        check(!find("SENSITIVE_FIXTURE",error.message & error.detail),arguments.name & " sanitized");
    }
    check(caught,arguments.name & " rejected");
}
check(fileExists(getDirectoryFromPath(getCurrentTemplatePath()) & "services/EventDescriptionRewriteService.cfc"),"Rewrite service is available");
service=createObject("component","services.EventDescriptionRewriteService");
source=service.normalizeSource('<p>Corrida &amp; caminhada: 5 km e 10 km.</p><p>Largada: 07h30 na Pra&ccedil;a da S&eacute;.</p><a href="https://exemplo.run/prova?x=1&amp;y=2">Inscri&ccedil;&otilde;es</a><script>999 segredo</script>');
check(find("Corrida & caminhada: 5 km e 10 km.",source) GT 0,"HTML entities preserve source facts");
check(find("Praça da Sé",source) GT 0,"Named HTML entities decode accents");
check(find("https://exemplo.run/prova?x=1&y=2",source) GT 0,"Anchor destination is preserved");
check(find("https://exemplo.run/prova",service.normalizeSource('<a href=https://exemplo.run/prova>Inscrição</a>')) GT 0,"Unquoted HTML anchor destination is preserved");
check(find(chr(10),source) GT 0,"Paragraph boundaries remain visible");
check(!find("999",source) AND !find("<p>",source),"Script and formatting markup are excluded");
check(service.normalizeSource('7&##104;30 &##8212; R&##36; 50,00') EQ '7h30 — R$ 50,00',"Numeric entities preserve time and price");
check(service.normalizeSource('Prova&nbsp;de&##x20;21,1 km') EQ 'Prova de 21,1 km',"Numeric hexadecimal and nbsp entities decode");
check(service.normalizeSource('&amp;lt;!--[if !supportLists]--&amp;gt;Corrida de 5 km.') EQ 'Corrida de 5 km.',"Escaped Word comments do not become event facts");
expectError(function(){service.normalizeSource(repeatString('a',20001));},"EventDescriptionRewrite.Validation","Oversized source is rejected without truncation");
expectError(function(){service.normalizeSource('<script>only executable content</script>');},"EventDescriptionRewrite.Validation","Empty normalized source");

rewriteRequest=service.buildRewriteRequest("Prova de 21,1 km. Largada às 07h30.");
check(rewriteRequest.model EQ "gpt-4.1-mini" AND !rewriteRequest.store AND rewriteRequest.temperature EQ 0,"Rewrite request selects deterministic non-stored Responses call");
check(rewriteRequest.text.format.type EQ "json_schema" AND rewriteRequest.text.format.strict,"Rewrite request requires structured JSON");
check(rewriteRequest.text.format.schema.required[1] EQ "descricao" AND !rewriteRequest.text.format.schema.additionalProperties,"Description is the sole required response field");
check(arrayLen(rewriteRequest.input) EQ 2 AND rewriteRequest.input[1].role EQ "system" AND rewriteRequest.input[2].role EQ "user","Source is isolated from system instructions");
check(find("21,1 km",rewriteRequest.input[2].content) GT 0,"Full source reaches rewrite request");

check(service.validateRewrite("Corrida de 5 km. Largada às 07h30 na Praça Central.","Na Praça Central, a corrida de 5 km terá largada às 07h30.").valid,"Prose can change while facts remain");
check(service.validateRewrite("Corrida de 5km e caminhada de 3km.","- Corrida de 5km" & chr(10) & "- Caminhada de 3km.").valid,"Plain hyphen lists preserve distances without formatting markup");
check(service.validateRewrite("1. Kit: camisa oficial. 2. Medalha após 5km.","1. O kit inclui camisa oficial." & chr(10) & "2. A medalha é entregue após 5km.").valid,"Existing numbered list labels remain valid plain text");
check(service.validateRewrite("1.1 Kit: camisa oficial. 1.2 Medalha após 5km.","1.1 O kit inclui camisa oficial." & chr(10) & "1.2 A medalha é entregue após 5km.").valid,"Numbered subsection labels retain their literal values");
check(service.validateRewrite("Meia maratona de 21,1 km.","A distância da meia maratona será de 21.1 km.").valid,"Unambiguous decimal comma and point may alternate");
check(!service.validateRewrite("Corrida de 5 km e 10 km.","Corrida de 5 km e 15 km.").valid,"Changed distance is rejected");
check(!service.validateRewrite("Modalidade de 5 km e taxa de 10 reais.","Modalidade de 10 km e taxa de 5 reais.").valid,"Distance-number associations are preserved");
check(!service.validateRewrite("Largada às 07h30. 30 vagas.","Largada às 07h07. 30 vagas.").valid,"Time changes are rejected even when number set matches");
check(!service.validateRewrite("Percurso de 1.000 m.","Percurso de 1 km.").valid,"Unit conversions are not silently permitted");
check(!service.validateRewrite("Taxa R$ 1.000.","Taxa R$ 1,000.").valid,"Ambiguous thousands punctuation is not normalized");
check(!service.validateRewrite("Taxa de R$ 50,00.","Taxa de R$ 50,00. São 100 vagas.").valid,"New numeric facts are rejected");
check(!service.validateRewrite("Contato equipe@exemplo.run.","Contato outra@exemplo.run.").valid,"Email substitutions are rejected");
check(!service.validateRewrite("Inscrição https://exemplo.run/Evento.","Inscrição https://exemplo.run/evento.").valid,"URL paths retain case");
check(!service.validateRewrite("Corrida no parque.","<p>Corrida no parque.</p>").valid,"HTML response is rejected");
check(!service.validateRewrite("Corrida no parque.","**Corrida** no parque.").valid,"Markdown response is rejected");
check(!service.validateRewrite("Corrida no parque.","*Corrida* no parque.").valid,"Single-marker Markdown is rejected");
check(!service.validateRewrite("Corrida no parque.","## Corrida no parque.").valid,"Markdown heading remains rejected");
check(!service.validateRewrite("Corrida no parque.","`Corrida no parque.`").valid,"Markdown code remains rejected");
check(!service.validateRewrite("Inscrição https://exemplo.run/prova.","[Inscrição](https://exemplo.run/prova).").valid,"Markdown links remain rejected");
check(!service.validateRewrite("Corrida no parque.","").valid,"Empty response is rejected");
check(!service.validateRewrite("Corrida no parque.","Corrida no parque...").valid,"Trailing ellipsis signals an incomplete response");

function responseFor(required struct data) {
    return {status="completed",output=[{type="message",role="assistant",content=[{type="output_text",text=serializeJSON(arguments.data)}]}]};
}
validResponse=responseFor({descricao="Corrida de 5 km."});
check(service.parseResponse(validResponse) EQ "Corrida de 5 km.","Responses message text parses to description");
expectError(function(){service.parseResponse({status="incomplete",output=validResponse.output});},"EventDescriptionRewrite.Provider","Incomplete provider output");
expectError(function(){service.parseResponse({status="completed",output=[{type="message",content=[{type="refusal",refusal="SENSITIVE_FIXTURE"}]}]});},"EventDescriptionRewrite.Provider","Provider refusal");
expectError(function(){service.parseResponse(responseFor({descricao="",extra="SENSITIVE_FIXTURE"}));},"EventDescriptionRewrite.Provider","Malformed structured description");
expectError(function(){service.parseResponse({status="completed",output=[{type="message",content=[{type="output_text",text="SENSITIVE_FIXTURE"}]}]});},"EventDescriptionRewrite.Provider","Invalid provider JSON");

fixture=createObject("component","services.ProviderFixture").init([
    responseFor({descricao="Na Praça Central, a corrida de 5 km terá largada às 07h30."}),
    responseFor({preserved=true,reason="Todos os fatos foram preservados."})
]);
result=fixture.rewrite("Corrida de 5 km. Largada às 07h30 na Praça Central.","SENSITIVE_FIXTURE");
check(result.text EQ "Na Praça Central, a corrida de 5 km terá largada às 07h30." AND result.model EQ "gpt-4.1-mini","Rewrite returns factual reviewed text");
check(arrayLen(fixture.getRequests()) EQ 2,"Independent factual review is required before success");
reviewRequest=fixture.getRequests()[2];
check(reviewRequest.text.format.schema.properties.preserved.type EQ "boolean" AND reviewRequest.text.format.schema.properties.reason.type EQ "string","Factual checker uses a distinct structured schema");
check(find("Praça Central",reviewRequest.input[2].content) GT 0 AND !reviewRequest.store,"Factual checker receives full evidence without persistent storage");

fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="Largada às 07h30 na Praça Norte. Corrida de 5 km."}),responseFor({preserved=false,reason="SENSITIVE_FIXTURE local alterado"})]);
expectError(function(){fixture.rewrite("Largada às 07h30 na Praça Central. Corrida de 5 km.","SENSITIVE_FIXTURE");},"EventDescriptionRewrite.Validation","Factual review rejects changed named location");
fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="Corrida de 15 km."})]);
expectError(function(){fixture.rewrite("Corrida de 5 km.","SENSITIVE_FIXTURE");},"EventDescriptionRewrite.Validation","Local guard rejects changed number before second call");
check(arrayLen(fixture.getRequests()) EQ 1,"Invalid local result does not consume checker call");
fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="Corrida no parque."}),responseFor({preserved="true",reason=""})]);
expectError(function(){fixture.rewrite("Corrida no parque.","SENSITIVE_FIXTURE");},"EventDescriptionRewrite.Provider","Checker must return a JSON boolean");
fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="Corrida & caminhada." & chr(10) & "Encontro no parque."}),responseFor({preserved=true,reason="Preservado"})]);
result=fixture.rewrite("Corrida & caminhada." & chr(10) & "Encontro no parque.","SENSITIVE_FIXTURE");
check(find("&amp;",result.html) GT 0 AND find("<br>",result.html) GT 0,"Stored HTML encodes plain text and retains line breaks");
expectError(function(){service.rewrite("Corrida no parque.","");},"EventDescriptionRewrite.Provider","Missing API key cannot start provider request");
include "translation.cfm";
writeOutput("EVENT_REWRITE_TESTS_PASSED:" & assertions & chr(10));
</cfscript>
