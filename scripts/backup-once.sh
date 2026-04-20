#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

require_cmd tar
load_env
ensure_repo_dirs

BACKUP_ROOT="${REPO_ROOT}/data/backups"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE_PATH="${BACKUP_ROOT}/artifactory-backup-${TIMESTAMP}.tar.gz"

mkdir -p "${BACKUP_ROOT}"

tar -czf "${ARCHIVE_PATH}" \
  -C "${REPO_ROOT}" \
  .env \
  data/artifactory/var \
  data/postgres/data

mapfile -t archives < <(find "${BACKUP_ROOT}" -maxdepth 1 -type f -name 'artifactory-backup-*.tar.gz' | sort)
if (( ${#archives[@]} > 1 )); then
  for old_archive in "${archives[@]:0:${#archives[@]}-1}"; do
    rm -f "${old_archive}"
  done
fi

info "Created backup archive ${ARCHIVE_PATH}"

