component extends="services.geocoding.Worker" output=false {
    public any function init(required numeric workId) {
        variables.config={apiKey="fixture-only"};variables.store=new BoundedStore();variables.store.bindWork(workId);
        variables.policy=new services.geocoding.Policy();variables.geoClient=new FixtureGeoClient();variables.sources=new FixtureSources();return this;
    }
}
