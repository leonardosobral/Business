component extends="FixtureGeoClient" output=false {
    public struct function search(required struct query,required string key) {
        var result=super.search(query,key);result.results[1].rank.confidence=0.8;return result;
    }
}
