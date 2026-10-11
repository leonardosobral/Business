# SEO — resposta das páginas de eventos, RR-39

Publicado em 08/10/2026. A última nota oficial do Road Runners continua **75%**,
na auditoria Semrush de 5.000 páginas concluída às 20:20. Não houve nova auditoria
após esta entrega. A sessão autenticada do Chrome está no Mac bloqueado; a
solicitação de desbloqueio continua pendente. A meta de aumentar o Site Health
ainda não foi comprovada.

## Problema e alteração

A auditoria apontou quatro páginas lentas de São Silvestre: versões em inglês
de 2007 e 2008, espanhol de 2019 e português de 2026. Dezesseis medições GET,
com duas amostras públicas e duas pela origem por URL, confirmaram resposta de
cerca de dois segundos. EXPLAIN ANALYZE, em transação somente de leitura, mediu
2.095–2.150 ms na consulta `qEventoEdicoes`, com 19 edições.

O código de `RoadRunners/includes/backend/backend_evento.cfm` passou a ler os
resultados elegíveis uma vez por edição. Encontra os melhores valores de
classificação e tempo de cada sexo, mantém todos os resultados empatados e
aplica o desempate pelo perfil público ao conjunto reduzido. As expressões de
validação de identidade, privacidade, categoria, homologação e conclusão foram
preservadas. Os perfis são consultados na própria requisição. Não foi adicionado
cache de atletas, índice ou outra mudança de estrutura ou dados do banco.

Uma primeira tentativa de antecipar o limite mantendo empates reduziu pouco o
tempo total. A versão publicada reutiliza os resultados elegíveis e materializa
a busca da melhor classificação. A redução não deve ser atribuída às tentativas
anteriores nem confundida com aumento de nota.

## Verificação

- 34 cenários sintéticos passaram no PostgreSQL de produção, usando CTEs com
  dados fictícios em transação somente de leitura. Abrangem aliases de sexo,
  prioridades de classificação, valores nulos, empates, categorias PCD,
  homologação, conclusão, distância, múltiplos perfis, perfil privado e nomes
  incompatíveis com a conta importadora.
- Comparação completa das consultas antiga e nova, no mesmo snapshot: zero
  diferenças em 32 edições de quatro séries — São Silvestre (19), Jurerê (2),
  Maratona de Florianópolis (6) e Maratona do Rio (5). O caso sem edições também
  passou. A evidência conserva apenas contagens, sem nomes ou dados de atletas.
- Um template compilado. Hash publicado confirmado; quatro dependências
  preservadas, incluindo o template que exibe as edições.
- As 16 respostas após publicação retornaram 200. Título, H1, descrição,
  canonical, hreflang e robots permaneceram iguais ao baseline de cada URL.
- Mediana pela origem: **2,082799 → 1,6879295 s**, redução de **19,0%**. Mediana
  pública: **2,112185 → 1,80604 s**, redução de **14,5%**. Maior resposta pública
  posterior: 1,928806 s. Estas medições locais não substituem o rastreamento do
  Semrush nem encerram automaticamente seu achado de páginas lentas.
- Business: um arquivo de fila atualizado com RR-39. Template compilado, dez
  dependências preservadas e 19 cenários de renderização/acesso passaram antes
  e depois da publicação. Os includes reais confirmaram RR-39, a data atualizada
  e os números oficiais preservados: 75%, 39 erros, 35.227 avisos.

## Publicação e recuperação

Arquivos de runtime publicados:

- Road Runners: `includes/backend/backend_evento.cfm`.
- Business: `portal/includes/seo_queue_data.cfm`.

Backups recuperáveis no servidor:

- `/var/backups/seo-event-performance-20261008-rr/baseline`.
- `/var/backups/seo-event-performance-20261008-business/baseline`.

Scripts, hashes e recibos estão em
`Business/_codex/staging/seo-event-performance-20261008/`, com baselines,
candidatos e previews excluídos do Git. Sem commit, push ou publicação de arquivos
de outras frentes.

## Próxima ação

Com o Mac desbloqueado, iniciar uma auditoria do projeto Road Runners
**26661911**, mantendo 5.000 páginas, mobile e sem renderização JavaScript.
Importar a conclusão real, publicar o painel e comparar a nota e os quatro
achados de lentidão. A meta exige aumento confirmado acima de 75%, não uma
pontuação estimada.
