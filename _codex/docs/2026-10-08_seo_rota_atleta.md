# SEO — 403 em rota de atleta com espaço, 08/10/2026

Lote RR-34: correção de codificação em três regras Apache, nos dois arquivos
`.htaccess` e `atleta/.htaccess` do Road Runners. Registro no painel Business.

## Evidência e correção da classificação

Última auditoria Semrush disponível nesta revisão: 06/10, campanha 26661911,
5.000 páginas, Site Health 75%, pesquisa IA 78% e 27 ocorrências de erro. O
detalhamento HTTP 4xx tem a rota de atleta com espaço (403), ligada pelo ranking
Trail Run do Circuito Catarinense, e o endpoint de proteção de e-mail (404).

A classificação anterior atribuía o 403 à proteção do perfil. Isso estava
incorreto: as requisições PT/EN/ES reproduziram `AH10411: Rewritten query string
contains control characters or spaces` no Apache, antes da execução do template.
Uma consulta SELECT em transação somente leitura confirmou a existência da tag;
nenhum campo de cadastro, nome, tag, privacidade ou resultado foi alterado.

O template de atleta exige login, inclusive para perfis marcados como públicos.
A correção de URL conserva essa regra e retorna ao fluxo 302 para login. Não
transforma os perfis em páginas indexáveis nem concede acesso a dados pessoais.

A flag `B` foi adicionada às três regras que capturam a tag: a regra portuguesa
no diretório atleta e as duas regras localizadas na raiz. Ela recodifica as
capturas antes de inseri-las na query, conforme a
[documentação oficial do Apache](https://httpd.apache.org/docs/2.4/rewrite/flags.html#flag_b).
As demais regras, filtros e proteções ficaram iguais.

## Verificação

- Baselines local e produção iguais nos dois arquivos.
- 24 cenários em fixture Apache/Adobe restrita ao localhost, com hierarquia raiz
  e diretório atleta: espaços GET/HEAD PT/EN/ES, `+`, `&`, acentos, percentual
  literal, parâmetros de filtro/UTM, arquivos, diretório e entrada direta.
  As seis requisições GET/HEAD com espaço reproduziram 403 no baseline e passaram
  na fixture candidata. O teste de `&` confirma ausência de injeção de parâmetro.
- Sintaxe Apache aprovada antes e após publicação.
- 22 respostas públicas antes/depois: sete antes 403 passaram a 302 para login;
  15 controles conservaram status, destino e metadados observados. Inclui home,
  estado, Night Run 2025/2026, aliases Costa Esmeralda, sitemap, configuração de
  perfil, entrada direta e endpoint de proteção de e-mail.
- Dez dependências preservadas por hash, incluindo Application e os guards de
  login. Nenhuma alteração de autenticação ou Cloudflare.
- Navegador anônimo confirmou a tela de login após acessar a rota corrigida.
- Business: dois templates compilados; 19 cenários de renderização e acesso
  aprovados no candidato e após publicação, incluindo oito controles de acesso.
  Métricas Semrush e coleta orgânica de 04/10 preservadas.

A conferência da tela autenticada do Business e uma nova rodada Semrush pelo
Chrome ficaram indisponíveis porque o Mac estava bloqueado. A publicação foi
verificada por hashes e renderização Adobe dos arquivos publicados; não se
declara uma nova medição Semrush nem conferência visual autenticada.

## Operação

Scripts, baselines e recibos em `_codex/staging/seo-athlete-route-20261008/`.

- Road Runners: somente dois arquivos de runtime, backup recuperável
  `/var/backups/seo-athlete-route-20261008/baseline`.
- Business: somente `portal/includes/seo_queue_data.cfm` e
  `portal/conteudo/seo_semrush.cfm`, backup recuperável
  `/var/backups/seo-athlete-route-panel-20261008/baseline`.
- Os scripts de release rejeitam divergência de baseline, validação, candidato
  ou dependências. O rollback recusa conteúdo posteriormente alterado.

Os totais de 27 erros e 12 links quebrados continuam os da coleta de 06/10.
Uma nova auditoria de 5.000 páginas deve confirmar a baixa do caso, junto aos
lotes RR-32/RR-33. Não descontar ocorrências manualmente. Metadados da loja e
proteção de e-mail permanecem separados.
