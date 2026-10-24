# Reserva de rota do Comparador

A migração para /{tipo}/comparar/{slugs}/ exige reservar `comparar` no cadastro de produtos, além de `zerar` e `-vs-`. O serviço aplica a validação a criação, edição e publicação. Não há alteração de produtos existentes.

A consulta somente de leitura encontrou zero produtos com esse slug. Teste transacional no banco sintético demonstrou aceitação antes da alteração; a transação foi revertida. A mesma chamada pública `saveProduct` passou a rejeitar o slug após a alteração (GREEN), também em transação revertida.

Publicado em 17/10/2026, somente `services/ComparadorAdminService.cfc`, antes da nova rota pública. Backup: `/root/codex-backups/business/20261017T115657Z-seo-slug`. Baseline e hash final conferidos; três verificações de acesso anônimo aprovadas. Sem alteração de produtos, dados, permissões ou schema. [Recibo](2026-10-17_comparador_seo_slug_publicacao.json).
