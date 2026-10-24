# Inscrição LIVE com cupom inline

A página de evento mantém as regras existentes de disponibilidade, cancelamento e validade do cupom. Apenas eventos cujo circuito resolvido é `live-run-xp` podem usar o novo bloco. A leitura de `vw_cupom` usa o mesmo cupom/evento do modal legado e exige `ativo = true`, código não vazio e URL HTTPS nos hosts LIVE conhecidos. Caso não seja elegível, permanece o fluxo de modal existente.

O código é servido em um campo `readonly` selecionável e a inscrição usa uma âncora HTML. Não depende de login ou de JavaScript. O botão Copiar aparece quando o script inicializa; sucesso só é anunciado após a resolução da Clipboard API, enquanto erro seleciona o código e orienta a cópia manual. O texto deixa claro que o usuário precisa informar o código no checkout.

Na aba Próximos do circuito LIVE, o seletor oferece Todas as cidades inicialmente e filtra os cards sem navegação. As cidades usam slugs normalizados com UF para distinguir homônimos. O destaque geográfico permanece como primeiro card quando presente e participa do filtro; limpar o filtro restaura a lista original completa, sem duplicações. O estilo compacto e a ação Ver prova e cupom se limitam a essa lista.

## Contrato de interface

- Seção: `[data-live-coupon-view="ID_EVENTO"]`.
- Botão: `[data-live-coupon-copy="ID_EVENTO"]`.
- Link de inscrição: `[data-audience-live-registration="ID_EVENTO"]`.
- `window` recebe `CustomEvent('rr-live-funnel')`, com `detail.action` igual a `coupon_copy_success` ou `coupon_copy_error` e `detail.eventId` como string.
- Filtro `[data-live-city-select]`: `detail.action = 'city_select'` e `detail.citySlug` como `rio-de-janeiro-rj` ou `all` (Todas tem value vazio). Não envia o código, o URL ou labels livres.

## Validação local

Executar a partir da raiz RoadRunners (ou indicar o staging como primeiro argumento dos scripts):

```sh
node --check assets/js/rr-live-funnel-ui.js
node --test _codex/tests/live-funnel-ui.test.cjs _codex/tests/audience-live-registration.test.js
bash _codex/scripts/test_live_coupon_inline.sh
bash _codex/scripts/test_circuit_live_highlight.sh
```

Os scripts CFML renderizam fixtures em diretórios temporários, sem bootstrap da aplicação nem acesso a dados reais. Usam o CommandBox já adotado pelo projeto; o diretório temporário do runtime é configurável por `RR_COMMAND_BOX_HOME`. A inspeção final deve incluir o evento e circuito reais, desktop/mobile, após integração com o coletor.
