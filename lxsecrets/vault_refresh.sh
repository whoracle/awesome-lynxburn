#!/usr/bin/env bash
set -euo pipefail

# ---- config ---------------------------------------------------------------

VAULT_ADDR="${VAULT_ADDR:-https://vault.example.com}"
VAULT_AUTH_PATH="${VAULT_AUTH_PATH:-oidc}"     # auth mount path, e.g. "oidc"
VAULT_SKIP_VERIFY="${VAULT_SKIP_VERIFY:-false}"

#
# Keyring selection - store initial token like this:
#
# secret-tool store --label="LABEL_YOU_INTEND_TO_USE" service KEYRING_SERVICE account YOUR_MAIL_ADDRESS
#
# If you don't do that, defaults will take over:
#
# Label: "Vault token for VAULT_ADDR"
# Service: vault
# Account: me@example.org
#
KEYRING_LABEL="${KEYRING_LABEL:-Vault token for $VAULT_ADDR}"
KEYRING_SERVICE="${KEYRING_SERVICE:-vault}"
KEYRING_ACCOUNT="${KEYRING_ACCOUNT:-me@example.org}"

# only used in logging
VAULT_ENV="${VAULT_ENV:-unset}"

# Renew when remaining TTL is below this many seconds.
# Example: 7 days
RENEW_BELOW_SECONDS="${RENEW_BELOW_SECONDS:-604800}"

# Notification app name
NOTIFY_APP_NAME="${NOTIFY_APP_NAME:-vault-token-refresh}"
LXSECRETS_LOGIN_MODE="${LXSECRETS_LOGIN_MODE:-notify}"

# ---- helpers --------------------------------------------------------------

log() {
  printf "[vault-token-refresh] %s | [%s]\t | [%s]\n" "$*" "$VAULT_ENV" "$VAULT_ADDR" >&2
  logger -t vault-token-refresh "$1 | [${VAULT_ENV}] | [${VAULT_ADDR}]"
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

require_cmds() {
  local missing=0
  for cmd in vault secret-tool jq notify-send; do
    if ! have_cmd "$cmd"; then
      log "missing required command: $cmd"
      missing=1
    fi
  done
  (( missing == 0 )) || exit 1
}

keyring_get() {
  secret-tool lookup service "$KEYRING_SERVICE" account "$KEYRING_ACCOUNT" 2>/dev/null || true
}

keyring_set() {
  local token="$1"
  printf '%s' "$token" | secret-tool store \
    --label="$KEYRING_LABEL" \
    service "$KEYRING_SERVICE" \
    account "$KEYRING_ACCOUNT" >/dev/null
}

keyring_clear() {
  secret-tool clear service "$KEYRING_SERVICE" account "$KEYRING_ACCOUNT" >/dev/null 2>&1 || true
}

vault_lookup_json() {
  local token="$1"
  VAULT_ADDR="$VAULT_ADDR" VAULT_TOKEN="$token" VAULT_SKIP_VERIFY=$VAULT_SKIP_VERIFY vault token lookup -format=json
}

vault_renew_json() {
  local token="$1"
  VAULT_ADDR="$VAULT_ADDR" VAULT_TOKEN="$token" VAULT_SKIP_VERIFY=$VAULT_SKIP_VERIFY vault token renew -format=json
}

vault_oidc_login_token() {
  local stdout_file stderr_file rc

  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"

  if VAULT_ADDR="$VAULT_ADDR" VAULT_SKIP_VERIFY=$VAULT_SKIP_VERIFY vault login \
    -method=oidc \
    -path="$VAULT_AUTH_PATH" \
    -token-only >"$stdout_file" 2>"$stderr_file"; then
    cat "$stdout_file"
    rm -f "$stdout_file" "$stderr_file"
    return 0
  fi

  rc=$?
  cat "$stderr_file" >&2 || true
  rm -f "$stdout_file" "$stderr_file"
  return "$rc"
}

json_field() {
  local json="$1"
  local filter="$2"
  jq -r "$filter" <<<"$json"
}

prompt_login_action() {
  notify-send \
    -a "$NOTIFY_APP_NAME" \
    -A login="Login" \
    -A ignore="Ignore" \
    --wait \
    "Vault login needed" \
    "$VAULT_ADDR"
}

login_if_needed() {
  local action new_token

  case "$LXSECRETS_LOGIN_MODE" in
    direct)
      log "starting direct OIDC login for $VAULT_ADDR"
      new_token="$(vault_oidc_login_token)"
      [[ -n "$new_token" ]] || { log "OIDC login returned empty token"; exit 1; }
      keyring_set "$new_token"
      notify-send -a "$NOTIFY_APP_NAME" "Vault login succeeded" "$VAULT_ADDR"
      ;;
    silent)
      log "vault login required for $VAULT_ADDR"
      exit 10
      ;;
    notify|*)
      action="$(prompt_login_action || true)"

      case "$action" in
        login)
          log "user chose login for $VAULT_ADDR"
          new_token="$(vault_oidc_login_token)"
          [[ -n "$new_token" ]] || { log "OIDC login returned empty token"; exit 1; }
          keyring_set "$new_token"
          notify-send -a "$NOTIFY_APP_NAME" "Vault login succeeded" "$VAULT_ADDR"
          ;;
        ignore|"")
          log "user ignored login for $VAULT_ADDR"
          exit 10
          ;;
        *)
          log "unknown notification action: $action"
          exit 11
          ;;
      esac
      ;;
  esac
}

# ---- main -----------------------------------------------------------------

main() {
  require_cmds

  local token lookup_json ttl renewable renew_json

  token="$(keyring_get)"

  if [[ -z "$token" ]]; then
    log "no token in keyring"
    login_if_needed
    exit 0
  fi

  if ! lookup_json="$(vault_lookup_json "$token" 2>/dev/null)"; then
    log "stored token is invalid or expired"
    keyring_clear
    login_if_needed
    exit 0
  fi

  ttl="$(json_field "$lookup_json" '.data.ttl')"
  renewable="$(json_field "$lookup_json" '.data.renewable')"

  if [[ "$ttl" =~ ^[0-9]+$ ]] && (( ttl > RENEW_BELOW_SECONDS )); then
    log "token is healthy; ttl=${ttl}s"
    exit 0
  fi

  if [[ "$renewable" == "true" ]]; then
    log "token below threshold and renewable; attempting renewal"
    if renew_json="$(vault_renew_json "$token" 2>/dev/null)"; then
      ttl="$(json_field "$renew_json" '.auth.lease_duration // .lease_duration // 0')"
      log "renewal succeeded; new ttl=${ttl}s"
      exit 0
    fi
    log "renewal failed"
  else
    log "token below threshold and not renewable"
  fi

  login_if_needed
}

main "$@"
