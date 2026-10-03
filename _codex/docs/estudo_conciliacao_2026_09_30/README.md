# Conciliação e publicação — 30/09/2026

Autoria e operação permanecem no caderno 6, “Brasil que Corre Provas — Estudo e publicação”, em https://business.roadrunners.run/estudo/?caderno=6. Estes arquivos são recibos das consultas e notas salvas no notebook, não uma segunda fonte de publicação. Não houve mudança de runtime ou schema do Business nesta entrega; todas as operações usaram StudyNotebook e StudyPublication existentes.

## Consultas e congelamentos

| Seção | Célula / revisão | Execução | Conteúdo |
| --- | --- | --- | --- |
| 47 — P12 | 257 / 1 | 40 | Auditoria dos filtros de maratonas 2025 |
| 47 — P12 | 259 / 2 | 41 | População única para 12 indicadores por prova |
| 57 — 2026 Recortes e conciliação | 260 / 1 | 42 | Oito percentuais de distância derivados da execução 33 |
| 57 | 261 / 1 | 46 | Auditoria agregada dos mínimos de 2026 na base atual |
| 48 — P13 | 264 / 2 | 48 | Cinquenta médias pela classificação legada |
| 48 — P13 | 266 / 1 | 49 | Comparação desses tempos com a referência 34 |
| 54 — Saída 2025 | 249 / 6 | 45 | Pacote publicado: web v3, publicação 4 |
| 55 — Saída 2026 | 251 / 3 | 47 | Pacote publicado: web v2, publicação 5 |

Notas: 258 (P12), 262 (2026), 263 (acompanhamento), 265 (P13). Execuções 43 e 44 são intermediárias e não foram publicadas. A 43 foi recusada pelo contrato por omitir um contador obrigatório de conciliação que passou a zero; corrigido na revisão 6/execução 45, preservando o campo com zero. O contrato e suas permissões não foram relaxados.

## Achados

`public.vw_resultados` é uma view comum sobre `tb_resultados`, filtrada por status_final=0 e homologado=true; não é uma cópia congelada. Os resultados congelados no schema estudo preservam os retratos.

Em Curitiba 2025, seis registros “42k CADEIRANTE” têm pcd=false. O filtro booleano os incluía e produzia mínimo 01:56:00. Ao combinar o campo com o filtro de modalidade do SQL recebido, o mínimo é 02:15:13, como no PDF. São Paulo tem 13 registros DMS/DMAI com pcd=false. Nada foi alterado nos cadastros.

O recálculo publicado de 2025 usa uma população única para contagem, gênero, mínimo/média/mediana e sub-4/3/2h30. Nas dez provas são 43.395 participações; PDF 43.362. Sete contagens coincidem; diferenças residuais: SP City +6, São Paulo +5, Curitiba +22. Não há snapshot histórico para determinar a causa restante. Os filtros textuais amplos, inclusive `%DI%`, são legados e só foram aplicados à seleção auditada de dez provas; não devem ser copiados automaticamente para novos eventos.

2026 mantém a coleta original e o corte até 26/09: os oito percentuais novos são calculados a partir das contagens congeladas na execução 33. Somam 100% dentro de F e M; denominadores 2.255.290 e 1.928.402. Nenhum comparativo, total ou tempo foi atualizado.

A auditoria de mínimos em 2026 encontrou na base atual um registro SP City “42.2K ACD” a 01:29:29 e dez Floripa “42K GERAL” entre 00:21:31.725 e 01:36:57.659. Dois limites distintos: a anotação pública é derivada do congelamento 33; a execução 46 consulta a base em 30/09. Duas horas é um limiar de revisão, não filtro de exclusão. Origem, percurso e mapeamento de tempo precisam de conferência. A web identifica as pendências também nas contagens/médias/cortes afetados.

A regra legada dos melhores grupos foi localizada e executada: posições cadastradas <=10/100 e percentuais dos inscritos, não ranking novo por tempo. Top 10 inclui 20 ou 35 resultados em várias provas. Das 50 médias, 18 coincidem exatamente e 38 ficam a até um segundo do PDF (incluindo as 18). Restam 12 diferenças maiores. São Paulo tem somente 28 registros elegíveis até a classificação 100; a mesma média se repete nos três grupos percentuais. Execuções 48/49 permanecem para conciliação; não foram promovidas à web. Não há regra confirmada de medalhas/desempates.

## Validação e reversão

StudyPublication.preview aceitou 45/47 antes da publicação, com baselines 3/2 verificados. O HTTP público retornou 200 e noindex/nofollow nas duas edições, com payload igual ao candidato (exceto metadados de publicação). Referências e categorias preservadas: 120 comparações alteradas em 2025, oito em 2026. Os comparativos de 2026 e totais nacionais dos dois anos permaneceram idênticos. Testes de integridade e interface no RoadRunners: 34 passaram. Chrome autenticado confirmou web v3/45 e web v2/47.

Para retornar aos pacotes anteriores, selecionar execução 35 para 2025 e 33 para 2026 na aba Versão web e publicar com nota. Não apagar ou modificar congelamentos. Backup do runtime RoadRunners: /var/backups/roadrunners-estudo-conciliacao-20260930/runtime/RoadRunners/. Evidências e testes no RoadRunners: `_codex/docs/brasil_que_corre_provas/conciliacao_2026_09_30/`.
