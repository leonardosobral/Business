# Central interna do lançamento Q3 — 10/10/2026

Endereço: https://business.roadrunners.run/estudos/lancamento/

A página única reúne hotsite, biblioteca profissional, kit para criadores/imprensa, gestão de convites, notebook, resumo de uma página e quatro PDFs anteriores. O plano de execução v3 é a referência atual; versões anteriores permanecem disponíveis e identificadas. Há atalho na aba Gestão de convites da biblioteca.

## Acesso e arquivos

Apenas o administrador real autenticado pode abrir a central e baixar PDFs. `_admin.cfm` consulta a identidade pessoal via `StudyAccess.dashboard`, que revalida usuário ativo e permissão no banco; empresa selecionada/delegação não concede acesso. Requisições GET e parâmetros estritamente limitados. Não há alteração no notebook, query, campanha, voucher ou acesso comercial.

`arquivo.cfm` aceita aliases fixos: `resumo`, `execucao-v3`, `conselho-v2`, `conselho-v1`, `estrategia-inicial`. Nunca recebe um caminho de arquivo do usuário. A pasta `arquivos` bloqueia acesso HTTP direto por `.htaccess`. Respostas privadas com `no-store`, `noindex` e `nosniff`.

O guia rápido tem uma página A4 paisagem e dez links. Documentos na ordem acima: 1/8/11/6/10 páginas.

## Datas

Piloto proposto com 5–10 leitores em 11–12/10; revisão em 13/10; alvo interno de divulgação 14/10; repercussão 15–21/10. 12/10 é feriado e o plano não depende de respostas externas nessa janela. Janeiro de 2027: propostas de compra antecipada em 06/01 e venda geral em 11/01. Preço R$ 497 / R$ 248,50 continua hipótese. ABRACEO permanece em negociação; não há convite enviado ou campanha ativada por esta entrega.

## Publicação e validação

Publicação isolada sem migração de banco, com baseline, compilação CF e hashes. Novos arquivos: manifesto `/var/backups/study-q3-central-20261010-v2/`. Biblioteca e RequestBoundary: patch do manifesto anterior `/var/backups/study-q3-launch-20261009-v1/`. Operadores e evidências ficam no projeto RoadRunners em `_codex/scripts/deploy_estudo_central.py` e `_codex/staging/central-q3/`.

Verificações: 17 contratos de rotas; HTTP anônimo 401, não admin 403, admin 200; cinco PDFs com bytes idênticos aos publicados e cabeçalho correto; download direto 403; alias inexistente 404; método/parâmetro indevido bloqueado; helper direto 404. Identidade admin de teste somente em aplicação temporária, restrita ao loopback, para leitura; removida ao concluir. O Chrome sem sessão mostra entrada obrigatória; layout revisado em cópia do HTML renderizado no servidor, desktop e 390px, sem overflow. PDF renderizado e revisado visualmente.


## Textos para divulgação — 10/10/2026

Adicionados o release para imprensa e o convite curto para influenciadores elaborados na conversa. A seção `#textos` tem dois blocos recolhíveis, campos de leitura e botões de cópia, com seleção manual como alternativa. Links diretos `#texto-release` e `#texto-convite` abrem o bloco correspondente. O envio continua manual; não houve contato, emissão de voucher ou alteração de permissões. A contagem do kit e a descrição do hotsite foram atualizadas. Fontes numéricas e congelamentos do notebook não foram alterados.

Validação desta inclusão: compilação ColdFusion, renderização administrativa HTTP 200 com ambos os textos íntegros, quinze verificações HTTP de acesso/documentos e sintaxe JavaScript aprovadas. Apenas index.cfm e lancamento.css publicados pelo patch do manifesto existente. A conferência visual desta inclusão não foi concluída: o controle do Chrome ficou indisponível nas duas tentativas; não se afirma teste visual ou de clipboard no navegador.
