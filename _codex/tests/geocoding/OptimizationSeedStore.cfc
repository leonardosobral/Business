component extends="services.geocoding.LocationStore" output=false {
    public any function init(required numeric id){variables.fixtureId=id;return this;}
    public array function selectEvents(numeric limit=5){return [variables.fixtureId];}
}
