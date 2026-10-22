<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
security=new services.geocoding.JobSecurity();
check(!security.verify("GET","{}",{},"test-secret").allowed,"GET cannot run a geocoding job");
check(!security.verify("POST","{}",{},"test-secret").allowed,"Unsigned POST cannot process events");
stamp=dateTimeFormat(now(),"yyyy-mm-dd HH:nn:ss");body='{"limit":5}';secret="test-secret";
headers={"X-RR-Handoff-Timestamp"=stamp,"X-RR-Handoff-Signature"=lCase(hmac(stamp & "." & body,secret,"HmacSHA256"))};
check(security.verify("POST",body,headers,secret).allowed,"Valid HMAC permits bounded job dispatch");
check(!security.verify("POST",body & " ",headers,secret).allowed,"Modified signed body is rejected");
check(!security.verify("POST",body,headers,"").allowed,"Missing configured secret fails closed");
writeOutput("GEO_ENDPOINT_PASSED");
</cfscript>
