component extends="EventDescriptionRewriteService" output="false" {
    public any function init(required array responses) {
        variables.responses=arguments.responses;
        variables.requests=[];
        return this;
    }
    public struct function requestProvider(required struct payload,required string apiKey) {
        arrayAppend(variables.requests,duplicate(arguments.payload));
        if(!arrayLen(variables.responses)) throw(type="Test.Failed",message="Unexpected extra provider request");
        var response=variables.responses[1];
        arrayDeleteAt(variables.responses,1);
        return response;
    }
    public array function getRequests() {return duplicate(variables.requests);}
}
