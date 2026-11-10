# This is a zsh file; shellcheck only understands bash and reports false positives.
# shellcheck disable=all

# Requires:
#   - macOS `open`
#   - Claude desktop app (registers the claude:// URL scheme)
# Config: none

# Open a new Claude Code (desktop app) session in a directory.
#   cc                    -> current directory
#   cc path/to/dir        -> that directory
#   cc . "fix the tests"  -> with an initial prompt pre-filled
cc() {
  emulate -L zsh
  local dir="${1:-.}" prompt="$2" url
  dir="${dir:A}"                      # absolute, symlinks resolved
  [[ -d "$dir" ]] || { print -u2 "cc: not a directory: $dir"; return 1 }
  url="claude://code/new?folder=$(_cc_urlencode "$dir")"
  [[ -n "$prompt" ]] && url+="&q=$(_cc_urlencode "$prompt")"
  open "$url"
}

# Percent-encode like encodeURIComponent (byte-wise, UTF-8 safe).
_cc_urlencode() {
  emulate -L zsh
  local LC_ALL=C s="$1" out="" c i
  for (( i = 1; i <= ${#s}; i++ )); do
    c="${s[i]}"
    case "$c" in
      [A-Za-z0-9._~-]) out+="$c" ;;
      *) out+=$(printf '%%%02X' "'$c") ;;
    esac
  done
  print -rn -- "$out"
}
