# Promoções estáticas — publicação de 11/09/2026

## Resultado

Publicado em **11/09/2026 às 00:28:43 de Brasília** (`2026-09-11T03:28:43Z`, relógio do servidor), após o usuário autorizar a continuidade em resposta à pergunta de publicação dos seis arquivos. A medição foi confirmada em **Business → Audiência e inventário → Posições** com navegação real de teste, identificada como interna. Nenhum SQL adicional, acesso direto ao banco ou alteração de runtime do Business.

## Escopo e recuperação

Foram publicados exclusivamente, nesta ordem, no RoadRunners (`/var/www/roadrunners.com.br`):

1. `assets/js/rr-audience.js`
2. `atleta/parts/sidebar_desktop.cfm`
3. `canal/index.cfm`
4. `desafios/desafio_confirmado.cfm`
5. `includes/estrutura/barra_lateral.cfm`
6. `includes/analytics/bootstrap.cfm`

São cinco identidades de posição em oito ramos possíveis de imagem, conforme a [entrega técnica](2026-09-11_audiencia_promos_estaticas_entrega.md). Nada foi acrescentado ao layout: a medição acompanha as imagens institucionais existentes e suas condições de exibição. O tracker servido em produção foi confirmado como `rr-audience.js?v=27dd026e4ad8`.

- [Manifesto com hashes anteriores/finais](2026-09-11_audience_static_promos_manifest.json).
- [Pacote de seis arquivos](../releases/2026-09-11_audience_static_promos_linux.tar.gz), SHA-256 `c4ee24969fcef97482aa9fe4acdceee64c2c4b39dbbb5977b13baa01162fd3f7`.
- Backup no host `ssh.runnerhub.run`: `/var/backups/rr-audience-static.BUGVqM`.
- Pasta de backup contém pacote, candidato, `before/`, `before.sha256`, `before.metadata`, `guards.sha256`, `runtime.tsv`, `publish.sh` e `published.log`.
- Publicador local: `/private/tmp/rr-static-release.YP6sL4/publish.sh`; cópia persistida no backup remoto.

Os seis hashes de produção coincidiam com os valores anteriores aprovados. Backups foram conferidos antes de cada substituição atômica, com proprietário, grupo e modo preservados. Conferência após publicação e novamente após os testes: **6 hashes/metadados corretos e 31 arquivos protegidos inalterados**, incluindo autenticação, configurações, Ads/cobrança, coletor, backend de eventos e relatório do Business. Apache e `cf2023` permaneceram ativos; sem reinício de serviço.

Se necessário, restaurar somente os seis destinos a partir de `before/`, conferindo o manifesto e preservando os metadados. Não restaurar pastas inteiras. Não há rollback SQL nem exclusão de eventos. Nenhuma reversão foi necessária.

## Evidência ponta a ponta

Chrome autenticado, contexto assinado com `isInternal=true`. Navegação e rolagem normais, sem injeção de eventos, cliques em anunciante, conexão OAuth ou ações de cadastro/desafio. A presença de marcação no HTML sozinha não foi tratada como recepção: os números abaixo foram lidos no Business após os acessos.

Recorte: 7 dias, contexto comercial, todas as UFs, família **Outras páginas**, produção, incluindo internos.

| Posição / dispositivo | Registradas | Institucionais | Montadas | Visíveis | Pedidos / entregas | Ads renderizados / visíveis |
|---|---:|---:|---:|---:|---:|---:|
| `rr-legacy-sidebar-promo` / Desktop | 1 | 1 | 1 | 1 | 0 / 0 | 0 / 0 |
| `rr-legacy-sidebar-marathons` / Desktop | 1 | 1 | 1 | 1 | 0 / 0 | 0 / 0 |
| `rr-legacy-sidebar-marathons` / Mobile | 1 | 1 | 1 | 1 | 0 / 0 | 0 / 0 |

Desktop: `/maratonas/`, viewport 1516×834, imagens carregadas; a promoção superior e a inferior foram trazidas à área visível. Mobile: viewport 390×844, inferior carregada e visível; a superior tinha área zero por seu ancestral responsivo e **não apareceu como posição Mobile**. Não foi observado overflow horizontal na página móvel. Última recepção no recorte móvel: **11/09 00:32, Brasília**.

A página do perfil consultado não continha nenhuma das duas imagens estáticas existentes; nenhuma exposição dessa posição foi reivindicada. Perfil, canal legado e desafio confirmado possuem cobertura local de ramos CFML/contrato descrita na entrega técnica, mas não foram todos confirmados ponta a ponta nesta publicação. Não foram alteradas condições de negócio para forçar sua exibição. O canal legado também não possui tráfego real comprovado pelo levantamento anterior.

Ao terminar, a aba temporária do RoadRunners foi fechada, o viewport restaurado e os filtros originais do Business recompostos: 7 dias, contexto comercial, todas as UFs/páginas/dispositivos, produção e **internos desmarcados**. O painel continuou autenticado e as posições de QA deixaram de aparecer no resultado padrão. Abas preexistentes do usuário preservadas.

## Validação e limites

Preflight independente confirmou oito hashes locais, os seis membros e hashes internos do pacote, seu SHA-256, **87 testes Node** e sintaxe. O controlador repetiu os 87 testes e sintaxe após a publicação; ambos os projetos passaram `git diff --check`. Nenhum byte do runtime revisado foi alterado nesta etapa. SQL/CFML local, cenários extremos e revisões da implementação estão na entrega técnica; não foram confundidos com execução em produção.

As posições são `house`, sem campanha/delivery Ads. Medem oportunidade, montagem e exposição qualificada: pelo menos 50% por um segundo contínuo, imagem carregada e documento visível. Não geram cobrança/consumo de créditos; não há histórico retroativo. Os valores da tabela acima são testes internos, não estimativa de público ou prova de inventário vendável.

Preservados DSN `runner`, permissões de `runner_dba`, login, opt-out/GPC, política de 90 dias, configurações e `tb_log`. Retenção segue independente da contagem; o Business ainda informa rotina instalada sem execução confirmada. Continuam pendentes no plano maior: potencial visual de posições colapsadas, UF física confiável, operação de retenção pelo DBA, projeção comercial com semanas completas e piloto de aquisição com verba aprovada. Remover somente o writer de visualização de evento em `tb_log` continua reservado para o final.
