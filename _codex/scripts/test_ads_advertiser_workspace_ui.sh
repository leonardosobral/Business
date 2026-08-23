#!/usr/bin/env bash

set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root" || exit 2

workspace_files=(
  "ads/home.cfm"
  "ads/includes/workspace_campaigns.cfm"
  "ads/includes/workspace_campaign_form.cfm"
  "ads/includes/workspace_admin.cfm"
  "ads/includes/workspace_history.cfm"
  "ads/includes/payments_home.cfm"
)
failures=0

pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures + 1)); }

require_pattern() {
  local pattern="$1" description="$2"
  if rg -q -i -U --pcre2 -- "$pattern" "${workspace_files[@]}"; then
    pass "$description"
  else
    fail "$description"
  fi
}

reject_pattern() {
  local pattern="$1" description="$2"
  if rg -q -i -U --pcre2 -- "$pattern" "${workspace_files[@]}"; then
    fail "$description"
  else
    pass "$description"
  fi
}

require_pattern 'adsV1WorkspaceView' 'workspace possui estado de navegacao explicito'
require_pattern 'Vis[aã]o geral.*Campanhas.*Saldo e pagamentos.*Hist[oó]rico' 'tarefas extensas ficam separadas em navegacao'
require_pattern 'view=campaigns&amp;mode=new|view=campaigns&mode=new' 'CTA abre o fluxo de nova campanha sob demanda'
require_pattern 'adsV1ShowCampaignForm' 'formulario de campanha possui estado de abertura explicito'
require_pattern '(?s)<cfif[^>]*adsV1ShowCampaignForm[^>]*>.*workspace_campaign_form\.cfm' 'formulario nao e renderizado permanentemente'
require_pattern 'Em andamento.*Rascunhos.*Finalizadas' 'campanhas possuem filtros por ciclo de vida'
require_pattern 'adsV1PlacementLabel' 'locais de exibicao recebem nomes amigaveis'
require_pattern 'P[aá]gina inicial|Busca de eventos|P[aá]gina do evento|Eventos por estado' 'interface apresenta locais em linguagem do anunciante'
require_pattern '(?s)adsV1WorkspaceView[^\n]*EQ[^\n]*"payments".*includes/payments_home\.cfm' 'pagamentos extensos ficam em sua propria area'
require_pattern '(?s)adsV1WorkspaceView[[:space:]]+EQ[[:space:]]+"payments"[[:space:]]+AND[[:space:]]+!VARIABLES\.adsAccessCanViewPayments.*adsV1WorkspaceView[[:space:]]*=[[:space:]]*"overview"' 'area de pagamentos respeita a capacidade da conta'
require_pattern '(?s)<cfif[[:space:]]+VARIABLES\.adsAccessCanViewPayments>.*?view=payments.*?</cfif>' 'navegacao de pagamentos acompanha a permissao'
require_pattern '(?s)adsV1WorkspaceView[^\n]*EQ[^\n]*"admin".*workspace_admin\.cfm' 'operacao financeira interna fica separada do anunciante'
require_pattern '(?s)adsV1WorkspaceView[^\n]*EQ[^\n]*"history".*workspace_history\.cfm' 'historico operacional fica em sua propria area'
require_pattern 'Atividade recente' 'visao geral resume atividade recente'
require_pattern '(?s)<cfif[[:space:]]+VARIABLES\.adsAccessCanManageCampaign>.*?Criar uma campanha.*?<cfelse>.*?Acompanhar campanhas' 'proximos passos nao oferece mutacao a perfil somente leitura'

reject_pattern 'Spots:[[:space:]]*#htmlEditFormat\(replace\(placement_keys' 'lista de campanhas nao expoe chaves tecnicas'
reject_pattern '<div class="ads-v1-code text-muted">#htmlEditFormat\(campaign_id\)#</div>' 'lista de campanhas nao expoe UUID'
reject_pattern '<strong>#htmlEditFormat\(surface\)#</strong>[[:space:]]*<span[^>]*>#htmlEditFormat\(placement_key\)#</span>' 'formulario nao expoe surface e chave tecnicas'
reject_pattern 'API pronta|ledger e budget state|spots nativos|Configuracao CPC' 'tela do anunciante nao usa linguagem interna'
reject_pattern '(href|action)="[^"#\n]*##(campaign-form|payment-credit)' 'links e formularios nao publicam ancora duplicada'
require_pattern 'adsV1PaymentStatusLabel' 'status de pagamento recebe rotulo amigavel'

if (( failures > 0 )); then
  printf '\nADS ADVERTISER WORKSPACE UI: FAIL (%d gates)\n' "$failures" >&2
  exit 1
fi

printf '\nADS ADVERTISER WORKSPACE UI: PASS\n'
