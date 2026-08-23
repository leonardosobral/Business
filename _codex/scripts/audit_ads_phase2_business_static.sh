#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FAILED=0

if ! command -v rg >/dev/null 2>&1; then
    printf '%s\n' 'Auditoria Ads Fase 2 Business: ERRO: rg e obrigatorio.' >&2
    exit 2
fi

if ! command -v git >/dev/null 2>&1; then
    printf '%s\n' 'Auditoria Ads Fase 2 Business: ERRO: git e obrigatorio.' >&2
    exit 2
fi

candidate_files() {
    local root="$1"
    local file

    while IFS= read -r file; do
        [[ -n "$file" && -f "$root/$file" ]] || continue
        printf '%s\n' "$file"
    done < <(
        git -C "$root" ls-files -co --exclude-standard -- \
            '*.cfm' '*.cfc' '*.cfml' 'config/*' \
            | LC_ALL=C sort -u
    )
}

files_matching() {
    local root="$1"
    local pattern="$2"
    local file

    while IFS= read -r file; do
        [[ -n "$file" ]] || continue
        if rg -q -i -- "$pattern" "$root/$file"; then
            printf '%s\n' "$root/$file"
        fi
    done < <(candidate_files "$root")
}

files_matching_multiline() {
    local root="$1"
    local pattern="$2"
    local file

    while IFS= read -r file; do
        [[ -n "$file" ]] || continue
        if rg -q -i -U -- "$pattern" "$root/$file"; then
            printf '%s\n' "$root/$file"
        fi
    done < <(candidate_files "$root")
}

ads_checkout_evidence() {
    local root="$1"
    local pattern="$2"
    local file

    while IFS= read -r file; do
        [[ -n "$file" ]] || continue
        [[ "$file" == ads/* ]] || continue
        if [[ "$file" == *checkout* || "$file" == *payment* || "$file" == *pagarme* ]] \
            || rg -q -i -- "$pattern" "$root/$file"; then
            printf '%s\n' "$root/$file"
        fi
    done < <(candidate_files "$root")
}

payment_redirect_files() {
    local root="$1"
    local file

    while IFS= read -r file; do
        [[ -n "$file" ]] || continue
        [[ "$file" == ads/* ]] || continue
        [[ "$file" != ads/components/PagarMeClient.cfc ]] || continue
        case "$file" in
            ads/*.cfm|ads/*.cfc) ;;
            *) continue ;;
        esac
        if rg -q -i -- '(cflocation|redirect|location|cfheader|href=).*validatedcheckouturl' "$root/$file"; then
            printf '%s\n' "$root/$file"
        fi
    done < <(candidate_files "$root")
}

report_violation() {
    local rule="$1"
    local matches="$2"
    local match

    [[ -n "$matches" ]] || return 0

    printf 'FALHA: %s\n' "$rule" >&2
    while IFS= read -r match; do
        [[ -n "$match" ]] || continue
        printf '  %s\n' "${match#"$REPO_ROOT"/}" >&2
    done <<< "$matches"
    FAILED=1
}

report_pending() {
    printf 'PENDENTE: %s\n' "$1"
}

has_exact_payment_methods() {
    awk '
        function strip_comments(raw,    line,start,finish,rest) {
            line = raw
            while (html_comment) {
                finish = index(line, "--->")
                if (finish == 0) return ""
                line = substr(line, finish + 4)
                html_comment = 0
            }
            while (block_comment) {
                finish = index(line, "*/")
                if (finish == 0) return ""
                line = substr(line, finish + 2)
                block_comment = 0
            }
            while (index(line, "<!---")) {
                start = index(line, "<!---")
                finish = index(substr(line, start + 5), "--->")
                if (finish == 0) {
                    html_comment = 1
                    return substr(line, 1, start - 1)
                }
                rest = substr(line, start + finish + 8)
                line = substr(line, 1, start - 1) rest
            }
            while (index(line, "/*")) {
                start = index(line, "/*")
                finish = index(substr(line, start + 2), "*/")
                if (finish == 0) {
                    block_comment = 1
                    return substr(line, 1, start - 1)
                }
                rest = substr(line, start + 2 + finish + 1)
                line = substr(line, 1, start - 1) rest
            }
            if (match(line, /(^|[[:space:]])\/\//)) line = substr(line, 1, RSTART - 1)
            return line
        }
        function check_method(value) {
            gsub(/[[:space:]\042\047;]/, "", value)
            if (value == "") {
                return
            }
            if (value == "pix" || value == "credit_card") {
                seen[value] = 1
            } else {
                bad = 1
            }
        }
        {
            line = tolower(strip_comments($0))
            if (line == "") next
            if (!active && line ~ /accepted_payment_methods[\042]?[[:space:]]*[:=]/) {
                sub(/.*accepted_payment_methods[\042]?[[:space:]]*[:=][[:space:]]*/, "", line)
                active = 1
            }
            if (active) {
                if (!opened && line !~ /\[/) {
                    next
                }
                if (!opened) {
                    sub(/^[^\[]*\[/, "", line)
                    opened = 1
                }
                closing = index(line, "]")
                if (closing > 0) {
                    values = substr(line, 1, closing - 1)
                    active = 0
                    closed = 1
                } else {
                    values = line
                }
                count = split(values, methods, ",")
                for (position = 1; position <= count; position++) {
                    check_method(methods[position])
                }
            }
        }
        END {
            exit(!(closed && seen["pix"] && seen["credit_card"] && !bad))
        }
    ' "$1"
}

has_checkout_url_contract() {
    awk '
        function strip_comments(raw,    line,start,finish,rest) {
            line = raw
            while (html_comment) {
                finish = index(line, "--->")
                if (finish == 0) return ""
                line = substr(line, finish + 4)
                html_comment = 0
            }
            while (block_comment) {
                finish = index(line, "*/")
                if (finish == 0) return ""
                line = substr(line, finish + 2)
                block_comment = 0
            }
            while (index(line, "<!---")) {
                start = index(line, "<!---")
                finish = index(substr(line, start + 5), "--->")
                if (finish == 0) { html_comment = 1; return substr(line, 1, start - 1) }
                rest = substr(line, start + finish + 8)
                line = substr(line, 1, start - 1) rest
            }
            while (index(line, "/*")) {
                start = index(line, "/*")
                finish = index(substr(line, start + 2), "*/")
                if (finish == 0) { block_comment = 1; return substr(line, 1, start - 1) }
                rest = substr(line, start + finish + 3)
                line = substr(line, 1, start - 1) rest
            }
            if (match(line, /(^|[[:space:]])\/\//)) line = substr(line, 1, RSTART - 1)
            return line
        }
        {
            line = tolower(strip_comments($0))
            if (line == "") next
            sub(/^[[:space:]]+/, "", line)
            new_function = 0
            if (!inside) {
                if (line ~ /^(public|private|remote|package)[[:space:]].*function[[:space:]]+validatecheckouturl[[:space:]]*\(/ \
                    || line ~ /^function[[:space:]]+validatecheckouturl[[:space:]]*\(/ \
                    || line ~ /^<cffunction[[:space:]]+name=[\042\047]validatecheckouturl[\042\047]/) {
                    declared = 1
                    inside = 1
                    new_function = 1
                    cffunction = (line ~ /^<cffunction/)
                    if (!cffunction) {
                        opens = gsub(/\{/, "{", line)
                        closes = gsub(/\}/, "}", line)
                        depth = opens - closes
                        body_started = (opens > 0)
                    }
                } else {
                    next
                }
            }
            counted_line = 0
            if (!cffunction && !body_started && line ~ /\{/) {
                opens = gsub(/\{/, "{", line)
                closes = gsub(/\}/, "}", line)
                depth = opens - closes
                body_started = 1
                counted_line = 1
            }
            if (line ~ /java[.]net[.]uri|java[.]net[.]URI|parse(uri|url)|createobject[[:space:]]*\([^)]*uri/) parsed = 1
            if (line ~ /if[[:space:]]*\(|<cfif/) {
                condition_text = line
                condition_active = 1
            } else if (condition_active) {
                condition_text = condition_text " " line
            }
            if (condition_active \
                && condition_text ~ /getscheme[[:space:]]*\([^)]*\)/ \
                && condition_text ~ /https/ \
                && condition_text ~ /gethost[[:space:]]*\([^)]*\)/ \
                && condition_text ~ /checkouthost/) {
                validated_condition = 1
                condition_active = 0
            } else if (condition_active && (line ~ /\{/ || line ~ />[[:space:]]*$/)) {
                condition_active = 0
            }
            if (validated_condition && line ~ /(throw|cfthrow)/) rejected = 1
            if (line ~ /return[[:space:]]+[^;]*(normalize|normalized|tostring|uri)/) normalized_return = 1
            if (cffunction && line ~ /<\/cffunction>/) inside = 0
            if (!cffunction && body_started && !new_function && !counted_line) {
                opens = gsub(/\{/, "{", line)
                closes = gsub(/\}/, "}", line)
                depth += opens - closes
                if (depth <= 0) inside = 0
            }
            if (!cffunction && new_function && body_started && depth <= 0) inside = 0
        }
        END {
            exit(!(declared && parsed && validated_condition && rejected && normalized_return))
        }
    ' "$1"
}

has_validated_consumer() {
    awk '
        function strip_comments(raw,    line,start,finish,rest) {
            line = raw
            while (html_comment) {
                finish = index(line, "--->")
                if (finish == 0) return ""
                line = substr(line, finish + 4)
                html_comment = 0
            }
            while (block_comment) {
                finish = index(line, "*/")
                if (finish == 0) return ""
                line = substr(line, finish + 2)
                block_comment = 0
            }
            while (index(line, "<!---")) {
                start = index(line, "<!---")
                finish = index(substr(line, start + 5), "--->")
                if (finish == 0) { html_comment = 1; return substr(line, 1, start - 1) }
                rest = substr(line, start + finish + 8)
                line = substr(line, 1, start - 1) rest
            }
            while (index(line, "/*")) {
                start = index(line, "/*")
                finish = index(substr(line, start + 2), "*/")
                if (finish == 0) { block_comment = 1; return substr(line, 1, start - 1) }
                rest = substr(line, start + finish + 3)
                line = substr(line, 1, start - 1) rest
            }
            if (match(line, /(^|[[:space:]])\/\//)) line = substr(line, 1, RSTART - 1)
            return line
        }
        {
            line = tolower(strip_comments($0))
            if (line == "") next
            sub(/^[[:space:]]+/, "", line)
            if (line ~ /^(\/\/|\/\*|\*|<!---)/) {
                next
            }
            if (line ~ /validatedcheckouturl[[:space:]]*=[^;]*(validatecheckouturl[[:space:]]*\()/) {
                validated = 1
            }
            if (validated && line ~ /(cflocation|redirect|location|cfheader)/ && line ~ /validatedcheckouturl/) {
                redirected = 1
            }
            if (line ~ /href=.*validatedcheckouturl/) {
                validated = 1
                redirected = 1
            }
        }
        END {
            exit(!(validated && redirected))
        }
    ' "$1"
}

example_contract_ok() {
    awk '
        function strip_comments(raw,    line,start,finish,rest) {
            line = raw
            while (html_comment) {
                finish = index(line, "--->")
                if (finish == 0) return ""
                line = substr(line, finish + 4); html_comment = 0
            }
            while (block_comment) {
                finish = index(line, "*/")
                if (finish == 0) return ""
                line = substr(line, finish + 2); block_comment = 0
            }
            while (index(line, "<!---")) {
                start = index(line, "<!---"); finish = index(substr(line, start + 5), "--->")
                if (finish == 0) { html_comment = 1; return substr(line, 1, start - 1) }
                rest = substr(line, start + finish + 8); line = substr(line, 1, start - 1) rest
            }
            while (index(line, "/*")) {
                start = index(line, "/*"); finish = index(substr(line, start + 2), "*/")
                if (finish == 0) { block_comment = 1; return substr(line, 1, start - 1) }
                rest = substr(line, start + finish + 3); line = substr(line, 1, start - 1) rest
            }
            if (match(line, /(^|[[:space:]])\/\//)) line = substr(line, 1, RSTART - 1)
            return line
        }
        {
            line = tolower(strip_comments($0))
            if (line == "") next
            if (line ~ /secretkey[[:space:]]*[:=][[:space:]]*[\042\047][[:space:]]*[\042\047]/) empty_key = 1
            sensitive = "(secretkey|secret_key|secret-key|apikey|api_key|api-key|clientsecret|client_secret|client-secret|accesstoken|access_token|access-token|token|password|authorization)"
            if (line ~ /[\042\047]sk_(live|test|prod)?_?[[:alnum:]]/) bad = 1
            if (line ~ sensitive "[[:space:]]*[:=][[:space:]]*[\042\047][^\042\047]+[\042\047]") bad = 1
            if (line ~ sensitive "[[:space:]]*[:=][[:space:]]*[^[:space:];,\042\047]+") bad = 1
        }
        END { exit(!(empty_key && !bad)) }
    ' "$1"
}

secret_literal_pattern="[\"']sk_(live|test|prod)?_?[[:alnum:]]"
secret_assignment_pattern="VARIABLES[[:space:]]*\\.[[:space:]]*chave_pagarme[[:space:]]*=[[:space:]]*((toBase64|base64Encode)[[:space:]]*\\([[:space:]]*[\"'][^\"']+[\"']|[\"'][^\"']+[\"'])"
runner_dba_pattern="datasource[[:space:]]*=[[:space:]]*[\"']runner_dba[\"']"
one_installment_pattern="(installments?|installment_count|parcelas?)[[:space:]]*[:=][[:space:]]*[\"']?1[\"']?"

report_violation \
    'literal com prefixo de chave secreta Pagar.me em CFML versionado' \
    "$(files_matching "$REPO_ROOT" "$secret_literal_pattern")"

report_violation \
    'VARIABLES.chave_pagarme derivada de literal' \
    "$(files_matching "$REPO_ROOT" "$secret_assignment_pattern")"

if ! git -C "$REPO_ROOT" check-ignore -q -- config/pagarme.local.cfm; then
    report_violation \
        'config/pagarme.local.cfm deve ser ignorado pelo Git' \
        "$REPO_ROOT/.gitignore"
fi

ADS_ROOT="$REPO_ROOT/ads"
if [[ -d "$ADS_ROOT" ]]; then
    ads_card_matches=""
    while IFS= read -r file; do
        if [[ "$file" == ads/* ]] && rg -q -i -- \
            '(numero[[:space:]_-]*cart[aã]o|cart[aã]o[[:space:]_-]*numero|card[[:space:]_-]*(number|no|num)|cardnumber|cc[[:space:]_-]*number|cvv|cvc|security[[:space:]_-]*code|codigo[[:space:]_-]*seguranca|expir(y|ation)[[:space:]_-]*(date|month|year)?|exp_month|exp_year|validade[[:space:]_-]*cart[aã]o)' \
            "$REPO_ROOT/$file"; then
            ads_card_matches+="$REPO_ROOT/$file"$'\n'
        fi
    done < <(candidate_files "$REPO_ROOT")
    report_violation \
        'Business/ads nao pode aceitar numero de cartao, CVV ou validade' \
        "${ads_card_matches%$'\n'}"

    ads_datasource_matches=""
    while IFS= read -r file; do
        if [[ "$file" == ads/* ]] && rg -q -i -- \
            "$runner_dba_pattern" \
            "$REPO_ROOT/$file"; then
            ads_datasource_matches+="$REPO_ROOT/$file"$'\n'
        fi
    done < <(candidate_files "$REPO_ROOT")
    report_violation \
        'novo fluxo Ads nao pode usar datasource="runner_dba"' \
        "${ads_datasource_matches%$'\n'}"
else
    report_pending 'escopo Business/ads ainda nao existe; gates de cartao e datasource aguardam a implementacao'
fi

payment_tables='payment_intents|payment_events|account_financial_holds|account_balances|credit_ledger'
report_violation \
    'CFML nao pode executar DML direto nas tabelas financeiras ads' \
    "$(files_matching_multiline "$REPO_ROOT" "(insert[[:space:]]+into|update|delete[[:space:]]+from|merge[[:space:]]+into|truncate[[:space:]]+table)[[:space:]]+ads\\.(${payment_tables})")"

example="$REPO_ROOT/config/pagarme.local.example.cfm"
if [[ ! -f "$example" ]]; then
    report_pending 'config/pagarme.local.example.cfm ainda nao existe'
elif git -C "$REPO_ROOT" check-ignore -q -- config/pagarme.local.example.cfm; then
    report_violation \
        'config/pagarme.local.example.cfm nao pode ser ignorado' \
        "$example"
elif ! example_contract_ok "$example"; then
    report_violation \
        'config/pagarme.local.example.cfm deve conter secretKey vazio e nenhuma chave sensivel nao vazia' \
        "$example"
else
    printf '%s\n' 'OK: exemplo de configuracao local nao ignorado, com secretKey vazio.'
fi

PAGARME_CLIENT="$ADS_ROOT/components/PagarMeClient.cfc"
checkout_evidence="$(ads_checkout_evidence "$REPO_ROOT" '(accepted_payment_methods|payment-link[.]pagar[.]me|(create|new)[[:space:]_-]*(checkout|payment[[:space:]_-]*link)|PagarMeClient)')"
if [[ ! -f "$PAGARME_CLIENT" ]]; then
    if [[ -n "$checkout_evidence" ]]; then
        report_violation \
            'evidencia de checkout Ads sem Business/ads/components/PagarMeClient.cfc' \
            "$checkout_evidence"
    else
        report_pending 'Business/ads/components/PagarMeClient.cfc ainda nao existe e nao ha evidencia de checkout'
    fi
else
    if ! has_exact_payment_methods "$PAGARME_CLIENT"; then
        report_violation \
            'PagarMeClient deve aceitar exatamente credit_card e pix' \
            "$PAGARME_CLIENT"
    fi

    if rg -q -i -- '(installments?|installment_count|parcelas?)[^;\n]*(2|3|4|5|6|7|8|9|[1-9][0-9])' "$PAGARME_CLIENT"; then
        report_violation \
            'PagarMeClient nao pode configurar duas ou mais parcelas' \
            "$PAGARME_CLIENT"
    elif ! rg -q -i -- "$one_installment_pattern" "$PAGARME_CLIENT"; then
        report_violation \
            'PagarMeClient deve configurar exatamente uma parcela' \
            "$PAGARME_CLIENT"
    fi

    if ! rg -q -i -- 'minimum[[:space:]_-]*amount[[:space:]_-]*cents[[:space:]]*[:=][[:space:]]*5000([^0-9]|$)' "$PAGARME_CLIENT" \
        && ! rg -q -i -- 'minimum[[:space:]_-]*amount[[:space:]_-]*cents[[:space:]]*[:=][[:space:]]*5000([^0-9]|$)' "$example" 2>/dev/null; then
        report_violation \
            'PagarMeClient deve respeitar minimo de 5.000 centavos' \
            "$PAGARME_CLIENT"
    fi

    if ! has_checkout_url_contract "$PAGARME_CLIENT"; then
        report_violation \
            'PagarMeClient deve declarar validateCheckoutUrl, fazer parsing, exigir HTTPS e comparar checkoutHost' \
            "$PAGARME_CLIENT"
    fi

    redirect_consumers="$(payment_redirect_files "$REPO_ROOT")"
    if [[ -z "$redirect_consumers" ]]; then
        report_pending 'consumidor de redirect do checkout ainda nao existe'
    else
        invalid_consumers=""
        while IFS= read -r consumer; do
            [[ -n "$consumer" ]] || continue
            if ! has_validated_consumer "$consumer"; then
                invalid_consumers+="$consumer"$'\n'
            fi
        done <<< "$redirect_consumers"
        report_violation \
            'consumidor de redirect do checkout deve usar URL validada por validateCheckoutUrl ou validatedCheckoutUrl' \
            "${invalid_consumers%$'\n'}"
    fi
fi

voucher_bridge_test="$REPO_ROOT/_codex/scripts/test_ads_voucher_balance_bridge.sh"
if [[ ! -f "$voucher_bridge_test" ]]; then
    report_violation \
        'teste estatico da ponte de vouchers e obrigatorio' \
        "$voucher_bridge_test"
elif ! bash "$voucher_bridge_test"; then
    FAILED=1
fi

if [[ "$FAILED" -ne 0 ]]; then
    printf '%s\n' 'Auditoria Ads Fase 2 Business: REPROVADA.' >&2
    exit 1
fi

printf '%s\n' 'Auditoria Ads Fase 2 Business: APROVADA.'
