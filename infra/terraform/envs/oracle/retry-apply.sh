#!/bin/bash
# Retry terraform apply with backoff for A1.Flex capacity contention
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

MAX_ATTEMPTS=10
ATTEMPT=1
SLEEP=15

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
  echo "=== Attempt $ATTEMPT/$MAX_ATTEMPTS ==="

  set +e
  OUTPUT=$(terraform apply -auto-approve -lock=false 2>&1)
  EXIT_CODE=$?
  set -e

  if [ $EXIT_CODE -eq 0 ]; then
    echo "$OUTPUT"
    echo "=== SUCCESS on attempt $ATTEMPT ==="
    exit 0
  fi

  if echo "$OUTPUT" | grep -q "Out of host capacity"; then
    echo "=== Out of capacity. Retrying in ${SLEEP}s... ==="
  else
    echo "$OUTPUT"
    echo "=== Non-capacity error. Aborting. ==="
    exit 1
  fi

  sleep $SLEEP
  ATTEMPT=$((ATTEMPT + 1))
  SLEEP=$((SLEEP * 2))
  [ $SLEEP -gt 120 ] && SLEEP=120
done

echo "=== Failed after $MAX_ATTEMPTS attempts. ==="
exit 1
