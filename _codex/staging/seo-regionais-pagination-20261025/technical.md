# Paginação e períodos regionais — 25/10/2026

## Entrega publicada

O lote 3 do plano regional foi publicado em 25/10/2026, às 18:09 (Brasília), com ajuste posterior na sincronização visual do controle de distância. O template é compartilhado por todas as regionais; PR, DF, SC, RS e SP foram conferidos. Não é um experimento isolado nessas regiões.

- `/estado/{uf}/` e `/estado/{uf}/{cidade}/` aceitam `pagina=2`, `pagina=3` etc. Página 1 usa a URL sem esse parâmetro. Links HTML de primeira/anterior/próxima permitem percorrer o calendário sem JavaScript. A navegação regional passa a usar páginas; a rolagem infinita de home/busca permanece independente.
- Cada página tem canonical própria. Estado/cidade e sua paginação padrão continuam indexáveis. Combinações não padrão de distância, período, modalidade ou cupom recebem `noindex,follow`, preservando canonical normalizada por página. Esses filtros não foram adicionados ao sitemap.
- `periodo_inicio` e `periodo_fim` usam YYYY-MM-DD, ambos obrigatórios quando informados, inclusive as extremidades e com referência de hoje no fuso America/Sao_Paulo. Intervalos invertidos, datas inexistentes, início passado e extensão superior a 732 dias retornam 400. O período padrão mantém o comportamento legado baseado na data final e meses de 30 dias.
- Para datas exatas, o evento entra quando seu intervalo se sobrepõe ao filtro; eventos de vários dias são contemplados. Não há alteração das datas no cadastro.
- Atalhos: restante deste fim de semana, até o fim do mês, próximo mês e próximo ano. O formulário permite outras datas e preserva os filtros atuais, inclusive mudanças feitas por AJAX depois da abertura da página.
- Alterar filtros volta à primeira página. Navegar entre cidades conserva datas/distância/cupom; contagens antigas de outro período são rejeitadas.
- Página além do fim retorna 404 com noindex. Uma cidade legítima sem provas continua com estado vazio explicativo. Parâmetros malformados retornam 400, sem expor erros CFML.

## Consulta e integração

`includes/backend/backend_regional_calendar.cfm` é incluído pelo backend compartilhado somente quando `VARIABLES.template == "/estado/"`. A consulta usa parâmetros, LIMIT/OFFSET de 50 linhas e desempate por `id_evento` na ordenação. Uma agregação por cidade calcula o total do recorte e as distâncias sem contar somente a página atual. Facetas reaproveitam a agregação.

A API `/api/eventos.cfm` preserva `page` com base zero; a URL pública usa `pagina` com base um. O resumo aparece na página completa e na resposta inicial da API, não nas respostas de continuação. Não houve mudança de schema ou escrita no banco: nenhuma operação no DataGrip é necessária.

A correção de revisão do cache da agenda que já estava em produção e faltava na cópia local de `includes/backend/backend.cfm` foi preservada no candidato e reconciliada na sincronização local. Demais alterações do Git do usuário foram mantidas.

O slider legado de meses fica oculto nas regionais, que agora possuem o seletor de datas. O controlador compartilhado reconstrói cada slider visível independentemente; ocultar o de meses não impede inicializar o de distância.

## Validação e evidência

- 42 testes Node: 8 de períodos/cidades (fonte e minificado), 9 de navegação de cidades e 25 de regressão de busca/filtros, incluindo slider de período oculto e visível.
- 10 templates CFML compilados e 21 cenários executados no Adobe com bootstrap real, em fixtures temporárias restritas a localhost e removidas no final. Sem escrita no banco.
- No snapshot de PR, 128 provas distribuídas em 50/50/28 linhas, sem IDs repetidos entre páginas. Novembro: 66 provas no total, com 50 na primeira página. Valores mudam com o inventário.
- HTTP público: 14 rotas/casos, incluindo canonicals, erros 400/404, filtros, API e regressão da calculadora; quatro assets comparados por conteúdo.
- Navegador desktop/mobile de 390 px: próxima página, atalhos exatos, formulário conservando cupom alterado via AJAX, arraste de distância e cidade conservando datas; sem overflow mobile. Exemplo conferido: Curitiba com nove provas em novembro para faixa 1–11 km, conforme a contagem do seletor de cidade.
- Três requisições quentes de origem por versão ficaram na mesma ordem de latência. São verificações operacionais, não um benchmark nem evidência de ganho de aquisição.

Backup inicial: `/var/backups/seo-regionais-pagination-20261025/baseline`. Ajuste do slider: `slider-fix/baseline` dentro do mesmo diretório. 18 arquivos de runtime, cinco dependências compartilhadas observadas. Evidências e scripts de publicação guardados no Business em `_codex/staging/seo-regionais-pagination-20261025/`.

## Manutenção e próximos itens

```sh
node _codex/scripts/build_regionais_pagination.mjs . /caminho/node_modules/esbuild
node --test _codex/tests/seo_regional_period.test.cjs _codex/tests/estado-city-navigation.test.cjs _codex/tests/search-page.test.js
```

Build com esbuild 0.28.2, minificação somente de whitespace. Alterar fontes e regenerar os `.min`.

Permanecem pendentes: baseline GSC das URLs/consultas, comprovação de recebimento das ações da calculadora no GA4/GTM, revisão editorial das fichas piloto e etapas Floripa/circuitos/pós-prova. A data da próxima prova já é calculada na agregação, mas não foi acrescentada ao resumo visível. A publicação não comprova aumento de tráfego/ranking/Site Health.

Referência técnica da política de paginação: [Google Search Central](https://developers.google.com/search/docs/specialty/ecommerce/pagination-and-incremental-page-loading). Plano e andamento: `Business/_codex/docs/2026-10-25_plano_seo_regionais_pace.md`. Sem commit/push.
