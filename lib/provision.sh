# globals
source "$(dirname "$0")/tui.sh"
source "$(dirname "$0")/../config/defaults.conf"

# outputs next CT number
function next_ct_id() {
    print_text "Fetching CT ID"
    local HIGHEST=$(ssh root@$PVE_HOST "pct list | awk 'NR>1 {print \$1}' | sort -n | tail -1") # cmd by Sonnet 4.6
    if ! [[ "$HIGHEST" =~ ^[0-9]+$ ]]; then
        print_warn "Could not find any CT IDs, defaulting to 100"
        HIGHEST=100
    fi
    local NEW_ID=(( HIGHEST + 1 ))
    print_success "New CT ID: $NEW_ID"
    echo $NEW_ID
}

# gets template for CT
function download_template() {
    if [[ -z "$(ssh root@$PVE_HOST "pveam list $CT_STORAGE | grep '$CT_TEMPLATE'")" ]]; then
        print_text "$CT_TEMPLATE not found, downloading now"
        ssh root@$PVE_HOST "pveam download $CT_STORAGE $CT_TEMPLATE"
        if [[ $? -ne 0 ]]; then
            print_error "error: could not download $CT_TEMPLATE"
            exit 1
        else
            print_success "$CT_TEMPLATE downloaded successfully"
        fi
    else
        print_text "$CT_TEMPLATE exists, no need to download"
    fi
}