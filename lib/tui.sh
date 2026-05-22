# globals
RESET="\033[0m"
source "$(dirname "$0")/../config/defaults.conf"

# sets the input hex into making the outputs that color
hex_to_ansi() {
  local HEX=${1#'#'}
  local R_HEX=${HEX:0:2}
  local G_HEX=${HEX:2:2}
  local B_HEX=${HEX:4:2}
  local R_DEC=$((16#$R_HEX))
  local G_DEC=$((16#$G_HEX))
  local B_DEC=$((16#$B_HEX))
  printf "\033[38;2;${R_DEC};${G_DEC};${B_DEC}m"
}

# sourcing / loading theme
load_theme() {
  local THEME="${1:-$LATHE_THEME}"
  local THEME_PATH="$(dirname "$0")/../config/themes/$THEME.conf"
  if [[ -f "$THEME_PATH" ]]; then
    source "$THEME_PATH"
  else
    printf "$(hex_to_ansi "#f87171")error: theme '$THEME' not found${RESET}\n"
  fi
}

# print helpers
print_accent()  { printf "$(hex_to_ansi "$COLOR_ACCENT")$1${RESET}\n";}
print_success() { printf "$(hex_to_ansi "$COLOR_SUCCESS")$1${RESET}\n";}
print_warn()    { printf "$(hex_to_ansi "$COLOR_WARN")$1${RESET}\n";}
print_error()   { printf "$(hex_to_ansi "$COLOR_ERROR")$1${RESET}\n";}
print_muted()   { printf "$(hex_to_ansi "$COLOR_MUTED")$1${RESET}\n";}
print_text()    { printf "$(hex_to_ansi "$COLOR_TEXT")$1${RESET}\n";}

# cursor control
cursor_hide() { printf "\033[?25l"; }
cursor_show() { printf "\033[?25h"; }

# region TUI functions (written by Sonnet 4.6)
# header
print_header() {
  local title="$1"
  local version="$2"
  local width=40
  local line=$(printf '─%.0s' $(seq 1 $width))
  print_accent "┌${line}┐"
  print_accent "│  $(printf "%-$((width-2))s" "$title  $version")│"
  print_accent "└${line}┘"
}

# section divider
print_section() {
  local title="$1"
  print_muted "── $title ──"
}

# free text prompt
prompt() {
  local question="$1"
  printf "$(hex_to_ansi "$COLOR_ACCENT")? $(hex_to_ansi "$COLOR_TEXT")$question${RESET} "
  read -r REPLY
  echo "$REPLY"
}

# secure prompting
prompt_secure() {
  local question="$1"
  printf "$(hex_to_ansi "$COLOR_ACCENT")? $(hex_to_ansi "$COLOR_TEXT")$question${RESET} "
  read -rs REPLY
  echo ""
  echo "$REPLY"
}

# yes/no confirm with optional default (y/n/none)
confirm() {
  local question="$1"
  local default="$2"
  local display
  if [[ "$default" == "y" ]]; then
    display="[Y/n]"
  elif [[ "$default" == "n" ]]; then
    display="[y/N]"
  else
    display="[y/n]"
  fi

  while true; do
    printf "$(hex_to_ansi "$COLOR_WARN")? $(hex_to_ansi "$COLOR_TEXT")$question ${RESET}$display "
    read -r REPLY
    [[ -z "$REPLY" ]] && REPLY="$default"
    if [[ "$REPLY" =~ ^([Yy]|[Yy][Ee][Ss]|[Yy][Ee])$ ]]; then
      return 0
    elif [[ "$REPLY" =~ ^([Nn]|[Nn][Oo])$ ]]; then
      return 1
    else
      print_error "Please enter y or n"
    fi
  done
}

# single select with arrow keys (enter to confirm)
select_option() {
  cursor_hide
  trap cursor_show EXIT
  local prompt_text="$1"
  shift
  local options=("$@")
  local selected=0
  local count=${#options[@]}
  local key

  print_text "$prompt_text"
  print_muted "↑/↓ move  enter confirm"

  _draw_select() {
    for i in "${!options[@]}"; do
      if [[ $i -eq $selected ]]; then
        printf "$(hex_to_ansi "$COLOR_ACCENT")  > ${options[$i]}${RESET}\n"
      else
        printf "$(hex_to_ansi "$COLOR_MUTED")    ${options[$i]}${RESET}\n"
      fi
    done
  }

  _clear_select() {
    for i in "${!options[@]}"; do
      printf "\033[A"
    done
    printf "\033[0G"
  }

  _draw_select
  while true; do
    IFS= read -rsn1 key
    if [[ "$key" == $'\x1b' ]]; then
      read -rsn2 key
      case "$key" in
        '[A') selected=$(( (selected - 1 + count) % count )) ;;
        '[B') selected=$(( (selected + 1) % count )) ;;
      esac
    elif [[ "$key" == "" ]]; then
      break
    fi
    _clear_select
    _draw_select
  done
  printf "\033[K"
  cursor_show
  echo "${options[$selected]}"
}

# multiselect with arrow keys, space to toggle, enter to confirm
multiselect() {
  local prompt_text="$1"
  shift
  local options=("$@")
  local cursor=0
  local count=${#options[@]}
  local key
  local checked=()
  for i in "${!options[@]}"; do
    checked[$i]=0
  done

  print_text "$prompt_text"
  print_muted "↑/↓ move  space select  enter confirm"
  printf "\n"
  cursor_hide
  trap cursor_show EXIT

  _draw_multi() {
      for i in "${!options[@]}"; do
        local box
        if [[ $i -eq $cursor ]]; then
          [[ ${checked[$i]} -eq 1 ]] && box="$(hex_to_ansi "$COLOR_ACCENT")($(hex_to_ansi "$COLOR_SUCCESS")x$(hex_to_ansi "$COLOR_ACCENT"))${RESET}" || box="$(hex_to_ansi "$COLOR_ACCENT")( )${RESET}"
        else
          [[ ${checked[$i]} -eq 1 ]] && box="$(hex_to_ansi "$COLOR_SUCCESS")(x)${RESET}" || box="$(hex_to_ansi "$COLOR_MUTED")( )${RESET}"
        fi
        if [[ $i -eq $cursor ]]; then
          printf "  $box $(hex_to_ansi "$COLOR_ACCENT")${options[$i]}${RESET}\n"
        else
          printf "  $box $(hex_to_ansi "$COLOR_TEXT")${options[$i]}${RESET}\n"
        fi
      done
    }

  _clear_multi() {
    for i in "${!options[@]}"; do
      printf "\033[A"
    done
    printf "\033[0G"
  }

  _draw_multi
  while true; do
    IFS= read -rsn1 key
    if [[ "$key" == $'\x1b' ]]; then
      read -rsn2 key
      case "$key" in
        '[A') cursor=$(( (cursor - 1 + count) % count )) ;;
        '[B') cursor=$(( (cursor + 1) % count )) ;;
      esac
    elif [[ "$key" == " " ]]; then
      [[ ${checked[$cursor]} -eq 0 ]] && checked[$cursor]=1 || checked[$cursor]=0
    elif [[ "$key" == "" ]]; then
      break
    fi
    _clear_multi
    _draw_multi
  done

  local result=()
  for i in "${!options[@]}"; do
    [[ ${checked[$i]} -eq 1 ]] && result+=("${options[$i]}")
  done
  echo "${result[@]}"
  cursor_show
}

# spinner (pass background process PID)
spinner() {
  local pid="$1"
  local message="$2"
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  while kill -0 "$pid" 2>/dev/null; do
    for frame in "${frames[@]}"; do
      printf "\r$(hex_to_ansi "$COLOR_ACCENT")$frame${RESET} $message"
      sleep 0.08
    done
  done
  printf "\r\033[K"
}

# progress bar
progress_bar() {
  local current="$1"
  local total="$2"
  local label="$3"
  local width=30
  local filled=$(( (current * width) / total ))
  local empty=$(( width - filled ))
  local bar="$(printf '█%.0s' $(seq 1 $filled))$(printf '░%.0s' $(seq 1 $empty))"
  printf "\r$(hex_to_ansi "$COLOR_ACCENT")$bar${RESET} $current/$total $label\n"
}

# status line
status_line() {
  local status="$1"
  local message="$2"
  case "$status" in
    ok)      printf "$(hex_to_ansi "$COLOR_SUCCESS")✓${RESET} $message\n" ;;
    fail)    printf "$(hex_to_ansi "$COLOR_ERROR")✗${RESET} $message\n" ;;
    pending) printf "$(hex_to_ansi "$COLOR_MUTED")·${RESET} $message\n" ;;
  esac
}
# endregion

# testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # test 1: hex_to_ansi function
  printf "$(hex_to_ansi "#7dd3fc")hello${RESET} world\n" 

  # test 2: load_theme function
  load_theme amber
  printf "$(hex_to_ansi "$COLOR_ACCENT")accent color loaded\n${RESET}"
  load_theme
  printf "$(hex_to_ansi "$COLOR_ACCENT")accent color loaded\n${RESET}"

  # test 3: print helpers
  print_accent "accent test"
  print_error "err test"
  print_muted "muted test"
  print_success "success test"
  print_text "text test"
  print_warn "warn test"

  # test 4: TUI functions
  print_header "lathe" "v0.1.0"
  print_section "test section"
  status_line ok "CT created"
  status_line fail "something broke"
  status_line pending "waiting"
  select_option "Pick one" "option a" "option b" "option c"
  confirm "Continue?"
  select_option "Pick a theme" "mono" "amber" "teal"
  multiselect "Pick features" "Tailscale" "SSH keys" "DNS" "Users"
  confirm "Continue?" y

fi

# TODO: sticky progress bar (terminal cursor manipulation or smth ???)