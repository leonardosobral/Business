<cfsetting showdebugoutput="false" requesttimeout="40">
<cfscript>
status=200;
result={success=true};
try {
    if(CGI.REQUEST_METHOD!='POST') throw(type='BrevoWebhook.Method');
    if(compareNoCase(listFirst(CGI.HTTP_HOST,':'),'business.roadrunners.run')!=0) throw(type='BrevoWebhook.Forbidden');
    events=new services.BrevoMarketingEvents();
    events.authenticate(getHttpRequestData(false).headers);
    if(val(CGI.CONTENT_LENGTH)>2097152) throw(type='BrevoWebhook.TooLarge');
    events.accept(toString(getHttpRequestData().content));
} catch(BrevoWebhook.Method e) {
    status=405;
    cfheader(name='Allow',value='POST');
} catch(BrevoWebhook.Forbidden e) {
    status=403;
} catch(BrevoWebhook.Invalid e) {
    status=400;
} catch(BrevoWebhook.TooLarge e) {
    status=413;
} catch(any unavailable) {
    // Brevo only retries HTTP 429 among explicit error responses.
    status=429;
    cfheader(name='Retry-After',value='600');
    writeLog(file='application',type='warning',text='Brevo marketing webhook temporarily unavailable');
}
result.success=(status==200);
cfheader(statuscode=status);
cfheader(name='Cache-Control',value='no-store');
cfcontent(reset=true,type='application/json; charset=utf-8');
writeOutput(serializeJSON(result));
</cfscript>
