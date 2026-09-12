# Saída para inscrições LIVE! e contexto de circuito

Implementação local de 12/09/2026. O produtor reutiliza o coletor de audiência;
não chama endpoints financeiros de Ads, não registra compra e não instala código
no parceiro. A publicação e a confirmação de recepção ficam a cargo do rollout.

## Contrato

- `kind`: `outbound_click`.
- `key`: `outbound_click:live_registration:<id_evento>`; `emit` acrescenta o prefixo
  `outbound_click:` à chave da ação.
- `contentType`: `event`; `contentId`: ID positivo da prova.
- Sessão, visitante estimado, origem, meio, campanha e variante usam o envelope
  existente. `campaignId` continua reservado à publicidade interna.
- Nenhuma URL externa, cupom, GCLID, localização pessoal ou campo novo é enviado.
- O servidor rejeita identidade inconsistente, campos financeiros e durações de
  engajamento inventadas nessa ação. Outros tipos/chaves existentes permanecem
  compatíveis.

O SQL existente admite `outbound_click`, famílias por regex e IDs de conteúdo;
não há migration. A família `circuit` e o tipo `circuit` usam o
`qAgrega.id_agrega_evento`; o caminho canônico público distingue
`/circuito/live-run-xp/` e exclui a query string. Perfis continuam sem slug pessoal.

## Superfícies e navegação

Os CTAs usam `data-audience-live-registration` com o ID da prova:

1. `#linkInscricao` no conteúdo assíncrono do modal de cupom, somente quando a linha
   de cupom possui ID de evento válido;
2. link principal de inscrição da página do evento;
3. botão de inscrição da barra de ações, cujo `window.open` foi preservado;
4. edição atual que está aberta para inscrição, com destino externo.

Links de informações, resultados, edições fechadas e navegação interna não recebem
o marcador. O destino é conferido no clique e exige HTTPS, sem credenciais nem
porta alternativa, nos hosts exatos `liverun.com.br`, `www.liverun.com.br`,
`appliveexperience.com.br` e `www.appliveexperience.com.br`. Não são aceitos
subdomínios arbitrários nem hosts parecidos. Essa conferência classifica a ação;
não impede nem altera a navegação existente para destinos fora da lista.

Um listener delegado cobre conteúdo inserido após o carregamento, clique em ícone,
ativação por teclado, clique modificado e botão do meio em links. Não chama
`preventDefault`, não aguarda rede e não modifica `href`, `target` ou `window.open`.
O envio usa `sendBeacon` e o fallback existente. Bloqueio/falha de coleta não pode
impedir o encaminhamento. O hash do script no bootstrap foi atualizado para evitar
o uso inicial de um asset antigo em cache.

## Privacidade, deduplicação e limites

GPC e recusa por cookie/localStorage interrompem a coleta; recusa posterior limpa
a fila. Permanecem os filtros de UTM, validade do contexto assinado, retenção dos
identificadores e limites de fila/rede existentes.

Cliques repetidos em CTAs da mesma prova na mesma página usam a mesma chave.
Revisitas e recarregamentos podem produzir novos registros; o Business deve contar
uma única saída por `session_id + content_id`, e uma única sessão no total da
campanha, mesmo que tenha saído para mais de uma prova. Não somar etapas como
pessoas distintas.

O contrato existente associa a chave ao `pageViewId`: uma aba contínua que rotacione
a sessão após 30 minutos não cria uma nova abertura da página. Se já houve saída
naquela página/prova, um novo clique pode ficar deduplicado; navegar ou recarregar
obtém outro contexto. Nenhum contrato de sessão foi alterado neste lote.

Um beacon pode ser perdido e o clique não comprova carregamento do parceiro,
inscrição ou pagamento. Ausência de recepção não comprova que ninguém clicou.
Attribution continua sendo a do início da sessão; o relatório de cupom universal
não permite atribuir vendas ao Google sem vínculo adicional.

## Verificação local

TDD: o teste Node falhou sem emissor; o contrato CFML falhou sem identidade do
circuito; os testes Chrome falharam sem marcador no modal e depois na edição.

- `node --test _codex/tests/audience-tracker.test.js _codex/tests/audience-editorial.test.js _codex/tests/audience-live-registration.test.js _codex/tests/audience-sw-navigation.test.js`: 74 passaram.
- `node --check assets/js/rr-audience.js`: passou.
- `bash _codex/scripts/test_audience_live_cfml_local.sh`: passou no runtime CFML
  isolado existente, sem bootstrap, datasource ou rede.
- `bash _codex/scripts/test_audience_editorial_cfml_local.sh`: passou com o serviço
  candidato.
- `NODE_PATH=<dependencias-node> node _codex/tests/audience-live-browser.test.mjs`:
  oito cenários passaram em Chrome headless (1280 e 390 pixels). O teste renderiza
  os fragmentos reais de CFML e intercepta toda a rede, inclusive novas abas.
  Cobre modal substituído, repetição, teclado, nova aba, barra `window.open`,
  edição aberta/fechada e recusa posterior. O teste Node cobre GPC inicial, opt-out,
  armazenamento indisponível, destinos rejeitados e falha de transporte.

Os testes de navegador verificam fragmentos reais; não renderizam toda a página de
evento com banco. O service worker permaneceu intacto e a regressão existente
passou. Não houve teste no parceiro, ingestão no banco ou alteração de produção.

## Rollout

Primeiro disponibilizar no Business o consumidor que reconhece a chave e a família
`circuit`; depois publicar serviço, tracker com bootstrap atualizado e marcadores
dos quatro CTAs. A coleta pode chegar antes do relatório, porque os campos e tipos
já são aceitos. Conferir versão efetivamente implantada e recepção após publicação.
Rollback do produtor remove a emissão futura; eventos já recebidos permanecem
sujeitos à retenção existente.

O candidato `evento/index.cfm` também preserva dois blocos de sidebar/footer que
já existiam em produção e estavam ausentes na cópia local. Isso é reconciliação
do baseline, não funcionalidade nova desta instrumentação.
