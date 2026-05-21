# globals
source "$(dirname "$0")/tui.sh"
source "$(dirname "$0")/../config/defaults.conf"

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
prompt_secret() {
  local NAME="$1"
  local TEMP_FILE="$2"
  local VALUE=$(prompt "Enter $NAME:")
  echo "$NAME=$VALUE" >> "$TEMP_FILE"
}
# saving all secrets using prompt_secret
# saves personal secrets (GPG fingerprint only)
save_personal_secrets() {
  local TEMP=$(mktemp)
  trap "rm -f $TEMP" EXIT
  mkdir -p "$HOME/.config/lathe"

  local GPG_FINGERPRINT=$(prompt "Enter your GPG fingerprint:")
  echo "GPG_FINGERPRINT=$GPG_FINGERPRINT" >> "$TEMP"

  gpg --quiet --recipient "$GPG_FINGERPRINT" --encrypt --output "$HOME/.config/lathe/secrets.gpg" "$TEMP"
  print_success "personal secrets saved"
}

# saves org secrets (encrypted for all keys in the secrets repo)
save_org_secrets() {
  local TEMP=$(mktemp)
  trap "rm -f $TEMP" EXIT

  prompt_secret TAILSCALE_AUTH_KEY "$TEMP"
  prompt_secret PORKBUN_API_KEY "$TEMP"
  prompt_secret PORKBUN_SECRET_KEY "$TEMP"

  local recipients=()
  for key in "$SECRETS_REPO/keys"/*.asc; do
    local fingerprint=$(gpg --show-keys --with-colons "$key" 2>/dev/null | grep '^pub' | cut -d: -f5)
    [[ -n "$fingerprint" ]] && recipients+=(--recipient "$fingerprint")
  done
  # encrypt the secrets repo
  gpg --quiet "${recipients[@]}" --encrypt --output "$SECRETS_REPO/secrets/org.gpg" "$TEMP"
  print_success "org secrets saved"
}
# endregion
# endregion 