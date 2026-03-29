# Bash completion for code-remote
# shellcheck shell=bash

_code_remote_hosts() {
  local hosts=""

  if [[ -r "$HOME/.ssh/config" ]]; then
    hosts+=" $(awk '
      tolower($1)=="host" {
        for (i=2; i<=NF; i++) {
          if ($i !~ /[*?]/) print $i
        }
      }
    ' "$HOME/.ssh/config" 2>/dev/null)"
  fi

  if [[ -r "$HOME/.ssh/known_hosts" ]]; then
    hosts+=" $(awk -F'[ ,]' '
      /^[|@]/ { next }
      {
        split($1, a, ",")
        for (i in a) {
          if (a[i] !~ /^[0-9.]+$/ && a[i] !~ /^\[/) print a[i]
        }
      }
    ' "$HOME/.ssh/known_hosts" 2>/dev/null)"
  fi

  printf "%s\n" "$hosts" | tr ' ' '\n' | sed '/^$/d' | sort -u
}

_code_remote_remote_paths() {
  local host="$1"
  local cur="$2"

  ssh -o BatchMode=yes -o ConnectTimeout=2 "$host" 'bash -s --' "$cur" <<'EOF' 2>/dev/null
set -euo pipefail

input="${1:-}"

case "$input" in
  "")
    base="$HOME"
    prefix=""
    ;;
  ~)
    base="$HOME"
    prefix="~"
    ;;
  ~/*)
    p="${input#~/}"
    ;;
  /*)
    p="${input#/}"
    ;;
  *)
    p="$input"
    ;;
esac

if [[ -n "${p:-}" ]]; then
  dir="${p%/*}"
  leaf="${p##*/}"
  if [[ "$dir" == "$p" ]]; then
    dir=""
  fi

  if [[ "$input" == /* ]]; then
    base="/${dir}"
    prefix="/${dir}"
  else
    base="$HOME/${dir}"
    if [[ "$input" == ~/* ]]; then
      prefix="~/${dir}"
    else
      prefix="${dir}"
    fi
  fi
else
  leaf=""
fi

base="${base%/}"
[[ -z "$base" ]] && base="/"

shopt -s nullglob dotglob
for entry in "$base"/*; do
  name="${entry##*/}"
  [[ -n "${leaf:-}" && "$name" != "$leaf"* ]] && continue

  out="$name"
  if [[ -n "${prefix:-}" ]]; then
    out="${prefix%/}/$name"
  fi

  [[ -d "$entry" ]] && out="$out/"
  printf "%s\n" "$out"
done
EOF
}

_code_remote_complete() {
  local cur prev
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]:-}"

  if [[ $COMP_CWORD -eq 1 ]]; then
    COMPREPLY=( $(compgen -W "$(_code_remote_hosts)" -- "$cur") )
    return 0
  fi

  if [[ $COMP_CWORD -eq 2 ]]; then
    local host="${COMP_WORDS[1]}"
    if [[ -n "$host" ]]; then
      local suggestions
      suggestions="$(_code_remote_remote_paths "$host" "$cur")"
      COMPREPLY=( $(compgen -W "$suggestions" -- "$cur") )
    fi
    return 0
  fi

  return 0
}

complete -o nospace -F _code_remote_complete code-remote
