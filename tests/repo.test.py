from pathlib import Path

root = Path(__file__).resolve().parents[1]
required = [
    'Jenkinsfile', 'Dockerfile', 'docker-compose.yml',
    'scripts/deploy_remote.sh', 'docs/operations.md',
    '.github/workflows/validation.yml', 'app/package-lock.json'
]
for item in required:
    assert (root / item).is_file(), item

jenkins = (root / 'Jenkinsfile').read_text()
for token in [
    'disableConcurrentBuilds()', 'timeout(', 'withCredentials',
    'docker build', 'docker push', 'input message',
    'DEPLOY_STAGING', 'DEPLOY_PRODUCTION', 'StrictHostKeyChecking=yes'
]:
    assert token in jenkins, token
print('Project 22 repository checks passed.')
