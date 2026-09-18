# Banners CPC — ponto de retomada, atualizado em 17/09/2026

## Estado real

**Implementação parcial; Task 1 SQL aplicada pelo operador. Task 2 integração local em andamento; runtime ainda não publicado.** A aplicação foi corroborada por leitura do log DataGrip: INSERT do marcador e COMMIT concluídos em 17/09 às 18:46:35. Nenhuma campanha/saldo foi alterado pelo agente em produção. A preferência comercial aprovada é CPC elegível primeiro, HOUSE apenas na ausência de pago elegível.

A migration `2026-09-16_ads_paid_banners.sql` está corrigida, testada e aprovada em revisão independente (spec/quality). Rerun do controlador: 11 grupos PASS, exit 0, fixture `ads-paid-banner-RtCo0j`. SHA256 `b706b0921e58d5101f341da4c62f541bcb14b9eee42a058d1d5fa2cd5270da39`. O ledger `.superpowers/sdd/2026-09-16_paid_banners_plan/progress.md` é a fonte canônica: Task1 completa; Task2 com `/root/paid_banner_workspace`, sem review final ainda; Task3/4 pendentes. Antes de publicar, preservar o rótulo localizado existente apenas em produção no banner_slot (snapshot em production-before). Trechos abaixo são histórico de 16/09 e não prevalecem sobre este estado atual.

## Histórico: arquivos preparados em 16/09

- `portal/includes/paid_banner_helpers.cfm`: DTO do formulário, valores monetários, datas com fuso de São Paulo, validação de escopo, autorização de ações/CSRF, rótulos de revisão. Usa helpers HOUSE existentes sem modificar o fluxo HOUSE. Não é incluído por nenhuma rota atual.
- `portal/includes/paid_banner_form.cfm`: formulário de imagens, destino, CPC/orçamento, período, dispositivo, páginas/UFs, envio e rascunho separados. Usa a versão esperada na edição.
- `portal/includes/paid_banner_actions.cfm`, `paid_banner_queries.cfm`, `paid_banner_backend.cfm`: adaptadores com contexto autenticado, CSRF vinculado à conta, save/submit atômico, escopo de leitura por conta, uploads validados e edição/revisão. Ainda não incluídos por rota pública.
- `portal/includes/paid_banner_home.cfm`, `paid_banner_list.cfm`, `assets/css/paid-banner-workspace.css`: painel com gráfico, saldo compartilhado, detalhes expansíveis e revisão, isolado até integração.
- `_codex/tests/paid-banner-{workspace,actions,queries,render,backend-boundary}.cfm`: **51 checks GREEN** na última execução serial desta retomada. Helpers/render reais; fronteiras de SQL simuladas nestes testes CFML, não cobrança simulada na suíte SQL.
- `_codex/scripts/test_ads_paid_banners.mjs`: PostgreSQL descartável Unix-socket-only com funções canônicas e testes reais de cobrança, orçamento, hold, revisão e concorrência. Último GREEN completo `ads-paid-banner-kmef4H`; novo teste de liberação de conta ainda pendente.
- `../RoadRunners/_codex/sql/2026-09-16_ads_paid_banners.sql`: migration ainda não liberada para aplicação; `*_preflight.sql`: inventário somente leitura; `*_contract_tests.sql`: fixture de desenvolvimento com guarda, não teste para produção.
- Desenho e plano aprovados: `2026-09-16_paid_banners_design.md`, `2026-09-16_paid_banners_plan.md`.
- Ledger/brief: `.superpowers/sdd/2026-09-16_paid_banners_plan/`. Preservado pois commits não foram autorizados.

## Evidência executada

1. Baseline HOUSE/leilão: `node _codex/scripts/test_ads_house_banner_scope.mjs`, escalado para permitir PostgreSQL local. PASS canonical, auction, scope, ownership, drift rejection e concurrent scope change. Fixture `ads-house-scope-wnzpvZ`.
2. RED formulário: falha esperada por ausência de `paid_banner_helpers.cfm`; depois GREEN, 22 checks, com comando:

   `RUNNERHUB_OFFLINE_CFML_TESTS=1 /usr/bin/java -cp '/Users/Shared/Projects/ColdFusion Certification/box' cliloader.LoaderCLIMain -CommandBox_home=/private/tmp/runnerhub-audience-cfml.j0MZzV/commandbox execute _codex/tests/paid-banner-workspace.cfm`

3. RED banco confirmado pelo controlador: `node _codex/scripts/test_ads_paid_banners.mjs --baseline`; saída `function ads.save_paid_banner_campaign(unknown, integer, integer, jsonb, boolean) does not exist`. Fixture `ads-paid-banner-f0Ln3G`. Depois, GREEN registrado pelo implementador em `task-1-report.md`: save/review/edit, preço, token, replay, estorno, corrida EVENT+BANNER sobre saldo insuficiente, limites, chargeback hold, escopo, HOUSE e drift. Duas verificações iniciais de preflight e o novo teste de liberação após aprovação da conta foram adicionados depois; exigem rerun.
4. `node --check _codex/scripts/test_ads_paid_banners.mjs` passou. Sem publicação, compile Adobe CF de produção ou validação visual do novo formulário em página real.

## Próximo trabalho, nesta ordem

1. Manter os testes PostgreSQL seriais e escalados; não apagar IPC alheio. O recurso antes bloqueante já não consta do inventário.
2. Implementador SQL retomado: RED reproduziu tanto conta aprovada permanecendo WAITING quanto banner PENDING sendo rebaixado. Finalizar correção guardada e GREEN, obter revisão do diff da rodada 1 e rerun independente. Não liberar migration incompleta.
3. Integrar os includes preparados à rota Business, preservar HOUSE explícito e links legados, adicionar menu de conta e filtrar EVENT nas consultas/ações antigas de Ads. Acrescentar identificação do tipo ao extrato. Revisar e validar queries contra banco real, uploads, matriz de acesso e Adobe CF.
4. RoadRunners: flag por ambiente desligada por padrão, seleção paga antes de HOUSE, receipt/endpoints conforme billing real; preservar renderização e dois spots EVENT.
5. Verificar tudo, entregar migration para aplicação pelo operador, preparar baseline/backup/publicação com gate de banco. Não publicar nem habilitar um produto financeiro incompleto.

## Decisões de execução

- Trabalhar nos checkouts atuais sem git writes, conforme AGENTS e preferência do usuário; custo: menos isolamento, mitigado por novos arquivos e comparação estrita antes de publicar.
- Preservar artefatos/ledger sem limpeza final, pois não há commits para recuperação; custo: arquivos de trabalho locais retidos.
- Preparar helpers/form isolados enquanto banco era construído, sem declarar integração pronta; custo: eventual adaptação ao contrato final.

## Observação de ambiente de teste

A primeira tentativa sandbox de initdb deixou um segmento IPC sem anexos, 56 bytes, ID 18022404, chave 0x14a78100, correspondente ao erro desta tarefa. Somente esse segmento temporário foi removido; nenhum dado de banco foi apagado. Depois, os testes escalados funcionaram. Rodar próximos harnesses locais com escalada para não repetir a falha; não alterar sysctl ou limpar segmentos alheios.

Na retomada, a última tentativa falhou antes de carregar SQL por esgotamento dos 32 IDs. O segmento ID23986180/CPID89092/chave0x14a87c29 não pôde ser atribuído com certeza à tarefa; permaneceu intacto. O implementador SQL está disponível como `/root/paid_banner_sql`; o revisor `/root/paid_banner_sql_review`. Relatórios e diff imutável estão no ledger do plano.

A revisão independente terminou: **Needs fixes**, confirmando a transição ausente e o risco de o refresher antigo rebaixar BANNER pendente para WAITING. Nenhum outro defeito financeiro bloqueante foi encontrado na revisão estática escopada. A revisão também apontou que sleeps fixos não provam a espera pelos locks nos testes concorrentes. Próxima rodada deve levar esses achados ao implementador original e obter nova revisão do diff de correção. A última execução serial dos cinco testes CFML terminou com 51 checks e exit 0.
