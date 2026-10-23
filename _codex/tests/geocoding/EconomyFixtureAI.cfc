component output=false {
 variables.count=0;
 public any function init(required struct reply){variables.reply=reply;return this;}
 public numeric function calls(){return variables.count;}
 public struct function extract(required struct context,required array documents){variables.count++;return duplicate(variables.reply);}
}
