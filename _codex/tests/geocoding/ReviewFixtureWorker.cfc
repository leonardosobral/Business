component extends="FixtureWorker" output=false {
    public any function init(required numeric workId) {
        super.init(workId);variables.geoClient=new ReviewGeoClient();return this;
    }
}
