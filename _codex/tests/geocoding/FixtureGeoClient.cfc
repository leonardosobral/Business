component output=false {
    public struct function search(required struct query,required string key) {
        if(query.local NEQ "Parque das Flores" OR !find("123",query.text))throw(type="Test.Failed",message="Worker discarded the source-confirmed venue/address");
        return {ok=true,code="ok",results=[{lat=-23.5614,lon=-46.6559,city="São Paulo",state_code="SP",country_code="br",result_type="amenity",name="Parque das Flores",street="Avenida das Flores",housenumber="123",rank={confidence=1,confidence_city_level=1,confidence_building_level=1}}]};
    }
}
