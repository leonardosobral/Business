component output=false {
    this.name='RunnerAppsLegacyRedirect';
    this.sessionManagement=false;
    this.setClientCookies=false;
    public boolean function onRequestStart(required string target) {
        setting requesttimeout=5 showdebugoutput=false;
        if (listLast(arguments.target,'/') NEQ 'index.cfm') {
            cfheader(statuscode=404);cfcontent(type='text/plain',reset=true);abort;
        }
        return true;
    }
    public void function onError(any exception,string eventName) {
        cfheader(statuscode=503);cfcontent(type='text/plain',reset=true);
        writeOutput('Temporarily unavailable.');
    }
}
