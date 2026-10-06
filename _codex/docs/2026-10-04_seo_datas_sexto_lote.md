# Sexto lote factual de datas — 04/10/2026

Publicado e verificado no RoadRunners; painel Business atualizado às 10:34 (Brasília). Seleção por proximidade e divergências de cadastro, sem inferência de receita ou tráfego.

| Evento | Percursos | Antes | Data confirmada | Fonte |
|---|---|---|---|---|
| Comerciário Manacapuru — 48246 | 70765, 5 km | 11/12/2026 | 11/10/2026 | [TicketSports](https://www.ticketsports.com.br/e/CORRIDA+DO+COMERCI%C3%81RIO+-+ETAPA+MANACAPURU+2026-87872), PDF ligado na página |
| Serrinha Runners — 44229 | 64896, 5 km | 22/08/2026 | 17/10/2026 | [Tiquet](https://tiquet.com.br/evento/2026-13-serrinha-runners-2026/), aviso explícito de mudança e regulamento v2 |
| Correr é Massa Apucarana — 45646 | 65042/65043, 5/10 km | 18/10/2026 | 17/10/2026 | [Regulamento Sports360](https://sports360.com.br/wp-content/uploads/Regulamento-CIRCUITO-CORRER-E-MASSA-2.pdf), página TicketSports 87900 |
| Bota Pra Correr Rio — 42850 | 61654/61655, 5/10 km | 15/11/2026 | 18/10/2026 | [Running Land](https://www.runningland.com.br/bota-pra-correr-rio-de-janeiro-2026), página atual e regulamento HTML que remete a data à página |

Somente data_percurso e percurso_bloqueado=true foram alterados. Os quatro eventos permaneceram integralmente iguais. IDs, distâncias, horários, modalidades, descrições PT/EN/ES e dependências preservados. A proteção já existente evita sobrescrita pela geração automática; não significa revisão integral do evento.

## Fontes e exclusões

As páginas selecionadas foram consultadas renderizadas no navegador. Os PDFs de Manacapuru, Serrinha e Apucarana foram baixados da fonte pública e a primeira página conferida visualmente. Serrinha é imagem, sem texto extraível. O regulamento do Rio é genérico e remete a data à página: 18 Out, edição 2026, 5K/10K. O revisor independente confirmou os três PDFs; para Rio usou o registro da consulta CUA, pois seu extrator expirou.

- Corre pela Formatura: página PScronos 11/10, PDF 25/10 e percurso 18/10. Mantido sem alteração por conflito.
- ARDAP Run: página consultada 11/10, cadastro 18/10 e PDF 26/04. Mantido por conflito; não promover PDF antigo à verdade atual.
- Nossa Senhora do Rosário: PDF 26/09 versus cadastro 11/10; página não forneceu confirmação atual suficiente. Mantido.
- Itamaracá Night Run: página com inscrição indisponível, sem confirmação atual suficiente. Mantido.

Nenhum contato ou mensagem enviado aos organizadores. Nenhuma conferência pública criada automaticamente.

## Verificação e reversão

Baseline integral, locks e hashes anteriores; ensaio com rollback, SQL inverso e rejeição deliberada de conflito aprovados. Revisão independente sem bloqueadores. Publicação comparou estado esperado antes do commit; depois conferiu quatro eventos, seis percursos e 13 tabelas dependentes. Histórico privado capturou exatamente seis alterações de data. As 12 páginas PT/EN/ES retornaram 200 e preservaram canonical, alternates e JSON-LD.

Recontagem passou de **141 percursos/73 eventos para 135 percursos/69 eventos** futuros ativos fora do intervalo. São divergências para revisão, não 135 erros já confirmados. SQL inverso e baseline recuperáveis em `/var/backups/seo-date-sixth-20261004`; eventual reversão conserva a auditoria e gera entradas novas. Artefatos em `_codex/staging/seo-date-sixth-20261004/`.

Painel Business: somente `portal/includes/seo_queue_data.cfm` publicado após compilação e render candidato. Hash e cinco dependências conferidos; relatório/fila publicados renderizados no Adobe. Mantidos 24 itens, 18 concluídos e seis pendentes; SH-02 parcial, evidências Google e notas técnicas históricas inalteradas. Backup `/var/backups/seo-date-sixth-panel-20261004/baseline`.
