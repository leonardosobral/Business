<cfscript>
checks=0;function check(required boolean ok,required string label){if(!ok)throw(type='Teams.Test',message=label);checks++;}
service=new services.teams.Service();boundary=new services.teams.Boundary();
check(service.validDocument('529.982.247-25'),'CPF válido');check(!service.validDocument('11111111111'),'CPF repetido rejeitado');check(!service.validDocument('52998224726'),'CPF com dígito inválido');
check(service.validDocument('11.222.333/0001-81'),'CNPJ válido');check(!service.validDocument('11222333000182'),'CNPJ inválido');
check(!boundary.valid({}, {csrf='fake'},142),'Sem sessão não aceita CSRF');
state={};token=boundary.token(state,142);check(len(token)==64,'Token forte');check(boundary.valid(state,{csrf=token},142),'CSRF correto aceita');check(!boundary.valid(state,{csrf=token},143),'Token vinculado ao ator');check(!boundary.valid(state,{csrf='fake'},142),'CSRF incorreto rejeitado');check(!boundary.valid(state,{csrf=[]},142),'CSRF complexo rejeitado');
check(boundary.token(state,142)==token,'Token estável na sessão');check(boundary.token(state,143)!=token,'Mudança de ator troca token');
blocked=false;try{boundary.number({team='1 OR 1=1'},'team');}catch(Teams.Validation e){blocked=true;}check(blocked,'Identificador injetado rejeitado');
blocked=false;try{boundary.text({operation=[]},'operation');}catch(Teams.Validation e){blocked=true;}check(blocked,'Parâmetro não escalar rejeitado');
writeOutput('TEAMS_SECURITY_PASSED ' & checks);
</cfscript>
