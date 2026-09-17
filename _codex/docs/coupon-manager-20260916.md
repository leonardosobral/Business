# Gerenciador de cupons — 16/09/2026

## Estado da entrega

Implementado localmente e testado com dados sintéticos. **Ainda não publicado.** O SSH para `ssh.runnerhub.run:22` expira mesmo fora do sandbox. Nenhum arquivo ou dado de produção foi alterado nesta tarefa.

## Problema corrigido

O formulário de `/cupons-rr/` e seus handlers estavam copiados do gerenciador de anúncios: salvavam em `ads.tb_ad_eventos` e exibiam CPC, orçamento e público. Foram substituídos por um fluxo específico de cupons nas tabelas existentes `tb_cupom` e `tb_evento_corridas_cupom`.

## Funcionalidades

- Cadastro com código, parceiro, condições, descrição, URL, expiração e disponibilidade.
- Primeiro evento obrigatório; pesquisa autenticada limitada aos eventos operáveis pela identidade/conta efetiva.
- Edição do cupom, ativação/desativação e inclusão/edição/remoção de vínculo com evento.
- Datas de validade e quantidade acordada por evento. Quantidade é informativa: não existe controle de consumo neste módulo.
- Catálogo com busca por código/parceiro/evento, filtros ativo/inativo/expirado, paginação de 20 registros e totais do catálogo acessível.
- Preservação dos vínculos existentes de circuitos/páginas, exibidos para consulta. O novo gerenciador de vínculos opera eventos, conforme o pedido.
- Layout desktop em duas colunas e layout mobile em uma coluna.

## Escopo e segurança

- Global efetivo pode operar todos os cupons; simulação de conta usa as permissões efetivas existentes.
- Operador de conta só altera cupons cujos vínculos diretos sejam TODOS de eventos operáveis e que não possuam vínculos de circuito/página. Compartilhados ficam somente para consulta e administração global.
- Usuário leitor não altera dados; listas e pesquisa não revelam eventos de outras contas.
- Todas as mutações usam POST/CSRF, parâmetros SQL e transação. Edição bloqueia a linha e confere `xmin` para detectar formulários antigos. Mudanças nos vínculos também atualizam a revisão do cupom.
- O cupom não é excluído; a ação é desativar. Desvincular remove somente a associação selecionada. Conta não pode remover seu último vínculo e tornar o cupom inacessível.
- Código/parceiro repetidos são detectados no catálogo autorizado; registros legados repetidos podem ter outros campos editados se código e parceiro não mudarem.
- A UI avisa antes de descartar rascunhos de outro formulário ou ao navegar; evita submissão duplicada.
- Código e condições são para divulgação. Não configura automaticamente o desconto em plataformas externas de inscrição.

## Validação local executada

- Nove testes Node aprovados: rascunhos, envio duplicado, confirmação de ações, busca/JSON/erro, preservação de seleção, edição de vínculo e contrato de autenticação/CSRF.
- CFML executado em Lucee 6.2.8.20 temporário: validação de campos/datas/IDs, consulta parametrizada e literal, paginação limitada, escopo da conta, edição compartilhada negada, revisão desatualizada negada, duplicidade e fluxos de criar/editar/vincular/status com substituto de banco.
- Templates reais de cadastro/edição/vínculos e controller renderizados/compilados localmente. O teste não carrega Application.cfc do Business e não conecta a bancos. O token de sessão nos templates visuais é substituído apenas na cópia temporária devido ao isolamento de sessões do motor de scripts; o controller usa o código original de sessão.
- Preview desktop e iframe de 390px inspecionados no navegador. Botão de editar vínculo preencheu corretamente evento, datas e quantidade. HTML malicioso nos dados sintéticos foi mostrado como texto.
- `node --check` e `git diff --check` aprovados.

## Pendências obrigatórias antes da publicação

1. Restabelecer SSH e comparar os quatro arquivos alterados com a versão original do Git (`index.cfm`, `home.cfm`, `includes/backend.cfm`, `includes/form_campanha.cfm`). Preparar backup recuperável e detectar conflitos antes de upload.
2. Confirmar colunas reais e definição de `public.vw_evento_corridas_cupom`. O schema local de referência (`../RoadRunners/_codex/sql/schema.sql`) e as consultas locais do portal **não filtram `tb_cupom.ativo` nem a expiração geral** nessa view. Se produção corresponder, corrigir a view, preservando colunas/assinatura, para incluir `cp.ativo = true AND (cp.data_expiracao IS NULL OR cp.data_expiracao >= current_date)` nos dois ramos de evento/circuito. Salvar a definição original para rollback. Não publicar o gerenciador antes de validar que desativados/expirados não aparecem no portal.
3. Compilar candidatos com Adobe ColdFusion em diretório privado no servidor, sem iniciar aplicação ou instalar componentes no runtime de produção.
4. Testar SQL real e gravação/rollback em fixture isolada, incluindo quantidade nula, datas, permissões, compartilhamento, conflito e cancelamento completo de transação.
5. Publicar apenas os arquivos de runtime listados abaixo. Conferir interface autenticada, pesquisa de eventos, filtros e casos de acesso de conta/leitor; validar comportamento público do benefício sem criar cupons reais de teste.

## Arquivos de runtime

Alterados: `cupons-rr/index.cfm`, `cupons-rr/home.cfm`, `cupons-rr/includes/backend.cfm`, `cupons-rr/includes/form_campanha.cfm` (formulário antigo aposentado, resposta 410).

Novos: `cupons-rr/includes/CouponService.cfc`, `form_cupom.cfm`, `event-fields.cfm`, `links.cfm`, `cupons-rr/assets/manager.css`, `manager.js`.

O include de onboarding antigo deixa de ser utilizado, mas foi preservado no repositório. Não houve commit/push.

## Reexecutar testes

`node --test _codex/tests/coupon-manager.test.cjs`

O runner `_codex/tests/CouponManagerCheck.java` recebe raiz do projeto e diretório temporário. Requer `lucee.jar`, `servlet.jar` e `jsp.jar` no classpath; a sessão desta tarefa usou `/private/tmp/business-coupons-qa.r7jvbS`. Dependências obtidas do Maven Central, sem instalação no projeto.
