# Bash completion for code-remote
# shellcheck shell=bash

_code_remote_hosts() {
  local hosts=""

  # Collect SSH config files, honoring Include directives (recursive, cycle-safe).
  # Supports: multiple paths per line, tilde expansion, relative paths (~/.ssh/),
  # globs, and nested includes — matching OpenSSH's own Include semantics.
  local -a ssh_configs=()
  local -a pending=()
  local -A visited=()
  [[ -r "$HOME/.ssh/config" ]] && pending+=("$HOME/.ssh/config")
  while [[ ${#pending[@]} -gt 0 ]]; do
    local cfg="${pending[0]}"
    pending=("${pending[@]:1}")
    [[ -n "${visited[$cfg]+set}" ]] && continue
    visited[$cfg]=1
    ssh_configs+=("$cfg")
    while IFS= read -r line; do
      # Strip leading whitespace then check for Include (case-insensitive)
      local stripped="${line#"${line%%[![:space:]]*}"}"
      [[ "${stripped,,}" =~ ^include[[:space:]]+(.+)$ ]] || continue
      local include_val="${BASH_REMATCH[1]}"
      # Strip trailing whitespace
      include_val="${include_val%"${include_val##*[![:space:]]}"}"
      # Split on whitespace — SSH allows multiple paths on one Include line
      local -a include_paths
      read -ra include_paths <<< "$include_val"
      for pattern in "${include_paths[@]}"; do
        pattern="${pattern/#\~/$HOME}"
        [[ "$pattern" != /* ]] && pattern="$HOME/.ssh/$pattern"
        for f in $pattern; do
          [[ -r "$f" ]] && [[ -z "${visited[$f]+set}" ]] && pending+=("$f")
        done
      done
    done < "$cfg"
  done

  for cfg in "${ssh_configs[@]}"; do
    hosts+=" $(awk '
      tolower($1)=="host" {
        for (i=2; i<=NF; i++) {
          if ($i !~ /[*?]/) print $i
        }
      }
    ' "$cfg" 2>/dev/null)"
  done

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

  if [[ $COMP_CWORD -ge 2 ]]; then
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
