component extends="services.geocoding.Worker" output=false {
    public any function init(required struct config,required numeric workId) {
        super.init(config);variables.store=new BoundedStore();variables.store.bindWork(workId);return this;
    }
}
