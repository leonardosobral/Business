# SEO — fontes e revisões no cadastro — 04/10/2026

Publicada a aba administrativa **Fontes e revisões** em `/eventos/?id_evento=<id>&sessao=fontes`. O formulário conserva os filtros existentes, integra-se às abas e permite conferir separadamente datas inicial/final do evento, local (cidade/estado/país/endereço/coordenadas) e situação cadastrada. A confirmação de inscrições permanece em sua aba própria; revisão de datas do evento não aprova datas de cada percurso.

Cada conferência exige URL HTTP(S) válida e confirmação humana explícita de consulta à fonte. Guarda os valores vistos, URL e horário do servidor em timestamptz, apresentado em Brasília. Hash do snapshot com lock de evento rejeita formulário aberto antes de uma alteração; UUID impede duplicação do mesmo envio. O sistema não consulta a URL, não decide se a fonte está correta e não altera fatos. Retirar marca o registro sem apagar fonte/valores. Não há backfill nem identificação de operador/IP.

A tela mostra as dez conferências mais recentes e vinte alterações automáticas do histórico privado. Somente a última conferência de cada grupo conta; retirada não reativa as anteriores. Diferencia cadastro igual à conferência, cadastro alterado e conferência retirada. Igualdade não demonstra que a fonte externa continue atualizada. Textos/URLs escapados e fonte validada antes de formar link; null aparece como Não informado.

## Arquivos e contrato

Novos: `services/EventFactReviewService.cfc`, `eventos/includes/backend/fontes_revisoes.cfm`, `eventos/form_edicao_fontes.cfm`. Integrações mínimas em `eventos/form_edicao.cfm`, `eventos/includes/backend/backend_evento_edicao.cfm` e `eventos/includes/variaveis.cfm`. Serviço não remoto, administração efetiva interna, rejeição de delegação, POST e CSRF; ID do formulário deve coincidir com URL. SQL parametrizado, sem alterar permissões dos cadastros nem event_mutations.cfm.

Migração `_codex/sql/2026-10-04_evento_fatos_revisao.sql`: tabela privada `tb_evento_fatos_revisao`, identity, índices/constraints. Sem FK que apague recibos junto com cadastro e sem acesso direto do papel runner. Registros internos não são automaticamente promovidos ao site público. A ligação às fontes/histórico público existente é a próxima etapa; a revisão de percursos e demais divergências permanece pendente.

## Evidências

- 68 assertions (56 nomes distintos) do serviço e cinco casos de controller real passaram antes/depois: permissões, GET, CSRF, ID, URL inválida, no-op de envio repetido, token reaproveitado com payload/evento diferente, fonte retirada, formulário obsoleto e rollback.
- Render Adobe antes/depois com três estados de conferência, campos nulos, formulários e tentativa de HTML em valor renderizada como texto.
- Seis arquivos compilados; hashes publicados e seis dependências de autenticação/delegação/helper preservados. Revisão independente aprovada.
- Migração, inversão estrutural e falha forçada ensaiadas; hashes integrais dos eventos/percursos iguais antes/depois da instalação. Schema/owner/ACLs e triggers existentes conferidos em produção.
- Prévia em 1280×900 e 390×844 sem overflow; expansão/recolhimento por Enter. Sessão administrativa real confirmou link direto da aba no evento 37570 e troca Dados → Fontes e revisões. Não foi enviada uma conferência real só para testar. Fixtures usaram rollback/tabelas temporárias; sem registros de teste permanentes.

Artefatos: `_codex/staging/seo-fact-review-form-20261004/`. Backup schema: `/var/backups/seo-fact-review-form-db-20261004`. Backup runtime: `/var/backups/seo-fact-review-form-20261004/baseline`. Ordem: tabela privada, verificação, runtime, verificação funcional. Rollback via release.py rollback restaura os três arquivos existentes e retira os três novos, preservando tabela e recibos. Não remover a tabela para reverter a interface.

SH-02 continua parcial. Não houve alteração do runtime RoadRunners/OpenResults, resultados pessoais, políticas de robôs, cron pago, notas técnicas, Google ou comprovação de citações. O painel registra a entrega com sua data e mantém 24 itens, 18 concluídos e seis pendentes.

Painel publicado e verificado nas abas relatório/fila: um template compilado, um hash e cinco dependências preservadas. Backup `/var/backups/seo-fact-review-panel-20261004/baseline`.
