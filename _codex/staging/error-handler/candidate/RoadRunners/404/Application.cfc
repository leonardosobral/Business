component output="false" {
    this.name="RoadRunnersNotFound";
    this.sessionManagement=false;
    boolean function onRequestStart(string targetPage){return true;}
    void function onError(any exception,string eventName="") {
        cfheader(statuscode=500,statustext="Internal Server Error");
        cfheader(name="Cache-Control",value="no-store");
        cfcontent(type="text/html; charset=utf-8",reset=true);
        writeOutput('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>Road Runners</title><h1>Uma pausa no percurso</h1><p>Tente novamente em instantes.</p><a href="/">Ir para o início</a></html>');
    }
}
