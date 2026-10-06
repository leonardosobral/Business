# Sétimo lote factual de datas — 04/10/2026

## Escopo confirmado

| Evento | Percursos | Antes | Confirmado | Fonte |
|---|---|---|---|---|
| 3º Circuito Run — 43533 | 61688, 5 km | 20/09/2026 | 24/10/2026 | [RealTiming](https://www.realtiming.com.br/evento/3-circuito-run) |
| 1ª Corrida Empório Prime — 44805 | 62495/62496/62497, 3/5/10 km | 25/10/2026 | 18/10/2026 | [Races: página e regulamento HTML](https://www.races.com.br/1-corrida-emporio-prime) |
| 10 Milhas de Marília — 46084 | 65923/65924/65925, 16,09/5/3 km | 27/09/2026 | 18/10/2026 | [Organizador no Sympla](https://www.sympla.com.br/evento/10-milhas-de-marilia-sp/3456105) |
| 2º Patinhas Run — 47031 | 68590/68591, 6/3 km | 20/09/2026 | 18/10/2026 | [Organizador no Sympla, aviso de nova data](https://www.sympla.com.br/evento/2-patinhas-run/3540094) |

Seleção por proximidade e divergência entre datas; não há inferência de prioridade por receita ou tráfego. As quatro páginas foram consultadas no navegador e seus HTMLs públicos salvos com HTTP200 e hash. Datas gerais dos eventos já corretas; somente as nove datas de percursos e a proteção contra sobrescrita automática foram alteradas nesses registros.

## Textos e categorias

Marília: descrição ainda indicava 26 de setembro e confundia 5km caminhada/3km Kids. Substituições mínimas em PT/EN/ES para 18 de outubro de 2026, 5km corrida, 3km caminhada e Kids separado, sem atribuir distância não confirmada aos Kids. A lista de categorias também incluía caminhada16.09km sem apoio da fonte: passa a `16.09km, 5km, caminhada 3km, kids`. Conjunto numérico de distâncias preservado. Percursos são protegidos antes da atualização do evento, pois o trigger de categorias pode recriar registros desbloqueados. Ensaio e inversão verificam IDs e linhas integrais.

Patinhas: descriçãoPT/ES corrigida nas duas referências a20/09 para18/10; EN continua NULL e usa fallback existente. Demais conteúdos preservados; não equivale a auditoria integral dos patrocinadores, preços ou disponibilidade. Metadados source_hash/description_hash atualizados conforme MD5 do texto armazenado para preservar traduções válidas.

RCC Run Bragança não alterada: cabeçalho e descrição18/10, programação ainda19setembro às17h. Toca Raul e Q2 Americana não incluídos neste lote: os textos locais contêm datas antigas e programação de kits; exigem investigação própria das fontes atuais.

## Validação prévia

Baseline completo de quatro eventos/nove percursos; locks e hashes contra conflito. Aplicação, inversão e rejeição deliberada de estado inesperado aprovadas em transações revertidas, incluindo13 tabelas dependentes. Baseline público12URLs200. Teste de regressão detectou os textos/categorias antigos nas seis versões de Marília/Patinhas antes da publicação. O JSON-LD usa descrição genérica que já refletia a data geral correta e deve permanecer idêntico.

Backup preparado em `/var/backups/seo-date-seventh-20261004-v2`; primeira versão de ensaio, sem correção de categorias, conservada em `/var/backups/seo-date-seventh-20261004`. Nenhuma dessas duas preparações, por si só, confirma publicação. Artefatos locais em `_codex/staging/seo-date-seventh-20261004/`.

## Publicação confirmada

Revisão independente sem bloqueadores: fontes salvas e hashes conferidos, traduções e proteção de IDs validadas. Publicado e verificado em produção: quatro eventos, nove percursos e13 dependências coincidem com o estado ensaiado. Histórico privado registrou exatamente nove datas e uma categoria; descrições não são acompanhadas pelo trigger, mas têm antes/depois no backup. DozeURLs PT/EN/ES retornaram200, todos os testes de texto passaram e canonical/alternates/JSON-LD permaneceram idênticos. Página espanhola de Marília também conferida visualmente no navegador.

Recontagem: **126 percursos em65 eventos**, antes135/69. Divergências pendentes de confirmação, não contagem de erros provados. Painel publicado às10:43(Brasília), um template compilado, relatório/fila renderizados antes/depois, um hash e cinco dependências conferidos. Preservados24 itens/18concluídos/6pendentes, SH-02parcial e evidênciasGoogle históricas. Backup do painel em `/var/backups/seo-date-seventh-panel-20261004/baseline`.

Nenhum runtimeRoadRunners ou OpenResults alterado; dados compartilhados corrigidos e somente o runtimeBusiness `portal/includes/seo_queue_data.cfm` publicado. Nenhum contato externo enviado, nenhuma ampliação de permissões e nenhuma operaçãoGit.
