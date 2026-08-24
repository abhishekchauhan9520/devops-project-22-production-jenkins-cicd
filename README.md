# Project 22 — Production Jenkins CI/CD

A production-style Jenkins pipeline for a small Node.js service. The project demonstrates reproducible tests, immutable image tags, container smoke testing, credential isolation, staging promotion, manual production approval, timeouts, concurrency control, and deployment verification.

## Pipeline

```text
Pull Request
   ↓
Checkout → npm ci → Tests → Static validation

main
   ↓
Docker build
   ↓
Container smoke test
   ↓
Push immutable image tagged with Git SHA
   ↓
Optional staging deployment
   ↓
Staging smoke test
   ↓
Manual production approval
   ↓
Production deployment
   ↓
Production smoke test
```

## Jenkins configuration

Create these credentials in Jenkins:

- `ghcr-push` — username/password credential for GHCR push
- `staging-ssh` — SSH private-key credential
- `production-ssh` — SSH private-key credential

Set these environment variables at the Jenkins job/global-folder level:

- `GHCR_IMAGE`
- `STAGING_HOST`
- `STAGING_URL`
- `PRODUCTION_HOST`
- `PRODUCTION_URL`

The pipeline uses Git SHA tags for immutable deployment artifacts. Do not place registry, SSH, or cloud secrets in the repository.

## Local validation

```bash
./scripts/validate.sh
```

The local environment can execute the Node tests and repository checks. Docker image build and Jenkinsfile execution require Docker and Jenkins respectively.

## Why this is different from Project 11

Project 11 demonstrates a basic Jenkins + Docker pipeline. Project 22 focuses on production pipeline controls and release discipline: reproducible dependencies, immutable artifacts, credentials, protected promotion, staging verification, production approval, health checks, timeouts, concurrency control, and deployment rollback.
