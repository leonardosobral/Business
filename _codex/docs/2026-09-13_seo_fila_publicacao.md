# Fila SEO no Portal de Conteúdo — publicação de 13/09/2026

Publicado no Business às 19:24:35 UTC (16:24 de Brasília); hashes e metadados conferidos novamente às 19:28:27 UTC após os testes no navegador.

Acesso: [SEO e correções](https://business.roadrunners.run/portal/conteudo/?visao=seo), pelo botão em [Conteúdo das provas](https://business.roadrunners.run/portal/conteudo/). Somente administradores, com a decisão de acesso já existente.

## Comportamento

- Sete frentes revisadas, duas de prioridade alta. O item SH-01 aparece nos filtros dos dois sites, mas conta uma única vez no total global.
- Filtros GET por site e prioridade; detalhes com evidência, impacto, responsável pela frente, critério de conclusão e links públicos.
- Resumo dos dois pilotos separa falhas de coleta e avisos nas páginas, com descoberta parcial RoadRunners explícita.
- Fila de consulta baseada na revisão de 13/09/2026 às 15:27 de Brasília. A tela não altera status, dispara crawl, consulta banco novo nem lê os relatórios privados locais. Não há sincronização automática.
- O fluxo original de completude das provas continua em `/portal/conteudo/`. A opção `visao=seo` seleciona um include fixo, sem usar parâmetros como caminho.

## Arquivos publicados

1. `portal/includes/seo_queue_data.cfm`: dados curados da fila e dos pilotos.
2. `portal/includes/seo_queue_backend.cfm`: filtros em memória e validação de URLs.
3. `portal/conteudo/seo.cfm`: apresentação responsiva protegida.
4. `portal/conteudo/index.cfm`: seleção da visão SEO.
5. `portal/conteudo/home.cfm`: acesso pelo painel existente.

Os dados curados estão em um include CFML protegido e não em um JSON para download. Relatórios brutos e observações continuam fora do docroot. Nenhum arquivo RoadRunners/OpenResults foi alterado nesta entrega de tela. Sem alteração de permissões, credenciais, SQL, cron ou reinício de serviço.

## Validação

- Lucee local isolado com templates reais e guarda administrativa original: 108 assertivas de contrato/filtros; 12 cenários incluindo seis recusas de acesso, renderização completa/filtrada/vazia, escape HTML e rejeição de sete URLs perigosas. Os números 1.090 e 33.096 são verificados no HTML.
- Adobe ColdFusion de produção, em staging privado: cinco templates compilados com sucesso antes da publicação.
- Navegador autenticado: acesso de Conteúdo para SEO e retorno; sete frentes; OpenResults/P1 vazio e OpenResults/P2 com apenas OR-01; detalhes abertos.
- Desktop 1415 px e celular 390 px, incluindo detalhes e URL longa, sem transbordamento horizontal. Viewports temporários restaurados. A fila completa ficou aberta em uma aba de entrega.
- HTTP anônimo: rota principal retorna 302 para `/`; view e dois includes retornam 403, sem dados da fila. Casos de usuário não administrador foram executados no harness com a guarda real, não por alteração de contas de produção.
- A view emite `Cache-Control: private, no-store`. O harness CLI não comprova códigos HTTP nem POST porque CGI é readonly; não foram simuladas sessões no servidor público.
- Revisão independente Astra sem achados materiais; `git diff --check` aprovado.

Comando local: `node _codex/scripts/test_seo_queue_cfml_local.mjs`. Reutiliza Java/CommandBox já instalados; não instala software nem acessa produção.

## Backup e recuperação

Host `ssh.runnerhub.run`, raiz `/var/www/business.roadrunners.run`. Backup privado: `/var/backups/business-seo-screen-20260913.1igzwy3v`.

O baseline dos dois arquivos substituídos coincidiu com a cópia local anterior. Os três arquivos novos estavam ausentes. O publicador conferiu novamente todos os hashes antes das substituições, guardou o conteúdo anterior, preservou dono/grupo/modo e verificou cinco hashes finais. Oito arquivos de autenticação, estrutura e backend de KPIs permaneceram com os mesmos hashes.

Recibo com hashes, metadados e checagens: [2026-09-13_seo_fila_publicacao.json](2026-09-13_seo_fila_publicacao.json). Para reverter, conferir os hashes atuais contra o recibo, restaurar `index.cfm` e `home.cfm` do backup e remover apenas os três arquivos novos que ainda correspondam ao lote. Não restaurar diretórios completos nem alterações posteriores.

## Atualização da fila

Após nova auditoria e revisão, atualizar juntos medições, datas, evidências e itens em `seo_queue_data.cfm`. Cada site agora possui `auditLabel` próprio; a view não usa data fixa. O campo `resolved` indica frentes concluídas, que permanecem consultáveis nos filtros e deixam de contar como pendências. Preservar as diferenças entre coleta parcial e completa; não encerrar uma frente sem verificação após a correção. Executar os testes e publicar o lote atualizado com o mesmo procedimento restrito. Estados editáveis e ingestão automática podem ser acrescentados em uma entrega própria. A [recuperação do inventário](2026-09-13_seo_descoberta_execucao.md) documenta a rodada posterior com 99.360 URLs RoadRunners.
