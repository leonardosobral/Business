# Circuitos separados dos grupos de edições

Migração aplicada e runtime publicado em 28/09/2026, após autorização do usuário.

## Modelo e dados

- `tb_agregadores`, com `agregador_tipo='circuito'`, representa o circuito.
- `tb_agregadores_eventos` guarda as associações do circuito com eventos. Um evento pode ter múltiplos agregadores gerais e, simultaneamente, um grupo de edições.
- `tb_agrega_eventos` / `tb_evento_corridas.id_agrega_evento` ficam reservados aos grupos de edições. O banco bloqueia atribuição de um circuito legado nesse campo.
- Migrados os **39** registros classificados como circuito; **36** agregadores gerais criados e **três reutilizados**: Brasil Gigante e os dois FCA. Reutilização mantém IDs, tags, associações, descrição e ordem existentes; o tipo passa a circuito e o tema vem do circuito original.
- Preservadas as **1.387 associações** originais; seus campos de edição foram liberados. Existem agora **1.464 associações** nos 39 circuitos, incluindo as que os agregadores reutilizados já possuíam. Os outros vínculos entre edições foram preservados.
- O campo novo `tb_agregadores.id_agrega_evento_legado` é único e referencia o cadastro anterior para compatibilidade de URLs e cupons. Os 39 registros antigos permanecem como referências legadas, fora dos seletores de edições; não foram apagados.
- O mapeamento explícito está em `circuitos_2026_09_28/mapeamento.json`. Não se unificaram circuitos de nomes apenas semelhantes. Tags antigas continuam válidas, inclusive os dois circuitos FCA com tags distintas do catálogo geral.

## Consumidores

**Business:** configurações do evento distinguem “Edições da mesma prova” de “Agregadores e circuitos”. Seletores, criação/aplicação na revisão e manutenção manual impedem tratar circuito como grupo de edições. O histórico de revisões aplicadas a circuitos migrados não impede uma nova sugestão de edições; os registros históricos continuam preservados. Revisões ignoradas e revisões pendentes continuam protegidas.

**RoadRunners:** `/circuito/{tag}/` consulta o catálogo geral e suas associações, preservando as URLs e temas. Usa `EXISTS` para evitar repetir eventos por duplicidades na tabela de associação. O ID legado é mantido no contexto de audiência dos circuitos migrados.

**Cupons / OpenResults:** `vw_evento_corridas_cupom` resolve cupons dos circuitos migrados em linhas por evento (`tipo_evento=1`), mantendo o contrato dos consumidores. Os grupos não migrados continuam com o comportamento anterior. `vw_cupom` também usa a associação nova para os circuitos migrados. A tabela histórica de cupons permanece intacta. Cupom Live! 68 continua associado a 187 eventos; não foi necessário editar o runtime do OpenResults.

## Sugestões e os 63 pares do estudo

Geração de 2025–2026 analisou 19.532 eventos e criou **160 sugestões** (134 + 26 após considerar o histórico de circuitos). Nenhum vínculo de edição foi aplicado. Repetição criou zero sugestões, com hashes de vínculos e do histórico aplicado/ignorado inalterados.

Dos 63 pares identificados pelo nome na prévia v3:

- **62** têm agora uma revisão pendente do par 2025–2026.
- **Um**, Meia Maratona de Joinville (26558 → 35612), tem a edição de 2025 na revisão pendente **4891**, junto da edição de 2024 (10762). O gerador não duplica um evento em duas revisões pendentes. A revisão existente foi preservada: https://business.roadrunners.run/administracao/agrega-revisao/?grupo=4891
- Quinze pares já apareciam em revisões históricas aplicadas ao circuito. A nova consulta permite sugerir as edições sem apagar ou reabrir esses históricos. A explicação anterior de exclusão referia-se ao gerador por edições; não comprovava ausência em toda a história da ferramenta.

## Execução e verificações

1. Inventário e backup; ensaio das duas fases em transação com rollback.
2. `_codex/sql/2026-09-28_circuitos_preparar.sql`: fase aditiva, cria/reutiliza o catálogo e copia associações.
3. Publicação de sete templates Business e um RoadRunners, compilados com sucesso e hashes verificados.
4. `_codex/sql/2026-09-28_circuitos_ativar.sql`: adapta as views, libera o campo de edição e instala a proteção, numa transação. Asserções abortam a migração se alguma edição não relacionada ou cobertura de cupom se perder.
5. Ajuste final de um template Business para o histórico de circuitos; compilação e publicação conferidas.
6. 24 testes existentes do normalizador/pareamento passaram. Teste de atribuição indevida de circuito foi bloqueado pelo trigger, em transação com rollback. Geração repetida não duplicou grupos.
7. Conferência direta de 1.387/1.387 associações; zero eventos referenciando circuitos no campo de edição. Conferência individual dos 63 pares.
8. Chrome autenticado: revisão mostra novas sugestões; evento 26957 mostra “Sem grupo de edições” e “Circuito das Estações” em campos separados. Desktop e mobile 390 px conferidos, sem rolagem horizontal. Página Live! mantém 14 próximos + 173 realizados e cupom de 15%.

Consultas foram executadas por operador temporário ColdFusion restrito a loopback e chave aleatória, removido ao terminar. O envio pelo diálogo de confirmação do Chrome não concluiu; a geração foi executada pelo mesmo código publicado, no operador privado, com o administrador identificado de forma única. A primeira tentativa do operador foi revertida por inicialização incompleta, corrigida antes da geração efetiva.

Evidências e manifesto de arquivos em `circuitos_2026_09_28/`. Backups privados do banco (antes de cada fase) e SQLs aplicados em `/var/backups/circuitos-20260928/database/`; backups do runtime em `runtime-v2/` e `runtime-v3/` dentro do mesmo diretório. As credenciais de datasource não foram extraídas.

## Recuperação

Não executar recuperação automaticamente após novas aceitações de edições. Conferir alterações concorrentes primeiro.

Para reverter a ativação, numa transação com bloqueio dos registros afetados: remover o trigger `circuito_fora_do_vinculo_edicao`; restaurar somente os `id_agrega_evento` que eram circuitos no backup `ativar-before.json`, exigindo que continuem nulos ou iguais ao valor de origem; restaurar as definições de `vw_cupom` e `vw_evento_corridas_cupom` do mesmo backup. Abortar se um evento já recebeu um novo vínculo de edição. Não sobrescrever outras edições. O catálogo geral e as associações adicionadas podem permanecer, pois são aditivos; as páginas novas continuam lendo esse catálogo. Se for necessário reverter runtime, usar os manifests/backups correspondentes e conferir os hashes atuais antes de substituir arquivos.

A prévia v3 do estudo continua congelada no estado da coleta anterior (20:28 BRT); esta migração não altera resultados esportivos, snapshots do schema `estudo` ou os arquivos v1/v2/v3.
