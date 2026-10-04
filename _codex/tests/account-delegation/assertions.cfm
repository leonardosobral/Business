<cfscript>
function assertEqual(required any actual, required any expected, required string label) {
    if (serializeJSON(arguments.actual)!=serializeJSON(arguments.expected))
        throw(type="DelegationAssertion",message=arguments.label,detail="Expected " & serializeJSON(arguments.expected) & ", got " & serializeJSON(arguments.actual));
}
function assertContains(required string text, required string fragment, required string label) {
    if (!find(arguments.fragment,arguments.text)) throw(type="DelegationAssertion",message=arguments.label);
}
function assertThrowsType(required any callback, required string type, required string label) {
    var caught=false;
    try { arguments.callback(); }
    catch (any error) {
        caught=true;
        if (compareNoCase(error.type,arguments.type)!=0) throw(type="DelegationAssertion",message=arguments.label,detail="Unexpected exception: " & error.type);
    }
    if (!caught) throw(type="DelegationAssertion",message=arguments.label,detail="Expected exception " & arguments.type);
}
</cfscript>
