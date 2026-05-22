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