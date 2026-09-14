# Interesse nas provas — audiência nova

Atualização posterior: os critérios de “Em alta” descritos abaixo foram substituídos
pela [regra semanal/mensal para baixo volume](/Users/Shared/Projects/RunnerHub/Business/_codex/docs/2026-09-14_event_interest_highlights.md).
Este documento preserva a implantação inicial e seus resultados de validação.

## Escopo

Migração de `/portal/eventos-analytics/` para `audience.events`, sem migrar ou somar
o legado `tb_log`. Apenas Road Runners em produção; tráfego interno excluído por
padrão. Tela administrativa existente, DSN `runnerhub`, consultas somente leitura.

Arquivos de runtime: `portal/eventos-analytics/home.cfm`,
`portal/includes/event_interest_backend.cfm`,
`portal/audiencia/queries/event_interest.sql` e `event_agenda.sql`.
O leitor legado permanece intacto para recuperação; a página nova não o inclui.

## Definições

- Abertura: `page_view`, família e conteúdo `event`, deduplicado por `page_view_id`.
  Totais antes da paginação (50 provas); visitantes e sessões distintos no recorte.
- Em alta: provas ativas de hoje/futuras; últimos dois dias completos contra os
  dois anteriores em Brasília. Crescimento positivo, mínimo 10 visitantes recentes
  e 5 anteriores. Exige sinais nos quatro dias e registro anterior à base;
  isso não certifica coleta ininterrupta. Ordem por ganho absoluto de visitantes.
  A comparação permanece fixa ao mudar o período de acessos. Não prevê vendas.
- Agenda: saldo atual de atletas distintos em `tb_evento_corridas_checkin`, sem
  fornecedor, estados `calendario`/`inscricao`. Categorias podem se sobrepor.
  Compartilhado entre portais; não é inclusão no período, pagamento ou conversão.
- Revisão de cadastro: localização, descrição, imagem, percursos e inscrição para
  provas não encerradas. Futuras primeiro, depois aberturas. Campos herdados podem
  suprir ausências do cadastro-base; não são erros confirmados. Até 20 prioridades.
- Origem: até 30 combinações realmente observadas; UF do acesso separada da UF
  da prova. Faixa de tela não identifica aparelho. Sequências entre eventos da
  mesma sessão não representam necessariamente clique direto.
- Histórico iniciado em 08/09/2026 com implantação progressiva; retenção 90 dias.
  Recusa/bloqueadores limitam cobertura. Não há garantia de eliminar todos os bots.

Filtros: 1/7/30/90 dias, UF da prova, nome/cidade/ID, futuras/passadas, internos,
detalhe de prova. Abas: Mais acessadas, Em alta, Melhorar cadastros, Origem,
Público e navegação, Como interpretar. Cache de leitura até 1 minuto.
Falha de audiência mostra indisponibilidade, nunca zero fictício. Agenda pode
falhar separadamente sem esconder os acessos.

## Validação

- SQL real em PostgreSQL local isolado: 28 verificações de contagens, deduplicação,
  cobertura, filtros, IDs fora do catálogo/oversized, paginação e agenda; mais uma
  asserção de proteção do índice do catálogo.
- CFML local: 10 cenários renderizados, incluindo seis abas, vazio, indisponível,
  agenda indisponível, acesso negado antes do banco e escaping de conteúdo.
- Compatibilidade de SQL com parser Adobe: passou. Publicador reversível: 15 testes.
- Layout local em desktop e 390 px. Compilação nativa Adobe dos dois CFM: passou.

## Publicação e desempenho

Primeira tentativa `business-event-interest.204bd0f4814f` revertida: consulta
atingiu o limite de 20 s. EXPLAIN administrativo revelou varredura repetida do
catálogo porque `id_evento` era convertido para texto. Corrigido convertendo apenas
o ID da audiência, com regex e limite de inteiro; a chave do catálogo permanece
indexável, sem migração. Consulta real corrigida: 330 ms, 1.443 aberturas, 850
visitantes, 937 sessões, 858 provas (08/09 a 14/09/2026 12:43 BRT).

Timeouts locais ao leitor: 3 s para disponibilidade, 8 s para audiência, 4 s para
agenda; limite global do sistema não foi alterado. Diagnóstico administrativo
temporário retirado de runtime e preservado no backup privado, com baseline
original restaurado antes do segundo preparo. Nenhum dado de banco foi modificado.

Release corrigida preparada em `/var/backups/business-event-interest.d6c8b786a631`.
Recibos locais `2026-09-14_event_interest_release_v2*.json`. Publicador confere
baseline, backups, hashes e 115 guardas; publica dependências antes da página.
Não inclui mudanças de SEO, autenticação, configuração ou outras frentes.

Publicação corrigida concluída e verificada em 14/09/2026, por volta de 12:45–12:48
BRT: quatro arquivos e 115 guardas conferidos. Tela autenticada confirmou os mesmos
totais do diagnóstico e agenda real (ex.: Floripa 2026, 165 atletas distintos,
31 quero ir e 138 inscritos, com sobreposição). Detalhe da prova: 38 aberturas,
24 visitantes, 26 sessões. Filtro SC + futuras: 52 aberturas em 29 provas.

As seis abas, detalhe, filtro de 90 dias e filtro SC/futuras foram exercitados em
produção. OpenResults apareceu em Origem (57 aberturas com a campanha identificada,
mais 1 sem campanha no recorte observado). Nenhuma prova satisfez a regra de alta
nessa janela; a tela exibe o estado vazio e os critérios. UF de acesso estava
ausente nas aberturas do recorte: exibida como “Não identificada”, sem substituir
pela UF da prova. Não houve alteração da coleta geográfica nesta tarefa.

Desktop e carregamento inicial em 390 px verificados visualmente em produção.
Conteúdo com 358 px e sem extravasamento; tabela em contêiner próprio de rolagem
(326 px disponíveis para 667 px de conteúdo). Viewport restaurado ao final.
Sem login, página responde 302; leitura direta do SQL e do backend responde 403.
Revisão independente final: nenhum P1/P2 nos deltas. Sem necessidade de SQL de
instalação, mudanças em permissões, configurações ou dados.
