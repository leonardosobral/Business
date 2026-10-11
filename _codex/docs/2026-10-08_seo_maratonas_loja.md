# SEO — H1 das maratonas e revisão da loja, 08/10/2026

RR-35 publicado no Road Runners e registrado no painel Business. RR-36 separa
as duplicações da loja, cuja aplicação é externa ao Apache RunnerHub.

## Maratonas

O Semrush de 06/10 apontava 14 páginas sem H1, entre elas a Maratona Internacional
de São Paulo. A inspeção ampliada, a partir de SELECT somente leitura no catálogo,
encontrou 47 maratonas com tag. Todas entregavam HTTP 200 sem H1. O número 47
é a verificação própria destas páginas, não a contagem do erro na amostra Semrush.

O include `includes/estrutura/header_tema.cfm` já envolvia o cabeçalho existente
em H1 para `/org/`, `/timer/` e `/circuito/`. A condição agora inclui `/maratona/`.
Nenhuma outra linha de runtime foi alterada no Road Runners. Mantidos conteúdo,
logo/fallback, links e CSS; o wrapper herda tamanho e peso da fonte.

Validação:

- Baseline local/produção igual; 12 dependências preservadas por hash.
- Um template compilado com Adobe ColdFusion.
- 20 cenários Adobe antes e após publicação: quatro maratonas com/sem tema e
  em modo compacto/normal; 16 controles de org, timer, circuito e evento.
  Conteúdo preservado, exceto wrapper H1 e espaço ao fim de linha do compilador.
- 55 URLs públicas antes/depois, com uma requisição por segundo: 47 maratonas
  passaram de zero a exatamente um H1, todas em 200. Título, descrição, canonical
  e alternates ficaram iguais. Oito controles conservaram status e metadados,
  incluindo alias FCA em 301 e configuração de perfil em 302 para login.
- Navegador em 1280×800 e 390×844: H1 confirmado, dimensões e posição do cabeçalho
  iguais ao baseline, sem overflow horizontal. Override restaurado.
- Nenhum dado de evento, atleta, resultado ou privacidade alterado.

Ausência de H1 é advertência no Semrush. Não descontar esse lote dos 27 erros
históricos nem afirmar ganho de ranking ou indexação.

## Loja e contatos

Seis URLs detalhadas pelo Semrush e a raiz da loja foram verificadas. Catálogo,
página 2, login e inactive usam o mesmo título. Política de privacidade e termos
têm títulos específicos; todas as seis páginas repetem a descrição. A raiz faz
301/302 até inactive, que responde 200 com `X-Robots-Tag: noindex`.

O servidor público informa Heroku; não há vhost da loja no Apache conferido.
Não foi localizado código da aplicação neste projeto. A correção precisa ocorrer
no tema/editor da plataforma responsável. A investigação não altera DNS,
disponibilidade, indexação, cadastro de produtos ou condições comerciais da loja.
RR-36 permanece pendente e contém os endereços e critérios de validação.

Os 11 links restantes de proteção de e-mail permanecem separados. O mecanismo
Cloudflare oculta endereços no HTML e os recupera no navegador via JavaScript,
conforme a [documentação oficial](https://developers.cloudflare.com/waf/tools/scrape-shield/email-address-obfuscation/).
A campanha Semrush está sem renderização JS. Na verificação de privacidade,
o navegador mostrou o contato como link `mailto` e nenhum link residual para
`/cdn-cgi/l/email-protection`. Isso confirma o funcionamento dessa amostra;
não comprova todos os 11 casos. Proteção e contatos foram preservados.

## Medição e publicação

Nova campanha de 5.000 páginas iniciada na interface autenticada do Semrush em
08/10. Configuração observável preservada: móvel, JS desativado. Confirmado
423/5.000 durante a revisão; não era auditoria concluída. RR-32/RR-33/RR-34 já
estavam publicados no início, enquanto RR-35 foi publicado durante a execução.
A nova coleta pode conter a versão anterior em parte das páginas de maratonas;
não concluir ausência de efeito sem revisar URLs e datas.

Painel conserva a auditoria concluída de 06/10: Site Health 75%, IA 78%, 27 erros,
45.495 avisos e 2.328 observações, além da coleta orgânica de 04/10. Nova nota
explicita o rastreamento em andamento. RR-35 concluído, RR-36 pendente.

Business: dois templates compilados e publicados, 19 cenários de renderização
e acesso antes/depois, incluindo oito controles de acesso; dez dependências
preservadas, incluindo dados Semrush, GA4 e guard administrativo.

Também foram renderizados os includes originais de produção em fixture restrita
ao localhost: RR-35, RR-36, timestamp ISO da revisão e aviso da nova coleta
confirmados. A aba autenticada do Chrome mostrou inicialmente a versão anterior;
a recarga foi interrompida pela mudança de aba do usuário. A confirmação visual
da tela autenticada permanece incompleta. Nenhum cache global foi limpo.

Backups recuperáveis:

- `/var/backups/seo-marathon-h1-20261008-rr/baseline` — um arquivo de runtime.
- `/var/backups/seo-marathon-h1-20261008-business-final/baseline` — dois arquivos.

Scripts e recibos: `_codex/staging/seo-issues-followup-20261008/`. Os gates conferem
baseline, hashes testados, compilação e dependências; rollback recusa alterações
concorrentes. Sem commit, push ou PR.

A validação candidata rejeitou os links do subdomínio na lista de URLs da fila,
cujo contrato admite apenas os domínios principais. O guard foi preservado:
RR-36 mantém os destinos externos na evidência, com link fixo na aba Semrush.
O candidato rejeitado não foi publicado; a preparação final usa backup separado.
