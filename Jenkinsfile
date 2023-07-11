/* groovylint-disable LineLength */
/* groovylint-disable-next-line CompileStatic */
pipeline {
    agent any

    environment {
        AWS_REGION = 'eu-west-2'
        AWS_ACCOUNT_ID = ''
        ECR_REPO = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"
        HELM_REPO = "${env.IMAGE_REPO}/helm-chart"
        IMAGE_TAG = "v-${env.BUILD_NUMBER}"
        NAMESPACE = 'jumia-phone-validator'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'master',
                    credentialsId: 'github_credentials',
                    url: 'https://github.com/Jumia/DevOps-Challenge.git'

                sh 'ls -lat'
            }
        }
        stage('Install and package backend') {
            steps {
                echo 'Installing maven dependencies'
                sh 'cd jumia_phone_validator/validor-backend'
                sh './mvnw clean verify -Dmaven.test.skipTests=true -Dmaven.test.skip=true --batch-mode'
            }
        }

        stage('Install and package frontend') {
            steps {
                echo 'Installing node dependencies'
                sh 'cd ../validator-frontend'
                sh 'yarn install --frozen-lockfile --production'
                sh 'yarn build --no-lint'
            }
        }

        stage('Login to ECR') {
            steps {
                sh "aws ecr get-login-password --region ${env.AWS_REGION} | docker login --username AWS --password-stdin ${env.ECR_REPO}"
            }
        }
        stage('Build Images') {
            steps {
                echo 'Building Docker Image..'
                sh "docker build --push -t ${env.ECR_REPO}/validator-backend:${env.IMAGE_TAG} ${BACKEND_CONTEXT}"
                sh "docker build --push -t ${env.ECR_REPO}/validator-frontend:${env.IMAGE_TAG} ${FRONTEND_CONTEXT}"
            }
        }
        stage('Deploy App') {
            steps {
                echo 'Installing Applications with helm'
                sh """
                    helm upgrade --install phone-validator oci://${env.HELP_REPO} \
                    --set image.frontend.repository=${env.ECR_REPO}/validator-frontend \
                    --set image.frontend.tag=${env.IMAGE_TAG} \
                    --set image.backend.repository=${env.ECR_REPO}/validator-backend \
                    --set image.backend.tag=${env.IMAGE_TAG} \
                    --namespace ${env.NAMESPACE} --atomic --timeout 15m0s
                """
            }
        }
    }
}