component extends="services.geocoding.LocationWorker" output=false {
    public any function init(required numeric id,required string aiKey){super.init({apiKey="fixture-only",aiKey=aiKey,aiModel="gpt-4.1-mini",aiDailyLimit=1000});variables.store=new ReplayAIStore();variables.store.bindWork(id);return this;}
}
