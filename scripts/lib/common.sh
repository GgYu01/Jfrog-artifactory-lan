#!/usr/bin/env bash
set -euo pipefail

COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${COMMON_DIR}/../.." && pwd)"
ENV_FILE="${REPO_ROOT}/.env"

info() {
  printf '[INFO] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*" >&2
}

fail() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

ensure_env_file() {
  if [[ ! -f "${ENV_FILE}" ]]; then
    cp "${REPO_ROOT}/.env.example" "${ENV_FILE}"
    info "Created ${ENV_FILE} from .env.example"
  fi
}

load_env() {
  ensure_env_file
  while IFS= read -r line || [[ -n "${line}" ]]; do
    line="${line%$'\r'}"
    [[ -z "${line}" || "${line}" =~ ^[[:space:]]*# ]] && continue
    [[ "${line}" == *=* ]] || fail "Invalid .env line: ${line}"

    local key="${line%%=*}"
    local value="${line#*=}"

    [[ "${key}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || fail "Invalid .env key: ${key}"

    if [[ "${value}" =~ ^\".*\"$ || "${value}" =~ ^\'.*\'$ ]]; then
      value="${value:1:${#value}-2}"
    fi

    printf -v "${key}" '%s' "${value}"
    export "${key}"
  done < "${ENV_FILE}"
}

ensure_repo_dirs() {
  mkdir -p \
    "${REPO_ROOT}/data/artifactory/var/bootstrap" \
    "${REPO_ROOT}/data/artifactory/var/data" \
    "${REPO_ROOT}/data/artifactory/var/etc/access" \
    "${REPO_ROOT}/data/artifactory/var/etc/security" \
    "${REPO_ROOT}/data/artifactory/var/etc/artifactory" \
    "${REPO_ROOT}/data/artifactory/var/etc/router" \
    "${REPO_ROOT}/data/artifactory/var/log" \
    "${REPO_ROOT}/data/artifactory/var/backup" \
    "${REPO_ROOT}/data/postgres/data" \
    "${REPO_ROOT}/vendor/upstream" \
    "${REPO_ROOT}/tmp" \
    "${REPO_ROOT}/reports"
}

copy_if_different() {
  local source_file="$1"
  local target_file="$2"
  mkdir -p "$(dirname "${target_file}")"
  if [[ ! -f "${target_file}" ]] || ! cmp -s "${source_file}" "${target_file}"; then
    cp "${source_file}" "${target_file}"
  fi
}

maybe_chown_tree() {
  local owner_group="$1"
  local target_dir="$2"
  if chown -R "${owner_group}" "${target_dir}" >/dev/null 2>&1; then
    return 0
  fi
  warn "Could not chown ${target_dir} to ${owner_group}; run with elevated privileges if your container runtime needs it."
}

compose_available() {
  command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1
}

compose_run() {
  if ! compose_available; then
    fail "docker compose is required for this action but Docker is not installed or not usable."
  fi
  (cd "${REPO_ROOT}" && docker compose "$@")
}

admin_probe_host() {
  case "${ARTIFACTORY_ADMIN_BIND_HOST:-127.0.0.1}" in
    0.0.0.0|'::'|'[::]')
      printf '127.0.0.1'
      ;;
    *)
      printf '%s' "${ARTIFACTORY_ADMIN_BIND_HOST:-127.0.0.1}"
      ;;
  esac
}

admin_probe_base_url() {
  printf 'http://%s:%s' "$(admin_probe_host)" "${ARTIFACTORY_ADMIN_PORT:-8082}"
}

configured_admin_url() {
  printf 'http://%s:%s' "${ARTIFACTORY_ADMIN_BIND_HOST:-127.0.0.1}" "${ARTIFACTORY_ADMIN_PORT:-8082}"
}

latest_backup_archive() {
  find "${REPO_ROOT}/data/backups" -maxdepth 1 -type f -name 'artifactory-backup-*.tar.gz' 2>/dev/null | sort | tail -n 1
}

write_report_line() {
  local text="$1"
  mkdir -p "${REPO_ROOT}/tmp"
  printf '%s\n' "${text}" >> "${REPO_ROOT}/tmp/runtime.log"
}
