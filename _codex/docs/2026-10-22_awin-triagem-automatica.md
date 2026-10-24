# Triagem automática das campanhas Awin — 22/10/2026

Publicado no Business, no mesmo job **24 — Comparador - Campanhas e ofertas Awin**, a cada **30 minutos**. O Comparador continua apenas consumindo os contratos. Não há novo importador nem novo cron.

## Decisões na sincronização

- Categorias explicitamente ausentes do catálogo elegível de tênis, como vestuário, chuteiras, chinelos, eletrônicos e suplementos, entram em **Fora do catálogo**, com motivo e `origin=automatico` nas decisões. Seleções que também mencionem tênis exigem revisão. Catálogo vazio ou com outras categorias impede essa exclusão automática por categoria.
- Um modelo ausente só pode ser separado automaticamente quando o título completo e o endereço direto do produto concordam em marca/modelo, sem identidade, geração omitida ou variante que possa corresponder ao acervo. Coleções, marcas desconhecidas, destinos divergentes e ambiguidades ficam em **Precisam de revisão**.
- Correspondências únicas continuam sendo vinculadas e publicadas pelo fluxo existente. Cupons por categoria e seleções amplas exigem confirmar quais modelos e gerações participam; não se aplica o cupom sobre o preço do feed.
- Regras manuais, bloqueios e reaberturas editoriais têm precedência. A triagem automática grava decisões, sem criar regras editoriais em `rules`, e é reavaliada conforme a campanha e o catálogo mudam. Classificações editoriais anteriores conservam a proteção de identidade e a reabertura quando surgir nova correspondência.

A normalização de acentos passou a remover marcas Unicode pelo Java: o motor de regex CF instalado não reconhecia `\p{M}` e dividia “tênis” em “te nis”. Isso foi corrigido para impedir exclusões erradas em seleções mistas e reconhecer títulos como “calção”. O fingerprint da campanha permanece inalterado.

## Avisos sem repetição

Resultado do serviço, API e histórico acrescentam `newReviewCount` e `newReviewCampaignIds`. A API fornece também `new_items`, compatível com o contador já instalado do cron. Esses campos consideram somente entradas novas, alterações de identidade/motivo e reaberturas da fila de revisão. Fora do catálogo e pendências inalteradas não geram esse aviso.

O heartbeat existente **Sincronizar Awin e promoções** foi atualizado, mantendo o mesmo ID, chat e horário diário de **10h30 em Brasília**. Ele compara a fila atual e o histórico com [o checkpoint de revisão](/Users/Shared/Projects/RunnerHub/Comparador/codex/docs/evidencias/awin-revisao-checkpoint.json), sem depender do delta da última execução de 30 minutos. Avisa sobre nova revisão necessária ou falha operacional que exija ação; variações rotineiras de preço, disponibilidade, campanhas externas e pendências já avisadas ficam no recibo. Nenhum destinatário de mensagens foi adicionado ao job.

## Validação em produção

Run final **236955**, concluído em **22/10/2026 às 15h35min12s de Brasília**, HTTP **200 OK**, `success=true`, fonte e **sete feeds sem erros**. Resultado:

- **45 campanhas fora do catálogo**: 40 decisões editoriais preservadas e cinco novas campanhas de suplementos classificadas automaticamente.
- **Três campanhas da ASICS em revisão**: `4148975` / **ESTILO15** (Casual), `4148973` / **JOGA15** (Quadras) e `4148970` / **RUN15** (Running). Os títulos anunciam categorias; os modelos elegíveis não estão confirmados. Nenhum vínculo de campanha foi publicado sem essa confirmação.
- **98 ofertas de preço**, **68 produtos**, **1.896 variantes** aceitas pelos leitores reais; **94 combinações de produto/gênero cadastrado** e **1.253 verificações de mínimos**. Cinco amostras públicas de Nike, ASICS, Olympikus, Mizuno e Centauro conferiram preço, SKU, loja, gênero e destino de compra, sem abrir afiliados.
- **90 testes CFML** da publicação/triagem e **dois testes** do contador instalado de notificações passaram. API manteve GET 405 e POST sem autenticação 401. A segunda coleta retornou `newReviewCount=0` e `new_items=0`, sem repetir as três pendências.

A primeira validação, run **236919**, trouxe cinco novas campanhas de nutrição. A regra foi ampliada com esses casos e seleção mista, testada e validada na versão final. Cada versão teve uma invocação do mecanismo existente, com lock, autenticação e histórico. A próxima execução ficou registrada às **16h05min12s**, com intervalo de 30 minutos.

## Arquivos e recuperação

Business: `services/ComparadorAwinPublicationService.cfc`, `api/comparador/awin-sync.cfm` e teste local `_codex/tests/comparador/awin-publication.cfm`. Sem alteração de templates, runtime do Comparador, banco, `tb_cupom`, produtos, fotos ou World Athletics. Hashes, regras, bloqueios e atributos privados foram conferidos antes/depois.

Release inicial **20261022T182635Z-3teba7un**; complemento final **20261022T183449Z-3teba7un-r2**. Backups privados em `/var/backups/awin-auto-triagem-20261022/<release>`, com runtime anterior, manifesto e cópias dos contratos. Para voltar ao comportamento anterior à tarefa, considerar o backup inicial; o segundo contém a primeira versão desta entrega. Conferir hashes e alterações posteriores antes de restaurar somente o runtime necessário. Não substituir regras ou contratos atuais por snapshots antigos. A API anterior deve ser restaurada antes de um serviço que não exponha os campos novos.

[Recibo sanitizado](2026-10-22_awin-triagem-automatica_recibo.json) · [Gestão no Business](https://business.roadrunners.run/administracao/comparador/awin/?aba=publicacao).
