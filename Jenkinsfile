pipeline {
    agent any
    options {
        timestamps()
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
        // Build records and diagnostic artifacts use matching retention windows.
        buildDiscarder(logRotator(
            numToKeepStr: '30',
            artifactNumToKeepStr: '30'
        ))
    }
    triggers {
        // SCM changes are checked at a hashed 15-minute interval.
        pollSCM('H/15 * * * *')
    }
    environment {
        IMAGE_REPOSITORY = 'unbeelee/aws-elastic-beanstalk-express-js-sample'
    }
    stages {
        stage('Checkout') {
            steps {
                // Generated evidence is cleared from the reused workspace.
                dir('reports') {
                    deleteDir()
                }
                sh 'rm -f -- image-metadata.txt .workspace-write-check'

                checkout scm
                script {
                    env.SOURCE_REVISION = sh(
                        returnStdout: true,
                        script: 'git rev-parse HEAD'
                    ).trim()
                    env.IMAGE_TAG = "${env.BUILD_NUMBER}-${env.SOURCE_REVISION.take(12)}"
                }
            }
        }
        stage('Install dependencies') {
            agent {
                docker {
                    image 'node:16-bullseye-slim'
                    args '--user 1000:1000 -e HOME=/home/node'
                    reuseNode true
                }
            }
            steps {
                sh '''
                    node --version
                    npm --version
                    whoami
                    id
                    test "$(id -u)" -ne 0
                    touch .workspace-write-check
		    test -w .workspace-write-check
		    rm .workspace-write-check
		    echo "workspace write check: PASS"
                    mkdir -p reports
                    npm ci --no-audit
                '''
            }
        }
        stage('Unit tests') {
            agent {
                docker {
                    image 'node:16-bullseye-slim'
                    args '--user 1000:1000 -e HOME=/home/node'
                    reuseNode true
                }
            }
            steps {
                sh 'npm run test:ci'
            }
        }
        stage('Dependency security gate') {
    agent {
        docker {
            image 'node:16-bullseye-slim'
            args '--user 1000:1000 -e HOME=/home/node'
            reuseNode true
        }
    }

    steps {
        sh '''
            mkdir -p reports
            npm --version

            audit_status=0

            npm audit --audit-level=high --json \
              > reports/npm-audit.json || audit_status=$?

            node -e "const r=require('./reports/npm-audit.json'); \
              if(r.error){ \
                console.error(r.error.summary || r.error); \
                process.exit(2); \
              } \
              console.log(r.metadata.vulnerabilities);"

            test "$audit_status" -eq 0
        '''
    }
}
        stage('Build image') {
            steps {
                sh '''
                    docker build --pull \
                     --label "org.opencontainers.image.revision=$SOURCE_REVISION" \
                      -t "$IMAGE_REPOSITORY:$IMAGE_TAG" .

                    echo "built image: $IMAGE_REPOSITORY:$IMAGE_TAG"

                    docker image inspect "$IMAGE_REPOSITORY:$IMAGE_TAG" \
                     --format='id={{.Id}} revision={{index .Config.Labels "org.opencontainers.image.revision"}}' \
                     | tee image-metadata.txt
                '''
            }
         }
        stage('Publish image') {
    steps {
        withCredentials([usernamePassword(
            credentialsId: 'dockerhub-assessment2',
            usernameVariable: 'REGISTRY_USER',
            passwordVariable: 'REGISTRY_TOKEN'
        )]) {
            sh '''
                set +x

                trap 'docker logout docker.io >/dev/null 2>&1 || true' EXIT

                printf '%s' "$REGISTRY_TOKEN" |
                  docker login docker.io \
                    --username "$REGISTRY_USER" \
                    --password-stdin

                docker push "$IMAGE_REPOSITORY:$IMAGE_TAG"

                docker image inspect "$IMAGE_REPOSITORY:$IMAGE_TAG" \
                  --format='digest={{index .RepoDigests 0}}' \
                  | tee -a image-metadata.txt
            '''
        }
    }
}
    } // closes stages

    post {
        always {
            // Diagnostic output is retained for successful and failed runs.
            archiveArtifacts(
                artifacts: 'reports/junit.xml,reports/npm-audit.json,image-metadata.txt',
                allowEmptyArchive: true,
                onlyIfSuccessful: false
            )
            script {
                // Successful delivery requires a complete evidence set.
                if (currentBuild.currentResult == 'SUCCESS') {
                    def required = ['reports/junit.xml',
                                    'reports/npm-audit.json',
                                    'image-metadata.txt']
                    def missing = required.findAll { !fileExists(it) }
                    if (missing) {
                        error("Missing required build evidence: ${missing.join(', ')}")
                    }
                 }
            }
       }
   }
}

