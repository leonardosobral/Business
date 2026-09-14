# Traduções das descrições — publicação e validação

**Publicação e verificações encerradas em 14/09/2026 às 14:35:57 UTC.**
Os 13 arquivos de runtime tiveram seus hashes conferidos, a continuidade da fila
após rejeição foi observada e os diagnósticos foram retirados da área pública.
O job continua ativo processando a fila; este encerramento não significa que
todas as descrições já foram traduzidas ou que todas passaram pela validação.
O usuário autorizou gerar traduções EN/ES a partir da descrição PT publicada,
mantendo a fonte original, a descrição PT e as traduções humanas existentes.
Plano: [event-description-translations](../../docs/superpowers/plans/2026-09-14-event-description-translations.md).

## Situação após a correção

- Os seis arquivos de runtime do Business permanecem publicados.
- Os sete arquivos do site RoadRunners foram revertidos ao baseline após erro
  encontrado na navegação real e republicados corrigidos às **14:29:34 UTC**.
- O job 15 foi retomado com `ativo=true`, intervalo de **um minuto** e o mesmo
  corpo `{"limit":1,"dryRun":false}`. A execução de **11:31:09 BRT** publicou
  EN de 34737 com sucesso. Depois houve **`http_error` às 11:33:08 BRT** por
  rejeição factual HTTP 422 do ES de 34737. A execução seguinte registrada às
  **11:35:10 BRT** voltou a **`success`**, demonstrando continuidade; o snapshot
  de encerramento indica próxima execução às **11:36:10 BRT**.
- As páginas reais voltaram a retornar HTTP 200 após o rollback e, após a
  correção, quatro páginas públicas foram conferidas com HTTP 200 e o conteúdo
  efetivo. A URL exata que disparou o alerta também retornou 200.
- Traduções EN e ES do evento 46144 foram gravadas e exibidas. A rotina
  automática retomada publicou depois o EN de 34737. O ES de 34737 foi rejeitado
  sem sobrescrita e a página permanece com fallback explícito para PT.

## Linha do tempo do incidente

Horários de 14/09/2026, em UTC; horário de Brasília entre parênteses.

| Horário | Evidência / ação |
| --- | --- |
| 14:16 UTC (11:16 BRT) | Publicação inicial dos 13 arquivos: seis do Business e sete do site. |
| Entre publicação e rollback | A consulta da página real do evento falhou por escape de aspas ao interpolar SQL dinâmico em `CFQUERY` no Adobe ColdFusion. Compilação isolada e fixtures Lucee anteriores não exercitaram essa fronteira real. |
| 14:22 UTC (11:22 BRT) | Rollback dos sete arquivos do site; os seis arquivos do Business foram mantidos e o job continuou pausado. |
| Após rollback | Páginas reais verificadas com HTTP 200. Correção do site em curso. |
| Antes da republicação | O teste foi alterado para usar `CFQUERY` real; reproduziu a falha antes da correção e passou depois. A consulta completa `qEvento`, no Adobe e com o role existente `runnerhub`, passou em EN/ES/PT pelo diagnóstico protegido em loopback. |
| 14:29:34 UTC (11:29:34 BRT) | Republicação corrigida dos arquivos do site. O escape de aspas dos fragmentos SQL no ponto de interpolação `CFQUERY` foi corrigido. |
| Após republicação | Dry-run real EN retornou 200 sem gravações; EN/ES de 46144 publicados, reexecução EN selecionou zero, páginas e painel conferidos em navegador. |
| 14:31:09 UTC (11:31:09 BRT) | Primeira execução automática registrada após retomada: `success`; auditoria 3 publicou EN de 34737. |
| 14:32:30 UTC (11:32:30 BRT) | Painel em navegador indicava job ativo, 11.687 etapas pendentes e 269 para revisão. Snapshot anterior à rejeição abaixo; contagens são mutáveis. |
| 14:33:08 UTC (11:33:08 BRT) | Cron registrou `http_error` por HTTP 422; auditoria 4 rejeitou ES de 34737 por validação factual, sem gravar tradução. |
| Verificação final de runtime | Cópias privadas dos 13 arquivos reais de produção tiveram hashes conferidos; Adobe compilou `successful 13`, `total 13` em 2,95 segundos. GET 405 e POST sem assinatura 401 confirmados no endpoint. |
| 14:35:10 UTC (11:35:10 BRT) | Job 15 registrou `success` após a rejeição, continuando a fila; ativo, intervalo 1 e corpo preservados. Próxima execução calculada para 11:36:10 BRT. |
| 14:35:57 UTC (11:35:57 BRT) | Recibo `completion.json` encerrado com 13 hashes verificados. Diagnósticos movidos para `private-probe` no backup, modo 700; rota do harness externo retornou 404. |

## Escopo e estado dos dados

- Banco: adições compatíveis `descricao_en text`, `descricao_es text` e
  `descricao_traducoes_meta jsonb` em `public.tb_evento_corridas`, além da
  auditoria separada `public.tb_evento_descricao_translations`.
- Metadados por idioma: `source_hash = md5(descricao PT)` e
  `description_hash = md5(HTML publicado no idioma)`. Publicação condicional de
  texto, metadados e resultado da auditoria na mesma transação. O idioma não
  processado é preservado.
- Fonte da tradução: descrição PT publicada. `descricao_original` continua
  reservada ao texto importado; não é substituída pelas traduções.
- `vw_evento_corridas`, credenciais e permissões estão fora do escopo aprovado
  de alteração. O site deve funcionar com o acesso SELECT já existente sobre
  a tabela de eventos, sem consultar a auditoria administrativa.
- A gravação real confirmou as colunas de tradução/metadados e a auditoria.
  No piloto do evento **46144**, auditoria **1/en** e auditoria **2/es** têm
  status `updated`, antes NULL e `attempt_count=1`; os dois idiomas possuem
  os hashes de fonte e destino correspondentes na coluna JSONB.
- A comparação do piloto preservou exatamente descrição PT, descrição original
  e MD5 de todos os demais campos fora dos três campos novos. O evento controle
  **34737** estava inalterado no snapshot imediatamente após as duas gravações.
  Depois da retomada, a auditoria **3/en** registrou a tradução automática de
  34737, mantendo seus hashes de PT, original e demais campos estáveis.
- A auditoria **4/es** do mesmo evento tem status `rejected`, tentativa 1.
  Não gravou tradução: a versão portuguesa continua disponível no fallback ES.
- A definição de `vw_evento_corridas` foi comparada e permaneceu igual.
- Evidências locais: `/private/tmp/rr-translations-after-writes.json` e
  `/private/tmp/rr-translations-final.json`; snapshot da rejeição em
  `/private/tmp/rr-translations-completion.json`. Esses arquivos guardam snapshots,
  não devem ser publicados na área web.

## Runtime e recuperação

Raízes registradas no manifesto inicial:

- Business: `/var/www/business.roadrunners.run`.
- Site: `/var/www/roadrunners.com.br`.
- Backup privado: `/var/backups/event-translations-20260914.slzm0_91`.
- Staging inicial: `/tmp/rr-event-translations-20260914`.
- Manifesto local inicial: `/private/tmp/rr-translations-manifest.json`.
- Recibos remotos no backup: `site-rollback.json` e `published-corrected.json`.
- Conferência final no backup: `compile-final.log` e
  `hashes-final-verified.json`.
- Encerramento final no backup: `completion.json`, registrado às
  `2026-09-14T14:35:57Z`; guarda estado final do job e conferência de runtime.
- Diagnóstico recuperável: `private-probe/`, retirado integralmente da área
  pública e mantido com modo 700. O harness externo passou a responder 404.

O manifesto inicial relaciona os seis arquivos abaixo. A conferência final do
executor leu os 13 arquivos reais, validou seus hashes e compilou essas mesmas
cópias privadas. O recibo `hashes-final-verified.json` é a referência final,
inclusive para o backend do site corrigido após o primeiro manifesto.

| Business | SHA-256 do manifesto inicial |
| --- | --- |
| `services/EventDescriptionRewriteService.cfc` | `bee90db7d8cfe72657f7023b7fe04ef4acd35ea958aa233fe5d27c12c2468e21` |
| `api/eventos/jobs/rewrite-descriptions.cfm` | `cb6adff0daff8c2dcc3efa73183b7835687200502f02c4050e8a64942a434e77` |
| `api/eventos/jobs/queue.cfm` | `ea4928e4e3bbd5307fff9588aafa537693254a06545414a5997b8ddf258c54bf` |
| `administracao/cron-jobs/home.cfm` | `a1963c05865d6d3072003209c24239ec40863bd996781b883675a9e6fb444986` |
| `administracao/cron-jobs/descricoes.cfm` | `0c0719d054e1003e704601a8447587f9de42651f82c5990bc98be4db95cf6fd6` |
| `administracao/cron-jobs/includes/description_status.cfm` | `49151a1aa677a7d122f63c5e5358e7b048db645e3bf68e260af3cd13c5c3ef94` |

Arquivos do site incluídos no primeiro manifesto, revertidos e republicados:
`evento/index.cfm`, `evento/parts/descricao_localizada.cfm`, `i18n/en.cfm`,
`i18n/es.cfm`, `i18n/pt-BR.cfm`, `includes/backend/backend_evento.cfm` e
`services/EventDescriptionLocaleService.cfc`.

O backend corrigido `site/includes/backend/backend_evento.cfm` tem SHA-256
`4a7af9d57767e0efc33adfbe23fccca939dc006c53bb595e0b06e8914804adc4`,
conforme verificação comunicada pelo executor da republicação.

Compilação final: **13/13**, sem erros, em **2,95 segundos**; entradas foram
cópias dos arquivos efetivamente publicados com hashes conferidos. Preservar os
backups; qualquer nova restauração deve conferir hashes e preservar alterações
posteriores, inclusive as da frente SEO. Não executar remoções de colunas ou
tabelas como parte do rollback de runtime.

## Verificações concluídas antes deste registro

- Serviço real em CFML/Lucee: **155 assertions**, incluindo os 73 testes de
  reescrita anteriores e 82 de tradução. Comando:
  `node _codex/scripts/test_event_description_rewrite_cfml_local.mjs`.
  Abrange EN/ES, idioma inválido, números, horários, inversão de datas, moedas,
  unidades traduzidas sem conversão, nomes alterados reprovados pelo verificador,
  idioma errado, respostas incompletas/recusas e HTML escapado.
- Endpoint/fila: executor responsável comunicou **28 verificações de
  acesso/parâmetros, 10 fluxos PT e 16 fluxos de tradução**, mais testes SQL
  reais em PostgreSQL temporário. Abrange NULL, compare-and-set, edição humana,
  fonte nova, reutilização A→B→A, rollback, concorrência, dry-run, rejeição por
  idioma e retries de 5/30 minutos limitados a três falhas.
- Site: executor responsável comunicou **62 verificações**, incluindo leitor
  com SELECT somente na tabela de eventos, detecção de versão obsoleta,
  traduções humanas e fallback PT. A suíte foi corrigida para exercitar
  `CFQUERY`, reproduziu o erro de aspas antes do ajuste e passou depois.
- Adobe: diagnóstico protegido executou a consulta completa `qEvento` real
  com o role existente `runnerhub`, em EN/ES/PT; todos os indicadores de
  validação retornaram verdadeiros. Esse teste executa a fronteira que a
  compilação isolada não detectou.
- Adobe final: 13 arquivos reais copiados para staging privado, hashes
  conferidos e compilação `successful 13`, `total 13`, duração 2,95 segundos.
- Endpoint publicado: GET retornou **405** e POST sem assinatura retornou **401**.
- Revisão estática de endpoint, fila, schema e painel: sem bloqueadores
  encontrados em integridade/concorrência/autorização/contagens. O painel exige
  `qPerfil.is_admin` e compartilha a definição da fila com o executor.
- Auditoria posterior ao incidente: as consultas novas do Business usam
  `queryExecute(sql, params, options)`. `eventDescriptionQueueSql()` é passado
  diretamente a `queryExecute` no endpoint e nas contagens; não há interpolação
  dos fragmentos SQL em `CFQUERY` nesses dois consumidores. O único trecho novo
  em `administracao/cron-jobs/home.cfm` é o link para o painel.
- `git diff --check` passou na conclusão do serviço.
- IA/produção: dry-run real EN retornou HTTP 200 com prévia e sem escrita de
  evento ou auditoria. A execução real gravou EN e ES do evento 46144;
  reexecução EN com `dryRun=false` selecionou zero.
- Navegação real: quatro páginas públicas retornaram 200 com descrição
  correspondente; URL exata do alerta também retornou 200. EN foi conferido
  em desktop e viewport mobile de 390 px; ES, em mobile, incluindo o DOM.
- Painel: desktop/mobile conferidos com acesso autenticado. A tentativa pública
  sem autenticação redirecionou com HTTP 302, sem expor as contagens.
- Fallback real: a página ES de 34737 retornou 200, mostrou
  `Descripción original en portugués.` e o corpo com `lang="pt-BR"`; HTML
  guardado localmente em `/private/tmp/rr-muchacho-es-final.html`.
- Agendamento: job 15 ativo, intervalo um minuto, corpo preservado. Houve
  `success` às 11:31:09 BRT (auditoria 3/en de 34737) e depois `http_error`
  às 11:33:08 BRT por rejeição factual 422 (auditoria 4/es), sem sobrescrita.
  Em seguida, `success` às **11:35:10 BRT** confirmou que a rejeição não bloqueou
  a fila. `completion.json` registra o job ativo, intervalo 1, corpo idêntico
  e próxima execução às 11:36:10 BRT. Isso não significa aprovação de todas as
  traduções; o ES rejeitado continua preservando o fallback PT.
- Limpeza: o diagnóstico completo foi movido para `private-probe/` no backup
  privado, com modo 700, sem rota pública remanescente; harness externo 404.

## Ajuste da abordagem de diagnóstico

O revisor automático rejeitou o envio inicial de um helper de diagnóstico.
O executor apresentou evidência da restrição ao loopback e reduziu a consulta
a somente leitura dos dois eventos envolvidos, 46144 e 34737. A abordagem
restrita foi então executada sem contornar as proteções. Não houve mudança de
credenciais ou permissões para obter essa evidência.

## Verificações de encerramento

- [x] Corrigir e testar a interpolação SQL do site no Adobe ColdFusion real.
- [x] Compilar todos os arquivos finais e registrar o log e os hashes exatos.
- [x] Republicar somente o escopo necessário após conferir baseline/backup.
- [x] Confirmar GET 405 e POST sem assinatura 401 no endpoint publicado.
- [x] Rodar dry-run real sem alteração de evento/auditoria.
- [x] Publicar EN e ES de um evento e conferir fonte PT/original intactas,
      exclusividade dos campos alterados, auditoria e metadados por idioma.
- [x] Reexecutar e confirmar ausência de chamada desnecessária à IA.
- [x] Conferir páginas reais PT/EN/ES, conteúdo efetivo e fallback, em desktop e
      mobile; HTTP 200 sozinho não basta.
- [x] Conferir acesso autorizado ao painel e contagens reais.
- [x] Restaurar o job 15 com corpo e agenda aprovados e verificar uma execução
      automática; registrar último status e horário.
- [x] Confirmar no histórico que a fila continua após a rejeição factual mais
      recente, preservando o idioma rejeitado e processando outra etapa elegível.
- [x] Encerrar rotas temporárias de diagnóstico e registrar recibo final.

## Limites operacionais

O verificador local e a segunda chamada à IA reduzem o risco de alteração de
fatos, mas não provam equivalência semântica absoluta. A fonte normalizada acima
de 20 mil caracteres é rejeitada inteira. Cada tradução usa no máximo duas
chamadas de até 45 segundos. Uma rejeição factual encerra automaticamente aquela
versão/idioma; falhas do provedor possuem retry limitado. Traduções humanas não
reconhecidas como saída do cron são preservadas.

O intervalo configurado é um minuto **após o término da execução**: o executor
central calcula `next_run_at = now() + interval_minutes` no fechamento do job,
em `includes/backend/cron_jobs_service.cfm:733`. Como a consulta de jobs ocorre
em ticks de minuto, a cadência observada foi de aproximadamente **dois minutos**,
com execuções registradas às 11:31, 11:33 e 11:35 BRT. O scheduler central não
foi alterado nesta tarefa. Não interpretar a configuração como garantia de uma
tradução nova a cada minuto de relógio.

O painel às 11:32:30 BRT mostrava **11.687 etapas pendentes e 269 para revisão**;
essa fotografia precede a rejeição ES e muda com o processamento. A fila não
estava concluída no encerramento. Publicação, recuperação do incidente,
validação funcional, retomada, continuidade e limpeza foram verificadas.
