# Oitavo lote factual de datas — 04/10/2026

## Escopo e fontes

| Evento | Percursos | Data anterior | Data confirmada | Fonte |
|---|---|---|---|---|
| Blue Run Santos — 38508 | 60746/60747, 5/10km | 25/10/2026 | 01/11/2026 | [Running Land](https://www.runningland.com.br/blue-run-2026-santos) |
| Toca Raul Barra Mansa — 40176 | 66939/66940, 2/7km | 17/10/2026 | 24/10/2026 | [TicketSports](https://www.ticketsports.com.br/e/CORRIDA+TOCA+RAUL+BARRA+MANSA-86432) e regulamento vinculado |
| Corrida Águia — 43392 | 64868/64870/64871, 3/5/10km | 20/09/2026 | 01/11/2026 | [Tiquet](https://tiquet.com.br/evento/2026-13-corrida-aguia-2026/) e regulamento vinculado |
| Legado Run — 45308 | 63977/63978/63979, 3/6/9km | 08/11/2026 | 01/11/2026 | [TicketSports](https://www.ticketsports.com.br/e/LEGADO+RUN-87806) |
| Morro Beach Run — 47482 | 69133/69134, 5/10km | 25/10/2026 | 01/11/2026 | [Central das Inscrições](https://www.centraldasinscricoes.com.br/evento/2026/corrida-de-rua/morro-beach-run) e regulamento vinculado |

Datas gerais data_inicial/data_final permanecem iguais. Só data_percurso e percurso_bloqueado=true mudam nos12 percursos. A fila nasce de comparação interna entre datas do evento e percursos, não de alertas Google. Seleção por proximidade e possibilidade de confirmação factual; sem inferência de receita.

Página renderizada consultada via navegador para Blue, Toca, Legado e Morro; Águia via web e HTML atual salvo. PDFs Toca/Águia/Morro primeira página conferida visualmente. Blue: regulamento HTML remete a data à página, que exibe1Nov/edição2026. Legado: cabeçalho e texto da página01/11; PDF atual confirma modalidades/programação, mas não traz data literal. HTMLs que retornam apenas estrutura inicial não provam a data; a leitura renderizada é a evidência nesses casos.

## Ajustes complementares e limites

Toca Raul: descriçãoPT/ES com corrida17outubro e kits16/17outubro corrigida para corrida24 e kits23/24. ENcontinuaNULL com fallback. Hashes espanhóis source_hash/description_hash atualizados. Horários da retirada dos kits divergem: página sexta14h/sábado16h; PDFsexta15h/sábado16h30. Horários existentes14h/16h30 foram preservados e não considerados conferidos. Não inferir uma nova hora de retirada; somente datas concordantes foram corrigidas.

Legado: URL de regulamento atualizada para o PDF que a inscrição liga atualmente, `8d17551b81fa4e19ad40521f1e79149c639203965308463912.pdf`; arquivo anterior preservado como evidência no staging. Nenhuma alteração de local, horários, disponibilidade, categorias, inscrições ou resultados.

Q2 Americana e Circuito das Águas continuam sem correção: PDFs cadastrados ainda indicam junho/agosto frente a cadastro outubro, faltando reconciliação completa da fonte atual. Potiretama e Nossa Senhora Aparecida não foram concluídos neste lote. Nenhuma mensagem externa enviada.

## Procedimento

Ensaio e inversão transacionais com comparação integral dos cinco eventos,12 percursos e13 tabelas dependentes. Guards contra concorrência; SQL inverso e backup em `/var/backups/seo-date-eighth-20261004`. Os registros anteriores não são apagados em eventual reversão. Artefatos em `_codex/staging/seo-date-eighth-20261004/`.

## Publicação confirmada

Revisão independente sem bloqueadores. Ensaio, inversão, rejeição de conflito e verificação após commit aprovados: cinco eventos, 12 percursos e 13 tabelas dependentes. Teste público reproduziu textos e links antigos antes; após publicação, 15 URLs PT/EN/ES retornaram 200 com correções presentes e canonical, alternates e JSON-LD preservados. Página espanhola da Toca também conferida no navegador. Histórico privado capturou 13 registros: 12 datas de percurso e um regulamento. Descrições têm antes/depois no backup, pois não pertencem ao trigger atual.

Recontagem: **114 percursos em 60 eventos**, antes 126/65; são divergências internas a conferir. Painel Business atualizado às 11:58 (Brasília), compilado e renderizado antes/depois; hash publicado e cinco dependências verificados. Mantidos 24 itens/18 concluídos/6 pendentes, SH-02 parcial e evidências históricas do Google. Backup do painel: `/var/backups/seo-date-eighth-panel-20261004/baseline`.

Nenhum runtime RoadRunners/OpenResults alterado; somente dados compartilhados e o runtime Business `portal/includes/seo_queue_data.cfm`. Não houve mensagens externas, mudanças de permissões ou operações Git.
