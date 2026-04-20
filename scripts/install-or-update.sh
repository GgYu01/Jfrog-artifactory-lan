#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

require_cmd curl
require_cmd python3
require_cmd tar
load_env
ensure_repo_dirs

MODE="${1:---configured-only}"

if [[ "${MODE}" == "--track-latest" ]]; then
  LATEST_VERSION="$(
    python3 "${REPO_ROOT}/scripts/lib/releases.py" latest "${JFROG_RELEASE_INDEX_URL}"
  )"
  if [[ "${ARTIFACTORY_VERSION}" != "${LATEST_VERSION}" ]]; then
    info "Updating .env ARTIFACTORY_VERSION from ${ARTIFACTORY_VERSION} to ${LATEST_VERSION}"
    python3 - "${ENV_FILE}" "${LATEST_VERSION}" <<'PY'
from pathlib import Path
import sys

env_path = Path(sys.argv[1])
latest = sys.argv[2]
lines = env_path.read_text(encoding="utf-8").splitlines()
updated = []
seen = False
for line in lines:
    if line.startswith("ARTIFACTORY_VERSION="):
        updated.append(f"ARTIFACTORY_VERSION={latest}")
        seen = True
    else:
        updated.append(line)
if not seen:
    updated.append(f"ARTIFACTORY_VERSION={latest}")
env_path.write_text("\n".join(updated) + "\n", encoding="utf-8")
PY
    load_env
  fi
elif [[ "${MODE}" != "--configured-only" ]]; then
  fail "Unknown option ${MODE}. Use --configured-only or --track-latest."
fi

ARCHIVE_NAME="jfrog-artifactory-oss-${ARTIFACTORY_VERSION}-compose.tar.gz"
ARCHIVE_URL="${JFROG_RELEASE_INDEX_URL%/}/${ARTIFACTORY_VERSION}/${ARCHIVE_NAME}"
ARCHIVE_PATH="${REPO_ROOT}/vendor/upstream/${ARCHIVE_NAME}"
EXTRACT_DIR="${REPO_ROOT}/vendor/upstream/artifactory-oss-${ARTIFACTORY_VERSION}"

if [[ ! -f "${ARCHIVE_PATH}" ]]; then
  info "Downloading upstream package ${ARCHIVE_URL}"
  curl -fsSL -o "${ARCHIVE_PATH}" "${ARCHIVE_URL}"
else
  info "Upstream package already cached: ${ARCHIVE_PATH}"
fi

if [[ ! -d "${EXTRACT_DIR}" ]]; then
  mkdir -p "${EXTRACT_DIR}"
  tar -xzf "${ARCHIVE_PATH}" -C "${REPO_ROOT}/vendor/upstream"
  info "Extracted upstream package into ${REPO_ROOT}/vendor/upstream"
else
  info "Upstream package already extracted: ${EXTRACT_DIR}"
fi

bash "${REPO_ROOT}/scripts/prepare-host.sh"
info "Install-or-update preparation completed for configured version ${ARTIFACTORY_VERSION}."
