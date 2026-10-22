<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
// A real request with a spelled-out UF/country must not become a false geographic conflict.
fixtureSource={nome_evento="Corrida Parque das Flores",start_date="2026-11-15",cidade="Florianópolis",estado="SC",pais="BR"};
fixtureIdentity="Corrida Parque das Flores — 15/11/2026";
fixtureQuote="Largada no Parque das Flores, Rua das Flores, 123, Florianópolis, Santa Catarina, Brasil.";
fixtureDocs=[{url="https://example.com/regulamento",sha256=repeatString("a",64),text=fixtureIdentity & chr(10) & fixtureQuote}];
fixtureFacts={event_name=fixtureSource.nome_evento,event_date=fixtureSource.start_date,identity_document=1,identity_quote=fixtureIdentity,locations=[{role="evento",name="Parque das Flores",address="Rua das Flores, 123",city="Florianópolis",state="Santa Catarina",country="Brasil",quote=fixtureQuote,document_index=1,certainty="confirmed"}]};
fixtureLocation=new services.geocoding.LocationPolicy().validate(fixtureSource,fixtureDocs,fixtureFacts);
check(arrayLen(fixtureLocation.targets) EQ 1 AND fixtureLocation.targets[1].trusted AND fixtureLocation.targets[1].context.estado EQ "SC" AND fixtureLocation.targets[1].context.pais EQ "BR","Spelled-out UF and country become canonical equivalents, not a review");
fixtureRegions=new services.geocoding.RegionNames();
check(fixtureRegions.country("Brazil") EQ "BR" AND fixtureRegions.country("Portugal") EQ "PT" AND fixtureRegions.state("BR-SC") EQ "SC","Country languages and Brazilian UF prefixes have authoritative aliases");
check(fixtureRegions.country("Brasil") NEQ fixtureRegions.country("Bolívia") AND fixtureRegions.state("Mato Grosso") NEQ fixtureRegions.state("Mato Grosso do Sul"),"Different countries and neighboring UFs are never merged");
fixtureP=new services.geocoding.EnrichmentPolicy();
fixtureText="Organizador: Associação Flores. Horários de largada: 5 km às 07:00 e 10 km às 07:30. Site oficial: https://example.com/corrida. Inscrições de 01/09/2026 a 10/11/2026.";
fixtureDocs[1].text &= chr(10) & fixtureText;
fixtureFacts.attributes=[{field="organizador",value="Associação Flores",quote="Organizador: Associação Flores.",document_index=1,certainty="confirmed"},{field="horarios_largada",value="5 km às 07:00 e 10 km às 07:30",quote="Horários de largada: 5 km às 07:00 e 10 km às 07:30.",document_index=1,certainty="confirmed"}];
fixtureSource.organizador="";fixtureSource.localizacoes={};
fixtureDecision=fixtureP.validate(fixtureSource,fixtureDocs,fixtureFacts);
check(arrayLen(fixtureDecision.fields) EQ 2 AND fixtureDecision.fields[1].status EQ "fill" AND fixtureDecision.fields[2].status EQ "fill","Literal facts with purpose and correct edition can fill native and complementary blanks");
fixtureSource.organizador="Organizador manual";fixtureDecision=fixtureP.validate(fixtureSource,fixtureDocs,fixtureFacts);
check(fixtureDecision.fields[1].status EQ "needs_review" AND fixtureDecision.fields[1].current EQ "Organizador manual","A real divergence preserves the existing value for review");
fixtureSource.organizador="Associação Flores";fixtureDecision=fixtureP.validate(fixtureSource,fixtureDocs,fixtureFacts);
check(fixtureDecision.fields[1].status EQ "equivalent","An already matching value needs neither a write nor review");
fixtureBad=duplicate(fixtureFacts);fixtureBad.attributes[1].value="Organização inventada";fixtureDecision=fixtureP.validate(fixtureSource,fixtureDocs,fixtureBad);
check(!fixtureDecision.fields[1].trusted AND fixtureDecision.fields[1].status EQ "unconfirmed","Invented values are not accepted by model confidence");
fixtureBad=duplicate(fixtureFacts);fixtureBad.attributes[1].field="endereco";fixtureBad.attributes[1].value="Rua das Flores, 123";fixtureBad.attributes[1].quote="Retirada de kits na Rua das Flores, 123, Florianópolis/SC.";fixtureDocs[1].text &= chr(10) & fixtureBad.attributes[1].quote;
fixtureDecision=fixtureP.validate(fixtureSource,fixtureDocs,fixtureBad);check(!fixtureDecision.fields[1].trusted,"A kit address cannot fill the race address");
fixtureBad=duplicate(fixtureFacts);fixtureBad.attributes[1].field="pais";fixtureBad.attributes[1].value="Brasil";fixtureBad.attributes[1].quote=fixtureQuote;fixtureDecision=fixtureP.validate(fixtureSource,fixtureDocs,fixtureBad);
check(fixtureDecision.fields[1].status EQ "equivalent" AND fixtureDecision.fields[1].value EQ "BR","Native country names and codes do not create false divergences");
fixtureBad=duplicate(fixtureFacts);fixtureBad.attributes[1].field="organizador";fixtureBad.attributes[1].value="Flores";fixtureBad.attributes[1].quote="Retirada de kits na Loja Flores.";fixtureDocs[1].text &= chr(10) & fixtureBad.attributes[1].quote;
fixtureDecision=fixtureP.validate(fixtureSource,fixtureDocs,fixtureBad);check(!fixtureDecision.fields[1].trusted,"Literal text with the wrong semantic purpose is not trusted");
fixtureBad=duplicate(fixtureFacts);fixtureBad.event_date="2025-11-15";fixtureDecision=fixtureP.validate(fixtureSource,fixtureDocs,fixtureBad);
check(!fixtureDecision.fields[1].trusted,"A different edition cannot enrich the event");
fixtureBad=duplicate(fixtureFacts);fixtureBad.attributes=[{field="data_final",value="2026-11-16",quote="O evento ocorre nos dias 15 e 16/11/2026.",document_index=1,certainty="confirmed"}];fixtureDocs[1].text &= chr(10) & fixtureBad.attributes[1].quote;
fixtureDecision=fixtureP.validate(fixtureSource,fixtureDocs,fixtureBad);check(fixtureDecision.fields[1].trusted,"ISO dates must be justified by a real equivalent date in the source");
fixtureBad.attributes[1].value="2026-02-31";fixtureDecision=fixtureP.validate(fixtureSource,fixtureDocs,fixtureBad);check(!fixtureDecision.fields[1].trusted,"Impossible dates cannot reach a native date column");
fixtureBad=duplicate(fixtureFacts);fixtureBad.attributes=[{field="organizador",value="<script>alert(1)</script>",quote="Organizador: <script>alert(1)</script>.",document_index=1,certainty="confirmed"}];fixtureDocs[1].text &= chr(10) & fixtureBad.attributes[1].quote;fixtureDecision=fixtureP.validate(fixtureSource,fixtureDocs,fixtureBad);
check(!fixtureDecision.fields[1].trusted,"Markup cannot be promoted into native event text fields");
fixtureBad=duplicate(fixtureFacts);fixtureBad.attributes=[{field="url_hotsite",value="https://example.com/Evento",quote="Site oficial: https://example.com/evento.",document_index=1,certainty="confirmed"}];fixtureDocs[1].text &= chr(10) & fixtureBad.attributes[1].quote;fixtureDecision=fixtureP.validate(fixtureSource,fixtureDocs,fixtureBad);
check(!fixtureDecision.fields[1].trusted,"URL path case cannot be invented by punctuation-insensitive matching");
check(!fixtureRegions.hasCountry("Largada no Parque de Flores, Brasil.","DE") AND !fixtureRegions.hasState("Largada em Campo Grande, Mato Grosso do Sul.","MT"),"Ordinary words and shorter state names cannot authenticate another region");
fixtureBad=duplicate(fixtureFacts);fixtureBad.attributes=[{field="organizador",value="Loja X",quote="Organização: Associação Y. Patrocínio: Loja X.",document_index=1,certainty="confirmed"}];fixtureDocs[1].text &= chr(10) & fixtureBad.attributes[1].quote;fixtureDecision=fixtureP.validate(fixtureSource,fixtureDocs,fixtureBad);
check(!fixtureDecision.fields[1].trusted,"A sponsor cannot borrow the organizer marker from a different clause");
fixtureBad.attributes[1].value="Associação Antiga";fixtureBad.attributes[1].quote="Corrida Parque das Flores — 15/11/2025. Organizador: Associação Antiga.";fixtureDocs[1].text &= chr(10) & fixtureBad.attributes[1].quote;fixtureDecision=fixtureP.validate(fixtureSource,fixtureDocs,fixtureBad);
check(!fixtureDecision.fields[1].trusted,"An explicit historical event date invalidates its attribute citation");
writeOutput("GEO_ENRICHMENT_POLICY_PASSED");
</cfscript>
