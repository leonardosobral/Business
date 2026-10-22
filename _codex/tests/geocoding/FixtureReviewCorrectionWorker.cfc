component extends="FixtureEnrichmentWorker" output=false {
    public any function init(required numeric id){super.init(id);variables.ai=new FixtureReviewCorrectionAI();return this;}
}
