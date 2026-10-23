component extends="services.geocoding.LocationWorker" output=false {
    public any function init(required numeric id){super.init({apiKey="fixture-only",aiKey="fixture-only",aiModel="gpt-6.1-sol",aiDailyLimit=1000});variables.store=new BoundedAIStore();variables.store.bindWork(id);variables.reader=new FixtureAIReader();variables.ai=new FixtureAI();variables.geoClient=new FixtureAIGeo();variables.fixtureBudget=new services.geocoding.AIBudget("fixture-" & createUUID());refreshEconomy();return this;}
    public void function refreshEconomy(){variables.economy=new services.geocoding.Economy(variables.config,variables.fixtureBudget,new FixtureBatchTransport(),variables.ai,variables.store,variables.ai);}
    public numeric function aiCallCount(){return variables.ai.callCount();}
    public void function setTemporarySource(required boolean value){variables.reader.setTemporary(value);}
    public void function setMissingSpecific(){variables.store.allowCalls();variables.geoClient.setEmptySpecific(true);}
    public void function setUnavailableAI(){variables.ai=new UnavailableAI();refreshEconomy();}
}
