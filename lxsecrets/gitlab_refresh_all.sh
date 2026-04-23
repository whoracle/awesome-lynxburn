#!/usr/bin/env bash
set -eu

usage() {
    cat >&2 <<'EOF'
Usage:
  gitlab_refresh_all.sh --config /path/to/gitlab-pats.tsv [--dry-run]

Config format: tab-separated, one entry per line
  gitlab_url<TAB>admin_selector<TAB>token_selector<TAB>threshold_days<TAB>new_lifetime_days<TAB>store_label

Empty lines and lines starting with # are ignored.
EOF
    exit 2
}

log() {
    printf '[gitlab-refresh-all] %s\n' "$*" >&2
    logger -t gitlab-refresh-all "[WRAPPER] | $1"
}

CONFIG=
DRY_RUN=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        --config)
            CONFIG=$2; shift 2 ;;
        --dry-run)
            DRY_RUN=1; shift ;;
        -h|--help)
            usage ;;
        *)
            usage ;;
    esac
done

[ -n "$CONFIG" ] || usage
[ -f "$CONFIG" ] || { log "config not found: $CONFIG"; exit 1; }

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CORE="$SCRIPT_DIR/gitlab_refresh.sh"

[ -x "$CORE" ] || { log "core script not executable: $CORE"; exit 1; }

rc=0

while IFS=$'\t' read -r gitlab_url admin_selector token_selector threshold_days new_lifetime_days store_label || [ -n "$gitlab_url" ]; do
    case "${gitlab_url:-}" in
        ''|'#'*) continue ;;
    esac

    log "processing $gitlab_url :: $store_label"

    if [ "$DRY_RUN" -eq 1 ]; then
        if ! "$CORE" \
            --gitlab-url "$gitlab_url" \
            --admin-selector "$admin_selector" \
            --token-selector "$token_selector" \
            --threshold-days "$threshold_days" \
            --new-lifetime-days "$new_lifetime_days" \
            --store-label "$store_label" \
            --dry-run
        then
            rc=1
        fi
    else
        if ! "$CORE" \
            --gitlab-url "$gitlab_url" \
            --admin-selector "$admin_selector" \
            --token-selector "$token_selector" \
            --threshold-days "$threshold_days" \
            --new-lifetime-days "$new_lifetime_days" \
            --store-label "$store_label"
        then
            rc=1
        fi
    fi
done < "$CONFIG"

exit "$rc"
