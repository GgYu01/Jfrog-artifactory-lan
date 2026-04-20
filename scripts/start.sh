#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

bash "${REPO_ROOT}/scripts/install-or-update.sh" --configured-only
load_env
compose_run up -d --build
bash "${REPO_ROOT}/scripts/wait-artifactory.sh"
bash "${REPO_ROOT}/scripts/bootstrap-artifactory.sh"
info "Stack started. Portal (host-local): http://127.0.0.1:${PORTAL_PORT:-8080}  Portal (LAN): http://<host>:${PORTAL_PORT:-8080}  Admin UI: $(configured_admin_url)"
