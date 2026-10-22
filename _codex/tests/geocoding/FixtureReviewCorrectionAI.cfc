component extends="FixtureEnrichmentAI" output=false {
    public struct function extract(required struct context,required array documents){
        var reply=super.extract(context,documents);
        // A genuinely conflicting pair remains reviewable even when fieldEvidence
        // cannot bind either citation to this edition. No provider is contacted.
        reply.facts.identity_quote="Identidade não confirmada na fonte";
        reply.facts.attributes=[{field="organizador",value="Associação Flores",quote="Organizador: Associação Flores.",document_index=1,certainty="conflicting"},{field="organizador",value="Outro organizador",quote="Organizador: Outro organizador.",document_index=1,certainty="conflicting"}];return reply;
    }
}
