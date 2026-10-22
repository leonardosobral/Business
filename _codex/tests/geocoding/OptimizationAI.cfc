component extends="FixtureAI" output=false {
    public struct function extract(required struct context,required array documents){var result=super.extract(context,documents);for(var target in result.facts.locations)target.certainty="conflicting";result.facts.attributes=[{field="organizador",value="Associação Flores",quote="Organizador: Associação Flores.",document_index=1,certainty="conflicting"}];return result;}
}
