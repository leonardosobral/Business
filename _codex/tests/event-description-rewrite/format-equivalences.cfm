<cfscript>
// These exercise the real translate path; only the paid provider is replaced.
formatSource="Largada 7h. Até 7.000 participantes. Inscrições de 01/03/2026 a 21/08/2026. Taxa R$ 190,00. Duração: 2 horas.";
formatCandidate="Start at 7 a.m. Up to 7,000 participants. Registration from 03/01/2026 to 08/21/2026. Fee R$ 190.00. Duration: 2 hours.";
fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao=formatCandidate}),responseFor({preserved=true,target_language=true,reason="Same facts after format restoration."})]);
formatResult=fixture.translate(formatSource,"en","SENSITIVE_FIXTURE");
check(formatResult.text EQ "Start at 7h. Up to 7.000 participants. Registration from 01/03/2026 to 21/08/2026. Fee R$ 190,00. Duration: 2 hours.","The observed thousands, AM clock and unambiguously US date sequence retain source spellings");
check(arrayLen(fixture.getRequests()) EQ 2 AND find("7h",fixture.getRequests()[2].input[2].content),"Restored facts still pass through an independent factual review");
formatDelta=service.compareAuditFacts(formatSource,formatCandidate,"en");
for(formatKind in ["numbers","times","units","dates","currencies"])check(!formatDelta[formatKind].missingTotal AND !formatDelta[formatKind].addedTotal,"Audit uses the same safe format equivalence for " & formatKind);

for(formatCase in [
 {source="Largada 19h30.",candidate="Start at 7:30 p.m.",expected="Start at 19h30."},
 {source="Largada 00h. Encerramento 12h.",candidate="Start at 12 a.m. Finish at 12 p.m.",expected="Start at 00h. Finish at 12h."},
 {source="Largada 07h30.",candidate="Start at 7:30 AM.",expected="Start at 07h30."},
 {source="Duração: 2h. Largada: 7h.",candidate="Duration: 2h. Start: 7 a.m.",expected="Duration: 2h. Start: 7h."},
 {source="Limite: 1.234.567 participantes. Taxa R$ 1.234,50.",candidate="Limit: 1,234,567 participants. Fee R$ 1,234.50.",expected="Limit: 1.234.567 participants. Fee R$ 1.234,50."},
 {source="Corrida em 21/08/2026.",candidate="Race on 2026-08-21.",expected="Race on 21/08/2026."},
 {source="Corrida em 21/08/2026.",candidate="Race on 08/21/2026.",expected="Race on 21/08/2026."}
]) {
 fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao=formatCase.candidate}),responseFor({preserved=true,target_language=true,reason="Same facts."})]);
 check(fixture.translate(formatCase.source,"en","SENSITIVE_FIXTURE").text EQ formatCase.expected,"Equivalent format is restored: " & formatCase.candidate);
}

for(formatBad in [
 {source="Até 7.000 participantes.",candidate="Up to 7,001 participants."},
 {source="Até 7.000 participantes.",candidate="Up to 7.000 participants." & " Fee R$ 8.00."},
 {source="Taxa R$ 1.234,50.",candidate="Fee R$ 1,234.51."},
 {source="Largada 7h.",candidate="Start at 7 p.m."},
 {source="Largada 19h30.",candidate="Start at 7:31 p.m."},
 {source="Até 7 participantes.",candidate="At 7 a.m. participants gather."},
 {source="Duração: 7h.",candidate="Duration: 7 a.m."},
 {source="Duração: 4h30.",candidate="Duration: 4:30 a.m."},
 {source="A corrida dura 7h. Largada 8h.",candidate="The race lasts 7 a.m. Start at 8 a.m."},
 {source="Prova de 7h de duração. Largada 8h.",candidate="Race of 7 a.m. duration. Start at 8 a.m."},
 {source="Prova 7h.",candidate="Race 7 a.m."},
 {source="Duração: 7h. Largada: 7h.",candidate="The race takes 7 a.m. Start at 7 a.m."},
 {source="Tempo máximo após a largada: 7h.",candidate="Maximum time after the start: 7 a.m."},
 {source="Largada 7:00 min.",candidate="Start at 7 a.m."},
 {source="Largada 7h.",candidate="Start at 13 a.m."},
 {source="Largada 7h.",candidate="Start at 7:60 a.m."},
 {source="Inscrições de 01/03/2026 a 21/08/2026.",candidate="Registration from 03/02/2026 to 08/21/2026."},
 {source="Inscrições de 01/03/2026 a 21/08/2026.",candidate="Registration from 03/01/2026 to 08/22/2026."},
 {source="Corrida em 09/05/2027.",candidate="Race on 05/09/2027."},
 {source="Corrida em 28/02/2026.",candidate="Race on 02/30/2026."},
 {source="Inscrição https://example.com/7.000/21/08/2026/ .",candidate="Registration https://example.com/7,000/08/21/2026/ ."},
 {source="Inscrição www.example.com/7.000",candidate="Registration www.example.com/7,000"},
 {source="Contato evento7.000@example.com.",candidate="Contact evento7,000@example.com."}
]) {
 fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao=formatBad.candidate})]);
 expectError(function(){fixture.translate(formatBad.source,"en","SENSITIVE_FIXTURE");},"EventDescriptionRewrite.Validation","Real change or unproved format stays rejected: " & formatBad.candidate);
 check(arrayLen(fixture.getRequests()) EQ 1,"Unsafe equivalence never consumes the independent reviewer call");
}

fixture=createObject("component","services.ProviderFixture").init([responseFor({descricao="Start at 7 a.m. at Praça Norte."}),responseFor({preserved=false,target_language=true,reason="The official venue changed."})]);
expectError(function(){fixture.translate("Largada 7h na Praça Central.","en","SENSITIVE_FIXTURE");},"EventDescriptionRewrite.Validation","Format normalization never bypasses semantic venue review");
check(fixture.getRejectionEvidence().candidate EQ "Start at 7 a.m. at Praça Norte.","Private rejection retains the raw provider candidate, not a silently edited copy");
check(!service.validateRewrite("Até 7.000 participantes.","Até 7,000 participantes.").valid,"Portuguese rewrite guards remain strict and unchanged");
</cfscript>
