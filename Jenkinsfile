pipeline {
    agent any

    tools {
        maven 'Maven3'
        jdk   'JDK17'
    }

    environment {
        DOCKERHUB_CREDENTIALS = "docker_hub_cred"
        DOCKERHUB_REPO        = "saurabhdevops17/boardgame-listing"
        IMAGE_NAME            = "boardgame-listing"
        IMAGE_TAG             = "${env.GIT_COMMIT.take(7)}"
        SONARQUBE_ENV         = "MySonarQubeServer"
        AWS_REGION            = "ap-south-1"
        EKS_CLUSTER_NAME      = "boardgame-eks-cluster"
        KUBE_NAMESPACE        = "capstone"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/saurabhss-17/Boardgame.git'
            }
        }

        stage('Build') {
            steps {
                sh "mvn clean install -DskipTests"
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build --no-cache -t ${IMAGE_NAME}:latest .
                    docker tag ${IMAGE_NAME}:latest ${DOCKERHUB_REPO}:latest
                """
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: "${DOCKERHUB_CREDENTIALS}",
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${DOCKERHUB_REPO}:latest
                    '''
                }
            }
        }

        stage('SonarQube Analysis') {
    steps {
        withSonarQubeEnv("${SONARQUBE_ENV}") {
            withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                sh """
                    echo "DEBUG: Token length = \${#SONAR_TOKEN}"

                    mvn clean verify sonar:sonar \
                      -Dsonar.projectKey=Boardgame \
                      -Dsonar.projectName=Boardgame \
                      -Dsonar.host.url=$SONAR_HOST_URL \
                      -Dsonar.login=$SONAR_TOKEN
                """
            }
        }
    }
}

        stage('Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('OWASP Dependency-Check Vulnerabilities') {
            steps {
                dependencyCheck additionalArguments: '''
                    -o './'
                    -s './'
                    -f 'ALL'
                    --prettyPrint
                ''',
                odcInstallation: 'owasp-DC'
                dependencyCheckPublisher pattern: 'dependency-check-report.xml'
            }
        }

        stage('Deploy to EKS') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws_eks_access',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                        set -e
                        echo "=== AWS identity check ==="
                        aws sts get-caller-identity

                        echo "=== Updating kubeconfig for EKS ==="
                        export AWS_DEFAULT_REGION=${AWS_REGION}
                        aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME} --region ${AWS_REGION}

                        echo "=== Ensuring namespace exists ==="
                        kubectl create namespace ${KUBE_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

                        echo "=== Deploying application ==="
                        kubectl apply -f k8s/namespace.yaml
                        kubectl apply -f k8s/deployment.yaml -n ${KUBE_NAMESPACE}
                    '''
        }
      }
    }
  }
}
