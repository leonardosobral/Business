component extends="__CLOSE_COMPONENT__" {
 variables.fixtureId=0;
 public void function limitTicket(required numeric id){variables.fixtureId=arguments.id;}
 public string function candidatesSql(boolean locking=false){return replace(super.candidatesSql(arguments.locking),'WHERE cham.status','WHERE cham.id_chamado=' & int(variables.fixtureId) & ' AND cham.status','one');}
}
