tv() {
  if (( $# == 0 )) && [[ -t 0 ]]; then
    "$HOME/.config/television/browse.py" "$PWD"
  else
    command tv "$@"
  fi
}
