# globals
source "$(dirname "$0")/tui.sh"
source "$(dirname "$0")/../config/defaults.conf"

# search docker hub for an image
function search_image() { # TODO: allow the user to go back and select another image or another query
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
function select_tag() {
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
function configure_container() {
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