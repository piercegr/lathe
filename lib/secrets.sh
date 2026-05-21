# globals
source "$(dirname "$0")/tui.sh"

# region GPG checkers
check_gpg_cmd() {
  if command -v gpg &>/dev/null; then
    return 0
  else
    print_error "error: the cmd 'gpg' does not exist"
    exit 1
  fi
}
check_gpg_key() {
  if [[ -n "$(gpg --list-secret-keys 2>/dev/null)" ]]; then
    return 0
  else
    print_error "error: no GPG key found -> run 'gpg --full-generate-key'"
    exit 1
  fi
}
# endregion