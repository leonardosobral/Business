<cfscript>
checks=0;
function check(required boolean yes,required string name){if(!yes)throw(type='Test.Failed',message=name);checks++;}
repo=new FakeRepository();
service=new services.VickyProactiveService({provider='meta_cloud'},repo);
result=service.run(2);
check(result.generated EQ 14 AND result.generatedBrasilGigante EQ 5,'Worker inclui geração Brasil Gigante sem remover geradores atuais');
check(result.completed EQ 1 AND find('**Mais uma etapa está chegando**',repo.savedContent()) EQ 1,'Webchat recebe mensagem formatada determinística');
request=service.whatsappTemplate({rule_code='brasil_gigante_d7',provider_template_name='atualize_cbg'},{event_name='Aracaju'});
check(request.name EQ 'atualize_cbg' AND request.language EQ 'pt_BR' AND arrayLen(request.components) EQ 0,'Modelo aprovado atualize_cbg não tem parâmetros dinâmicos');
request=service.whatsappTemplate({rule_code='agenda_d7',provider_template_name='outro'},{event_name='Aracaju'});
check(request.name EQ 'vicky_agenda_d7' AND request.components[1].parameters[1].text EQ 'Aracaju','Modelos existentes preservam parâmetro e nome efetivos');
legacyService=new services.VickyProactiveService({provider='manychat'},repo);
check(legacyService.whatsappProviderForJob({reference_type='brasil_gigante_event'}) EQ 'meta_cloud','Brasil Gigante usa Meta mesmo com provedor global legado ManyChat');
check(legacyService.whatsappProviderForJob({reference_type='event'}) EQ 'manychat','Demais regras preservam provedor global');
repo=new FakeRepository();repo.block();service=new services.VickyProactiveService({provider='meta_cloud'},repo);result=service.processOne();
check(result.status EQ 'suppressed' AND !len(repo.savedContent()) AND repo.suppression() EQ 'brasil_gigante_ineligible','Revalidação impede entrega depois de revogação/saída/desativação');
writeOutput('VICKY_CBG_SERVICE_PASSED ' & checks);
</cfscript>
