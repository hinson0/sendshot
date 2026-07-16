# sendshot Ctrl+G integration for zsh.
if [[ -o interactive ]] && command -v sendshot >/dev/null 2>&1; then
  sendshot_zle_widget() {
    zle -M "sendshot: uploading clipboard image..."
    zle -R

    local output
    if output="$(command sendshot 2>&1)"; then
      zle -M "sendshot: uploaded and copied
${output##*$'\n'}"
    else
      zle -M "sendshot: failed
${output##*$'\n'}"
      return 1
    fi
  }

  zle -N sendshot_zle_widget
  bindkey '^G' sendshot_zle_widget
fi
