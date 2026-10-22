<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
geoClient=new services.geocoding.GeoapifyClient();
raw={results=[{lat=-23.5,lon=-46.6,city="São Paulo",country_code="br",state_code="SP",result_type="building",housenumber="1",street="Rua A",rank={confidence=1,confidence_city_level=1,confidence_building_level=1},datasource={attribution="© OpenStreetMap contributors"},apiKey="NEVER_COPY",unknown="ignore"}]};
reply=geoClient.decode(200,serializeJSON(raw),{});
check(arrayLen(reply.results) EQ 1 AND reply.results[1].lat EQ -23.5,"Provider decoding retains usable coordinates");
check(!find("NEVER_COPY",serializeJSON(reply)) AND !structKeyExists(reply.results[1],"unknown"),"Provider decoding allowlist drops unknown and secret fields");
for(status in [401,403,429,500]) {
 reply=geoClient.decode(status,'{"message":"https://example/?apiKey=NEVER_COPY"}',{"Retry-After"="120"});
 check(!reply.ok AND !find("NEVER_COPY",serializeJSON(reply)),"Provider error is safe for status " & status);
 if(status EQ 429) check(reply.retryAfter EQ 120 AND reply.code EQ "rate_limited","Rate-limit cooldown respects retry header");
 if(status EQ 401 OR status EQ 403) check(reply.code EQ "credentials_rejected","Authentication failure stops provider calls");
}
reply=geoClient.decode(200,"not-json",{});check(!reply.ok AND reply.code EQ "invalid_response","Malformed provider body cannot become success");
reply=geoClient.decode(200,'{"results":[]}',{});check(reply.ok AND !arrayLen(reply.results),"Empty valid result is distinct from provider failure");
reply=geoClient.decode(408,"timeout",{});check(reply.code EQ "provider_timeout" AND reply.retryAfter EQ 60,"A transport timeout has a short explicit retry, not a generic five-minute outage");
writeOutput("GEO_PROVIDER_PASSED");
</cfscript>
