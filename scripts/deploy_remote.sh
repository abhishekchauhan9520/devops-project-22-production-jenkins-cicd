#!/usr/bin/env bash
set -euo pipefail

IMAGE="${1:?image required}"
PORT="${2:-3000}"
CONTAINER="${3:-project22}"
HEALTH_PATH="${4:-/health}"
PREVIOUS_IMAGE=''

if docker inspect "$CONTAINER" >/dev/null 2>&1; then
  PREVIOUS_IMAGE="$(docker inspect --format='{{.Config.Image}}' "$CONTAINER" || true)"
fi

echo "Pulling $IMAGE"
docker pull "$IMAGE"
echo "Stopping previous container"
docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
echo "Starting $CONTAINER"
docker run -d --name "$CONTAINER" --restart unless-stopped -p "${PORT}:3000" "$IMAGE" >/dev/null

for _ in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:${PORT}${HEALTH_PATH}" >/dev/null; then
    echo "Deployment healthy"
    exit 0
  fi
  sleep 2
done

echo "New deployment failed health check"
docker logs "$CONTAINER" || true
docker rm -f "$CONTAINER" >/dev/null 2>&1 || true

if [[ -n "$PREVIOUS_IMAGE" ]]; then
  echo "Rolling back to $PREVIOUS_IMAGE"
  docker run -d --name "$CONTAINER" --restart unless-stopped -p "${PORT}:3000" "$PREVIOUS_IMAGE" >/dev/null
fi

exit 1
