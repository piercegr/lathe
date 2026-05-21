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

# region secrets functions

# loading the gpg secret
load_secrets() {
  local KEY_PATH="$HOME/.config/lathe/secrets.gpg"
  if [[ -f "$KEY_PATH" ]]; then
    source <(gpg --quiet --decrypt "$KEY_PATH")
    return 0
  else
    print_error "error: secrets file not found -> run 'lathe setup' to initialize" # TEMP: 'lathe setup' not made yet
    exit 1
  fi
}

# region saving secrets
# prompting secrets from user
#prompt_secrets() {
#  
#}

# endregion
# endregion 