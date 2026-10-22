<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
reader=new services.geocoding.Sources();
source={nome_evento="Corrida do Parque das Flores",start_date="2026-10-17",cidade="São Paulo",estado="SP",pais="BR",endereco="",descricao="",descricao_original="",catalog_city="",catalog_state=""};
doc={url="https://race.com/prova-2026",sha256=repeatString("a",64),kind="html",title="Corrida do Parque das Flores 2026",text="Corrida do Parque das Flores 17/10/2026",jsonld=[{"@type"="SportsEvent",name="Corrida do Parque das Flores",startDate="2026-10-17T07:00:00-03:00",location={"@type"="Place",name="Parque das Flores",address={streetAddress="Avenida das Flores, 123",addressLocality="São Paulo",addressRegion="SP",addressCountry="BR"}}}]};
result=reader.parseDocument(source,doc);
check(arrayLen(result.queries) EQ 1 AND result.queries[1].autoEligible AND result.queries[1].venue EQ "Parque das Flores" AND result.queries[1].housenumber EQ "123","Matching event JSON-LD yields a dated specific venue/address with provenance");
old=duplicate(doc);old.jsonld[1].startDate="2025-10-17";old.text="Corrida do Parque das Flores 17/10/2025";
check(!arrayLen(reader.parseDocument(source,old).queries),"A previous edition cannot provide the event location");
other=duplicate(doc);other.jsonld[1].name="Corrida da Montanha Azul";other.title="Corrida da Montanha Azul";other.text="Corrida da Montanha Azul 17/10/2026";
check(!arrayLen(reader.parseDocument(source,other).queries),"Another race on the same day is not a location source");
kit=duplicate(doc);kit.jsonld=[];kit.text="Corrida do Parque das Flores 17/10/2026" & chr(10) & "Retirada de kits" & chr(10) & "Local: Shopping Exemplo";
check(!arrayLen(reader.parseDocument(source,kit).queries),"A kit collection location is not a start venue");
textDoc=duplicate(kit);textDoc.kind="pdf";textDoc.text="REGULAMENTO Corrida do Parque das Flores 17/10/2026" & chr(10) & "Local da largada: Parque das Flores";
check(arrayLen(reader.parseDocument(source,textDoc).queries) EQ 1,"A dated textual regulation can identify the explicit start venue");
conflict=duplicate(doc);conflict.jsonld[1].location.address.addressLocality="Campinas";
check(!reader.parseDocument(source,conflict).queries[1].autoEligible,"External city mismatch cannot be auto-applied");
policy=new services.geocoding.Policy();
query=reader.parseDocument(source,doc).queries[1];
candidate={lat=-23.5614,lon=-46.6559,city="São Paulo",state_code="SP",country_code="br",result_type="amenity",name="Parque das Flores",street="Avenida das Flores",housenumber="123",rank={confidence=1,confidence_city_level=1,confidence_building_level=1}};
check(policy.evaluate(source,query,[candidate]).status EQ "auto_applied","A source-confirmed venue with full address is evaluated as the named venue");
cfdocument(format="PDF",name="local.regulationPdf"){writeOutput("<h1>Corrida do Parque das Flores</h1><p>17/10/2026</p><p>Local da largada: Parque das Flores</p>");}
pdfDoc={url="https://race.com/regulamento.pdf",sha256=repeatString("b",64),kind="pdf",pdf=toBase64(regulationPdf)};
pdfResult=reader.parseDocument(source,pdfDoc);
check(arrayLen(pdfResult.queries) EQ 1 AND pdfResult.queries[1].local EQ "Parque das Flores","Native PDF extraction reads a regulation in memory without external binaries");
shopping={nome_evento="Corre Cidade + Movimente-se: Edição Especial Outubro Rosa",start_date="2026-10-17",cidade="Belo Horizonte",estado="MG",pais="BR"};
shoppingDoc={url="https://www.sympla.com.br/evento/prova/123",kind="html",sha256=repeatString("c",64),title="Corre Cidade + Movimente-se: Edição Especial Outubro Rosa",text="Corre Cidade + Movimente-se: Edição Especial Outubro Rosa" & chr(10) & "17 out - 2026 • 08:30" & chr(10) & "Local" & chr(10) & "Shopping Cidade" & chr(10) & "Rua dos Tupis, 337 Centro" & chr(10) & "Belo Horizonte, MG",jsonld=[]};
shoppingResult=reader.parseDocument(shopping,shoppingDoc);
check(arrayLen(shoppingResult.queries) EQ 1 AND shoppingResult.queries[1].housenumber EQ "337" AND shoppingResult.queries[1].street EQ "Rua dos Tupis","A dated official location block yields venue, street and number without including neighborhood as house number");
writeOutput("GEO_SOURCES_PASSED");
</cfscript>
