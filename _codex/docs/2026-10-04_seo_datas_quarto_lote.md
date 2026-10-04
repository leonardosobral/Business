# Quarto lote de revisão factual de datas — 04/10/2026

Publicado no RoadRunners; evidência atualizada no Business (SH-02 permanece parcial).

| Evento | Data confirmada | Percursos corrigidos | Fonte |
|---|---|---|---|
| LIVE Fortaleza, 37570 | 20/11/2026 | 54298,54299,54300 (5/10/21km) | https://www.liverun.com.br/etapa/live21k-fortaleza-2026 — cabeçalho e regulamento HTML, cap. I art. 1/3 |
| Primavera Campo Grande, 40745 | 11/10/2026 | 61914,61915 (5/10km) | https://www.runningland.com.br/circuito-das-estacoes-2026-primavera-campo-grande — página da etapa; regulamento genérico remete ao calendário |
| TGS Run, 42288 | 22/11/2026 | 64079,64081,64082 (3/5/12km) | https://brasilcorrida.com.br/#/evento/tgs-run-2026 — aviso explícito de adiamento e descrição |
| Reis Magos, 45413 | 18/10/2026 | 64412,64413 (21/5km) | https://www.ticketsports.com.br/e/MEIA+MARATONA+DOS+REIS+MAGOS+2026-87738 — página e PDF ligado, p. 1 §1.1 |

As datas gerais dos quatro eventos já estavam corretas. Dez datas de percursos foram corrigidas com percurso_bloqueado=true, conforme a proteção de edição manual existente. IDs, demais campos de percurso e todas as linhas dependentes preservados. Dois links de regulamento adicionados (LIVE e RunningLand, regulamento HTML na própria página). Apenas a data 15→22 de novembro foi alterada na descrição portuguesa TGS; EN/ES continuam fallback existente. Não foram alterados horários, locais, preços, status de inscrição ou resultados.

Prioridade: 23 visualizações agregadas na janela 27/09/2026 01:34:14 a 04/10/2026 01:34:14 BRT, todos os canais. Não é receita nem tráfego orgânico exclusivamente.

## Caso excluído

IZ1 Telecom, 46585: cabeçalho e descrição TicketSports dizem 01/11/2026, mas PDF atualmente ligado ainda afirma 25/10/2026. PDF lido e página 1 renderizada visualmente. A página também diverge no local entre cabeçalho/descrição. Nenhum campo alterado. Necessária confirmação do organizador ou atualização consistente das fontes; nenhum contato enviado.

## Verificações e publicação

- Baseline com hashes integrais das linhas; ensaio de aplicação com rollback, inversa e teste de drift aprovados.
- Revisão independente /root/date_next_review sem bloqueios. Script gerado coincide com candidato ensaiado.
- Publicação transacional condicionada aos hashes de baseline e estado esperado antes do commit.
- Verificação pós-publicação: quatro eventos, dez IDs de percursos e 13 tabelas dependentes. Backup recuperável /var/backups/seo-date-next-20261004; inverse.sql validado.
- Doze páginas públicas PT/EN/ES 200 antes/depois; canonical/alternates preservados; JSON-LD coincide com baseline ajustado apenas para descrição TGS. Nenhuma data antiga de 15/11 na página TGS; descrição visível também conferida em navegador normal.
- Recontagem:148 percursos em77 eventos futuros fora do intervalo (antes 158/81). São divergências para revisão, não 148 erros confirmados.
- Business: somente portal/includes/seo_queue_data.cfm publicado. Compilação Adobe, renderização real das abas relatório/fila antes/depois, hash e cinco dependências aprovados. Backup /var/backups/seo-date-next-panel-20261004/baseline.24 itens, 18 resolvidos, 6 pendentes; notas técnicas e evidência Google histórica preservadas.

Evidências: Business/_codex/staging/seo-date-next-20261004 e seo-date-next-panel-20261004. O inventário dependencies.json contém somente nomes; contagens/hashes deste lote constam dos recibos reais de ensaio/verificação, não de medições anteriores. Nenhum commit, alteração Cloudflare, rotina de importação, mensagem externa ou alteração OpenResults.
