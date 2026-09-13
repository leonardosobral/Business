# Reescrita de descrições — publicação no Business

Publicação e verificação concluídas em 13/09/2026. O usuário confirmou IA direta
no Business, substituindo o n8n neste processamento.

## Operação

- Job **15 — Business - Reescrita de descricoes de eventos**, ativo a cada cinco
  minutos, um evento por execução, timeout 120 segundos, sem retry automático.
- Endpoint: `POST https://business.roadrunners.run/api/event-description-rewrite.cfm`.
- Corpo ativo: `{"limit":1,"dryRun":false}`. Autenticação HMAC com a referência
  existente `business_internal`; modelo `gpt-4.1-mini` e chave já configurada.
- Somente `descricao` vazia é preenchida. `descricao_original`, categorias e
  todos os demais campos permanecem preservados pela implementação.
- Auditoria: `public.tb_evento_descricao_rewrites`, criada de forma aditiva com
  o datasource existente. Nenhuma credencial ou permissão foi alterada.
- Referência operacional: [README](../../api/eventos/jobs/README.md).

## Publicação e recuperação

Host `ssh.runnerhub.run`, raiz `/var/www/business.roadrunners.run`.
Somente três arquivos de runtime foram publicados. Todos estavam ausentes no
baseline; criação sem sobrescrita, conferência de hashes e manifesto privado.
O ajuste final no serviço guardou a versão anterior e conferiu o hash antes da
substituição atômica.

Backup e recibo completos:
`/var/backups/business-event-description-20260913.j4fu5ibu/`.

| Arquivo | SHA-256 final |
| --- | --- |
| `services/EventDescriptionRewriteService.cfc` | `7253f2724ede4f0dc146e0dbc776f1a10b92036ba7ec2b794f63d2885b525da1` |
| `api/eventos/jobs/rewrite-descriptions.cfm` | `7808c6eff84649059f7226e796869c7f720e96fcd4f0e864f501f306f864f81b` |
| `api/event-description-rewrite.cfm` | `3e589267b65b0c0bb5e903f1a5e9f8928eb76cea8715432f2d51376439848857` |

Os SQLs, testes e documentação não foram expostos na área pública. As consultas
temporárias tinham `Require local` (403 externo e 200 pelo próprio servidor)
e foram retiradas da área web ao concluir; a cópia ficou no backup privado.
Nenhum arquivo do RunnerHub foi alterado. Nenhum cron n8n/resumo foi encontrado
ativo nas tabelas do Business, nos crontabs consultados ou em `/etc/cron.d`.
Não houve commit, branch, push ou reinício de serviço.

Para recuperação, pausar o job 15 primeiro. Reverter descrições individualmente
a partir de `description_before`, somente quando o valor atual ainda coincidir
com `description_after` e a fonte com `source_text`. Preservar a auditoria. A
retirada dos três arquivos novos também exige conferir os hashes atuais para
não remover alterações posteriores.

## Evidência

- Serviço: **73 assertions** em CFML real, com transporte da IA isolado.
- Endpoint: **22 testes de acesso/parâmetros + 10 fluxos completos** com CFML e
  PostgreSQL temporário: simulação, gravação, NULL, concorrência, edição humana,
  troca de fonte, rejeição, erro do provedor e rollback.
- SQL real do endpoint em outro PostgreSQL descartável: elegibilidade,
  compare-and-set, deduplicação, nova fonte e instalação idempotente.
- ColdFusion de produção compilou **3/3** templates da versão final em staging
  privado. Hashes publicados conferidos novamente após os testes reais.
- HTTP público: GET 405; POST sem assinatura 401.
- Simulação do evento **46144** retornou prévia, sem alterar evento ou auditoria.
- Execução pelo runner existente **99113** preencheu sua descrição. Comparação
  do original integral e hash de **todos os campos exceto descricao** confirmou
  que somente o campo pretendido mudou. Auditoria 1 preservou o NULL anterior.
- Reexecução **99115** selecionou zero eventos, sem nova chamada à IA.
- Execução automática **99120** (`trigger_type=scheduled`) rejeitou o evento
  **32860**, retornou HTTP 422 e registrou auditoria 2, sem gravar descrição.
- Execução seguinte **99122** avançou para **34737**, atualizou a descrição e
  registrou auditoria 3. A rejeição anterior não bloqueou a fila.
- Última observação: job ativo, agenda cinco minutos, último status `success`;
  2 descrições preenchidas, 1 rejeitada, 2.996 descrições ainda vazias. Esse total
  inclui a rejeitada, que não é mais elegível para tentativa automática.

## Limites

As checagens locais e a segunda avaliação da IA reduzem o risco de alteração
factual, sem constituir garantia absoluta de equivalência semântica. Fontes
acima de 20 mil caracteres normalizados são rejeitadas integralmente.
Fontes rejeitadas e falhas do provedor não têm nova tentativa automática para a
mesma versão, inclusive via `eventId`; exigem tratamento manual. A auditoria
guarda códigos de erro sanitizados, sem registrar credenciais ou resposta bruta
do provedor.

O diagnóstico inicial contou 2.998 pendentes (original acima de 200 caracteres,
descrição vazia), sendo 1.643 ainda não encerrados; encontrou também 2.932
registros com os dois textos diferentes e 19 com textos iguais. Diferença de
texto não prova por si só que um registro foi gerado pelo fluxo n8n.
