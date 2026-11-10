# macOS port inspection for Zsh.
# Usage:   portinfo 3000 [--verbose|-v] [--files]
# Requires: macOS ps, lsof, sudo; fzf for --files.

# One-line, terminal-width-limited presentation. Full values appear in -v mode.
_portinfo_clip() {
  emulate -L zsh
  local value="$1" limit="${2:-80}"
  value="${value//$'\n'/ }"
  value="${value//$'\r'/ }"
  (( limit < 12 )) && limit=12
  if (( ${#value} <= limit )); then
    print -r -- "$value"
  else
    print -r -- "${value[1,$((limit - 1))]}…"
  fi
}

_portinfo_home() {
  emulate -L zsh
  local path="$1"
  if [[ "$path" == "$HOME" ]]; then
    print -r -- '~'
  elif [[ "$path" == "$HOME/"* ]]; then
    print -r -- "~/${path#"$HOME"/}"
  else
    print -r -- "$path"
  fi
}

# Inspect with the authenticated sudo credential. No repeated prompts in fzf.
_portinfo_ps() {
  sudo -n /bin/ps -ww -p "$1" -o "$2=" 2>/dev/null
}

_portinfo_lsof_path() {
  sudo -n lsof -nP -w -a -p "$1" -d "$2" -Fn 2>/dev/null |
    awk '/^n/ { print substr($0, 2); exit }'
}

portinfo() {
  emulate -L zsh
  setopt local_options no_sh_word_split

  local port='' arg verbose=0 files_mode=0
  local listeners line pid current parent label detail addresses cwd cwd_full cmd name age user cpu
  local width summary metrics started binary mapped fd_list selected raw entries
  local chain_text prefix i j show_count parent_cmd
  local -a pids chain fields
  local -A unique_pids visited

  for arg in "$@"; do
    case "$arg" in
      -v|--verbose) verbose=1 ;;
      --files) files_mode=1 ;;
      -h|--help)
        print 'Usage: portinfo PORT [-v|--verbose] [--files]'
        print '  PORT              TCP port (1-65535)'
        print '  -v, --verbose     Detailed process and complete ancestor information'
        print '  --files           Browse open descriptors in fzf (can combine with -v)'
        return 0
        ;;
      *)
        if [[ "$arg" == <-> && -z "$port" ]]; then
          port="$arg"
        else
          print -u2 'Usage: portinfo PORT [-v|--verbose] [--files]'
          return 2
        fi
        ;;
    esac
  done

  if [[ -z "$port" || "$port" != <-> ]] || (( port < 1 || port > 65535 )); then
    print -u2 'Usage: portinfo PORT [-v|--verbose] [--files]'
    return 2
  fi
  if (( files_mode )) && ! command -v fzf >/dev/null 2>&1; then
    print -u2 'portinfo: --files requires fzf (brew install fzf)'
    return 127
  fi
  for arg in sudo lsof awk; do
    if ! command -v "$arg" >/dev/null 2>&1; then
      print -u2 "portinfo: missing required command: $arg"
      return 127
    fi
  done

  # This deliberately requests sudo: lsof may omit other users' processes.
  sudo -v || return 1
  listeners=$(sudo -n lsof -nP -w +c 0 -iTCP:"$port" -sTCP:LISTEN -Fpfn 2>/dev/null)
  if [[ -z "$listeners" ]]; then
    print -r -- "No visible TCP listener on port $port."
    return 1
  fi

  # lsof's machine-readable process records are more stable than table columns.
  while IFS= read -r line; do
    if [[ "$line" == p<-> ]]; then
      pid="${line#p}"
      if [[ -z "${unique_pids[$pid]-}" ]]; then
        pids+=("$pid")
        unique_pids[$pid]=1
      fi
    fi
  done <<< "$listeners"
  if (( ${#pids} == 0 )); then
    print -r -- "No visible TCP listener on port $port."
    return 1
  fi

  if (( files_mode )); then
    # Separate mode: inspect all descriptors of the actual listener(s), not
    # every open file of their parents. No password prompts inside fzf.
    raw=$(sudo -n lsof -nP -w +c 0 -p "${(j:,:)pids}" -Fpcftn 2>/dev/null)
    if [[ -z "$raw" ]]; then
      print -u2 'portinfo: open-file inspection failed (process may have exited).'
      return 1
    fi
    entries=$(print -r -- "$raw" | awk '
      function emit() {
        if (pid != "" && fd != "") {
          gsub(/\t/, " ", name)
          gsub(/\r/, " ", name)
          printf "%s\t%s\t%s\t%s\n", pid, fd, typ, name
        }
      }
      /^p[0-9]+$/ { emit(); pid=substr($0,2); fd=""; next }
      /^f/ { emit(); fd=substr($0,2); typ=""; name=""; next }
      /^t/ { typ=substr($0,2); next }
      /^n/ { name=substr($0,2); next }
      END { emit() }
    ')
    if [[ -z "$entries" ]]; then
      print -u2 'portinfo: no open-file entries found (process may have exited).'
      return 1
    fi

    local preview_cmd='
      pid={1}; fd={2}; typ={3}; target={4}
      printf "PID: %s    FD: %s    Type: %s\nName: %s\n" "$pid" "$fd" "$typ" "$target"
      printf "\nPROCESS\n"
      /usr/bin/sudo -n /bin/ps -ww -p "$pid" -o command= 2>/dev/null || true
      if [ "${target#/}" != "$target" ]; then
        printf "\nFILESYSTEM METADATA (path as it exists now)\n"
        /usr/bin/sudo -n /usr/bin/stat -f \
          "Owner: %Su:%Sg | Mode: %Sp | Size: %z bytes | Inode: %i | Modified: %Sm" \
          -t "%Y-%m-%d %H:%M:%S" "$target" 2>/dev/null ||
          printf "Path unavailable (deleted, replaced, or restricted).\n"
        /usr/bin/sudo -n /usr/bin/file -b "$target" 2>/dev/null || true
      else
        printf "\nSocket, pipe, anonymous descriptor, or non-path entry.\n"
      fi
    '
    if (( verbose )); then
      preview_cmd+='
        printf "\nPROCESS DETAILS\n"
        /usr/bin/sudo -n /bin/ps -ww -p "$pid" \
          -o pid,ppid,user,stat,etime,%cpu,%mem,rss,command 2>/dev/null || true
        printf "\nFULL lsof ROW(S) FOR FD\n"
        case "$fd" in
          [0-9]*) descriptor=${fd%%[^0-9]*} ;;
          *) descriptor=$fd ;;
        esac
        /usr/bin/sudo -n lsof -nP -w -a -p "$pid" -d "$descriptor" 2>/dev/null |
          /usr/bin/head -n 18
      '
    fi

    if (( verbose )); then
      selected=$(print -r -- "$entries" | fzf \
        --delimiter=$'\t' --with-nth=1,2,3,4 \
        --layout=reverse --height=100% --border \
        --header="Port $port | PID / FD / TYPE / NAME | Ctrl-Y: copy name | Ctrl-/: preview layout | Enter: select" \
        --preview-window='right,60%,wrap' \
        --preview="$preview_cmd" \
        --bind='ctrl-y:execute-silent(printf %s {4} | pbcopy)' \
        --bind='ctrl-/:change-preview-window(down,45%,wrap|hidden|right,60%,wrap)') || return 0
    else
      selected=$(print -r -- "$entries" | fzf \
        --delimiter=$'\t' --with-nth=1,2,3,4 \
        --layout=reverse --height=100% --border \
        --header="Port $port | PID / FD / TYPE / NAME | Ctrl-Y: copy name | Ctrl-/: preview layout | Enter: select" \
        --preview-window='down,45%,wrap' \
        --preview="$preview_cmd" \
        --bind='ctrl-y:execute-silent(printf %s {4} | pbcopy)' \
        --bind='ctrl-/:change-preview-window(right,60%,wrap|hidden|down,45%,wrap)') || return 0
    fi
    print 'Selected descriptor (PID / FD / TYPE / NAME):'
    print -r -- "$selected"
    return 0
  fi

  # Limited dimensions for dropdown/Quake-style terminals; -v never truncates.
  width=${COLUMNS:-80}
  (( width > 12 )) || width=80
  (( width > 120 )) && width=120

  if (( verbose )); then
    print -r -- "PORT $port — TCP LISTEN — ${#pids} process(es)"
    print
    print 'LISTENING SOCKETS'
    sudo -n lsof -nP -w +c 0 -iTCP:"$port" -sTCP:LISTEN 2>/dev/null
  else
    print -r -- "TCP :$port — ${#pids} listener(s)"
  fi

  for pid in "${pids[@]}"; do
    # Build the whole current parent chain, even when compact mode shows only
    # a short breadcrumb. Stop at PID 1, a missing parent, or a PID loop.
    chain=()
    visited=()
    current="$pid"
    while [[ "$current" == <-> ]] && (( current > 0 )) &&
          [[ -z "${visited[$current]-}" ]] && (( ${#chain} < 64 )); do
      parent=$(_portinfo_ps "$current" ppid)
      [[ -n "$parent" ]] || break
      chain+=("$current")
      visited[$current]=1
      parent="${parent//[[:space:]]/}"
      current="$parent"
    done

    # Even if ancestor discovery fails, show the initial listening PID.
    (( ${#chain} )) || chain=("$pid")

    cmd=$(_portinfo_ps "$pid" command)
    name=$(_portinfo_ps "$pid" ucomm)
    cwd_full=$(_portinfo_lsof_path "$pid" cwd)
    cwd=$cwd_full
    user=$(_portinfo_ps "$pid" user)
    age=$(_portinfo_ps "$pid" etime)
    cpu=$(_portinfo_ps "$pid" %cpu)
    [[ -n "$cwd" ]] && cwd=$(_portinfo_home "$cwd")

    addresses=$(print -r -- "$listeners" | awk -v wanted="$pid" '
      /^p[0-9]+$/ { current=substr($0,2); next }
      /^n/ && current==wanted {
        if (length(result)) result=result ", "
        result=result substr($0,2)
      }
      END { print result }
    ')

    if (( ! verbose )); then
      print
      _portinfo_clip "PID $pid · ${name:-unknown} · ${user:-?} · ${age:-?} · CPU ${cpu:-?}%" "$width"
      _portinfo_clip "  Bind  ${addresses:-unknown}" "$width"
      _portinfo_clip "  Dir   ${cwd:-unavailable}" "$width"
      _portinfo_clip "  Args  ${cmd:-unavailable}" "$width"
      if (( ${#chain} > 1 )); then
        parent_cmd=$(_portinfo_ps "${chain[2]}" command)
        _portinfo_clip "  PPID  ${chain[2]} · ${parent_cmd:-unavailable}" "$width"
      fi

      # Only the nearest three parents are shown in compact mode.
      chain_text=''
      show_count=$(( ${#chain} - 1 ))
      (( show_count > 3 )) && show_count=3
      for (( j=show_count+1; j>=2; --j )); do
        current="${chain[j]}"
        label=$(_portinfo_ps "$current" ucomm)
        [[ -n "$chain_text" ]] && chain_text+=' > '
        chain_text+="${label:-?}($current)"
      done
      if (( ${#chain} > show_count + 1 )); then
        chain_text="… > $chain_text"
      fi
      _portinfo_clip "  From  ${chain_text:-no reachable parent}" "$width"
      continue
    fi

    print
    print -r -- "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print -r -- "LISTENER  PID $pid — ${name:-unknown}"
    print -r -- "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print -r -- "Listening: ${addresses:-unavailable}"
    print -r -- "User:      ${user:-unavailable}"
    print -r -- "State:     $(_portinfo_ps "$pid" stat)"
    print -r -- "Runtime:   ${age:-unavailable}"
    print -r -- "Started:   $(_portinfo_ps "$pid" lstart)"
    print -r -- "CPU:       ${cpu:-?}%"
    print -r -- "Memory:    $(_portinfo_ps "$pid" %mem)% (RSS: $(_portinfo_ps "$pid" rss) KiB)"
    print -r -- "Terminal:  $(_portinfo_ps "$pid" tty)"
    print -r -- "PPID / PGID / session: $(_portinfo_ps "$pid" ppid) / $(_portinfo_ps "$pid" pgid) / $(_portinfo_ps "$pid" sess)"
    print -r -- "Directory: ${cwd_full:-unavailable}"
    print -r -- "Command:   ${cmd:-unavailable}"
    print -r -- "Executable (ps comm): $(_portinfo_ps "$pid" comm)"
    mapped=$(_portinfo_lsof_path "$pid" txt)
    print -r -- "First text mapping (not always executable): ${mapped:-unavailable}"

    print
    print 'PROCESS ANCESTRY (oldest reachable → listener)'
    for (( i=${#chain}; i>=1; --i )); do
      current="${chain[i]}"
      label=$(_portinfo_ps "$current" ucomm)
      if [[ "$current" == "$pid" ]]; then
        print -r -- "  • PID $current — ${label:-unknown} [LISTENER]"
      else
        print -r -- "  • PID $current — ${label:-unknown}"
      fi
      print -r -- "    Owner / state / age: $(_portinfo_ps "$current" user) / $(_portinfo_ps "$current" stat) / $(_portinfo_ps "$current" etime)"
      print -r -- "    Command: $(_portinfo_ps "$current" command)"
      detail=$(_portinfo_lsof_path "$current" cwd)
      print -r -- "    CWD: ${detail:-unavailable}"
      if (( i > 1 )); then
        print '    │'
      fi
    done

    print
    print 'STANDARD STREAMS (listener FD 0 / 1 / 2)'
    sudo -n lsof -nP -w +c 0 -a -p "$pid" -d 0,1,2 2>/dev/null ||
      print '  Unavailable (or no standard descriptors remain open).'
  done
  if (( verbose )); then
    print
    print -r -- "Tip: portinfo $port --files  (browse all open descriptors)"
  fi
}
