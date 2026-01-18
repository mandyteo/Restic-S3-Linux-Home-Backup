#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   sudo /usr/local/sbin/restic-home-backup.sh
#   sudo VERBOSE=1 /usr/local/sbin/restic-home-backup.sh
#   sudo DRYRUN=1 /usr/local/sbin/restic-home-backup.sh
#   sudo DRYRUN=1 VERBOSE=1 /usr/local/sbin/restic-home-backup.sh

DRYRUN="${DRYRUN:-0}"
VERBOSE="${VERBOSE:-0}"

BACKUP_ARGS=()

if [ "$DRYRUN" = "1" ]; then
  BACKUP_ARGS+=(--dry-run)
  VERBOSE=1
fi

if [ "$VERBOSE" = "1" ]; then
  BACKUP_ARGS+=(--verbose)
fi

EXCLUDE_FILE="/etc/restic/home-excludes.txt"
ENV_FILE="/etc/restic/shayu-home.env"
LOCK_FILE="/run/restic-home-backup.lock"

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

# NOTE: To prevent concurrent runs...
exec 200>"$LOCK_FILE"
flock -n 200 || exit 0

HOST_SHORT="$(hostname -s)"
TAG="home-daily"

restic backup /home \
  --exclude-caches \
  --one-file-system \
  --tag "$TAG" \
  --host "$HOST_SHORT" \
  --exclude-file "$EXCLUDE_FILE" \
  "${BACKUP_ARGS[@]}"

restic forget \
  --tag "$TAG" \
  --host "$HOST_SHORT" \
  --keep-daily 14 \
  --keep-weekly 8 \
  --keep-monthly 12 \
  --prune
