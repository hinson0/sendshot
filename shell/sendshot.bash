# sendshot Ctrl+G integration for bash.
if [[ $- == *i* ]] && command -v sendshot >/dev/null 2>&1; then
  sendshot_readline_widget() {
    local output status

    output="$(command sendshot 2>&1)"
    status=$?

    printf '\n%s\n' "$output"
    READLINE_LINE=""
    READLINE_POINT=0

    return "$status"
  }

  bind -x '"\C-g":sendshot_readline_widget'
fi
