# globals
source "$(dirname "$0")/tui.sh"
source "$(dirname "$0")/../config/defaults.conf"

# outputs next CT number
function next_ct_id() {
    local HIGHEST=${ssh root@$PVE_HOST "pct list | awk 'NR>1 {print \$1}' | sort -n | tail -1"} # cmd by Sonnet 4.6
    echo $(( HIGHEST++ ))
}   