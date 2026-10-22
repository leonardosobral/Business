component extends="services.geocoding.LocationStore" output=false {
    public array function enqueue(required array ids,required string actor){return ids;}
}
