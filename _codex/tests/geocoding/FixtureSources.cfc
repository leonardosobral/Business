component output=false {
    public struct function research(required struct source,required numeric deadline) {
        var doc={url="https://race.com/2026",kind="html",sha256=repeatString("d",64),title="Corrida do Parque das Flores",text="Corrida do Parque das Flores 17/10/2026",jsonld=[{"@type"="SportsEvent",name="Corrida do Parque das Flores",startDate="2026-10-17",location={name="Parque das Flores",address={streetAddress="Avenida das Flores, 123",addressLocality="São Paulo",addressRegion="SP",addressCountry="BR"}}}]};
        var parsed=new services.geocoding.Sources().parseDocument(source,doc);
        return {version=2,documents=1,checked_at="2026-10-17 10:00:00",queries=parsed.queries,evidence=[parsed.queries[1].evidence],diagnostics=parsed.diagnostics,pages=[{url=doc.url,kind="html",sha256=doc.sha256}]};
    }
}
