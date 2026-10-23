component output=false {
    public any function init(required string apiKey){variables.apiKey=apiKey;return this;}
    public struct function request(required string method,required string path,struct body={},string upload=""){
        if(!listFind("GET,POST",method) OR !reFind("^(files|batches|batches/[A-Za-z0-9_-]{1,100}|files/[A-Za-z0-9_-]{1,100}/content)$",path))throw(message="Caminho Batch inválido.");
        var response={};
        cfhttp(url="https://api.openai.com/v1/" & path,method=method,result="response",timeout=12,redirect=false,throwonerror=false,charset="utf-8"){
            cfhttpparam(type="header",name="Authorization",value="Bearer " & variables.apiKey);
            if(len(upload)){
                cfhttpparam(type="formfield",name="purpose",value="batch");
                cfhttpparam(type="file",name="file",file=upload,mimetype="application/jsonl");
            }else if(method EQ "POST"){
                cfhttpparam(type="header",name="Content-Type",value="application/json");cfhttpparam(type="body",value=serializeJSON(body));
            }
        }return response;
    }
}
