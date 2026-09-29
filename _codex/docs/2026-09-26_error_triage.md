# Acompanhamento de erros — operação e publicação

Publicado e validado em 26/09/2026 em https://business.roadrunners.run/portal/erros/.

## Uso

1. Abra Portal → Erros com acesso administrativo e clique em **Processar próximo lote**. Cada ação coleta até 200 logs dos tipos erro/404 ainda não vinculados.
2. Filtre por status, categoria ou site; abra um problema para registrar responsável, análise, proposta e evidências.
3. Use Novo → Investigando → Correção pronta → Publicado → Verificado conforme o trabalho real. Publicado exige evidências e horário efetivo; Verificado exige publicação anterior e evidências. Ignorar/reabrir manualmente exige motivo.
4. Selecione até 20 problemas e clique em **Exportar selecionados para o Codex**. O arquivo `problemas-para-codex.json` contém metadados e conteúdo técnico permitido; não dispara análise ou correção automaticamente.
5. Registre os resultados no problema. Uma ocorrência posterior à publicação reabre um problema publicado/verificado quando coletada.

Recorte inicial fixado em **19/09/2026 21:40:47, America/Sao_Paulo**. A verificação inicial processou **400 ocorrências, formando 356 problemas**. Ainda havia registros pendentes. Os totais representam os lotes processados, não todo o histórico. Logs ainda não coletados aparecem como “Ainda não processado”.

Mensagens sem identidade técnica suficiente ficam individuais. A tela permite separar/mover ocorrências com justificativa. Textos livres e segmentos de caminho não reconhecidos são omitidos na exportação; o log original continua acessível ao administrador. Salvar status registra acompanhamento, não executa correção.

Esta entrega é sob demanda; não configura agendamento, chamadas à IA ou alterações nos e-mails.

## Runtime publicado

- `portal/erros/includes/ErrorNormalizer.cfc`
- `portal/erros/includes/ErrorTriage.cfc`
- `portal/erros/includes/init.cfm`
- `portal/erros/includes/actions.cfm`
- `portal/erros/includes/workspace.cfm`
- `portal/erros/assets/triage.css`
- `portal/erros/assets/triage.js`
- `portal/erros/export.cfm`
- `portal/includes/error_log_backend.cfm`
- `portal/erros/index.cfm`
- `portal/erros/home.cfm`

Migração `_codex/sql/2026-09-26_error_triage.sql`: cria `tb_error_problem`, `tb_error_occurrence`, `tb_error_history` e `tb_error_collector` no schema public. Preserva tb_log; não altera credenciais, grants ou runtime RoadRunners.

## Verificação

46 asserções CFML aprovadas no Adobe ColdFusion e cinco guards HTTP 403; três testes Node e quatro testes Python aprovados. Compilação oficial de nove templates concluída sem erros. Inspeção responsiva de fixtures em 1440px e 390px. Produção validada por hashes dos 11 arquivos, acesso administrativo, dois lotes reais, detalhe agrupado e evento de download. Sem sessão, fila/exportação retornam 302 e include interno 403.

Comandos, a partir da raiz Business:

```sh
node --test _codex/tests/error-triage.test.cjs
python3 -m unittest discover -s _codex/tests -p test_error_triage_deploy.py
python3 _codex/scripts/test_error_triage.py service
python3 _codex/scripts/deploy_error_triage_tabs.py verify
```

O teste remoto usa aplicação temporária protegida por loopback/token e schema sintético, removidos ao final; requer SSH e autorização operacional correspondente. Detalhes em `_codex/docs/2026-09-26_error_triage_execution.md`.

## Backup e restauração

Servidor: `ssh.runnerhub.run`; raiz: `/var/www/business.roadrunners.run`.
Backup privado: `/var/backups/business-error-triage-20260926/baseline`. O diretório pai contém manifesto, candidatos e recibos. Os três arquivos preexistentes coincidiram com o baseline antes da preparação e da troca; os oito novos destinos estavam ausentes.

Para restaurar apenas este runtime, após verificar a necessidade:

```sh
python3 _codex/scripts/deploy_error_triage.py rollback
```

O restaurador recusa sobrescrever mudanças posteriores. Restaura os três arquivos antigos, remove os oito novos arquivos deste escopo e preserva tabelas/dados de acompanhamento. Não reexecute prepare sobre esta publicação; o diretório exclusivo já existe.

Nenhum commit, branch, push ou PR foi criado. A mudança local de `includes/estrutura/sidenav.cfm` não foi publicada.

## Atualização da interface em abas — 26/09/2026

A pedido do usuário, a tela passou a ter Acompanhamento, Logs e Resumo. Detalhes de problemas usam Tratamento, Ocorrências e Histórico, sem repetir a fila abaixo. Alternar abas preserva o texto não salvo e filtros; links de logs abrem Logs e paginação de ocorrências abre Ocorrências. Setas, Home e End navegam nas abas. Preferência registrada no AGENTS.md do Business.

Quatro arquivos publicados: home.cfm, includes/workspace.cfm e assets/triage.{css,js}, sob portal/erros. Banco, serviços e ações não foram alterados. Testes: 46 asserções CFML e cinco guards HTTP aprovados novamente; três testes JS aprovados; dois templates compilados sem erros. Navegador real confirmou abas, teclado, filtro de Resumo, detalhe de log, retorno à fila e preservação de texto sem salvar. Inspeção em 1440px e 390px; sem overflow horizontal da página em mobile. Nenhum status real foi alterado.

A verificação em produção identificou que os defaults de URL do backend interferiam na seleção inicial; a seleção agora é capturada antes desses defaults. O ajuste foi recompilado e republicado com novo baseline/backup.

Recibos: `_codex/staging/error-triage-tabs/` e `_codex/staging/error-triage-tabs-final/`. Backups privados correspondentes em `/var/backups/business-error-triage-tabs-20260926/baseline` e `/var/backups/business-error-triage-tabs-final-20260926/baseline`. A conferência final verificou os quatro hashes de runtime.

Para remover somente esta atualização de interface, a restauração segue a ordem inversa das duas publicações, sempre recusando alterações concorrentes:

```sh
python3 _codex/scripts/deploy_error_triage_tabs.py rollback
python3 _codex/scripts/deploy_error_triage_tabs.py rollback --initial
```

Somente depois dessas restaurações o rollback da primeira entrega, descrito acima, corresponde novamente ao baseline esperado.

## Ordenação do acompanhamento

A listagem em Acompanhamento usa última ocorrência decrescente (`last_seen DESC NULLS LAST, id DESC`), independentemente do status. Filtros e paginação permanecem iguais. Backup seletivo: `/var/backups/business-error-triage-order-20260926/baseline`.
