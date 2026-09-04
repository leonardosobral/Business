# Catálogo RaceTag — Maratona de Floripa 2025

Mapeamento realizado em 25 de agosto de 2026 a partir da tela pública de TV:

`https://result.racetag.com.br/onsports/#/maratona-de-floripa-2025/tv`

O catálogo estruturado, pronto para consumo por outra aplicação, está em
[`racetag_floripa_2025_sources.json`](racetag_floripa_2025_sources.json).

## Resultado principal

A tela não possui uma API distinta para cada distância, parcial ou sexo. Ela baixa dois arquivos principais e filtra tudo no cliente:

- `event.json`: percursos, categorias, parciais, premiações e equipes;
- `results.json`: todos os atletas, tempos finais e passagens nas parciais.

Os filtros são chaves compactas:

- distância/modalidade: `result.r` = `event.routes[].i`;
- sexo: `result.g` (`M`, `F` ou `X`; nos dados encontrados existem apenas `M` e `F`);
- parcial: `result.ck[].i` = `event.checkpoints[].i`.

O domínio permite leitura cross-origin (`Access-Control-Allow-Origin: *`) por `GET` e `HEAD`, sem autenticação. Os arquivos estão em S3/CloudFront.

## Fontes do link informado

Evento interno `KNY9FL`, slug `maratona-de-floripa-2025`:

| Fonte | URL | Situação | Uso |
| --- | --- | --- | --- |
| Registro de eventos | `https://result.racetag.com.br/onsports/data/events.json` | 200 | Resolve slug → ID e fornece nome/data/local |
| Metadados | `https://result.racetag.com.br/onsports/data/KNY9FL/event.json` | 200 | Percursos, categorias, checkpoints, equipes e prêmios |
| Resultados | `https://result.racetag.com.br/onsports/data/KNY9FL/results.json` | 200 | 9.954 registros, chegada e parciais |
| Marcador de alteração | `https://result.racetag.com.br/onsports/data/KNY9FL/resultChanged.txt` | 404 | Opcional; não exigir |
| Resultados por equipe | `https://result.racetag.com.br/onsports/data/KNY9FL/team_results.json` | 404 | Opcional; não exigir |
| Tema | `https://result.racetag.com.br/onsports/data/KNY9FL/theme.json` | 404 | Opcional; não exigir |

### Distâncias e sexos — fonte direta

“Elegíveis” reproduz a tela de TV: exclui registros com `s=DSQ` ou `s=DNF`.

| Percurso | ID | Distância | F: bruto / elegível / chegada | M: bruto / elegível / chegada |
| --- | --- | ---: | ---: | ---: |
| ELITE 42K | `1F1FF6K` | 42.000 m | 19 / 19 / 11 | 25 / 25 / 14 |
| CORRIDA 42KM - PCD | `BGI6CE` | 42.000 m | 2 / 2 / 1 | 21 / 21 / 14 |
| CORRIDA 42KM | `1YQVM7Y` | 42.000 m | 1.866 / 1.848 / 1.473 | 4.613 / 4.594 / 3.639 |
| CORRIDA 5KM | `X4MMI6` | 5.000 m | 2.229 / 2.228 / 1.869 | 1.167 / 1.167 / 936 |
| CORRIDA 5KM - PCD | `VU36Q2` | 5.000 m | 7 / 7 / 5 | 5 / 5 / 4 |

O percurso oculto `ZH30G5` (`GUIA`) não possui resultados e não aparece na TV.

### Parciais de 42 km — fonte direta

| Parcial | ID | Distância | Elite F/M | 42K PCD F/M | 42K F/M |
| --- | --- | ---: | ---: | ---: | ---: |
| PC1 | `W7VW2U` | 7.800 m | 12 / 18 | 1 / 14 | 1.495 / 3.695 |
| PC2 | `1DPIRGO` | 11.700 m | 12 / 18 | 0 / 5 | 416 / 1.143 |
| PC3 | `3BG7QF` | 21.097 m | 1 / 8 | 0 / 0 | 5 / 44 |
| PC4 | `1PBHBTT` | 36.000 m | 1 / 8 | 0 / 1 | 7 / 28 |
| Chegada | `null` | 42.000 m | 11 / 14 | 1 / 14 | 1.473 / 3.639 |

Os 5 km e 5 km PCD só possuem chegada; não há `ck` intermediário para esses percursos.

## Fonte complementar de 21 km

O registro público revelou um segundo evento do mesmo fim de semana: ID `19IWN2A`, slug `maratona-de-floripa-2025-21K`. Ele não é carregado pelo link original, mas é necessário para cobrir a distância de 21 km.

| Fonte | URL | Situação |
| --- | --- | --- |
| Metadados | `https://result.racetag.com.br/onsports/data/19IWN2A/event.json` | 200 |
| Resultados | `https://result.racetag.com.br/onsports/data/19IWN2A/results.json` | 200; 9.147 registros |
| Marcador/equipes/tema | mesmos nomes sob `/19IWN2A/` | 404; opcionais |

### Distâncias e sexos — fonte complementar

| Percurso | ID | Distância | F: bruto / elegível / chegada | M: bruto / elegível / chegada |
| --- | --- | ---: | ---: | ---: |
| ELITE 21K | `KDENMA` | 21.000 m | 20 / 20 / 12 | 43 / 43 / 29 |
| CORRIDA 21KM - PCD | `15J7XXR` | 21.000 m | 6 / 6 / 4 | 15 / 15 / 12 |
| CORRIDA 21KM | `10L8GOV` | 21.000 m | 4.681 / 4.679 / 3.900 | 4.379 / 4.378 / 3.530 |
| 05K | `NPVVBH` | 5.000 m | 1 / 1 / 0 | 2 / 2 / 0 |

Os percursos ocultos `PACER 21K` e `GUIA` não possuem resultados. O 05K desta fonte tem apenas três registros e nenhuma chegada, portanto não deve substituir o 5K do evento `KNY9FL`.

### Parciais de 21 km — fonte complementar

| Parcial | ID | Distância | Elite F/M | 21K PCD F/M | 21K F/M |
| --- | --- | ---: | ---: | ---: | ---: |
| PC 7,5K | `1FWDVVL` | 7.500 m | 11 / 29 | 4 / 11 | 3.387 / 2.991 |
| PC 11K | `VZM78G` | 11.000 m | 11 / 29 | 3 / 11 | 3.806 / 3.431 |
| PC 16K | `51IY36` | 16.000 m | 12 / 29 | 1 / 5 | 168 / 844 |
| Chegada | `null` | 21.000 m | 12 / 29 | 4 / 12 | 3.900 / 3.530 |

As contagens de passagens não são monotônicas no arquivo arquivado. Não use “passou na última parcial” como critério de chegada; use `tn`/`tg`.

## Regra exata do ranking da TV

1. Exclui qualquer atleta com `s` preenchido (`DSQ`, `DNF` etc.).
2. Filtra por `r` (percurso) e `g` (sexo).
3. Na chegada, usa `tn` positivo; se não existir, usa `tg` positivo.
4. Na parcial, calcula `new Date(ck.t) - new Date(st)`.
5. Ordena o tempo crescente, mostra os dez primeiros por sexo e divide em duas colunas de cinco.
6. Ignora `ck.r`; a posição é recalculada para a combinação percurso + parcial + sexo.

Exemplo mínimo:

```js
const timeToMs = (value) => {
  if (!value) return null;
  const [clock, fraction = "0"] = String(value).split(".");
  const parts = clock.split(":").map(Number);
  if (parts.some(Number.isNaN)) return null;
  return parts.reduce((total, part) => total * 60 + part, 0) * 1000
    + Number(fraction.padEnd(3, "0").slice(0, 3));
};

function ranking(results, { routeId, sex, checkpointId = null, limit = 10 }) {
  return results
    .filter((athlete) => !athlete.s && athlete.r === routeId && athlete.g === sex)
    .map((athlete) => {
      if (checkpointId === null) {
        const net = timeToMs(athlete.tn);
        const gross = timeToMs(athlete.tg);
        return { athlete, millis: net > 0 ? net : gross > 0 ? gross : null };
      }
      const passage = athlete.ck?.find((item) => item.i === checkpointId);
      if (!passage?.t || !athlete.st) return { athlete, millis: null };
      return { athlete, millis: new Date(passage.t) - new Date(athlete.st) };
    })
    .filter((row) => row.millis > 0)
    .sort((left, right) => left.millis - right.millis)
    .slice(0, limit);
}
```

## Campos úteis do `results.json`

| Campo | Significado |
| --- | --- |
| `n`, `nm` | número de peito e nome |
| `g`, `r`, `c`, `t` | sexo, percurso, categoria e equipe |
| `st`, `ft` | timestamps de largada e chegada |
| `tn`, `tg` | tempo líquido e bruto |
| `s` | status; no conjunto: `DSQ` e `DNF` |
| `ck[].i`, `ck[].t` | ID e timestamp da parcial |
| `aw` | posições, indexadas por `event.awards[].p` |
| `ct`, `tl` | campos personalizados e identificadores de chip |

`ct` e `tl` podem conter identificadores pessoais ou de cronometragem. Uma integração nova deve omiti-los quando não forem necessários.

## Estratégia recomendada de integração

1. Resolva o slug em `events.json` e não fixe apenas o nome do evento.
2. Baixe `event.json` e `results.json` em paralelo.
3. Faça os joins pelos IDs `i` e mantenha os filtros localmente.
4. Em evento histórico, use `ETag` ou `Last-Modified`; não é necessário repetir o polling de 15 segundos da TV.
5. Trate os quatro arquivos opcionais com tolerância a 404.

