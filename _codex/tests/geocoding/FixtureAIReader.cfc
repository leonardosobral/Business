component output=false {
    variables.temporary=false;
    public void function setTemporary(required boolean value){variables.temporary=value;}
    public struct function read(required struct source,required numeric deadline){return {documents=[{url="https://race.com/fixture",sha256=repeatString("b",64),kind="html",text=source.nome_evento & " " & source.start_date & chr(10) & "Largada: Avenida Paulista, 1578, São Paulo/SP." & chr(10) & "Retirada de kits: Rua Flores, 123, Campinas/SP."}],diagnostics=variables.temporary ? ["source_http_503"] : [],temporary=variables.temporary};}
}
