pipeline {
    agent any
    options {
        timestamps()
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
    }
    environment {
        IMAGE_REPOSITORY = 'unbee-lee/aws-elastic-beanstalk-express-js-sample'
    }
    stages {
        stage('Checkout') {
            steps {
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
        // The security, image-build and publication stages appear in Listing 6.
    }
}

