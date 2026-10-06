# SEO — publicação de fontes das datas — 04/10/2026

Implementada a ligação explícita entre a conferência interna de datas no Business e o bloco de fontes da página pública RoadRunners. Em Fontes e revisões, o administrador registra a conferência com fonte e valores e, em ação separada com confirmação, publica início/término, link oficial e data original da conferência. A data de publicação não é apresentada como nova revisão da fonte. Local e situação continuam internos; horários e datas de cada percurso não estão cobertos.

## Contrato e consistência

Business é dono da aprovação e escreve uma projeção mínima na coluna aditiva `tb_evento_corridas.conferencia_datas_publica` (jsonb). RoadRunners lê essa projeção na consulta existente, via `to_jsonb(evt)`, sem acesso à tabela privada de revisões, sem novo endpoint e sem mudança de permissões.

Contrato versão 1: state published, reviewId textual, startDate/endDate/checkedAt em YYYY-MM-DD, sourceUrl HTTP(S). Não contém operador, IP, notas internas ou dados de atletas. Estado withdrawn bloqueia o retorno a recibos legados; NULL mantém o comportamento manual anterior. Valor desconhecido ou inválido suprime o bloco de conferência sem quebrar a página nem remover o histórico de correções.

Publicação exige administração interna, ausência de delegação, POST, CSRF, ID do formulário igual à URL, última revisão do grupo datas não retirada e snapshot exatamente igual ao cadastro. A fonte é revalidada como URL e as datas devem ser preenchidas e ordenadas. Lock no evento serializa registrar/publicar/retirar. Publicar novamente a mesma revisão é idempotente. Retirada de formulário obsoleto não remove uma revisão mais nova e retorna erro, sem alegar sucesso.

Nova conferência de datas retira a projeção anterior, sem publicar a nova automaticamente. Revogar uma conferência publicada também retira sua projeção. Retirar somente a publicação preserva a conferência interna. O site só mostra o recibo enquanto as datas coincidirem; se voltarem exatamente aos valores conferidos, ele pode voltar a aparecer, salvo retirada explícita. Não há verificação automática de mudanças na fonte externa.

O histórico administrativo conserva as últimas dez revisões e a última de cada grupo para que os controles não desapareçam após muitas conferências de outros campos. O histórico público curado continua independente.

## Arquivos e publicação

Business: `services/EventFactReviewService.cfc`, `eventos/includes/backend/fontes_revisoes.cfm`, `eventos/form_edicao_fontes.cfm`, `portal/includes/seo_queue_data.cfm`.

RoadRunners: `includes/backend/backend_evento.cfm`, `evento/parts/fact_review.cfm`.

Migração: `_codex/sql/2026-10-04_evento_fonte_datas_publica.sql`. Ordem: migração, consumidor RoadRunners, controles Business, painel. Backups privados em `/var/backups/seo-fact-public-db-20261004`, `/var/backups/seo-fact-public-20261004-roadrunners/baseline`, `/var/backups/seo-fact-public-20261004-business/baseline` e `/var/backups/seo-fact-public-panel-20261004/baseline`.

Para rollback de runtime, usar release.py rollback por projeto nos artefatos da entrega, preservando a coluna e todos os recibos. Antes de voltar ao consumidor antigo, considerar que ele ignora tombstones novos e volta a usar os recibos manuais; não tratar rollback do consumidor como retirada editorial. A inversão estrutural foi ensaiada apenas em transação revertida antes da publicação. Não remover a coluna após uso real.

## Verificação

- Migração e inversão ensaiadas em rollback; hashes dos eventos (excluindo apenas a coluna nova), revisões e histórico iguais antes/depois. Permissões e triggers preservados. Uma tentativa inicial encontrou lock concorrente e abortou no limite de três segundos; repetição após leitura dos locks passou, sem interromper sessões.
- Cinco arquivos de runtime compilados; hashes reais publicados e oito dependências preservadas.
- Serviço: 22 assertions antes/depois, incluindo autorização, CSRF, GET, evento/grupo incorretos, revisão retirada/antiga, alteração de datas, histórico extenso, retirada obsoleta e idempotência.
- Controller real Adobe: oito casos e quatro estados renderizados antes/depois. Testes em tabelas temporárias, sem conferências fictícias permanentes.
- 283 assertions de renderização PT/EN/ES, incluindo regressão dos recibos/histórico anteriores, tombstone, versão desconhecida, JSON inválido, URL insegura, campos complexos, datas divergentes e escaping.
- 27 URLs públicas antes/depois: HTTP200, fontes e histórico esperados, canonical, alternates e JSON-LD preservados.
- Prévia Adobe com CSS real em 1280×900 e 390×844 sem overflow; detalhes abrem/fecham com Enter. Não foi enviada uma conferência real apenas para testar.
- Revisão independente corrigiu dois P2 e aprovou o delta sem outros bloqueadores.

Artefatos: `_codex/staging/seo-fact-public-20261004/` e `_codex/staging/seo-fact-public-panel-20261004/`. SH-02 continua parcial: revisão dos percursos, cobertura factual e demais divergências ainda pendentes. Esta entrega não comprova indexação no Google nem citações por IA.

Painel publicado e conferido nas abas relatório/fila: um template compilado, hash e cinco dependências preservados; 24 itens, 18 concluídos e seis pendentes. Alertas de evidência do Google e notas técnicas históricas mantidos.
