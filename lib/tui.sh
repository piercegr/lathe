# globals
RESET="\033[0m" 

# sets the input hex into making the outputs that color
function hex_to_ansi() {
  HEX=${1#'#'}
  R_HEX=${HEX:0:2}
  G_HEX=${HEX:2:2}
  B_HEX=${HEX:4:2}
  R_DEC=$((16#$R_HEX))
  G_DEC=$((16#$G_HEX))
  B_DEC=$((16#$B_HEX))
  printf "\033[38;2;${R_DEC};${G_DEC};${B_DEC}m"
}

# sourcing / loading theme
load_theme() {
  if [[ -f "$1" ]]; then
    source "$1"
  else
    printf "$(hex_to_ansi "#f87171")Error: theme file not found: $1${RESET}\n" # hard coded color bc the err color won't be loaded when it errs
  fi
}

# print helpers
print_accent()  { printf "$(hex_to_ansi "$COLOR_ACCENT")$1${RESET}\n";}
print_success() { printf "$(hex_to_ansi "$COLOR_SUCCESS")$1${RESET}\n";}
print_warn()    { printf "$(hex_to_ansi "$COLOR_WARN")$1${RESET}\n";}
print_error()   { printf "$(hex_to_ansi "$COLOR_ERROR")$1${RESET}\n";}
print_muted()   { printf "$(hex_to_ansi "$COLOR_MUTED")$1${RESET}\n";}
print_text()    { printf "$(hex_to_ansi "$COLOR_TEXT")$1${RESET}\n";}

# testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # test 1: hex_to_ansi function
  printf "$(hex_to_ansi "#7dd3fc")hello${RESET} world\n" 

  # test 2: load_theme function
  load_theme "config/themes/mono.conf"
  printf "$(hex_to_ansi "$COLOR_ACCENT")accent color loaded\n${RESET}"

  # test 3: print helpers
  print_accent "accent test"
  print_error "err test"
  print_muted "muted test"
  print_success "success test"
  print_text "text test"
  print_warn "warn test"
fi