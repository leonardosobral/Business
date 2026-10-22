component extends="FixtureAIReader" output=false {
    variables.calls=0;variables.emptyFirst=false;
    public void function failFirst(){variables.emptyFirst=true;}
    public void function throwOnRead(){variables.throwing=true;}
    public numeric function callCount(){return variables.calls;}
    public struct function read(required struct source,required numeric deadline){variables.calls++;if(variables.throwing ?: false)throw(type="Fixture.Unavailable",message="Synthetic exception");if(variables.emptyFirst AND variables.calls EQ 1)return {documents=[],diagnostics=["source_http_503"],temporary=true};return super.read(source,deadline);}
}
