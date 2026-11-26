# Gerador candidato da renovação Jan–Set

`../build_candidate.py` só lê arquivos e produz SQL. Não abre conexão, não executa consulta, não grava célula e não publica. A carga/revisão da BI2026 não é verificada por este gerador; uma execução nova pode continuar consultando uma carga antiga.

A montagem414 usa as105 projeções SELECT da montagem completa de05/10: perfil, atividades, cobertura, mapeamento, preços e os demais temas voltam a ser recombinados. O contrato17, unidades, casas decimais, atributos das definições e ordem das séries vêm do baseline233 fornecido. Rótulos de categorias dinâmicas são regenerados para que novas cidades/provas/distâncias não desapareçam do leitor. A saída conserva137 séries no exemplo antigo; uma categoria nova pode criar uma série dinâmica nova, sem recortar silenciosamente os dados.

A evidência histórica `variacoes_a_z` e a revisão manual de maratonas404/405 conservam suas datas, decisões e valores. Reexecutar a405 atual não renova sua evidência: ela contém decisões literais e lê212. O fechamento desses casos precisa de conciliação própria. O comparativo Alfa+Z explícito vem da380 atualizada.

Preços, CNA e ritmo42 permanecem temas em revisão no plano anual. Recombiná-los no pacote integral não os libera para o Q3. A seleção de páginas/temas aprovados continua responsabilidade dos consumidores do produto profissional. O gerador não altera `produtos`, `web_destinos` nem `lancamento_publico`.

## Entrada

```python
import build_candidate as b
runs = b.load_runs('/caminho/refresh-completo-20261109/runs')
# Aceita diretamente os recibos atuais de collect.py:
# {"run": {...metadados...}, "data": {"result": {"columns": [...], "rows": [...]}, ...}}
```

Também aceita JSON `{ "343": {"id":500,"cell_version":2,"started_at":"2026-11-09T12:00:00-03:00","result_json":"..."}, ... }` ou lista de runs. `cellversion` é aceito como alias. Se `status/frozen/truncated` estiverem presentes, fontes falhas, não congeladas ou truncadas são recusadas. Os predicados SQL também exigem fonte congelada/ok/completa e revisão explícita.

A montagem414 exige343,347,350,351,353,355,356,357,358,359,361,363,364,366,367,368,377,378,380,384. As referências346/348/349 conservam seus congelamentos anteriores se não forem fornecidas: são históricas e não projetam números anuais antigos sobre2026.

## Ordem das derivadas

1. Após renovar os nove meses365/369–376: `build_derived(377,runs)`.
2. Após renovar gerações352/354/357 e conservar ou renovar346/348/349: `build_derived(380,runs)`.
3. Após renovar383/384: `sql387, completo = build_pairs(runs)`.
4. Depois de salvar/executar/congelar as derivadas acima, incluir os recibos novos no mapa e produzir414.
5. Depois do congelamento414, produzir251. O overlay exige353 nova e preserva exclusivamente402/run210 para Floripa; se os dados fornecidos da353 não incluírem Floripa no Top10, bloqueia para conciliar a seleção. Os totais nacionais e a coorte não recebem essa substituição.
6. Depois do congelamento251, produzir420 e418. A420 exige251,347,354,421,383,368,387 e usa378 para informar a data geográfica. A418 conserva `rascunho_interno` e os temas `Em revisão`.

```python
sql414 = b.build_themes(runs, baseline_payload,
    baseline_run={"id":233,"cell_id":251,"cell_version":39})
sql251 = b.build_final(runs)       # mapa já inclui a nova414
sql420 = b.build_public(runs)      # mapa já inclui a nova251
sql418 = b.build_annual(runs)
```

A referência baseline é explícita; não substituir233 por um run arbitrário sem fornecer seu payload e revisão correspondentes. `payload_from()` aceita pacote direto, resultado nativo, reciboRUN ou envelope com `payload`.

CLI equivalente:

```sh
python3 build_candidate.py --runs runs --baseline baseline233.json --output-dir candidate --steps 414
python3 build_candidate.py --runs runs --output-dir candidate --steps 251
python3 build_candidate.py --runs runs --output-dir candidate --steps 420 418
```

Cada etapa depende dos novos congelamentos anteriores; gerar arquivos consecutivos não executa essas dependências.

## Verificação offline

```sh
python3 build_support/test_builder.py
python3 build_support/offline_example.py
```

Treze testes verificam projeções completas, igualdade das105 expressões contra o gerador histórico, ponteiros/revisões novos, rejeição de fonte ausente/falha, proteção de contagens/IDs/limiares contra substituição global, todos os608 pares e métricas exatas, fonte especial de Floripa e rascunho anual.

`old-fixture-example/` contém exemplos históricos identificados como tais e `verification.json`. Essa prova não executa o SQL gerado no PostgreSQL nem comprova atualização da cargaBI2026. Validação sintática/numérica, revisão das novas contagens, preview do contrato, congelamento e liberação pertencem à etapa controladora.
