# Segundo lote de próximos eventos — 04/10/2026

Priorização: cinco próximos eventos ainda não revisados entre os300 mais vistos da medição própria, janela27/09às01:34–04/10às01:34. Porto Alegre23visualizações, Impacto23, Aracaju22, Juiz de Fora20 e Jurerê20, total108. Todos os canais; não é receita nem aquisição orgânica isolada.

## Correções publicadas

- Corrida de Impacto47807: três menções de03/10 em PT e três em ES corrigidas para14/11/2026, conforme Sympla. Percursos2/5/10km estavam em17/10 e foram corrigidos para14/11. Hashes de fonte/tradução ES atualizados; EN ausente continua fallback PT.
- Jurerê39401: início11→10/10/2026 e percursos10/21km no dia10;5/42 permanecem11. Link do regulamento atual substitui PDF antigo.
- Aracaju39399: percursos10/21km01/11→31/10/2026;5/42 permanecem01/11. Regulamento atualizado.
- Porto Alegre43439: meia maratona06→05/06/2027. Regulamento atualizado confirma também5/10km no sábado; mantidos os percursos.
- Juiz de Fora37742: percurso5km10/11→11/10/2026. Adicionado link da página oficial que contém regulamento HTML.

Total: cinco eventos, nove datas de percursos, quatro links de regulamento. Nenhuma alteração de resultados, categorias, distâncias, horários, endereços, inscrição ou disponibilidade.

## Evidência e limites

TicketSports foi conferido no navegador: os três PDFs cadastrados estavam desatualizados. PDFs atuais foram baixados, tiveram hash registrado, texto extraído e primeira página conferida visualmente. Porto Alegre: PDF atual inclui5/10km apesar de a descrição da página omiti-los; não remover por ausência em uma fonte parcial. LIVE tem local divergente entre página (Via São Pedro) e regulamento (estádio), além de diferença de horário; preservar até esclarecimento. Aracaju tem horários divergentes entre PDF/página e exibe Esgotado; disponibilidade não foi alterada neste lote. Jurerê também mantém informações de endereço/inscrição divergentes, fora das correções confirmadas.

QuinzeURLs RoadRunnersPT/EN/ES conferidas antes/depois no navegador. Canonical e alternates preservados. SportsEvent só mudou startDate e frase da data de Jurerê. Descrições de Impacto deixaram de exibir03outubro nas três rotas (ENusaPT). Não comprova indexação ou citações; sem nova auditoria ampla.

## Publicação e recuperação

Backup privado /var/backups/seo-upcoming-second-20261004/. Cinco hashes de eventos e16IDs de percursos protegidos;13tabelas dependentes preservadas. Aplicação e inversão ensaiadas com rollback. Teste de drift forçou erro antes decommit e confirmou baseline intacto. Revisão independente sem achados. Estado publicado verificado. Nenhum runtime público foi alterado; banco compartilhado pode refletir as correções nos consumidores, sem mudar privacidade do OpenResults.

Painel: SH-02 permanece aberto; evidência do lote acrescentada, com22itens/17entregues/5pendentes e notas históricas preservadas. Artefatos em Business/_codex/staging/seo-upcoming-second-20261004/ e seo-upcoming-second-panel-20261004/.

## Fontes

- https://www.sympla.com.br/evento/corrida-de-impacto/3554938
- https://www.liverun.com.br/etapa/live-run-juiz-de-fora-2026 (página e modal)
- https://www.ticketsports.com.br/e/42%C2%AA+MARATONA+INTERNACIONAL+DE+PORTO+ALEGRE+-+2027-86759
- https://www.ticketsports.com.br/e/MARATONA+DE+ARACAJU+2026-74615
- https://www.ticketsports.com.br/e/maratona-de-jurere-or-hospital-sos-cardio-2026-74597

URLs exatas e hashes dos três regulamentos atuais: current-regulations.json. As versões antigas estão preservadas apenas como evidência de substituição.

Próxima investigação: origem das divergências entre data do evento, data de percurso e descrição. Não aplicar sincronização automática indiscriminada: eventos de vários dias precisam de datas por modalidade.
