# Plano - Home logada para contas Business

## Objetivo

Transformar o Dashboard de usuarios de conta em uma home operacional, parecida com a home do WordPress: ao entrar, o usuario entende o estado da conta, identifica pendencias e segue para as telas detalhadas.

## Regras

- Admin real, sem simulacao de conta, pode continuar vendo blocos administrativos enquanto essa home admin nao for redesenhada.
- Admin simulando uma conta pelo seletor do topo deve ver a mesma home de conta que um usuario comum.
- Usuario comum (`is_admin = false`) deve ver apenas informacoes da conta efetiva e a secao de BI liberada por permissao.
- Todos os dados da home de conta devem respeitar `VARIABLES.businessEffectiveAccountIds`.
- A home deve ser um resumo; a acao detalhada fica nas telas especificas.

## MVP

- [x] Definir o escopo da primeira versao da home de conta.
- [x] Manter blocos administrativos fora da visao de usuario comum e fora da simulacao de conta.
- [x] Criar cabecalho da conta ativa/simulada.
- [x] Criar cards de resumo: eventos ativos, proximas provas, usuarios da conta, saldo de ads e pendencias.
- [x] Criar bloco "Proximas provas" com atalhos para eventos e ads.
- [x] Criar bloco "Completar conteudo" com provas que precisam de descricao, inscricao, categorias, organizador, local ou imagem.
- [x] Criar bloco de marketing com campanhas, credito e vouchers.
- [x] Preservar a secao de BI abaixo dos resumos.

## Depois do MVP

- [x] Evoluir indicadores comerciais de venda/ads sem expor metricas tecnicas de site ou infraestrutura.
- [x] Refinar home admin separada, com indicadores internos em vez dos cards legados atuais.
- [x] Criar testes manuais documentados para admin real, admin simulando conta e usuario comum.

## Fontes de dados previstas

- Conta e permissao efetiva: `includes/backend/business_account_context.cfm`.
- Vinculo conta-evento: `tb_conta_eventos`.
- Cadastro de eventos/conteudo: `tb_evento_corridas`.
- Usuarios da conta: `tb_conta_usuarios`.
- Solicitacoes de vinculo: `tb_conta_evento_solicitacoes`.
- Vouchers de credito: `tb_ad_vouchers`.
- Campanhas de ads: `tb_ad_eventos`.
- BI liberado: `qPermissoes`.

## Observacoes

- A home Business e voltada para clientes. Nao exibir erro, 404, logs tecnicos, disponibilidade, performance de infraestrutura ou performance geral do site.
- A home Business nao deve consultar `tb_log` ou `tb_busca_log`; essas leituras ficam restritas a telas internas/admin do Portal.
- A home Business tambem evita agregacoes pesadas em `tb_ad_log`; performance detalhada de anuncios fica em `/ads/`.
- Os indicadores comerciais da home usam fontes leves: credito/vouchers, campanhas ativas, orcamento planejado, limite diario ativo, proximas provas e pendencias de conteudo.
- A home admin real tambem deve ser leve: nao carregar widgets externos ou varreduras de logs na entrada.
- Indicadores futuros devem priorizar inscricoes, cupons e conversao quando houver fonte confiavel e multi-evento.
- A area de BI permanece dependente das permissoes existentes em `qPermissoes`.

## Testes manuais

### Admin real sem simulacao

- Entrar em `/` sem conta selecionada no topo.
- Deve exibir o painel "Admin interno" com indicadores de contas, usuarios, eventos, solicitacoes e campanhas.
- Nao deve renderizar a home de conta nem depender das consultas legadas de manutencao que varriam logs.
- Deve manter atalhos para `/administracao/contas/`, `/eventos/`, `/ads/` e `/portal/conteudo/`.

### Admin simulando conta

- Selecionar uma conta no seletor do topo e voltar para `/`.
- Deve exibir "Dashboard da conta", com dados restritos a `VARIABLES.businessEffectiveAccountIds`.
- Nao deve exibir o painel "Admin interno".
- Deve ter o mesmo comportamento visual e de dados de um usuario daquela conta.

### Usuario comum com conta ativa

- Entrar em `/` com usuario `is_admin = false` vinculado a conta ativa.
- Deve exibir a home de conta com eventos, pendencias de conteudo, saldo/credito e campanhas.
- Nao deve exibir cards administrativos, logs, erro/404, uptime ou metricas tecnicas do site.
- A secao de BI so aparece quando houver permissao em `qPermissoes` com `tipo = 'bi'`.

### Usuario comum sem conta ativa

- Entrar em `/` com usuario logado sem vinculo ativo em `tb_conta_usuarios`.
- Deve exibir aviso de acesso Business em analise e CTA para `/cadastro/`.
- Nao deve exibir dados de outra conta nem cards administrativos.
