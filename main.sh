#!/bin/bash
# globals
source "$(dirname "$0")/lib/tui.sh"
source "$(dirname "$0")/lib/secrets.sh"
source "$(dirname "$0")/lib/provision.sh"
source "$(dirname "$0")/lib/docker.sh"
VERSION=$(jq -r '.version' "$(dirname "$0")/package.json")

check_single_dep() {
if command -v $1 &>/dev/null; then
    return 0
  else
    print_error "error: the cmd '$1' does not exist"
    exit 1
  fi
}

check_deps() {
  check_single_dep "gpg"
  check_single_dep "ssh"
  check_single_dep "curl"
  check_single_dep "jq"
  check_single_dep "git"
}

main() {
  check_deps
  load_theme
  
  print_header "lathe" "v$VERSION"
  load_org_secrets
  load_personal_secrets
}

main