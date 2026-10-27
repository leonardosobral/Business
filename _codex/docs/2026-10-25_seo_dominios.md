# Domínios monitorados no SEO

## Escopo e fonte

O usuário pediu a lista montada em **Semrush → Início → Domínios para monitoramento** no painel Business, com ordenação por JavaScript e comparação de crescimento/queda. Implementação exclusivamente no Business, sem alterações no RoadRunners, OpenResults, banco de dados ou configuração do Semrush.

Endereço: `/portal/seo/?aba=dominios`. A aba é independente dos cartões de projetos e da auditoria técnica. A primeira importação contém os **27 domínios** visíveis em 25/10/2026, 15:03 de Brasília, **base Brasil** e janela **“Mês”** selecionada. Inclui tráfego orgânico, palavras-chave orgânicas/pagas, tráfego pago, domínios de referência, Authority Score e as respectivas variações. Dados dos cartões superiores de projetos não foram misturados: o OpenResults tem 764 de tráfego nessa tabela BR, embora o cartão do projeto apresentasse outro recorte.

O Road Runners aparece em **17º de 27** em tráfego orgânico e em palavras-chave. Valores exibidos na fonte: **3,2K**, **1,3K**, variações de **+191,3%** e **+31,13%**, respectivamente. São estimativas e valores arredondados, não medições GA4, cliques GSC ou o total real de visitas. As posições referem-se exclusivamente à lista selecionada. Authority Score varia em pontos; as demais variações são percentuais.

## Interface

- Busca por domínio; grupo RR/OpenResults ou demais referências; filtro por alta/queda/estabilidade do tráfego.
- Clique no cabeçalho ou seletor para ordenar valor ou variação, em ambas as direções, sem nova requisição ao servidor.
- Ausentes ficam no fim em qualquer direção; zero medido continua distinto de ausente. Empates usam domínio para estabilizar a ordem.
- O rank de tráfego não muda quando a lista é filtrada ou ordenada por outra métrica; o texto da tela explica a base completa de 27 domínios.
- Filtros e ordenação são preservados em parâmetros `dominio_*` do URL, com allowlist dos seletores e limite de 100 caracteres da busca. Não há inserção de HTML pela pesquisa.
- Cabeçalhos e coluna de domínio fixos, área de tabela com rolagem própria, navegação por teclado, `aria-sort`, anúncio de resultados e cores acompanhadas de sinais/texto.
- Links para domínio no Semrush e para visitar o site apoiam a etapa posterior de análise de páginas e palavras-chave. A variação isolada não comprova causa ou tendência sustentada.

Sem JavaScript, permanecem visíveis os 27 domínios já ordenados por tráfego e a explicação da limitação dos filtros. A tela mantém os controles de administrador existentes, GET somente e bloqueio do acesso direto aos templates de dados/view. Não há endpoint de consulta ao Semrush ou segredos novos.

## Arquivos

Runtime publicado no escopo:

- `portal/conteudo/seo.cfm`: adiciona `aba=dominios` à navegação e ao include; nenhuma alteração no relatório/audiência/fila.
- `portal/conteudo/seo_domains.cfm`: apresentação e guards.
- `portal/includes/seo_domains_data.cfm`: snapshot gerado, autenticado e protegido contra acesso direto.
- `portal/seo/assets/domains.css` e `domains.js`: estilos e ordenação/filtros.

Operação local: `_codex/scripts/seo_domains_snapshot.py`; arquivo imutável da coleta em `_codex/analyses/seo_domains/2026-10-25T150300-0300.json`; fonte da interface e recibos em `_codex/staging/seo-domains-20261025/`. Esses arquivos locais de operação não integram a publicação de runtime.

## Próxima atualização

1. Pelo navegador autorizado, abrir a lista, conferir base BR e **Mês** selecionado, capturar seu DOM completo sem coletar cookies, tokens, requisições privadas ou estado interno dos gráficos.
2. Salvar a nova observação e executar, com horário real e **arquivo histórico novo**:

```sh
python3 _codex/scripts/seo_domains_snapshot.py \
  --snapshot-dom /caminho/da/nova-coleta-dom.txt \
  --collected-at 2026-10-25T15:03:00-03:00 \
  --archive _codex/analyses/seo_domains/AAAA-MM-DDTHHMMSS-0300.json \
  --cfml-output portal/includes/seo_domains_data.cfm
```

O horário acima é apenas o exemplo da primeira importação; substituir pelo horário da nova leitura. O gerador valida cabeçalhos, base, período, células, duplicação de domínio e presença de RR/OpenResults. O arquivo histórico não pode ser sobrescrito por conteúdo diferente. Se o Semrush mudar o DOM, inspecionar o novo contrato antes de adaptar o parser.

3. Comparar com a observação anterior, preservar os arquivos históricos e publicar somente o novo snapshot após baseline, backup, testes Adobe e conferência real. Não reutilizar o backup desta implantação para outra publicação.

Não foi instalada agenda nem integração automática. A data aparece na tela e o carregamento da página não inicia uma coleta. Há uma observação desta lista: não foram inventadas séries históricas a partir das porcentagens ou gráficos da fonte. Novas observações preservadas permitirão implementar a comparação longitudinal posteriormente.

## Validação e publicação

Testes focados: **8 Node** (ordem numérica/percentual, empates, ausentes, filtros e estado no URL) e **6 Python** (parser, recorte, unidades, duplicações, integridade da coleta e guards). Fixture Adobe isolada em localhost: **16 cenários**, **8 controles de acesso** e conferência de **162 células** contra a fonte, além de navegação para abas antigas. Não foram executadas consultas ou migrações SQL.

Publicação com baseline e backup recuperável por `_codex/staging/seo-domains-20261025/release.py`. Root correto: `/var/www/business.roadrunners.run`; backup previsto: `/var/backups/seo-domains-20261025/baseline`. Dados/view/assets são publicados antes da navegação. `rollback` verifica mudanças concorrentes antes de recuperar arquivos anteriores e retirar os novos. Nenhuma operação Git de escrita é autorizada por esse procedimento.

Publicado em **25/10/2026 às 15:18:04 de Brasília** (`2026-10-25T18:18:04.896305Z`). Foram compilados os **3 templates**, publicados e conferidos os **5 hashes**, com **8 dependências preservadas**. Repetida a validação Adobe sobre a produção: **16 cenários, 8 controles de acesso e 162 células** aprovados. Recibos: `release-prepare.json`, `release-publish.json`, `release-verify.json`, `candidate-verified.json` e `published-verified.json` no staging desta entrega.

Conferência autenticada no Chrome: ordenação por tráfego, variação e palavras-chave, teclado Enter no cabeçalho, inversão de direção, busca sem diferenciar maiúsculas, grupos, combinação sem resultados, limpeza e persistência no URL após recarregar. A página de desktop tinha 1.516px sem overflow global; teste móvel real em **390×844**, largura de documento de390px e tabela de324px com rolagem horizontal funcionando. Viewport e filtros restaurados ao padrão. Sem erros de JavaScript nos logs da aba durante a conferência. Capturas: `published-desktop.png` e `published-mobile.png`. Nenhum arquivo fora dos cinco nomes do manifesto foi publicado; nenhum commit/push foi feito.
