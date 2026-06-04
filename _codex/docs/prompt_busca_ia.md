# Busca Inteligente com IA

Atualizado em: 2026-06-04

## Objetivo

Documentar a busca atual do Road Runners, que combina:

- busca tradicional;
- interpretação em linguagem natural com IA;
- resultados segmentados por tipo de conteúdo.

------------------------------------------------------------------------

## Estado atual

A busca hoje atende:

- `eventos`
- `resultados`
- `atletas`
- `noticias`
- `videos`

Arquivos principais:

- [includes/estrutura/busca.cfm](/Users/geraldoprotta/IdeaProjects/RoadRunners/includes/estrutura/busca.cfm)
- [includes/busca_home.cfm](/Users/geraldoprotta/IdeaProjects/RoadRunners/includes/busca_home.cfm)
- [busca/index.cfm](/Users/geraldoprotta/IdeaProjects/RoadRunners/busca/index.cfm)
- [assets/js/runnerhub-busca-page.js](/Users/geraldoprotta/IdeaProjects/RoadRunners/assets/js/runnerhub-busca-page.js)
- [api/noticias_busca.cfm](/Users/geraldoprotta/IdeaProjects/RoadRunners/api/noticias_busca.cfm)
- [api/videos_busca.cfm](/Users/geraldoprotta/IdeaProjects/RoadRunners/api/videos_busca.cfm)
- [repositories/RaceRepository.cfc](/Users/geraldoprotta/IdeaProjects/RoadRunners/repositories/RaceRepository.cfc)

## Comportamento esperado

### Busca simples

- respeita o tipo de busca escolhido;
- consulta diretamente a base correta;
- é o fluxo usado quando `busca_mode=plain`.

### Busca com IA

- interpreta intenção e filtros;
- normaliza saída para filtros de eventos;
- também pode conviver com abas de resultados, atletas, notícias e vídeos;
- é o fluxo usado quando `busca_mode=ai`.

### Entradas por GET

- URLs com filtros devem autoexecutar a busca, mesmo sem termo livre;
- isso vale especialmente para casos como distância e período.

## Interpretação estruturada

Exemplo de intenção:

Entrada:
- `quero correr uma meia maratona em floripa`

Saída esperada da etapa de interpretação:

```json
{
  "cidade": "Florianópolis",
  "estado": "SC",
  "distancia_km": 21.097,
  "periodo_inicio": null,
  "periodo_fim": null,
  "termo_livre": null
}
```

Regras que continuam valendo:

- não inventar dados;
- campos desconhecidos devem virar `null`;
- a IA não consulta banco;
- a query final deve continuar parametrizada.
- `termo_livre` só deve existir quando o texto tiver cara de nome próprio de prova/corrida/circuito/desafio ou nome de pessoa;
- buscas `tipo_termo: descricao` devem sair com `termo_livre: null`; descrição não deve virar filtro textual duro;
- sobras temporais como `mes`, `meses`, `semana`, `dia`, `dezena`, `quinzena`, `semestre`, `daqui`, `em 3 semanas`, `próximo mês` e `mês que vem` devem virar período ou ser descartadas, nunca filtro textual;
- sobras vagas como `quero`, `procuro`, `evento`, `corrida`, `futuro`, `próximo`, `qualquer`, `algumas`, `cerca de`, `aproximadamente` e números por extenso usados só para período também não devem virar `termo_livre`.

Exemplo:

Entrada:
- `Quero uma corrida em sampa daqui uns 3 meses`

Saída esperada:
- cidade `Sao Paulo`, estado `SP`, período a partir de três meses da data atual, `termo_livre: null`, `tipo_termo: descricao`.

## Tabela auxiliar

A estrutura de apoio atual documentada no repositório está em:

- [schema.sql](/Users/geraldoprotta/IdeaProjects/RoadRunners/_codex/sql/schema.sql)

Ela inclui:

- `tb_busca_ia_cache`
- `tb_busca_log`
- `tb_evento_treinos_config`

## Log analítico

A busca grava eventos em `tb_busca_log` para permitir uma página futura de análise no admin.

O contrato para construir essa página está em:

- [admin_busca_log.md](/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/docs/admin_busca_log.md)

Fluxo esperado:

- `api/search.cfm` grava a etapa `interpretacao`, com termo original, modelo, resposta da IA, filtros brutos, filtros normalizados e mensagem exibida;
- o JS recebe `searchLogId` e repassa como `busca_log_id` para os endpoints das abas;
- `api/eventos_busca.cfm`, `api/resultados_busca.cfm`, `api/atletas_busca.cfm`, `api/noticias_busca.cfm` e `api/videos_busca.cfm` gravam etapas `execucao` apontando para `id_busca_log_parent`;
- os campos `filtros_json`, `contagens_json`, `request_json`, `ia_json` e `payload_json` ficam em JSONB para consultas analíticas;
- erros de gravação do log não devem derrubar a busca; eles ficam em `REQUEST.buscaLogErrors` durante a request.

## Observações práticas

- `noticias` e `videos` não compartilham a mesma origem de dados;
- a busca visual hoje já foi redesenhada para home, `/busca` e `/estado`;
- o resultado da busca usa abas compactas com contagem por tipo;
- qualquer alteração nessa área deve ser validada em desktop e mobile.

## Próximas evoluções possíveis

- aprofundar semântica para `noticias` e `videos`;
- ampliar explicabilidade da interpretação de IA;
- revisar performance da query de eventos em cenários de filtros amplos;
- evoluir estratégia de cache e observabilidade.
