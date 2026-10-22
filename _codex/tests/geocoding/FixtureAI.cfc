component output=false {
    variables.calls=0;
    public numeric function callCount(){return variables.calls;}
    public struct function extract(required struct context,required array documents){variables.calls++;return {ok=true,code="ok",model="fixture",facts={event_name=context.nome_evento,event_date=context.start_date,identity_document=1,identity_quote=context.nome_evento & " " & context.start_date,locations=[{role="evento",name="",address="Avenida Paulista, 1578",city="São Paulo",state="SP",country="BR",quote="Largada: Avenida Paulista, 1578, São Paulo/SP.",document_index=1,certainty="confirmed"},{role="kit",name="",address="Rua Flores, 123",city="Campinas",state="SP",country="BR",quote="Retirada de kits: Rua Flores, 123, Campinas/SP.",document_index=1,certainty="confirmed"}]}};}
}
