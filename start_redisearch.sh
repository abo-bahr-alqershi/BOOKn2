#!/usr/bin/env bash
set -euo pipefail

IMAGE="${REDISEARCH_IMAGE:-redis/redis-stack:latest}"
CONTAINER_NAME="${REDISEARCH_CONTAINER:-redisearch-server}"
HOST_PORT="${REDISEARCH_PORT:-6379}"
DATA_DIR="${REDISEARCH_DATA_DIR:-$PWD/.redisearch-data}"
NETWORK="${REDISEARCH_NETWORK:-}"
ACTION="${1:-start}"

log() {
  printf '[redisearch] %s\n' "$1"
}

check_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    log "Docker is required but not installed or not in PATH."
    exit 1
  fi
}

prepare_data_dir() {
  mkdir -p "$DATA_DIR"
}

container_exists() {
  docker ps -a --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"
}

container_running() {
  docker ps --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"
}

start_container() {
  local network_args=()
  if [[ -n "$NETWORK" ]]; then
    network_args=(--network "$NETWORK")
  fi

  if container_running; then
    log "Container '$CONTAINER_NAME' is already running on port $HOST_PORT."
    return 0
  fi

  if container_exists; then
    log "Found existing container '$CONTAINER_NAME'. Starting it again."
    docker start "$CONTAINER_NAME" >/dev/null
  else
    log "Launching new container '$CONTAINER_NAME' from image '$IMAGE'."
    local run_args=(-d --name "$CONTAINER_NAME" -p "$HOST_PORT:6379" -v "$DATA_DIR:/data" --restart unless-stopped)
    if (( ${#network_args[@]} )); then
      run_args+=("${network_args[@]}")
    fi
    run_args+=("$IMAGE")
    docker run "${run_args[@]}" >/dev/null
  fi

  wait_for_ready
}

stop_container() {
  if ! container_exists; then
    log "Container '$CONTAINER_NAME' does not exist. Nothing to stop."
    return 0
  fi

  if container_running; then
    log "Stopping container '$CONTAINER_NAME'."
    docker stop "$CONTAINER_NAME" >/dev/null
  fi

  log "Removing container '$CONTAINER_NAME'."
  docker rm "$CONTAINER_NAME" >/dev/null
}

status_container() {
  if container_running; then
    log "Container '$CONTAINER_NAME' is running."
    docker ps --filter "name=$CONTAINER_NAME" --format '  -> {{.Status}} (Ports: {{.Ports}})'
  elif container_exists; then
    log "Container '$CONTAINER_NAME' exists but is not running."
    docker ps -a --filter "name=$CONTAINER_NAME" --format '  -> {{.Status}}'
  else
    log "Container '$CONTAINER_NAME' is not created yet."
  fi
}

wait_for_ready() {
  local attempts=20
  local delay=0.5
  while (( attempts-- > 0 )); do
    if docker exec "$CONTAINER_NAME" redis-cli ping >/dev/null 2>&1; then
      if docker exec "$CONTAINER_NAME" redis-cli module list | grep -qx 'search'; then
        log "RediSearch module is loaded and ready at localhost:$HOST_PORT."
      else
        log "Redis started, but RediSearch module was not detected."
      fi
      return 0
    fi
    sleep "$delay"
  done

  log "Timed out waiting for container '$CONTAINER_NAME' to become ready."
  exit 1
}

main() {
  check_docker

  case "$ACTION" in
    start)
      prepare_data_dir
      start_container
      ;;
    stop)
      stop_container
      ;;
    restart)
      stop_container
      prepare_data_dir
      start_container
      ;;
    status)
      status_container
      ;;
    *)
      cat <<'EOF'
Usage: start_redisearch.sh [start|stop|restart|status]

Environment variables:
  REDISEARCH_IMAGE      Docker image to use (default: redis/redis-stack:latest)
  REDISEARCH_CONTAINER  Container name (default: redisearch-server)
  REDISEARCH_PORT       Host port to bind (default: 6379)
  REDISEARCH_DATA_DIR   Host directory for persistence (default: $PWD/.redisearch-data)
  REDISEARCH_NETWORK    Optional Docker network to attach to
EOF
      exit 1
      ;;
  es
}

main
