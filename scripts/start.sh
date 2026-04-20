#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

load_env
require_safe_admin_password_for_lan_bind
bash "${REPO_ROOT}/scripts/install-or-update.sh" --configured-only
load_env
compose_run up -d --build
bash "${REPO_ROOT}/scripts/wait-artifactory.sh"
bash "${REPO_ROOT}/scripts/bootstrap-artifactory.sh"
info "Stack started. Portal: http://<host>:${PORTAL_PORT:-8080}  Admin UI (access): $(configured_admin_access_url)  Admin bind: ${ARTIFACTORY_ADMIN_BIND_HOST:-127.0.0.1}:${ARTIFACTORY_ADMIN_PORT:-8082}"
