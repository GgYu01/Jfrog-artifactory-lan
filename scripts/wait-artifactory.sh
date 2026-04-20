#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

require_cmd curl
load_env

BASE_URL="$(admin_probe_base_url)"
ROUTER_URL="${BASE_URL}/router/api/v1/system/health"
PING_URL="${BASE_URL}/artifactory/api/system/ping"

for attempt in $(seq 1 60); do
  if curl -fsS "${ROUTER_URL}" >/dev/null 2>&1 && curl -fsS "${PING_URL}" | grep -q '^OK'; then
    info "Artifactory is healthy."
    exit 0
  fi
  sleep 10
done

fail "Artifactory did not become healthy in time."
