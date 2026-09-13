# Capacidade e abas do Business — publicação de 12/09/2026

## Resultado

Publicado após o usuário autorizar “pode publicar”. O lote inicial foi ativado às
**20:08:10 de Brasília** (`2026-09-12T23:08:10Z`, relógio do servidor). Uma correção
de compatibilidade da consulta foi publicada às **20:15:16**, e a aba Capacidade
foi confirmada funcionando no Chrome autenticado com dados reais.

Não houve migração, acesso direto ao banco, mudança de credenciais/permissões,
reinício de serviço ou publicação no RoadRunners. A mudança de runtime ficou
restrita a estes seis arquivos, na ordem abaixo. Os hashes são os finais:

| Arquivo | SHA-256 |
| --- | --- |
| `portal/audiencia/queries/capacity.sql` | `e09244e2b4ad1f7e36c87265eff25531cd9f1a67db8b23d0ebe1fab1819aeddb` |
| `portal/audiencia/capacity.cfm` | `8f21e2aad63ebc2bfa3b52ca838b4c4daba609c0e8936ec30f9f2e8f18f150e5` |
| `assets/css/audience-dashboard.css` | `80edebfd25f4da9f61b6ee2be731142c3cd61a248af8f77b404994d9b209efc4` |
| `assets/js/audience-dashboard.js` | `c63bacd81e74ef4f62b9ca3f82ecad5f984490bf8c74a290ec6efc32bc376c47` |
| `portal/includes/audience_backend.cfm` | `4450b16bca39758fab06f18c2f093c89fc77607c6206d5e39318528de5c85e3a` |
| `portal/audiencia/home.cfm` | `465762686af4287e9e6d632cf8003e4ec72d8bb81748aff61dfc35a1fade783d` |

## Backup e integridade

- Host verificado: `ssh.runnerhub.run`; destino `/var/www/business.roadrunners.run`.
- Backup privado: `/var/backups/business-audience-capacity.mpLIx8` (0700).
- Quatro arquivos substituídos têm cópias verificadas em `before/`; SQL e template
  de capacidade eram novos. Os quatro hashes anteriores correspondiam à revisão
  `b2be30b`, sem sobrescrever divergência de outra frente.
- Publicador adaptado do procedimento anterior: staging privado, conferência de
  baseline, cópia de recuperação antes das trocas e rename no mesmo filesystem.
  Proprietário, grupo e modo foram preservados; os arquivos novos usam as mesmas
  permissões das respectivas consultas/views existentes.
- Pacote inicial com exatamente seis membros: SHA-256
  `ceec1ded1dab769f4b1bdf26d1cbb14bf4e44f09ac0bd386c931693c152e3de6`.
  A correção posterior está em `capacity-adobe.sql`; a versão inicial foi
  preservada como `capacity.before-adobe.sql`. Os manifestos inicial e final
  estão em `runtime.initial.tsv` e `runtime.final.tsv`; `runtime.tsv` é o final.
- Conferência final às **20:16:32 BRT**: seis hashes/metadados corretos, quatro
  backups íntegros e 24 arquivos protegidos inalterados. Proteções incluem login,
  configurações, coleta, serviços de Ads, backend de evento e relatórios anteriores.
- Apache e `cf2023` ativos. O SQL de capacidade respondeu HTTP 403 na origem com
  TLS validado. O painel sem sessão respondeu 302; nenhum guard foi removido.
  CSS e JS entregues por HTTP coincidiram com os hashes locais.

## Falha encontrada e corrigida na validação

A primeira leitura autenticada abriu a interface nova e seus contadores, mas a
capacidade retornou indisponibilidade; o log registrou erro de tipo `Application`.
O SQL novo reintroduzia o literal de dois hífens que o parser de parâmetros do
Adobe ColdFusion confunde com comentário, comportamento já reproduzido na
[homologação nativa de 07/09](2026-09-07_audiencia_homologacao_http.md).

A correção foi somente construir o marcador com `repeat('-', 2)`, como já faz
`filter.sql`. O valor continua `--` e a semântica regional não muda. Não foram
alterados parâmetros, datasource, retenção, cálculos ou tratamento de erros.
Os demais relatórios permaneceram independentes durante a falha.

Um guard local de compatibilidade passou de RED a GREEN; ele detecta a forma de
SQL incompatível, não substitui teste do motor Adobe. Os **58 casos PostgreSQL**
da capacidade passaram novamente após a correção, incluindo UF desconhecida e
filtros. A confirmação funcional final foi a própria aba no Adobe de produção.
Os testes locais anteriores não haviam coberto esse parser específico.

## Evidência visual e limites

Chrome autenticado, sem novo login ou troca de conta, recorte de 7 dias, contexto
comercial, todas as UFs/páginas/dispositivos, produção e internos desmarcados.
As seis abas apareceram e a navegação Visão geral → Capacidade funcionou.

Na leitura final da capacidade: **1.673 exposições visíveis**, **2.409 posições
montadas** e **5.842 registradas**. Foram exibidas linhas de banners e nativos,
UF desconhecida e estados identificados, famílias como Home, Busca, Evento e
Estado, além de histórico insuficiente. Exemplos visíveis: banner desktop de
evento em SC com 57 registros, 55 montagens e 41 exposições; banner mobile de
estado em SC com 49 registros, 48 montagens e 42 exposições. São fotografias do
recorte, não números permanentes, audiência única ou promessa de campanha.

As consultas têm caches independentes de até um minuto; o topo e a capacidade
podem exibir momentos de recepção ligeiramente distintos. Não foi gerado tráfego
publicitário nem injetado evento para produzir números. A base de 14/28 dias não
estava madura; não foi alegada validação de cenário numérico em produção.

O controle por aba do navegador falhou e a validação foi concluída pela interface
nativa do Chrome. A aba de audiência foi deixada aberta; abas e filtros de outras
frentes não foram alterados. Não houve nova validação mobile em produção: desktop,
tablet, celular, teclado, filtros e fallbacks têm os testes locais registrados na
[entrega técnica](2026-09-12_audience_capacity_business.md).

## Reversão

Para reverter o lote, restaurar somente `home.cfm`, backend e assets a partir dos
respectivos `before/`, conferindo seus hashes e metadados. Depois, mover os dois
arquivos novos de capacidade para o backup privado, sem restaurar diretórios
inteiros. Não há reversão de migração nem exclusão de eventos. Nenhum rollback
foi necessário; o problema pontual foi corrigido durante a validação.

O agente não criou commit, branch ou push. Um commit concorrente do workspace
incorporou o lote inicial durante o preflight; a correção SQL e este recibo ficam
como alterações locais posteriores. Configuração, autenticação, opt-out/GPC,
retenção e todo `tb_log` permanecem fora das mudanças deste lote.
