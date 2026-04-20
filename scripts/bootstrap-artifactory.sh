#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

require_cmd curl
load_env

BASE_URL="$(admin_probe_base_url)"
AUTH=("${ARTIFACTORY_ADMIN_USER}:${ARTIFACTORY_ADMIN_PASSWORD}")
REPO_URL="${BASE_URL}/artifactory/api/storage/${CONTENT_REPOSITORY_KEY}"
REPO_CONFIG_URL="${BASE_URL}/artifactory/api/repositories/${CONTENT_REPOSITORY_KEY}"

ensure_content_repository() {
  local status
  local payload
  local response_file
  response_file="$(mktemp)"

  status="$(
    curl -sS -o "${response_file}" -w '%{http_code}' \
      -u "${AUTH[0]}" \
      "${REPO_CONFIG_URL}"
  )"
  if [[ "${status}" == "200" ]]; then
    rm -f "${response_file}"
    info "Repository ${CONTENT_REPOSITORY_KEY} already exists."
    return 0
  fi

  if [[ "${status}" != "404" ]]; then
    local existing_response
    existing_response="$(cat "${response_file}")"
    rm -f "${response_file}"
    fail "Unexpected response while checking repository ${CONTENT_REPOSITORY_KEY}: HTTP ${status}. Response: ${existing_response}"
  fi
  rm -f "${response_file}"

  payload="$(mktemp)"
  cat >"${payload}" <<EOF
{
  "key": "${CONTENT_REPOSITORY_KEY}",
  "rclass": "local",
  "packageType": "generic",
  "description": "LAN firmware and patch drop repository",
  "includesPattern": "**/*",
  "excludesPattern": "",
  "handleReleases": true,
  "handleSnapshots": true
}
EOF

  response_file="$(mktemp)"
  status="$(
    curl -sS -o "${response_file}" -w '%{http_code}' \
      -u "${AUTH[0]}" \
      -X PUT \
      -H 'Content-Type: application/json' \
      --data-binary "@${payload}" \
      "${REPO_CONFIG_URL}"
  )"
  rm -f "${payload}"

  if [[ "${status}" == "200" || "${status}" == "201" ]]; then
    rm -f "${response_file}"
    info "Created generic local repository ${CONTENT_REPOSITORY_KEY}."
    return 0
  fi

  local create_response
  create_response="$(cat "${response_file}")"
  rm -f "${response_file}"
  fail "Could not create repository ${CONTENT_REPOSITORY_KEY} automatically (HTTP ${status}). If your Artifactory build rejects repository creation through the API, create a local Generic repository named ${CONTENT_REPOSITORY_KEY} in the admin UI, then rerun this script. Response: ${create_response}"
}

ensure_content_repository

if ! curl -fsS -u "${AUTH[0]}" "${REPO_URL}" >/dev/null 2>&1; then
  fail "The configured content repository '${CONTENT_REPOSITORY_KEY}' is not reachable after bootstrap. Update CONTENT_REPOSITORY_KEY in .env or create the repository manually in the admin UI."
fi

upload_placeholder() {
  local area_prefix="$1"
  local temp_file
  temp_file="$(mktemp)"
  printf 'Repository bootstrap marker for %s\n' "${area_prefix}" > "${temp_file}"
  curl -fsS -u "${AUTH[0]}" \
    -X PUT \
    -H 'Content-Type: text/plain' \
    --data-binary "@${temp_file}" \
    "${BASE_URL}/artifactory/${CONTENT_REPOSITORY_KEY}/${area_prefix}/.bootstrap-marker.txt" \
    >/dev/null
  rm -f "${temp_file}"
}

upload_placeholder "${FIRMWARE_PREFIX}"
upload_placeholder "${PATCH_PREFIX}"

info "Bootstrap content markers uploaded for ${CONTENT_REPOSITORY_KEY}/${FIRMWARE_PREFIX} and ${CONTENT_REPOSITORY_KEY}/${PATCH_PREFIX}"
