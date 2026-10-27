component output="false" {
  variables.path='/var/lib/runnerhub-business/helpdesk/quick-replies.json';
  public any function init(string path='/var/lib/runnerhub-business/helpdesk/quick-replies.json'){variables.path=arguments.path;return this;}
  private array function defaults(){return [
    {id='contexto',title='Pedir informações para investigar',text='Olá! Para entendermos melhor o que aconteceu, você pode informar em qual etapa encontrou a dificuldade e qual mensagem apareceu? Se enviar uma captura de tela, oculte senhas e outros dados sensíveis.'&chr(10)&chr(10)&'Com esse contexto, poderemos orientar os próximos passos.'},
    {id='andamento',title='Informar que estamos verificando',text='Olá! Obrigado por compartilhar os detalhes. Vamos analisar as informações do chamado para orientar você com segurança. Se houver algum contexto adicional que possa ajudar, pode nos enviar por aqui.'},
    {id='confirmacao',title='Pedir confirmação da solução',text='Olá! Você conseguiu realizar o procedimento orientado na nossa conversa? Se a dificuldade continuar, conte em qual etapa ela ocorre e qual mensagem aparece para darmos continuidade ao atendimento.'}
  ];}
  private struct function read(){
    if(!fileExists(variables.path))return {revision='initial',items=defaults()};
    if(getFileInfo(variables.path).size GT 10000000)throw(type='HelpdeskReplies.Storage',message='Biblioteca indisponível.');
    var raw=fileRead(variables.path,'utf-8');var data=deserializeJSON(raw);
    if(!isStruct(data) OR !structKeyExists(data,'items') OR !isArray(data.items))throw(type='HelpdeskReplies.Storage',message='Biblioteca indisponível.');
    data.revision=lCase(hash(raw,'SHA-256'));return data;
  }
  public struct function list(){
    var result={};lock name='helpdesk-replies-#hash(variables.path)#' type='readonly' timeout=10 {result=read();}return result;
  }
  private void function write(required struct data){
    var parent=getDirectoryFromPath(variables.path);
    if(!directoryExists(parent))throw(type='HelpdeskReplies.Storage',message='Armazenamento da biblioteca indisponível.');
    var tmp=createObject('java','java.io.File').createTempFile('quick-replies-','.tmp',createObject('java','java.io.File').init(parent));
    var target=createObject('java','java.io.File').init(variables.path);var stream=0;
    try {
      fileSetAccessMode(tmp.getPath(),'600');
      stream=createObject('java','java.io.RandomAccessFile').init(tmp,'rw');
      stream.write(charsetDecode(serializeJSON(arguments.data),'utf-8'));stream.getFD().sync();stream.close();stream=0;
      if(!tmp.renameTo(target))throw(type='HelpdeskReplies.Storage',message='Não foi possível salvar a biblioteca.');
    } finally {
      if(isObject(stream))stream.close();
      if(tmp.exists())tmp.delete();
    }
  }
  private struct function mutate(required string action,required string id,required string title,required string text,required string revision,required numeric actorId){
    var result={};var cleanTitle=trim(arguments.title);var cleanText=trim(arguments.text);
    if(arguments.actorId LT 1 OR (arguments.action EQ 'save' AND (!len(cleanTitle) OR len(cleanTitle) GT 80 OR !len(cleanText) OR len(cleanText) GT 12000)))throw(type='HelpdeskReplies.Validation',message='Preencha título (até 80 caracteres) e mensagem (até 12.000 caracteres).');
    lock name='helpdesk-replies-#hash(variables.path)#' type='exclusive' timeout=10 {
      // The Business runtime is a single JVM; this named lock spans requests.
        var data=read();
        if(compare(data.revision,arguments.revision) NEQ 0)throw(type='HelpdeskReplies.Conflict',message='A biblioteca foi alterada por outro atendente. Recarregue a página e revise sua alteração.');
        var position=0;for(var i=1;i LTE arrayLen(data.items);i++)if(data.items[i].id EQ arguments.id)position=i;
        if(len(arguments.id) AND !position)throw(type='HelpdeskReplies.Conflict',message='Esta resposta não está mais disponível. Recarregue a biblioteca.');
        if(arguments.action EQ 'remove'){
          if(!position)throw(type='HelpdeskReplies.Validation',message='Escolha uma resposta para remover.');
          arrayDeleteAt(data.items,position);
        }else{
          if(!position AND arrayLen(data.items) GTE 100)throw(type='HelpdeskReplies.Validation',message='A biblioteca permite até 100 respostas rápidas.');
          var item={id=position?arguments.id:lCase(createUUID()),title=cleanTitle,text=cleanText,updatedBy=arguments.actorId,updatedAt=dateTimeFormat(now(),"yyyy-mm-dd'T'HH:nn:ss")};
          if(position)data.items[position]=item;else arrayAppend(data.items,item);
        }
        structDelete(data,'revision');data.version=1;write(data);result=read();
    }
    return result;
  }
  public struct function save(required string id,required string title,required string text,required string revision,required numeric actorId){return mutate('save',arguments.id,arguments.title,arguments.text,arguments.revision,arguments.actorId);}
  public struct function remove(required string id,required string revision,required numeric actorId){return mutate('remove',arguments.id,'','',arguments.revision,arguments.actorId);}
}
