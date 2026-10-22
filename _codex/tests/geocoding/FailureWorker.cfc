component extends="services.geocoding.Worker" output=false {
    public any function init(){variables.config={apiKey="fixture-only"};variables.store=new FailureStore();variables.policy=new services.geocoding.Policy();return this;}
    public struct function counts(){return variables.store.counts();}
}
