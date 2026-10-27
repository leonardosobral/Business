<cfscript>
checks=0;function check(required boolean ok,required string name){if(!ok)throw(message=name);checks++;}
path=getDirectoryFromPath(getCurrentTemplatePath())&'replies-test.json';s=new __REPLIES__(path);a=s.list();check(arrayLen(a.items) EQ 3,'Padrões iniciais preservados');
b=s.save('', 'Teste & <script>', 'Linha 1'&chr(10)&'Linha 2 </textarea>',a.revision,17);check(arrayLen(b.items) EQ 4,'Criar disponível para todos');
id=b.items[4].id;c=s.save(id,'Editado','Texto editado',b.revision,17);check(c.items[4].text EQ 'Texto editado','Editar persistente');
failed=false;try{s.remove(id,b.revision,17);}catch(HelpdeskReplies.Conflict e){failed=true;}check(failed,'Revisão antiga não remove alteração alheia');
d=s.remove(id,c.revision,17);check(arrayLen(d.items) EQ 3,'Remover modelo');
failed=false;try{s.save('','Título',repeatString('x',12001),d.revision,17);}catch(HelpdeskReplies.Validation e){failed=true;}check(failed,'Limite aplicado no servidor');
for(item in duplicate(d.items))d=s.remove(item.id,d.revision,17);check(!arrayLen(new __REPLIES__(path).list().items),'Biblioteca vazia persiste sem restaurar padrões');
writeOutput('HELPDESK_TOOLS_REPLIES_PASSED '&checks);
</cfscript>
