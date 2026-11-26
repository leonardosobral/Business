## Floripa 2026 — índices gerais de Boston 2027

**264 corredores atingiram os índices gerais: 186 homens e 78 mulheres.**
- Geral e elite: 262 (185 homens e 77 mulheres), em 3.592 concluintes classificados.
- PCD/DV: outros 2 (1 homem e 1 mulher) atingiram a mesma tabela geral; são 11 concluintes nesse recorte.
- Total de corrida a pé analisado: 3.603. Cadeira de rodas e índices próprios de divisões para/adaptadas ficam separados.

### Fontes e regra

Fonte primária: [RaceTag / MyCrono — Floripa, 30/08/2026](https://resultados.racetag.com.br/mycrono/#/maratona-de-floripa-2026), classificação v3; a página informa última alteração em 22/09/2026 14:57:12. Captura de 05/10/2026. Arquivos públicos `data/14221WX/event.json` e `data/14221WX/results.json`.

[Índices gerais B.A.A. 2027](https://www.baa.org/races/boston-marathon/qualify/): tempo líquido menor ou igual ao índice por sexo e idade **em 19/04/2027**. A idade veio do nascimento na fonte, não do range nem da idade em 31/12. Cálculo: `2027 - ano_nascimento - ((4,19) < (mes_nascimento,dia_nascimento))`.

Excluídos resultados com DNF/DSQ, sem tempo positivo ou sem classificação oficial `rg`/`rn` positiva. Não se eliminou nenhum tempo por um limiar arbitrário. A modalidade foi identificada pelos IDs oficiais 42K ELITE e 42K GERAL, DV e PCD. Nenhum dado operacional foi alterado.

A consulta abaixo guarda a projeção necessária dos 4.629 registros de 42 km, sem nomes, nascimento, contato ou número de peito. A idade já está calculada para Boston. Reexecutar esta célula recalcula **a captura congelada**; uma atualização exige nova captura da cronometragem. Não representa uma consulta em tempo real a tb_resultados.

### Conferências

- 3.604 classificados nos 42 km, incluindo uma cadeirante; 3.603 corredores a pé, sem número de peito duplicado na fonte.
- Datas de nascimento válidas e idade publicada compatível com 31/12/2026 nos 3.604 classificados. A classificação de Boston usa a data de Boston.
- Sem resultado a menos de 1 segundo do índice, portanto o tratamento dos milissegundos não muda esta contagem.
- A idade de Boston acrescenta 6 BQs (5 homens e 1 mulher) ao cálculo que usaria indevidamente 31/12/2026.
- A fonte atual difere da base do portal: o portal ainda tinha 3.594 concluintes geral/elite, enquanto a classificação oficial tem 3.592. O resultado desta análise usa a fonte oficial.

**BQ não é vaga confirmada.** O corte adicional publicado para Boston 2027 é 5min17s: 189 corredores (128 homens e 61 mulheres) também ficam abaixo desse tempo. Não sabemos quem se inscreveu nem quem foi aceito; não chamar esse grupo de inscritos/aceitos.

Os 264 não incluem uma auditoria dos índices específicos para divisões para/adaptadas. Os dois PCD/DV foram contados somente porque atingem a tabela geral.
