#!/usr/bin/env bash
# Run on the verified web host, from a private release directory, after tests.
set -euo pipefail
release_dir="${1:?private release directory required}"
mode="${2:?prepare or publish}"
[[ "$release_dir" =~ ^/var/backups/business-remember-[A-Za-z0-9.]+$ ]] || exit 2
business_webroot=/var/www/business.roadrunners.run
files=(
  services/BusinessRememberDevice.cfc
  includes/backend/business_remember_issue.cfm
  includes/backend/business_remember_request.cfm
  includes/backend/business_remember_revoke.cfm
  includes/backend/business_request_identity.cfm
  includes/backend/business_google_callback.cfm
  logout.cfm
  cadastro/includes/backend.cfm
  bi/Application.cfc
  Application.cfc
)
declare -A baseline=(
  [includes/backend/business_request_identity.cfm]=d47cf29aae9a21b6f5a5b2976a3a13dc19c62df05f1729cbc0c6722a4f534342
  [includes/backend/business_google_callback.cfm]=10c0f7ca431b69424c46dc5529b6d29701978c6a15438b7d6046ab0b89fec415
  [logout.cfm]=f841210f2f5bf8d0738c6164182d914e2e53cbad99955dbb5b165993219b28a8
  [cadastro/includes/backend.cfm]=8c80551d652a1012bd6d2c767e96085a08070ac2688005be770c04d7b937e758
  [bi/Application.cfc]=f368691be15fa65ef4a7c06e75e76a7cfe42f4cad5355e3de0f3e85f1cdab5ae
  [Application.cfc]=7320a875a9055dda24cd709fb2edc65aa37f96e1b41df0e363eb956c14a01ec8
)
check_baseline() {
  local path actual
  for path in "${files[@]}"; do
    if [[ -n "${baseline[$path]:-}" ]]; then
      actual="$(sha256sum "$business_webroot/$path")"
      [[ "${actual%% *}" == "${baseline[$path]}" ]] || { echo "Baseline changed: $path" >&2; exit 3; }
    else
      [[ ! -e "$business_webroot/$path" && ! -L "$business_webroot/$path" ]] || { echo "New target already exists: $path" >&2; exit 3; }
    fi
    [[ -f "$release_dir/candidate/$path" && ! -L "$release_dir/candidate/$path" ]] || exit 4
  done
}
if [[ "$mode" == prepare ]]; then
  [[ ! -e "$release_dir/before" ]] || exit 5
  check_baseline
  mkdir -m 0700 "$release_dir/before"
  for path in "${files[@]}"; do
    if [[ -n "${baseline[$path]:-}" ]]; then
      mkdir -p "$release_dir/before/$(dirname "$path")"
      cp -a "$business_webroot/$path" "$release_dir/before/$path"
    fi
  done
  (cd "$release_dir/candidate" && sha256sum "${files[@]}") > "$release_dir/candidate.sha256"
  echo "Backed up 6 current files; prepared 4 new files."
elif [[ "$mode" == publish ]]; then
  [[ -f "$release_dir/compile.ok" && ! -e "$release_dir/published.log" ]] || exit 6
  check_baseline
  (cd "$release_dir/candidate" && sha256sum --check "$release_dir/candidate.sha256")
  # Every original has a verified private backup before the first replacement.
  for path in "${files[@]}"; do
    if [[ -n "${baseline[$path]:-}" ]]; then
      actual="$(sha256sum "$release_dir/before/$path")"
      [[ "${actual%% *}" == "${baseline[$path]}" ]] || exit 7
    fi
  done
  for path in "${files[@]}"; do
    temporary="$(mktemp "$business_webroot/$(dirname "$path")/.business-remember.XXXXXX")"
    cp "$release_dir/candidate/$path" "$temporary"
    if [[ -n "${baseline[$path]:-}" ]]; then
      chmod --reference="$business_webroot/$path" "$temporary"
      chown --reference="$business_webroot/$path" "$temporary"
    else
      chmod 0644 "$temporary"
      chown root:root "$temporary"
    fi
    mv -f "$temporary" "$business_webroot/$path"
    printf '%s %s\n' "$(date -u +%FT%TZ)" "$path" >> "$release_dir/published.log"
  done
  (cd "$business_webroot" && sha256sum --check "$release_dir/candidate.sha256")
else
  exit 2
fi
