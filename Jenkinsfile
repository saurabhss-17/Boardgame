pipeline {

  agent any

  tools {
    maven 'Maven3'
    jdk   'JDK17'
  }

  environment {
    DOCKERHUB_CREDENTIALS = "docker_hub_cred"
    DOCKERHUB_REPO        = "jayu3110/boardgame-listing"
    IMAGE_NAME            = "boardgame-listing"
    IMAGE_TAG             = "${env.GIT_COMMIT.take(7)}"
    SONARQUBE_ENV         = 'MySonarQubeServer'
    AWS_REGION            = 'ap-south-1'
    EKS_CLUSTER_NAME      = 'boardgame-eks-cluster'
    KUBE_NAMESPACE        = 'capstone'
  }

  stages {

    stage('Checkout') {
      steps {
        git branch: 'main',
            url: 'https://github.com/JK00119500/boardgame.git'
      }
    }

    stage('Build') {
      steps {
        sh '''
          mvn clean install -DskipTests
        '''
      }
    }

    stage('Build Docker Image') {
      steps {
        sh """
          pwd
          ls -lrt

          # Build local image
          docker build --no-cache -t ${IMAGE_NAME}:latest .

          ls -lrt target

          # Tag for Docker Hub
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

    stage('Trivy scan') {
      steps {
        sh '''
          docker run --rm --name trivy-cli \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -u root \
            aquasec/trivy:latest image \
            ${IMAGE_NAME}:latest
        '''
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv("${SONARQUBE_ENV}") {
          sh """
            mvn clean verify sonar:sonar \
              -Dsonar.projectKey=Boardgame \
              -Dsonar.projectName='Boardgame'
          """
        }
      }
    }

    stage('OWASP Dependency-Check Vulnerabilities') {
      steps {
        dependencyCheck additionalArguments: '''
          -o './'
          -s './'
          -f 'ALL'
          --prettyPrint''',
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
            aws sts get-caller-identity || { echo "AWS creds not working"; exit 1; }

            echo "=== Updating kubeconfig for EKS ==="
            export AWS_DEFAULT_REGION=${AWS_REGION}
            aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME} --region ${AWS_REGION}

            echo "=== Ensuring namespace exists ==="
            kubectl create namespace ${KUBE_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

            echo "=== Applying Kubernetes manifests ==="
            kubectl apply -f k8s/namespace.yaml
            kubectl apply -f k8s/deployment.yaml -n ${KUBE_NAMESPACE}
            kubectl apply -f k8s/service.yaml -n ${KUBE_NAMESPACE}

            echo "=== Restarting deployment to pull new image ==="
            kubectl rollout restart deployment/boardgame-app -n ${KUBE_NAMESPACE}

            echo "=== Waiting for rollout to finish ==="
            kubectl rollout status deployment/boardgame-app -n ${KUBE_NAMESPACE}
          '''
        }
      }
    }
  }
}
