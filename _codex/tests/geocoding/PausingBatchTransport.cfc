component extends="FixtureBatchTransport" output=false {
 public any function init(required any gate,string pausePath="files"){super.init();variables.gate=gate;variables.pausePath=pausePath;return this;}
 public struct function request(required string method,required string path,struct body={},string upload=""){
  var response=super.request(method,path,body,upload);if(path EQ variables.pausePath)variables.gate.pause();return response;
 }
}
