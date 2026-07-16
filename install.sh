#!/usr/bin/env bash
set -Eeuo pipefail

REPOSITORY="${SENDSHOT_REPOSITORY:-hinson0/sendshot}"
BRANCH="${SENDSHOT_BRANCH:-main}"
RAW_BASE="${SENDSHOT_RAW_BASE:-https://raw.githubusercontent.com/$REPOSITORY/$BRANCH}"

INSTALL_DIR="${SENDSHOT_INSTALL_DIR:-$HOME/.local/bin}"
INSTALL_PATH="$INSTALL_DIR/sendshot"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/sendshot"

PATH_BEGIN='# >>> sendshot path >>>'
PATH_END='# <<< sendshot path <<<'
INTEGRATION_BEGIN='# >>> sendshot integration >>>'
INTEGRATION_END='# <<< sendshot integration <<<'

log() {
  printf 'sendshot installer: %s\n' "$*"
}

die() {
  printf 'sendshot installer: %s\n' "$*" >&2
  exit 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

ask_yes_no() {
  local prompt="$1"
  local default="${2:-yes}"
  local answer=""

  if [[ "${SENDSHOT_NON_INTERACTIVE:-0}" == "1" || ! -r /dev/tty ]]; then
    [[ "$default" == "yes" ]]
    return
  fi

  if [[ "$default" == "yes" ]]; then
    read -r -p "$prompt [Y/n]: " answer </dev/tty || true
    answer="${answer:-y}"
  else
    read -r -p "$prompt [y/N]: " answer </dev/tty || true
    answer="${answer:-n}"
  fi

  [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]
}

detect_rc_file() {
  case "${SHELL:-}" in
    */zsh)
      printf '%s\n' "$HOME/.zshrc"
      ;;
    */bash)
      printf '%s\n' "$HOME/.bashrc"
      ;;
    *)
      if [[ -f "$HOME/.zshrc" ]]; then
        printf '%s\n' "$HOME/.zshrc"
      else
        printf '%s\n' "$HOME/.bashrc"
      fi
      ;;
  esac
}

download_to() {
  local source_path="$1"
  local destination="$2"
  local installer_source="${BASH_SOURCE[0]:-}"
  local installer_dir=""

  if [[ -n "$installer_source" && -f "$installer_source" ]]; then
    installer_dir="$(cd "$(dirname "$installer_source")" && pwd)"
    if [[ -f "$installer_dir/$source_path" ]]; then
      cp "$installer_dir/$source_path" "$destination"
      return
    fi
  fi

  if command_exists curl; then
    curl -fsSL "$RAW_BASE/$source_path" -o "$destination"
  elif command_exists wget; then
    wget -qO "$destination" "$RAW_BASE/$source_path"
  else
    die "curl or wget is required"
  fi
}

replace_marker_block() {
  local file="$1"
  local begin="$2"
  local end="$3"
  local content="$4"
  local tmp

  touch "$file"
  tmp="$(mktemp)"

  awk -v begin="$begin" -v end="$end" '
    $0 == begin { skipping = 1; next }
    $0 == end   { skipping = 0; next }
    !skipping   { print }
  ' "$file" >"$tmp"

  {
    cat "$tmp"
    printf '\n%s\n' "$begin"
    printf '%s\n' "$content"
    printf '%s\n' "$end"
  } >"$file"

  rm -f "$tmp"
}

remove_marker_block() {
  local file="$1"
  local begin="$2"
  local end="$3"
  local tmp

  [[ -f "$file" ]] || return 0
  tmp="$(mktemp)"

  awk -v begin="$begin" -v end="$end" '
    $0 == begin { skipping = 1; next }
    $0 == end   { skipping = 0; next }
    !skipping   { print }
  ' "$file" >"$tmp"

  mv "$tmp" "$file"
}

install_ubuntu_dependencies() {
  [[ "$(uname -s)" == "Linux" ]] || return 0
  command_exists apt-get || return 0

  local packages=()

  command_exists ssh || packages+=(openssh-client)
  command_exists scp || packages+=(openssh-client)

  if [[ "${XDG_SESSION_TYPE:-}" == "wayland" || -n "${WAYLAND_DISPLAY:-}" ]]; then
    command_exists wl-paste || packages+=(wl-clipboard)
    command_exists wl-copy || packages+=(wl-clipboard)
  elif [[ "${XDG_SESSION_TYPE:-}" == "x11" || -n "${DISPLAY:-}" ]]; then
    command_exists xclip || packages+=(xclip)
  else
    command_exists wl-paste || packages+=(wl-clipboard)
    command_exists xclip || packages+=(xclip)
  fi

  if ((${#packages[@]} == 0)); then
    return 0
  fi

  # Remove duplicate package names.
  mapfile -t packages < <(printf '%s\n' "${packages[@]}" | awk '!seen[$0]++')

  log "missing Ubuntu packages: ${packages[*]}"

  if ask_yes_no "Install missing packages with apt?" yes; then
    sudo apt-get update
    sudo apt-get install -y "${packages[@]}"
  else
    log "skipped dependency installation"
  fi
}

install_binary() {
  mkdir -p "$INSTALL_DIR"

  local tmp
  tmp="$(mktemp)"
  download_to "bin/sendshot" "$tmp"

  bash -n "$tmp"
  install -m 0755 "$tmp" "$INSTALL_PATH"
  rm -f "$tmp"

  log "installed executable: $INSTALL_PATH"
}

install_path() {
  local rc_file
  rc_file="$(detect_rc_file)"

  if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
    log "$INSTALL_DIR is already in PATH"
    return
  fi

  replace_marker_block \
    "$rc_file" \
    "$PATH_BEGIN" \
    "$PATH_END" \
    'export PATH="$HOME/.local/bin:$PATH"'

  export PATH="$INSTALL_DIR:$PATH"
  log "added $INSTALL_DIR to PATH in $rc_file"
}

install_hotkey() {
  local shell_name
  shell_name="$(basename "${SHELL:-bash}")"

  if ! ask_yes_no "Bind Ctrl+G to upload the clipboard image?" yes; then
    return
  fi

  mkdir -p "$CONFIG_DIR"

  local integration_source=""
  case "$shell_name" in
    zsh)
      integration_source="shell/sendshot.zsh"
      ;;
    bash)
      integration_source="shell/sendshot.bash"
      ;;
    *)
      log "Ctrl+G integration supports bash and zsh only"
      return
      ;;
  esac

  local integration_path="$CONFIG_DIR/${integration_source##*/}"
  download_to "$integration_source" "$integration_path"

  local rc_file
  rc_file="$(detect_rc_file)"

  replace_marker_block \
    "$rc_file" \
    "$INTEGRATION_BEGIN" \
    "$INTEGRATION_END" \
    "source \"$integration_path\""

  log "installed Ctrl+G integration in $rc_file"
}

run_configuration() {
  if [[ "${SENDSHOT_SKIP_CONFIG:-0}" == "1" ]]; then
    return
  fi

  if ask_yes_no "Configure the EC2 destination now?" yes; then
    "$INSTALL_PATH" config
  else
    log "configure later with: sendshot config"
  fi
}

uninstall_sendshot() {
  local rc_file
  rc_file="$(detect_rc_file)"

  rm -f "$INSTALL_PATH"
  rm -f "$CONFIG_DIR/sendshot.zsh" "$CONFIG_DIR/sendshot.bash"

  remove_marker_block "$rc_file" "$PATH_BEGIN" "$PATH_END"
  remove_marker_block "$rc_file" "$INTEGRATION_BEGIN" "$INTEGRATION_END"

  log "removed sendshot executable and shell integration"
  log "configuration retained at $CONFIG_DIR/config"

  if ask_yes_no "Remove the saved EC2 configuration too?" no; then
    rm -f "$CONFIG_DIR/config"
    rmdir "$CONFIG_DIR" 2>/dev/null || true
    log "removed configuration"
  fi
}

main() {
  case "${1:-install}" in
    install)
      install_ubuntu_dependencies
      install_binary
      install_path
      install_hotkey
      run_configuration

      log "installation complete"
      log "open a new terminal or run: source $(detect_rc_file)"
      log "usage: sendshot"
      ;;
    uninstall)
      uninstall_sendshot
      ;;
    *)
      die "usage: install.sh [install|uninstall]"
      ;;
  esac
}

main "$@"
