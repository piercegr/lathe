# globals
source "$(dirname "$0")/tui.sh"
source "$(dirname "$0")/../config/defaults.conf"

# search docker hub for an image
search_image() { # TODO: allow the user to go back and select another image or another query
  local QUERY=$(prompt "Search Docker Hub:")
  local RESULTS=$(curl -s "https://hub.docker.com/v2/search/repositories/?query=$QUERY&page_size=10" | jq -r '.results[].repo_name')

  if [[ -z "$RESULTS" ]]; then
    print_error "error: no results found for '$QUERY'"
    exit 1
  fi

  # convert results to array for select_option
  local options=()
  while IFS= read -r line; do
    options+=("$line")
  done <<< "$RESULTS"

  local IMAGE=$(select_option "Select an image:" "${options[@]}")
  echo "$IMAGE"
}

# get available tags for an image
select_tag() {
  local IMAGE="$1"
  local RESULTS=$(curl -s "https://hub.docker.com/v2/repositories/$IMAGE/tags/?page_size=10" | jq -r '.results[].name')

  if [[ -z "$RESULTS" ]]; then
    print_error "error: could not fetch tags for '$IMAGE'"
    exit 1
  fi

  local options=()
  while IFS= read -r line; do
    options+=("$line")
  done <<< "$RESULTS"

  local TAG=$(select_option "Select a tag:" "${options[@]}")
  echo "$TAG"
}

# prompt for container config
configure_container() {
  local IMAGE="$1"
  local TAG="$2"

  local PORTS=$(prompt "Port mappings (e.g. 8080:80) leave blank for none:")
  local VOLUMES=$(prompt "Volume mappings (e.g. /data:/data) leave blank for none:")
  local ENV_VARS=$(prompt "Environment variables (e.g. KEY=value) leave blank for none:")
  local CONTAINER_NAME=$(prompt "Container name:")

  # build docker run command
  local CMD="docker run -d --name $CONTAINER_NAME --restart unless-stopped"
  [[ -n "$PORTS" ]] && CMD="$CMD -p $PORTS"
  [[ -n "$VOLUMES" ]] && CMD="$CMD -v $VOLUMES"
  [[ -n "$ENV_VARS" ]] && CMD="$CMD -e $ENV_VARS"
  CMD="$CMD $IMAGE:$TAG"

  echo "$CMD"
}

# deploy container to CT
deploy_container() {
  local CT_ID="$1"

  local IMAGE=$(search_image)
  local TAG=$(select_tag "$IMAGE")
  local CMD=$(configure_container "$IMAGE" "$TAG")

  # pull image
  ssh root@$PVE_HOST "pct exec $CT_ID -- docker pull $IMAGE:$TAG" &
  spinner $! "Pulling $IMAGE:$TAG..."
  wait $!
  if [[ $? -ne 0 ]]; then
    print_error "error: failed to pull $IMAGE:$TAG"
    exit 1
  fi

  # run container
  ssh root@$PVE_HOST "pct exec $CT_ID -- $CMD" &
  spinner $! "Starting container..."
  wait $!
  if [[ $? -ne 0 ]]; then
    print_error "error: failed to start container"
    exit 1
  fi

  print_success "Container $IMAGE:$TAG deployed to CT $CT_ID"
}