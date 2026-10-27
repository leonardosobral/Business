<cfscript>
checks=0;function check(required boolean ok,required string label){if(!ok)throw(type='Teams.Test',message=label);checks++;}
check(fileExists(expandPath('services/teams/Identity.cfc')),'Boundary de identidade verificada ausente');
identity=new services.teams.Identity();store={};protocol=createObject('component','__PROTOCOL__').init(store);accounts=createObject('component','__FAKE_ACCOUNTS__');
check(structIsEmpty(identity.browser(protocol,accounts,{id=142})),'Cookie de ID não autentica');
check(structIsEmpty(identity.browser(protocol,accounts,{'__Host-rr-comparador-identity'='fake'})),'Prova inventada não autentica');
binding=protocol.randomToken();proof={id=142,version='v1',sessionId=protocol.randomToken(),browserBinding=protocol.digest(binding)};protocol.rememberBrowser(binding,proof,dateAdd('h',1,now()));
check(identity.browser(protocol,accounts,{'__Host-rr-comparador-identity'=binding}).id==142,'Prova válida autentica conta corrente');
proof.version='old';otherBinding=protocol.randomToken();proof.browserBinding=protocol.digest(otherBinding);protocol.rememberBrowser(otherBinding,proof,dateAdd('h',1,now()));
check(structIsEmpty(identity.browser(protocol,accounts,{'__Host-rr-comparador-identity'=otherBinding})),'Versão de conta obsoleta não autentica');
protocol.revokeBrowser(binding);check(structIsEmpty(identity.browser(protocol,accounts,{'__Host-rr-comparador-identity'=binding})),'Prova revogada não autentica');
check(identity.returnPath('//evil.example')=='/teams/meu-team/','Retorno externo rejeitado');check(identity.returnPath('/teams/includes/start.cfm')=='/teams/meu-team/','Retorno para include rejeitado');check(identity.returnPath('/teams/?team=abc-1')=='/teams/?team=abc-1','Retorno ao Team preservado');
writeOutput('TEAMS_IDENTITY_PASSED ' & checks);
</cfscript>
