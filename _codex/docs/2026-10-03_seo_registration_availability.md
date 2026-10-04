# Confirmação de inscrições para o SEO de eventos

Implementado e publicado em 03/10/2026 no Business e no Road Runners.

## Comportamento

No Business, administradores encontram **Eventos → editar evento → Inscrições**. A aba aceita inscrições abertas, vagas esgotadas, pré-venda já disponível, inscrições encerradas ou disponibilidade não confirmada. Uma confirmação exige URL da fonte oficial e a declaração de que o status foi verificado agora. Salvar “Não confirmadas” limpa o registro. Edições comuns não renovam sua validade.

O Road Runners mostra status, fonte e data da verificação em português, inglês e espanhol. O JSON-LD de `SportsEvent.offers` usa `InStock`, `SoldOut` ou `PreOrder` apenas para confirmações válidas. “Encerradas” não significa “esgotadas” e não gera `SoldOut`. Para esgotadas/encerradas, a ação de inscrição leva à fonte com o status correspondente. Open Results não foi alterado.

A confirmação vale por menos de 86.400 segundos e exige o mesmo link de inscrição. Eventos passados/cancelados, dados inválidos, data de confirmação futura e confirmações vencidas não afirmam disponibilidade. Alterar o link em Dados limpa o registro no mesmo UPDATE; voltar ao link anterior não recupera a confirmação.

O alerta não crítico do Search Console pode permanecer em páginas sem confirmação. Esta etapa cria o mecanismo de confirmação; não presume disponibilidade em todo o catálogo nem inicia coleta automática das plataformas de inscrição.

## Contrato e arquivos

A migração `../sql/2026-10-03_event_registration_availability.sql` acrescenta `public.tb_evento_corridas.inscricao_disponibilidade`, JSONB anulável, sem preencher eventos existentes. Objeto versão 1:

```json
{"version":1,"status":"open","source_url":"https://organizador.example/prova","registration_url":"https://inscricao.example/prova","checked_at":1791030000}
```

`checked_at` é um segundo Unix UTC calculado pelo servidor na confirmação. Os status permitidos são `open`, `sold_out`, `preorder`, `closed`; ausência equivale a não confirmado. O Business escreve dados e auditoria em uma transação, com `SELECT FOR UPDATE`, autorização administrativa efetiva, POST e CSRF. URLs exigem HTTP(S), host válido, ausência de credenciais e limite de 2.048 caracteres; nenhum URL é buscado pelo serviço.

Business: `services/EventRegistrationAvailabilityService.cfc` grava o contrato; `services/EventRegistrationAvailability.cfc` avalia a confirmação; `eventos/includes/backend/inscricao_disponibilidade.cfm` protege/processa o formulário; `eventos/form_edicao_inscricoes.cfm` apresenta a aba. Integrações estreitas em `eventos/form_edicao.cfm`, `eventos/includes/variaveis.cfm` e `eventos/includes/backend/backend_evento_edicao.cfm`.

Road Runners: `services/EventRegistrationAvailability.cfc` valida o mesmo contrato; `includes/backend/backend_evento.cfm` lê o campo com `to_jsonb(evt)->>'inscricao_disponibilidade'`; `evento/index.cfm` consome a política no JSON-LD e na ação de inscrição; `evento/parts/inscricao_disponibilidade.cfm` apresenta a confirmação. As cópias da política têm o mesmo hash; uma mudança futura no contrato deve atualizar e testar os dois consumidores.

## Verificação e publicação

- 15 casos de JSON-LD executam o bloco real do template de evento.
- 12 submissões exercitam status válidos e rejeição por confirmação ausente, URL insegura, status inválido, admin/POST/CSRF inválidos.
- 16 verificações CFML/PostgreSQL exercitam o serviço real, migração idempotente, isolamento do outro evento, auditoria, rollback e o UPDATE real de edição do link.
- Onze arquivos de runtime compilaram no Adobe ColdFusion; quatro arquivos foram novamente compilados após corrigir JSON `null`.
- Adobe real: CSRF válido/inválido, formulário com confirmação e sem dados, texto público pt/en/es, cinco casos de metadata vazia/inválida.
- Eventos públicos: futuro pt/en/es e passado pt responderam HTTP 200 com SportsEvent e URL de Offer, sem disponibilidade inventada. URLs e hashes estão no comprovante JSON.
- Prévia do formulário real renderizado no Adobe, com evento fictício e sem gravação: desktop 1280 e celular 390, sem rolagem horizontal; seleção de status altera corretamente a obrigatoriedade de fonte/checkbox. Não foi possível testar a sessão autenticada do usuário no navegador, que abriu sem login.
- A migração verificou a integridade de 34.381 eventos na transação; o fingerprint anterior/posterior permaneceu igual e todos ficaram sem confirmação.

A primeira conferência pública encontrou um erro específico do Adobe: `deserializeJSON("null")` remove a variável local quando o suporte a null está desativado. O teste nativo reproduziu `Variable DATA is undefined`. A política e a view agora verificam `isNull` antes de acessar a variável; a consulta RR usa `->>` para converter JSON null em SQL NULL. O teste nativo e os quatro GETs públicos passaram depois da correção. A regressão nativa está em `../tests/seo_registration_native_empty.cfm`.

A publicação conferiu baseline, fez backups e substituiu somente o escopo. O template RR local já continha diferenças de organizador/header ausentes em produção: foram preservadas localmente e mantidas fora do candidato publicado. Não houve alteração de autenticação, menus, campanhas ou outros arquivos protegidos; nenhum commit/branch/push foi criado.

Comprovantes: `2026-10-03_seo_registration_availability_release.json`. Prévia visual: `../../output/seo-registration-availability/preview-desktop.jpg` e `preview-mobile.jpg`.

## Recuperação

Backups anteriores à funcionalidade: `/var/backups/seo-availability-business-uos190l0` e `/var/backups/seo-availability-rr-vxzihrkf`, com manifestos e arquivos existentes. Backups imediatamente anteriores à correção de null: `/var/backups/seo-availability-business-bdap1gtn` e `/var/backups/seo-availability-rr-h7o9dxjl`.

Para reverter a funcionalidade, restaurar arquivos existentes a partir dos primeiros backups e retirar apenas os novos arquivos cujo hash ainda corresponda ao comprovante, preservando mudanças posteriores. Manter o campo JSONB: isso preserva confirmações feitas depois do deploy e é compatível com o runtime antigo. Não restaurar apenas a versão anterior da política sem a correção de null. Antes de recuperar, comparar produção, hashes e manifestos e verificar o comportamento HTTP após a restauração.
