# Curadoria de provas e circuitos — 30/10/2026

Entrega posterior à estrutura regional de 30/10. RoadRunners recebeu correções no cadastro e melhorias nas páginas permanentes. Business mantém plano, snapshots, regulamentos e recibos desta rodada em `_codex/staging/seo-curadoria-circuitos-20261030/`.

## Correções de cadastro publicadas

| Evento | Correção | Evidência |
|---|---|---|
| 43657 — Curitiba 2026 | Vínculo ao histórico 29, inclusão de 42 km, descrição concisa PT/EN/ES e regulamento atualizado | Site oficial `maratonadecuritiba.com.br`, que reconhece a edição anterior; PDF atual do evento Ticket Sports 86884, página 1: 15/11/2026 e 5/10/21/42 km |
| 39395 — Monumental 2026 | Categorias 5/10/21/42 km + kids; percursos por dia e horários; descrição PT/EN/ES corrigida, removendo referência a 2025; regulamento v6 atual | `maratonamonumentalbsb.com.br` e PDF v6: 5/10 km em 21/11 às 17h, 42 km em 22/11 às 5h, 21 km em 22/11 às 6h |
| 38982 — Santander Night Run Curitiba | Cidade física Pinhais, código municipal 4119152, localidade 4002 e endereço Parque das Águas | Página de venda Running Land distingue a marca comercial Curitiba do local físico Parque das Águas, Pinhais |
| 37774 — Night Run duplicada | Inativação reversível e `tag_301` para a ficha 38982; nenhum registro excluído | Página O2 fornecida na ficha aponta para a mesma página Running Land, em 31/10; antigo cadastro em 07/11 não tem resultado, agenda, inscrição/conta, anúncio ou percurso para migrar. Geocoding e estado Foco permanecem preservados |
| 46521 e 46508 — Estações Curitiba/Brasília | Inclusão de dois vínculos em `tb_agregadores_eventos`, tag `estacoes`; fichas intactas | Páginas oficiais Running Land confirmam Curitiba em 29/11 e Brasília em 06/12, edição Verão 2026 |

Não foram alteradas datas de início/término dos eventos. As distâncias de catálogo continuam nas categorias 21/42 km existentes; as descrições e fontes distinguem meia maratona e maratona. Os três percursos antigos de Curitiba preservaram os IDs e foram bloqueados para proteger a conferência manual. Criados apenas os cinco percursos faltantes: um em Curitiba e quatro na Monumental. Os percursos de LIVE, Night Run e Floripa foram preservados.

## Conferências sem necessidade de correção

- LIVE! Brasília: origem confirma 13/12/2026 e 5/10/15 km + Kids; retirada de kits ainda a confirmar. Vínculo moderno `tb_agregadores_eventos` com `live-run-xp` já existe; `id_agrega_evento` nulo é correto para circuitos. A aceitação do cupom no checkout externo não foi testada; não se atribui essa confirmação ao simples anúncio do desconto.
- Floripa 2027: vínculo e datas dos percursos corretos — meia em 28/08, maratona e 5 km em 29/08. Nenhum dado dessa ficha foi alterado. PDF cadastrado tem um ano antigo na introdução, mas sua programação explicita 2027; não foram importados os trechos inconsistentes sobre outros anos ou limites.

## Páginas permanentes

- Novo `includes/permanent_race_editorial.cfm`: informações práticas de Curitiba, Monumental e Floripa, recolhidas em detalhes, com fonte e data da conferência. Exibe somente quando tag da próxima edição e intervalo de datas coincidem com a evidência; oculta automaticamente quando outra edição/data passa a ser selecionada.
- `backend_permanent_race.cfm` e overview reutilizados para os circuitos LIVE!/Estações, com canonical de circuito e rótulos de etapas. `CollectionPage`/`ItemList` aponta às fichas reais.
- Circuitos exibem próxima etapa, última realizada e menu recolhido de calendários das próximas cidades (limite 32). Agenda continua no corpo, com abas existentes e destaque LIVE preservado. Reutiliza as consultas existentes; não muda contratos de cupom, anúncios ou inscrição.
- Classificação considera o fim do evento, com fallback de início e proteção de nulo no Adobe QoQ.
- Não há novo JavaScript, CSS ou biblioteca. Publicados 5 arquivos, dos quais `maratona/index.cfm` foi republicado idêntico ao baseline para manter o pacote verificado; 4 arquivos têm mudanças nesta rodada.

## Segurança, validação e reversão

- Correções de dados ensaiadas em transação com rollback e inversão comprovada antes do commit; baseline guardado em `/var/backups/seo-curadoria-circuitos-20261030-data/`.
- Eventos protegidos por hash integral de linha; percursos antigos comparados por ID e conteúdo. 47 conjuntos de dependências preservados por contagem/hash, incluindo resultados, agenda, contas, mídia, anúncios e CRM.
- Dois vínculos do Estações têm ensaio e inversão próprios, em `/var/backups/seo-curadoria-estacoes-20261030/`. Os dois hashes de fichas permaneceram iguais.
- Histórico factual automático conferido; backup contém também mudanças de vínculo/descrição não cobertas pelo gatilho de fatos. Dados de pessoas não foram exportados: dependências foram conferidas por hashes e contagens.
- Runtime: backup `/var/backups/seo-curadoria-circuitos-20261030-runtime/baseline`, ajuste de cidades em `update-161928/baseline`; cinco hashes e cinco dependências conferidos.
- 5 templates compilados, 7 cenários Adobe, 16 asserções de modelo (incluindo expiração do conteúdo editorial por data/tag). LIVE respondeu em 0,239/0,286/0,227 s contra baseline 0,219/0,228/0,227 s: amostras de resposta, não Core Web Vitals.
- HTTP anônimo: 13 páginas, três redirecionamentos 301 nos idiomas PT/EN/ES e 403 do novo include. Chrome desktop/mobile 390 px, abertura por teclado e ausência de overflow conferidos; evidências em PNG.
- `data_release.py rollback` exige o estado publicado exato, restaura campos e flags originais e remove somente percursos criados pela operação; `membership_release.py rollback` remove somente os dois vínculos criados, com guarda de estado. `release.py rollback` restaura templates e remove o include novo com verificação contra alterações concorrentes. Não executar rollback se houver drift; revisar o conflito.

## Próximas etapas

- Revisar a cobertura restante de Estações/LIVE por fontes oficiais. A investigação encontrou outras etapas sem vínculo e também provas de outros organizadores com palavras semelhantes; não foi feita associação por nome em lote.
- Conferir horários de kits LIVE quando a origem publicar; medir cliques para fichas/inscrição e aquisição de cidade/prova com GSC em janelas equivalentes.
- Desenvolver a navegação pós-prova com resultados/fotos disponíveis. Não há garantia de melhora de posição ou tráfego apenas pela publicação.

Sem migração de schema, operação manual no DataGrip, commit ou push. Plano principal: `Business/_codex/docs/2026-10-25_plano_seo_regionais_pace.md`.
