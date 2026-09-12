# Audiência — continuação de 10/09/2026

## Estado desta entrega

**Lote de vídeos publicado em 10/09/2026, 10:34:32 Brasília, e validado no navegador e no Business.** O cache de localização continua somente local, fora da publicação. Nenhuma alteração em `tb_log`, autenticação, banco, cobrança de Ads ou configurações de produção. Recibo: [publicação YouTube](2026-09-10_audience_youtube_publicado.md).

## Reprodução real de YouTube

No RoadRunners, o modal compartilhado agora conecta a API oficial do player ao coletor existente. Abrir o modal continua sendo `content_open`; somente estado PLAYING, em aba visível e com identidade confirmada do vídeo selecionado, pode produzir `video_start`.

- `video_progress`: marcos de posição 25%, 50% e 75%, deduplicados por vídeo/página. Não equivalem a tempo integral assistido: o usuário pode avançar o playhead.
- `video_complete`: ENDED observado depois de um início observado. Não prova que cada segundo foi assistido.
- Ready, cued, pausa e buffering não contam como início.
- Fechar ou trocar o modal encerra o observador anterior e ignora callbacks atrasados.
- Selecionar outro vídeo dentro do iframe encerra a atribuição ao vídeo original. Não se atribuem quartis/conclusões do relacionado ao original.
- A URL do player é consultada apenas localmente para confirmar o ID. Não é enviada como telemetria.
- Bloqueio/falha da API mantém o embed convencional, mas deixa a reprodução sem confirmação. Não se fabrica zero observado nem início a partir da abertura.
- Opt-out e GPC existentes permanecem; HTML5 mantém seu fluxo anterior.

Referência: [YouTube IFrame Player API](https://developers.google.com/youtube/iframe_api_reference).

### Contrato e Business

Sem tipos novos de evento, migração SQL ou permissão nova. O coletor já aceita os três tipos. O relatório `portal/audiencia/queries/content.sql` já agrega `video_start` e `video_complete`, exibidos em **Conteúdo individual → Inícios de vídeo / Conclusões**. Os quartis ficam registrados, mas não ganharam novas colunas no painel nesta etapa.

Os números refletem reproduções reais elegíveis a partir desta publicação. Dois vídeos de teste chegaram ao Business com uma abertura e um início cada, incluindo a reprodução em viewport móvel. Não há preenchimento retroativo dos vídeos abertos anteriormente.

### Arquivos de execução RR

| Arquivo | SHA-256 local e publicado |
|---|---|
| `assets/js/rr-audience.js` | `b79bb913eb5f604eecd1ad6a77024198c96179850e3da299d82997f1a409a7d2` |
| `includes/modal/modal_youtube.cfm` | `92a7e067f7d36f361e09d89043c962e45940a8bada22f7846dd5bc6ce8f38aba` |
| `includes/analytics/bootstrap.cfm` | `9578188a77ba16a6c7a48b7c45c37b7137bccd7507892582d02317ee99c32d51` |

Bootstrap referencia `rr-audience.js?v=b79bb913eb5f` para separar a versão do asset em cache. Nenhuma alteração no service worker nesta etapa.

Pacote local de publicação **somente de vídeos**: `_codex/releases/2026-09-10_audience_youtube_linux.tar.gz`, SHA-256 `16c53efd3489b8dd9afb541de0c1b349c9a267af3c2cb337145f26747f7f3ce7`. Criado com `COPYFILE_DISABLE=1` e formato ustar; listagem contém exatamente os três arquivos acima. Não inclui cache geográfico, testes, documentos, autenticação ou Ads.

### Validação local executada

- RED → GREEN: observador ausente; modal sem API; e atribuição incorreta após mudança de identidade reproduzidos antes das respectivas correções.
- Node: **69/69 testes** no projeto RR, cobrindo tracker, modal real integrado ao tracker, controles de privacidade, i18n e navegação editorial do service worker.
- `node --check assets/js/rr-audience.js`: passou.
- `git diff --check`: passou em RR e Business.
- Business: **5/5 testes** do dashboard.
- `_codex/scripts/test_audience_cfml_local.sh`: passou (contexto assinado, origem, identidade, expiração e guards de payload, sem banco).
- Renderização isolada do modal em CFML/Lucee: passou com tradução substituída apenas na fixture, sem carregar Application ou datasource. O primeiro ensaio apontou sintaxe inválida de `savecontent` na fixture; corrigida para a tag `cfsavecontent`, sem mudança no código de execução.
- Revisão independente: proteção contra vídeo relacionado incorporada e reavaliada; sem achado remanescente no escopo de reprodução.

Na publicação, a suíte de 69 testes Node passou novamente, também em conferência independente do pacote. Em produção, o player reproduziu em desktop e viewport de 390 × 844; pausa, retomada, fechamento e reabertura funcionaram. O Business recebeu um início para cada um dos dois vídeos, sem duplicar o primeiro após reabertura. O teste utilizou acessos internos, excluídos do filtro comercial padrão; os filtros e o viewport foram restaurados. Conclusões e quartis possuem cobertura local, mas não foram confirmados ponta a ponta nesta sessão: os vídeos não foram assistidos até o fim.

### Procedimento realizado / recuperação

1. Conferir os três arquivos atuais no servidor e preservar backup/hash, sem publicar arquivos de autenticação ou Ads adjacentes da árvore suja.
2. Publicar primeiro o JS, depois modal e bootstrap como um lote compatível. Durante sobreposição, o modal verifica se `bindYouTube` existe e preserva playback sem métricas novas.
3. Abrir um vídeo editorial em desktop/mobile: confirmar player, pausa, retomada, fechamento e troca sem efeitos em layout ou login. Não clicar em anúncio.
4. Confirmar os eventos e os contadores no Business com período, ambiente e filtro de tráfego interno adequados. Não confundir abertura de modal com início; considerar o cache de consulta de um minuto.
5. Backup disponível em `/var/backups/rr-audience-youtube.36MZOB/before/`; rollback dos três arquivos somente se necessário, sem SQL, reset de APPLICATION ou invalidar sessões. Nenhum rollback foi necessário. Hashes dos arquivos publicados e dos arquivos protegidos conferidos novamente após a validação.

## Cache negativo de localização

Implementado localmente em `RoadRunners/services/LocationResolver.cfc`, SHA-256 `1aad7ccd36a68ce66e1968766df842d1d27c32a9a34471b88b37af4f63e74f22`. Teste/runner/documentação específicos em `_codex/tests/location-cache-contract.cfm`, `_codex/scripts/test_location_cache_local.sh` e `_codex/docs/location-negative-cache.md` no RR.

- País BR sem UF válida: cache de cinco minutos; cookies negativos antigos não impedem nova consulta ao cache/provedor.
- Entradas negativas antigas sem data de criação deixam de herdar as 12 horas. Leituras não renovam o prazo de tentativa.
- UF brasileira válida e país estrangeiro mantêm os TTLs anteriores e o contrato legado.
- Não foi alterada a fonte de IP/UF, o provedor ou o proxy. Nenhuma UF do perfil/conteúdo preenche a UF de acesso.
- 30 verificações CFML offline passaram no candidato e novamente nos arquivos finais do checkout, em execução independente do agente principal; `bash -n` passou; revisão independente sem achados. O ambiente usa Lucee, não comprova execução Adobe ColdFusion de produção.
- Com o 403 persistente, tentativas mais frequentes podem aumentar consultas e latência. Esse arquivo é um lote independente da medição de vídeos; não tratar seu deploy como recuperação comprovada de UF nem torná-lo pré-requisito para publicar os vídeos.

## Restante do plano — atualizado em 12/09/2026

Bloqueio HTTP 403 diagnosticado no provedor de UF permanece pendência de origem/infraestrutura; cache curto não é correção desse bloqueio. A fonte confiável de localização e seu transporte até CF precisam ser validados antes de se declarar a medição por UF física completa.

Exposição editorial e profundidade alcançada (não leitura comprovada) foram publicadas no lote seguinte, em 10/09/2026 às 23:34:17 Brasília, após o usuário informar a execução do SQL; os novos sinais chegaram ao Business em navegação interna de validação: [recibo editorial](2026-09-10_audience_editorial_publicado.md). Promoções estáticas, classificação dos estados de entrega e piloto institucional lateral também tiveram publicações posteriores. O [estado consolidado de 12/09](2026-09-12_audiencia_escopo_e_pendencias.md) registra os lotes e as pendências reais, incluindo a base necessária à projeção comercial. Retenção continua independente da contagem.

Em 12/09, o usuário retirou a segunda parte de mídia e crescimento desta tarefa, pois está sendo tratada em outra frente. Não há piloto de aquisição, verba, criativos externos ou testes A/B de mídia a executar aqui. A coleta de origem/UTM existente permanece, assim como o piloto institucional lateral para medir a área sem campanha.

A pedido reforçado do usuário, eventual aposentadoria **somente do writer de visualização de página de evento** em `tb_log` fica para o final; demais registros e todo histórico permanecem. Não transforma essa migração em pré-requisito para avançar a mensuração.
