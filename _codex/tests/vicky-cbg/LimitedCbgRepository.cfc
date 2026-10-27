component extends="__CBG_COMPONENT__" {
 variables.testUser=0;
 public void function limitUser(required numeric id){variables.testUser=arguments.id;}
 public string function candidatesSql(){return replace(super.candidatesSql(),'e.id_evento,e.nome_evento','(e.id_evento+1000000000) AS id_evento,e.nome_evento','one') & ' AND u.id=' & int(variables.testUser);}
}
