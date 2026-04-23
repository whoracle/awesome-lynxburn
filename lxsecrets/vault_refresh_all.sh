#!/usr/bin/env bash
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REFRESH_SCRIPT="${SCRIPT_DIR}/vault_refresh.sh"
VPN_NAME="senec"

log() {
  printf "[vault-token-refresh] [WRAPPER] | %s\n" "$*" >&2
  logger -t vault-token-refresh "[WRAPPER] | $1"
}

#
# Homelab
#
#VAULT_ADDR="https://vault.home.lynxcore.org" \
#    VAULT_SKIP_VERIFY=true \
#    KEYRING_LABEL=SHELL_TF_VAR_vault_token_homelab \
#    KEYRING_SERVICE=vault-homelab \
#    KEYRING_ACCOUNT="anthrax@lynxcore.org" \
#    $REFRESH_SCRIPT

#
# SENEC
#

refresh_vpn_gated_tokens() {
    # CI
    VAULT_ENV="ci" \
        VAULT_ADDR="https://vault-1.${VAULT_ENV}.senecops.com" \
        VAULT_SKIP_VERIFY=true \
        KEYRING_LABEL=SHELL_TF_VAR_vault_token_${VAULT_ENV} \
        KEYRING_SERVICE=vault-senec-${VAULT_ENV} \
        KEYRING_ACCOUNT="m.gerber@senec.com" \
        $REFRESH_SCRIPT

    # PG
    VAULT_ENV="pg" \
        VAULT_ADDR="https://vault-1.${VAULT_ENV}.senecops.com" \
        KEYRING_LABEL=SHELL_TF_VAR_vault_token_${VAULT_ENV} \
        KEYRING_SERVICE=vault-senec-${VAULT_ENV} \
        KEYRING_ACCOUNT="m.gerber@senec.com" \
        $REFRESH_SCRIPT

    # QA
    VAULT_ENV="qa" \
        VAULT_ADDR="https://vault-1.${VAULT_ENV}.senecops.com" \
        KEYRING_LABEL=SHELL_TF_VAR_vault_token_${VAULT_ENV} \
        KEYRING_SERVICE=vault-senec-${VAULT_ENV} \
        KEYRING_ACCOUNT="m.gerber@senec.com" \
        $REFRESH_SCRIPT

    # PROD
    VAULT_ENV="prod" \
        VAULT_ADDR="https://vault-1.${VAULT_ENV}.senecops.com" \
        KEYRING_LABEL=SHELL_TF_VAR_vault_token_${VAULT_ENV} \
        KEYRING_SERVICE=vault-senec-${VAULT_ENV} \
        KEYRING_ACCOUNT="m.gerber@senec.com" \
        $REFRESH_SCRIPT

    # PROD
    VAULT_ENV="prod" \
        VAULT_ADDR="https://vault-iot-1.${VAULT_ENV}.senecops.com" \
        VAULT_SKIP_VERIFY=true \
        KEYRING_LABEL=SHELL_TF_VAR_vault_token_iot_${VAULT_ENV} \
        KEYRING_SERVICE=vault-senec-iot \
        KEYRING_ACCOUNT="m.gerber@senec.com" \
        $REFRESH_SCRIPT
}

# need to be connected to VPN for this to work, else we don't even try.
# STRICTLY speaking only for vault-pg but that will change soon.

nmcli c show --active | grep $VPN_NAME > /dev/null
if [ $? -eq 0 ]
then
  log "VPN is up. Refreshing..."
  refresh_vpn_gated_tokens
else
  log "VPN is down. Enabling and refreshing..."
  nmcli connection up $VPN_NAME --ask > /dev/null
  refresh_vpn_gated_tokens
  log "Disabling VPN again"
  nmcli connection down $VPN_NAME > /dev/null
fi
