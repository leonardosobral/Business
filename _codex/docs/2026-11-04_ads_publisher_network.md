# Banners em outros sites — ads.roadrunners.run

## Escopo e propriedade

Business mantém o inventário de sites/spots, o formulário dos banners e a aplicação pública isolada `ads-network/`. A regra de seleção, aprovação, orçamento, saldo, impressão e cobrança continua nas funções canônicas do schema `ads`, consumidas também pelo RoadRunners. Nenhuma mudança no runtime do RoadRunners é necessária. Não há segunda carteira nem duplicação do algoritmo de leilão.

O domínio público é **ads.roadrunners.run**, com document root próprio `/var/www/ads.roadrunners.run`, separado do login do Business. Não instalar como alias para o Business inteiro.

## Operação

1. Admin global: Banners → Sites e spots → Sites. Informar nome, identificador e origens HTTPS exatas (sem caminho, porta, wildcard ou barra final). `www` é outra origem e precisa constar separadamente.
2. Spots: selecionar site, nome/identificador, tipo de página, UF contextual opcional, largura/altura de referência e status.
3. Código de instalação: copiar a div correspondente e carregar o script uma vez por página. É possível ter várias divs/slots. Para páginas dinâmicas chamar `window.RoadRunnersAds.scan()` depois de inserir novas divs. Não substituir os atributos de uma div já carregada; criar outra div ao trocar a página.
4. Cliente: criar banner, escolher site/spot, orçamento e segmentação, enviar para análise. Trocar o spot exige nova análise. Uma campanha atende um spot; uma segunda campanha compartilha o mesmo saldo e tem orçamento próprio.
5. HOUSE: admin pode escolher o spot no cadastro institucional. Só concorre quando não houver CPC elegível naquele spot.

Identificadores de instalação são imutáveis. Sites/spots são inativados, não excluídos; alterações ficam em `ads.publisher_inventory_history`. Inativar bloqueia novas entregas e tracking do inventário. Não modifica campanhas, recibos ou saldos históricos. Cada salvamento administrativo usa versão esperada e CSRF. Modo delegado não administra inventário.

A UF configurada é **contexto da página**, não geolocalização do visitante. Sem UF, banners restritos a estados não são elegíveis. Na primeira versão, um site com várias páginas estaduais deve ter spots específicos por UF. Tipo de página vazio é geral; banners limitados a tipos específicos não concorrem ali. Não aceitar UF arbitrária enviada pelo navegador.

## Contrato público v1

Script assíncrono `GET /sdk/v1.js`. Sem cookies, localStorage, identificador pessoal, HTML arbitrário ou credencial administrativa no cliente.

```
<div data-rr-ads-site="meu-site" data-rr-ads-spot="lateral-home"></div>
<script async src="https://ads.roadrunners.run/sdk/v1.js"></script>
```

`POST /v1/serve.cfm` (form-urlencoded: site, spot) exige `Origin` exata autorizada e inventário ativo. Responde `{status:"empty"}` ou recibo, token opaco de 30 minutos, URLs HTTPS das peças/destino, alt text e dimensões. Escolha CPC primeiro, HOUSE depois. O servidor define IDs de eventos e vincula recibo a site/spot/origem no contexto canônico da entrega.

`POST /v1/viewable.cfm` e `/v1/click.cfm` recebem delivery/token. Validam novamente origem, inventário, validade e token. Repetições usam os mesmos IDs de evento e preservam a idempotência canônica. Os tokens não devem ir em logs/URLs.

SDK registra impressão somente após imagem carregada, elemento visível ≥50% por 1 segundo, aba visível. Falha de imagem, aba oculta, entrega vazia e DOM desconectado não são impressões. Até três tentativas do mesmo recibo; recarregar a página gera nova entrega. Falta de IntersectionObserver impede contabilizar impressões/cliques cobrados.

Clique só pode gerar contagem/cobrança após recibo válido de impressão visível. Clique rápido sem esse recibo abre o destino, sem fabricar impressão e sem débito. Eventos sintéticos do SDK não acionam cobrança. A falha de tracking não impede navegação. Filtros de bots/prefetch e limite de 600 requisições/minuto por IP+origem são defesa adicional, não prova de humanidade; CORS não substitui validação de recibo.

CORS exato sem credenciais; chamadas form-urlencoded não exigem preflight. Respostas da API nunca entram em cache. Script pode ter cache de cinco minutos. Para CSP do consumidor liberar `https://ads.roadrunners.run` em script-src/connect-src, origem dos assets em img-src; estilos do componente são inline. O script não sobrescreve estilos globais do consumidor. O elemento expõe `data-rr-ads-status` (loading/served/empty/error).

Referências das APIs de navegador: [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CORS), [Intersection Observer](https://developer.mozilla.org/en-US/docs/Web/API/Intersection_Observer_API).

## Banco e publicação

Migration `_codex/sql/2026-11-04_ads_publisher_network.sql`: só schema ads. Novas tabelas/funções de inventário, autorização e entrega; extensão restrita dos quatro contratos de banner (validação, seleção CPC, save CPC e save HOUSE). Guardas verificam os fingerprints das definições de produção antes de substituir. Não altera `public`, ledger ou campanhas existentes. `public.tb_usuarios` é consultada para autorização, nunca modificada.

O runtime é compatível com a fase anterior à migration: inventário mostra aviso e seletor mantém o spot atual do RoadRunners. Aplicar a migration por conexão DBA; o datasource de aplicação não permite DDL.

Instalações que aplicaram a primeira versão também precisam de `_codex/sql/2026-11-04_ads_publisher_network_business_permission.sql`. Ela concede somente EXECUTE nas duas funções de cadastro à role existente `ads_business`; as funções continuam validando administrador global e recusando delegação. A migration principal já contém esse grant para instalações novas. A interface verifica a permissão efetiva antes de liberar os formulários.

Ordem: testar SQL isolado; backup e compilar CF; aplicar migration; publicar arquivos próprios; configurar DNS do ads.roadrunners.run no mesmo servidor; obter certificado do novo domínio; configurar vhost específico `_codex/deploy/ads-network.apache.conf`; testar API e embed em domínio autorizado. O certificado deve ser emitido usando conta ACME existente e desafio HTTP-01 sem expor arquivos internos. Não copiar chaves/certificados de outro domínio. Se o domínio estiver sob Cloudflare, usar o mesmo bloco RemoteIPTrustedProxy do vhost de API já instalado, nunca confiar genericamente em X-Forwarded-For.

Rollback: restaurar somente arquivos do manifesto da tarefa e retirar somente o novo vhost. Manter os objetos SQL aditivos e registros de inventário/histórico. Não executar DROP em dados nem reverter ledger. O seletor antigo do RR continua limitado ao seu placement.

## Verificação

- `node _codex/scripts/test_ads_publisher_network.mjs`: PostgreSQL temporário via socket, fixtures sintéticas, rollback/encerramento verificado. Testa permissões, origens, versão, aprovação, regionalização, page scope, cobrança única, impressão obrigatória, HOUSE fallback e alteração de spot.
- `node _codex/scripts/test_ads_network_sdk.mjs`: SDK com DOM/rede sintéticos, visibilidade, imagem quebrada, aba oculta, repetição, clique sintético e entrega vazia.
- Compilar templates com ColdFusion do servidor em candidato privado, sem tocar runtime.
- Conferir desktop/mobile da interface, usuário sem permissão, resposta da API sem Origin/spot/token, CORS exato, HTTPS, carregamento externo e ausência de campanhas reais modificadas pelos testes.

Os baselines SQL usados nos testes são definições capturadas em leitura de produção, sem dados de clientes, preservadas em `_codex/tests/publisher-network-baseline/`.

## Estado da entrega em 04/11/2026

- Publicados e conferidos por SHA-256 os 20 arquivos de runtime do escopo. A aplicação pública está em seu document root isolado, ainda sem vhost exposto.
- Backups recuperáveis: `/var/backups/ads-network-20261104-csb4jt9i/baseline` e, para a correção posterior do include condicional HOUSE, `/var/backups/ads-network-20261104-8_5kf2j2/baseline`.
- Testes PostgreSQL e SDK aprovados; 18 templates compilados, mais recompilação da correção HOUSE. Formulários conferidos em desktop e mobile com dados sintéticos. Páginas autenticadas de banners pagos, HOUSE e inventário conferidas em produção sem criar campanhas, aprovar anúncios ou movimentar saldo.
- Migration principal e SQL complementar aplicados pelo usuário e confirmados na aplicação. Cadastro e edição de site/spot realizados com sucesso pelo formulário real. A verificação efetiva de permissão impede liberar formulários caso falte algum grant.
- DNS configurado pelo usuário, certificado emitido e vhost HTTPS isolado ativo. Script público responde 200 com hash idêntico ao publicado; TLS direto na origem validado. Arquivos internos, métodos, origem ausente/não cadastrada e token malformado rejeitados; nenhuma resposta de teste criou cookies.
- Certificado válido até 02/02/2027. Renovação pelo agendamento existente `snap.certbot.renew.timer`; hook específico `/etc/letsencrypt/renewal-hooks/deploy/ads-network-apache` testa e recarrega o Apache somente para esse certificado. Backup do vhost: `/var/backups/ads-network-vhost-20261104-r_tbkef3`.
- Templates de readiness recompilados e publicados, backup `/var/backups/ads-network-20261104-wnotoc_g/baseline`. Teste completo PostgreSQL repetido com criação de site/spot sob `SET ROLE runner`, incluindo rejeição de ator não administrador e de delegação: aprovado.
- Corrigido também o processamento do formulário antes do HTML: `backend.cfm` executa no início de `index.cfm`, sob `cfsilent`, permitindo o redirect 303 e a confirmação `Cadastro salvo.`. Dois templates compilados e publicados; backup `/var/backups/ads-network-20261104-47n6d9p1/baseline`.
- Teste real entre domínios concluído no Chrome: página temporária HTTPS do Business carregou `https://ads.roadrunners.run/sdk/v1.js` e recebeu `empty` para site/spot autorizados sem campanha. Botão de copiar código confirmado. Após inativar o inventário, nova chamada foi rejeitada. Nenhuma campanha criada/aprovada e nenhum saldo movimentado; a exibição de uma peça real nesse novo domínio permanece dependente do cadastro de campanha para um spot real.
- Inventário técnico preservado inativo para auditoria: site `validacao-integracao-20261104` (`72f57feb-6270-433d-87da-54444a43c858`), spot `integracao-teste` (`44a00473-3d69-4661-928d-53a8caef2a58`). Página HTML temporária removida e ausência conferida.
- Navegador/servidor temporários e PostgreSQL de teste encerrados e conferidos. Nenhuma alteração no runtime RoadRunners, nem commit/push.

## Teste real LiveRunners — 04/11/2026

- Página publicada: `https://liverunners.roadrunners.run/publicidade-demo/`. Fonte no consumidor: `LiveRunners/frontend/public/publicidade-demo/index.html`; não altera a home nem exige reinício. Usa somente a div de inventário e o SDK público `https://ads.roadrunners.run/sdk/v1.js`.
- Site `liverunners` (`b8acc4a3-6a25-4427-a093-1cd195df4b6e`), spot `demo-banner` (`72f8357b-8168-4ab7-af48-a5615f7ff150`), placement `717bcc17-0aff-44a4-a450-b9af92500df7`. Criados pelo formulário autenticado.
- Campanha HOUSE `299a6236-7e69-43cd-b2b2-65c4b1288b04`, “Live! Run XP — teste LiveRunners”. Cópia de mídia existente, sem alterar a campanha original. Ativa até 05/11/2026 23:59 America/Sao_Paulo. Destino real: `/circuito/live-run-xp/` no RoadRunners.
- Chrome real: banner carregado, clique levou ao destino. Conferência SQL somente leitura e painel autenticado coincidem: **3 entregas, 3 impressões visíveis, 1 clique válido, custo 0, nenhum registro em credit_ledger**. Impressão registrada após 1 segundo; todos os eventos HOUSE não faturáveis. Evidências locais em `_codex/staging/ads-network-real-banner-20261104/`.
- A automação não aplicou a largura mobile solicitada (continuou em 1533 px); a validação visual mobile desta página permanece pendente. Overrides foram resetados. Não apresentar as capturas como mobile.
- Falha encontrada no cadastro HOUSE: processamento após HTML impedia o redirecionamento e permitia reenvio ao recarregar. Backends movidos para o início do index, sob `cfsilent`, antes de renderizar. Corrigidos também os `&amp;` literais nos URLs de `cflocation`. Nenhuma regra de aprovação ou cobrança alterada.
- Rascunho duplicado durante a verificação (`88a9faf4-f0e2-4114-949e-9f18a68cd1d1`) encerrado pela interface e excluído da veiculação, sem apagamento de histórico.
- Compilação ColdFusion: 3 templates aprovados; 11 testes dos publicadores aprovados; SDK aprovado (visibilidade, aba oculta, imagem com falha, inicialização idempotente, clique confiável, inventário vazio). Rotas HOUSE e paid renderizadas em produção após a mudança.
- Backups Business: `/var/backups/ads-network-20261104-8vbv0lsx/baseline` e `/var/backups/ads-network-20261104-5ny93v75/baseline`. Manifesto LiveRunners: `/var/backups/liverunners-banner-20261104-gdd5c3zk/manifest.json` (dois caminhos novos, antes ausentes). Publicação por escopo e SHA-256 conferidos. Sem migração adicional, commit ou push.
