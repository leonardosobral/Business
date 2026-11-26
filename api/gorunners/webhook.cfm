<cfsetting showdebugoutput="false" requesttimeout="40"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfheader name="Cache-Control" value="no-store"/>
<cfscript>
function respond(required numeric status) output=true {
    cfheader(statuscode=arguments.status);
    writeOutput(serializeJSON({"received":arguments.status==200}));
    abort;
}
if (cgi.request_method!="POST") {cfheader(name="Allow",value="POST");respond(405);}
if (listFirst(cgi.content_type,";")!="application/json") respond(415);
if (val(cgi.content_length ?: 0)>131072) respond(413);
api=new ads.gorunners.CommerceClient();
if (!api.enabled()) respond(503);
requestData=getHttpRequestData();
raw=requestData.content;
body=isBinary(raw) ? charsetEncode(raw,"utf-8") : raw;
if (len(body)>131072) respond(413);
provider=url.provider ?: "gorunners";
if (!listFind("gorunners,pagarme",provider)) respond(404);
if (provider=="gorunners" && !api.signed(raw,requestData.headers["X-GR-Signature"] ?: "")) respond(401);
if (!isJSON(body)) respond(400);
event=deserializeJSON(body);
if (!isStruct(event) || !isStruct(event.data ?: "")) respond(400);
sales=new ads.gorunners.ZoneSales(api);
try {
    if (provider=="gorunners") {
        if (!isValid("guid",event.id ?: "") || compare(event.id,requestData.headers["X-GR-Delivery"] ?: "") ||
            compare(event.event ?: "",requestData.headers["X-GR-Event"] ?: "") ||
            !listFind("order.created,order.paid,order.activated,order.expired,order.cancelled,order.rejected",event.event ?: "") ||
            !isStruct(event.data.order ?: "") || !len(event.created_at ?: "")) respond(400);
        sales.gameEvent(event);
    } else {
        // Only authenticated retrieval from the merchant can confirm a payment.
        code="";
        if (left(event.type ?: "",6)=="order.") code=event.data.code ?: "";
        else if (isStruct(event.data.order ?: "")) code=event.data.order.code ?: "";
        else if (isStruct(event.data.charge ?: "") && isStruct(event.data.charge.order ?: "")) code=event.data.charge.order.code ?: "";
        if (reFind("^RHGR-[0-9a-f]{32}$",code)) sales.paymentEvent(code);
    }
} catch (any e) {
    cflog(file="gorunners_zones",text="Falha ao processar evento de #provider# (#e.type#)");
    respond(503);
}
respond(200);
</cfscript>
