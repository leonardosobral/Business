component output=false {
    public struct function decode(required numeric status,required string body,required struct headers) {
        var result={ok=false,code="provider_unavailable",retryAfter=60,httpStatus=status,results=[]};var raw={};var row={};var item={};var k="";
        if(status EQ 0 OR status EQ 408){result.code="provider_timeout";return result;}
        if(status EQ 401 OR status EQ 403) {result.code="credentials_rejected";result.retryAfter=86400;return result;}
        if(status EQ 429) {
            result.code="rate_limited";
            if(structKeyExists(headers,"Retry-After") AND isSimpleValue(headers["Retry-After"])) {
                if(isNumeric(headers["Retry-After"])) result.retryAfter=max(1,min(86400,val(headers["Retry-After"])));
                else if(isDate(headers["Retry-After"])) result.retryAfter=max(1,min(86400,dateDiff("s",now(),parseDateTime(headers["Retry-After"]))));
            }
            return result;
        }
        if(status NEQ 200) return result;
        result.code="invalid_response";
        if(len(body) GT 500000 OR !isJSON(body)) return result;
        try {
            raw=deserializeJSON(body);
            if(!isStruct(raw) OR !structKeyExists(raw,"results") OR !isArray(raw.results) OR arrayLen(raw.results) GT 10) return result;
            for(row in raw.results) {
                if(!isStruct(row)) return result;
                item={rank={},datasource={}};
                for(k in listToArray("lat,lon,city,state,state_code,country_code,result_type,housenumber,street,name,formatted,place_id"))
                    if(structKeyExists(row,k) AND !isNull(row[k]) AND isSimpleValue(row[k])) item[k]=left(row[k] & "",600);
                if(structKeyExists(row,"rank") AND isStruct(row.rank)) for(k in listToArray("confidence,confidence_city_level,confidence_street_level,confidence_building_level"))
                    if(structKeyExists(row.rank,k) AND !isNull(row.rank[k]) AND isNumeric(row.rank[k]) AND val(row.rank[k]) GTE 0 AND val(row.rank[k]) LTE 1) item.rank[k]=val(row.rank[k]);
                if(structKeyExists(row,"datasource") AND isStruct(row.datasource)) for(k in ["sourcename","attribution","license"])
                    if(structKeyExists(row.datasource,k) AND !isNull(row.datasource[k]) AND isSimpleValue(row.datasource[k])) item.datasource[k]=left(row.datasource[k] & "",600);
                arrayAppend(result.results,item);
            }
            result.ok=true;result.code="ok";result.retryAfter=0;
        } catch(any invalidPayload) {result.results=[];}
        return result;
    }
    public struct function search(required struct query,required string apiKey) {
        var reply={};var status=0;
        if(!reFind("^[A-Za-z0-9_-]{16,128}$",apiKey)) return {ok=false,code="credentials_rejected",retryAfter=86400,results=[]};
        try {
            cfhttp(url="https://api.geoapify.com/v1/geocode/search",method="GET",timeout=15,redirect=false,result="reply",charset="utf-8") {
                cfhttpparam(type="url",name="text",value=left(query.text,500));
                cfhttpparam(type="url",name="format",value="json");
                cfhttpparam(type="url",name="lang",value="pt");
                cfhttpparam(type="url",name="limit",value="5");
                cfhttpparam(type="url",name="bias",value="countrycode:none");
                if(structKeyExists(query,"country") AND reFind("^[A-Za-z]{2}$",query.country)) cfhttpparam(type="url",name="filter",value="countrycode:" & lCase(query.country));
                if(query.kind EQ "city") cfhttpparam(type="url",name="type",value="city");
                cfhttpparam(type="url",name="apiKey",value=apiKey);
            }
            status=val(listFirst(reply.statusCode & ""," "));
            return decode(status,toString(reply.fileContent),isStruct(reply.responseHeader) ? reply.responseHeader : {});
        } catch(any transportError) {
            // Never rethrow CFHTTP exceptions: messages may contain the request key.
            return {ok=false,code="provider_timeout",retryAfter=60,httpStatus=0,results=[]};
        }
    }
}
