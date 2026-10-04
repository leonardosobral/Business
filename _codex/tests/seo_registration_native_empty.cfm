<!--- Run in an isolated Adobe application with /services mapped to the task candidate. --->
<cfscript>
policy = new services.EventRegistrationAvailability();
for (metadata in ["null", "", "[]", "false", "invalid-json"]) {
    state = policy.evaluate(metadata, "https://inscricao.example/prova", "", createDate(2099,10,10));
    if (state.confirmed OR len(state.availability)) throw(message="Invalid metadata asserted availability");
}
writeOutput("Native Adobe: 5 empty/null/invalid metadata cases passed.");
</cfscript>
