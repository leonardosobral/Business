component extends="FixtureAIReader" output=false {
    public struct function read(required struct source,required numeric deadline){var result=super.read(source,deadline);result.documents[1].text &= chr(10) & "Organizador: Associação Flores. Horários de largada: 5 km às 07:00.";return result;}
}
