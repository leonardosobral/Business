component extends="FixtureAI" output=false {
    public struct function extract(required struct context,required array documents){var result=super.extract(context,documents);result.facts.attributes=[{field="organizador",value="Associação Flores",quote="Organizador: Associação Flores.",document_index=1,certainty="confirmed"},{field="horarios_largada",value="5 km às 07:00",quote="Horários de largada: 5 km às 07:00.",document_index=1,certainty="confirmed"}];return result;}
}
