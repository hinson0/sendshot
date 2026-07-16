# sendshot Ctrl+G integration for zsh.
if [[ -o interactive ]] && command -v sendshot >/dev/null 2>&1; then
  sendshot_zle_widget() {
    local output_file status

    output_file="$(mktemp "${TMPDIR:-/tmp}/sendshot-zle.XXXXXX")" || {
      zle -M "sendshot: failed to create temporary output file"
      return 1
    }

    zle -M "sendshot: uploading clipboard image..."
    zle -R

    # Do not use command substitution here. On X11, xclip keeps a background
    # selection process alive, which can leave a command-substitution pipe open
    # and make the ZLE widget appear to hang.
    #
    # Update prompts are disabled inside ZLE because interactive `read` prompts
    # are not reliable while the line editor owns the terminal.
    SENDSHOT_NO_UPDATE_CHECK=1 command sendshot >"$output_file" 2>&1
    status=$?

    # Invalidate the current ZLE display, print the real command output to the
    # terminal, then redraw a clean prompt.
    zle -I
    printf '\n'
    cat -- "$output_file"

    if ((status == 0)); then
      printf '%s\n' "sendshot: uploaded and copied"
    else
      printf '%s\n' "sendshot: upload failed"
    fi

    rm -f -- "$output_file"
    zle reset-prompt

    return "$status"
  }

  zle -N sendshot_zle_widget
  bindkey '^G' sendshot_zle_widget
fi
