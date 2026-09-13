#!/bin/sh
# Executar no servidor, após cfcompile da área candidate. Sem migração ou reinício.
set -eu
stage=/var/backups/business-helpdesk-ai.psFjhh
root=/var/www/business.roadrunners.run
expected=b040f5ae19e4b1867f199522a72b1aad6fcb1426d209db74c4be31e3889bc77e
test "$(sha256sum "$stage/baseline/helpdesk/home.cfm" | cut -d ' ' -f 1)" = "$expected"
cmp "$stage/baseline/helpdesk/home.cfm" "$root/helpdesk/home.cfm"
test "$(sha256sum "$root/helpdesk/ai-draft.cfm" | cut -d ' ' -f 1)" = "830b4f1509903f299f5bf6e3a333e35c2153e058d55b92e3b2c3da9190155a1c"
test "$(sha256sum "$root/helpdesk/includes/HelpdeskAI.cfc" | cut -d ' ' -f 1)" = "027e5b6264c849e056d455182880804f4185d0eeb182b59ddcff5132097b7837"
mkdir -p "$stage/baseline/helpdesk/includes"
cp -p "$root/helpdesk/ai-draft.cfm" "$stage/baseline/helpdesk/ai-draft.cfm"
cp -p "$root/helpdesk/includes/HelpdeskAI.cfc" "$stage/baseline/helpdesk/includes/HelpdeskAI.cfc"
for relative in helpdesk/includes/ai-editor.cfm helpdesk/assets/ai-draft.js; do
  test ! -e "$root/$relative"
done
mkdir -p "$root/helpdesk/assets"
for relative in helpdesk/includes/HelpdeskAI.cfc helpdesk/includes/ai-editor.cfm helpdesk/assets/ai-draft.js helpdesk/ai-draft.cfm helpdesk/home.cfm; do
  cp "$stage/candidate/$relative" "$root/$relative.helpdesk-ai-new"
  chown --reference="$root/helpdesk/home.cfm" "$root/$relative.helpdesk-ai-new"
  chmod --reference="$root/helpdesk/home.cfm" "$root/$relative.helpdesk-ai-new"
  mv "$root/$relative.helpdesk-ai-new" "$root/$relative"
  cmp "$stage/candidate/$relative" "$root/$relative"
done
sha256sum "$root/helpdesk/home.cfm" "$root/helpdesk/ai-draft.cfm" "$root/helpdesk/includes/HelpdeskAI.cfc" "$root/helpdesk/includes/ai-editor.cfm" "$root/helpdesk/assets/ai-draft.js"
