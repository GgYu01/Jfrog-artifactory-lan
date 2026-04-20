#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

require_cmd bash
require_cmd python3
require_cmd node
load_env

for script in \
  "${REPO_ROOT}/scripts/"*.sh \
  "${REPO_ROOT}/scripts/lib/common.sh"; do
  bash -n "${script}"
done

python3 - "${REPO_ROOT}/docker-compose.yml" <<'PY'
import sys
from pathlib import Path
import yaml

path = Path(sys.argv[1])
with path.open("r", encoding="utf-8") as handle:
    yaml.safe_load(handle)
PY
node --check "${REPO_ROOT}/portal/server.js"
python3 -m unittest discover -s "${REPO_ROOT}/tests" -p 'test_*.py'
node --test "${REPO_ROOT}/portal/tests/"*.test.js

info "Validation completed."
