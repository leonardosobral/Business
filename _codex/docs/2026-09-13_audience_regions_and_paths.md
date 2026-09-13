# Business — oportunidades por UF e cobertura por pasta

Escopo aprovado pelo usuário em 13/09/2026: renomear “Origem e LIVE!” para “Origem”, mover “Regiões do público” da visão geral para uma aba própria com oportunidades/preenchimento/lacunas por estado e identificar as pastas de “Outras páginas”. Publicado em 13/09/2026 às 00:16 BRT e conferido no Business autenticado.

## Decisões e contratos

- Alteração exclusiva do Business. RoadRunners continua produzindo os mesmos eventos. Não há migração, SQL manual, mudanças de DSN, autenticação, permissões, campanhas, créditos, retenção ou `tb_log`.
- Regra comercial preservada do [contrato de oportunidades](2026-09-12_audience_delivery_opportunities.md): posição/página aplicável independentemente de visibilidade; preenchimento inclui servido e institucional; vazio exige evidência explícita; falhas/desligadas/pendentes permanecem sem confirmação. Exposição de 1s não é denominador comercial.
- `occupancy_base.sql` é a parte comum da consulta existente, até a classificação de uma posição/página em cada UF. `occupancy.sql` continua deduplicando fisicamente o total entre UFs; `occupancy_regions.sql` preserva cada UF separada. Backend compõe os arquivos pelo marcador fixo `/* AUDIENCE_OCCUPANCY_BASE */`.
- Regional retorna `audience_uf,format,registered,potential,filled,empty,unclassified`, quatro formatos por UF observada. Mesmos sete filtros tipados e leitura `runnerhub`, timeout de 15s e cache de um minuto. Não há uma consulta por estado. Cada UF/formato reconcilia suas contagens; UFs sobrepostas não são somadas para formar o topo geral.
- Falha nos novos detalhes não oculta nem zera o resumo ou as consultas existentes. Contratos e contagens são validados antes de expor `ready`; atualização falha não conserva dados antigos como atuais.

## Navegação e leitura comercial

Sete abas. “Regiões” vem após a visão geral. A seleção local Total/Ads/Banners mantém os estados comparáveis e começa em Ads; outros formatos só aparecem quando há registro. Cada formato usa uma tabela compacta, números, percentuais e barra de ocupação por UF, ordenada por quantidade sem anúncio, depois oportunidades e UF. As mesmas cores e denominadores do topo são reutilizados. Sem JavaScript, os formatos permanecem acessíveis como seções.

Sem registros não é falha nem medição completa de audiência zero. UF desconhecida fica identificada; não é atribuída a um estado por inferência. Linhas sem oportunidades aplicáveis não ganham percentual artificial. Dados antigos de público/região ficam recolhidos dentro da nova aba, e o link `#regioes` continua válido. A aba Origem mantém seus relatórios atuais; só o nome de navegação muda.

## O que eram “Outras páginas”

O produtor classifica `VARIABLES.template` pelo mapa em `RoadRunners/services/AudienceMeasurementService.cfc`. Rotas fora do mapa viram `other`, embora mantenham `page_path` validado. Exemplos presentes no código: `/calendario/`, `/treino/`, `/atividades/`, `/mif/`, `/sobre/`, `/ajuda/` e `/login/`. São exemplos de classificação, não ranking real. `/oque` era exemplo do usuário, não rota encontrada.

O resumo existente de cobertura segue por família. A nova consulta `coverage_paths.sql` detalha exclusivamente `other` pela primeira pasta de `page_path`, sob os mesmos filtros. Preserva maiúsculas/minúsculas, rejeita caminhos inválidos, duplicação de barras e parâmetros; raiz, vazio ou caminho não seguro se tornam “Pasta não identificada”. A chave de deduplicação CFML usa hash para não colapsar pastas distintas apenas por caixa.

Os caminhos registrados são templates, não reconstrução de todas as URLs do navegador. O detalhamento aproveita o histórico que já existe; não inventa caminhos, aliases, parâmetros ou períodos anteriores à coleta. Métricas de cobertura continuam sinais técnicos: `pageviews`, `pages_with_slots` distinto por pasta, `opportunities`, `slot_views` e `last_received`. Não equivalem às oportunidades físicas comerciais. Contagens distintas de páginas por pasta não são universalmente aditivas se uma página registrar mais de uma pasta.

## Verificação e publicação

Runtime do lote: cinco arquivos novos (três consultas e duas views) e cinco substituições (consulta global, backend, home, JS e CSS). Publicação: novas dependências primeiro; backend compatível com consulta completa antiga antes de substituir essa consulta pelo template compartilhado; home com referências atualizadas por último. Backup fora do webroot, baseline e metadados verificados, demais arquivos protegidos por hash.

Validações concluídas antes da publicação:

- PostgreSQL 16 isolado, com dados sintéticos e consultas somente leitura: 1.565 asserções existentes e 445 novas, incluindo equivalência global, filtros, ausência de campanhas, isolamento por UF e pastas adversariais.
- Backend CFML real com fronteira de banco substituída por fixtures: 33 asserções; render editorial: 11. Render regional e página completa também executados sem DSN de produção.
- Nove testes Node de navegação, âncoras, histórico, filtros e compatibilidade das consultas passaram; sintaxe JS, shell e `git diff --check` limpos.
- Conferência visual em navegador, desktop e largura de 390px, incluindo seleção Ads/Banners/Total e rolagem horizontal das tabelas. Revisão independente concluída; contraste da primeira coluna na impressão ajustado e revisado.

Recibo remoto: `/var/backups/business-audience-regions.1JAEfg`, fora do webroot. Dez arquivos publicados entre `2026-09-13T03:15:59Z` e `2026-09-13T03:16:00Z`. Cinco backups e cinco alvos anteriormente ausentes registrados. Dez hashes e metadados conferidos após publicação; 28 arquivos protegidos de Business/RoadRunners permaneceram inalterados. Apache e CF2023 ativos, sem reinício.

- Pacote SHA-256: `0df21c1fe839b53fdd4dd5e66e7c362b987b3566074dc5cdaee273f4733df038`.
- Manifesto SHA-256: `5de5195d1162d7df8cb05d9be8dd9bf59cfba678836fcb0e2b2734311849c240`.
- Publicador SHA-256: `c9dffa021002e4538f67d07ac91647e8944c4943d69e28ca7a869ff93897b0d9`.
- Acesso HTTP anônimo: três novos arquivos SQL e duas views retornaram 403; painel retornou 302 para autenticação. Nenhuma consulta, credencial ou dado detalhado exposto.

## Conferência real após publicação

Business autenticado, produção, 7 dias, contexto comercial, todas as UFs/páginas/dispositivos, recepção até 13/09 00:17 BRT. Valores são uma fotografia daquele recorte, não promessa futura nem amostra sintética.

- Resumo: 5.272 oportunidades, 2.683 preenchidas, 2.159 sem anúncio e 430 sem confirmação.
- Ads por UF: AC com 27 oportunidades, zero preenchidas e 27 sem anúncio; SP com 459 oportunidades, 151 preenchidas, 277 sem anúncio e 31 sem confirmação; SC com 357 oportunidades, 197 preenchidas, 147 sem anúncio e 13 sem confirmação.
- Seletores regionais conferidos: AC em Banners tem 21 preenchidas de 21 oportunidades; em Total, 21 preenchidas e 27 sem anúncio de 48 oportunidades. Barras e percentuais conferidos na interface real.
- “Origem” selecionável com relatórios de aquisição e jornada LIVE! preservados.
- “Outras páginas”: 2.048 páginas vistas. Principais pastas reais: `/mif/` 752, `/desafios/` 682, `/circuitocatarinense/` 173 e `/atividades/` 112. O detalhamento exibe 19 pastas, sem limitar às primeiras linhas, e mantém as colunas de posições e visibilidade. São contagens de páginas vistas, não visitantes únicos nem inventário comercial.

Nenhuma mutação Git, migração, alteração de coleta, autenticação, créditos, retenção ou `tb_log` neste lote. A pendência operacional de retenção continua independente desta entrega.
