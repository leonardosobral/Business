component output=false {
    variables.requests=[];variables.output="";
    public any function init(string output=""){variables.output=output;return this;}
    public array function calls(){return variables.requests;}
    public void function setOutput(required string value){variables.output=value;}
    public boolean function observe(required string module,required string operation,required string model,required struct response,numeric durationMs=0){return true;}
    public struct function request(required string method,required string path,struct body={},string upload=""){
        arrayAppend(variables.requests,{method=method,path=path});
        if(path EQ "files")return {statusCode="200",fileContent='{"id":"file_fixture"}'};
        if(path EQ "batches")return {statusCode="200",fileContent='{"id":"batch_fixture"}'};
        if(path EQ "batches/batch_fixture")return {statusCode="200",fileContent='{"status":"completed","output_file_id":"file_output"}'};
        if(path EQ "files/file_output/content")return {statusCode="200",fileContent=variables.output};
        throw(message="Unexpected fixture transport");
    }
}
