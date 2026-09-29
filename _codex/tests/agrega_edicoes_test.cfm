<cfinclude template="matching.cfm"/><cfscript>
checks=[];
for (c in [{input="1ª Etapa Circuito das Águas 2025",expected="1 etapa circuito das aguas"},{input="Desafio 24 Horas de São Paulo",expected="desafio 24 horas de sao paulo"},{input="4ª Corrida da Cidade 2025",expected="corrida da cidade"},{input="5ª EDIÇÃO Corrida da Cidade 2026",expected="corrida da cidade"},{input="Corrida Cidade - 2ª Etapa 10 km 2026",expected="corrida cidade 2 etapa 10 km"}]) {
 actual=agregaReviewNormalizeText(c.input);arrayAppend(checks,{input=c.input,expected=c.expected,actual=actual,passed=actual==c.expected});
}
function fixture(id, name, date, extra={}) {
 var row={id_evento=id,nome_evento=name,cidade="São Paulo",estado="SP",pais="BR",tag="",data_inicial=date,data_comparacao=date,id_agrega_evento=0,tipo_agregacao="",ativo=true,tipo_corrida="rua"};structAppend(row,extra,true);return row;
}
function testPair(label,rows,count,firstYear=2025,secondYear=2026) {
 var q=queryNew("id_evento,nome_evento,cidade,estado,pais,tag,data_inicial,data_comparacao,id_agrega_evento,tipo_agregacao,ativo,tipo_corrida", "integer,varchar,varchar,varchar,varchar,varchar,date,date,integer,varchar,bit,varchar",rows);
 var actual=structCount(agregaReviewMatchEditions(q,firstYear,secondYear).groups);
 arrayAppend(checks,{input=label,expected=count,actual=actual,passed=actual==count});
}
a=fixture(1,"4ª Corrida da Cidade 2025","2025-05-01");b=fixture(2,"5ª CORRIDA DA CIDADE 2026","2026-05-03");
testPair("Consecutive editions",[a,b],1);
testPair("Numeric distances differ",[fixture(1,"Desafio 24 Horas da Cidade","2025-05-01"),fixture(2,"Desafio 12 Horas da Cidade","2026-05-03")],0);
testPair("Stage numbers differ",[fixture(1,"1ª Etapa Circuito das Águas","2025-05-01"),fixture(2,"2ª Etapa Circuito das Águas","2026-05-03")],0);
testPair("Duplicate annual edition",[a,b,fixture(3,a.nome_evento,"2025-10-01")],0);
testPair("Inactive duplicate still blocks",[a,b,fixture(3,a.nome_evento,"2025-10-01",{ativo=false})],0);
testPair("Nonconsecutive editions",[a,fixture(2,"6ª Corrida da Cidade 2026","2026-05-03")],0);
testPair("Different race type",[a,fixture(2,b.nome_evento,"2026-05-03",{tipo_corrida="trail"})],0);
testPair("Different city",[a,fixture(2,b.nome_evento,"2026-05-03",{cidade="Santos"})],0);
testPair("Date shift beyond 90 days",[a,fixture(2,b.nome_evento,"2026-10-03")],0);
testPair("Already linked",[fixture(1,a.nome_evento,a.data_inicial,{id_agrega_evento=21}),fixture(2,b.nome_evento,b.data_inicial,{id_agrega_evento=21})],0);
testPair("Circuit aggregator",[fixture(1,a.nome_evento,a.data_inicial,{id_agrega_evento=21,tipo_agregacao="circuito"}),b],0);
testPair("Missing type",[a,fixture(2,b.nome_evento,b.data_inicial,{tipo_corrida=""})],0);
testPair("Leap day",[fixture(1,"Corrida da Cidade Aberta","2023-02-28"),fixture(2,"Corrida da Cidade Aberta","2024-02-29")],1,2023,2024);
testPair("One existing aggregator",[fixture(1,a.nome_evento,a.data_inicial,{id_agrega_evento=21}),b],1);
testPair("Missing country",[a,fixture(2,b.nome_evento,b.data_inicial,{pais=""})],0);
testPair("Different country",[a,fixture(2,b.nome_evento,b.data_inicial,{pais="PT"})],0);
testPair("Conflicting aggregators remain reviewable",[fixture(1,a.nome_evento,a.data_inicial,{id_agrega_evento=21}),fixture(2,b.nome_evento,b.data_inicial,{id_agrega_evento=22})],1);
testPair("Short generic name",[fixture(1,"Corrida 2025","2025-05-01"),fixture(2,"Corrida 2026","2026-05-01")],0);
arrayAppend(checks,{input="Other year in brand preserved",passed=agregaReviewNormalizeText("Corrida Clube 1930 2025",2025,2026)=="corrida clube 1930"});
writeOutput(serializeJSON(checks));
</cfscript>
