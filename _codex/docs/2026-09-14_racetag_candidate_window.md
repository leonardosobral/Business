# RaceTag: janela de vínculo e navegação da fila

## Alterações publicadas

- `racetag/form.cfm`: candidatos Road Runners por sobreposição com o período da
  fonte ampliado em um dia antes/depois. Uma prova de 12/09 inclui 11–13/09;
  provas de vários dias mantêm todo o intervalo. UF, prioridade da cidade,
  eventos ativos e vínculo explícito permanecem como antes.
- `administracao/importacoes-resultados/home.cfm`: processamento na mesma aba;
  links mantêm `status=` explícito quando o usuário escolhe Todos.
- `administracao/importacoes-resultados/includes/backend.cfm`: entrada sem filtro
  usa Pendente; histórico de grupo continua completo. Filtros explícitos prevalecem.

Sem alteração de API, banco, resultados, permissões ou processamento automático.

## Verificações executadas

- `node _codex/scripts/test_result_import_groups.mjs`: aprovado com PostgreSQL
  temporário e CFML real. Testes reproduziram as falhas antes das correções.
  Cobertura de datas anterior/mesmo dia/posterior, limites de ano, múltiplos dias,
  UF, ativos, seleção explícita, falta de data final, data inválida, navegação,
  padrão Pendente, Todos persistido nos links e histórico completo.
- 24 testes Node de fila/intenção/contrato passaram.
- `git diff --check` passou.
- Seletor real renderizado com dados controlados, inspecionado no navegador em
  desktop e 390 px; clique no link real da fila navegou na mesma aba de teste.
- Compilação Adobe ColdFusion no servidor: `successful 3 / total 3`.
- Verificação pós-publicação dos três hashes, metadados, backups e 121 proteções.
- GET sem autenticação nas duas rotas: HTTP 302 para a entrada do Business.
  Isso confirma a proteção da rota, não uma sessão autenticada. Nenhum evento
  de produção foi processado como teste.

## Publicação e recuperação

Pacote vigente: `/var/backups/business-racetag-candidate-window.d149c51c1147`.
Recibos: `2026-09-14_racetag_candidate_window_release_v2*.json`.

Hashes instalados:

| Arquivo | SHA-256 |
|---|---|
| `racetag/form.cfm` | `93cb5e3ed9cc2cc8f08b2bc21c4d0e6705d49a149bb456867935652c041c2c98` |
| `administracao/importacoes-resultados/home.cfm` | `7ce1b0da4f535a54c6dbed711d9ceb6b759bdcce98a2f6f2727815c5654095c4` |
| `administracao/importacoes-resultados/includes/backend.cfm` | `ad0e775a65892bf33e3acd6cca8323c0707f439af52eeb10f0ca9731827ad3eb` |

Rollback do pacote vigente, se necessário:

```sh
python3 _codex/scripts/deploy_racetag_candidate_window.py rollback
```

A tentativa inicial, `business-racetag-candidate-window.dc6e35a43d7d`, foi
revertida automaticamente e verificada como `rolled_back`: `home.cfm` havia sido
incluído simultaneamente nos alvos e nas proteções de arquivo imutável do pacote.
Os hashes originais foram conferidos antes de preparar o pacote novo. A versão
local do publicador agora rejeita essa sobreposição antes de acessar o servidor.
Os arquivos-alvo continuam protegidos por hashes de baseline/candidato, backups
e metadados; arquivos alheios continuam nas proteções de conteúdo inalterado.

Nenhum commit, branch, push ou reinício de serviço foi realizado.
