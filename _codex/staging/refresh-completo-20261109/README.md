# Renovação das fontes — 09/11/2026

**Em andamento, dependente da carga BI do DBA.** Recorte mantido em01/01–30/09/2026 e comparáveisJan–Set2025. A edição publicada continua41/run233 e a narrativa pública239. Nenhum runtime, produto, regra de acesso ou view foi trocado nesta rodada.

## Feito e conferido

- Fonte corrente lida do notebook:297 células,174SQL, conteúdos/revisões/hashes preservados em `notebook-before.json` e `sources/`.
- 33 execuções completas e congeladas:267–299. Recibos267–298 em `runs/`;299 em `freshness-audit-receipt.json`. Auditoria final confirma statusok, frozen=true e truncated=false de todas.
- Novas coletas de perfil, atividades, mapeamento, cobertura, preços em preparação, cadastro de maratonas, referênciasJan–Set2025/2024, gerações históricas e calendário2025. Agregação377 passou da revisão1 para2 e soma exatamente os novos nove meses. Critérios analíticos preservados.
- Maratonas: novos inventários2025/2024 e contexto2025. Saídas293–295 de434/436/441 são **sondagens dos41IDs históricos**, não uma seleção renovada. Não promovê-las sem revisar a seleção e suas exclusões.
- Nova auditoria454 rev1/run299 está na seção63, “2026 — Fontes BI do DBA”. Conservação porID e deltas registrados no banco.
- Nota419 rev3 registra progresso, bloqueio e sequência. Central atualizada emorganizar/liberacao pela sessão autenticada do Chrome, mantendo responsáveis/observações anteriores e nenhuma etapa validada.
- `audit-final.json` confirma que as demais295 células originais e todos os ponteiros/publicações permanecem intactos. Nenhuma alteração de consulta do DBA foi sobrescrita.

## Dependência do DBA

Solicitação objetiva: **renovar a carga original de `public.tbbi_fat_perfil_br_2026` e dimensões pertinentes, mantendo o corte até30/09/2026 e as regras acordadas, ou fornecer o SQL/nome da rotina de carga.** A rotina não está nas células, funções do banco ou arquivos locais pesquisados.

Auditoria299, capturada09/11 às15:55, em snapshot único:

| Medida | IDs |
|---|---:|
| FatoBI atual |4.502.542|
| Operacional elegível |4.572.000|
| Comuns |4.501.814|
| Novos no operacional |70.186|
| BI fora da elegibilidade atual |728|
| Mesmos IDs com data divergente |170|

Dos728, uma sondagem anterior encontrou585 IDs removidos dos resultados e143 eventos com data movida para foraJan–Set. Não basta acrescentar os novos; a carga precisa reconciliar exclusões e mudanças. A fonte operacional recebe alterações durante a coleta. Não misturar contagens de instantes diferentes nem supor que `vwbi_fat_perfil_br_2026` renova a tabela física.

Não alterar a fato compartilhada com uma carga inferida. Preservar backup recuperável, regras/estrutura/permissões e confirmar os critérios da rotina antes de executá-la. Não contornar o bloqueioCREATE/ALTER do datasource. Inventário adicional em `../vinculos-refresh-20261109/bi-refresh-inventory.md`.

## Sequência para retomar

1. Após a carga, reler revisões atuais e repetir a auditoria454 e conservação413. Conferir elegibilidade,IDs,dimensões,idades/gerações,meses e localidades.
2. Renovar fontesBI343/350/351/353/357/359/378/368/384 e fontesBI do vertical. Capturar ambos calendários novamente caso o intervalo de carga tenha alterado os dados operacionais.
3. Gerar novas revisões380,387,414,251,420 e418 por `build_candidate.py`; salvar com versão esperada, executar e congelar. Não reexecutar387 literal antigo supondo que ele repareia dados.
4. Validar os números, camposNULL, universo e proveniência. Manter Floripa402/run210 exclusivamente no desempenho específico, sem sobrepor totais nacionais/coorte. Anual permaneceDRAFT, preços/CNA/ritmo42/cadastro em revisão. O congelamento418 é selecionado porlatest no anual interno; coordenar sua execução.
5. Atualizar coordenadamente view pública, pins, guardas de proveniência no serviço/leitor, leitoresBusiness/imprensa,fixture pública, kit/release/textos. `media_builder/` recebe explicitamente o novo payload e proveniência; não importa números antigos. Respeitar o holdTeams em qualquer deployRoadRunners.
6. Maratonas exige revisar novas candidatas/decisõesCR e atualizar também os literais narrativosJS deBoston/cenários/pares; ver `marathon-refresh-map.md`. Não gerar novo PDF antes da aprovação da versãoweb.

O principal anual2025 continua na edição dinâmica já publicada. `principal-2025-refresh-map.md` explica por que reexecutar249 não renova integralmente suas famílias. FontesJan–Set novas não substituem seus denominadores anuais.

## Ferramentas/evidências preparadas

- `inspect.py`, `collect.py`, `save_collect.py`: operadores com revisões/hashes esperados e recibos; não alteram publicação.
- `build_candidate.py` + `build_support/`: projeção completa preservando contrato17;13 testes offline e reprodução exata dos608 pares antigos.
- `media_builder/`: kit independente com17 arquivos,PDF7páginas,10artes+2aliases,HTML/TXTs e6 testes. Fixtures sintéticas são candidatas, nunca publicar.
- `runner-candidate/`:11 controles naengineCF real descartaram a hipótese de truncamento800KB;JSON4,5MB preservado e limites reais1000linhas/100colunas/5MB funcionando. Nenhum patch no runner.
- `audit-final.json`:33 congelamentos completos, note419v3, célula454nova,377v2, produtos/destinos/view públicos preservados,0 etapas validadas.
- `qa/central-renovacao-fontes.png`: registro salvo na central. Nenhum convite, mensagem ou divulgação foi enviado.


## Continuação — rotina do DBA recebida em09/11 às16h

A dependência de encontrar a rotina foi resolvida. Original e adaptação estão no notebook, células455–458 da seção63; nota419rev4. A nova dependência é executar integralmente `_codex/sql/2026-11-09_renovar_estudo_q3.sql` numa conexãoDataGrip limpa. CREATE/ALTER/DROP/GRANT continuamFALSE no datasourceCF, conformeflags lidos semcredenciais.

SQL finalSHA256 `46cf49e20c5598fe5ae26e82900d44ae97c05309e3e6965664dab6fd4f54e4df`. Cria versão aditiva emestudo; nove meses/umsnapshot; troca os dois adaptadores só após asserts. Produtos e JSONs publicados permanecem antigos até aremontagem. Nenhum SQL de carga foi executado por esta tarefa.

Pré-checkreadonly:4.573.104IDs,0duplicados/0missingdate; funções/contratos correntes conferidos. SELECT compilado com20colunas e amostra1000IDs única/elegível.9testesestáticosPASS e revisão independente. Sourceblocks degeração2argsvs4args diferem509.932participaçõesnesta fotografia; quatroargumentos conservados. Ver `dba-load-review/README.md`, `dba-load-candidate/README.md`, `dba-handoff-audit.json`.

Central:organizar/liberacaoatualizadas pela sessão autenticada; responsáveis e histórico preservados. Aba temporária283510116encerrada e ausência confirmada; nenhuma aba pessoal fechada. Screenshotválida `qa/central-carga-dba.png`; captura comclip descartada por falha de render.
