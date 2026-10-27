component output=false {
 variables.calls=[];
 public string function enviarEmail(required string subject,required string html,required string email,required string name){arrayAppend(variables.calls,{email=email,name=name,subject=subject});return 'OK';}
 public array function calls(){return duplicate(variables.calls);}
}
