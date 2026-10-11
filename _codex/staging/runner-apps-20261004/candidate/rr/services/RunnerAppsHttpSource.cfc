component output=false {
    public struct function fetch() {
        var response={};
        cfhttp(url='https://api.roadrunners.run/v1/discovery/runner-apps.cfm',method='get',timeout=3,result='response',redirect=false) {
            cfhttpparam(type='header',name='Accept',value='application/json');
        }
        if (left(response.statusCode,3) NEQ '200' || !isJSON(response.fileContent)) {
            throw(type='RunnerApps.Unavailable',message='Runner apps catalog unavailable');
        }
        return deserializeJSON(response.fileContent);
    }
}
