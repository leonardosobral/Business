# Atualização da aba Domínios — 30/10/2026

Pedido: atualizar os dados de `/portal/seo/?aba=dominios`.

Fonte: tabela visível Semrush → Domínios para monitoramento, Brasil, Mês. Coleta em 30/10/2026 às 12:17 (Brasília), 27 domínios, mesmo conjunto da coleta anterior. Arquivo original `semrush-month-dom.txt`; observação arquivada em `../../analyses/seo_domains/2026-10-30.json`. Preservado o registro de 25/10. Os cartões de projetos do Semrush usam outro recorte e não foram misturados à lista.

Road Runners: tráfego estimado 3,9K, variação mensal exibida +260,71%, rank 16/27; palavras-chave 1,3K, +41,3%, rank 17/27. OpenResults: tráfego 1,1K, 479 palavras-chave, rank de tráfego 22/27. Os valores abreviados são aproximações; +0% de OpenResults é o valor exibido pela fonte e não foi reinterpretado como variação entre nossas coletas.

Runtime: `portal/includes/seo_domains_data.cfm` atualizado pelo importador existente; `portal/conteudo/seo_domains.cfm` ajustado apenas para remover a descrição desatualizada de “primeiro registro”. Sem alterações de JS, CSS, autenticação, banco ou outras abas. Publicação às 12:18:53 BRT com backup `/var/backups/seo-domains-20261030/baseline`.

Validação: seis testes Python, oito Node; compilação de dois templates; 16 cenários ColdFusion antes e após publicação, com oito verificações de acesso e comparação de 162 células/variações. Hashes dos dois arquivos publicados e quatro dependências conferidos. Navegador autenticado confirmou data, resumo, filtro de nossos sites (2/27) e retorno à lista completa. Screenshot `published-desktop.png`. Sem commit/push.
