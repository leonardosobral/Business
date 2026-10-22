component extends="FixtureAIWorker" output=false {
    public any function init(required numeric id){super.init(id);variables.reader=new FixtureEnrichmentReader();variables.ai=new FixtureEnrichmentAI();return this;}
}
