# OpenResults — cidades na home

Publicado e conferido em `https://openresults.run/` em 04/10/2026.

A home agora tem Eventos por cidade ao lado de Eventos por estado. Escolher estado continua abrindo a página estadual imediatamente. O seletor de cidade oferece busca nacional por nome ou UF, ignora acentos, distingue homônimos por UF e prioriza nomes exatos. A seleção abre a rota estadual existente com `cidade=<slug>`.

Sugestões: até seis cidades com mais provas nos últimos 30 dias e até seis outras com mais provas nos últimos 12 meses, sem duplicação entre grupos. Contagens recentes/anuais são rotuladas por período. As sugestões usam somente eventos já elegíveis para resultados públicos na consulta existente da home. Datas finais futuras não elevam as sugestões. A busca conserva cidades com eventos mais antigos; mostra até 30 correspondências por vez, com orientação para refinar.

O catálogo foi construído a partir de `qEventosBase`, sem novas consultas SQL. Render com dados reais encontrou 2.708 pares cidade/UF; o JSON compacto tem cerca de 180 mil caracteres. Somente as 12 sugestões são renderizadas como links no servidor; a busca cria até 30 links usando textContent. O catálogo não inclui nomes de participantes. HTML recebe escape e `<` no JSON é neutralizado para não encerrar o elemento script.

Os atalhos de cidade incluem rua e trail quando não há filtro explícito dessas modalidades na URL de origem, pois o catálogo histórico contempla todas as modalidades. Na verificação pública, Feira de Santana mostrou 75 provas na home e abriu a lista estadual com os mesmos 75 eventos. O atalho de estado continua com seu comportamento e filtros padrão. Canonical estadual, sitemap, privacidade/noindex, login, Cloudflare, dados e RoadRunners permanecem fora deste escopo.

## Validação

- 13 testes Node aprovados: sete da navegação estadual e seis novos da home. A implementação ausente, a priorização de nomes exatos e o parâmetro de modalidades tiveram testes RED antes da correção.
- 18 verificações CFML aprovadas: cidade/UF, histórico, datas-limite de 30 dias/12 meses, datas futuras, contagens, deduplicação, limite de sugestões, catálogo vazio, JSON seguro, atalhos com modalidades e isolamento do formulário fora da home.
- Três templates compilados pelo Adobe ColdFusion; include direto com parâmetros URL forjados retornou 403 na fixture privada.
- Render completo privado com dados reais e dependências publicadas; todos os temporários de render, fixture e compilação removidos. O render HTML salvo antecede a última atualização de parâmetros dos atalhos; a versão final foi conferida publicamente e por CFML.
- Prévia no navegador em 1280, 390, 320 e 700 px. Finding da revisão reproduzido em 700 px (scrollWidth 738), corrigido (scrollWidth 700). Celular de 320 px ficou com scrollWidth 320 e painel de x=12 a x=308. Em produção, seletores lado a lado em 390 px, scrollWidth 390 e painel de x=12 a x=378. Tamanho temporário do navegador restaurado.
- Busca sem acento, mensagem de ausência de resultado, Escape/foco e restauração das sugestões verificados na prévia. Busca e clique para Feira de Santana e atalho de estado BA verificados na versão publicada.
- Busca pública `/busca/?termo=salvador&aba=eventos`: HTTP 200, termo mantido, estado mantido e widget da home ausente.
- Console da aba de produção sem erros JavaScript. A prévia apresentou aviso preexistente do Meta Pixel sobre permissão de tráfego no host local; não é falha do seletor. Leitor de tela não foi testado formalmente.
- Hashes dos cinco arquivos publicados confirmados, quinze dependências monitoradas preservadas; git diff --check aprovado.

## Revisão independente

Revisor executou quatro testes Node da versão inicial, conferiu destinos e os 2.708 pares únicos do render e ensaiou o init em DOM simulado. Nenhum finding Critical. Finding Important: painel podia exceder a largura entre 601 e 767 px; corrigido e confirmado no navegador. Priorização de nomes exatos e ajuste final de modalidades receberam testes do executor após a revisão.

Rulings sobre Declined to judge: desktop/mobile, execução Adobe e publicação foram cobertos pelo executor; tecnologia assistiva formal continua não medida. Regras mais amplas de slug e filtros estaduais foram mantidas por estarem fora da melhoria aprovada.

## Arquivos e publicação

Runtime publicado: `includes/backend_home_cidades.cfm`, `assets/css/openresults-home-cidades.css`, `assets/js/openresults-home-cidades.js`, `includes/form_busca_principal.cfm`, `index.cfm`. Reutilizados builder/matcher e CSS estadual, sem alterá-los. Formulário compartilhado só acrescenta o widget quando template é `/`.

Usuário trouxe mudanças do remoto durante a tarefa e aceitou a versão remota na home; HEAD local avançou para `56524ed4b3395117ab032b5816269d21688c31c1`. A comparação confirmou que o layout compacto mobile já coincidia com produção. Foram preservados o layout e o H1 SEO publicado, enquanto a versão remota ainda tinha parágrafo nesse lugar. Sincronização local limitada aos arquivos do escopo, com verificação de hashes contra edição concorrente. Nenhum comando Git de mutação foi executado pelo agente.

Publicação por substituição atômica por arquivo: includes e recursos primeiro, consumidores depois, proprietário/permissões preservados. Sem backups avulsos conforme preferência do OpenResults. Recuperação comprovada dos dois arquivos anteriores pelo Git `e769528c34b23beb6fc3a16ea615184849ce5e5c` mais `baseline.patch` para os ajustes já publicados da home. Antes de reverter, comparar hashes atuais; restaurar consumidores e depois remover somente os três novos arquivos. Não reverter checkout ou dependências inteiras.

Manifesto, patch de baseline, recibos, fixtures e render: `Business/_codex/staging/openresults-home-cidades-20261004/`. Testes duráveis: `OpenResults/_codex/tests/home-city-search.test.cjs` e `estado-city-navigation.test.cjs`. Sem commit, branch, tag, push ou PR.
