component extends="services.geocoding.LocationWorker" output=false {
    public any function init(required numeric id){super.init({apiKey="fixture-only",aiKey="fixture-only",aiModel="gpt-4.1-mini",aiDailyLimit=1000});variables.store=new BoundedAIStore();variables.store.bindWork(id);variables.reader=new FixtureAIReader();variables.ai=new FixtureAI();variables.geoClient=new FixtureAIGeo();return this;}
    public numeric function aiCallCount(){return variables.ai.callCount();}
    public void function setTemporarySource(required boolean value){variables.reader.setTemporary(value);}
    public void function setMissingSpecific(){variables.store.allowCalls();variables.geoClient.setEmptySpecific(true);}
    public void function setUnavailableAI(){variables.ai=new UnavailableAI();}
}
