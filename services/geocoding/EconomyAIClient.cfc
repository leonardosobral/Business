component extends="services.geocoding.AIClient" output=false {
    public struct function requestBody(required struct context,required array documents,string model="gpt-6.1-sol"){
        return new services.geocoding.EconomyPolicy().body(context,documents,model);
    }
}
