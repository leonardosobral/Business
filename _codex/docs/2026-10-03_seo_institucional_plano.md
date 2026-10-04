# Lote: idiomas institucionais e coerência editorial

Continuação do plano SEO/SEO para IA de 29/09, autorizada pelo pedido “prossiga com o plano”. Publicar o runtime do escopo com baseline, backup e verificação real. Não criar branch, commit ou PR.

## Escopo e critérios

1. Sobre, Ajuda e Privacidade: identificar a rota no template PT para entregar canonical próprio e o mesmo conjunto PT/EN/ES/x-default nos nove destinos públicos. Preservar todo o conteúdo e autenticação.
2. Notícias: preservar o canonical definido pelo modo editorial; omitir alternates de SEO quando o canonical selecionado é diferente do próprio. Preservar a rota para navegação entre idiomas e o noindex existente de `external_only`. Notícias próprias, resumos, canais e listagem mantêm alternates.
3. Reauditar Road Runners com 100 páginas e descoberta completa; incluir os nove destinos institucionais e seis versões das duas notícias na cobertura estratégica. Atualizar os dois snapshots do painel somente com evidências datadas e verificadas.
4. Validar regressões CFML, revisar o lote inteiro com contexto novo, compilar Adobe, publicar apenas cinco templates RR e dois snapshots Business, verificar HTML público e renderização do painel.

## Decisões

Ruling: trabalhar em staging dedicado com baseline de produção, sem Git — a instrução do usuário não autoriza branch/commit; outras frentes têm arquivos modificados.

Ruling: RR-08 permanece parcialmente pendente — o CMS público confirma `licensed_full` e `original_url` externo, porém também declara `authorized_republication=false`. Isso confirma a regra existente, sem comprovar licença ou autorizar mudar a política editorial. Corrigir a coerência dos alternates, conservar canonical e registrar a divergência no painel.

Ruling: a configuração estratégica muda a amostra — a nota continua usando o mesmo método; o histórico deve registrar a falta de comparabilidade, sem atribuir um delta a este lote.

## Registro de execução

- Baseline: seis arquivos Road Runners e dois snapshots Business recuperados da produção. Os cinco candidatos RR coincidem com os arquivos locais. Application.cfc tem diferença preexistente e fica apenas monitorado.
- Open Results: robots público ainda em cache HIT, Age 5212, bloqueando /resultados; origem correta previamente verificada. OR-02 permanece pendente.
- Tarefa 1: implementação concluída em staging; CFML RED (três páginas PT sem alternates) → GREEN (nove destinos). Publicação pendente.
- Tarefa 2: implementação concluída em staging; CFML RED (seis casos com canonical na fonte e alternates locais) → GREEN (30 modos/idiomas). RR-08 continuará parcialmente pendente no painel.
- Tarefa 3: pendente (auditoria após publicação e snapshot).
- Tarefa 4: backup RR preparado e cinco templates compilados pelo Adobe; três testes Python (nove subcasos) passaram. Revisão e publicação pendentes.

- O teste do builder detectou que a separação original agrupava itens RR-07/RR-08/RR-09; correção RED → GREEN evita modificar a resolução de itens adjacentes.

- Revisão final Astra: sem Critical/Important; um Minor de contagem textual dos controles corrigido. 53 testes Node passaram; CFML head/search verdes. Nove cenários do painel candidato passaram sequencialmente (a execução paralela colidiu no cache de classes CommandBox, sem falha de template).

- Runtime RR publicado: cinco templates, hashes confirmados e cinco dependências preservadas. Backup recuperável em /var/backups/seo-institutional-roadrunners-20261003/baseline. O verificador público foi ajustado: o seletor de idiomas já existente só aparece para usuários autenticados; nas requisições anônimas sua ausência é registrada, e a preservação da rota fica coberta pelos testes CFML e hash do header. Não houve alteração do header.

- Verificação pública posterior: 27/27 URLs com HTTP 200 direto e canonical esperado; nove institucionais com conjunto PT/EN/ES/x-default completo, seis versões de notícias com canonical na fonte sem hreflang local, doze controles preservados. Nova auditoria RR iniciada depois dessa conferência.

Ruling: incluir a correção focal do H1 de /maratonas/, achado público novo da auditoria ampliada — a página tem somente h3 após o slogan compartilhado passar a ser parágrafo. Trocar para h1 class=h3, preservando texto, aparência, consultas e autenticação. Baseline independente, backup próprio e nova auditoria posterior; registrar RR-10 concluído somente com HTML público e auditoria positivos.

- Maratonas: RED sem H1 → GREEN um H1 com classe h3; extensão revisada por Astra sem Critical/Important. Um template compilado Adobe, publicado com backup próprio, hash e três dependências conferidos. HTML público retorna 200/canonical próprio/um H1. Nova rodada final RR iniciada depois dessa conferência.

- Tarefa 1: complete — nove destinos institucionais aprovados em HTML público e auditoria posterior.
- Tarefa 2: complete no escopo técnico — seis versões com canonical na fonte e sem cluster local; política editorial RR-08 continua pendente.
- Tarefa 3: complete — rodada final RR após todas as correções, score/queue publicados com mesmos runId e datas. Open Results mantém rodada anterior datada.
- Tarefa 4: complete — oito templates compilados, backups/hashes, dependências preservadas, 27 páginas e Maratonas verificados, painel Adobe confirmou 15/12/3.
