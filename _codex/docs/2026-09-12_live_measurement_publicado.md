# LIVE! — correções de cadastro e mensuração

Data: 12/09/2026. Continuação autorizada pelo usuário com “Prossiga”.

## Estado da entrega

**Publicado e validado em produção em 12/09/2026.** Cadastros corrigidos e conferidos na página pública. Código aplicado aos dois checkouts e aos dois sites, aprovado em revisão, testes e compilação Adobe CF. A validação real recebeu **1 sessão, 2 páginas vistas e 1 saída para a inscrição de Tamboré**, com Barueri/SP e ID 45368 no relatório. A campanha Google Ads continua com a configuração salva anteriormente: uma Smart, 16 cidades, R$ 20/dia no total. Nenhuma alteração adicional de orçamento ou ativação da Performance Max nesta continuação.

## Cadastros corrigidos

Alterações feitas na interface autenticada Business, usando “Salvar Dados Básicos”, com conferência posterior na página pública do circuito. Preservados tags/URLs, links de inscrição e demais campos.

| ID | Antes | Depois | Dados preservados |
|---|---|---|---|
| 37536 | LIVE! RUN XP Santo André 2026; cidade Santo André | LIVE! RUN XP São Caetano do Sul 2026; cidade São Caetano do Sul/SP | 27/09/2026; tag `2026-live-run-xp-santo-andre-2026` |
| 40833 | Rio de Janeiro: início e término 15/11/2026 | Início e término 02/11/2026 | Nome, Rio de Janeiro/RJ, Aterro do Flamengo; tag `2026-live-run-xp-rio-de-janeiro-2026-21k` |
| 37570 | Fortaleza: início e término 15/11/2026 | Início e término 20/11/2026 | Nome, Fortaleza/CE; tag `2026-live-run-xp-fortaleza-2026-ii` |
| 45368 | Tamboré aparecia como cidade; seletor municipal sem valor válido | Município Barueri/SP | Nome LIVE! RUN - TAMBORÉ 2026, 11/10/2026 e endereço Shopping Tamboré |

O evento Tamboré exigiu selecionar “Todas as contas”, opção administrativa já disponível no perfil autenticado; não foi alterado vínculo de conta do evento. Não foram editadas as outras etapas homônimas de Rio de Janeiro e Fortaleza.

Após a correção, a conta Live! foi restaurada, mas o relatório global retornou “Acesso restrito” nesse contexto. Para conferir a audiência, foi novamente selecionada “Todas as contas” pela interface administrativa. Não houve alteração de perfil, regra de acesso ou autenticação.

Referências oficiais conferidas antes da edição: [calendário LIVE!](https://liverun.com.br/calendario), [Rio](https://www.liverun.com.br/etapa/live21k-rio-de-janeiro-2026), [Fortaleza](https://www.liverun.com.br/etapa/live21k-fortaleza-2026), [Tamboré](https://www.liverun.com.br/etapa/live-run-alphaville-2026). Resultado público conferido em [Circuito LIVE! no Road Runners](https://roadrunners.run/circuito/live-run-xp/).

A revisão separada de distâncias/modalidades e o vencimento administrativo do cupom não foram modificados. A validade comercial do ROADRUNNERS para todas as etapas de 2026 foi confirmada explicitamente pelo usuário.

## Contrato da mensuração

O Road Runners mede visitas e intenção de inscrição: `outbound_click`, `contentType=event`, `contentId` da prova e chave persistida `outbound_click:live_registration:<id>`. O Business deve apresentar sessões por campanha e sessões por campanha × prova/cidade, deduplicando saídas por sessão/prova e o total da campanha por sessão. A cidade é a da prova, não a localização física do visitante.

Uma saída não comprova carregamento no destino, inscrição ou pagamento. O mesmo cupom em vários canais não comprova atribuição ao Google. Inscrições e comissão de 10% sobre o valor efetivamente pago continuam dependentes da planilha conciliada da LIVE!. Não atribuir o valor integral da inscrição como receita do Road Runners.

A coleta começa com a publicação; não reconstruir cliques anteriores. Uma UTM nova durante sessão ativa mantém a atribuição original até o encerramento da sessão por inatividade. GPC e recusa de analytics devem continuar respeitados.

## Implementação e validação

- RoadRunners: 7 arquivos runtime e 5 arquivos novos de documentação/testes. Coleta nos quatro CTAs de inscrição (modal, principal, barra e edição aberta), allowlist de hosts LIVE! e família de página `circuit`. [Contrato do produtor](/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/docs/audience-live-registration.md).
- Business: 4 arquivos runtime, incluindo consulta e seção novas. Sem migration. [Definições e testes do relatório](/Users/Shared/Projects/RunnerHub/Business/_codex/docs/2026-09-12_audience_live_journey_business.md).
- Produtor: 74 testes Node, contratos CFML LIVE/editorial e 8 cenários Chrome com CTAs reais renderizados em 1280/390 px aprovados.
- Consumidor: 28 verificações SQL, 15 verificações CFML renderizadas e browser em 1440/390 px aprovados. Regressões: SQL 51, home CFML 11, gráficos Node 5.
- Revisão independente sem achados críticos/importantes; repetiu Node LIVE (7), contrato CFML, render Business (15) e SQL LIVE (28). `git diff --check` aprovado nos arquivos alterados desta tarefa.
- Compilação privada no Adobe ColdFusion de produção: **successful 9 / total 9**, retorno 0, sem executar a aplicação por HTTP. Diretório `/var/tmp/rr-live-compile.hqz9bqb6`. O pacote contém 11 arquivos runtime; JS e SQL não são templates CFML. [Recibo de compilação](/Users/Shared/Projects/RunnerHub/Business/_codex/staging/live-measurement/private-compile-result.json).

O candidato de `evento/index.cfm` preserva dois blocos de sidebar/footer presentes em produção e ausentes no checkout. `circuito/index.cfm` também divergia, mas ficou intacto. Nenhuma alteração preexistente de Ads/CPC ou sidebar foi incluída no lote.

Limite herdado: uma mesma página mantida aberta após rotação de sessão pode suprimir o segundo clique da mesma prova, por deduplicação ligada à identidade da página. Foi reproduzido, documentado e aceito na revisão. Recarregar/navegar cria outro contexto; o relatório deduplica revisitas da mesma sessão. A medição não equivale a cobertura completa.

## Publicação e verificação em produção

Release privado: `/var/backups/rr-live-measurement.9ceb5386ee32`. Manifesto: [11 arquivos runtime](/Users/Shared/Projects/RunnerHub/Business/_codex/staging/live-measurement/release/runtime.tsv). Publicador revisado: SHA `512feca9b058db452dd6cb2189e813055f671a657d3b4a36975c2d4a97521d04`.

- Preparação: 9 backups de arquivos existentes e ausência confirmada dos 2 novos; 106 itens protegidos.
- Publicação e verificação final: retorno 0, fase `published`, 11 hashes/metadados conferidos, 106 itens protegidos inalterados, nenhum conflito de rollback. [Recibo final](/Users/Shared/Projects/RunnerHub/Business/_codex/staging/live-measurement/remote-verify-result.json).
- Ordem: SQL/partial Business, backend/home Business, serviço/JS RoadRunners, quatro superfícies CTA, bootstrap por último.
- Permissões e proprietário dos existentes preservados; mtime atualizado para o ColdFusion reconhecer os templates alterados. Novos arquivos 0644, root:root. Backups conservam os metadados originais. Sem SQL de alteração de esquema, reinício, commit, branch ou mudança de configuração.
- Publicador passou 15 testes offline, inclusive falha parcial/rollback, concorrência, criação exclusiva dos novos, hash alterado, symlink, filesystem diferente e hardlinks nos guardas. Uma primeira preparação abortou antes de modificar o site porque `config/audience.local.cfm` é arquivo regular com 2 hardlinks. A correção limitou a aceitação de hardlinks à leitura dos guardas; candidatos, backups e alvos continuam estritos. Configuração não foi lida em logs nem alterada. O recibo da tentativa abortada foi preservado.

Fluxo real em navegador separado, sem login e com identificação de teste: URL de circuito com `utm_source=qa`, `utm_medium=manual`, `utm_campaign=live_medicao_validacao`, `utm_content=teste_controlado`; abriu a prova de Tamboré, depois o modal e o CTA “Utilize este cupom”. O DOM confirmou ID `45368`, destino `https://www.appliveexperience.com.br/evento/live-run-alphaville-2026` e script `/assets/js/rr-audience.js?v=62bc8dc568f4`.

Na interface autenticada Business, a recepção de **12/09 15:39 (Brasília)** confirmou 1 sessão, 2 aberturas no Road Runners, 1 sessão qualificada, 1 visita à prova e 1 saída; detalhe “LIVE! RUN - TAMBORÉ 2026 — Barueri/SP — ID 45368”. A campanha de QA fica separada de `google/cpc`; os percentuais dessa visita de teste não são desempenho de mídia. Não houve compra, reserva ou submissão no parceiro, e a recepção comprova o clique de saída, não uma inscrição.

O painel foi deixado em “Todas as contas”, seção Jornada LIVE!, filtrado para `google` e `live_cupom_2026_retomada`. Nesse momento havia 3 sessões/3 aberturas com essa UTM, última recepção 13:59, anterior à publicação; nenhuma saída recebida. Esse recorte anterior não permite avaliar conversão da nova medição nem comprova cliques faturados do Google. O teste QA e o filtro Google renderizaram sem erro em produção.

Rollback disponível, se necessário: `python3 /var/backups/rr-live-measurement.9ceb5386ee32/publish.py /var/backups/rr-live-measurement.9ceb5386ee32 rollback`. O procedimento só restaura alvos ainda iguais aos hashes/metadados publicados; preserva conflitos e não apaga a telemetria coletada. Não foi necessário acioná-lo. O lock é por release: qualquer operação posterior exige conferir ausência de mudanças concorrentes nos 11 alvos.
