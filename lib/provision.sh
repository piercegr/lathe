# globals
source "$(dirname "$0")/tui.sh"
source "$(dirname "$0")/../config/defaults.conf"

# outputs next CT number
function next_ct_id() {
    print_text "Fetching CT ID"
    local HIGHEST=${ssh root@$PVE_HOST "pct list | awk 'NR>1 {print \$1}' | sort -n | tail -1"} # cmd by Sonnet 4.6
    if ! [[ "$HIGHEST" =~ ^[+-]?[0-9]+$ ]]; then
        print_warn "Could not find any CT IDs, defaulting to 100"
        HIGHEST=100
    fi
    local NEW_ID = (( HIGHEST + 1 ))
    print_success "New CT ID: $NEW_ID"
    echo $NEW_ID
}