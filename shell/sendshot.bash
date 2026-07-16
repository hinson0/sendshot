# sendshot Ctrl+G integration for bash.
if [[ $- == *i* ]] && command -v sendshot >/dev/null 2>&1; then
  sendshot_readline_widget() {
    local output_file status

    output_file="$(mktemp "${TMPDIR:-/tmp}/sendshot-readline.XXXXXX")" || {
      printf '\nsendshot: failed to create temporary output file\n'
      return 1
    }

    # Avoid command substitution for the same reason as the zsh integration:
    # X11 clipboard owners such as xclip may keep inherited pipes open.
    SENDSHOT_NO_UPDATE_CHECK=1 command sendshot >"$output_file" 2>&1
    status=$?

    printf '\n'
    cat -- "$output_file"

    if ((status == 0)); then
      printf '%s\n' "sendshot: uploaded and copied"
    else
      printf '%s\n' "sendshot: upload failed"
    fi

    rm -f -- "$output_file"

    READLINE_LINE=""
    READLINE_POINT=0

    return "$status"
  }

  bind -x '"\C-g":sendshot_readline_widget'
fi
