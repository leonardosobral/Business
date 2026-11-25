component output=false {
    this.name='RoadRunnersAdsNetworkV1';
    this.sessionManagement=false;
    this.setClientCookies=false;
    this.datasource='runnerhub';
    this.serialization.preserveCaseForStructKey=true;
    public boolean function onRequestStart(string targetPage) {
        setting showdebugoutput=false requesttimeout=15;
        cfheader(name='Cache-Control',value='no-store');
        cfheader(name='X-Content-Type-Options',value='nosniff');
        cfheader(name='Referrer-Policy',value='no-referrer');
        // This application has its own document root, no Business login/session.
        if(!listFindNoCase('ads.roadrunners.run',cgi.server_name)) {cfheader(statuscode=404);abort;}
        if(!listFind('serve,viewable,click',listFirst(listLast(targetPage,'/'),'.'))) {cfheader(statuscode=404);abort;}
        if(cgi.request_method!='POST') {cfheader(statuscode=405);cfheader(name='Allow',value='POST');abort;}
        if(val(cgi.content_length)>8192) {cfheader(statuscode=413);abort;}
        return true;
    }
    public void function onError(any exception,string eventName) {
        writeLog(file='ads_network',type='error',text='Request failed: ' & left(exception.type,100));
        cfheader(statuscode=503);cfcontent(type='application/json',reset=true);
        writeOutput('{"status":"unavailable"}');
    }
}
