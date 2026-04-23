#!/bin/sh
set -eu

# Manage a single GitLab PAT:
# - read admin PAT from keyring
# - read managed PAT from keyring
# - inspect managed PAT via /personal_access_tokens/self
# - if within threshold, create successor PAT with same scopes for same user
# - write new PAT back to same keyring selector, adding expiry_date as visible attribute
# - revoke old PAT after successful write
#
# Requires: curl jq secret-tool date mktemp

usage() {
    cat >&2 <<'EOF'
Usage:
  gitlab-pat-manage.sh \
    --gitlab-url URL \
    --admin-selector "attr1 val1 attr2 val2 ..." \
    --token-selector "attr1 val1 attr2 val2 ..." \
    [--threshold-days N] \
    [--new-lifetime-days N] \
    [--store-label LABEL] \
    [--dry-run]

Notes:
  - admin-selector and token-selector are raw secret-tool attribute pairs.
  - token-selector must uniquely identify exactly one keyring entry.
  - expiry_date is added as an extra stored attribute for visibility, but should
    not be part of the lookup selector.
EOF
    exit 2
}

log() {
    printf '[gitlab-refresh] [%s] %s\n' "${GITLAB_URL:-unknown}" "$*" >&2
    logger -t gitlab-refresh "$1 | [${GITLAB_URL}]"
}

die() {
    log "ERROR: $*"
    exit 1
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "missing command: $1"
}

json_escape() {
    printf '%s' "$1" | jq -Rsa .
}

append_selector_args() {
    # Input: raw selector string like: "service gitlab host gitlab.example.com kind pat"
    # Output: shell words appended to set --
    # Intentionally uses shell splitting on trusted config input.
    # shellcheck disable=SC2086
    set -- $1
    while [ "$#" -gt 0 ]; do
        printf '%s\037' "$1"
        shift
    done
}

secret_lookup() {
    sel=$1
    # shellcheck disable=SC2086
    secret-tool lookup $sel
}

secret_clear() {
    sel=$1
    # shellcheck disable=SC2086
    secret-tool clear $sel >/dev/null 2>&1 || true
}

secret_store() {
    label=$1
    selector=$2
    expiry=$3
    secret=$4

    # Store using original selector attrs plus visible expiry_date attribute.
    # shellcheck disable=SC2086
    printf '%s' "$secret" | secret-tool store --label="$label" $selector expiry_date "$expiry"
}

curl_json() {
    method=$1
    token=$2
    url=$3
    data_file=${4:-}

    body_file=$(mktemp)
    code_file=$(mktemp)

    if [ -n "$data_file" ]; then
        curl -sS \
            -X "$method" \
            -H "PRIVATE-TOKEN: $token" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            --data @"$data_file" \
            -o "$body_file" \
            -w '%{http_code}' \
            "$url" >"$code_file"
    else
        curl -sS \
            -X "$method" \
            -H "PRIVATE-TOKEN: $token" \
            -H "Accept: application/json" \
            -o "$body_file" \
            -w '%{http_code}' \
            "$url" >"$code_file"
    fi

    code=$(cat "$code_file")
    rm -f "$code_file"
    printf '%s\n%s\n' "$code" "$body_file"
}

parse_date_epoch() {
    d=$1
    date -u -d "${d} 00:00:00 UTC" +%s
}

GITLAB_URL=
ADMIN_SELECTOR=
TOKEN_SELECTOR=
THRESHOLD_DAYS=14
NEW_LIFETIME_DAYS=365
STORE_LABEL="GitLab Personal Access Token"
DRY_RUN=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        --gitlab-url)
            GITLAB_URL=$2; shift 2 ;;
        --admin-selector)
            ADMIN_SELECTOR=$2; shift 2 ;;
        --token-selector)
            TOKEN_SELECTOR=$2; shift 2 ;;
        --threshold-days)
            THRESHOLD_DAYS=$2; shift 2 ;;
        --new-lifetime-days)
            NEW_LIFETIME_DAYS=$2; shift 2 ;;
        --store-label)
            STORE_LABEL=$2; shift 2 ;;
        --dry-run)
            DRY_RUN=1; shift ;;
        -h|--help)
            usage ;;
        *)
            usage ;;
    esac
done

[ -n "$GITLAB_URL" ] || usage
[ -n "$ADMIN_SELECTOR" ] || usage
[ -n "$TOKEN_SELECTOR" ] || usage

require_cmd curl
require_cmd jq
require_cmd secret-tool
require_cmd date
require_cmd mktemp

API_BASE="${GITLAB_URL%/}/api/v4"

ADMIN_PAT=$(secret_lookup "$ADMIN_SELECTOR" || true)
[ -n "${ADMIN_PAT:-}" ] || die "admin PAT not found in keyring"

MANAGED_PAT=$(secret_lookup "$TOKEN_SELECTOR" || true)
[ -n "${MANAGED_PAT:-}" ] || die "managed PAT not found in keyring"

log "retrieving PAT metadata"
set -- $(curl_json GET "$MANAGED_PAT" "$API_BASE/personal_access_tokens/self")
code=$1
body_file=$2

case "$code" in
    200) ;;
    401) rm -f "$body_file"; die "managed PAT is invalid, expired, or revoked" ;;
    *) body=$(cat "$body_file" 2>/dev/null || true); rm -f "$body_file"; die "unexpected HTTP $code from self info endpoint: $body" ;;
esac

token_id=$(jq -r '.id // empty' <"$body_file")
user_id=$(jq -r '.user_id // empty' <"$body_file")
name=$(jq -r '.name // empty' <"$body_file")
description=$(jq -r '.description // empty' <"$body_file")
expires_at=$(jq -r '.expires_at // empty' <"$body_file")
scopes_json=$(jq -c '.scopes // []' <"$body_file")
scopes_csv=$(jq -r '(.scopes // []) | join(",")' <"$body_file")
rm -f "$body_file"

[ -n "$token_id" ] || die "managed PAT metadata missing id"
[ -n "$user_id" ] || die "managed PAT metadata missing user_id"
[ -n "$expires_at" ] || die "managed PAT metadata missing expires_at"

now_epoch=$(date -u +%s)
exp_epoch=$(parse_date_epoch "$expires_at") || die "failed to parse expires_at: $expires_at"
seconds_left=$((exp_epoch - now_epoch))
days_left=$((seconds_left / 86400))

log "token id=$token_id user_id=$user_id scopes=$scopes_csv expires_at=$expires_at (~${days_left}d left)"

if [ "$seconds_left" -le 0 ]; then
    die "managed PAT is already expired"
fi

if [ "$days_left" -gt "$THRESHOLD_DAYS" ]; then
    log "no renewal needed"
    exit 0
fi

new_expiry=$(date -u -d "+${NEW_LIFETIME_DAYS} days" +%F)

log "creating successor PAT with same scopes, new expiry $new_expiry"
payload=$(mktemp)
cleanup_payload() { rm -f "$payload"; }
trap cleanup_payload EXIT HUP INT TERM

jq -n \
    --arg name "$name" \
    --arg description "$description" \
    --arg expires_at "$new_expiry" \
    --argjson scopes "$scopes_json" \
    '{
      name: $name,
      description: (if $description == "" then null else $description end),
      expires_at: $expires_at,
      scopes: $scopes
    }' >"$payload"

if [ "$DRY_RUN" -eq 1 ]; then
    log "dry-run: would create successor for user_id=$user_id and replace keyring secret"
    exit 0
fi

set -- $(curl_json POST "$ADMIN_PAT" "$API_BASE/users/$user_id/personal_access_tokens" "$payload")
code=$1
body_file=$2

case "$code" in
    200|201) ;;
    401|403)
        body=$(cat "$body_file" 2>/dev/null || true)
        rm -f "$body_file"
        die "admin PAT not authorized to create successor token: HTTP $code; body: $body"
        ;;
    *)
        body=$(cat "$body_file" 2>/dev/null || true)
        rm -f "$body_file"
        die "failed to create successor PAT: HTTP $code; body: $body"
        ;;
esac

new_pat=$(jq -r '.token // empty' <"$body_file")
new_id=$(jq -r '.id // empty' <"$body_file")
new_expires_at=$(jq -r '.expires_at // empty' <"$body_file")
rm -f "$body_file"

[ -n "$new_pat" ] || die "GitLab did not return the new PAT value"
[ -n "$new_expires_at" ] || die "GitLab did not return the new PAT expiry"

log "verifying successor PAT"
set -- $(curl_json GET "$new_pat" "$API_BASE/personal_access_tokens/self")
code=$1
body_file=$2
case "$code" in
    200) rm -f "$body_file" ;;
    *)
        body=$(cat "$body_file" 2>/dev/null || true)
        rm -f "$body_file"
        die "successor PAT verification failed: HTTP $code; body: $body"
        ;;
esac

log "updating keyring entry"
secret_clear "$TOKEN_SELECTOR"
secret_store "$STORE_LABEL" "$TOKEN_SELECTOR" "$new_expires_at" "$new_pat"

log "revoking old PAT id=$token_id"
set -- $(curl_json DELETE "$ADMIN_PAT" "$API_BASE/personal_access_tokens/$token_id")
code=$1
body_file=$2
rm -f "$body_file"

case "$code" in
    204) ;;
    200) ;;
    *)
        die "new PAT stored, but failed to revoke old PAT id=$token_id (HTTP $code)"
        ;;
esac

log "done: replaced PAT id=$token_id with new id=$new_id expiring $new_expires_at"
