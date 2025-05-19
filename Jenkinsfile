pipeline {
    agent any

    environment {
        TF_WORKSPACE = "default"
        // Add any cloud credentials here (e.g., AWS_ACCESS_KEY_ID, etc.)
    }

    parameters {
        string(name: 'GIT_REPO', defaultValue: 'https://github.com/ndongo716/kube.git', description: 'Git repository URL containing Terraform code')
        string(name: 'BRANCH', defaultValue: 'main', description: 'Branch to checkout')
    }

    stages {
        stage('Clone Terraform Config') {
            steps {
                git branch: "${params.BRANCH}", url: "${params.GIT_REPO}"
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform plan -out=tfplan'
            }
        }

        stage('Terraform Apply') {
            steps {
                input message: 'Approve Terraform Apply?'
                sh 'terraform apply -auto-approve tfplan'
            }
        }
    }

    post {
        failure {
            echo 'Pipeline failed!'
        }
    }
}
