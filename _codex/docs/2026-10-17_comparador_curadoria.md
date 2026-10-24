# Curadoria administrativa do Comparador

A seção [Comparador → Curadoria](https://business.roadrunners.run/administracao/comparador/curadoria/) usa o login Business existente e exige administrador global. Administrador de conta, acesso delegado e simulação de conta são recusados. O novo acesso aparece na navegação interna do módulo; o menu global preexistente foi preservado.

## Operação

**Marcas:** duas escolhas independentes por marca: destaque inicial no filtro e presença comercial no Brasil. Lista alfabética com até 30 marcas por página. Salvar afeta somente a página aberta; salve antes de mudar de página. No site, só aparecem marcas com produtos públicos, e as demais opções ficam em Mostrar mais. Se nenhuma tiver destaque, o filtro mostra suas seis primeiras opções habituais. Presença da marca não comprova estoque de cada modelo.

**Página inicial:** proporção de lançamentos e produtos com oferta por ciclo, inteiros de 1 a 10 para cada fila. Padrão 2:1. Lançamentos é a fila sem oferta que prioriza datas conhecidas dos últimos 12 meses e completa com modelos anteriores quando necessário. Produtos com oferta válida entram apenas na outra fila. Filas disjuntas; quando uma termina, a outra continua. Protótipos, compra bloqueada e lançamento futuro continuam fora de Destaques.

**Histórico:** resumo humano de proporção e marcas alteradas, com administrador e data. Não apresenta o snapshot JSON ao operador.

As escolhas entram na próxima requisição pública; sem deploy ou cache a invalidar. Busca, filtros aplicados e ordenação explícita do Comparador preservam suas regras. Não há mudança nas URLs, ofertas, autenticação ou cadastros de produtos.

## Segurança e banco

`services/ComparadorCuradoriaService.cfc` autoriza todas as leituras e escritas. Mutações exigem POST, CSRF próprio, formulário completo e token SHA-256 do snapshot de configuração e de todas as marcas. Bloqueio compartilhado de marcas precede o bloqueio exclusivo do singleton. Configuração, revisão, ator/data e auditoria antes/depois são uma única transação; conflito não reutiliza o formulário antigo.

A lista paginada envia escopo explícito com no máximo 30 marcas únicas e conhecidas; campos de outra página são rejeitados e seus valores anteriores são preservados. Uma sentinela no final do formulário impede gravações quando o contêiner trunca campos por ultrapassar seu limite. Nenhum limite global do servidor foi alterado. Após erro, os valores enviados só são reutilizados se o formulário estiver completo e seu token ainda for atual. Edição concorrente exige reabrir; não se associa token novo a valores antigos nem se reutilizam checkboxes truncados.

Migração aditiva em `Comparador/codex/docs/sql/2026-10-17_comparador_curadoria.sql`; versão com guarda de produção em `2026-10-17_comparador_curadoria_producao.sql`. Tabelas `comparador.tb_home_curadoria` e `tb_marca_curadoria`, com histórico privado em `tb_cadastro_auditoria`. A instalação inicial preserva 2:1, dez destaques e quinze códigos de presença no Brasil. Seed só na criação do singleton; reexecução não desfaz escolhas. O público recebe SELECT apenas nas duas tabelas novas. A exclusão de marcas pelo catálogo considera este vínculo.

A migração em produção foi aplicada pela conexão RunnerHub/runner_dba existente no DataGrip. O datasource web recusou DDL e suas proteções foram preservadas. Verificação posterior confirmou configuração e permissões; não houve alteração em produtos ou ofertas.

## Verificação e recuperação

Testes privados usam CF2025 e PostgreSQL isolado, login sintético protegido por loopback, contexto de admin global, CSRF real, tokens antigos, limites, paginação, integridade do POST e rollback se falhar a auditoria. Testes públicos cobrem configuração vazia, independência das flags, proporções 1:2 e 3:1 e duas páginas sem repetição. Os endpoints e fixtures de teste nunca são publicados.

O deploy usa hashes anteriores, escopo de nove arquivos entre Business e Comparador, backup e gravação atômica. Em rollback, preserve tabelas, histórico e escolhas administrativas. O leitor antigo conserva seu padrão estático até a correção ser republicada. Recibo final em `Comparador/codex/docs/evidencias/curadoria-business-2026-10-17.json`.


Publicado em 17/10/2026: seis arquivos Business e três Comparador, com backup `/root/codex-backups/comparador/20261017T233441Z-business-curadoria-runtime`, sem rollback e nove hashes reconferidos. Leitor real configurado com o papel público runner (somente leitura), dez destaques, quinze códigos de presença no Brasil e padrão 2:1. Conferência da borda: HTML dinâmico.

Aprovados: 66 verificações do serviço CF2025, 232 HTTP, 20 dirigidas de erro/concorrência, 16 testes públicos, 30 verificações de navegador privado e 13 públicas. Dados originais restaurados, endpoints sintéticos removidos e navegador próprio encerrado; recursos compartilhados preservados. Nenhum commit, branch ou push criado.
