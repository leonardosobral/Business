# Conteúdos novos: pendência de curadoria

Correção publicada em 18/09/2026 em `/portal/conteudos/`.

## Causa

A função PostgreSQL `news.fn_content_force_hidden_on_insert()` impedia publicação automática, mas também forçava `editorial_status='draft'`. A tela, o menu e o dashboard só consideram pendência editorial o estado `review`. Assim, conteúdos novos chegavam corretamente fora do site, porém eram apresentados como Ocultos e não entravam na fila de curadoria.

## Correção

- Default e trigger de inserção passam a gravar `review`.
- Mantidos `published=false`, `is_featured=false` e `published_at=NULL` na entrada. Importadores não conseguem publicar automaticamente.
- Atualizações posteriores não são forçadas pelo trigger: aprovar, rejeitar e ocultar continuam sendo decisões explícitas.
- Listagem com contador/link de pendências e selo amarelo; prévia também informa Pendente de curadoria.
- O filtro antigo `status=ocultos` mantém sua abrangência de todos os não publicados, mas o rótulo passa a explicar isso: Não publicados (todos).
- Rascunhos ocultos também podem ser retornados manualmente à curadoria pelo botão da lista.

Migração: `_codex/sql/2026-09-18_content_starts_in_review.sql`. Substitui a regra definida na migração histórica `2026-07-24_new_content_starts_hidden.sql`; não reexecutar a migração antiga após esta.

## Recuperação conservadora

Foram migrados somente quatro importados sem edição nem publicação anterior: IDs 2358, 2359, 2371 e 2406. Critérios simultâneos: `published=false`, estado `draft`, `published_at IS NULL`, `created_at=updated_at` e vínculo em `news.tb_content_imports`.

Permaneceram inalterados 1.681 publicados, 167 rejeitados, 6 em lixeira e os demais 21 ocultos/rascunhos. Não houve publicação de conteúdo. Os casos sem evidência suficiente de importação intocada não foram reclassificados; podem ser encaminhados manualmente à curadoria.

## Validação e recuperação

- Nove testes locais (curadoria e integração com dashboard).
- Compilação ColdFusion dos três templates de runtime.
- Teste real de INSERT, aprovação, ocultação e rejeição em transação revertida; nenhum conteúdo de teste permaneceu no banco.
- Consulta real de listagem validada contra o contador de pendências.
- Baseline dos três arquivos conferido antes da publicação; alterações de outras frentes não incluídas.

Backup no servidor: `/var/backups/business-content-curation-20260918-qihoZK1I/`.

- `runtime-before.tgz`: três templates anteriores.
- `database-before.json`: definição anterior da função, default, IDs e campos dos quatro registros, com datas originais.

Reversão de dados exige conferir se os quatro itens ainda não receberam uma decisão depois da migração. Não restaurar seus estados às cegas. A função anterior e o default estão no backup; restauração deve ser transacional. A migração não remove tabelas nem credenciais.
