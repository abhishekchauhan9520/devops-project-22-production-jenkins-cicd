#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"
node --check app/server.js
node --test tests/*.test.js
python3 tests/repo.test.py
python3 - <<'PY'
from pathlib import Path
for required in ['Jenkinsfile','Dockerfile','docker-compose.yml','scripts/deploy_remote.sh','docs/operations.md','app/package-lock.json']:
    assert Path(required).is_file(), required
text = Path('Jenkinsfile').read_text()
for needle in ['disableConcurrentBuilds()', 'timeout(', 'withCredentials', 'docker build', 'docker push', 'input message', 'DEPLOY_STAGING', 'DEPLOY_PRODUCTION', 'StrictHostKeyChecking=yes']:
    assert needle in text, needle
print('Project 22 offline validation passed.')
PY
