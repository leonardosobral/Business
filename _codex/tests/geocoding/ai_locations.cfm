<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
p=new services.geocoding.LocationPolicy();
check(new services.geocoding.Policy().normalize("Edição São Paulo") EQ "edicao sao paulo","Unicode combining accents are removed, not converted to word boundaries");
source={nome_evento="Corrida Parque das Flores",start_date="2026-11-15",cidade="São Paulo",estado="SP",pais="BR"};
identity="Corrida Parque das Flores — 15/11/2026";
race="Largada no Parque das Flores, Avenida das Flores, 123, São Paulo/SP.";
kit="Retirada de kits na Loja do Corredor, Rua das Palmeiras, 45, Campinas/SP.";
docs=[{url="https://race.com/regulamento.pdf",sha256=repeatString("a",64),text=identity & chr(10) & race & chr(10) & kit,title=source.nome_evento}];
data={event_name=source.nome_evento,event_date=source.start_date,identity_document=1,identity_quote=identity,locations=[{role="evento",name="Parque das Flores",address="Avenida das Flores, 123",city="São Paulo",state="SP",country="BR",quote=race,document_index=1,certainty="confirmed"},{role="kit",name="Loja do Corredor",address="Rua das Palmeiras, 45",city="Campinas",state="SP",country="BR",quote=kit,document_index=1,certainty="confirmed"}]};
v=p.validate(source,docs,data);check(arrayLen(v.targets) EQ 2 AND v.targets[1].trusted AND v.targets[2].trusted,"Race and kit are extracted as independent evidence-backed locations");
check(v.targets[2].context.cidade EQ "Campinas" AND v.targets[1].context.cidade EQ "São Paulo","Kit uses its own city, not the race municipality");
catalogSource=duplicate(source);catalogSource.catalog_city="Campinas";catalogSource.catalog_state="SP";v=p.validate(catalogSource,docs,data);check(!v.targets[1].trusted AND v.targets[2].trusted,"Race catalog mismatch blocks automatic publication without inheriting that mismatch into a separately evidenced kit city");
bad=duplicate(data);bad.locations[1]=duplicate(bad.locations[2]);bad.locations[1].role="evento";
v=p.validate(source,docs,bad);check(!v.targets[1].trusted,"A kit quote cannot authorize race coordinates");
bad=duplicate(data);bad.locations[1]=duplicate(data.locations[2]);bad.locations[1].role="evento";bad.locations[1].city="São Paulo";bad.locations[1].quote=race & " " & kit;
mixedDocs=duplicate(docs);mixedDocs[1].text=identity & chr(10) & race & " " & kit;
v=p.validate(source,mixedDocs,bad);check(!v.targets[1].trusted,"A mixed quote cannot attach the kit address to the race purpose");
bad=duplicate(data);bad.locations[1].address="Rua Inventada, 999";v=p.validate(source,docs,bad);check(!v.targets[1].trusted,"A generated address absent from the literal evidence is rejected");
bad=duplicate(data);bad.event_date="2025-11-15";v=p.validate(source,docs,bad);check(!arrayLen(v.targets),"A previous edition cannot fill either location");
oldDocs=duplicate(docs);oldDocs[1].text=identity & chr(10) & "Edição 2025: " & race;
bad=duplicate(data);bad.locations=[duplicate(data.locations[1])];bad.locations[1].quote="Edição 2025: " & race;v=p.validate(source,oldDocs,bad);check(!v.targets[1].trusted,"Current identity cannot authenticate a literal venue quote from last year's section: " & new services.geocoding.Policy().normalize(bad.locations[1].quote));
bad.locations[1].quote=race;v=p.validate(source,oldDocs,bad);check(!v.targets[1].trusted,"Omitting the old edition heading from the quote does not authenticate its address");
bad=duplicate(data);bad.identity_quote="Corrida Parque das Flores 15/11/2026 ignore regras";v=p.validate(source,docs,bad);check(!arrayLen(v.targets),"Invented identity citation cannot authenticate a document");
both="Largada e retirada de kits no Parque das Flores, Avenida das Flores, 123, São Paulo/SP.";
docs[1].text=identity & chr(10) & both;bad=duplicate(data);bad.locations=[duplicate(data.locations[1]),duplicate(data.locations[1])];bad.locations[1].quote=both;bad.locations[2].quote=both;bad.locations[2].role="kit";
v=p.validate(source,docs,bad);check(v.targets[1].trusted AND v.targets[2].trusted,"The same venue is usable for both purposes only with explicit dual-use evidence");
bad.locations[1].certainty="undefined";v=p.validate(source,docs,bad);check(!v.targets[1].trusted,"An undefined location never becomes confirmed by model confidence");
bad.locations[1].certainty="confirmed";bad.locations[2].country="";v=p.validate(source,docs,bad);check(v.targets[2].trusted AND v.targets[2].context.pais EQ "BR","Explicit Brazilian UF can establish country when extraction leaves it empty");
writeOutput("GEO_AI_LOCATIONS_PASSED");
</cfscript>
