# Operations Runbook

## Release model

Every deployable image is tagged with the Git commit SHA. The `main` tag is informational; production promotion uses the immutable SHA tag.

## Staging

1. Build and smoke-test the image in Jenkins.
2. Push the immutable image to GHCR.
3. Enable `DEPLOY_STAGING`.
4. Jenkins connects to the staging host and runs `scripts/deploy_remote.sh`.
5. The remote script pulls the new image, replaces the container, and checks `/health`.
6. If the new container fails health checks, the script removes it and starts the previously running image when one exists.

## Production

Production requires both `DEPLOY_PRODUCTION=true` and the Jenkins input approval. The production smoke test runs after deployment.

## Manual rollback

```bash
docker ps -a
docker images --format '{{.Repository}}:{{.Tag}}'
docker rm -f project22 || true
docker run -d --name project22 --restart unless-stopped -p 3000:3000 <known-good-image>
curl --fail http://127.0.0.1:3000/health
```

## Jenkins credentials

Use Jenkins credential storage for registry and SSH credentials. Do not copy secrets into `Jenkinsfile`, environment files committed to Git, Docker build arguments, or shell history.
