component output=false {
    variables.emptySpecific=false;
    public void function setEmptySpecific(required boolean value){variables.emptySpecific=value;}
    public struct function search(required struct query,required string apiKey){var kit=find("Campinas",query.text) GT 0;if(variables.emptySpecific AND query.kind EQ "specific")return {ok=true,code="ok",results=[]};return {ok=true,code="ok",results=[{lat=kit ? -22.9 : -23.56,lon=kit ? -47.1 : -46.65,city=kit ? "Campinas" : "São Paulo",state_code="SP",country_code="br",result_type=query.kind EQ "city" ? "city" : "building",housenumber=kit ? "123" : "1578",street=kit ? "Rua Flores" : "Avenida Paulista",rank={confidence=1,confidence_city_level=1,confidence_building_level=1}}]};}
}
