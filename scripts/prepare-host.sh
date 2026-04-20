#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

require_cmd python3
load_env
ensure_repo_dirs

python3 - \
  "${REPO_ROOT}/config/artifactory/templates/bootstrap.creds.template" \
  "${REPO_ROOT}/data/artifactory/var/etc/access/bootstrap.creds" \
  "${ARTIFACTORY_ADMIN_USER}" \
  "${ARTIFACTORY_ADMIN_PASSWORD}" <<'PY'
from pathlib import Path
import sys

template_path = Path(sys.argv[1])
target_path = Path(sys.argv[2])
admin_user = sys.argv[3]
admin_password = sys.argv[4]

content = template_path.read_text(encoding="utf-8")
content = content.replace("__ARTIFACTORY_ADMIN_USER__", admin_user)
content = content.replace("__ARTIFACTORY_ADMIN_PASSWORD__", admin_password)
target_path.write_text(content, encoding="utf-8")
PY
copy_if_different \
  "${REPO_ROOT}/config/artifactory/var/etc/security/master.key" \
  "${REPO_ROOT}/data/artifactory/var/etc/security/master.key"
copy_if_different \
  "${REPO_ROOT}/config/artifactory/var/etc/security/join.key" \
  "${REPO_ROOT}/data/artifactory/var/etc/security/join.key"
copy_if_different \
  "${REPO_ROOT}/config/artifactory/var/etc/security/master.key" \
  "${REPO_ROOT}/data/artifactory/var/bootstrap/access/etc/security/master.key"
copy_if_different \
  "${REPO_ROOT}/config/artifactory/var/etc/security/join.key" \
  "${REPO_ROOT}/data/artifactory/var/bootstrap/access/etc/security/join.key"

chmod 600 \
  "${REPO_ROOT}/data/artifactory/var/etc/access/bootstrap.creds" \
  "${REPO_ROOT}/data/artifactory/var/etc/security/master.key" \
  "${REPO_ROOT}/data/artifactory/var/etc/security/join.key" \
  "${REPO_ROOT}/data/artifactory/var/bootstrap/access/etc/security/master.key" \
  "${REPO_ROOT}/data/artifactory/var/bootstrap/access/etc/security/join.key"

maybe_chown_tree "1030:1030" "${REPO_ROOT}/data/artifactory/var"
maybe_chown_tree "999:999" "${REPO_ROOT}/data/postgres/data"

info "Prepared host directories and bootstrap files under ${REPO_ROOT}/data"
