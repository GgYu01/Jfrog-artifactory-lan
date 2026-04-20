#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

load_env
ARTIFACTORY_URL="$(configured_admin_url)"
ARTIFACTORY_PROBE_URL="$(admin_probe_base_url)"

if compose_available; then
  if ! compose_run ps; then
    warn "docker compose ps failed; continuing with static status output."
  fi
else
  warn "Docker is not available in this environment."
fi

printf 'Configured portal URL (host-local): http://127.0.0.1:%s\n' "${PORTAL_PORT}"
printf 'Configured portal URL (LAN): http://<host>:%s\n' "${PORTAL_PORT}"
printf 'Configured Artifactory URL: %s\n' "${ARTIFACTORY_URL}"

if command -v curl >/dev/null 2>&1; then
  if curl -fsS "http://127.0.0.1:${PORTAL_PORT}/api/health" >/dev/null 2>&1; then
    printf 'Portal health: OK\n'
  else
    printf 'Portal health: UNREACHABLE\n'
  fi

  if curl -fsS "${ARTIFACTORY_PROBE_URL}/router/api/v1/system/health" >/dev/null 2>&1 \
    && curl -fsS "${ARTIFACTORY_PROBE_URL}/artifactory/api/system/ping" | grep -q '^OK'; then
    printf 'Artifactory health: OK\n'
  else
    printf 'Artifactory health: UNREACHABLE\n'
  fi
fi

LATEST_BACKUP="$(latest_backup_archive || true)"
if [[ -n "${LATEST_BACKUP}" ]]; then
  printf 'Latest backup archive: %s\n' "${LATEST_BACKUP}"
else
  printf 'Latest backup archive: none\n'
fi
