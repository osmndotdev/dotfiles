# This is a zsh file; shellcheck only understands bash and reports false positives.
# shellcheck disable=all

# Requires:
#   - lsof (without sudo, it only sees your own processes)
# Config: none

portkill() {
  local port="$1"

  if [[ -z "$port" ]]; then
    echo "usage: portkill <port>"
    return 2
  fi

  local pids
  pids=$(lsof -tiTCP:"$port" -sTCP:LISTEN)

  if [[ -z "$pids" ]]; then
    echo "No process listening on port $port"
    return 1
  fi

  echo "$pids" | xargs kill
}

portkill-force() {
  local port="$1"

  if [[ -z "$port" ]]; then
    echo "usage: portkill-force <port>"
    return 2
  fi

  local pids
  pids=$(lsof -tiTCP:"$port" -sTCP:LISTEN)

  if [[ -z "$pids" ]]; then
    echo "No process listening on port $port"
    return 1
  fi

  echo "$pids" | xargs kill -9
}
