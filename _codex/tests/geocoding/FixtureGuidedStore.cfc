// Only used by the loopback/nonced HTTP fixture. Never deployed as runtime.
component extends="services.geocoding.LocationStore" output=false {
    variables.fixtureId=2147001701;
    variables.fixtureFields=[{field="organizador",label="Organizador",status="needs_review",trusted=true,current="",value="Organizador fixture",evidence={},reasons=[]},{field="horarios_largada",label="Horários",status="needs_review",trusted=false,current="",value="07:00",evidence={},reasons=[]}];
    if(listFind("last,correct_last",URL.testcase ?: ""))variables.fixtureFields[1].status="rejected";
    public struct function detail(required numeric id){var source=snapshot(event(id));return id EQ variables.fixtureId ? {id=id,id_evento=variables.fixtureId,nome_evento="Fixture HTTP",cidade="São Paulo",estado="SP",status="needs_review",proposal_revision=3,source_snapshot=serializeJSON(source),source_hash=sourceHash(source),decision=serializeJSON({targets=[],enrichment={fields=variables.fixtureFields}})} : {};}
    public struct function event(required numeric id,boolean locked=false){return {exists=true,id_evento=id,nome_evento="Fixture HTTP",cidade="São Paulo",estado="SP",pais="BR",organizador="",coordenadas="",localizacoes="{}",_sourceNulls=[]};}
    public struct function reviewField(required numeric id,required numeric index,required string action,required string actor,required string revision){
        if(revision NEQ "3")throw(type="Geocoding.Validation",message="Esta proposta mudou desde que a tela foi aberta.");
        if(id NEQ variables.fixtureId OR !listFind("approve,reject",action) OR index LT 1 OR index GT 2)throw(type="Test.Failed",message="Incorrect guided dispatch arguments");
        variables.fixtureFields[index].status=action EQ "approve" ? "approved" : "rejected";return {id=id,status="needs_review"};
    }
    public struct function correctField(required numeric id,required numeric index,required any value,required string actor,required string revision){
        if(revision NEQ "3")throw(type="Geocoding.Validation",message="Esta proposta mudou desde que a tela foi aberta.");
        if(value EQ "Valor inválido preservado")throw(type="Geocoding.Validation",message="Valor inválido na fixture.");
        if(id NEQ variables.fixtureId OR revision NEQ "3" OR value NEQ "Valor corrigido pelo operador" OR !listFind("1,2",index))throw(type="Test.Failed",message="Incorrect manual correction dispatch arguments");
        variables.fixtureFields[index].status="corrected";return {id=id,status="needs_review"};
    }
}
