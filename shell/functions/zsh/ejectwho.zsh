# This is a zsh file; shellcheck only understands bash and reports false positives.
# shellcheck disable=all

# Requires:
#   - macOS (diskutil, /Volumes)
#   - sudo rights (lsof runs as root to see every process)
# Config: none

# List the processes holding files open on a volume, i.e. what blocks ejecting it.
#   ejectwho MyDisk           -> /Volumes/MyDisk
#   ejectwho /Volumes/X -v    -> list every open file, not just the first 5 per process
ejectwho() {
  emulate -L zsh

  if [[ -z "$1" ]]; then
    print -u2 "usage: ejectwho <volume name | mount path> [-v]"
    return 2
  fi

  local volume="$1"
  local verbose=0
  local limit=5

  [[ "$2" == "-v" || "$2" == "--verbose" ]] && verbose=1

  # Accept both volume names and absolute mount paths.
  [[ "$volume" == /* ]] || volume="/Volumes/$volume"
  volume="${volume%/}"

  if [[ ! -d "$volume" ]] || \
     ! /usr/sbin/diskutil info "$volume" >/dev/null 2>&1; then
    print -u2 "Volume not found: $volume"
    return 1
  fi

  print "Inspecting: $volume"
  print "Scanning open files (sudo required)..."

  # A terminal whose cwd is on the disk can block ejection.
  if [[ "$PWD" == "$volume" || "$PWD" == "$volume/"* ]]; then
    print "\nWARNING: Your current terminal is inside the volume."
    print "Run 'cd ~' before attempting to eject it."
  fi

  /usr/bin/sudo -v || return 1

  # +f selects the whole mounted filesystem.
  # -F produces machine-readable records.
  local raw rc
  raw=$(/usr/bin/sudo /usr/sbin/lsof \
    -nP +c0 -Fpcufn +f -- "$volume")
  rc=$?

  if [[ -z "$raw" ]]; then
    if (( rc != 0 && rc != 1 )); then
      print -u2 "lsof failed (exit $rc)."
      return "$rc"
    fi
    print "\nNo open files were found."
    print "Some system-level blockers may not be visible to lsof."
    return 0
  fi

  local -A commands users counts paths
  local -a pids
  local line pid fd value

  # Group open files by process.
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    value="${line[2,-1]}"

    case "${line[1]}" in
      p)
        pid="$value"
        pids+=("$pid")
        counts[$pid]=0
        ;;
      c)
        commands[$pid]="$value"
        ;;
      u)
        users[$pid]="$value"
        ;;
      f)
        fd="$value"
        ;;
      n)
        [[ -z "$pid" ]] && continue
        counts[$pid]=$(( ${counts[$pid]:-0} + 1 ))

        if (( verbose || counts[$pid] <= limit )); then
          paths[$pid]+="    ${fd}  ${value}"$'\n'
        fi
        ;;
    esac
  done <<< "$raw"

  print "\nFound ${#pids} process(es):"

  local cmd
  for pid in "${pids[@]}"; do
    print "\n----------------------------------------"
    printf '%s  (PID %s, UID %s)\n' \
      "${commands[$pid]:-Unknown}" "$pid" "${users[$pid]:-?}"

    cmd=$(/bin/ps -p "$pid" -o command= 2>/dev/null)
    [[ -n "$cmd" ]] && printf '  Command: %.180s\n' "$cmd"

    printf '  Open entries: %s\n' "${counts[$pid]}"
    printf '%s' "${paths[$pid]}"

    if (( !verbose && counts[$pid] > limit )); then
      printf '    ... %d more (use -v to see all)\n' \
        "$(( counts[$pid] - limit ))"
    fi
  done

  print "\n----------------------------------------"
  print "Close the relevant apps or release their open files."
  print "Then run ejectwho again and retry ejecting normally."
}
