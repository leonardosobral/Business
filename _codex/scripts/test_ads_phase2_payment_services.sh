#!/usr/bin/env bash

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RR_ROOT="$(cd "$REPO_ROOT/../RoadRunners" && pwd)"
cd "$REPO_ROOT" || exit 2

failures=0

pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures + 1)); }

require_file() {
    [[ -f "$1" ]] && pass "$2" || fail "$2"
}

require_pattern() {
    if [[ -f "$1" ]] && rg -q -i -U --pcre2 -- "$2" "$1"; then
        pass "$3"
    else
        fail "$3"
    fi
}

reject_pattern() {
    if [[ ! -f "$1" ]] || ! rg -q -i -U --pcre2 -- "$2" "$1"; then
        pass "$3"
    else
        fail "$3"
        rg -n -i -U --pcre2 -- "$2" "$1" >&2 || true
    fi
}

client="ads/components/PagarMeClient.cfc"
service="ads/components/AdsPaymentService.cfc"
migration="$RR_ROOT/_codex/sql/2026-08-21_ads_phase2_payments.sql"
contract_tests="$RR_ROOT/_codex/sql/2026-08-21_ads_phase2_payments_contract_tests.sql"

require_file "$client" "cliente Pagar.me existe"
require_file "$service" "servico de pagamentos Ads existe"

require_pattern "$client" 'fileExists\(expandPath\("/config/pagarme\.local\.cfm"\)\)' "cliente verifica o arquivo local a cada instancia"
require_pattern "$client" 'include[[:space:]]+"/config/pagarme\.local\.cfm"' "cliente carrega o arquivo local fixo"
reject_pattern "$client" 'getenv|System\.getProperty|APPLICATION\.|SERVER\.' "cliente nao usa ambiente nem escopo global para configuracao"
require_pattern "$client" 'enabled[[:space:]]*=[[:space:]]*false' "kill switch nasce desligado"
require_pattern "$client" 'minimumAmountCents[[:space:]]*=[[:space:]]*5000' "cliente preserva compra minima de 5000 centavos"
require_pattern "$client" '(?s)cfhttp\([\s\S]{0,500}timeout[[:space:]]*=[[:space:]]*variables[.]config[.]requestTimeoutSeconds' "cliente aplica timeout no cfhttp"
require_pattern "$client" '(?s)cfhttpparam\([^;]{0,250}name[[:space:]]*=[[:space:]]*"Content-Type"[^;]{0,250}value[[:space:]]*=[[:space:]]*"application/json"' "cliente replica Content-Type funcional do RoadRunners"
require_pattern "$client" '(?s)cfhttpparam\([^;]{0,250}name[[:space:]]*=[[:space:]]*"Authorization"[^;]{0,300}toBase64\(variables[.]config[.]secretKey[[:space:]]*&[[:space:]]*":"\)' "cliente replica Basic Auth funcional do RoadRunners"
require_pattern "$client" '(?s)cfhttpparam\([^;]{0,250}name[[:space:]]*=[[:space:]]*"User-Agent"[^;]{0,250}value[[:space:]]*=[[:space:]]*"RunnerHub-Business-Ads/1[.]0"' "cliente envia o User-Agent exigido pelo checkout Pagar.me V5"
require_pattern "$client" 'cfhttpparam\(type[[:space:]]*=[[:space:]]*"body",[[:space:]]*value[[:space:]]*=[[:space:]]*serializedBody\)' "cliente envia JSON como body bruto"
reject_pattern "$client" 'openConnection\(|HttpURLConnection|charset[[:space:]]*=[[:space:]]*"utf-8"' "cliente nao usa transporte Java interno nem altera o body pelo charset do cfhttp"
require_pattern "$client" '(?s)function[[:space:]]+serializeProviderJson.*?isStruct.*?lCase\(key\).*?isArray.*?serializeJSON.*?reFind\("\^-\?\[0-9\]\+\[\.\]0\+\$".*?reReplace' "serializador fixa chaves minusculas e inteiros JSON sem sufixo decimal"
require_pattern "$client" 'serializedBody[[:space:]]*=[[:space:]]*serializeProviderJson\(arguments[.]body\)' "transporte usa o serializador de chaves minusculas"
require_pattern "$client" 'urlEncodedFormat\(lCase\(key\)\)' "query do provedor fixa nomes minusculos"
require_pattern "$client" 'toBase64\([^\n]*secretKey[^\n]*&[[:space:]]*":"\)' "Basic Auth usa secret como usuario e senha vazia"

require_pattern "$client" 'createPaymentLink' "cliente oferece criacao de checkout"
require_pattern "$client" '"/paymentlinks"' "cliente usa POST /paymentlinks"
require_pattern "$client" 'getOrder' "cliente oferece consulta por pedido"
require_pattern "$client" '"/orders/"' "cliente usa GET /orders/{id}"
require_pattern "$client" 'listOrdersByCode' "cliente oferece busca pelo order_code"
require_pattern "$client" '"/orders"' "cliente usa GET /orders"

for payload_token in \
    '"is_building"[[:space:]]*=[[:space:]]*false' \
    '"type"[[:space:]]*=[[:space:]]*"order"' \
    '"order_code"[[:space:]]*=' \
    '"payment_settings"[[:space:]]*=' \
    '"accepted_payment_methods"[[:space:]]*=[[:space:]]*\[[^]]*"credit_card"[^]]*"pix"' \
    '"operation_type"[[:space:]]*=[[:space:]]*"auth_and_capture"' \
    '"installments"[[:space:]]*=[[:space:]]*\[' \
    'installment_count[[:space:]]*=[[:space:]]*1' \
    '"number"[[:space:]]*=[[:space:]]*installment_count' \
    '"pix_settings"[[:space:]]*=' \
    '"cart_settings"[[:space:]]*=' \
    '"default_quantity"[[:space:]]*=[[:space:]]*1' \
    '"max_paid_sessions"[[:space:]]*=[[:space:]]*1' \
    '"expires_in"[[:space:]]*='
do
    require_pattern "$client" "$payload_token" "payload hospedado contem $payload_token"
done
require_pattern "$client" '(?s)listOrdersByCode.*?sendRequest\("GET",[[:space:]]*"/orders",[[:space:]]*\{[[:space:]]*"code"[[:space:]]*=.*?"page"[[:space:]]*=.*?"size"[[:space:]]*=' "query de reconciliacao preserva nomes minusculos do provedor"
reject_pattern "$client" 'split_settings|boleto_settings|recurrences|card_number|card_token|cvv|security_code' "payload nao contem split, boleto, recorrencia ou dados de cartao"

require_pattern "$client" '(?s)validateCheckoutUrl.*?getScheme\(\).*?"https".*?getHost\(\).*?checkoutHost.*?getPort\(\).*?-1.*?getUserInfo\(\)' "URL do checkout exige HTTPS, host exato, porta padrao e sem userinfo"
require_pattern "$client" 'payment-link\.pagar\.me' "host padrao do checkout e explicito"
require_pattern "$client" 'checkout\.pagar\.me' "host oficial alternativo do checkout de producao e explicito"
require_pattern "$client" 'payment-link-v3\.pagar\.me' "host real do checkout de producao e explicito"
require_pattern "$client" 'payment-link-v3-sdx\.pagar\.me' "host real do checkout sandbox e explicito"
require_pattern "$client" '(?s)function[[:space:]]+isCheckoutHostAllowed.*?mode[[:space:]]+EQ[[:space:]]+"production".*?payment-link[.]pagar[.]me,checkout[.]pagar[.]me,payment-link-v3[.]pagar[.]me' "validacao aceita somente os hosts oficiais de producao"
require_pattern "$client" '(?s)config[.]checkoutHost[[:space:]]*=[[:space:]]*config[.]mode[[:space:]]+EQ[[:space:]]+"production".*?payment-link[.]pagar[.]me.*?payment-link-v3-sdx[.]pagar[.]me' "allowlist do checkout acompanha o modo Pagar.me"
require_pattern "$client" 'normalizePaymentLink' "resposta do link e reduzida a DTO seguro"
require_pattern "$client" 'normalizeOrder' "resposta do pedido e reduzida a DTO seguro"
reject_pattern "$client" 'return[[:space:]]+(response\.data|responseData|raw|payload)[[:space:]]*;' "cliente nao devolve resposta bruta"
require_pattern "$client" '(?s)catch[[:space:]]*\([[:space:]]*any[[:space:]]+providerNetworkError[[:space:]]*\).*?logProviderNetworkError\([[:space:]]*providerNetworkError[[:space:]]*\)' "falha de rede do provedor deixa diagnostico sanitizado"
require_pattern "$client" '(?s)function[[:space:]]+logProviderNetworkError.*?file[[:space:]]*=[[:space:]]*"business_ads_payments".*?stage=provider_http.*?type=.*?message=' "diagnostico registra somente contexto operacional da falha HTTP"
require_pattern "$client" '(?s)statusCode[[:space:]]+LT[[:space:]]+200.*?logProviderRejection\([[:space:]]*statusCode,[[:space:]]*responseBody[[:space:]]*\).*?failureResult' "rejeicao HTTP registra diagnostico estruturado antes do erro estavel"
require_pattern "$client" '(?s)function[[:space:]]+summarizeProviderError.*?deserializeJSON.*?function[[:space:]]+logProviderRejection.*?stage=provider_rejected.*?status=.*?summary=' "diagnostico da rejeicao reduz JSON a status e resumo sanitizado"
reject_pattern "$client" '(?s)(cflog|writeLog)[[:space:]]*\([^;]{0,700}text[[:space:]]*=[[:space:]]*"[^"]*(secretKey|Authorization|serializedBody|arguments[.]body|responseBody)' "diagnostico nao registra segredo, autorizacao, payload ou resposta bruta"
reject_pattern "$client" 'writeDump|writeOutput|systemOutput' "cliente nao imprime diagnostico na resposta"

for sql_function in create_payment_intent attach_payment_checkout transition_payment_intent confirm_payment_credit reverse_payment_credit; do
    require_pattern "$service" "ads\\.${sql_function}[[:space:]]*\\(" "servico chama ads.${sql_function}"
done
require_pattern "$service" 'datasource[[:space:]]*=[[:space:]]*variables\.datasource' "servico usa datasource injetado"
require_pattern "$service" 'variables\.datasource[[:space:]]*=[[:space:]]*"runnerhub"' "datasource padrao e runnerhub"
require_pattern "$service" 'createCheckout' "servico orquestra checkout"
require_pattern "$service" 'reconcileIntent' "servico orquestra reconciliacao"
require_pattern "$service" 'getIntentStatus' "servico oferece estado estreito para painel"
require_pattern "$service" '(?s)create_payment_intent.*?createPaymentLink.*?attach_payment_checkout' "ordem local -> HTTP -> attach esta explicita"
require_pattern "$service" '(?s)provider_payment_link_id.*?checkout_url.*?isCheckoutUrlAllowed' "checkout anexado e reaproveitado somente apos validar a URL"
require_pattern "$service" '(?s)attach_payment_checkout.*?catch.*?checkout_attach_failed' "falha de attach retorna erro estavel"
reject_pattern "$service" '<cftransaction|transactionBegin|transactionCommit|transactionRollback' "chamada HTTP nao fica dentro de transacao CFML"
reject_pattern "$service" '\b(INSERT[[:space:]]+INTO|UPDATE[[:space:]]+ads\.|DELETE[[:space:]]+FROM|MERGE[[:space:]]+INTO)\b' "servico nao faz DML financeiro direto"
reject_pattern "$service" 'secretKey|Authorization|Basic[[:space:]]' "servico nao conhece credencial do provedor"

require_pattern "$migration" "'RHADS-'[[:space:]]*\\|\\|[[:space:]]*replace\\(new_intent_id::text" "order_code SQL usa prefixo RHADS deterministico"
require_pattern "$contract_tests" "order_code[[:space:]]*~[[:space:]]*'\\^RHADS-" "contract test prova o prefixo RHADS"

if (( failures > 0 )); then
    printf '\nADS PHASE 2 PAYMENT SERVICES: FAIL (%d gates)\n' "$failures" >&2
    exit 1
fi

printf '\nADS PHASE 2 PAYMENT SERVICES: PASS\n'
