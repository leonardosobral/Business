#!/usr/bin/env bash
set -u

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
failures=0
checks=0

check() {
  local description="$1"
  local pattern="$2"
  local file="$3"

  checks=$((checks + 1))
  if rg -q --fixed-strings "$pattern" "$repo_root/$file"; then
    printf 'ok - %s\n' "$description"
  else
    printf 'not ok - %s\n' "$description"
    failures=$((failures + 1))
  fi
}

check_absent() {
  local description="$1"
  local pattern="$2"
  local file="$3"

  checks=$((checks + 1))
  if rg -q --fixed-strings "$pattern" "$repo_root/$file"; then
    printf 'not ok - %s\n' "$description"
    failures=$((failures + 1))
  else
    printf 'ok - %s\n' "$description"
  fi
}

check "cadastro cria conta provisoria pendente" "'PENDENTE'::status_conta" "cadastro/includes/backend.cfm"
check "cadastro vincula o owner imediatamente" "'OWNER'::papel_usuario_conta" "cadastro/includes/backend.cfm"
check "cadastro associa solicitacao a conta provisoria" "id_conta," "cadastro/includes/backend.cfm"
check "cadastro entra no workspace apos o envio" "url=\"/\"" "cadastro/includes/backend.cfm"
check_absent "cadastro nao termina mais na tela passiva de recebimento" "<cflocation addtoken=\"false\" url=\"/cadastro/?solicitacao=recebida" "cadastro/includes/backend.cfm"
check "link antigo de recebimento reconhece o responsavel" "qCadastroSolicitacaoRecebidaResponsavel" "cadastro/includes/backend.cfm"
check "login aceita vinculo em conta pendente" "cont.status IN ('ATIVA'::status_conta, 'PENDENTE'::status_conta)" "includes/backend/backend_login.cfm"
check "login aceita solicitacao pendente sem conceder acesso ativo" "businessPendingWorkspace" "includes/backend/backend_login.cfm"
check "contexto separa conta pendente do escopo ativo" "businessPendingAccountId" "includes/backend/business_account_context.cfm"
check "home usa dashboard provisoria" "home_pending_account.cfm" "home_logado.cfm"
check "conta provisoria pode solicitar evento" "businessPendingAccountId" "eventos/includes/backend/backend_evento_solicitacoes.cfm"
check_absent "pedido para conta existente nao pode operar eventos antes da aprovacao" "eventoSolicitacaoEffectiveAccountIds = trim(VARIABLES.businessPendingRequestAccountId)" "eventos/includes/backend/backend_evento_solicitacoes.cfm"
check "historico pendente fica restrito ao solicitante" "AND sol.id_usuario_solicitante" "eventos/includes/backend/backend_evento_solicitacoes.cfm"
check "aprovacao ativa conta provisoria" "SET status = 'ATIVA'::status_conta" "administracao/contas/includes/backend.cfm"
check "recusa desativa vinculo provisorio" "status = 'INATIVO'::status_usuario_conta" "administracao/contas/includes/backend.cfm"
check "home carrega estado da reserva de voucher" "businessPendingVoucherStatus" "includes/estrutura/home_pending_account.cfm"
check "home carrega estado da revisao da campanha" "businessPendingCampaignReviewStatus" "includes/estrutura/home_pending_account.cfm"
check "etapa tres abre a reserva do voucher" "href=\"/ads/?view=payments#ads-voucher-form\"" "includes/estrutura/home_pending_account.cfm"
check "etapa quatro abre a preparacao da campanha" "href=\"/ads/?view=campaigns&amp;mode=new#campaign-form\"" "includes/estrutura/home_pending_account.cfm"
check "home explica estados intermediarios" "Aguardando pré-requisitos" "includes/estrutura/home_pending_account.cfm"
check "home mostra ajustes solicitados" "Ajustes solicitados" "includes/estrutura/home_pending_account.cfm"
check "home explica que preparacao nao publica" "Você pode preparar tudo agora." "includes/estrutura/home_pending_account.cfm"
check "menu da conta nova abre voucher" "href=\"/ads/?view=payments#ads-voucher-form\"" "includes/estrutura/sidenav.cfm"
check "menu da conta nova abre publicidade" "href=\"/ads/?view=campaigns\"" "includes/estrutura/sidenav.cfm"
check "menu mantem conta existente bloqueada" "businessPendingExistingAccountRequest" "includes/estrutura/sidenav.cfm"

if (( failures > 0 )); then
  printf '\n%d de %d verificacoes falharam.\n' "$failures" "$checks"
  exit 1
fi

printf '\n%d verificacoes passaram.\n' "$checks"
