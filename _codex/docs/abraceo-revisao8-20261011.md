# ABRACEO — revisão dos oito casos e consolidação dos 96 filiados

Operação autorizada pelo usuário em 11/10/2026: rever os oito casos, criar pré-cadastros e vouchers dos organizadores confirmados e manter dúvidas separadas. Fontes públicas confirmam contato publicado, não entrega do e-mail nem poderes de representação.

## Resultado em produção

Sete contas PJ novas, com documento NULL, documento_pendente=true e status PENDENTE: Amigos do Horto 111, CronusTec 112, MMB Eventos Esportivos 113, NK Sports 114, Premium 115, Soul+ 116 e TM4 117. Perfis ABRACEO, referências pesquisadas, logos e elegibilidade de primeiro acesso adicionados. Não foram criados membros, declarações de representante ou acessos operacionais. Total: 95 perfis ABRACEO e 95 contas elegíveis, em uma lista de 96 filiados.

Sete vouchers nominais emitidos pelo serviço publicado FirstAccess, para o produto previa-2026-q3, benefício comercial zero, prazo até 10/11/2026 às 23h59 de Brasília. Hash, destinatário, conta, status READY e prazo conferidos. Os 88 vouchers anteriores e estados de envio na planilha foram preservados. Nenhum convite foi enviado ou resgatado pela operação.

Dois vínculos adicionados: conta111 → evento47688, Kids Trimais Places em 12/10/2026; conta115 → evento45413, Meia Maratona dos Reis Magos em 18/10/2026. Datas futuras, atividade e ausência de associação anterior conferidas antes da gravação.

## Evidências e limites

- Amigos do Horto: dados públicos SportsEvent na página Ticket Sports da edição88357 nomeiam a organizadora; regulamento da Corrida de Escada72515 também a identifica expressamente.
- CronusTec: https://www.cronusteccorridas.com.br/nossos-servicos declara organização, realização e assessoria de corridas. Não se atribuem à empresa todos os eventos apenas cronometrados.
- MMB: https://www.ticketsports.com.br/e/maratona-monumental-de-brasilia-2026-74828 identifica MMB como organizadora. Cadastro da marca confirmado; vínculo do evento39395 separado, pois o regulamento atribui organização ao Instituto Meninos do Pôr do Sol e realização à MMB.
- NK Sports: dados públicos SportsEvent de https://www.ticketsports.com.br/e/2-corrida-santa-casa-araraquara-2026-85837 nomeiam NK SPORTS como organizador. Para convite, preservado contato nominal da ABRACEO, não o contato da cronometragem.
- Premium: https://meiamaratonadosreismagos.com.br/regulamento/ confirma organização Premium Comunicação e Marketing Ltda e data18/10/2026. Roberta selecionada por ser a responsável nominal ABRACEO; Bruno preservado no contato adicional do perfil.
- Soul+: comunicado oficial https://www.assai.com.br/imprensa/corrida-assai-em-fortaleza-dobra-de-tamanho-e-abre-novo-lote-de-inscricoes confirma organização em2025; regulamentos de Teresina e Vitória2026 confirmam realização e domínio de contato. Eventos48766 e48783 permanecem separados porque o catálogo identifica Instituto Novos Talentos como organizador.
- TM4: https://www.tm4.business/ confirma organização de eventos e coincide com marca, cidade, domínio e telefone ABRACEO. Nome do representante permanece a confirmar: não se presume equivalência entre Thiago de Oliveira e Thiago Mansur.
- MP3: atuação confirmada por documento CBAt para21k Salvador2025. Mesmo contato público da conta5 MP3 Marketing, porém conta existente usa CNPJ28434613000156 e candidato pesquisado para MP3 Soluções é11194903000177. Não foi criada conta duplicada, fundida PJ, alterada conta5 ou emitido voucher. Confirmar com o responsável qual PJ/conta representa o filiado.

Os sete CNPJs pesquisados permanecem apenas referências no perfil. A marca organizadora confirmada não comprova automaticamente o titular jurídico atual.

## Correção necessária no primeiro acesso

ColdFusion isValid("email") rejeitou o domínio .business da TM4. A primeira emissão em lote falhou; auditoria confirmou rollback integral, os mesmos88 vouchers e ausência de códigos recuperáveis antes da nova tentativa.

Novo services/EmailAddress.cfc preserva endereços aceitos pelo validador existente e acrescenta validação ASCII de dot-atom/DNS para TLDs alfabéticos de7–63 caracteres, com limites de tamanho e rejeição de controles, espaços, local-part com pontos inválidos e labels malformados. Usado por StudyAccess, GoogleIdentityVerifier, BusinessAuthSession e BusinessRememberDevice. Assinatura RS256, emissor, audience, nonce, email_verified, vinculação do usuário, permissões e critérios de sessão/dispositivo preservados.

Cinco componentes compilados no ColdFusion2025. O teste business_email_long_tld.cfscript passou em36 verificações no candidato e no runtime publicado: endereços válidos/inválidos, identidade assinada com domínio longo, rejeição de assinatura/claims inválidos, sessão e emissão real em transação revertida. Não foi realizado login real como destinatário. A emissão final dos sete vouchers passou pelo serviço real publicado. Página pública retornou200 e lookup anônimo401; sete logos conferidos por HTTP e SHA256.

## Entregas e recuperação

outputs/abraceo-revisao8-20261011/vouchers_abraceo.xlsx contém95 convites, pendências separadas e aba Empresas com96 filiados. Exportação reimportada e comparada com vouchers de produção; códigos únicos, destinatários corretos e88 linhas anteriores preservadas. empresas_96.csv mantém os campos completos e referências, sem códigos. Texto de convite preservado em convite_abraceo.txt.

Backups privados:
- /var/backups/business-abraceo-revisao8-20261011: estado completo anterior de contas, perfis, vínculos e elegibilidade, logos candidatos, dryrun revertido e resultado da gravação.
- /var/backups/business-email-long-tld-20261011: baseline recuperável dos quatro arquivos anteriores, novo componente, compilação e testes antes/depois da publicação.
- /var/backups/business-abraceo-vouchers-revisao8-20261011: tentativa revertida e prova de rollback; não reexecutar.
- /var/backups/business-abraceo-vouchers-revisao8-retry-20261011:88 vouchers anteriores, sete códigos privados, emissão e conferência.

Não reemitir vouchers a partir dos scripts. Recuperar os códigos privados já emitidos quando necessário. Revogação deve usar a gestão existente, preservando histórico. Antes de reverter contas/perfis/vínculos, verificar uso posterior e relacionamentos; não remover contas com resgates ou declarações. Nenhuma credencial, permissão de banco, migração, commit, push ou PR alterado/criado.
