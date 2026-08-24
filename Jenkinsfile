pipeline {
  agent any

  options {
    disableConcurrentBuilds()
    timestamps()
    timeout(time: 30, unit: 'MINUTES')
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  parameters {
    booleanParam(name: 'DEPLOY_STAGING', defaultValue: false, description: 'Deploy the immutable image to staging.')
    booleanParam(name: 'DEPLOY_PRODUCTION', defaultValue: false, description: 'Allow production promotion after staging validation.')
  }

  environment {
    REGISTRY = 'ghcr.io'
    IMAGE = "${REGISTRY}/${env.GHCR_IMAGE ?: 'owner/project22-production-jenkins-cicd'}"
    IMAGE_TAG = "${env.GIT_COMMIT ?: 'local'}"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Install & Test') {
      steps {
        dir('app') { sh 'npm ci' }
        sh 'npm test'
      }
    }

    stage('Static Validation') {
      steps {
        sh 'node --check app/server.js'
        sh 'test -f app/package-lock.json'
      }
    }

    stage('Build Image') {
      when { expression { return env.CHANGE_ID == null || env.CHANGE_ID == '' } }
      steps {
        sh 'docker build --pull -t "$IMAGE:$IMAGE_TAG" .'
      }
    }

    stage('Container Smoke Test') {
      when { expression { return env.CHANGE_ID == null || env.CHANGE_ID == '' } }
      steps {
        sh '''
          docker rm -f project22-smoke >/dev/null 2>&1 || true
          docker run -d --name project22-smoke -e APP_VERSION="$IMAGE_TAG" -p 3010:3000 "$IMAGE:$IMAGE_TAG"
          for i in $(seq 1 30); do
            if curl -fsS http://127.0.0.1:3010/health >/dev/null; then exit 0; fi
            sleep 1
          done
          docker logs project22-smoke
          exit 1
        '''
      }
      post {
        always { sh 'docker rm -f project22-smoke >/dev/null 2>&1 || true' }
      }
    }

    stage('Push Image') {
      when {
        allOf {
          branch 'main'
          expression { return env.CHANGE_ID == null || env.CHANGE_ID == '' }
        }
      }
      steps {
        withCredentials([usernamePassword(credentialsId: 'ghcr-push', usernameVariable: 'REG_USER', passwordVariable: 'REG_TOKEN')]) {
          sh '''
            echo "$REG_TOKEN" | docker login "$REGISTRY" --username "$REG_USER" --password-stdin
            docker push "$IMAGE:$IMAGE_TAG"
            docker tag "$IMAGE:$IMAGE_TAG" "$IMAGE:main"
            docker push "$IMAGE:main"
            docker logout "$REGISTRY"
          '''
        }
      }
    }

    stage('Deploy Staging') {
      when {
        allOf {
          branch 'main'
          expression { return params.DEPLOY_STAGING }
        }
      }
      steps {
        withCredentials([sshUserPrivateKey(credentialsId: 'staging-ssh', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
          sh '''
            ssh -i "$SSH_KEY" -o StrictHostKeyChecking=yes "$SSH_USER@$STAGING_HOST" \
              "bash -s -- '$IMAGE:$IMAGE_TAG'" < scripts/deploy_remote.sh
          '''
        }
      }
    }

    stage('Staging Smoke Test') {
      when { expression { return params.DEPLOY_STAGING } }
      steps {
        sh 'curl --fail --retry 10 --retry-delay 2 "$STAGING_URL/health"'
      }
    }

    stage('Production Approval') {
      when {
        allOf {
          branch 'main'
          expression { return params.DEPLOY_PRODUCTION }
        }
      }
      steps {
        input message: 'Promote the tested image to production?', ok: 'Deploy'
      }
    }

    stage('Deploy Production') {
      when {
        allOf {
          branch 'main'
          expression { return params.DEPLOY_PRODUCTION }
        }
      }
      steps {
        withCredentials([sshUserPrivateKey(credentialsId: 'production-ssh', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
          sh '''
            ssh -i "$SSH_KEY" -o StrictHostKeyChecking=yes "$SSH_USER@$PRODUCTION_HOST" \
              "bash -s -- '$IMAGE:$IMAGE_TAG'" < scripts/deploy_remote.sh
          '''
        }
      }
    }

    stage('Production Smoke Test') {
      when { expression { return params.DEPLOY_PRODUCTION } }
      steps {
        sh 'curl --fail --retry 10 --retry-delay 2 "$PRODUCTION_URL/health"'
      }
    }
  }

  post {
    always {
      sh 'docker logout "$REGISTRY" >/dev/null 2>&1 || true'
    }
    failure {
      echo 'Pipeline failed. Review the failed stage before promotion.'
    }
  }
}
