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
  local NEW_ID=$(( HIGHEST + 1 ))
  print_success "New CT ID: $NEW_ID"
  echo $NEW_ID
}

# gets template for CT
function download_template() {
  if [[ -z "$(ssh root@$PVE_HOST "pveam list $CT_STORAGE | grep '$CT_TEMPLATE'")" ]]; then
    print_text "$CT_TEMPLATE not found, downloading now"
    ssh root@$PVE_HOST "pveam download $CT_STORAGE $CT_TEMPLATE" &
    spinner $! "Downloading $CT_TEMPLATE..."
    wait $!
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

# creating the CT
function create_ct() {
  # CT specifics
  local CT_ID=$(next_ct_id)
  local HOSTNAME=$(prompt "Enter CT hostname:")
  print_accent "Please generate a secure passphrase and save it to your password manager"
  local CT_PASSWORD=$(prompt_secure "Enter CT root passphrase:")

  # default to defaults.conf values
  local MEMORY=$CT_MEMORY
  local CORES=$CT_CORES
  local DISK=$CT_DISK
  local STORAGE=$CT_STORAGE
  local BRIDGE=$CT_BRIDGE

  if ! confirm "Quick Deploy? (Use default CT settings)" y; then
    MEMORY=$(prompt "Memory in MB [$CT_MEMORY]:")
    CORES=$(prompt "CPU cores [$CT_CORES]:")
    DISK=$(prompt "Disk size in GB [$CT_DISK]:")
    STORAGE=$(prompt "Storage [$CT_STORAGE]:")
    BRIDGE=$(prompt "Network bridge [$CT_BRIDGE]:")
    MEMORY=${MEMORY:-$CT_MEMORY}
    CORES=${CORES:-$CT_CORES}
    DISK=${DISK:-$CT_DISK}
    STORAGE=${STORAGE:-$CT_STORAGE}
    BRIDGE=${BRIDGE:-$CT_BRIDGE}
  fi

  # ensure template is ready
  download_template

  # create the CT
  ssh root@$PVE_HOST "pct create $CT_ID local:vztmpl/${CT_TEMPLATE}_amd64.tar.zst \
    --hostname $HOSTNAME \
    --password $CT_PASSWORD \
    --storage $STORAGE \
    --memory $MEMORY \
    --cores $CORES \
    --rootfs $STORAGE:$DISK \
    --net0 name=eth0,bridge=$BRIDGE,ip=dhcp \
    --unprivileged 1 \
    --features nesting=1" &
  spinner $! "Creating CT $HOSTNAME..."
  wait $!
  if [[ $? -ne 0 ]]; then
    print_error "error: failed to create CT $HOSTNAME"
    exit 1
  fi

  print_success "CT $HOSTNAME ($CT_ID) created"
}